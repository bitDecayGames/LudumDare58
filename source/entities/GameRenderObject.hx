package entities;

import coordination.Completable;
import gameboard.GameBoard;
import gameboard.GameBoard.GameBoardMoveResult;

interface GameRenderObject {
	public function handleGameResult(r:GameBoardMoveResult, board:GameBoard):Completable;
	public function getId():Int;
}
