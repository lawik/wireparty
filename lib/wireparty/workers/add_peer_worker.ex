defmodule Wireparty.Workers.AddPeerWorker do
  use Oban.Worker, queue: :default

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"peer_id" => peer_id}}) do
    actor = Wireparty.Actors.system()
    peer = Ash.get!(Wireparty.Party.Peer, peer_id, actor: actor, load: [:event])
    event = peer.event

    if event.status == :active do
      Wireparty.WireGuard.add_peer(
        event.interface_name,
        peer.public_key,
        Wireparty.Subnet.peer_ip(event.subnet_index, peer.peer_index) <> "/32"
      )
    else
      :ok
    end
  end
end
