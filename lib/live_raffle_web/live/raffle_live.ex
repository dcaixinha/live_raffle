defmodule LiveRaffleWeb.RaffleLive do
  use LiveRaffleWeb, :live_view
  alias LiveRaffle.RaffleWorker
  alias LiveRaffle.Person

  def mount(%{"raffle_name" => raffle_name}, _session, socket) do
    {:ok, people, open} = RaffleWorker.get_people(raffle_name)
    if connected?(socket), do: Phoenix.PubSub.subscribe(LiveRaffle.PubSub, raffle_name)
    changeset = Person.changeset(%Person{})
    socket = assign(socket,
      form: to_form(changeset),
      raffle_name: raffle_name,
      people: people,
      person_name: "",
      open: open,
      started: false,
      winner: ""
    )
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="font-raleway font-black">
      <h1>Raffle '<%= @raffle_name %>' 🚀</h1> <br>
      <br><br>

      <%= if @started do %>
        <%= if @winner != "" do%>
          <%= if @winner == @person_name do%>
            <h2> 🏆 YOU are the winner! 🏆 </h2> <br>
          <% else %>
            <h2> 🏆 We have a winner: <%= @winner %> 🏆 </h2> <br>
          <% end %>
        <% else %>
          <h2>🥁 Raffle has started 🥁 </h2> <br>
        <% end %>
      <% else %>
        <%= if @open do %>
          <h2>🤗 Join this Raffle!</h2>

            <div id="raffle">
              <.form for={@form} phx-submit="submit-person-name">
                <div class="name-input">
                  <.input
                    label="Name"
                    field={@form[:person_name]}
                    autocomplete="off"
                    placeholder="Enter your name..."
                    value={@person_name}
                    readonly={@person_name != ""}
                  />
                </div>
                <div class="button-input">
                  <button
                    type="button"
                    phx-click="reset-person-name"
                    class={"edit-name  #{if @person_name == "", do: "hidden!", else: "visible"}"}
                  >
                    <Heroicons.LiveView.icon name="pencil-square" type="solid" class="h-4" />
                    Edit
                </button>
                <.button
                  disabled={@person_name != ""}
                  class={"submit-name #{if @person_name == "", do: "", else: "disabled:opacity-25 transition ease-in-out delay-700 "}"}
                >
                  <Heroicons.LiveView.icon name="check-circle" type="solid" class="h-4" />
                  Submit
                </.button>
                </div>
              </.form>
            </div>
          <% else %>
            <h2>⛔ Raffle registrations are closed. The draw will start soon!</h2>
            <%= if @person_name != "" do %>
              <h2>🤗 You joined as <%= @person_name %>!</h2>
            <% end %>
          <% end %>
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

  def handle_event("submit-person-name", %{"person" => person_params}, socket) do
    case RaffleWorker.add_person(socket.assigns.raffle_name, person_params) do
      {:ok, person_name} ->
        socket = assign(socket, person_name: person_name)
        changeset = Person.changeset(%Person{})
        {:noreply, assign(socket, :form, to_form(changeset))}

      {:error, changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  def handle_event("reset-person-name", _params, socket) do
    RaffleWorker.remove_person(socket.assigns.raffle_name, socket.assigns.person_name)
    {:noreply, assign(socket, person_name: "")}
  end

  def handle_info({:person_added, person_name}, socket) do
    socket = update(socket, :people, fn people -> Map.put(people, person_name, true) end)
    {:noreply, socket}
  end

  def handle_info({:person_removed, person_name}, socket) do
    socket = update(socket, :people, fn people -> Map.delete(people, person_name) end)
    {:noreply, socket}
  end

  def handle_info({:status_changed, new_status}, socket) do
    socket = assign(socket, open: new_status)
    {:noreply, socket}
  end

  def handle_info({:person_deactivated, person_name}, socket) do
    socket = update(socket, :people, fn people -> Map.put(people, person_name, false) end)
    {:noreply, socket}
  end

  def handle_info(:raffle_started, socket) do
    {:noreply, assign(socket, started: true)}
  end

  def handle_info({:raffle_ended, winner_name}, socket) do
    {:noreply, assign(socket, winner: winner_name)}
  end
end
