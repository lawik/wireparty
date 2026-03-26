defmodule Wireparty.Party.Peer do
  use Ash.Resource,
    otp_app: :wireparty,
    domain: Wireparty.Party,
    data_layer: AshSqlite.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  sqlite do
    table "peers"
    repo Wireparty.Repo
  end

  code_interface do
    define :join_party, action: :join
    define :list_for_event, action: :for_event, args: [:event_id]
  end

  actions do
    defaults [:read, :destroy]

    create :join do
      accept [:label]
      argument :event_id, :uuid, allow_nil?: false

      change fn changeset, _ctx ->
        event_id = Ash.Changeset.get_argument(changeset, :event_id)
        Ash.Changeset.force_change_attribute(changeset, :event_id, event_id)
      end

      change Wireparty.Party.Changes.AllocatePeerAddress

      change fn changeset, _ctx ->
        {priv, pub} = Wireparty.Crypto.generate_keypair()

        changeset
        |> Ash.Changeset.force_change_attribute(:private_key, priv)
        |> Ash.Changeset.force_change_attribute(:public_key, pub)
      end

      change after_action(fn _changeset, peer, _context ->
        %{peer_id: peer.id}
        |> Wireparty.Workers.AddPeerWorker.new()
        |> Oban.insert!()

        Wireparty.Party.PubSub.broadcast_peer_joined(peer.event_id, peer)

        {:ok, peer}
      end)
    end

    read :for_event do
      argument :event_id, :uuid, allow_nil?: false
      filter expr(event_id == ^arg(:event_id))
    end
  end

  policies do
    bypass Wireparty.Checks.IsSystem do
      authorize_if always()
    end

    bypass AshAuthentication.Checks.AshAuthenticationInteraction do
      authorize_if always()
    end

    # Anyone (including public/unauthenticated) can join a party
    policy action(:join) do
      authorize_if always()
    end

    # Anyone can read peers (needed to show peer count on public page)
    policy action([:read, :for_event]) do
      authorize_if always()
    end

    # Only the event's organizer can remove peers
    policy action(:destroy) do
      authorize_if actor_present()
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :label, :string, public?: true
    attribute :private_key, :string, allow_nil?: false, sensitive?: true
    attribute :public_key, :string, allow_nil?: false, public?: true
    attribute :assigned_ip, :string, allow_nil?: false, public?: true
    attribute :peer_index, :integer, allow_nil?: false, public?: true

    create_timestamp :inserted_at
  end

  relationships do
    belongs_to :event, Wireparty.Party.Event, allow_nil?: false
  end

  identities do
    identity :unique_ip_per_event, [:event_id, :assigned_ip]
    identity :unique_index_per_event, [:event_id, :peer_index]
    identity :unique_pubkey_per_event, [:event_id, :public_key]
  end
end
