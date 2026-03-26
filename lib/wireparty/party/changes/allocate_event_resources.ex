defmodule Wireparty.Party.Changes.AllocateEventResources do
  @moduledoc """
  Allocates listen_port, subnet_index, and interface_name for a new event.
  """
  use Ash.Resource.Change

  @starting_port 51820

  @impl true
  def change(changeset, _opts, _context) do
    Ash.Changeset.before_action(changeset, fn changeset ->
      {next_port, next_subnet} = next_allocation()

      changeset
      |> Ash.Changeset.change_attribute(:listen_port, next_port)
      |> Ash.Changeset.change_attribute(:subnet_index, next_subnet)
      |> Ash.Changeset.change_attribute(:interface_name, "wg-party-#{next_subnet}")
    end)
  end

  defp next_allocation do
    case Wireparty.Party.Event
         |> Ash.Query.sort(listen_port: :desc)
         |> Ash.Query.limit(1)
         |> Ash.Query.select([:listen_port, :subnet_index])
         |> Ash.read!(actor: Wireparty.Actors.system()) do
      [last] ->
        {last.listen_port + 1, last.subnet_index + 1}

      [] ->
        {@starting_port, 1}
    end
  end
end
