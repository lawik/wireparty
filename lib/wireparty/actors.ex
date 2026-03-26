defmodule Wireparty.Actors do
  defmodule Public do
    defstruct []
  end

  defmodule System do
    defstruct []
  end

  def public, do: %Public{}
  def system, do: %System{}
end
