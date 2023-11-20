defmodule App.Telegram.ChatBot do
  use Telegram.ChatBot
  alias App.OpenAI.Chat

  @session_ttl 1_000 * 60

  @impl true
  def init(_chat) do
    {:ok, {Chat.new(:private), 0}, @session_ttl}
  end

  @impl true
  def handle_update(
        %{"message" => %{"chat" => %{"id" => chat_id, "first_name" => name}, "text" => text}},
        token,
        {chat, counter}
      ) do
    # handle Private chat update.
    new_counter = counter + 1

    chat =
      case counter do
        0 ->
          Chat.add_message(chat, :user, "Halo, nama saya #{name}. #{text}")

        _ ->
          Chat.add_message(chat, :user, text)
      end

    chat = Chat.get_response(chat, {token, chat_id, nil})
    {:ok, {chat, new_counter}, @session_ttl}
  end

  @impl true
  def handle_update(
        %{"message" => %{"chat" => %{"type" => "group"}, "text" => "/start"}},
        _token,
        state
      ) do
    # Ignore /start command in group.
    {:stop, state}
  end

  @impl true
  def handle_update(
        %{
          "message" => %{
            "chat" => %{"id" => chat_id, "type" => "group"},
            "message_id" => message_id,
            "reply_to_message" => %{
              "message_id" => reply_to_message_id,
              "text" => reply_to_text
            },
            "from" => %{"username" => replying_username},
            "text" => replying_text
          }
        },
        token,
        state
      ) do
    # Handle Group chat update. We treat them as a one-off message (stateless).
    # Rules:
    # - a reply to a message
    # - replied by admin
    # - admin mention @BotName
    bot_username = Application.fetch_env!(:app, :bot_username)
    bot_admin_username = Application.fetch_env!(:app, :bot_admin_username)

    if String.contains?(replying_text, bot_username) do
      if replying_username == bot_admin_username do
        user_prompt = """
        #{reply_to_text}
        #{replying_text}
        """

        # create a new chat that are specifically configured for Group.
        Chat.new(:group)
        |> Chat.add_message(:user, user_prompt)
        |> Chat.get_response({token, chat_id, reply_to_message_id})
      else
        Chat.reply(
          {token, chat_id, message_id},
          "Maaf, untuk sementara hanya admin yang bisa meminta saya menjawab 🙏"
        )
      end
    end

    {:stop, state}
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
  def handle_timeout(token, chat_id, state) do
    Chat.reply(
      {token, chat_id, nil},
      "Karena tidak ada yang ditanyakan lagi, saya permisi dulu. sampai jumpa!👋"
    )

    {:stop, state}
  end
end
