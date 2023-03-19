defmodule Cannery.ComparableDateTime do
  @moduledoc """
  A custom `DateTime` module that provides a `compare/2` function that is
  comparable with nil values
  """

  @spec compare(DateTime.t() | any(), DateTime.t() | any()) :: :lt | :gt | :eq
  def compare(%DateTime{} = datetime_1, %DateTime{} = datetime_2) do
    DateTime.compare(datetime_1, datetime_2)
  end

  def compare(%DateTime{}, _datetime_2), do: :lt
  def compare(_datetime_1, %DateTime{}), do: :gt
  def compare(_datetime_1, _datetime_2), do: :eq
end
