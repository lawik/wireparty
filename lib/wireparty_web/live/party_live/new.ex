defmodule WirepartyWeb.PartyLive.New do
  use WirepartyWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    form =
      Wireparty.Party.Event
      |> AshPhoenix.Form.for_create(:create, actor: socket.assigns.current_user)
      |> to_form()

    {:ok,
     socket
     |> assign(:page_title, "New Party")
     |> assign(:form, form)}
  end

  @impl true
  def handle_event("validate", %{"form" => params}, socket) do
    form =
      socket.assigns.form.source
      |> AshPhoenix.Form.validate(params)
      |> to_form()

    {:noreply, assign(socket, :form, form)}
  end

  @impl true
  def handle_event("save", %{"form" => params}, socket) do
    case AshPhoenix.Form.submit(socket.assigns.form.source, params: params) do
      {:ok, event} ->
        {:noreply,
         socket
         |> put_flash(:info, "Party \"#{event.name}\" created!")
         |> push_navigate(to: ~p"/parties/#{event.id}/manage")}

      {:error, form} ->
        {:noreply, assign(socket, :form, to_form(form))}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-lg mx-auto p-6">
      <h1 class="text-3xl font-bold mb-8">Create a Wire Party</h1>

      <.form for={@form} phx-change="validate" phx-submit="save" class="space-y-4">
        <div class="form-control">
          <label class="label">
            <span class="label-text">Party Name</span>
          </label>
          <input
            type="text"
            name={@form[:name].name}
            value={@form[:name].value}
            class="input input-bordered"
            placeholder="e.g. NervesConf 2026 Hack Night"
            required
          />
          <p
            :for={{msg, _} <- @form[:name].errors}
            class="text-error text-sm mt-1"
          >
            {msg}
          </p>
        </div>

        <div class="flex gap-4 pt-4">
          <button type="submit" class="btn btn-primary">Create Party</button>
          <.link navigate={~p"/parties"} class="btn btn-ghost">Cancel</.link>
        </div>
      </.form>
    </div>
    """
  end

end
