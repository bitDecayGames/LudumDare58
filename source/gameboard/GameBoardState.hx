package gameboard;

import haxe.ds.Vector;

typedef TileType = Int;
inline final EMPTY:TileType = 0;
inline final SOLID:TileType = 1;
inline final WALKABLE:TileType = 2;
inline final SLIDING:TileType = 3;
inline final WALKABLE_BREAKABLE:TileType = 4;
inline final SLIDING_BREAKABLE:TileType = 5;
inline final HOLE:TileType = 6;
inline final DEATH:TileType = -1;

typedef ObjectType = Int;
inline final NONE:ObjectType = 0;
inline final PLAYER:ObjectType = 1;
inline final COLLECTABLE:ObjectType = 2;
inline final COLLECTED_COLLECTABLE:ObjectType = 3;
inline final BLOCK:ObjectType = 4;
inline final HAZARD:ObjectType = 5;
inline final SPAWN:ObjectType = 6;
inline final EXIT:ObjectType = -1;

class GameBoardState {
	public final width:Int;
	public final height:Int;
	public final length:Int;

	private final tileData:Vector<TileType>;
	private final objData:Array<GameBoardObject>;

	private static var idCounter:Int = 0;

	public function new(width:Int, height:Int) {
		this.width = width;
		this.height = height;
		length = width * height;
		if (length <= 0) {
			throw "cannot create game board state with no tiles";
		}
		tileData = new Vector(length);
		objData = [];
	}

	public function getTile(x:Int, y:Int):TileType {
		var index = y * width + x;
		return getTileByIndex(index);
	}

	public function getTileByIndex(index:Int):TileType {
		if (index >= length || index < 0) {
			return EMPTY;
		}
		return tileData[index];
	}

	public function indexToXY(index:Int):Vector<Int> {
		var v = new Vector<Int>(2);
		v[0] = index % width;
		v[1] = Std.int(index / width);
		return v;
	}

	public function xyToIndex(x:Int, y:Int):Int {
		return y * width + x;
	}

	public function setTile(x:Int, y:Int, v:TileType) {
		var index = y * width + x;
		if (index >= length || index < 0) {
			return;
		}
		tileData[index] = v;
	}

	public function getObj(x:Int, y:Int):GameBoardObject {
		var index = y * width + x;
		var f = objData.filter((o) -> o.index == index);
		if (f.length == 0) {
			return null;
		}
		return f[0];
	}

	public function getPlayer():GameBoardObject {
		return findObjType(PLAYER);
	}

	public function getObjectsByIndex(index:Int):Array<GameBoardObject> {
		return objData.filter((o) -> o.index == index);
	}

	public function findObj(id:Int):GameBoardObject {
		var f = objData.filter((o) -> o.id == id);
		if (f.length == 0) {
			return null;
		}
		return f[0];
	}

	public function findObjType(type:ObjectType):GameBoardObject {
		var f = objData.filter((o) -> o.type == type);
		if (f.length == 0) {
			return null;
		}
		return f[0];
	}

	public function addObj(v:GameBoardObject) {
		if (v.id <= 0) {
			idCounter++;
			v.id = idCounter;
		}
		objData.push(v);
	}

	public function removeObj(v:GameBoardObject) {
		objData.remove(v);
	}

	public function save():Vector<Int> {
		// 3 data points for each object, 2 'header' Ints for board size
		var d = new Vector<Int>(length + objData.length * 3 + 2);
		d[0] = width;
		d[1] = height;
		for (i in 0...length) {
			d[i + 2] = tileData[i];
		}
		for (i in 0...objData.length) {
			// skip into our vector by our 2 header ints + 3 spaces for each object
			d[2 + (i*3) + 0] = objData[i].id;
			d[2 + (i*3) + 1] = objData[i].index;
			d[2 + (i*3) + 2] = objData[i].type;
		}
		return d;
	}

	public static function load(d:Vector<Int>):GameBoardState {
		if (d.length == 0) {
			throw "cannot load game board state from empty array";
		}
		var g = new GameBoardState(d[0], d[1]);
		for (i in 0...g.length) {
			g.tileData[i] = d[i + 2];
		}

		for (i in 0...Std.int(d[1] / 3)) {
			var o = new GameBoardObject();
			o.id = d[0 + g.length + i + 2];
			o.index = d[1 + g.length + i + 2];
			o.type = d[2 + g.length + i + 2];
			g.addObj(o);
		}
		return g;
	}
}

class GameBoardObject {
	public var id:Int;
	public var index:Int;
	public var type:ObjectType;

	public function new() {}
}
