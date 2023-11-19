# change client to TelegramApiMock for testing.
Mox.defmock(TelegramApiMock, for: App.Telegram.ApiBehaviour)
Application.put_env(:app, :telegram_api, TelegramApiMock)

ExUnit.start()
