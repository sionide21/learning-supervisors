defmodule Supervisors.Email do
  defstruct to: [], from: nil, mime: ""

  def set(email, :from, address) do
    %__MODULE__{email | from: clean(address)}
  end

  def set(email, :to, address) do
    %__MODULE__{email | to: [clean(address) | email.to]}
  end

  def set(email, :next_line, line) do
    %__MODULE__{email | mime: email.mime <> line <> "\r\n"}
  end

  defp clean(email) do
    String.trim(email)
  end
end
