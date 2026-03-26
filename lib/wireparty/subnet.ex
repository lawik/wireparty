defmodule Wireparty.Subnet do
  @moduledoc """
  IP address allocation for wire parties.

  Each party gets a /24 subnet in the 10.100.X.0 range.
  Server is at .1, peers start at .2 through .254.
  """

  @base_octet1 10
  @base_octet2 100

  @doc """
  Returns the CIDR for a party's subnet.

      iex> Wireparty.Subnet.subnet_cidr(1)
      "10.100.1.0/24"
  """
  def subnet_cidr(subnet_index) do
    "#{@base_octet1}.#{@base_octet2}.#{subnet_index}.0/24"
  end

  @doc """
  Returns the server's address with CIDR for a party.

      iex> Wireparty.Subnet.server_address(1)
      "10.100.1.1/24"
  """
  def server_address(subnet_index) do
    "#{@base_octet1}.#{@base_octet2}.#{subnet_index}.1/24"
  end

  @doc """
  Returns a peer's address with CIDR.
  peer_index is 1-based, so peer 1 gets .2, peer 2 gets .3, etc.

      iex> Wireparty.Subnet.peer_address(1, 1)
      "10.100.1.2/24"

      iex> Wireparty.Subnet.peer_address(3, 5)
      "10.100.3.6/24"
  """
  def peer_address(subnet_index, peer_index) when peer_index >= 1 and peer_index <= 253 do
    "#{@base_octet1}.#{@base_octet2}.#{subnet_index}.#{peer_index + 1}/24"
  end

  @doc """
  Returns just the IP (no CIDR) for a peer.

      iex> Wireparty.Subnet.peer_ip(1, 1)
      "10.100.1.2"
  """
  def peer_ip(subnet_index, peer_index) when peer_index >= 1 and peer_index <= 253 do
    "#{@base_octet1}.#{@base_octet2}.#{subnet_index}.#{peer_index + 1}"
  end

  @doc """
  Returns just the server IP (no CIDR).

      iex> Wireparty.Subnet.server_ip(1)
      "10.100.1.1"
  """
  def server_ip(subnet_index) do
    "#{@base_octet1}.#{@base_octet2}.#{subnet_index}.1"
  end

  @doc """
  Maximum number of peers per party (addresses .2 through .254).
  """
  def max_peers, do: 253
end
