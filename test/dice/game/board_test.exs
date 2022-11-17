defmodule Dice.Game.BoardTest do
  use ExUnit.Case

  alias Dice.Game.{Snapshot, Board, BoardRow}

  test "new/0 generates new boards" do
    assert Board.new() == [
             [0, 0, 0],
             [0, 0, 0],
             [0, 0, 0]
           ]

    assert Board.new(2) == [
             [0, 0, 0],
             [0, 0, 0]
           ]

    assert Board.new(2, 4) == [
             [0, 0, 0, 0],
             [0, 0, 0, 0]
           ]
  end

  test "snapshot/1 snapshot for board" do
    board = [[1, 0, 0], [1, 1, 0], [0, 0, 0]]

    match_board = [
      %BoardRow{row: [1, 0, 0]},
      %BoardRow{row: [1, 1, 0]},
      %BoardRow{row: [0, 0, 0]}
    ]

    assert %Snapshot{board: ^match_board, rows_sum: [1, 4, 0], total: 5} =
             Board.get_snapshot(board)
  end

  test "finished/1 return if board is finished or not" do
    board = [
      [0, 0, 0],
      [0, 0, 0],
      [0, 0, 0]
    ]

    assert false == Board.finished?(board)

    board = [
      [5, 5, 5],
      [4, 7, 6],
      [1, 4, 1]
    ]

    assert true == Board.finished?(board)
  end

  test "total/1 return total score of board" do
    board = [
      [0, 0, 0],
      [0, 0, 0],
      [0, 0, 0]
    ]

    assert 0 == Board.total(board)

    # 20
    # 54
    # 6
    board = [
      [5, 5, 0],
      [6, 6, 6],
      [1, 2, 3]
    ]

    assert 20 + 54 + 6 == Board.total(board)
  end

  test "rows_sum/1 return total score of each row" do
    board = [
      [5, 0, 0],
      [6, 6, 0],
      [0, 0, 0]
    ]

    assert [5, 24, 0] == Board.rows_sum(board)
  end

  test "push/3 pushes a new value to a row stack" do
    board = [
      [5, 0, 0],
      [6, 6, 0],
      [0, 0, 0]
    ]

    assert [
             [5, 6, 0],
             [6, 6, 0],
             [0, 0, 0]
           ] == Board.push(board, 0, 6)

    assert [
             [5, 6, 6],
             [6, 6, 0],
             [1, 0, 0]
           ] == Board.push(board, 0, 6) |> Board.push(0, 6) |> Board.push(2, 1)
  end

  test "pop/3 pops a value from stack" do
    board = [
      [5, 1, 5],
      [6, 6, 0],
      [0, 0, 0]
    ]

    assert [
             [1, 0, 0],
             [6, 6, 0],
             [0, 0, 0]
           ] == Board.pop(board, 0, 5)

    assert [
             [0, 0, 0],
             [0, 0, 0],
             [0, 0, 0]
           ] == Board.pop(board, 0, 5) |> Board.pop(0, 1) |> Board.pop(1, 6)
  end
end
