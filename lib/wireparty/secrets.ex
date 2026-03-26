defmodule Wireparty.Secrets do
  use AshAuthentication.Secret

  def secret_for(
        [:authentication, :tokens, :signing_secret],
        Wireparty.Accounts.User,
        _opts,
        _context
      ) do
    Application.fetch_env(:wireparty, :token_signing_secret)
  end

  def secret_for(
        [:authentication, :strategies, :github, :client_id],
        Wireparty.Accounts.User,
        _opts,
        _context
      ) do
    get_github_config(:client_id)
  end

  def secret_for(
        [:authentication, :strategies, :github, :redirect_uri],
        Wireparty.Accounts.User,
        _opts,
        _context
      ) do
    get_github_config(:redirect_uri)
  end

  def secret_for(
        [:authentication, :strategies, :github, :client_secret],
        Wireparty.Accounts.User,
        _opts,
        _context
      ) do
    get_github_config(:client_secret)
  end

  defp get_github_config(key) do
    :wireparty
    |> Application.get_env(:github, [])
    |> Keyword.fetch(key)
  end
end
