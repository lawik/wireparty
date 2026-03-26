defmodule Wireparty.Accounts do
  use Ash.Domain,
    otp_app: :wireparty

  resources do
    resource Wireparty.Accounts.Token
    resource Wireparty.Accounts.User
  end
end
