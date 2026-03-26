defmodule Wireparty.IptablesTest do
  use ExUnit.Case, async: true

  # All iptables tests require root/Docker environment
  # They are tagged and excluded from normal test runs
  @moduletag :iptables_integration

  @tag :skip
  test "open and close UDP port" do
    assert :ok = Wireparty.Iptables.open_udp_port(51999)
    assert {:ok, rules} = Wireparty.Iptables.list_rules()
    assert rules =~ "51999"
    assert :ok = Wireparty.Iptables.close_udp_port(51999)
  end
end
