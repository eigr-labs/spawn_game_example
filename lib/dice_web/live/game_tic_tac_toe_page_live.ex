defmodule DiceWeb.Live.GameTicTacToePage do
  use DiceWeb, :live_view

  defmodule MatchAssigns do
    defstruct [
      :id,
      :board,
      :my_turn,
      :player_turn_ref,
      :status,
      :winner,
      :finished
    ]
  end

  alias Dice.GameTicTacToe, as: Game
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

  def handle_event("click", %{"row" => row, "col" => col}, socket) do
    %{player_id: player_id, match: match} = socket.assigns

    if match.status == "playing" do
      Game.play(match.id, player_id, String.to_integer(row), String.to_integer(col))
    end

    {:noreply, socket}
  end

  def handle_event("rematch", _params, socket) do
    %{match: %{id: match_ref}, player_id: player_id} = socket.assigns

    socket = initialize(socket, player_id, match_ref)

    {:noreply, socket}
  end

  def handle_info({:receive, %{event: "join", state: state}}, socket) do
    %{player_id: player_id, match: match} = socket.assigns

    match =
      match
      |> match_assign_play_states(state, player_id)
      |> match_assign(:status, state.status)

    socket = assign(socket, :match, match)

    {:noreply, socket}
  end

  def handle_info({:receive, %{event: "play", state: state}}, socket) do
    %{player_id: player_id, match: match} = socket.assigns

    match =
      match
      |> match_assign_play_states(state, player_id)
      |> match_assign(:status, state.status)

    socket = assign(socket, :match, match)

    {:noreply, socket}
  end

  def handle_info({:receive, %{event: "finished", state: state}}, socket) do
    %{player_id: player_id, match: match} = socket.assigns

    match =
      match
      |> match_assign_play_states(state, player_id)
      |> match_assign(:winner, state.playerWinner)
      |> match_assign(:finished, true)

    socket = assign(socket, :match, match)

    :ok = Game.unsubscribe(match.id)

    {:noreply, socket}
  end

  def handle_info({:receive, %{event: "finished_draw", state: state}}, socket) do
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

    {:ok, %{players: players}} = Game.join(match_ref, player_id)
    in_match_player = Enum.find(players, & &1 == player_id)

    socket = socket
    |> assign(:player_id, in_match_player)
    |> assign(:spectate, is_nil(in_match_player))

    state = Game.get_current_state(match_ref)

    match =
      %MatchAssigns{id: match_ref}
      |> match_assign_play_states(state, in_match_player)

    assign(socket, :match, match)
  end

  defp match_assign(match, key, value) do
    Map.put(match, key, value)
  end

  defp match_assign_play_states(match, state, player_id) do
    match
    |> Map.put(:board, state.board)
    |> Map.put(:my_turn, state.playerTurn == player_id)
    |> Map.put(:player_turn_ref, state.playerTurn)
    |> Map.put(:status, state.status)
    |> Map.put(:winner, nil)
    |> Map.put(:finished, false)
  end
end
