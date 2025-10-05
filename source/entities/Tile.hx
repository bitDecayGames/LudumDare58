package entities;

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
	public static var anims = AsepriteMacros.tagNames("assets/aseprite/player.json");
	public static var layers = AsepriteMacros.layerNames("assets/aseprite/player.json");

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
		Aseprite.loadAllAnimations(this, AssetPaths.player__json);
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
						// TODO: change to ice
						return new TweenCompletable(FlxTween.linearMotion(this, x, y, x, y, 0.6));
					default:
						return null;
				}
			case Crumble:
				switch (tileType) {
					case WALKABLE_BREAKABLE:
						// TODO: change from stone to hole/empty
						kill();
						return new TweenCompletable(FlxTween.linearMotion(this, x, y, x, y, 0.6));
					case SLIDING_BREAKABLE:
						// TODO: change from ice to hole/empty
						kill();
						return new TweenCompletable(FlxTween.linearMotion(this, x, y, x, y, 0.6));
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
