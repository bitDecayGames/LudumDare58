package gameboard;

import flixel.math.FlxPoint;
import gameboard.GameBoardState.WALKABLE_BREAKABLE;
import gameboard.GameBoardState.SLIDING_BREAKABLE;
import gameboard.GameBoardState.SLIDING;
import gameboard.GameBoardState.HOLE;
import gameboard.GameBoardState.HAZARD;
import gameboard.GameBoardState.COLLECTABLE;
import gameboard.GameBoardState.EXIT;
import gameboard.GameBoardState.GameBoardObject;
import gameboard.GameBoardState.DEATH;
import gameboard.GameBoardState.BLOCK;
import gameboard.GameBoardState.EMPTY;
import gameboard.GameBoardState.SOLID;
import gameboard.GameBoardState.TileType;
import bitdecay.flixel.spacial.Cardinal;
import haxe.ds.Vector;

abstract class GameBoardMoveResult {
	public var gameObj:GameBoardObject;
	public var startPos:Vector<Int>;
	public var endPos:Vector<Int>;
	public var dir:Cardinal;
}

class Move extends GameBoardMoveResult {
	public function new(gameObj:GameBoardObject, startPos:Vector<Int>, endPos:Vector<Int>, dir:Cardinal) {
		this.gameObj = gameObj;
		this.startPos = startPos;
		this.endPos = endPos;
		this.dir = dir;
	}

	public function toString():String {
		return 'Move(${gameObj.id} ${startPos} to ${endPos})';
	}
}

class Push extends GameBoardMoveResult {
	public var other:GameBoardObject;

	public function new(gameObj:GameBoardObject, other:GameBoardObject, startPos:Vector<Int>, endPos:Vector<Int>, dir:Cardinal) {
		this.gameObj = gameObj;
		this.other = other;
		this.startPos = startPos;
		this.endPos = endPos;
		this.dir = dir;
	}

	public function toString():String {
		return 'Push(${gameObj.id} pushes ${other.id} from ${startPos} to ${endPos})';
	}
}

class Slide extends GameBoardMoveResult {
	public function new(gameObj:GameBoardObject, startPos:Vector<Int>, endPos:Vector<Int>, dir:Cardinal) {
		this.gameObj = gameObj;
		this.startPos = startPos;
		this.endPos = endPos;
		this.dir = dir;
	}

	public function toString():String {
		return 'Slide(${gameObj.id} ${startPos} to ${endPos})';
	}
}

class Bump extends GameBoardMoveResult {
	public function new(gameObj:GameBoardObject, dir:Cardinal) {
		this.gameObj = gameObj;
		this.dir = dir;
	}

	public function toString():String {
		return 'Bump(${gameObj.id} ${dir})';
	}
}

class Collide extends GameBoardMoveResult {
	public var other:GameBoardObject;

	public function new(gameObj:GameBoardObject, other:GameBoardObject) {
		this.gameObj = gameObj;
		this.other = other;
	}

	public function toString():String {
		return 'Collide(${gameObj.id} and ${other.id})';
	}
}

class Collect extends GameBoardMoveResult {
	public var other:GameBoardObject;

	public function new(gameObj:GameBoardObject, other:GameBoardObject) {
		this.gameObj = gameObj;
		this.other = other;
	}

	public function toString():String {
		return 'Collect(${gameObj.id} and ${other.id})';
	}
}

class Drop extends GameBoardMoveResult {
	public var other:GameBoardObject;

	public function new(gameObj:GameBoardObject, pos:Vector<Int>) {
		this.gameObj = gameObj;
		this.startPos = pos;
	}

	public function toString():String {
		return 'Drop(${gameObj.id} at ${startPos})';
	}
}

class Crumble extends GameBoardMoveResult {
	public function new(pos:Vector<Int>) {
		gameObj = null;
		this.startPos = pos;
	}

	public function toString():String {
		return 'Crumble(${startPos})';
	}
}

class Die extends GameBoardMoveResult {
	public function new(gameObj:GameBoardObject, pos:Vector<Int>) {
		this.gameObj = gameObj;
		this.startPos = pos;
	}

	public function toString():String {
		return 'Die(${gameObj.id} at ${startPos})';
	}
}

