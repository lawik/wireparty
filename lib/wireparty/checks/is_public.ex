defmodule Wireparty.Checks.IsPublic do
  use Ash.Policy.SimpleCheck

  @impl true
  def describe(_opts), do: "actor is the public actor"

  @impl true
  def match?(%Wireparty.Actors.Public{}, _context, _opts), do: true
  def match?(_, _context, _opts), do: false
end
