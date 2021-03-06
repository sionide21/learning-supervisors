defmodule Supervisors.ClientHandler do
  use GenServer

  alias Supervisors.{Client, ClientState}

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

    if ClientState.current_state(client.state) == :init do
      send_reply("220 Simple Mail Transfer Service Ready", client)
    end

    send self, :listen
    {:noreply, client}
  end

  def handle_info(:listen, client) do
    listen(client)
    {:noreply, client}
  end

  defp listen(client) do
    client
      |> read_command
      |> run_command(client)
      |> handle_reply(client)
    send self, :listen
  end

  defp run_command(command, %{state: state}) do
    ClientState.command(state, command)
  end

  defp handle_reply({:halt, reply}, client) do
    send_reply(reply, client)
    Supervisor.stop(client.parent)
  end
  defp handle_reply(reply, client), do: send_reply(reply, client)

  defp send_reply(nil, _), do: :ok
  defp send_reply(reply, client) do
    :ok = :gen_tcp.send(client.socket, reply <> "\r\n")
  end

  defp read_command(client) do
    {:ok, command} = :gen_tcp.recv(client.socket, 0)
    command |> String.trim
  end
end
