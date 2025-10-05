package gameboard;

import gameboard.GameBoardState.IMMOVABLE;
import gameboard.GameBoardState.WALKABLE;
import gameboard.GameBoardMoveResult.Melt;
import gameboard.GameBoardMoveResult.Shove;
import gameboard.GameBoardMoveResult.Win;
import gameboard.GameBoardMoveResult.Die;
import gameboard.GameBoardMoveResult.Slide;
import gameboard.GameBoardMoveResult.Collide;
import gameboard.GameBoardMoveResult.Lose;
import gameboard.GameBoardMoveResult.Drop;
import gameboard.GameBoardMoveResult.Crumble;
import gameboard.GameBoardMoveResult.Collect;
import gameboard.GameBoardMoveResult.Move;
import gameboard.GameBoardMoveResult.Push;
import gameboard.GameBoardMoveResult.Bump;
import gameboard.GameBoardMoveResult.WheelSpin;
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
			if (targetObj != null && (targetObj.type == BLOCK || targetObj.type == IMMOVABLE)) {
				results.push([new Bump(targetObj, dir)]);
			}
			return results;
		}

		history.push(current.save());

		var playerStandingStill = false;
		var cur:Array<GameBoardMoveResult> = [];
		if (targetObj != null && targetObj.type == BLOCK) {
			// if you are standing on ice, then you can't push blocks
			if (currentTile == SLIDING || currentTile == SLIDING_BREAKABLE) {
				results.push([new WheelSpin(playerObj, dir)]);
				return results;
			}
			if (targetTile == SLIDING || targetTile == SLIDING_BREAKABLE) {
				// shove doesn't move the player
				cur.push(new Shove(playerObj, targetObj, xy, targetXY, dir));
				playerStandingStill = true;
			} else {
				cur.push(new Push(playerObj, targetObj, xy, targetXY, dir));
				playerObj.index = current.vecToIndex(targetXY);
			}
		} else {
			var targetIsSlide = targetTile == SLIDING || targetTile == SLIDING_BREAKABLE;
			if (targetIsSlide) {
				// TODO: if you can switch between running and sliding half-way, then uncomment this and use the "Slide.partial" value to trigger it in Player class
				// cur.push(new Slide(playerObj, xy, targetXY, dir, true));
				// then you can get rid of this line
				cur.push(new Move(playerObj, xy, targetXY, dir));
			} else {
				cur.push(new Move(playerObj, xy, targetXY, dir));
			}
			playerObj.index = current.vecToIndex(targetXY);
		}
		if (!playerStandingStill && currentTile == WALKABLE) {
			current.setTile(xy[0], xy[1], SLIDING);
			cur.push(new Melt(xy));
		}
		if (targetObj != null && targetObj.type == COLLECTABLE) {
			cur.push(new Collect(playerObj, targetObj));
			cur.push(new Collect(targetObj, playerObj));
			current.removeObj(targetObj);
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
								cur.push(new Slide(targetObj, nextXY, checkXY, dir, false));
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
							cur.push(new Slide(targetObj, nextXY, checkXY, dir, false));
							if (nextTile == SLIDING_BREAKABLE) {
								current.setTile(nextXY[0], nextXY[1], HOLE);
								cur.push(new Crumble(nextXY));
							}
						}
					default:
						// do nothing
				}
			}

			if (!playerStandingStill) {
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
								cur.push(new Slide(targetObj, nextXY, checkXY, dir, false));
								if (targetTile == SLIDING_BREAKABLE) {
									current.setTile(targetXY[0], targetXY[1], HOLE);
									cur.push(new Crumble(targetXY));
								}
								results.push(cur);
								cur = [];
								cur.push(new Die(playerObj, checkXY));
								results.push(cur);
								cur = [];
								QLog.notice('some how you lose');
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
							cur.push(new Slide(playerObj, targetXY, checkXY, dir, false));
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
			cur.push(new Win(playerObj));
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
		if (targetObj != null) {
			if (targetObj.type == BLOCK) {
				if (nextTargetObj != null || nextTargetTile == SOLID || nextTargetTile == DEATH) {
					return false;
				}
			} else if (targetObj.type == IMMOVABLE) {
				return false;
			}
		}
		return true;
	}

	private function isWin(playerObj:GameBoardObject) {
		return current.getTileByIndex(playerObj.index) == EXIT;
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
