defmodule Dice.Game do
  @moduledoc """
  Defines Game context functions
  """

  @type match_ref :: binary()
  @type player_ref :: binary()
  @type dice_number :: number()

  alias SpawnSdk.Channel.Subscriber
  alias Dice.Game.{PlayMatchAction, MatchCreateAction, JoinMatchAction, MatchState}

  def create(match_ref, matchmaking_ref) do
    payload = %MatchCreateAction{matchmaking_ref: matchmaking_ref}

    SpawnSdk.invoke(match_ref,
      system: "game-system",
      ref: Dice.Game.MatchActor,
      action: "create",
      payload: payload
    )
  end

  @doc """
  Subscribes self pid to Match Events, being:

  ```
  %MatchEvent{event: :join, state: state}
  %MatchEvent{event: :prepare_start, state: state}
  %MatchEvent{event: :start, state: state}
  %MatchEvent{event: :play, state: state}
  %MatchEvent{event: :finish, state: state}
  %MatchEvent{event: :draw, state: state}
  ```
  """
  @spec subscribe(match_ref) :: :ok | {:error, term()}
  def subscribe(match_ref) do
    Subscriber.subscribe("match:#{match_ref}")
  end

  @spec unsubscribe(match_ref) :: :ok
  def unsubscribe(match_ref) do
    Subscriber.unsubscribe("match:#{match_ref}")
  end

  def join(match_ref, player_ref) do
    payload = %JoinMatchAction{player_ref: player_ref}
    SpawnSdk.invoke(match_ref, system: "game-system", action: "join", payload: payload)
  end

  def prepare_start(match_ref) do
    SpawnSdk.invoke(match_ref, system: "game-system", action: "prepare_start")
  end

  def start(match_ref) do
    SpawnSdk.invoke(match_ref, system: "game-system", action: "start")
  end

  @spec get_current_state(match_ref) :: %MatchState{}
  def get_current_state(match_ref) do
    {:ok, state} = SpawnSdk.invoke(match_ref, system: "game-system", action: "get_state")

    state
  end

  def play(match_ref, player_ref, row_index) do
    payload = %PlayMatchAction{player_ref: player_ref, row_index: row_index}

    SpawnSdk.invoke(match_ref, system: "game-system", action: "play", payload: payload)
  end
end
