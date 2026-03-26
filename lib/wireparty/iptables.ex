defmodule Wireparty.Iptables do
  @moduledoc """
  Manages iptables rules for WireGuard UDP ports.
  """

  @doc """
  Opens a UDP port in iptables INPUT chain.
  """
  def open_udp_port(port) do
    run("iptables", ["-A", "INPUT", "-p", "udp", "--dport", to_string(port), "-j", "ACCEPT"])
  end

  @doc """
  Closes a previously opened UDP port.
  """
  def close_udp_port(port) do
    run("iptables", ["-D", "INPUT", "-p", "udp", "--dport", to_string(port), "-j", "ACCEPT"])
  end

  @doc """
  Lists current INPUT chain rules.
  """
  def list_rules do
    cmd_runner().run_cmd_output("iptables", ["-L", "INPUT", "-n", "--line-numbers"])
  end

  defp run(cmd, args) do
    cmd_runner().run_cmd(cmd, args)
  end

  defp cmd_runner do
    Application.get_env(:wireparty, :cmd_runner, Wireparty.WireGuard.SystemCmd)
  end
end
