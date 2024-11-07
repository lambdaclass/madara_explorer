defmodule StarknetExplorerWeb.Router do
  use StarknetExplorerWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {StarknetExplorerWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  live_session :default, on_mount: {StarknetExplorerWeb.Live.CommonAssigns, :network} do
    scope "/", StarknetExplorerWeb do
      pipe_through :browser

      live "/", HomeLive.Index, :index
      live "/blocks", BlockIndexLive
      live "/blocks/:number_or_hash", BlockDetailLive
      live "/transactions", TransactionIndexLive
      live "/transactions/:transaction_hash", TransactionLive
      live "/contracts", ContractIndexLive
      live "/contracts/:address", ContractDetailLive
      live "/events", EventIndexLive
      live "/events/:identifier", EventDetailLive
      live "/messages", MessageIndexLive
      live "/messages/:identifier", MessageDetailLive
      live "/classes", ClassIndexLive
      live "/classes/:hash", ClassDetailLive
      live "/memecoins", MemecoinIndexLive
    end

    scope "/:network", StarknetExplorerWeb do
      pipe_through :browser

      live "/", HomeLive.Index, :index
      live "/blocks", BlockIndexLive
      live "/blocks/:number_or_hash", BlockDetailLive
      live "/transactions", TransactionIndexLive
      live "/transactions/:transaction_hash", TransactionLive
      live "/contracts", ContractIndexLive
      live "/contracts/:address", ContractDetailLive
      live "/events", EventIndexLive
      live "/events/:identifier", EventDetailLive
      live "/messages", MessageIndexLive
      live "/messages/:identifier", MessageDetailLive
      live "/classes", ClassIndexLive
      live "/classes/:hash", ClassDetailLive
      live "/memecoins", MemecoinIndexLive
    end
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:starknet_explorer, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: StarknetExplorerWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  scope "/" do
    pipe_through :browser
  end
end
