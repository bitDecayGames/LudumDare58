package entities;

import coordination.Completable;
import gameboard.GameBoard;
import gameboard.GameBoardMoveResult;

interface GameRenderObject {
	public function handleGameResult(r:GameBoardMoveResult, board:GameBoard):Completable;
	public function getId():Int;
}
