defmodule Wireparty.Party.PubSub do
  @moduledoc """
  PubSub helpers for party events.
  """

  @pubsub Wireparty.PubSub

  def topic(event_id), do: "party:#{event_id}"

  def subscribe(event_id) do
    Phoenix.PubSub.subscribe(@pubsub, topic(event_id))
  end

  def broadcast_peer_joined(event_id, peer) do
    Phoenix.PubSub.broadcast(@pubsub, topic(event_id), {:peer_joined, peer})
  end

  def broadcast_peer_removed(event_id, peer_id) do
    Phoenix.PubSub.broadcast(@pubsub, topic(event_id), {:peer_removed, peer_id})
  end

  def broadcast_handshake_status(event_id, connected_keys) do
    Phoenix.PubSub.broadcast(@pubsub, topic(event_id), {:handshake_status, connected_keys})
  end

  def broadcast_event_updated(event_id, event) do
    Phoenix.PubSub.broadcast(@pubsub, topic(event_id), {:event_updated, event})
  end
end
