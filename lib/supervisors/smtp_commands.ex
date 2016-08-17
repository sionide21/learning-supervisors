defmodule Supervisors.SMTPCommands do
  alias Supervisors.Email

  def run("EHLO " <> name, state, :init) do
    state = state |> transition(:ready_for_mail)
    {"250 Howdy #{name}", state}
  end

  def run("HELO " <> name, state, :init) do
    state = state |> transition(:ready_for_mail)
    {"250 Howdy #{name}", state}
  end

  def run("QUIT", state, current) when current != :reading_message  do
    {{:halt, "221 closing transmission channel"}, state}
  end

  def run("MAIL FROM:" <> email, state, current) when current != :reading_message do
    state = state
      |> reset_email
      |> set_email(from: email)
      |> transition(:ready_for_rcpt)
    {"250 OK", state}
  end

  def run("RCPT TO:" <> email, state, :ready_for_rcpt) do
    state = state
      |> set_email(to: email)
      |> transition(:ready_for_data)
    {"250 OK", state}
  end

  def run("DATA", state, :ready_for_data) do
    state = state |> transition(:reading_message)
    {"354 Start mail input; end with <CRLF>.<CRLF>", state}
  end

  def run(".", %{email: email} = state, :reading_message) do
    state = state |> transition(:accepted)
    IO.puts ""
    IO.puts "Sent Email: #{email.from} -> #{email.to}"
    IO.puts email.mime
    {"250 OK", state}
  end

  def run(txt, state, :reading_message) do
    state |> set_email(next_line: txt)
    {nil, state |> set_email(next_line: txt)}
  end

  def run(_, state, _) do
    {"503 Bad sequence of commands", state}
  end

  defp transition(state, new) do
    %{state | state: new}
  end

  defp reset_email(state) do
    %{state | email: %Email{}}
  end

  defp set_email(state, [{field, value}]) do
    %{state | email: Email.set(state.email, field, value)}
  end
end
