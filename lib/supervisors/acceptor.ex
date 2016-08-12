defmodule Supervisors.Acceptor do
  use GenServer

  def start_link(port) do
    GenServer.start_link(__MODULE__, port)
  end

  def init(port) do
    {:ok, socket} = :gen_tcp.listen(port, [
      :binary, packet: :line, backlog: 2048,
      active: false, reuseaddr: true])

    send self, :accept

    {:ok, socket}
  end

  def handle_info(:accept, socket) do
    accept(socket)
  end

  defp accept(socket) do
    {:ok, client} = :gen_tcp.accept(socket)
    {:ok, pid} = Supervisors.ClientSupervisor.start_child(client)
     :ok = :gen_tcp.controlling_process(client, pid)

    accept(socket)
  end
end
