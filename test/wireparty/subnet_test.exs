defmodule Wireparty.SubnetTest do
  use ExUnit.Case, async: true

  alias Wireparty.Subnet

  describe "subnet_cidr/1" do
    test "returns the /24 CIDR for a subnet index" do
      assert Subnet.subnet_cidr(1) == "10.100.1.0/24"
      assert Subnet.subnet_cidr(42) == "10.100.42.0/24"
      assert Subnet.subnet_cidr(254) == "10.100.254.0/24"
    end
  end

  describe "server_address/1" do
    test "returns .1 with /24 CIDR" do
      assert Subnet.server_address(1) == "10.100.1.1/24"
      assert Subnet.server_address(10) == "10.100.10.1/24"
    end
  end

  describe "server_ip/1" do
    test "returns just the IP without CIDR" do
      assert Subnet.server_ip(1) == "10.100.1.1"
      assert Subnet.server_ip(10) == "10.100.10.1"
    end
  end

  describe "peer_address/2" do
    test "first peer gets .2" do
      assert Subnet.peer_address(1, 1) == "10.100.1.2/24"
    end

    test "nth peer gets n+1" do
      assert Subnet.peer_address(1, 5) == "10.100.1.6/24"
      assert Subnet.peer_address(3, 253) == "10.100.3.254/24"
    end
  end

  describe "peer_ip/2" do
    test "returns just the IP without CIDR" do
      assert Subnet.peer_ip(1, 1) == "10.100.1.2"
      assert Subnet.peer_ip(2, 10) == "10.100.2.11"
    end
  end

  describe "max_peers/0" do
    test "returns 253" do
      assert Subnet.max_peers() == 253
    end
  end
end
