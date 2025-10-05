package entities;

import gameboard.GameBoardState.NON_MELTABLE_WALKABLE;
import gameboard.GameBoardState.SLIDING;
import gameboard.GameBoardState.EMPTY;
import gameboard.GameBoardState.SLIDING_BREAKABLE;
import gameboard.GameBoardState.WALKABLE_BREAKABLE;
import gameboard.GameBoardState.WALKABLE;
import gameboard.GameBoardState.TileType;
import coordination.Completable;
import gameboard.GameBoard;
import gameboard.GameBoardMoveResult;
import flixel.tweens.FlxTween;
import flixel.FlxSprite;
import bitdecay.flixel.graphics.Aseprite;
import bitdecay.flixel.graphics.AsepriteMacros;

class Tile extends FlxSprite implements GameRenderObject {
	public static final WIDTH:Int = 32;
	public static final HEIGHT:Int = 32;
	public static var anims = AsepriteMacros.tagNames("assets/aseprite/tilesLarge.json");
	public static var layers = AsepriteMacros.layerNames("assets/aseprite/tilesLarge.json");

	public final index:Int;
	public final cellX:Int;
	public final cellY:Int;

	public var tileType:TileType;

	public function new(index:Int, cellX:Int, cellY:Int, tileType:TileType) {
		super(cellX * WIDTH, cellY * HEIGHT);
		this.index = index;
		this.cellX = cellX;
		this.cellY = cellY;

		// This call can be used once https://github.com/HaxeFlixel/flixel/pull/2860 is merged
		// FlxAsepriteUtil.loadAseAtlasAndTags(this, AssetPaths.player__png, AssetPaths.player__json);
		Aseprite.loadAllAnimations(this, AssetPaths.tilesLarge__json);
		// animation.onFrameChange.add((anim, frame, index) -> {
		// 	if (eventData.exists(index)) {
		// 		trace('frame $index has data ${eventData.get(index)}');
		// 	}
		// });

		// var vOffset = height - 32;
		// width = 32;
		// height = 32;

		// offset.y = vOffset;

		setTileType(tileType);
	}

	public function setTileType(tileType:TileType) {
		switch (tileType) {
			case EMPTY:
				// set sprite to empty
				kill();
			case WALKABLE:
				animation.play(anims.snow);
				animation.pause();
			case SLIDING:
				animation.play(anims.ice);
				animation.pause();
			case NON_MELTABLE_WALKABLE:
				animation.play(anims.rock);
				animation.pause();
			default:
				// huh?
		}
	}

	public function handleGameResult(r:GameBoardMoveResult, board:GameBoard):Completable {
		var t = Type.getClass(r);
		switch (t) {
			case Melt:
				switch (tileType) {
					case WALKABLE:
						return new AnimationCompletable(animation, anims.snow2ice, () -> {
							setTileType(SLIDING);
						});
					default:
						return null;
				}
			case Crumble:
				switch (tileType) {
					case SLIDING_BREAKABLE:
						return new AnimationCompletable(animation, anims.brokenice2nothing, () -> {
							setTileType(EMPTY);
						});
					default:
						return null;
				}
			default:
				// do nothing
		}
		return null;
	}

	public function getId():Int {
		return index;
	}
}
