defmodule WirepartyWeb.PartyLive.Index do
  use WirepartyWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    events =
      Wireparty.Party.Event
      |> Ash.Query.sort(inserted_at: :desc)
      |> Ash.read!(actor: socket.assigns.current_user)

    {:ok,
     socket
     |> assign(:page_title, "Parties")
     |> assign(:events, events)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-4xl mx-auto p-6">
      <div class="flex justify-between items-center mb-8">
        <h1 class="text-3xl font-bold">Your Parties</h1>
        <.link navigate={~p"/parties/new"} class="btn btn-primary">
          New Party
        </.link>
      </div>

      <div :if={@events == []} class="text-center py-12 text-base-content/60">
        <p class="text-lg">No parties yet.</p>
        <p>Create your first wire party to get started!</p>
      </div>

      <div class="overflow-x-auto">
        <table :if={@events != []} class="table">
          <thead>
            <tr>
              <th>Name</th>
              <th>Status</th>
              <th>Port</th>
              <th>Created</th>
              <th></th>
            </tr>
          </thead>
          <tbody>
            <tr :for={event <- @events}>
              <td class="font-medium">{event.name}</td>
              <td>
                <span class={["badge", status_badge(event.status)]}>
                  {event.status}
                </span>
              </td>
              <td>{event.listen_port}</td>
              <td>{Calendar.strftime(event.inserted_at, "%Y-%m-%d %H:%M")}</td>
              <td>
                <.link navigate={~p"/parties/#{event.id}/manage"} class="btn btn-sm btn-ghost">
                  Manage
                </.link>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
    """
  end

  defp status_badge(:draft), do: "badge-warning"
  defp status_badge(:active), do: "badge-success"
  defp status_badge(:archived), do: "badge-ghost"
end
