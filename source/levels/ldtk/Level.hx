package levels.ldtk;

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

	public var terrainLayer:BDTilemap;
	public var spawnPoint:FlxPoint = FlxPoint.get();
	public var blocks = new Array<FlxSprite>(); // TODO: make this an entity type for our game
	public var hazards = new Array<FlxSprite>(); // TODO: make this an entity type for our game

	public var camZones:Map<String, FlxRect>;
	public var camTransitions:Array<CameraTransition>;

	public var initialBoardState:GameBoardState;

	public function new(nameOrIID:String) {
		raw = project.getLevel(nameOrIID);
		terrainLayer = new BDTilemap();
		terrainLayer.loadLdtk(raw.l_Terrain);

		if (raw.l_Objects.all_Spawn.length == 0) {
			throw('no spawn found in level ${nameOrIID}');
		}

		var sp = raw.l_Objects.all_Spawn[0];
		spawnPoint.set(sp.pixelX, sp.pixelY);

		var test:Ldtk.Entity_Spawn = null;

		parseCameraZones(raw.l_Objects.all_CameraZone);
		parseCameraTransitions(raw.l_Objects.all_CameraTransition);
		parseBlocks(raw.l_Objects.all_Block);
		parseHazard(raw.l_Objects.all_Hazard);

		initialBoardState = new GameBoardState(terrainLayer.widthInTiles, terrainLayer.heightInTiles);

		for (x in 0...terrainLayer.widthInTiles) {
			for (y in 0...terrainLayer.heightInTiles) {
				// Filler for now until we figure out how to parse things properly
				if (terrainLayer.getTileIndex(x, y) > 0) {
					initialBoardState.setTile(x, y, WALKABLE);
				}
				// Ideally we turn the tiles directly from the tilemap into the game logic board
				// Do a max here to account for -1 being in empty tiles in the tilemap. Gameboard expects 0
				// initialBoardState.setTile(x, y, FlxMath.maxInt(0, terrainLayer.getTileIndex(x, y)));
			}
		}

		var spawnObj = new GameBoardObject();
		spawnObj.type = SPAWN;
		spawnObj.index = initialBoardState.xyToIndex(sp.cx, sp.cy);
		initialBoardState.addObj(spawnObj);
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

	function parseBlocks(blockDefs:Array<Ldtk.Entity_Block>) {
		for (b in blockDefs) {
			blocks.push(new FlxSprite(b.pixelX, b.pixelY));
		}
	}


	function parseHazard(hazardDefs:Array<Ldtk.Entity_Hazard>) {
		for (b in hazardDefs) {
			hazards.push(new FlxSprite(b.pixelX, b.pixelY));
		}
	}
}
