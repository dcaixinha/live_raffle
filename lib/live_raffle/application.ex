defmodule LiveRaffle.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      LiveRaffleWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: LiveRaffle.PubSub},
      # Start Finch
      {Finch, name: LiveRaffle.Finch},
      {Registry, keys: :unique, name: RaffleRegistry},
      LiveRaffle.RaffleSupervisor,
      # Start the Endpoint (http/https)
      LiveRaffleWeb.Endpoint
      # Start a worker by calling: LiveRaffle.Worker.start_link(arg)
      # {LiveRaffle.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: LiveRaffle.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    LiveRaffleWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
