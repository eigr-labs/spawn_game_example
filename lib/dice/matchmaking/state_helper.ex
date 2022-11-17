defmodule Dice.Matchmaking.StateHelper do
  @moduledoc """
  Defines matchmaking state definition and accessor helpers
  """

  alias Dice.Matchmaking.{MatchmakingState, PlayerRefs, MatchPairInput}

  def build_pair([player_ref, player_ref2] = _pair) do
    %MatchPairInput{player_ref_one: player_ref, player_ref_two: player_ref2}
  end

  def pair_input_to_list(pair_input) do
    %MatchPairInput{player_ref_one: player_ref, player_ref_two: player_ref2} = pair_input

    [player_ref, player_ref2]
  end

  def queue_player(state, player_ref) do
    queue = (state.queue ++ [player_ref]) |> Enum.uniq()
    put_state(state, queue: queue)
  end

  def dequeue_player(state, player_ref) do
    queue = state.queue -- [player_ref]
    put_state(state, queue: queue)
  end

  def maybe_add_player_to_match(state, match_id, player_ref) do
    players = get_match_players(state, match_id)
    new_players = %PlayerRefs{refs: Enum.uniq(players ++ [player_ref])}
    open_matches = Map.put(state.open_matches, match_id, new_players)
    put_state(state, open_matches: open_matches)
  end

  def find_match_for_player(state, player_ref) do
    Enum.find(state.open_matches, {nil, nil}, fn
      {_key, %PlayerRefs{refs: pair}} ->
        player_ref in pair && Enum.count(pair) == 2

      _ ->
        false
    end)
  end

  def remove_match(state, match_id) do
    open_matches = Map.delete(state.open_matches, match_id)
    put_state(state, open_matches: open_matches)
  end

  defp get_match_players(state, match_id) do
    player_refs = Map.get(state.open_matches, match_id, %PlayerRefs{refs: []})

    player_refs.refs
  end

  defp put_state(%MatchmakingState{} = state, attrs) do
    struct(state, attrs)
  end
end
