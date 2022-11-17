defmodule DiceWeb.Router do
  use DiceWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {DiceWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :anonymous_player do
    plug :player_cookies
  end

  scope "/", DiceWeb do
    pipe_through [:browser, :anonymous_player]

    live "/", Live.IndexPage
  end

  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: DiceWeb.Telemetry
    end
  end

  @player_cookie "pcookie"
  def player_cookies(conn, _opts) do
    anonymous_player_loaded =
      conn
      |> fetch_cookies(signed: [@player_cookie])
      |> Map.get(:cookies)
      |> Map.get(@player_cookie)

    if anonymous_player_loaded do
      conn
      |> put_session("anonymous_player", anonymous_player_loaded)
    else
      anonymous_player_ref = UUID.uuid4(:hex)

      conn
      |> put_session("anonymous_player", anonymous_player_ref)
      |> put_resp_cookie(@player_cookie, anonymous_player_ref, sign: true)
    end
  end
end
