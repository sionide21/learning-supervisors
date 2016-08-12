defmodule Supervisors.Client do
  use Supervisor

  def start_link(socket) do
    Supervisor.start_link(__MODULE__, socket)
  end

  def init(socket) do
    client = %{
      socket: socket,
      parent: self
    }

    children = [
      worker(Supervisors.ClientHandler, [client], restart: :transient)
    ]

    supervise(children, strategy: :one_for_one)
  end
end
