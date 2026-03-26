defmodule Wireparty.WireGuard.HandshakePoller do
  @moduledoc """
  Periodically checks WireGuard interfaces for recent handshakes
  and broadcasts connection status via PubSub.

  A peer is considered "connected" if its latest handshake was
  within the last 3 minutes (WireGuard sends keepalives every 25s
  if configured, handshakes refresh every 2 minutes).
  """
  use GenServer

  @poll_interval :timer.seconds(10)
  @handshake_timeout_seconds 180

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    schedule_poll()
    {:ok, %{}}
  end

  @impl true
  def handle_info(:poll, state) do
    state = poll_all_active_events(state)
    schedule_poll()
    {:noreply, state}
  end

  defp schedule_poll do
    Process.send_after(self(), :poll, @poll_interval)
  end

  defp poll_all_active_events(state) do
    events =
      require Ash.Query

      Wireparty.Party.Event
      |> Ash.Query.filter(status == :active)
      |> Ash.Query.select([:id, :interface_name])
      |> Ash.read!(actor: Wireparty.Actors.system())

    Enum.reduce(events, state, fn event, acc ->
      connected_keys = get_connected_keys(event.interface_name)
      prev_keys = Map.get(acc, event.id, MapSet.new())

      if connected_keys != prev_keys do
        Wireparty.Party.PubSub.broadcast_handshake_status(event.id, connected_keys)
      end

      Map.put(acc, event.id, connected_keys)
    end)
  end

  defp get_connected_keys(interface_name) do
    case cmd_runner().run_cmd_output("wg", ["show", interface_name, "latest-handshakes"]) do
      {:ok, output} ->
        now = System.os_time(:second)

        output
        |> String.split("\n", trim: true)
        |> Enum.reduce(MapSet.new(), fn line, acc ->
          case String.split(line, "\t") do
            [public_key, timestamp_str] ->
              case Integer.parse(timestamp_str) do
                {timestamp, _} when timestamp > 0 and now - timestamp < @handshake_timeout_seconds ->
                  MapSet.put(acc, public_key)

                _ ->
                  acc
              end

            _ ->
              acc
          end
        end)

      {:error, _} ->
        MapSet.new()
    end
  end

  defp cmd_runner do
    Application.get_env(:wireparty, :cmd_runner, Wireparty.WireGuard.SystemCmd)
  end
end
