defmodule Supervisors.ClientHandler do
  use GenServer

  alias Supervisors.Client

  def start_link(client) do
    GenServer.start_link(__MODULE__, client)
  end

  def init(client) do
    send self, :load_state
    {:ok, client}
  end

  def handle_info(:load_state, client) do
    client = %{client |
      state: Client.fetch_state(client.parent),
      handler: self
    }
    send self, :listen
    {:noreply, client}
  end

  def handle_info(:listen, client) do
    listen(client)
    {:noreply, client}
  end

  def handle_info(:exit, client) do
    Supervisor.stop(client.parent)
    {:noreply, client}
  end

  defp listen(client) do
    client
      |> prompt
      |> read_command
      |> String.trim
      |> Supervisor.Commands.run(client)
      |> send_reply(client)
    send self, :listen
  end

  defp prompt(client) do
    :ok = :gen_tcp.send(client.socket, "> ")
    client
  end

  defp send_reply(nil, client), do: :ok

  defp send_reply(reply, client) do
    :ok = :gen_tcp.send(client.socket, reply <> "\n")
  end

  defp read_command(client) do
    {:ok, command} = :gen_tcp.recv(client.socket, 0)
    command
  end
end
