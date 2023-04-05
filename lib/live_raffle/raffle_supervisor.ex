defmodule LiveRaffle.RaffleSupervisor do
  use DynamicSupervisor
  alias LiveRaffle.Raffle

  alias LiveRaffle.RaffleWorker

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl DynamicSupervisor
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_child(%{"raffle_name" => raffle_name} = params) do
    changeset =
      %Raffle{}
      |> Raffle.changeset(params)
      |> Map.put(:action, :validate)

    case changeset.valid? do
      true ->
        spec = {RaffleWorker, raffle_name}
        DynamicSupervisor.start_child(__MODULE__, spec)
        Phoenix.PubSub.broadcast(LiveRaffle.PubSub, "live_raffle", {:raffle_created, raffle_name})
        {:ok, raffle_name}

      _ ->
        {:error, changeset}
    end
  end

  def ongoing_raffles(), do:
    RaffleRegistry
    |> Registry.select([{{:"$1", :_, :_}, [], [:"$1"]}])
    |> Enum.map(fn raffle_name ->
      String.trim_leading(raffle_name, "raffle_")
    end)
end