class Lose extends GameBoardMoveResult {
	public function new() {}

	public function toString():String {
		return 'Lose()';
	}
}

class Win extends GameBoardMoveResult {
	public function new() {}

	public function toString():String {
		return 'Win()';
	}
}

class GameBoard {
	public var current:GameBoardState;

	private var initial:Vector<Int>;
	private var history:Array<Vector<Int>> = [];

	public function new(state:GameBoardState) {
		initial = state.save();
		current = GameBoardState.load(initial);
	}

	public function undo() {
		if (history.length == 0) {
			current = GameBoardState.load(initial);
			return;
		}
		var d = history.pop();
		current = GameBoardState.load(d);
	}

	public function reset() {
		history = [];
		current = GameBoardState.load(initial);
	}

	public function move(dir:Cardinal):Array<Array<GameBoardMoveResult>> {
		var results:Array<Array<GameBoardMoveResult>> = [];

		var playerObj = current.getPlayer();
		// TODO When would this happen?
		if (playerObj == null) {
			return [];
		}
		var xy = current.indexToXY(playerObj.index);
		var targetXY = new Vector<Int>(2);
		targetXY[0] = xy[0];
		targetXY[1] = xy[1];
		var nextXY = new Vector<Int>(2);
		nextXY[0] = xy[0];
		nextXY[1] = xy[1];
		targetXY = incr(targetXY, dir, 1);
		nextXY = incr(nextXY, dir, 2);
		var currentTile = current.getTile(xy[0], xy[1]);
		var targetTile = current.getTile(targetXY[0], targetXY[1]);
		var targetObj = current.getObj(targetXY[0], targetXY[1]);
		var nextTile = current.getTile(nextXY[0], nextXY[1]);
		var nextObj = current.getObj(nextXY[0], nextXY[1]);
		if (!isMovePossible(targetTile, targetObj, nextTile, nextObj)) {
			results.push([new Bump(playerObj, dir)]);
			if (targetObj != null && targetObj.type == BLOCK) {
				results.push([new Bump(targetObj, dir)]);
			}
			return results;
		}

		history.push(current.save());

		var cur:Array<GameBoardMoveResult> = [];
		playerObj.index = current.vecToIndex(targetXY);
		if (targetObj != null && targetObj.type == BLOCK) {
			cur.push(new Push(playerObj, targetObj, xy, targetXY, dir));
		} else {
			cur.push(new Move(playerObj, xy, targetXY, dir));
		}
		if (targetObj != null && targetObj.type == COLLECTABLE) {
			cur.push(new Collect(playerObj, targetObj));
		}
		if (currentTile == WALKABLE_BREAKABLE || currentTile == SLIDING_BREAKABLE) {
			current.setTile(xy[0], xy[1], HOLE);
			cur.push(new Crumble(xy));
		}
		if (targetObj != null && targetObj.type == BLOCK) {
			targetObj.index = current.vecToIndex(nextXY);
			cur.push(new Push(targetObj, playerObj, targetXY, nextXY, dir));

			if (targetTile == WALKABLE_BREAKABLE || targetTile == SLIDING_BREAKABLE) {
				current.setTile(targetXY[0], targetXY[1], HOLE);
				cur.push(new Crumble(targetXY));
				results.push(cur);
				cur = [];
				cur.push(new Drop(playerObj, targetXY));
				results.push(cur);
				cur = [];
				cur.push(new Lose());
				results.push(cur);
				return results;
			}
		}
		if (cur.length > 0) {
			results.push(cur);
		}
		cur = [];
		var playerDirty = true;
		var pushDirty = true;
		var targetDropped = false;
		while (playerDirty || pushDirty) {
			playerDirty = false;
			pushDirty = false;
			if (targetObj != null && targetObj.type == BLOCK) {
				switch (nextTile) {
					case EMPTY | HOLE:
						current.removeObj(targetObj);
						cur.push(new Drop(targetObj, nextXY));
						targetDropped = true;
					case SLIDING | SLIDING_BREAKABLE:
						var checkXY = incr(nextXY, dir, 1);
						var checkTile = current.getTile(checkXY[0], checkXY[1]);
						var checkObj = current.getObj(checkXY[0], checkXY[1]);
						if (checkObj != null) {
							if (checkObj.type == HAZARD) {
								pushDirty = true;
								cur.push(new Collide(targetObj, checkObj));
								current.removeObj(checkObj);
								targetObj.index = current.vecToIndex(checkXY);
								cur.push(new Slide(targetObj, nextXY, checkXY, dir));
								if (nextTile == SLIDING_BREAKABLE) {
									current.setTile(nextXY[0], nextXY[1], HOLE);
									cur.push(new Crumble(nextXY));
								}
							} else {
								cur.push(new Bump(targetObj, dir));
								cur.push(new Bump(checkObj, dir));
							}
						} else if (checkTile == SOLID || checkTile == DEATH) {
							cur.push(new Bump(targetObj, dir));
						} else {
							pushDirty = true;
							targetObj.index = current.vecToIndex(checkXY);
							cur.push(new Slide(targetObj, nextXY, checkXY, dir));
							if (nextTile == SLIDING_BREAKABLE) {
								current.setTile(nextXY[0], nextXY[1], HOLE);
								cur.push(new Crumble(nextXY));
							}
						}
					default:
						// do nothing
				}
			}

			switch (targetTile) {
				case EMPTY | HOLE:
					cur.push(new Drop(playerObj, targetXY));
					results.push(cur);
					cur = [];
					cur.push(new Lose());
					results.push(cur);
					return results;
				case SLIDING | SLIDING_BREAKABLE:
					var checkXY = incr(targetXY, dir, 1);
					var checkTile = current.getTile(checkXY[0], checkXY[1]);
					var checkObj = current.getObj(checkXY[0], checkXY[1]);
					if (checkObj != null) {
						if (checkObj.type == HAZARD) {
							playerObj.index = current.vecToIndex(checkXY);
							cur.push(new Slide(targetObj, nextXY, checkXY, dir));
							if (targetTile == SLIDING_BREAKABLE) {
								current.setTile(targetXY[0], targetXY[1], HOLE);
								cur.push(new Crumble(targetXY));
							}
							results.push(cur);
							cur = [];
							cur.push(new Die(playerObj, checkXY));
							results.push(cur);
							cur = [];
							cur.push(new Lose());
							results.push(cur);
							return results;
						} else {
							cur.push(new Bump(playerObj, dir));
							cur.push(new Bump(checkObj, dir));
						}
					} else if (checkTile == SOLID) {
						cur.push(new Bump(playerObj, dir));
					} else {
						playerDirty = true;
						playerObj.index = current.vecToIndex(checkXY);
						cur.push(new Slide(playerObj, targetXY, checkXY, dir));
						if (targetTile == SLIDING_BREAKABLE) {
							current.setTile(targetXY[0], targetXY[1], HOLE);
							cur.push(new Crumble(targetXY));
						}
					}
				case DEATH:
					cur.push(new Die(playerObj, targetXY));
					results.push(cur);
					cur = [];
					cur.push(new Lose());
					results.push(cur);
					return results;
				default:
					// do nothing
			}

			if (cur.length > 0) {
				results.push(cur);
				cur = [];
			}
			if (playerDirty) {
				targetXY = incr(targetXY, dir, 1);
				targetTile = current.getTile(targetXY[0], targetXY[1]);
			}
			if (pushDirty) {
				nextXY = incr(nextXY, dir, 1);
				nextTile = current.getTile(nextXY[0], nextXY[1]);
				nextObj = current.getObj(nextXY[0], nextXY[1]);
			}
		}

		if (cur.length > 0) {
			results.push(cur);
		}

		if (isWin(playerObj)) {
			cur.push(new Win());
			results.push(cur);
		}
		if (isLose(playerObj)) {
			cur.push(new Lose());
			results.push(cur);
		}
		return results;
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

	private function incr(v:Vector<Int>, dir:Cardinal, amount:Int):Vector<Int> {
		var r = new Vector<Int>(2);
		r[0] = v[0];
		r[1] = v[1];
		switch (dir) {
			case N:
				r[1] -= amount;
			case S:
				r[1] += amount;
			case W:
				r[0] -= amount;
			case E:
				r[0] += amount;
			default:
				throw "can only move in direction N, S, E, or W";
		}
		return r;
	}
}
