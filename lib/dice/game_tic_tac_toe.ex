defmodule Dice.GameTicTacToe do
  @moduledoc """
  Defines Game context functions
  """

  @type match_ref :: binary()
  @type player_ref :: binary()
  @type dice_number :: number()

  alias SpawnSdk.Channel.Subscriber

  def create(match_ref, matchmaking_ref) do
    payload = %{matchmakingRef: matchmaking_ref}

    SpawnSdk.invoke(match_ref,
      system: "game-system",
      ref: "tic_tac_toe",
      action: "create",
      payload: payload
    )
  end

  @doc """
  Subscribes self pid to Match Events, being:
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
    payload = %{playerRef: player_ref}
    SpawnSdk.invoke(match_ref, system: "game-system", action: "join", payload: payload)
  end

  def prepare_start(_match_ref) do
    :ok
  end

  def start(match_ref) do
    SpawnSdk.invoke(match_ref, system: "game-system", action: "start")
  end

  def get_current_state(match_ref) do
    {:ok, state} = SpawnSdk.invoke(match_ref, system: "game-system", action: "get_state")

    state
  end

  def play(match_ref, player_ref, row, col) do
    payload = %{playerRef: player_ref, row: row, col: col}

    SpawnSdk.invoke(match_ref, system: "game-system", action: "play", payload: payload)
  end
end
