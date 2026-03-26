defmodule Wireparty.Checks.IsSystem do
  use Ash.Policy.SimpleCheck

  @impl true
  def describe(_opts), do: "actor is the system actor"

  @impl true
  def match?(%Wireparty.Actors.System{}, _context, _opts), do: true
  def match?(_, _context, _opts), do: false
end
