defmodule Supervisors.ClientState do
  use GenServer
  alias Supervisors.SMTPCommands

  def start_link do
    GenServer.start_link(__MODULE__, %{state: :init, email: nil})
  end

  def current_state(pid) do
    GenServer.call(pid, :state)
  end

  def command(pid, command) do
    GenServer.call(pid, {:command, command})
  end

  ## Callbacks

  def handle_call(:state, _, state) do
    {:reply, state.state, state}
  end

  def handle_call({:command, command}, _, state) do
    {response, new_state} = SMTPCommands.run(command, state)
    {:reply, response, new_state}
  end
end
