defmodule Dice.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start SpawnSDK system
      {
        SpawnSdk.System.Supervisor,
        system: "game-system",
        actors: [
          Dice.Matchmaking.Actor
        ],
        extenal_subscribers: []
      },

      # Start the Telemetry supervisor
      DiceWeb.Telemetry,

      # Start the PubSub system
      Supervisor.child_spec({Phoenix.PubSub, name: Dice.PubSub}, id: :dice_pubsub),

      # Start the Endpoint (http/https)
      DiceWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Dice.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    DiceWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
