defmodule Supervisor.Commands do
  alias Supervisors.ClientState

  def run("echo " <> words, _) do
    words
  end

  def run("ping", _) do
    "pong"
  end

  def run("", _), do: nil

  def run("crash", _) do
    raise "Something Bad Happened"
  end

  def run("whoami", _) do
    inspect(self)
  end

  def run("state", %{state: state}) do
    inspect(ClientState.current_state(state))
  end

  def run("exit", %{handler: conn}) do
    send conn, :exit
    "goodbye"
  end

  def run(<<4>>, %{handler: conn}), do: run("exit", conn)

  def run(txt, _) do
    "Command not found: '#{txt}'"
  end
end
