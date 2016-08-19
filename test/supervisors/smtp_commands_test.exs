defmodule Supervisors.SMTPCommandsTest do
  use ExUnit.Case, async: true
  doctest Supervisors.SMTPCommands
  import Supervisors.SMTPCommands, only: [run: 2]
  alias Supervisors.Email

  test "HELO initializes the session" do
    state = %{state: :init, email: nil}

    new_state = run("HELO test.com", state)
    |> assert_reply("250")
    |> assert_state(:ready_for_mail)

    run("HELO test.com", new_state)
    |> assert_reply("503")
    |> assert_unchanged(new_state)
  end

  test "invalid commnds get 500" do
    state = %{state: :init, email: nil}

    run("BANANA", state)
    |> assert_reply("500")
    |> assert_unchanged(state)
  end

  describe "MAIL" do
    test "starts an email" do
      state = %{state: :ready_for_mail, email: nil}

      run("MAIL FROM: ben@example.net", state)
      |> assert_reply("250")
      |> assert_email(from: "ben@example.net")
    end

    test "resets a message already in progress" do
      email = %Email{from: "ben@example.net", to: ["test@example.com"]}
      state = %{state: :ready_for_data, email: email}

      run("MAIL FROM: banana@example.net", state)
      |> assert_reply("250")
      |> assert_email(from: "banana@example.net")
      |> assert_email(to: [])
    end

    test "cannot be run before HELO" do
      state = %{state: :init, email: nil}

      run("MAIL FROM: ben@example.net", state)
      |> assert_reply("503")
      |> assert_unchanged(state)
    end
  end

  describe "RCPT" do
    test "adds a recipient" do
      state = %{state: :ready_for_rcpt, email: %Email{}}

      new_state = run("RCPT TO: ben@example.net", state)
      |> assert_reply("250")
      |> assert_state(:ready_for_data)
      |> assert_email(to: ["ben@example.net"])


      run("RCPT TO: banana@example.net", new_state)
      |> assert_reply("250")
      |> assert_state(:ready_for_data)
      |> assert_email(to: ["banana@example.net", "ben@example.net"])
    end

    test "cannot be run before MAIL" do
      state = %{state: :ready_for_mail, email: nil}

      run("RCPT TO: ben@example.net", state)
      |> assert_reply("503")
      |> assert_unchanged(state)
    end
  end

  describe "DATA" do
    test "switches to message mode" do
      state = %{state: :ready_for_data, email: %Email{}}

      state = run("DATA", state)
      |> assert_reply("354")

      assert {nil, state} = run("hello smtp", state)
      assert {nil, state} = run("QUIT", state)
      assert {nil, state} = run("MAIL FROM: test", state)
      assert_email(state, mime: "hello smtp\r\nQUIT\r\nMAIL FROM: test\r\n")
    end
  end

  describe "QUIT" do
    test "halts" do
      state = %{state: :init, email: nil}

      assert {{:halt, "221 " <> _}, _} = run("QUIT", state)
    end
  end

  defp assert_reply({reply, state}, expected) do
    code = reply |> String.split |> Enum.at(0)
    assert code == expected, "Expected #{expected}, got \"#{reply}\""
    state
  end

  defp assert_state(state, expected) do
    assert state.state == expected
    state
  end

  defp assert_email(%{email: email} = state, email_assertions) do
    Enum.each email_assertions, fn {field, expected} ->
      assert Map.get(email, field) == expected
    end
    state
  end

  defp assert_unchanged(state, original) do
    assert original == state
    state
  end
end
