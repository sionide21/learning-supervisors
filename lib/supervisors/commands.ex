defmodule Supervisor.Commands do
  alias Supervisors.ClientState

  def run("QUIT", %{handler: conn}) do
    send conn, :exit
    "221 closing transmission channel"
  end

  def run(smtp, %{state: state}) do
    ClientState.command(state, smtp)
  end
end
