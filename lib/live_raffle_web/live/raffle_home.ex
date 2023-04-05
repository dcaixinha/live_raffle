defmodule LiveRaffleWeb.RaffleHome do
  use LiveRaffleWeb, :live_view

  def mount(_params, _session, socket) do
    raffles = LiveRaffle.RaffleSupervisor.ongoing_raffles()
    if connected?(socket), do: Phoenix.PubSub.subscribe(LiveRaffle.PubSub, "live_raffle")
    socket = assign(socket, raffles: raffles)
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="font-raleway font-black">
      <h1>👀 Ongoing Raffles</h1> <br>

      <%= if !Enum.empty?(@raffles) do %>
        <div class="grid grid-cols-1 gap-2 justify-items-center">
          <%= for raffle_name <- @raffles do %>
            <div class="rounded-md bg-violet-300 px-8 py-4 w-auto flex justify-center items-center">
            <.link navigate={~p"/raffle/#{raffle_name}"} class="flex items-center">
                  <%= raffle_name %>
                  <Heroicons.LiveView.icon name="ticket" type="solid" class="h-7 fill-violet-900 mx-1 " />
                </.link>
            </div>
          <% end %>
        </div>
      <% else %>
        <h2> No ongoing raffles... 😢 Ask the admin to create one! 🎫 </h2> <br>
      <% end %>
    </div>
    """
  end

  def handle_info({:raffle_created, raffle_name}, socket) do
    socket = update(socket, :raffles, fn raffles -> [ raffle_name | raffles] end)
    {:noreply, socket}
  end

end
