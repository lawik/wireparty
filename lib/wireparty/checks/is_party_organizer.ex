defmodule Wireparty.Checks.IsPartyOrganizer do
  use Ash.Policy.FilterCheck

  @impl true
  def describe(_opts), do: "actor is the organizer of this party"

  @impl true
  def filter(_actor, _context, _opts) do
    expr(organizer_id == ^actor(:id))
  end
end
