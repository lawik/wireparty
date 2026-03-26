defmodule WirepartyWeb.PartyLive.Manage do
  use WirepartyWeb, :live_view

  import WirepartyWeb.Components.QrCode

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    actor = socket.assigns.current_user

    case Ash.get(Wireparty.Party.Event, id, actor: actor, load: [:peers]) do
      {:ok, event} ->
        if connected?(socket) do
          Wireparty.Party.PubSub.subscribe(event.id)
        end

        {:ok,
         socket
         |> assign(:event, event)
         |> assign(:page_title, "Manage: #{event.name}")
         |> assign(:connected_keys, MapSet.new())}

      {:error, _} ->
        {:ok,
         socket
         |> put_flash(:error, "Party not found")
         |> redirect(to: ~p"/parties")}
    end
  end

  @impl true
  def handle_event("activate", _params, socket) do
    case Wireparty.Party.Event.activate_event(socket.assigns.event,
           actor: socket.assigns.current_user
         ) do
      {:ok, event} ->
        event = Ash.load!(event, [:peers], actor: Wireparty.Actors.system())

        {:noreply,
         socket
         |> assign(:event, event)
         |> put_flash(:info, "Party is now active!")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not activate party")}
    end
  end

  @impl true
  def handle_event("archive", _params, socket) do
    case Wireparty.Party.Event.archive_event(socket.assigns.event,
           actor: socket.assigns.current_user
         ) do
      {:ok, event} ->
        event = Ash.load!(event, [:peers], actor: Wireparty.Actors.system())

        {:noreply,
         socket
         |> assign(:event, event)
         |> put_flash(:info, "Party archived")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not archive party")}
    end
  end

  @impl true
  def handle_info({:peer_joined, peer}, socket) do
    event = socket.assigns.event
    peers = event.peers ++ [peer]
    {:noreply, assign(socket, :event, %{event | peers: peers})}
  end

  def handle_info({:peer_removed, peer_id}, socket) do
    event = socket.assigns.event
    peers = Enum.reject(event.peers, &(&1.id == peer_id))
    {:noreply, assign(socket, :event, %{event | peers: peers})}
  end

  def handle_info({:handshake_status, connected_keys}, socket) do
    {:noreply, assign(socket, :connected_keys, connected_keys)}
  end

  def handle_info({:event_updated, event}, socket) do
    event = Ash.load!(event, [:peers], actor: Wireparty.Actors.system())
    {:noreply, assign(socket, :event, event)}
  end

  def handle_info(_, socket), do: {:noreply, socket}

  defp party_url(slug) do
    WirepartyWeb.Endpoint.url() <> "/party/#{slug}"
  end

  defp peer_connected?(peer, connected_keys) do
    MapSet.member?(connected_keys, peer.public_key)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-4xl mx-auto p-6">
      <div class="flex items-center gap-4 mb-8">
        <.link navigate={~p"/parties"} class="btn btn-ghost btn-sm">Back</.link>
        <h1 class="text-3xl font-bold">{@event.name}</h1>
        <span class={["badge", status_badge(@event.status)]}>{@event.status}</span>
      </div>

      <div class="grid grid-cols-1 md:grid-cols-2 gap-6 mb-8">
        <div class="card bg-base-100 shadow">
          <div class="card-body">
            <h2 class="card-title">Details</h2>
            <dl class="space-y-2 text-sm">
              <div class="flex justify-between">
                <dt class="text-base-content/60">Slug</dt>
                <dd class="font-mono">{@event.slug}</dd>
              </div>
              <div class="flex justify-between">
                <dt class="text-base-content/60">Port</dt>
                <dd>{@event.listen_port}</dd>
              </div>
              <div class="flex justify-between">
                <dt class="text-base-content/60">Subnet</dt>
                <dd class="font-mono">{Wireparty.Subnet.subnet_cidr(@event.subnet_index)}</dd>
              </div>
              <div class="flex justify-between">
                <dt class="text-base-content/60">Interface</dt>
                <dd class="font-mono">{@event.interface_name}</dd>
              </div>
              <div :if={@event.server_endpoint} class="flex justify-between">
                <dt class="text-base-content/60">Endpoint</dt>
                <dd class="font-mono">{@event.server_endpoint}</dd>
              </div>
              <div class="flex justify-between">
                <dt class="text-base-content/60">Peers</dt>
                <dd>
                  {length(@event.peers)} joined
                  <span :if={MapSet.size(@connected_keys) > 0} class="text-success ml-1">
                    ({MapSet.size(@connected_keys)} connected)
                  </span>
                </dd>
              </div>
            </dl>

            <div class="card-actions mt-4">
              <button
                :if={@event.status == :draft}
                phx-click="activate"
                class="btn btn-success btn-sm"
              >
                Activate
              </button>
              <button
                :if={@event.status == :active}
                phx-click="archive"
                class="btn btn-warning btn-sm"
              >
                Archive
              </button>
            </div>
          </div>
        </div>

        <div class="card bg-base-100 shadow">
          <div class="card-body items-center">
            <h2 class="card-title">Public Link</h2>
            <div class="w-40">
              <.qr_code url={party_url(@event.slug)} />
            </div>
            <div class="relative w-full">
              <input
                type="text"
                value={party_url(@event.slug)}
                readonly
                class="input input-bordered input-sm w-full font-mono text-xs"
                id="public-url"
              />
              <button
                phx-hook="CopyToClipboard"
                id="copy-url"
                data-target="public-url"
                class="btn btn-xs btn-ghost absolute top-0.5 right-0.5"
              >
                Copy
              </button>
            </div>
          </div>
        </div>
      </div>

      <div class="card bg-base-100 shadow">
        <div class="card-body">
          <h2 class="card-title">Peers</h2>

          <div :if={@event.peers == []} class="py-4 text-base-content/60 text-center">
            No peers have joined yet.
          </div>

          <div :if={@event.peers != []} class="overflow-x-auto">
            <table class="table table-sm">
              <thead>
                <tr>
                  <th>Status</th>
                  <th>Label</th>
                  <th>IP</th>
                  <th>Public Key</th>
                  <th>Joined</th>
                </tr>
              </thead>
              <tbody>
                <tr :for={peer <- @event.peers}>
                  <td>
                    <span
                      :if={peer_connected?(peer, @connected_keys)}
                      class="badge badge-success badge-xs"
                    >
                      online
                    </span>
                    <span
                      :if={!peer_connected?(peer, @connected_keys)}
                      class="badge badge-ghost badge-xs"
                    >
                      offline
                    </span>
                  </td>
                  <td>{peer.label || "—"}</td>
                  <td class="font-mono text-xs">{peer.assigned_ip}</td>
                  <td class="font-mono text-xs">{String.slice(peer.public_key, 0..15)}...</td>
                  <td>{Calendar.strftime(peer.inserted_at, "%H:%M")}</td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp status_badge(:draft), do: "badge-warning"
  defp status_badge(:active), do: "badge-success"
  defp status_badge(:archived), do: "badge-ghost"
end
