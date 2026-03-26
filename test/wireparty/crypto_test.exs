defmodule Wireparty.CryptoTest do
  use ExUnit.Case, async: true

  alias Wireparty.Crypto

  describe "generate_keypair/0" do
    test "returns a tuple of two base64 strings" do
      {priv, pub} = Crypto.generate_keypair()

      assert is_binary(priv)
      assert is_binary(pub)
      assert {:ok, _} = Base.decode64(priv)
      assert {:ok, _} = Base.decode64(pub)
    end

    test "keys are 32 bytes (44 chars base64)" do
      {priv, pub} = Crypto.generate_keypair()

      assert byte_size(Base.decode64!(priv)) == 32
      assert byte_size(Base.decode64!(pub)) == 32
    end

    test "generates different keypairs each time" do
      {priv1, _pub1} = Crypto.generate_keypair()
      {priv2, _pub2} = Crypto.generate_keypair()

      refute priv1 == priv2
    end
  end

  describe "public_key/1" do
    test "derives the same public key from a private key" do
      {priv, pub} = Crypto.generate_keypair()

      assert Crypto.public_key(priv) == pub
    end

    test "is deterministic" do
      {priv, _pub} = Crypto.generate_keypair()

      assert Crypto.public_key(priv) == Crypto.public_key(priv)
    end
  end

  describe "generate_preshared_key/0" do
    test "returns a base64-encoded 32-byte key" do
      psk = Crypto.generate_preshared_key()

      assert is_binary(psk)
      assert byte_size(Base.decode64!(psk)) == 32
    end
  end
end
