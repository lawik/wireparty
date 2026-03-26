defmodule Wireparty.Accounts.User do
  use Ash.Resource,
    otp_app: :wireparty,
    domain: Wireparty.Accounts,
    data_layer: AshSqlite.DataLayer,
    authorizers: [Ash.Policy.Authorizer],
    extensions: [AshAuthentication]

  sqlite do
    table "users"
    repo Wireparty.Repo
  end

  authentication do
    add_ons do
      log_out_everywhere do
        apply_on_password_change? true
      end
    end

    strategies do
      github do
        client_id Wireparty.Secrets
        redirect_uri Wireparty.Secrets
        client_secret Wireparty.Secrets
        authorization_params scope: "user:email"
      end
    end

    tokens do
      enabled? true
      token_resource Wireparty.Accounts.Token
      signing_secret Wireparty.Secrets
      store_all_tokens? true
      require_token_presence_for_authentication? true
    end
  end

  actions do
    defaults [:read]

    read :get_by_subject do
      description "Get a user by the subject claim in a JWT"
      argument :subject, :string, allow_nil?: false
      get? true
      prepare AshAuthentication.Preparations.FilterBySubject
    end

    create :register_with_github do
      argument :user_info, :map, allow_nil?: false
      argument :oauth_tokens, :map, allow_nil?: false
      upsert? true
      upsert_identity :unique_email
      upsert_fields []

      accept [:email]

      change AshAuthentication.GenerateTokenChange

      change fn changeset, _ctx ->
        user_info = Ash.Changeset.get_argument(changeset, :user_info)

        email =
          user_info["email"] ||
            user_info["emails"]
            |> List.wrap()
            |> Enum.find(& &1["primary"])
            |> case do
              %{"email" => email} -> email
              _ -> nil
            end

        Ash.Changeset.change_attribute(changeset, :email, email)
      end
    end
  end

  policies do
    bypass AshAuthentication.Checks.AshAuthenticationInteraction do
      authorize_if always()
    end
  end

  attributes do
    uuid_primary_key :id
    attribute :email, :ci_string, allow_nil?: false, public?: true
    attribute :role, :atom, constraints: [one_of: [:user, :organizer]], default: :user
  end

  identities do
    identity :unique_email, [:email]
  end
end
