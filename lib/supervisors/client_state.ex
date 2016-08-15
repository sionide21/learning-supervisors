defmodule Supervisors.ClientState do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, %{state: :init, email: nil})
  end

  def current_state(pid) do
    GenServer.call(pid, :state)
  end

  ## Callbacks

  def handle_call(:state, _, state) do
    {:reply, state.state, state}
  end
end
