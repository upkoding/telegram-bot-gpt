defmodule AppTest do
  use ExUnit.Case
  doctest App

  test "telegram" do
    assert App.telegram() == TelegramApiMock
  end
end
