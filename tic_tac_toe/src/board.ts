export const checkWin = (
  board: (null | number)[][],
  playerIndex: number
): boolean => {
  for (let i = 0; i < 3; i++) {
    if (
      board[i].every((cell) => cell === playerIndex) ||
      board.every((row) => row[i] === playerIndex)
    ) {
      return true
    }
  }

  if (
    board[0][0] === playerIndex &&
    board[1][1] === playerIndex &&
    board[2][2] === playerIndex
  ) {
    return true
  }
  if (
    board[0][2] === playerIndex &&
    board[1][1] === playerIndex &&
    board[2][0] === playerIndex
  ) {
    return true
  }
  return false
}

export const checkDraw = (board: (null | number)[][]) =>
  board.flat().every((cell) => cell !== null)
