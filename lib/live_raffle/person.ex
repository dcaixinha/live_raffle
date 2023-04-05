defmodule LiveRaffle.Person do
  defstruct [:person_name]
  @types %{person_name: :string}

  alias LiveRaffle.Person
  import Ecto.Changeset

  def changeset(%Person{} = person, attrs \\ %{}) do
    {person, @types}
    |> cast(attrs, Map.keys(@types))
    |> validate_required([:person_name])
    |> validate_length(:person_name, min: 3, max: 100)
    |> validate_name_is_unique(:person_name, attrs["name_taken"])
  end

  def validate_name_is_unique(changeset, field, name_taken) when is_atom(field) do
    validate_change(changeset, :person_name, fn :person_name, _person_name ->
      case name_taken do
        true -> [person_name: "name already taken"]

        _ -> []
      end
    end)
  end
end
