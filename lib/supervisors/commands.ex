defmodule Supervisor.Commands do
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

  def run("exit", conn) do
    send conn, :exit
    "goodbye"
  end

  def run(<<4>>, conn), do: run("exit", conn)

  def run(txt, _) do
    "Command not found: '#{txt}'"
  end
end
