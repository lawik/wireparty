defmodule Wireparty.Party.Changes.AllocatePeerAddress do
  @moduledoc """
  Allocates peer_index and assigned_ip for a new peer joining a party.
  """
  use Ash.Resource.Change

  @impl true
  def change(changeset, _opts, _context) do
    Ash.Changeset.before_action(changeset, fn changeset ->
      event_id = Ash.Changeset.get_argument(changeset, :event_id)
      event = Ash.get!(Wireparty.Party.Event, event_id, actor: Wireparty.Actors.system())

      next_index = next_peer_index(event_id)

      changeset
      |> Ash.Changeset.change_attribute(:peer_index, next_index)
      |> Ash.Changeset.change_attribute(
        :assigned_ip,
        Wireparty.Subnet.peer_address(event.subnet_index, next_index)
      )
    end)
  end

  defp next_peer_index(event_id) do
    case Wireparty.Party.Peer
         |> Ash.Query.filter(event_id == ^event_id)
         |> Ash.Query.sort(peer_index: :desc)
         |> Ash.Query.limit(1)
         |> Ash.Query.select([:peer_index])
         |> Ash.read!(actor: Wireparty.Actors.system()) do
      [last] -> last.peer_index + 1
      [] -> 1
    end
  end
end
