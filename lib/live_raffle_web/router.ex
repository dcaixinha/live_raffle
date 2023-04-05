defmodule LiveRaffleWeb.Router do
  use LiveRaffleWeb, :router
  import Plug.BasicAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {LiveRaffleWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :auth do
    plug :basic_auth,
      username: System.fetch_env!("ADMIN_USER"),
      password: System.fetch_env!("ADMIN_PASSWORD")
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", LiveRaffleWeb do
    pipe_through :browser

    live "/", RaffleHome
    live "/raffle/:raffle_name", RaffleLive
  end

  scope "/admin", LiveRaffleWeb do
    pipe_through [:browser, :auth]

    live "/", AdminLive
    live "/raffle/:raffle_name", AdminRaffleLive
  end

  # Other scopes may use custom stacks.
  # scope "/api", LiveRaffleWeb do
  #   pipe_through :api
  # end

  # Enable Swoosh mailbox preview in development
  if Application.compile_env(:live_raffle, :dev_routes) do

    scope "/dev" do
      pipe_through :browser

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
