defmodule Wireparty.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      WirepartyWeb.Telemetry,
      Wireparty.Repo,
      {Ecto.Migrator,
       repos: Application.fetch_env!(:wireparty, :ecto_repos), skip: skip_migrations?()},
      {Oban,
       AshOban.config(
         Application.fetch_env!(:wireparty, :ash_domains),
         Application.fetch_env!(:wireparty, Oban)
       )},
      # Start a worker by calling: Wireparty.Worker.start_link(arg)
      # {Wireparty.Worker, arg},
      # Start to serve requests, typically the last entry
      {DNSCluster, query: Application.get_env(:wireparty, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Wireparty.PubSub},
      WirepartyWeb.Endpoint,
      {AshAuthentication.Supervisor, [otp_app: :wireparty]}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Wireparty.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    WirepartyWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp skip_migrations?() do
    # By default, sqlite migrations are run when using a release
    System.get_env("RELEASE_NAME") == nil
  end
end
