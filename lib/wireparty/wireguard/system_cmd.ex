defmodule Wireparty.WireGuard.SystemCmd do
  @moduledoc """
  Real command runner using System.cmd/3.
  """
  @behaviour Wireparty.WireGuard.CmdRunner

  @impl true
  def run_cmd(cmd, args) do
    case System.cmd(cmd, args, stderr_to_stdout: true) do
      {_output, 0} -> :ok
      {output, code} -> {:error, {output, code}}
    end
  end

  @impl true
  def run_cmd_output(cmd, args) do
    case System.cmd(cmd, args, stderr_to_stdout: true) do
      {output, 0} -> {:ok, output}
      {output, code} -> {:error, {output, code}}
    end
  end
end
