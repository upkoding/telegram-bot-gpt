import Config

# Runtime specific config

config :app, App.Telegram.Webhook,
  host: System.get_env("BOT_HOST"),
  port: System.get_env("PORT", "443") |> String.to_integer(),
  local_port: System.get_env("LOCAL_PORT", "8443") |> String.to_integer()

config :app, App.Telegram.Bot,
  token: System.get_env("BOT_TOKEN"),
  max_bot_concurrency: System.get_env("MAX_BOT_CONCURRENCY", "1000") |> String.to_integer()

config :app, OpenAI,
  token: System.get_env("OPENAI_API_KEY"),
  organization: System.get_env("OPENAI_ORG", nil)

config :app,
  bot_username: System.get_env("BOT_USERNAME"),
  bot_admin_username: System.get_env("BOT_ADMIN_USERNAME"),
  bot_admin_chatid: System.get_env("BOT_ADMIN_CHAT_ID") |> String.to_integer()
