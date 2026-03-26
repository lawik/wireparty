defmodule Wireparty.Party do
  use Ash.Domain, otp_app: :wireparty

  resources do
    resource Wireparty.Party.Event
    resource Wireparty.Party.Peer
  end
end
