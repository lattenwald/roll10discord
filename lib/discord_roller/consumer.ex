defmodule DiscordRoller.Consumer do
  use Nostrum.Consumer

  alias Nostrum.Api
  alias Nostrum.Struct.Component

  def start_link do
    Consumer.start_link(__MODULE__)
  end

  def handle_event({:INTERACTION_CREATE, interaction = %{type: 2, data: %{name: "ping"}}, _ws_state}) do
    Api.create_interaction_response(interaction, %{type: 4, data: %{content: "pong"}})
  end

  def handle_event({:INTERACTION_CREATE, interaction = %{type: 2, data: %{name: "plain"}}, _ws_state}) do
    text = Roller.roll()
    Api.create_interaction_response(interaction, %{type: 4, data: %{content: text}})
  end

  def handle_event({:INTERACTION_CREATE, interaction = %{type: 2, data: %{name: "dice", options: [%{name: optname, value: num}]}}, _ws_state}) do
    again = case optname do
      "10-again" -> 10
      "9-again" -> 9
      "8-again" -> 8
    end
    num = trunc(num)
    text = Roller.roll(num, again)
    Api.create_interaction_response(interaction, %{type: 4, data: %{content: text}})
  end

  def handle_event({:INTERACTION_CREATE, interaction = %{type: 2, data: %{name: "roll"}}, _ws_state}) do
    components = again_components()
    Api.create_interaction_response(interaction, %{type: 4, data: %{content: "roll", components: components}})
  end

  def handle_event({:INTERACTION_CREATE, interaction = %{type: 3, data: %{custom_id: "again-" <> again}}, _ws_state}) do
    again = String.to_integer(again)
    Api.create_interaction_response(interaction, %{type: 7, data: %{components: again_components(again)}})
  end

  def handle_event({:INTERACTION_CREATE, interaction = %{type: 3, data: %{custom_id: "roll-" <> roll}}, _ws_state}) do
    {num, again} = parse_num_again(roll)
    text = Roller.roll(num, again)
    Api.create_interaction_response(interaction, %{type: 7, data: %{content: text, components: []}})
  end

  def handle_event({:INTERACTION_CREATE, interaction = %{type: 2, data: %{name: "test"}}, _ws_state}) do
    components = test_again_components()
    Api.create_interaction_response(interaction, %{type: 4, data: %{content: "test roll", components: components}})
  end

  def handle_event({:INTERACTION_CREATE, interaction = %{type: 3, data: %{custom_id: "select-again", values: [again]}}, _ws_state}) do
    again = String.to_integer(again)
    Api.create_interaction_response(interaction, %{type: 7, data: %{components: test_again_components(again)}})
  end


  # Default event handler, if you don't include this, your consumer WILL crash if
  # you don't have a method definition for each event type.
  def handle_event(_event) do
    :noop
  end

  def button(label, value, highlight \\ false) do
    Component.Button.interaction_button(label, value, style: (if highlight, do: 1, else: 2), custom_id: value)
  end

  def again_components(again \\ 10) do
    [
      Component.ActionRow.action_row(10..8 |> Enum.map(&button("#{&1} again", "again-#{&1}", &1 == again))),
      Component.ActionRow.action_row(1..5 |> Enum.map(&button("#{&1}", "roll-#{&1}a#{again}"))),
      Component.ActionRow.action_row(6..10 |> Enum.map(&button("#{&1}", "roll-#{&1}a#{again}")))
    ]
  end

  def test_again_components(again \\ 10) do
    again_options = 10..8 |> Enum.map(&(%Component.Option{label: "#{&1} again", value: "#{&1}", default: &1 == again}))
    again_menu = Component.SelectMenu.select_menu("select-again", options: again_options)
    row1 = Component.ActionRow.action_row()
    row1 = Component.ActionRow.put row1, again_menu
    [ row1,
      Component.ActionRow.action_row(1..5 |> Enum.map(&button("#{&1}", "roll-#{&1}a#{again}"))),
      Component.ActionRow.action_row(6..10 |> Enum.map(&button("#{&1}", "roll-#{&1}a#{again}")))
    ]
  end


  defp parse_num_again(str, default_again \\ 10) do
    case Integer.parse(str) do
      {num, ""} when num <= 50 -> {num, default_again}
      {num, "a" <> str} ->
        case Integer.parse(str) do
          {again, ""} when again >= 7 -> {num, again}
          _ -> :error
        end
      _ -> :error
    end
  end

end
