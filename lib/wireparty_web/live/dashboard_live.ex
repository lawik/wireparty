defmodule WirepartyWeb.DashboardLive do
  use WirepartyWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    events =
      Wireparty.Party.Event
      |> Ash.read!(actor: socket.assigns.current_user)

    active_count = Enum.count(events, &(&1.status == :active))
    total_count = length(events)

    {:ok,
     socket
     |> assign(:page_title, "Dashboard")
     |> assign(:active_count, active_count)
     |> assign(:total_count, total_count)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-4xl mx-auto p-6">
      <h1 class="text-3xl font-bold mb-8">Dashboard</h1>

      <div class="stats shadow mb-8">
        <div class="stat">
          <div class="stat-title">Active Parties</div>
          <div class="stat-value">{@active_count}</div>
        </div>
        <div class="stat">
          <div class="stat-title">Total Parties</div>
          <div class="stat-value">{@total_count}</div>
        </div>
      </div>

      <div class="flex gap-4">
        <.link navigate={~p"/parties/new"} class="btn btn-primary">
          Create a Party
        </.link>
        <.link navigate={~p"/parties"} class="btn btn-outline">
          View All Parties
        </.link>
      </div>
    </div>
    """
  end
end
