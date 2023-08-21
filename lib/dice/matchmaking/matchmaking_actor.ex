defmodule Dice.Matchmaking.Actor do
  @moduledoc """
  Defines matchmaking actor iteractions
  """
  use SpawnSdk.Actor,
    kind: :unamed,
    stateful: true,
    state_type: Dice.Matchmaking.MatchmakingState

  require Logger

  alias Dice.GameTicTacToe, as: Game
  alias Dice.Matchmaking.StateHelper

  alias Dice.Matchmaking.{
    MatchmakingState,
    PlayerRefInput,
    MatchPairInput,
    ManualMatchmakingInput,
    MatchIdResponse,
    MatchFoundEvent
  }

  defact init(%Context{} = ctx) do
    matchmaking_id = ctx.self.name
    state = ctx.state || %MatchmakingState{id: matchmaking_id, queue: [], open_matches: %{}}

    Logger.info("Initialized matchmaking...", label: matchmaking_id)

    Value.noreply_state!(state)
  end

  defact enqueue(%PlayerRefInput{ref: player_ref}, %Context{state: state} = ctx) do
    matchmaking_id = ctx.self.name

    new_state = StateHelper.queue_player(state, player_ref)
    pair = Enum.slice(new_state.queue, 0..1)

    if Enum.count(pair) == 2 do
      Logger.info("Found pair in matchmaking #{inspect(pair)}", label: matchmaking_id)

      Value.of()
      |> Value.state(new_state)
      |> Value.effect(SideEffect.to(matchmaking_id, "start_game", StateHelper.build_pair(pair)))
      |> Value.noreply!()
    else
      Logger.info("Player enqueued #{inspect(player_ref)}", label: matchmaking_id)

      Value.noreply_state!(new_state)
    end
  end

  defact dequeue(%PlayerRefInput{ref: player_ref}, %Context{state: state} = ctx) do
    matchmaking_id = ctx.self.name

    Logger.info("Player dequeued #{inspect(player_ref)}", label: matchmaking_id)

    new_state = StateHelper.dequeue_player(state, player_ref)
    Value.noreply_state!(new_state)
  end

  defact manual(%ManualMatchmakingInput{} = input, %Context{state: state} = ctx) do
    matchmaking_id = ctx.self.name

    match_not_found = Map.get(state.open_matches, input.match_id) |> is_nil()
    new_state = StateHelper.maybe_add_player_to_match(state, input.match_id, input.player_ref)

    if match_not_found do
      Logger.info(
        "Manual game creation started by: #{inspect(input.player_ref)} for match_id: #{inspect(input.match_id)}",
        label: matchmaking_id
      )

      Game.create(input.match_id, matchmaking_id)
    end

    Value.noreply_state!(new_state)
  end

  defact get_active_game(%PlayerRefInput{ref: player_ref}, %Context{state: state}) do
    {match_id, _pair} = StateHelper.find_match_for_player(state, player_ref)

    %Value{}
    |> Value.of(%MatchIdResponse{match_id: match_id || ""}, state)
    |> Value.reply!()
  end

  defact match_finished(%{ref: match_id}, %Context{state: state} = ctx) do
    matchmaking_id = ctx.self.name

    Logger.info("Match finished, removing match from matchmaking: #{inspect(match_id)}",
      label: matchmaking_id
    )

    new_state = StateHelper.remove_match(state, match_id)

    Value.noreply_state!(new_state)
  end

  defact start_game(%MatchPairInput{} = pair_input, %Context{state: state} = ctx) do
    matchmaking_id = ctx.self.name
    match_id = UUID.uuid4()

    %{player_ref_one: p1, player_ref_two: p2} = pair_input

    match_not_found = Map.get(state.open_matches, match_id) |> is_nil()

    if match_not_found do
      Logger.info("Starting game from matchmaking: #{inspect(match_id)}", label: matchmaking_id)

      Game.create(match_id, matchmaking_id)

      match_found_event = %MatchFoundEvent{
        match_id: match_id,
        pair: StateHelper.pair_input_to_list(pair_input)
      }

      new_state =
        state
        |> StateHelper.maybe_add_player_to_match(match_id, p1)
        |> StateHelper.maybe_add_player_to_match(match_id, p2)
        |> StateHelper.dequeue_player(p1)
        |> StateHelper.dequeue_player(p2)

      Value.of()
      |> Value.state(new_state)
      |> Value.broadcast(Broadcast.to("matchmaking:#{matchmaking_id}", match_found_event))
      |> Value.noreply!()
    else
      Value.noreply_state!(state)
    end
  end
end
