defmodule Wireparty.Party.Event do
  use Ash.Resource,
    otp_app: :wireparty,
    domain: Wireparty.Party,
    data_layer: AshSqlite.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  sqlite do
    table "events"
    repo Wireparty.Repo
  end

  code_interface do
    define :create_event, action: :create
    define :get_by_slug, action: :by_slug, args: [:slug]
    define :activate_event, action: :activate
    define :archive_event, action: :archive
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      accept [:name]

      change Wireparty.Party.Changes.AllocateEventResources

      change fn changeset, _ctx ->
        {priv, pub} = Wireparty.Crypto.generate_keypair()

        %URI{host: host} = URI.parse(WirepartyWeb.Endpoint.url())

        changeset
        |> Ash.Changeset.change_attribute(:server_private_key, priv)
        |> Ash.Changeset.change_attribute(:server_public_key, pub)
        |> Ash.Changeset.change_attribute(:server_endpoint, host)
      end

      change fn changeset, _ctx ->
        name = Ash.Changeset.get_attribute(changeset, :name) || ""
        slug = name |> String.downcase() |> String.replace(~r/[^a-z0-9]+/, "-") |> String.trim("-")
        Ash.Changeset.change_attribute(changeset, :slug, slug)
      end

      change relate_actor(:organizer)
    end

    read :by_slug do
      argument :slug, :string, allow_nil?: false
      get? true
      filter expr(slug == ^arg(:slug))
    end

    update :activate do
      require_atomic? false
      change set_attribute(:status, :active)

      change after_action(fn _changeset, event, _context ->
        %{event_id: event.id}
        |> Wireparty.Workers.SetupPartyWorker.new()
        |> Oban.insert!()

        {:ok, event}
      end)
    end

    update :archive do
      require_atomic? false
      change set_attribute(:status, :archived)

      change after_action(fn _changeset, event, _context ->
        %{event_id: event.id}
        |> Wireparty.Workers.TeardownPartyWorker.new()
        |> Oban.insert!()

        {:ok, event}
      end)
    end
  end

  policies do
    bypass Wireparty.Checks.IsSystem do
      authorize_if always()
    end

    bypass AshAuthentication.Checks.AshAuthenticationInteraction do
      authorize_if always()
    end

    policy action(:by_slug) do
      authorize_if always()
    end

    policy action(:read) do
      authorize_if Wireparty.Checks.IsOrganizer
    end

    policy action(:create) do
      authorize_if Wireparty.Checks.IsOrganizer
    end

    policy action([:activate, :archive, :destroy]) do
      authorize_if Wireparty.Checks.IsPartyOrganizer
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :name, :string, allow_nil?: false, public?: true
    attribute :slug, :string, allow_nil?: false, public?: true
    attribute :status, :atom,
      constraints: [one_of: [:draft, :active, :archived]],
      default: :draft,
      public?: true

    attribute :server_private_key, :string, allow_nil?: false, sensitive?: true
    attribute :server_public_key, :string, allow_nil?: false, public?: true
    attribute :listen_port, :integer, allow_nil?: false, public?: true
    attribute :subnet_index, :integer, allow_nil?: false, public?: true
    attribute :interface_name, :string, allow_nil?: false, public?: true
    attribute :server_endpoint, :string, public?: true

    create_timestamp :inserted_at
    update_timestamp :updated_at
  end

  relationships do
    belongs_to :organizer, Wireparty.Accounts.User, allow_nil?: false
    has_many :peers, Wireparty.Party.Peer
  end

  identities do
    identity :unique_slug, [:slug]
    identity :unique_port, [:listen_port]
    identity :unique_subnet_index, [:subnet_index]
  end
end
