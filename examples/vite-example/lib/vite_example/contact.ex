defmodule ViteExample.Contact do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :name, :string
    field :email, :string
    field :message, :string
    field :subscribe, :boolean, default: false
  end

  def changeset(contact, attrs) do
    contact
    |> cast(attrs, [:name, :email, :message, :subscribe])
    |> validate_required([:name, :email, :message])
    |> validate_format(:email, ~r/@/)
    |> validate_length(:name, min: 2, max: 100)
    |> validate_length(:message, min: 10, max: 1000)
  end
end
