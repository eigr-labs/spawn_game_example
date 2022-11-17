defmodule Dice.Game.Match.StateHelper do
  @moduledoc """
  Defines match state definition and accessor helpers
  """

  alias Dice.Game.{MatchState, Board}

  @doc """
  Gets the board snapshot for a specific player
  """
  @spec get_snapshot(%MatchState{}, binary()) :: Board.Snapshot.t()
  def get_snapshot(state, player_ref) do
    player_ref = get_player_ref(state, player_ref)

    state.players |> Map.get(player_ref) |> Board.unwrap_snapshot()
  end

  @doc """
  Gets the enemy board snapshot based on a specific player
  """
  @spec get_enemy_snapshot(%MatchState{}, binary()) :: Board.Snapshot.t()
  def get_enemy_snapshot(state, player_ref) do
    player_ref = get_player_ref(state, player_ref)

    state.players
    |> Map.delete(player_ref)
    |> then(fn
      players when is_map(players) ->
        players |> Map.values() |> List.first() |> Board.unwrap_snapshot()

      _ ->
        nil
    end)
  end

  @doc """
  Checks if its the turn of the current player
  """
  @spec my_turn?(%MatchState{}, binary()) :: boolean()
  def my_turn?(%MatchState{} = state, player_ref) do
    player_ref = get_player_ref(state, player_ref)

    state.player_turn_ref == player_ref
  end

  def get_player_ref(state, nil), do: state.players |> Map.keys() |> List.first()
  def get_player_ref(_state, player_ref), do: player_ref

  def player_by_ref(state, ref) do
    Map.get(state.players, ref)
  end

  def enemy_by_ref(state, ref) do
    case state.players do
      %{^ref => _snapshot} -> state.players |> Map.delete(ref) |> Map.values() |> List.first()
      _ -> nil
    end
  end

  def get_enemy_ref(state, ref) do
    case state.players do
      %{^ref => _snapshot} -> state.players |> Map.delete(ref) |> Map.keys() |> List.first()
      _ -> nil
    end
  end

  def finished?(%{status: status}), do: finished?(status)

  def finished?(status) do
    status in [:finished, :finished_draw]
  end

  def new_player(ref) do
    %{ref => Board.new() |> Board.get_snapshot()}
  end

  def put_turn_or_winner_state(state, player_ref, enemy_ref, winner) do
    case winner do
      nil ->
        put_state_turn_ref(state, enemy_ref)

      :draw ->
        put_state(state, status: :finished_draw)

      :player ->
        state
        |> put_state(loser_ref: enemy_ref, winner_ref: player_ref, status: :finished)

      :enemy ->
        state
        |> put_state(loser_ref: player_ref, winner_ref: enemy_ref, status: :finished)
    end
  end

  def put_state_turn_ref(state, player_ref) do
    put_state(state, player_turn_ref: player_ref, player_turn_dice: Board.roll_dice())
  end

  def put_state(nil, attrs) do
    put_state(MatchState.new(), attrs)
  end

  def put_state(%MatchState{} = state, attrs) do
    datetime = DateTime.now!("Etc/UTC") |> DateTime.to_unix(:millisecond)

    attrs = attrs |> Map.new() |> Map.put(:updated_at, datetime)

    struct(state, attrs)
  end
end
