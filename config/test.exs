import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :dice, DiceWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "dLyJ/yb6idoO1ntUOwKgVaSIGgBaFC2qSK1btSWU0vdLG0A5CR6yo8hUmn20Pdkc",
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
