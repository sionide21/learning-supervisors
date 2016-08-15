defmodule Supervisors.Client do
  use Supervisor

  def start_link(socket) do
    Supervisor.start_link(__MODULE__, socket)
  end

  def init(socket) do
    client = %{
      socket: socket,
      parent: self,
      handler: nil,
      state: nil
    }

    children = [
      worker(Supervisors.ClientState, [], id: :state),
      worker(Supervisors.ClientHandler, [client], restart: :transient)
    ]

    supervise(children, strategy: :rest_for_one)
  end

  def fetch_state(pid) do
    pid
      |> Supervisor.which_children
      |> Enum.find(fn {id, _, _, _} -> id == :state end)
      |> elem(1)
  end
end
