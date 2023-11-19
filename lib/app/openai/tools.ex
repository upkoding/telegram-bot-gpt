defmodule App.OpenAI.Tools do
  @fn_bali_time_spec %{
    type: "function",
    function: %{
      name: "fn_bali_time",
      description: "Current time in Bali",
      parameters: %{
        type: "object",
        properties: %{}
      }
    }
  }

  def handle_tool("fn_bali_time", _args) do
    {:ok, "time in Bali 2:44 PM"}
  end

  @fn_about_spec %{
    type: "function",
    function: %{
      name: "fn_about",
      description: "Information about you, the AI assistant.",
      parameters: %{
        type: "object",
        properties: %{}
      }
    }
  }

  def handle_tool("fn_about", _args) do
    {:ok,
     """
     This assistant is created by Eka Putra, a Balinese developer who keen to experiments with new technologies.
     The source code of this AI assistant available at https://github.com/upkoding/telegram-bot-gpt.
     Created using Elixir language.
     """}
  end

  def specs do
    [
      @fn_bali_time_spec,
      @fn_about_spec
    ]
  end
end
