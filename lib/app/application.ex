defmodule App.Application do
  @moduledoc false

  use Application
  require Config

  @impl true
  def start(_type, _args) do
    webhook_config = Application.fetch_env!(:app, App.Telegram.Webhook)
    bot_config = Application.fetch_env!(:app, App.Telegram.Bot)
    # add our bot under supervision tree only if :start_bot config == true
    # as we don't want to start the bot on :test env
    children =
      case Application.fetch_env!(:app, :start_bot) do
        true ->
          [{Telegram.Webhook, config: webhook_config, bots: [{App.Telegram.ChatBot, bot_config}]}]

        _ ->
          []
      end

    opts = [strategy: :one_for_one, name: App.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
