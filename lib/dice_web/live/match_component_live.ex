defmodule DiceWeb.Live.MatchComponent do
  use DiceWeb, :live_component

  def render(assigns) do
    Phoenix.View.render(DiceWeb.LiveComponentsView, "match.html", assigns)
  end
end
