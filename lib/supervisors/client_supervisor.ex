defmodule Supervisors.ClientSupervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def start_child(socket) do
    Supervisor.start_child(__MODULE__, [socket])
  end

  def init([]) do
    children = [
      worker(Supervisors.Client, [], restart: :temporary)
    ]

    supervise(children, strategy: :simple_one_for_one)
  end
end
