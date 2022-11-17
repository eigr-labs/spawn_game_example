defmodule Dice.Game.Board do
  @moduledoc """
  Define board rule verifiers

  ```
  Board direction
    5 5 6 (26) --->
    3 0 0 (3)  --->
    6 1 0 (7)  --->
  Total board value: 36
  ```
  """

  @typedoc """
  Board matrix

  ```
  example = [
    [5, 5, 6],
    [3, 0, 0],
    [0, 0, 0]
  ]
  ```
  """

  alias Dice.Game.{Snapshot, BoardRow}

  @type board :: list(list(integer()))

  @typedoc "Row index starting with 0, usually 0 to 2"
  @type index :: integer

  @spec new :: board
  @doc "Generates a new board following number of cols and rows"
  def new(rows \\ 3, cols \\ 3) do
    Enum.map(1..rows, fn _ ->
      Enum.map(1..cols, fn _ -> 0 end)
    end)
  end

  @doc "Generates a snapshot for a specific board"
  @spec get_snapshot(board) :: Snapshot.t()
  def get_snapshot(board) do
    wrapped_board = maybe_wrap_board(board)

    %Snapshot{board: wrapped_board, rows_sum: rows_sum(board), total: total(board)}
  end

  @spec unwrap_snapshot(Snapshot.t() | nil) :: Snapshot.t() | nil
  def unwrap_snapshot(nil), do: nil

  def unwrap_snapshot(snapshot) do
    board = maybe_unwrap_board(snapshot.board)

    %Snapshot{snapshot | board: board}
  end

  @spec finished?(board) :: boolean()
  def finished?(board) do
    board = maybe_unwrap_board(board)

    Enum.all?(board, &Enum.all?(&1, fn num -> num != 0 end))
  end

  @spec roll_dice :: integer()
  def roll_dice do
    :rand.uniform(6)
  end

  @spec is_row_full?(board, index) :: boolean()
  def is_row_full?(board, row_index) do
    board = maybe_unwrap_board(board)

    board
    |> Enum.at(row_index)
    |> row_full?
  end

  @spec rows_sum(board) :: list(integer())
  def rows_sum(board) do
    board = maybe_unwrap_board(board)

    board
    |> Enum.map(&calculate_row_value/1)
  end

  @spec total(board) :: integer()
  def total(board) do
    board = maybe_unwrap_board(board)

    board
    |> rows_sum()
    |> Enum.sum()
  end

  @spec push(board, index, integer()) :: board()
  def push(board, row_index, number) when is_integer(row_index) and is_integer(number) do
    board = maybe_unwrap_board(board)

    board
    |> Enum.at(row_index)
    |> then(fn
      nil ->
        board

      row ->
        new_row =
          case row_full?(row) do
            true ->
              row

            false ->
              available_slot_index = Enum.find_index(row, &(&1 == 0))

              List.replace_at(row, available_slot_index, number)
          end

        List.replace_at(board, row_index, new_row)
    end)
  end

  def push(board, _, _), do: board

  @spec pop(board, index, integer()) :: board()
  def pop(board, row_index, number) when is_integer(row_index) and is_integer(number) do
    board = maybe_unwrap_board(board)

    board
    |> Enum.at(row_index)
    |> then(fn
      nil ->
        board

      row ->
        new_row = Enum.reject(row, &(&1 == number)) |> fill_row_size(Enum.count(row))

        List.replace_at(board, row_index, new_row)
    end)
  end

  def pop(board, _, _), do: board

  defp maybe_unwrap_board(board) do
    Enum.map(board, fn
      %BoardRow{row: row} -> row
      row -> row
    end)
  end

  defp maybe_wrap_board(board) do
    Enum.map(board, fn
      %BoardRow{row: row} -> row
      row -> BoardRow.new(row: row)
    end)
  end

  defp fill_row_size(row, row_count) do
    (row ++ Enum.map(1..row_count, fn _ -> 0 end)) |> Enum.slice(0, row_count)
  end

  defp row_full?(row) do
    not Enum.any?(row, &(&1 == 0))
  end

  defp calculate_row_value(row) do
    row
    |> Enum.frequencies()
    |> Enum.reduce(0, fn {num, times}, total ->
      total + num * times * times
    end)
  end
end
