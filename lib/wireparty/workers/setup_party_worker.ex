defmodule Wireparty.Workers.SetupPartyWorker do
  use Oban.Worker, queue: :default

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"event_id" => event_id}}) do
    actor = Wireparty.Actors.system()
    event = Ash.get!(Wireparty.Party.Event, event_id, actor: actor, load: [:peers])

    with :ok <- Wireparty.Iptables.open_udp_port(event.listen_port),
         :ok <-
           Wireparty.WireGuard.setup_interface(
             event.interface_name,
             event.server_private_key,
             Wireparty.Subnet.server_address(event.subnet_index),
             event.listen_port
           ) do
      # Add any existing peers
      Enum.each(event.peers, fn peer ->
        Wireparty.WireGuard.add_peer(
          event.interface_name,
          peer.public_key,
          Wireparty.Subnet.peer_ip(event.subnet_index, peer.peer_index) <> "/32"
        )
      end)

      :ok
    end
  end
end
