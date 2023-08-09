defmodule Dice.MixProject do
  use Mix.Project

  def project do
    [
      app: :dice,
      version: "1.0.0-rc.18",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      releases: releases()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Dice.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.6.11"},
      {:phoenix_html, "~> 3.0"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 0.17.5"},
      {:floki, ">= 0.30.0", only: :test},
      {:phoenix_live_dashboard, "~> 0.6"},
      {:esbuild, "~> 0.4", runtime: Mix.env() == :dev},
      {:jason, "~> 1.2"},
      {:plug_cowboy, "~> 2.5"},
      {:uuid, "~> 1.1"},
      {:spawn_sdk, "== 1.0.0-rc.18"},
      {:spawn_statestores_mysql, "== 1.0.0-rc.18"}
    ]
  end

  defp aliases do
    [
      setup: ["deps.get"],
      "assets.deploy": ["esbuild default --minify", "phx.digest"]
    ]
  end

  defp releases do
    [
      dice: [
        include_executables_for: [:unix],
        include_erts: Mix.env() == :prod,
        applications: [dice: :permanent],
        steps: [:assemble]
      ]
    ]
  end
end
