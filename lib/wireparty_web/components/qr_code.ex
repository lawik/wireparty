defmodule WirepartyWeb.Components.QrCode do
  use Phoenix.Component

  attr :url, :string, required: true
  attr :class, :string, default: ""

  def qr_code(assigns) do
    svg = assigns.url |> EQRCode.encode() |> EQRCode.svg(viewbox: true)
    assigns = assign(assigns, :svg, svg)

    ~H"""
    <div class={@class}>
      {Phoenix.HTML.raw(@svg)}
    </div>
    """
  end
end
