defmodule App.Telegram.ChatBot do
  use Telegram.ChatBot
  require Logger
  alias App
  alias App.OpenAI.{Chat, Tools}

  @session_ttl 1_000 * 60

  @impl true
  def init(_chat) do
    {:ok, {Chat.new(), 0}, @session_ttl}
  end

  @impl true
  def handle_update(
        %{"message" => %{"chat" => %{"id" => chat_id, "first_name" => name}, "text" => text}},
        token,
        {chat, counter}
      ) do
    new_counter = counter + 1

    new_chat =
      case counter do
        0 ->
          Chat.add_message(
            chat,
            :user,
            "Halo, nama saya #{name}. #{text}"
          )

        _ ->
          Chat.add_message(chat, :user, text)
      end

    chat = get_response(new_chat, token, chat_id)
    {:ok, {chat, new_counter}, @session_ttl}
  end

  def handle_update(_update, _token, state) do
    # ignore unknown updates

    {:ok, state, @session_ttl}
  end

  @impl true
  def handle_info(_msg, _token, _chat_id, state) do
    # direct message processing

    {:ok, state}
  end

  @impl true
  def handle_timeout(_token, _chat_id, state) do
    # App.telegram().request(token, "sendMessage",
    #   chat_id: chat_id,
    #   text: "Sampai jumpa 👋"
    # )

    {:stop, state}
  end

  defp reply(token, chat_id, message) do
    App.telegram().request(token, "sendMessage",
      chat_id: chat_id,
      text: message
    )
  end

  defp get_response(chat, token, chat_id) do
    case Chat.get_response(chat) do
      %{"error" => error} ->
        Logger.error(inspect(error))
        reply(token, chat_id, "Maaf, terjadi kesalahan. Saya belum bisa memproses pesan kamu 🙏")
        chat

      %{"choices" => messages} ->
        Enum.reduce(messages, chat, fn msg, acc ->
          handle_message(msg, acc, token, chat_id)
        end)

      response ->
        Logger.debug(response)
        chat
    end
  end

  defp handle_message(%{"message" => %{"content" => content}}, chat, token, chat_id)
       when not is_nil(content) do
    reply(token, chat_id, content)
    Chat.add_message(chat, :assistant, content)
  end

  defp handle_message(
         %{"message" => %{"content" => nil, "tool_calls" => tool_calls} = message},
         chat,
         token,
         chat_id
       ) do
    chat = Chat.add_message(chat, message)

    with tool <- List.first(tool_calls),
         {:ok, tool_id} <- Map.fetch(tool, "id"),
         {:ok, function} <- Map.fetch(tool, "function"),
         {:ok, fn_name} <- Map.fetch(function, "name"),
         {:ok, fn_args} <- Map.fetch(function, "arguments"),
         {:ok, output} <- Tools.handle_tool(fn_name, fn_args) do
      Chat.add_tool(chat, tool_id, fn_name, output) |> get_response(token, chat_id)
    else
      _ -> chat
    end
  end
end
