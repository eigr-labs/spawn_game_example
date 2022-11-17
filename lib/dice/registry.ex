defmodule Dice.Registry do
  @moduledoc """
  Defines a distributed registry for all process
  """
  use Horde.Registry

  def child_spec() do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [%{}]}
    }
  end

  @doc false
  def start_link(_) do
    Horde.Registry.start_link(
      __MODULE__,
      [
        keys: :unique,
        members: :auto,
        process_redistribution: :passive
      ],
      name: __MODULE__
    )
  end

  @doc """
  Get Process if this is alive.
  """
  def lookup(actor_name, for_module \\ Dice.Game.Match) do
    Horde.Registry.lookup(__MODULE__, {actor_name, for_module})
  end

  @impl true
  def init(args) do
    Horde.Registry.init(args)
  end
end
