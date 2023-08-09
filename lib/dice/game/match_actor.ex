defmodule Dice.Game.MatchActor do
  use SpawnSdk.Actor,
    kind: :unamed,
    stateful: true,
    state_type: Dice.Game.MatchState,
    deactivate_timeout: 60 * 60 * 1000

  require Logger
  import Dice.Game.Match.StateHelper

  alias Dice.Game.{
    Board,
    JoinMatchAction,
    MatchEvent,
    PlayMatchAction,
    Snapshot,
    MatchCreateAction
  }

  alias Dice.Matchmaking.MatchRefInput

  @finished_statuses [:finished, :finished_draw]
  @start_in_seconds 5

  defact create(%MatchCreateAction{matchmaking_ref: matchmaking_ref}, %Context{} = ctx) do
    match_id = ctx.self.name

    Logger.info(
      "Initializing match for match_id: #{inspect(match_id)} (from #{inspect(matchmaking_ref)})",
      label: "#{__MODULE__}"
    )

    state = initialize_state(ctx.state, match_id, matchmaking_ref)

    Value.noreply_state!(state)
  end

  defact stop(%Context{state: state} = ctx) do
    match_id = ctx.self.name
    event = if state.status == :finished_draw, do: :draw, else: :finish

    Logger.info(
      "Match is finished. Status: #{inspect(state.status)}, winner: #{inspect(state.winner_ref)}",
      label: "#{__MODULE__}"
    )

    brand_new_match = initialize_state(nil, match_id, state.matchmaking_ref)

    Value.of()
    |> Value.state(brand_new_match)
    |> value_broadcast(event, state)
    |> Value.effect(
      SideEffect.to(state.matchmaking_ref, "match_finished", %MatchRefInput{ref: match_id})
    )
    |> Value.noreply!()
  end

  defact start(%Context{state: state}) do
    cond do
      state.status != :starting ->
        Value.noreply_state!(state)

      true ->
        starting_player_ref = state.players |> Map.keys() |> Enum.random()

        new_state =
          state
          |> put_state(status: :playing)
          |> put_state(scheduled_to: nil)
          |> put_state_turn_ref(starting_player_ref)

        Value.of()
        |> Value.state(new_state)
        |> value_broadcast(:start, new_state)
        |> Value.noreply!()
    end
  end

  defact prepare_start(%Context{state: state} = ctx) do
    match_id = ctx.self.name

    cond do
      Enum.count(state.players) != 2 ->
        Value.noreply_state!(state)

      state.status in [:starting, :playing, :finished, :finished_draw] ->
        Value.noreply_state!(state)

      true ->
        scheduled_to = DateTime.add(DateTime.now!("Etc/UTC"), @start_in_seconds, :second)

        new_state =
          state
          |> put_state(status: :starting)
          |> put_state(scheduled_to: DateTime.to_unix(scheduled_to, :millisecond))

        Value.of()
        |> Value.state(new_state)
        |> Value.effect(SideEffect.to(match_id, "start", nil, delay: @start_in_seconds * 1_000))
        |> value_broadcast(:prepare_start, new_state)
        |> Value.noreply!()
    end
  end

  defact join(%JoinMatchAction{player_ref: player_ref}, %Context{state: state}) do
    player_found = player_by_ref(state, player_ref)

    cond do
      not is_nil(player_found) ->
        Value.noreply_state!(state)

      Enum.count(state.players) == 2 ->
        Value.noreply_state!(state)

      true ->
        players = Map.merge(state.players, new_player(player_ref))

        # status = if Enum.count(players) == 2, do: :joined_last, else: :joined
        new_state = put_state(state, players: players)

        Value.of()
        |> Value.state(new_state)
        |> value_broadcast(:join, state)
        |> Value.noreply!()
    end
  end

  defact play(
           %PlayMatchAction{player_ref: player_ref, row_index: row_index},
           %Context{state: state} = ctx
         ) do
    match_id = ctx.self.name
    player = player_by_ref(state, player_ref)

    cond do
      state.status in @finished_statuses ->
        Value.noreply_state!(state)

      state.status != :playing ->
        Value.noreply_state!(state)

      state.player_turn_ref != player_ref ->
        Value.noreply_state!(state)

      Board.is_row_full?(player.board, row_index) ->
        Value.noreply_state!(state)

      true ->
        enemy = enemy_by_ref(state, player_ref)
        enemy_ref = get_enemy_ref(state, player_ref)

        {player_snapshot, enemy_snapshot, winner} =
          do_combat(player, enemy, row_index, state.player_turn_dice)

        players =
          state.players
          |> Map.replace(player_ref, player_snapshot)
          |> Map.replace(enemy_ref, enemy_snapshot)

        state =
          state
          |> put_state(players: players)
          |> put_turn_or_winner_state(player_ref, enemy_ref, winner)

        reply =
          Value.of()
          |> value_broadcast(:play, state)
          |> Value.state(state)

        if state.status in @finished_statuses do
          reply
          |> Value.effects([
            SideEffect.to(match_id, "stop")
          ])
        else
          reply
        end
        |> Value.noreply!()
    end
  end

  defp do_combat(%Snapshot{} = player, %Snapshot{} = enemy, row_index, dice_num) do
    player_snapshot = Board.push(player.board, row_index, dice_num) |> Board.get_snapshot()
    enemy_snapshot = Board.pop(enemy.board, row_index, dice_num) |> Board.get_snapshot()

    winner_status =
      if Board.finished?(player_snapshot.board) do
        cond do
          player_snapshot.total > enemy_snapshot.total -> :player
          player_snapshot.total < enemy_snapshot.total -> :enemy
          player_snapshot.total == enemy_snapshot.total -> :draw
        end
      end

    {player_snapshot, enemy_snapshot, winner_status}
  end

  defp initialize_state(state, match_id, matchmaking_ref) do
    datetime = DateTime.now!("Etc/UTC") |> DateTime.to_unix(:millisecond)

    put_state(state,
      id: match_id,
      matchmaking_ref: matchmaking_ref,
      created_at: datetime,
      status: :waiting_players
    )
  end

  defp value_broadcast(value, event, state) do
    Logger.info("Game event (#{inspect(state.id)}) sent #{inspect(event)}", label: "#{__MODULE__}")

    Value.broadcast(
      value,
      Broadcast.to("match:#{state.id}", %MatchEvent{
        event: Atom.to_string(event),
        state: state
      })
    )
  end
end
