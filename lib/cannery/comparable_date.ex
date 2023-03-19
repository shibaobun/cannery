defmodule Cannery.ComparableDate do
  @moduledoc """
  A custom `Date` module that provides a `compare/2` function that is comparable
  with nil values
  """

  @spec compare(Date.t() | any(), Date.t() | any()) :: :lt | :gt | :eq
  def compare(%Date{} = date_1, %Date{} = date_2), do: Date.compare(date_1, date_2)
  def compare(%Date{}, _date_2), do: :lt
  def compare(_date_1, %Date{}), do: :gt
  def compare(_date_1, _date_2), do: :eq
end
