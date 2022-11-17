defmodule DiceWeb.Live.BoardComponent do
  use DiceWeb, :live_component

  def render(assigns) do
    Phoenix.View.render(DiceWeb.LiveComponentsView, "board.html", assigns)
  end

  def rows_sum(assigns) do
    ~H"""
    <div class="row sum-rows">
      <%= for sum <- @rows_sum do %>
        <div class="column">
          <h2 class="spot blank"><%= sum %></h2>
        </div>
      <% end %>
    </div>
    """
  end

  def dice_spots(assigns) do
    block_col = fn col ->
      ~H"""
        <%= for num <- if @enemy, do: col, else: Enum.reverse(col) do %>
          <div class="w-full spot">
            <%= if num != 0 do %>
              <img src={"/images/#{num}.png"} width="64" alt="dice" />
            <% else %>
              <div class="block-empty"/>
            <% end %>
          </div>
        <% end %>
      """
    end

    ~H"""
    <%= for {col, index} <- Enum.with_index(@snapshot.board) do %>
      <%= if not @match.my_turn || @enemy || @match.finished do %>
        <div class="column enemy">
          <%= block_col.(col) %>
        </div>
      <% else %>
        <div class="column" phx-value-row={index} phx-click="row_click">
          <%= block_col.(col) %>
        </div>
      <% end %>
    <% end %>
    """
  end
end
