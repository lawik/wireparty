defmodule Wireparty.WireGuard do
  @moduledoc """
  WireGuard configuration generation and interface management.
  """

  @doc """
  Generates the server-side WireGuard config for a party.
  """
  def server_config(event, peers \\ []) do
    interface = """
    [Interface]
    PrivateKey = #{event.server_private_key}
    Address = #{Wireparty.Subnet.server_address(event.subnet_index)}
    ListenPort = #{event.listen_port}
    """

    peer_sections =
      Enum.map(peers, fn peer ->
        """

        [Peer]
        PublicKey = #{peer.public_key}
        AllowedIPs = #{Wireparty.Subnet.peer_ip(event.subnet_index, peer.peer_index)}/32
        """
      end)

    String.trim(interface <> Enum.join(peer_sections))
  end

  @doc """
  Generates a full client WireGuard config for a peer.
  """
  def peer_config(peer, event) do
    """
    [Interface]
    PrivateKey = #{peer.private_key}
    Address = #{peer.assigned_ip}

    [Peer]
    PublicKey = #{event.server_public_key}
    Endpoint = #{event.server_endpoint}:#{event.listen_port}
    AllowedIPs = #{Wireparty.Subnet.subnet_cidr(event.subnet_index)}
    PersistentKeepalive = 25
    """
    |> String.trim()
  end

  @doc """
  Generates an iex-pasteable snippet for connecting a Nerves device.
  """
  def nerves_snippet(peer, event) do
    """
    VintageNet.configure("wg0", %{
      type: VintageNetWireGuard,
      vintage_net_wireguard: %{
        private_key: "#{peer.private_key}",
        addresses: ["#{peer.assigned_ip}"],
        peers: [
          %{
            public_key: "#{event.server_public_key}",
            endpoint: "#{event.server_endpoint}:#{event.listen_port}",
            allowed_ips: ["#{Wireparty.Subnet.subnet_cidr(event.subnet_index)}"],
            persistent_keepalive: 25
          }
        ]
      }
    })
    """
    |> String.trim()
  end

  # --- Interface management (shell commands) ---

  @doc """
  Creates and configures a WireGuard interface.
  """
  def setup_interface(name, private_key, address, listen_port) do
    with :ok <- run("ip", ["link", "add", name, "type", "wireguard"]),
         :ok <- write_private_key_and_configure(name, private_key, listen_port),
         :ok <- run("ip", ["address", "add", address, "dev", name]),
         :ok <- run("ip", ["link", "set", name, "up"]) do
      :ok
    end
  end

  defp write_private_key_and_configure(name, private_key, listen_port) do
    # Write private key to a temp file, configure, then delete
    tmp = "/tmp/wg-#{name}-#{System.unique_integer([:positive])}"

    File.write!(tmp, private_key)

    result =
      run("wg", [
        "set",
        name,
        "listen-port",
        to_string(listen_port),
        "private-key",
        tmp
      ])

    File.rm(tmp)
    result
  end

  @doc """
  Tears down a WireGuard interface.
  """
  def teardown_interface(name) do
    run("ip", ["link", "del", name])
  end

  @doc """
  Adds a peer to an existing WireGuard interface.
  """
  def add_peer(interface_name, public_key, allowed_ips) do
    run("wg", ["set", interface_name, "peer", public_key, "allowed-ips", allowed_ips])
  end

  @doc """
  Removes a peer from a WireGuard interface.
  """
  def remove_peer(interface_name, public_key) do
    run("wg", ["set", interface_name, "peer", public_key, "remove"])
  end

  defp run(cmd, args) do
    cmd_runner().run_cmd(cmd, args)
  end

  defp cmd_runner do
    Application.get_env(:wireparty, :cmd_runner, Wireparty.WireGuard.SystemCmd)
  end
end
