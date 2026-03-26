defmodule Wireparty.Workers.TeardownPartyWorker do
  use Oban.Worker, queue: :default

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"event_id" => event_id}}) do
    actor = Wireparty.Actors.system()
    event = Ash.get!(Wireparty.Party.Event, event_id, actor: actor)

    with :ok <- Wireparty.WireGuard.teardown_interface(event.interface_name),
         :ok <- Wireparty.Iptables.close_udp_port(event.listen_port) do
      :ok
    end
  end
end
