defmodule LiveRaffle.RaffleWorker do
  use GenServer, restart: :transient
  alias LiveRaffle.Person

  def start_link(raffle_name) do
    initial_state = %{raffle_name: raffle_name, people: %{}, open: true}
    GenServer.start_link(__MODULE__, initial_state, name: process_name(raffle_name))
  end

  @impl GenServer
  def init(initial_state) do
    {:ok, initial_state}
  end

  def add_person(raffle_name, person_name) do
    GenServer.call(process_name(raffle_name), {:add_person, person_name})
  end

  def remove_person(raffle_name, person_name) do
    GenServer.call(process_name(raffle_name), {:remove_person, person_name})
  end

  def get_people(raffle_name) do
    GenServer.call(process_name(raffle_name), :get_people)
  end

  def toggle_status(raffle_name) do
    GenServer.call(process_name(raffle_name), :toggle_status)
  end

  def start_draw(raffle_name) do
    GenServer.call(process_name(raffle_name), :start_draw)
  end

  def process_name(raffle_name),
    do: {:via, Registry, {RaffleRegistry, "raffle_#{raffle_name}"}}

  @impl GenServer
  def handle_call({:add_person, %{"person_name" => person_name} = params}, _from, %{people: people} = state) do
    name_taken =
      people
      |> Map.keys()
      |> Enum.any?(fn existing_name ->
        sanitize_name(person_name) == sanitize_name(existing_name)
      end)
    changeset =
      %Person{}
      |> Person.changeset(params |> Map.put("name_taken", name_taken))
      |> Map.put(:action, :validate)

    case changeset.valid? do
        true ->
          Phoenix.PubSub.broadcast(LiveRaffle.PubSub, state.raffle_name, {:person_added, person_name})
          {:reply, {:ok, person_name}, %{state | people: Map.put(people, person_name, true)}}

        _ ->
          {:reply, {:error, changeset}, state}
    end
  end

  @impl GenServer
  def handle_call({:remove_person, person_name}, _from, %{people: people} = state) do
    Phoenix.PubSub.broadcast(LiveRaffle.PubSub, state.raffle_name, {:person_removed, person_name})
    {:reply, {:ok, person_name}, %{state | people: Map.delete(people, person_name)}}
  end


  @impl GenServer
  def handle_call(:get_people, _from, %{people: people, open: open} = state), do:
    {:reply, {:ok, people, open}, state}

  @impl GenServer
  def handle_call(:toggle_status, _from, %{open: open} = state) do
    new_status = !open
    Phoenix.PubSub.broadcast(LiveRaffle.PubSub, state.raffle_name, {:status_changed, new_status})
    {:reply, {:ok, new_status}, %{state | open: new_status}}
  end

  @impl GenServer
  def handle_call(:start_draw, _from, state) do
    Process.sleep(1_500)
    Phoenix.PubSub.broadcast(LiveRaffle.PubSub, state.raffle_name, :raffle_started)

    Process.send_after(self(), :start_draw, 3_000)
    {:reply, :ok, state}
  end

  @impl GenServer
  def handle_info(:start_draw, %{people: people} = state) do
    nr_active_people =
      people
      |> Map.values()
      |> Enum.count(fn status -> status == true end)

    if nr_active_people >= 2 do
      Process.send_after(self(), :start_draw, 3_000)
      {person_name, _status} = Enum.random(people)
      Phoenix.PubSub.broadcast(LiveRaffle.PubSub, state.raffle_name, {:person_deactivated, person_name})
      {:noreply, %{state | people: Map.put(people, person_name, false)}}
    else
      {winner, _status} = Enum.find(people, fn {_name, status} -> status == true  end)

      Phoenix.PubSub.broadcast(LiveRaffle.PubSub, state.raffle_name, {:raffle_ended, winner})
      {:noreply, state}
    end
  end

  defp sanitize_name(person_name) do
    person_name
    |> String.trim()
    |> String.downcase()
  end
end
