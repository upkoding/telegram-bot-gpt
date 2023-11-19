defmodule App do
  @doc """
  Return Telegram API client that is set via config, default to: App.Telegram.Api
  This will allow us to replace (mock) the client on test env.

  Bots must use this function to get API client to make it easier to test
  bot logic.
  """
  def telegram do
    Application.get_env(:app, :telegram_api, App.Telegram.Api)
  end

  def openai do
    [token: token, organization: org] = Application.fetch_env!(:app, OpenAI)
    OpenaiEx.new(token, org)
  end
end
