package gameboard;

import bitdecay.flixel.spacial.Cardinal;
import gameboard.GameBoardState.GameBoardObject;
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

class Shove extends GameBoardMoveResult {
	public var other:GameBoardObject;

	public function new(gameObj:GameBoardObject, other:GameBoardObject, startPos:Vector<Int>, endPos:Vector<Int>, dir:Cardinal) {
		this.gameObj = gameObj;
		this.other = other;
		this.startPos = startPos;
		this.endPos = endPos;
		this.dir = dir;
	}

	public function toString():String {
		return 'Shove(${gameObj.id} pushes ${other.id} from ${startPos} to ${endPos})';
	}
}

class Slide extends GameBoardMoveResult {
	public var partial:Bool = false;

	public function new(gameObj:GameBoardObject, startPos:Vector<Int>, endPos:Vector<Int>, dir:Cardinal, partial:Bool) {
		this.gameObj = gameObj;
		this.startPos = startPos;
		this.endPos = endPos;
		this.dir = dir;
		this.partial = partial;
	}

	public function toString():String {
		return 'Slide(${gameObj?.id} ${startPos} to ${endPos})';
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

class WheelSpin extends GameBoardMoveResult {
	public function new(gameObj:GameBoardObject, dir:Cardinal) {
		this.gameObj = gameObj;
		this.dir = dir;
	}

	public function toString():String {
		return 'WheelSpin(${gameObj.id} ${dir})';
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

class Melt extends GameBoardMoveResult {
	public function new(pos:Vector<Int>) {
		gameObj = null;
		this.startPos = pos;
	}

	public function toString():String {
		return 'Melt(${startPos})';
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
	public function new(gameObj:GameBoardObject) {
		this.gameObj = gameObj;
	}

	public function toString():String {
		return 'Win(${gameObj.id})';
	}
}
