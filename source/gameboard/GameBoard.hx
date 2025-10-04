package gameboard;

import gameboard.GameBoardState.*;
import bitdecay.flixel.spacial.Cardinal;

class GameBoard {
	public var current:GameBoardState;

	private var initial:GameBoardState;
	private final history:Array<Vector<Int>> = [];

	public function new(initial:GameBoardState) {
		this.initial = initial;
	}

	public function undo() {
		if (history.length == 0) {
			current = initial;
			return;
		}
		var d = history.pop();
		current = GameBoardState.load(d);
	}

	public function reset() {
		history = [];
		current = initial;
	}

	public function move(dir:Cardinal):MoveResult {
		return FAIL;
	}

	private function isMovePossible(targetTile:TileType, targetObj:ObjectType, nextTargetTile:TileType, nextTargetObj:ObjectType):Bool {
		if (targetTile == EMPTY || targetTile == SOLID) {
			return false;
		}
		if (targetObj == BLOCK) {
			if (nextTargetObj == BLOCK || nextTargetTile == EMPTY || nextTargetTile == SOLID || nextTargetTile == DEATH) {
				return false;
			}
		}
		return true;
	}
}
