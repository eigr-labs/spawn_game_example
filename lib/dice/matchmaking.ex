defmodule Dice.Matchmaking do
  @moduledoc """
  Defines matchmaking functions
  """

  alias Dice.Matchmaking
  alias SpawnSdk.Channel.Subscriber

  @spec subscribe(binary()) :: :ok | {:error, term()}
  def subscribe(matchmaking_ref \\ "default_matchmaking") do
    Subscriber.subscribe("matchmaking:#{matchmaking_ref}")
  end

  @spec unsubscribe(binary()) :: :ok
  def unsubscribe(matchmaking_ref \\ "default_matchmaking") do
    Subscriber.unsubscribe("matchmaking:#{matchmaking_ref}")
  end

  @doc """
  Enqueue player for a matchmaking
  """
  def enqueue(player_ref, matchmaking_ref \\ "default_matchmaking") do
    payload = %Matchmaking.PlayerRefInput{ref: player_ref}

    SpawnSdk.invoke(matchmaking_ref,
      ref: Dice.Matchmaking.Actor,
      system: "game-system",
      action: "enqueue",
      payload: payload
    )
  end

  @doc """
  Dequeue player for a matchmaking
  """
  def dequeue(player_ref, matchmaking_ref \\ "default_matchmaking") do
    payload = %Matchmaking.PlayerRefInput{ref: player_ref}

    SpawnSdk.invoke(matchmaking_ref,
      ref: Dice.Matchmaking.Actor,
      system: "game-system",
      action: "dequeue",
      payload: payload
    )
  end

  @doc """
  Manual matchmaking
  """
  def manual(player_ref, match_ref, matchmaking_ref \\ "default_matchmaking") do
    payload = %Matchmaking.ManualMatchmakingInput{match_id: match_ref, player_ref: player_ref}

    SpawnSdk.invoke(matchmaking_ref,
      ref: Dice.Matchmaking.Actor,
      system: "game-system",
      action: "manual",
      payload: payload
    )
  end

  @doc """
  Get a player's current game
  """
  def get_active_game(player_ref, matchmaking_ref \\ "default_matchmaking") do
    payload = %Matchmaking.PlayerRefInput{ref: player_ref}

    SpawnSdk.invoke(matchmaking_ref,
      ref: Dice.Matchmaking.Actor,
      system: "game-system",
      action: "get_active_game",
      payload: payload
    )
  end
end
