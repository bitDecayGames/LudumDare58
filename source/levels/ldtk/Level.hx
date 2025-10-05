package levels.ldtk;

import entities.Immovable;
import entities.Tile;
import entities.Seal;
import entities.GameRenderObject;
import entities.Player;
import entities.PushBlock;
import haxe.ds.Vector;
import flixel.math.FlxMath;
import gameboard.GameBoardState;
import entities.CameraTransition;
import flixel.math.FlxRect;
import flixel.math.FlxPoint;
import flixel.FlxSprite;
import levels.ldtk.Ldtk.LdtkProject;

using levels.ldtk.LdtkUtils;

/**
 * The middle layer between LDTK project and game code. This class
 * should do all of the major parsing of project data into flixel
 * types and basic game objects.
**/
class Level {
	public static var project = new LdtkProject();

	/**
	 * The raw level from the project. Available to get any needed
	 * one-off values out of the level for special use-cases
	**/
	public var raw:Ldtk.Ldtk_Level;

	private var terrainLayer:BDTilemap;

	public var spawnPoint:FlxPoint = FlxPoint.get();
	public var spawnPointCell:Vector<Int>;
	public var player:Player;
	public var blocks = new Array<FlxSprite>();
	public var waterFlavor = new Array<FlxSprite>();
	public var hazards = new Array<FlxSprite>(); // TODO: make this an entity type for our game
	public var collectables = new Array<Seal>();
	public var tiles = new Array<Tile>();

	public var camZones:Map<String, FlxRect>;
	public var camTransitions:Array<CameraTransition>;

	public var initialBoardState:GameBoardState;

	public var renderObjectsById:Map<Int, GameRenderObject> = new Map<Int, GameRenderObject>();
	public var tilesById:Map<Int, Tile> = new Map<Int, Tile>();

	public final name:String;

	public function new(nameOrIID:String) {
		name = nameOrIID;
		raw = project.getLevel(nameOrIID);
		terrainLayer = new BDTilemap();
		terrainLayer.loadLdtk(raw.l_Terrain);

		if (raw.l_Objects.all_Spawn.length == 0) {
			throw('no spawn found in level ${nameOrIID}');
		}

		initialBoardState = new GameBoardState(terrainLayer.widthInTiles, terrainLayer.heightInTiles);

		var sp = raw.l_Objects.all_Spawn[0];
		spawnPoint.set(sp.pixelX, sp.pixelY);
		spawnPointCell = new Vector<Int>(2);
		spawnPointCell[0] = sp.cx;
		spawnPointCell[1] = sp.cy;

		var playerObj = new GameBoardObject();
		playerObj.type = PLAYER;
		playerObj.index = initialBoardState.xyToIndex(sp.cx, sp.cy);
		initialBoardState.addObj(playerObj);
		player = new Player(playerObj.id, spawnPoint.x, spawnPoint.y);
		renderObjectsById.set(player.getId(), player);

		var test:Ldtk.Entity_Spawn = null;

		parseCameraZones(raw.l_Objects.all_CameraZone);
		parseCameraTransitions(raw.l_Objects.all_CameraTransition);
		parseBlocks(raw.l_Objects.all_Block);
		parseHazards(raw.l_Objects.all_Hazard);
		parseCollectables(raw.l_Objects.all_Collectable);
		parseTiles(terrainLayer);
		// TODO: uncomment me
		// parseWaterFlavor(thingGoesHere);
	}

	function parseCameraZones(zoneDefs:Array<Ldtk.Entity_CameraZone>) {
		camZones = new Map<String, FlxRect>();
		for (z in zoneDefs) {
			camZones.set(z.iid, FlxRect.get(z.pixelX, z.pixelY, z.width, z.height));
		}
	}

	function parseCameraTransitions(areaDefs:Array<Ldtk.Entity_CameraTransition>) {
		camTransitions = new Array<CameraTransition>();
		for (def in areaDefs) {
			var transArea = FlxRect.get(def.pixelX, def.pixelY, def.width, def.height);
			var camTrigger = new CameraTransition(transArea);
			for (i in 0...def.f_Directions.length) {
				camTrigger.addGuideTrigger(def.f_Directions[i].toCardinal(), camZones.get(def.f_Zones[i].entityIid));
			}
			camTransitions.push(camTrigger);
		}
	}

	function parseTiles(terrainLayer:BDTilemap) {
		for (x in 0...terrainLayer.widthInTiles) {
			for (y in 0...terrainLayer.heightInTiles) {
				var tileType = Std.int(Math.max(0, terrainLayer.getTileIndex(x, y)));
				var index = initialBoardState.xyToIndex(x, y);
				initialBoardState.setTile(x, y, tileType);
				var tile = new Tile(index, x, y, tileType);
				tiles.push(tile);
				tilesById.set(index, tile);
			}
		}
	}

	function parseBlocks(blockDefs:Array<Ldtk.Entity_Block>) {
		for (b in blockDefs) {
			var obj = new GameBoardObject();
			initialBoardState.addObj(obj);
			obj.index = initialBoardState.xyToIndex(b.cx, b.cy);
			var v:GameRenderObject;
			if (b.f_Type == Ldtk.Enum_BlockType.WallBlock) {
				obj.type = IMMOVABLE;
				v = new Immovable(obj.id, b.pixelX, b.pixelY);
			} else {
				obj.type = BLOCK;
				v = new PushBlock(obj.id, b.pixelX, b.pixelY);
			}
			renderObjectsById.set(v.getId(), v);
			blocks.push(cast v);
		}
	}

	function parseHazards(hazardDefs:Array<Ldtk.Entity_Hazard>) {
		for (b in hazardDefs) {
			var obj = new GameBoardObject();
			obj.index = initialBoardState.xyToIndex(b.cx, b.cy);
			obj.type = HAZARD;
			initialBoardState.addObj(obj);
			// TODO: create a hazard entity and swap this one out
			var v = new FlxSprite(b.pixelX, b.pixelY);
			// TODO: uncomment me
			// renderObjectsById.set(v.getId(), v);
			hazards.push(v);
		}
	}

	function parseCollectables(defs:Array<Ldtk.Entity_Collectable>) {
		for (v in defs) {
			var obj = new GameBoardObject();
			obj.index = initialBoardState.xyToIndex(v.cx, v.cy);
			obj.type = COLLECTABLE;
			initialBoardState.addObj(obj);
			var v = new Seal(obj.id, v.pixelX, v.pixelY);
			renderObjectsById.set(v.getId(), v);
			collectables.push(v);
		}
	}

	function parseWaterFlavor(defs:Array<Dynamic>) {
		for (b in defs) {
			// TODO: separate fish from ice blocks
			var v = new FlxSprite(b.pixelX, b.pixelY);
			waterFlavor.push(v);
		}
	}

	public function getBounds():FlxRect {
		return terrainLayer.getBounds();
	}
}
