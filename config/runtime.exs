import Config

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.
# The block below contains prod specific runtime configuration.

# ## Using releases
#
# If you use `mix release`, you need to explicitly enable the server
# by passing the PHX_SERVER=true when you start it:
#
#     PHX_SERVER=true bin/starknet_explorer start
#
# Alternatively, you can use `mix phx.gen.release` to generate a `bin/server`
# script that automatically sets the env var above.
if System.get_env("PHX_SERVER") do
  config :starknet_explorer, StarknetExplorerWeb.Endpoint, server: true
end

rpc_host =
  System.get_env("RPC_API_HOST") ||
    raise """
    environment variable RPC_API_HOST is missing.
    """

testnet_rpc_host =
  System.get_env("TESTNET_RPC_API_HOST") ||
    raise """
    environment variable for testnet is missing.
    """

testnet_2_rpc_host =
  System.get_env("TESTNET_2_RPC_API_HOST") ||
    raise """
    environment variable for testnet 2 is missing.
    """

config :starknet_explorer,
  rpc_host: rpc_host,
  testnet_host: testnet_rpc_host,
  testnet_2_host: testnet_2_rpc_host,
  enable_gateway_data: System.get_env("ENABLE_GATEWAY_DATA") == "true"

config :starknet_explorer, rpc_host: rpc_host

config :starknet_explorer,
  rpc_host: rpc_host,
  s3_bucket_name: System.get_env("S3_BUCKET_NAME"),
  prover_storage: System.get_env("PROVER_STORAGE"),
  proofs_root_dir: System.get_env("PROOFS_ROOT_DIR") || "./proofs"

config :ex_aws,
  access_key_id: System.get_env("AWS_ACCESS_KEY_ID"),
  secret_access_key: System.get_env("AWS_SECRET_ACCESS_KEY"),
  region: System.get_env("AWS_REGION")

config :starknet_explorer,
  enable_block_verification: System.get_env("ENABLE_BLOCK_VERIFICATION") || false

if config_env() == :prod do
  db_type =
    System.get_env("DB_TYPE") ||
      raise """
      environment variable DB_TYPE is missing.
      For example: "postgres" or "sqlite"
      """

  if db_type == "postgresql" do
    database_url =
      System.get_env("DATABASE_URL") ||
        raise """
        environment variable DATABASE_URL is missing.
        For example: ecto://USER:PASS@HOST/DATABASE
        """

    maybe_ipv6 = if System.get_env("ECTO_IPV6") in ~w(true 1), do: [:inet6], else: []

    config :starknet_explorer, StarknetExplorer.Repo,
      url: database_url,
      pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
      socket_options: maybe_ipv6,
      stacktrace: true,
      show_sensitive_data_on_connection_error: true
  else
    database_path =
      System.get_env("DATABASE_PATH") ||
        raise """
        environment variable DATABASE_PATH is missing.
        For example: /etc/my_app/my_app.db
        """

    config :starknet_explorer, StarknetExplorer.Repo,
      database: database_path,
      pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
      stacktrace: true,
      show_sensitive_data_on_connection_error: true
  end

  # The secret key base is used to sign/encrypt cookies and other secrets.
  # A default value is used in config/dev.exs and config/test.exs but you
  # want to use a different value for prod and you most likely don't want
  # to check this value into version control, so we use an environment
  # variable instead.
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("PHX_HOST") || "madarastark.com"
  port = String.to_integer(System.get_env("PORT") || "4000")

  config :starknet_explorer, StarknetExplorerWeb.Endpoint,
    server: true,
    url: [host: host, port: 443, scheme: "https"],
    check_origin: [
      "https://madaraexplorer.com",
      "https://www.madaraexplorer.com",
      "https://madaraexplorer.lambdaclass.com",
      "https://testing.madaraexplorer.com",
      "https://#{host}:#{port}",
      "http://#{host}:#{port}"
    ],
    http: [
      # Enable IPv6 and bind on all interfaces.
      # Set it to  {0, 0, 0, 0, 0, 0, 0, 1} for local network only access.
      # See the documentation on https://hexdocs.pm/plug_cowboy/Plug.Cowboy.html
      # for details about using IPv6 vs IPv4 and loopback vs public addresses.
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: port
    ],
    secret_key_base: secret_key_base

  # Newrelic agent
  newrelic_license_key =
    System.get_env("NEWRELIC_KEY")

  newrelic_app_name =
    System.get_env("NEWRELIC_APP_NAME")

  config :new_relic_agent,
    app_name: newrelic_app_name,
    license_key: newrelic_license_key,
    # Logs are forwarded directly from Elixir to New Relic
    logs_in_context: :direct

  # ## SSL Support
  #
  # To get SSL working, you will need to add the `https` key
  # to your endpoint configuration:
  #
  #     config :starknet_explorer, StarknetExplorerWeb.Endpoint,
  #       https: [
  #         ...,
  #         port: 443,
  #         cipher_suite: :strong,
  #         keyfile: System.get_env("SOME_APP_SSL_KEY_PATH"),
  #         certfile: System.get_env("SOME_APP_SSL_CERT_PATH")
  #       ]
  #
  # The `cipher_suite` is set to `:strong` to support only the
  # latest and more secure SSL ciphers. This means old browsers
  # and clients may not be supported. You can set it to
  # `:compatible` for wider support.
  #
  # `:keyfile` and `:certfile` expect an absolute path to the key
  # and cert in disk or a relative path inside priv, for example
  # "priv/ssl/server.key". For all supported SSL configuration
  # options, see https://hexdocs.pm/plug/Plug.SSL.html#configure/1
  #
  # We also recommend setting `force_ssl` in your endpoint, ensuring
  # no data is ever sent via http, always redirecting to https:
  #
  #     config :starknet_explorer, StarknetExplorerWeb.Endpoint,
  #       force_ssl: [hsts: true]
  #
  # Check `Plug.SSL` for all available options in `force_ssl`.

  # ## Configuring the mailer
  #
  # In production you need to configure the mailer to use a different adapter.
  # Also, you may need to configure the Swoosh API client of your choice if you
  # are not using SMTP. Here is an example of the configuration:
  #
  #     config :starknet_explorer, StarknetExplorer.Mailer,
  #       adapter: Swoosh.Adapters.Mailgun,
  #       api_key: System.get_env("MAILGUN_API_KEY"),
  #       domain: System.get_env("MAILGUN_DOMAIN")
  #
  # For this example you need include a HTTP client required by Swoosh API client.
  # Swoosh supports Hackney and Finch out of the box:
  #
  #     config :swoosh, :api_client, Swoosh.ApiClient.Hackney
  #
  # See https://hexdocs.pm/swoosh/Swoosh.html#module-installation for details.
end
