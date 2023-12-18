defmodule App.Telegram.ChatBot do
  use Telegram.ChatBot
  alias App.OpenAI.Chat

  @session_ttl 1_000 * 60
  @message_limit 3

  @impl true
  def init(%{"type" => type}) do
    {:ok, {Chat.new(type), 0, type}, @session_ttl}
  end

  @impl true
  def handle_update(
        %{
          "message" => %{
            "chat" => %{"id" => chat_id, "first_name" => name, "type" => "private"},
            "text" => "/sayamau"
          }
        },
        token,
        {chat, _counter, _type} = state
      ) do
    admin_chat_id = Application.fetch_env!(:app, :bot_admin_chatid)

    chat
    |> Chat.reply(
      {token, admin_chat_id, nil},
      "🚀 Halo Admin, [#{name}](tg://user?id=#{chat_id}) ingin mendapatkan akses penuh."
    )
    |> Chat.reply(
      {token, chat_id, nil},
      "Terima kasih! pesan mu sudah saya sampaikan ke pengembang 🙏"
    )

    {:stop, state}
  end

  @impl true
  def handle_update(
        %{
          "message" => %{"chat" => %{"id" => chat_id, "type" => "private"}, "text" => "/chatid"}
        },
        token,
        {chat, _counter, _type} = state
      ) do
    Chat.reply(
      chat,
      {token, chat_id, nil},
      chat_id
    )

    {:stop, state}
  end

  @impl true
  def handle_update(
        %{"message" => %{"chat" => %{"id" => chat_id, "first_name" => name}, "text" => text}},
        token,
        {chat, counter, type} = state
      ) do
    # handle Private chat update.
    # for this trial we limit user to send max 5 messages per session.

    cond do
      counter == 0 ->
        new_chat =
          chat
          |> Chat.add_message(:user, "Halo, nama saya #{name}. #{text}")
          |> Chat.get_response({token, chat_id, nil})

        {:ok, {new_chat, counter + 1, type}, @session_ttl}

      counter <= @message_limit ->
        new_chat =
          chat
          |> Chat.add_message(:user, text)
          |> Chat.get_response({token, chat_id, nil})

        {:ok, {new_chat, counter + 1, type}, @session_ttl}

      counter > @message_limit ->
        Chat.reply(
          chat,
          {token, chat_id, nil},
          """
          🚧 SESI CHAT BERAKHIR 🚧

          Selama masa uji coba ini Bot hanya bisa memproses 3 pesan kamu sebelumnya.

          Kamu tetap bisa melanjutkan komunikasi, tetapi Bot tidak akan punya konteks dari percakapan sebelumnya.

          *Apabila tool ini berguna dan kamu ingin mendapatkan akses penuh? Klik link /sayamau ini.*
          """
        )

        {:stop, state}
    end
  end

  @impl true
  def handle_update(
        %{"message" => %{"chat" => %{"type" => "group"}}} = message,
        token,
        state
      ) do
    handle_group_update(message, token, state)
  end

  @impl true
  def handle_update(
        %{"message" => %{"chat" => %{"type" => "supergroup"}}} = message,
        token,
        state
      ) do
    handle_group_update(message, token, state)
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
  def handle_timeout(token, chat_id, {chat, _counter, type} = state) do
    # say goodby on private chat when timeout.
    if type == "private" do
      chat
      |> Chat.reply(
        {token, chat_id, nil},
        "Karena tidak ada yang ditanyakan lagi, saya permisi dulu. sampai jumpa!👋"
      )
    end

    {:stop, state}
  end

  defp handle_group_update(
         %{"message" => %{"text" => "/start"}},
         _token,
         state
       ) do
    # Ignore /start command in group.
    {:stop, state}
  end

  defp handle_group_update(
         %{
           "message" => %{
             "chat" => %{"id" => chat_id},
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
         {chat, counter, type}
       ) do
    new_counter = counter + 1
    # Handle Group chat update. We treat them as a one-off message (stateless).
    # Rules:
    # - a reply to a message
    # - replied by admin
    # - admin mention @BotName
    bot_username = Application.fetch_env!(:app, :bot_username)
    bot_admin_username = Application.fetch_env!(:app, :bot_admin_username)

    chat =
      if String.contains?(replying_text, bot_username) do
        if replying_username == bot_admin_username do
          user_prompt = """
          #{reply_to_text}
          #{replying_text}
          """

          # create a new chat that are specifically configured for Group.
          chat
          |> Chat.add_message(:user, user_prompt)
          |> Chat.get_response({token, chat_id, reply_to_message_id})
        else
          chat
          |> Chat.reply(
            {token, chat_id, message_id},
            "Maaf, untuk sementara hanya admin yang bisa meminta saya menjawab 🙏"
          )
        end
      else
        chat
      end

    {:ok, {chat, new_counter, type}, @session_ttl}
  end
end
