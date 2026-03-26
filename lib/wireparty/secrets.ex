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
end
