import spawn, { ActorContext, Broadcast, Kind, Value } from '@eigr/spawn-sdk'
import { checkDraw, checkWin } from './src/board'

const system = spawn.createSystem('game-system')
const actor = system.buildActor({
  name: 'tic_tac_toe',
  kind: Kind.UNAMED,
  stateful: true,
  deactivatedTimeout: 60_000n,
  stateType: 'json',
})

interface State {
  board: (null | number)[][]
  status: 'waiting_players' | 'playing' | 'finished' | 'finished_draw'
  players: string[]
  playerTurn: string | null
  playerWinner: string | null
  matchmakingRef: string
}

actor.addAction(
  { name: 'create' },
  async (ctx: ActorContext<State>, { matchmakingRef }) => {
    console.log('create', ctx, matchmakingRef)

    if (ctx.state.status === 'playing') return Value.of()

    const board = Array.from({ length: 3 }, () => Array(3).fill(null))
    const newState: State = {
      ...ctx.state,
      board,
      matchmakingRef,
      status: 'waiting_players',
      players: [],
    }

    return Value.of()
      .state(newState)
      .broadcast({
        action: 'created',
        channel: `match:${ctx.self.name}`,
        payload: newState,
      })
  }
)

actor.addAction(
  { name: 'join' },
  async (ctx: ActorContext<State>, { playerRef }) => {
    console.log('join', ctx, playerRef)

    if (
      ctx.state.players.find((p) => p === playerRef) ||
      ctx.state.players.length >= 2
    ) {
      return Value.of().response({
        board: ctx.state.board,
        players: ctx.state.players,
        playerTurn: ctx.state.playerTurn,
      })
    }

    const players = ctx.state.players
    players.push(playerRef)

    let playerTurn: string | null = null
    let status: string = 'waiting_players'

    if (players.length == 2) {
      status = 'playing'
      playerTurn = players[0]
    }

    const newState = { ...ctx.state, players, playerTurn, status }

    return Value.of()
      .state(newState)
      .response({ board: ctx.state.board, players, playerTurn })
      .broadcast({
        channel: `match:${ctx.self.name}`,
        payload: { event: 'join', state: newState },
      } as any)
  }
)

actor.addAction(
  { name: 'play' },
  async (ctx: ActorContext<State>, { playerRef, row, col }) => {
    console.log('play', ctx, playerRef, row, col)

    if (ctx.state.status !== 'playing') return Value.of()
    if (ctx.state.playerTurn != playerRef) return Value.of()
    if (ctx.state.board[row][col] !== null) return Value.of()

    const currentPlayerIndex = ctx.state.players.indexOf(playerRef)

    let board = ctx.state.board
    board[row][col] = currentPlayerIndex

    const won = checkWin(board, currentPlayerIndex)

    if (won || checkDraw(board)) {
      const status = won ? 'finished' : 'finished_draw'
      const newState = {
        ...ctx.state,
        board,
        status,
        playerWinner: won && playerRef,
      }

      return Value.of()
        .state({ ...ctx.state, board, status })
        .effects([
          {
            action: 'match_finished',
            actorName: ctx.state.matchmakingRef,
            payload: { ref: ctx.self.name },
          },
        ])
        .response({ board, status })
        .broadcast({
          channel: `match:${ctx.self.name}`,
          payload: { event: status, state: newState },
        } as any)
    }

    const playerTurn = ctx.state.players.find((p) => p !== playerRef)!
    const status = 'playing'
    const newState = { ...ctx.state, board, playerTurn, status }

    return Value.of()
      .state(newState)
      .response({ board, status })
      .broadcast({
        channel: `match:${ctx.self.name}`,
        payload: { event: 'play', state: newState },
      } as any)
  }
)

system.register().then((c) => console.log('Actors Registered', c))
