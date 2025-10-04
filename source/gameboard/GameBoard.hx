package gameboard;

import gameboard.GameBoardState.HOLE;
import gameboard.GameBoardState.WIN;
import gameboard.GameBoardState.HAZARD;
import gameboard.GameBoardState.COLLECTABLE;
import gameboard.GameBoardState.EXIT;
import gameboard.GameBoardState.GameBoardObject;
import gameboard.GameBoardState.SUCCESS;
import gameboard.GameBoardState.DEATH;
import gameboard.GameBoardState.BLOCK;
import gameboard.GameBoardState.EMPTY;
import gameboard.GameBoardState.SOLID;
import gameboard.GameBoardState.TileType;
import gameboard.GameBoardState.ObjectType;
import gameboard.GameBoardState.FAIL;
import gameboard.GameBoardState.LOSE;
import gameboard.GameBoardState.PLAYER;
import gameboard.GameBoardState.MoveResult;
import bitdecay.flixel.spacial.Cardinal;
import haxe.ds.Vector;

class GameBoard {
	public var current:GameBoardState;

	private var initial:GameBoardState;
	private var history:Array<Vector<Int>> = [];

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
		var playerObj = current.findObjType(PLAYER);
		if (playerObj == null) {
			return LOSE;
		}
		var xy = current.indexToXY(playerObj.index);
		var targetXY = new Vector<Int>(2);
		targetXY[0] = xy[0];
		targetXY[1] = xy[1];
		var nextXY = new Vector<Int>(2);
		nextXY[0] = xy[0];
		nextXY[1] = xy[1];
		switch (dir) {
			case N:
				targetXY[1]--;
				nextXY[1] -= 2;
			case S:
				targetXY[1]++;
				nextXY[1] += 2;
			case W:
				targetXY[0]--;
				nextXY[0] -= 2;
			case E:
				targetXY[0]++;
				nextXY[0] += 2;
			default:
				throw "can only move in direction N, S, E, or W";
		}
		var targetTile = current.getTile(targetXY[0], targetXY[1]);
		var targetObj = current.getObj(targetXY[0], targetXY[1]);
		var nextTile = current.getTile(nextXY[0], nextXY[1]);
		var nextObj = current.getObj(nextXY[0], nextXY[1]);
		if (!isMovePossible(targetTile, targetObj, nextTile, nextObj)) {
			return FAIL;
		}

		history.push(current.save());

		doMove(playerObj, targetXY[0], targetXY[1]);

		if (isWin(playerObj)) {
			return WIN;
		}
		if (isLose(playerObj)) {
			return LOSE;
		}
		return SUCCESS;
	}

	private function isMovePossible(targetTile:TileType, targetObj:GameBoardObject, nextTargetTile:TileType, nextTargetObj:GameBoardObject):Bool {
		if (targetTile == SOLID) {
			return false;
		}
		if (targetObj != null && targetObj.type == BLOCK) {
			if ((nextTargetObj != null && nextTargetObj.type == BLOCK) || nextTargetTile == SOLID || nextTargetTile == DEATH) {
				return false;
			}
		}
		return true;
	}

	private function isWin(playerObj:GameBoardObject) {
		return current.getTileByIndex(playerObj.index) == EXIT && current.findObjType(COLLECTABLE) == null;
	}

	private function isLose(playerObj:GameBoardObject) {
		var curTile = current.getTileByIndex(playerObj.index);
		var sharesSpaceWithHazard = current.getObjectsByIndex(playerObj.index).filter((o) -> o.id != playerObj.id && o.type == HAZARD).length > 0;
		return curTile == DEATH || curTile == EMPTY || curTile == HOLE || sharesSpaceWithHazard;
	}

	private function doMove(player:GameBoardObject, x:Int, y:Int) {
		// TODO: do actual move logic, moving blocks, etc
	}
}
