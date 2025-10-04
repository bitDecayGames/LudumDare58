package entities;

import gameboard.GameBoard;
import flixel.tweens.FlxTween;
import gameboard.GameBoard.GameBoardMoveResult;

interface GameRenderObject {
    public function handleGameResult(r:GameBoardMoveResult, board:GameBoard):FlxTween;
}