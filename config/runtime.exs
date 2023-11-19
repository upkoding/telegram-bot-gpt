import Config

# Runtime specific config

config :app, App.Telegram.Webhook,
  host: System.get_env("BOT_HOST"),
  port: System.get_env("PORT", "443") |> String.to_integer(),
  local_port: System.get_env("PORT", "8443") |> String.to_integer()

config :app, App.Telegram.Bot,
  token: System.get_env("BOT_TOKEN"),
  max_bot_concurrency: System.get_env("MAX_BOT_CONCURRENCY", "1000") |> String.to_integer()

config :app, OpenAI,
  token: System.get_env("OPENAI_API_KEY"),
  organization: System.get_env("OPENAI_ORG", nil)
