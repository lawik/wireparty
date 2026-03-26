defmodule Wireparty.WireGuard.CmdRunner do
  @moduledoc """
  Behaviour for running system commands.
  Allows swapping in a mock for testing.
  """

  @callback run_cmd(binary(), [binary()]) :: :ok | {:error, {binary(), non_neg_integer()}}
  @callback run_cmd_output(binary(), [binary()]) :: {:ok, binary()} | {:error, {binary(), non_neg_integer()}}
end
