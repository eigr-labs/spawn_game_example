defmodule DiceWeb.Live.GamePage do
  use DiceWeb, :live_view

  defmodule MatchAssigns do
    defstruct [
      :id,
      :scheduled_to,
      :status,
      :board_snapshot,
      :opposite_board_snapshot,
      :my_turn,
      :dice,
      :winner,
      :finished
    ]
  end

  alias Dice.Game
  alias Dice.Game.{MatchState, MatchEvent}
  alias Dice.Game.Match.StateHelper
  alias Dice.Matchmaking

  def render(assigns) do
    Phoenix.View.render(DiceWeb.PageView, "game.html", assigns)
  end

  def mount(_params, session, socket) do
    player_id = session["player_id"] || UUID.uuid4(:default)
    match_ref = session["match_id"] || UUID.uuid4(:default)

    socket =
      socket
      |> initialize(player_id, match_ref)
      |> assign(%{current_account: nil, signed_in: false})

    {:ok, socket}
  end

  def handle_event("row_click", %{"row" => row_num}, socket) do
    %{player_id: player_id, match: match} = socket.assigns

    if match.status == :playing do
      Dice.Game.play(match.id, player_id, String.to_integer(row_num))
    end

    {:noreply, socket}
  end

  def handle_event("rematch", _params, socket) do
    %{match: %{id: match_ref}, player_id: player_id} = socket.assigns

    socket = initialize(socket, player_id, match_ref)

    {:noreply, socket}
  end

  def handle_info({:receive, %MatchEvent{event: "join", state: %MatchState{} = state}}, socket) do
    %{player_id: player_id, match: match} = socket.assigns

    match =
      match
      |> match_assign_play_states(state, player_id)
      |> match_assign_scheduled(state.scheduled_to)
      |> match_assign(:status, state.status)

    socket = assign(socket, :match, match)

    {:noreply, socket}
  end

  def handle_info(
        {:receive, %MatchEvent{event: "prepare_start", state: %MatchState{} = state}},
        socket
      ) do
    %{match: match} = socket.assigns

    match =
      match
      |> match_assign_scheduled(state.scheduled_to)
      |> match_assign(:status, state.status)

    socket = assign(socket, :match, match)

    {:noreply, socket}
  end

  def handle_info({:receive, %MatchEvent{event: "start", state: %MatchState{} = state}}, socket) do
    %{player_id: player_id, match: match} = socket.assigns

    match =
      match
      |> match_assign_play_states(state, player_id)
      |> match_assign(:status, state.status)

    socket = assign(socket, :match, match)

    {:noreply, socket}
  end

  def handle_info({:receive, %MatchEvent{event: "play", state: %MatchState{} = state}}, socket) do
    %{player_id: player_id, match: match} = socket.assigns

    match =
      match
      |> match_assign_play_states(state, player_id)
      |> match_assign(:status, state.status)

    socket = assign(socket, :match, match)

    {:noreply, socket}
  end

  def handle_info({:receive, %MatchEvent{event: "finish", state: %MatchState{} = state}}, socket) do
    %{player_id: player_id, match: match} = socket.assigns

    match =
      match
      |> match_assign_play_states(state, player_id)
      |> match_assign(:winner, state.winner_ref)
      |> match_assign(:finished, true)

    socket = assign(socket, :match, match)

    :ok = Game.unsubscribe(match.id)

    {:noreply, socket}
  end

  def handle_info({:receive, %MatchEvent{event: "draw", state: state}}, socket) do
    %{player_id: player_id, match: match} = socket.assigns

    match =
      match
      |> match_assign_play_states(state, player_id)
      |> match_assign(:winner, nil)
      |> match_assign(:finished, true)

    socket = assign(socket, :match, match)

    :ok = Game.unsubscribe(match.id)

    {:noreply, socket}
  end

  def handle_info(_event, socket) do
    {:noreply, socket}
  end

  defp initialize(socket, player_id, match_ref) do
    Matchmaking.manual(player_id, match_ref)

    :ok = Game.subscribe(match_ref)

    socket =
      case Game.join(match_ref, player_id) do
        :full ->
          socket
          |> assign(:player_id, nil)
          |> assign(:spectate, true)

        _joined ->
          Game.prepare_start(match_ref)

          socket
          |> assign(:player_id, player_id)
          |> assign(:spectate, false)
      end

    state = Game.get_current_state(match_ref)

    match =
      %MatchAssigns{id: match_ref}
      |> match_assign_play_states(state, socket.assigns.player_id)
      |> match_assign_scheduled(state.scheduled_to)
      |> match_assign(:status, state.status)

    assign(socket, :match, match)
  end

  defp match_assign(match, key, value) do
    Map.put(match, key, value)
  end

  defp match_assign_scheduled(match, nil) do
    Map.put(match, :scheduled_to, nil)
  end

  defp match_assign_scheduled(match, value) do
    value = DateTime.from_unix!(value, :millisecond)
    Map.put(match, :scheduled_to, value)
  end

  defp match_assign_play_states(match, state, player_id) do
    match
    |> Map.put(:board_snapshot, StateHelper.get_snapshot(state, player_id))
    |> Map.put(:opposite_board_snapshot, StateHelper.get_enemy_snapshot(state, player_id))
    |> Map.put(:my_turn, StateHelper.my_turn?(state, player_id))
    |> Map.put(:player_turn_ref, state.player_turn_ref)
    |> Map.put(:dice, state.player_turn_dice)
    |> Map.put(:winner, nil)
    |> Map.put(:finished, false)
  end
end
