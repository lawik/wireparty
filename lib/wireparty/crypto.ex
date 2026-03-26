defmodule Wireparty.Crypto do
  @moduledoc """
  WireGuard key generation using Curve25519/X25519.
  """

  @doc """
  Generates a WireGuard keypair.
  Returns `{private_key_b64, public_key_b64}`.
  """
  def generate_keypair do
    {pub, priv} = :crypto.generate_key(:ecdh, :x25519)
    {Base.encode64(priv), Base.encode64(pub)}
  end

  @doc """
  Derives the public key from a base64-encoded private key.
  """
  def public_key(private_key_b64) do
    private_key = Base.decode64!(private_key_b64)
    {pub, _priv} = :crypto.generate_key(:ecdh, :x25519, private_key)
    Base.encode64(pub)
  end

  @doc """
  Generates a random 32-byte preshared key, base64-encoded.
  """
  def generate_preshared_key do
    :crypto.strong_rand_bytes(32) |> Base.encode64()
  end
end
