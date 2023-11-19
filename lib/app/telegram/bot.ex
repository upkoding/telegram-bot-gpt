defmodule App.Telegram.Bot do
  @moduledoc """
  An example of Telegram bot command handlers.
  """
  use Telegram.Bot
  import App

  @doc """
  Handle update type `message`, other types are ignored.
  """
  @impl true
  def handle_update(
        %{
          "message" => %{
            "chat" => chat,
            "message_id" => message_id,
            "text" => text
          }
        },
        token
      ) do
    handle_chat(text, chat, message_id, token)
  end

  @impl true
  def handle_update(_message, _token) do
    # ignore unknown updates
    :ok
  end

  # helper function to reply a message
  defp reply(token, chat_id, _message_id, message) do
    telegram().request(token, "sendMessage",
      chat_id: chat_id,
      # reply_to_message_id: message_id,
      text: message
    )

    :ok
  end

  # handle `/start` command
  defp handle_chat("/start", %{"id" => chat_id, "username" => username}, message_id, token) do
    reply(token, chat_id, message_id, "Hi #{username}, nice to meet you!")
  end
end
