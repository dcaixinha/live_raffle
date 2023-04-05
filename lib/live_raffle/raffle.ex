defmodule LiveRaffle.Raffle do
  defstruct [:raffle_name]
  @types %{raffle_name: :string}

  alias LiveRaffle.Raffle
  import Ecto.Changeset

  def changeset(%Raffle{} = raffle, attrs \\ %{}) do
    {raffle, @types}
    |> cast(attrs, Map.keys(@types))
    |> validate_required([:raffle_name])
    |> validate_length(:raffle_name, min: 3, max: 100)
    |> validate_name_is_unique(:raffle_name)
  end

  def validate_name_is_unique(changeset, field) when is_atom(field) do
    validate_change(changeset, :raffle_name, fn :raffle_name, raffle_name ->
      case Registry.lookup(RaffleRegistry, "raffle_#{raffle_name}") do
        [] -> []

        _ -> [raffle_name: "name already taken"]
      end
    end)
  end
end
