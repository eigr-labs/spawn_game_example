defmodule DiceWeb.Live.BoardComponent do
  use DiceWeb, :live_component

  def render(assigns) do
    Phoenix.View.render(DiceWeb.LiveComponentsView, "board.html", assigns)
  end

  def board(assigns) do
    ~H"""
    <%= for {rows, row} <- Enum.with_index(assigns.board) do %>
      <div class={"rr r-#{row} board-rows"}>
        <%= for {value, col} <- Enum.with_index(rows) do %>
          <div class={"cc c-#{col}"} phx-value-row={row} phx-value-col={col} phx-click="click">
            <h2 class="spot blank"><%= get_label(value) %></h2>
          </div>
        <% end %>
      </div>
    <% end %>
    """
  end

  defp get_label(0), do: "X"
  defp get_label(1), do: "O"
  defp get_label(nil), do: ""
end
