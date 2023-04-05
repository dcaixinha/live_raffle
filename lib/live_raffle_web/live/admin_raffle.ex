defmodule LiveRaffleWeb.AdminRaffleLive do
  use LiveRaffleWeb, :live_view
  alias LiveRaffle.RaffleWorker

  def mount(%{"raffle_name" => raffle_name}, _session, socket) do
    {:ok, people, open} = RaffleWorker.get_people(raffle_name)
    if connected?(socket), do: Phoenix.PubSub.subscribe(LiveRaffle.PubSub, raffle_name)
    socket = assign(socket, raffle_name: raffle_name, people: people, open: open, started: false, winner: "")
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="font-raleway font-black">
      <h1>🛡 Raffle '<%= @raffle_name %>' 🚀</h1> <br>

    <div class="flex items-center justify-center space-x-3">
      <%= if !@started do %>
        <button id="toggle-raffle" type="button" phx-click="toggle-raffle" class={"flex items-center space-x-1"}>
          <%= if @open do %>
            <Heroicons.LiveView.icon name="lock-closed" type="solid" class="h-4" />
            <span class="text-base"> Close Raffle </span>
          <% else %>
            <Heroicons.LiveView.icon name="lock-open" type="solid" class="h-4" />
            <span class="text-base"> Open Raffle </span>
          <% end %>
        </button>
      <% end %>

      <%= if !@open do %>
        <button id="start-draw" type="button" phx-click="start-draw" class={"flex items-center space-x-1"}>
            <Heroicons.LiveView.icon name="check-circle" type="solid" class="h-4" />
            <span class="text-base"> Start Draw </span>
        </button>
      <% end %>
      </div>
      <br><br>
      <%= if @started do %>
        <%= if @winner != "" do%>
          <h2> 🏆 We have a winner: <%= @winner %> 🏆 </h2> <br>
        <% else %>
          <h2>🥁 Raffle has started 🥁 </h2> <br>
        <% end %>
      <% else %>
          <h2>🫂 People in the Raffle: <%= length(Map.keys(@people)) %></h2> <br>
      <% end %>

        <div class="people flex flex-wrap items-center justify-center">
          <%= for {person, status} <- @people do %>
            <div
              class={"person w-40 m-3 p-2 rounded-md bg-violet-300 h-12 flex justify-center items-center #{if status, do: "", else: "opacity-20 transition ease-in-out delay-700"}"}
            >
              <%= person %>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  def handle_event("create-raffle", %{"raffle_name" => raffle_name}, socket) do
    LiveRaffle.RaffleSupervisor.start_child(raffle_name)
    socket = assign(socket, raffle_name: raffle_name)
    {:noreply, push_navigate(socket, to: "/raffle/#{raffle_name}")}
  end

  def handle_event("toggle-raffle", _params, socket) do
    {:ok, new_status} = RaffleWorker.toggle_status(socket.assigns.raffle_name)
    socket = assign(socket, open: new_status)
    {:noreply, socket}
  end

  def handle_event("start-draw", _params, socket) do
    :ok = RaffleWorker.start_draw(socket.assigns.raffle_name)
    socket = assign(socket, open: false, started: true)
    {:noreply, socket}
  end

  def handle_info({:person_added, person_name}, socket) do
    socket = update(socket, :people, fn people -> Map.put(people, person_name, true) end)
    {:noreply, socket}
  end

  def handle_info({:person_removed, person_name}, socket) do
    socket = update(socket, :people, fn people -> Map.delete(people, person_name) end)
    {:noreply, socket}
  end

  def handle_info({:person_deactivated, person_name}, socket) do
    socket = update(socket, :people, fn people -> Map.put(people, person_name, false) end)
    {:noreply, socket}
  end

  def handle_info({:status_changed, _new_status}, socket) do
    {:noreply, socket}
  end

  def handle_info(:raffle_started, socket) do
    {:noreply, assign(socket, started: true)}
  end

  def handle_info({:raffle_ended, winner_name}, socket) do
    {:noreply, assign(socket, winner: winner_name)}
  end
end
