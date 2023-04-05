defmodule LiveRaffleWeb.AdminLive do
  use LiveRaffleWeb, :live_view
  alias LiveRaffle.Raffle

  def mount(_params, _session, socket) do
    raffles = LiveRaffle.RaffleSupervisor.ongoing_raffles()
    changeset = Raffle.changeset(%Raffle{})
    socket = assign(socket,
      form: to_form(changeset),
      raffles: raffles,
      raffle_name: ""
    )
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="font-raleway font-black">
      <h1>🛡 Admin Page – 👀 Ongoing Raffles</h1> <br>

      <div class="grid grid-cols-1 gap-2 justify-items-center">
        <%= for raffle_name <- @raffles do %>
          <div class="rounded-md bg-violet-300 px-8 py-4 w-auto flex justify-center items-center">
            <.link navigate={~p"/admin/raffle/#{raffle_name}"} class="flex items-center">
              <%= raffle_name %>
              <Heroicons.LiveView.icon name="ticket" type="solid" class="h-7 fill-violet-900 mx-1 " />
            </.link>
          </div>
        <% end %>
      </div>

      <div id="raffle">
        <.form for={@form} phx-submit="create-raffle">
          <div class="name-input">
          <.input
            label="Raffle Name"
            field={@form[:raffle_name]}
            autocomplete="off"
            placeholder="Enter raffle name..."
            value={@raffle_name}
          />
          </div>
          <div class="button-input">
          <.button
            class="submit-name"
          >
            <Heroicons.LiveView.icon name="check-circle" type="solid" class="h-4" />
            Create Raffle
          </.button>
          </div>
        </.form>
      </div>
    </div>
    """
  end

  def handle_event("create-raffle", %{"raffle" => raffle_params}, socket) do
    case LiveRaffle.RaffleSupervisor.start_child(raffle_params) do
      {:ok, raffle_name} ->
        socket = assign(socket, raffle_name: raffle_name)
        changeset = Raffle.changeset(%Raffle{})
        socket = assign(socket, form: to_form(changeset))
        {:noreply, push_navigate(socket, to: "/admin/raffle/#{raffle_name}")}

      {:error, changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end
end
