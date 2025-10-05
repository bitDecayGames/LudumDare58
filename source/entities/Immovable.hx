package entities;

import todo.TODO;
import coordination.Completable;
import flixel.math.FlxPoint;
import bitdecay.flixel.spacial.Cardinal;
import flixel.util.FlxDirection;
import gameboard.GameBoard;
import gameboard.GameBoardMoveResult;
import flixel.tweens.FlxTween;
import flixel.util.FlxDirectionFlags;
import flixel.FlxSprite;
import input.InputCalculator;
import input.SimpleController;
import bitdecay.flixel.graphics.Aseprite;
import bitdecay.flixel.graphics.AsepriteMacros;
import flixel.FlxG;

class Immovable extends FlxSprite implements GameRenderObject {
	public static var anims = AsepriteMacros.tagNames("assets/aseprite/blockingTile.json");
	public static var layers = AsepriteMacros.layerNames("assets/aseprite/blockingTile.json");

	var id:Int = 0;

	public function new(id:Int, X:Float, Y:Float) {
		super(X, Y);
		this.id = id;
		Aseprite.loadAllAnimations(this, AssetPaths.blockingTile__json);
		var vOffset = height - 32;
		width = 32;
		height = 32;
		offset.y = vOffset;
	}

	public function handleGameResult(r:GameBoardMoveResult, board:GameBoard):Completable {
		var dest = r.endPos;
		var t = Type.getClass(r);
		switch (t) {
			case Bump:
				return new TweenCompletable(FlxTween.linearMotion(this, x, y, x, y, 0.6));
			default:
				// eh?
		}
		return null;
	}

	public function getId():Int {
		return id;
	}
}
