defmodule Supervisors.ClientState do
  use GenServer
  alias Supervisors.Email

  def start_link do
    GenServer.start_link(__MODULE__, %{state: :init, email: nil})
  end

  def current_state(pid) do
    GenServer.call(pid, :state)
  end

  def command(pid, command) do
    GenServer.call(pid, {:command, command})
  end

  defp run("EHLO " <> name, state, :init) do
    state = state |> transition(:ready_for_mail)
    {"250 Howdy #{name}", state}
  end

  defp run("HELO " <> name, state, :init) do
    state = state |> transition(:ready_for_mail)
    {"250 Howdy #{name}", state}
  end

  defp run("MAIL FROM:" <> email, state, current) when current != :reading_message do
    state = state
      |> reset_email
      |> set_email(from: email)
      |> transition(:ready_for_rcpt)
    {"250 OK", state}
  end

  defp run("RCPT TO:" <> email, state, :ready_for_rcpt) do
    state = state
      |> set_email(to: email)
      |> transition(:ready_for_data)
    {"250 OK", state}
  end

  defp run("DATA", state, :ready_for_data) do
    state = state |> transition(:reading_message)
    {"354 Start mail input; end with <CRLF>.<CRLF>", state}
  end

  defp run(".", %{email: email} = state, :reading_message) do
    state = state |> transition(:accepted)
    IO.puts ""
    IO.puts "Sent Email: #{email.from} -> #{email.to}"
    IO.puts email.mime
    {"250 OK", state}
  end

  defp run(txt, state, :reading_message) do
    state |> set_email(next_line: txt)
    {nil, state |> set_email(next_line: txt)}
  end

  defp run(_, state, _) do
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

  ## Callbacks

  def handle_call(:state, _, state) do
    {:reply, state.state, state}
  end

  def handle_call({:command, command}, _, state) do
    {response, new_state} = run(command, state, state.state)
    {:reply, response, new_state}
  end
end
