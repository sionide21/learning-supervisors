defmodule Supervisors.SMTPCommands do
  alias Supervisors.Email

  def run("EHLO " <> name, state, :init) do
    state
      |> transition(:ready_for_mail)
      |> reply("250 Howdy #{name}")
  end

  def run("HELO " <> name, state, :init) do
    state
      |> transition(:ready_for_mail)
      |> reply("250 Howdy #{name}")
  end

  def run("QUIT", state, current) when current != :reading_message  do
    state |> reply({:halt, "221 closing transmission channel"})
  end

  def run("MAIL FROM:" <> email, state, current) when current != :reading_message do
    state
      |> reset_email
      |> set_email(from: email)
      |> transition(:ready_for_rcpt)
      |> reply("250 OK")
  end

  def run("RCPT TO:" <> email, state, :ready_for_rcpt) do
    state
      |> set_email(to: email)
      |> transition(:ready_for_data)
      |> reply("250 OK")
  end

  def run("DATA", state, :ready_for_data) do
    state
      |> transition(:reading_message)
      |> reply("354 Start mail input; end with <CRLF>.<CRLF>")
  end

  def run(".", %{email: email} = state, :reading_message) do
    IO.puts ""
    IO.puts "Sent Email: #{email.from} -> #{email.to}"
    IO.puts email.mime

    state
      |> transition(:accepted)
      |> reply("250 OK")
  end

  def run(txt, state, :reading_message) do
    state
      |> set_email(next_line: txt)
      |> no_reply
  end

  def run(_, state, _) do
    state |> reply("503 Bad sequence of commands")
  end

  defp transition(state, new) do
    %{state | state: new}
  end

  defp reply(state, message) do
    {message, state}
  end

  defp no_reply(state) do
    {nil, state}
  end

  defp reset_email(state) do
    %{state | email: %Email{}}
  end

  defp set_email(state, [{field, value}]) do
    %{state | email: Email.set(state.email, field, value)}
  end
end