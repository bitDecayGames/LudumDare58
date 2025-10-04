package gameboard;

import haxe.ds.Vector;

typedef TileType = Int;
public static inline final EMPTY:TileType = 0;
public static inline final SOLID:TileType = 1;
public static inline final WALKABLE:TileType = 2;
public static inline final SLIDING:TileType = 3;
public static inline final WALKABLE_BREAKABLE:TileType = 4;
public static inline final SLIDING_BREAKABLE:TileType = 5;
public static inline final HOLE:TileType = 6;
public static inline final DEATH:TileType = -1;
typedef ObjectType = Int;
public static inline final NONE:ObjectType = 0;
public static inline final PLAYER:ObjectType = 1;
public static inline final COLLECTABLE:ObjectType = 2;
public static inline final BLOCK:ObjectType = 3;
public static inline final HAZARD:ObjectType = 4;
public static inline final EXIT:ObjectType = -1;
typedef MoveResult = Int;
public static inline final FAIL:MoveResult = 0;
public static inline final SUCCESS:MoveResult = 1;
public static inline final WIN:MoveResult = 2;
public static inline final LOSE:MoveResult = -1;

class GameBoardState {
	private final size:Int;
	private final length:Int;
	private final tileData:Vector<TileType>;
	private final objData:Array<GameBoardObject>;

	public function new(size:Int) {
		if (size <= 0) {
			throw new Error("cannot create game board state with size <= 0");
		}
		this.size = size;
		length = size * size;
		tileData = new Vector(length);
		objData = [];
	}

	public function getTile(x:Int, y:Int):TileType {
		var index = y * size + x;
		if (index >= length || index < 0) {
			return EMPTY;
		}
		return tileData[index];
	}

	public function setTile(x:Int, y:Int, v:TileType) {
		var index = y * size + x;
		if (index >= length || index < 0) {
			return;
		}
		tileData[index] = v;
	}

	public function getObj(x:Int, y:Int):GameBoardObject {
		var index = y * size + x;
		return objData.find((o) -> o.index == index);
	}

	public function findObj(id:Int):GameBoardObject {
		return objData.find((o) -> o.id == id);
	}

	public function addObj(x:Int, y:Int, v:GameBoardObject) {
		var index = y * size + x;
		if (index >= length || index < 0) {
			return;
		}
		objData.push(v);
	}

	public function save():Vector<Int> {
		var d = new Vector<Int>(length + objData.length * 3 + 2);
		d[0] = size;
		d[1] = objData.length;
		for (i in 0...length) {
			d[i + 2] = tileData[i];
		}
		for (i in 0...objData.length) {
			d[i + 0 + length + 2] = objData[i].id;
			d[i + 1 + length + 2] = objData[i].index;
			d[i + 2 + length + 2] = objData[i].type;
		}
		return d;
	}

	public static function load(d:Vector<Int>):GameBoardState {
		if (d.length == 0) {
			throw new Error("cannot load game board state from empty array");
		}
		var g = new GameBoardState(d[0]);
		for (i in 0...g.length) {
			tileData[i] = d[i + 2];
		}
		for (i in 0...(d[1] / 3)) {
			var o = new GameBoardObject();
			o.id = d[0 + g.length + i + 2];
			o.index = d[1 + g.length + i + 2];
			o.type = d[2 + g.length + i + 2];
			objData[i] = o;
		}
		return g;
	}
}

class GameBoardObject {
	public var id:Int;
	public var index:Int;
	public var type:ObjectType;
}
