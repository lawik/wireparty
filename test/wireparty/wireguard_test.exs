defmodule Wireparty.WireGuardTest do
  use ExUnit.Case, async: true

  alias Wireparty.WireGuard

  @event %{
    server_private_key: "YNqHbfBQKaGvlC8Bk4F2kMOvICFnx2GzSfkI9XaFcnk=",
    server_public_key: "f5IOVR9VbCEAmDfJtMrUSVfjBk/JoFSw7jYkKmS3ySI=",
    listen_port: 51820,
    subnet_index: 1,
    server_endpoint: "wireparty.example.com"
  }

  @peer %{
    private_key: "kMp+S22MjlCNLF/lOUzfGSCjOI+rGGRb3vFsHFVCWH4=",
    public_key: "dTpA9fNEPKGSEN9AiCVjOIGRjO1fNLClSsGMzUGWpSY=",
    assigned_ip: "10.100.1.2/24",
    peer_index: 1
  }

  describe "server_config/2" do
    test "generates valid server config with no peers" do
      config = WireGuard.server_config(@event)

      assert config =~ "[Interface]"
      assert config =~ "PrivateKey = #{@event.server_private_key}"
      assert config =~ "Address = 10.100.1.1/24"
      assert config =~ "ListenPort = 51820"
      refute config =~ "[Peer]"
    end

    test "includes peer sections" do
      config = WireGuard.server_config(@event, [@peer])

      assert config =~ "[Peer]"
      assert config =~ "PublicKey = #{@peer.public_key}"
      assert config =~ "AllowedIPs = 10.100.1.2/32"
    end
  end

  describe "peer_config/2" do
    test "generates valid client config" do
      config = WireGuard.peer_config(@peer, @event)

      assert config =~ "[Interface]"
      assert config =~ "PrivateKey = #{@peer.private_key}"
      assert config =~ "Address = #{@peer.assigned_ip}"
      assert config =~ "[Peer]"
      assert config =~ "PublicKey = #{@event.server_public_key}"
      assert config =~ "Endpoint = wireparty.example.com:51820"
      assert config =~ "AllowedIPs = 10.100.1.0/24"
      assert config =~ "PersistentKeepalive = 25"
    end
  end

  describe "nerves_snippet/2" do
    test "generates VintageNet configuration snippet" do
      snippet = WireGuard.nerves_snippet(@peer, @event)

      assert snippet =~ "VintageNet.configure"
      assert snippet =~ "VintageNetWireGuard"
      assert snippet =~ @peer.private_key
      assert snippet =~ @peer.assigned_ip
      assert snippet =~ @event.server_public_key
      assert snippet =~ "wireparty.example.com:51820"
      assert snippet =~ "persistent_keepalive: 25"
    end
  end
end
