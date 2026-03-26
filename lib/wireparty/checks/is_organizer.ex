defmodule Wireparty.Checks.IsOrganizer do
  use Ash.Policy.SimpleCheck

  @impl true
  def describe(_opts), do: "actor is an organizer"

  @impl true
  def match?(%Wireparty.Accounts.User{role: :organizer}, _context, _opts), do: true
  def match?(_, _context, _opts), do: false
end
