defmodule Cannery.ActivityLogFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Cannery.ActivityLog` context.
  """

  @doc """
  Generate a shot_group.
  """
  def shot_group_fixture(attrs \\ %{}) do
    {:ok, shot_group} =
      attrs
      |> Enum.into(%{
        count: 42,
        date: ~N[2022-02-13 03:17:00],
        notes: "some notes"
      })
      |> Cannery.ActivityLog.create_shot_group()

    shot_group
  end
end
