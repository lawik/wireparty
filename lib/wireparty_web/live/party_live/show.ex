defmodule WirepartyWeb.PartyLive.Show do
  use WirepartyWeb, :live_view

  import WirepartyWeb.Components.QrCode

  @impl true
  def mount(%{"slug" => slug}, _session, socket) do
    case Wireparty.Party.Event.get_by_slug(slug, actor: Wireparty.Actors.public(), load: [:peers]) do
      {:ok, event} ->
        {:ok,
         socket
         |> assign(:event, event)
         |> assign(:peer, nil)
         |> assign(:page_title, event.name)
         |> assign(:peer_count, length(event.peers))}

      {:error, _} ->
        {:ok,
         socket
         |> put_flash(:error, "Party not found")
         |> redirect(to: ~p"/")}
    end
  end

  @impl true
  def handle_event("join", %{"label" => label}, socket) do
    event = socket.assigns.event
    label = if label == "", do: nil, else: label

    case Wireparty.Party.Peer.join_party(
           %{event_id: event.id, label: label},
           actor: Wireparty.Actors.public()
         ) do
      {:ok, peer} ->
        # Load the event association for config generation
        peer = %{peer | event: event}

        {:noreply,
         socket
         |> assign(:peer, peer)
         |> assign(:peer_count, socket.assigns.peer_count + 1)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not join the party. Try again!")}
    end
  end

  defp wg_config(peer, event) do
    Wireparty.WireGuard.peer_config(peer, event)
  end

  defp nerves_config(peer, event) do
    Wireparty.WireGuard.nerves_snippet(peer, event)
  end

  defp party_url(slug) do
    WirepartyWeb.Endpoint.url() <> "/party/#{slug}"
  end
end
