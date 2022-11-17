defmodule DiceWeb.Live.IndexPage do
  use DiceWeb, :live_view

  alias Dice.Matchmaking
  alias Dice.Matchmaking.MatchFoundEvent

  def render(assigns) do
    Phoenix.View.render(DiceWeb.PageView, "index.html", assigns)
  end

  def mount(_params, session, socket) do
    socket =
      socket
      |> assign(:anonymous_player, session["anonymous_player"])
      |> assign(:match_id, nil)
      |> assign(:player_id, nil)
      |> assign(:current_account, nil)
      |> assign(:signed_in, false)
      |> assign(:playable, false)
      |> assign(:linked_matchmaking, nil)

    player_id = get_player_id(socket)

    socket =
      case Matchmaking.get_active_game(player_id) do
        {:ok, %{match_id: match_id}} when is_nil(match_id) or match_id == "" -> socket
        {:error, _} -> socket
        {:ok, %{match_id: match_id}} -> assign_start_playing(socket, match_id, player_id)
      end

    {:ok, socket}
  end

  def handle_info(:sign_in, socket) do
    {:noreply, assign(socket, :signed_in, true)}
  end

  def handle_info(:sign_out, socket) do
    {:noreply, assign(socket, :signed_in, false)}
  end

  def handle_info({:match_found, match_id}, socket) do
    socket =
      socket
      |> assign(:playable, true)
      |> assign(:match_id, match_id)
      |> assign_remove_matchmaking()

    {:noreply, socket}
  end

  def handle_event("join_matchmaking", _params, socket) do
    %{linked_matchmaking: pid} = socket.assigns

    socket =
      if is_nil(pid) do
        player_id = get_player_id(socket)
        parent_pid = self()

        pid =
          spawn_link(fn ->
            Process.flag(:trap_exit, true)

            Matchmaking.subscribe()
            Matchmaking.enqueue(player_id)

            receive do
              {:receive, %MatchFoundEvent{match_id: match_id, pair: pair}} ->
                if player_id in pair do
                  send(parent_pid, {:match_found, match_id})
                end

              {:EXIT, _from, _reason} ->
                Matchmaking.unsubscribe()
                Matchmaking.dequeue(player_id)
            end
          end)

        socket
        |> assign(:linked_matchmaking, pid)
        |> assign(:player_id, player_id)
      else
        socket
      end

    {:noreply, socket}
  end

  def handle_event("cancel_matchmaking", _params, socket) do
    {:noreply, assign_remove_matchmaking(socket)}
  end

  def handle_event("create_room", params, socket) do
    %{match_id: match_id} = socket.assigns

    player_id = get_player_id(socket)

    match_id = match_id || params["match_id"] || UUID.uuid4(:hex)

    socket =
      socket
      |> assign(:playable, true)
      |> assign(:match_id, match_id)
      |> assign(:player_id, player_id)
      |> assign_remove_matchmaking()

    {:noreply, socket}
  end

  defp assign_start_playing(socket, match_id, player_id) do
    socket
    |> assign(:playable, true)
    |> assign(:match_id, match_id)
    |> assign(:player_id, player_id)
    |> assign_remove_matchmaking()
  end

  defp assign_remove_matchmaking(socket) do
    %{linked_matchmaking: linked_matchmaking_pid} = socket.assigns

    if linked_matchmaking_pid do
      Process.exit(linked_matchmaking_pid, :normal)
    end

    assign(socket, :linked_matchmaking, nil)
  end

  defp get_player_id(socket) do
    %{current_account: current_account, anonymous_player: anonymous_player, signed_in: signed_in?} =
      socket.assigns

    if current_account && signed_in? do
      current_account
    else
      anonymous_player
    end
  end
end
