package entities;

import flixel.math.FlxPoint;
import bitdecay.flixel.spacial.Cardinal;
import flixel.util.FlxDirection;
import gameboard.GameBoard;
import gameboard.GameBoard.GameBoardMoveResult;
import flixel.tweens.FlxTween;
import flixel.util.FlxDirectionFlags;
import flixel.FlxSprite;
import input.InputCalculator;
import input.SimpleController;
import bitdecay.flixel.graphics.Aseprite;
import bitdecay.flixel.graphics.AsepriteMacros;
import flixel.FlxG;

class PushBlock extends FlxSprite implements GameRenderObject {
	public static var anims = AsepriteMacros.tagNames("assets/aseprite/crate.json");
	public static var layers = AsepriteMacros.layerNames("assets/aseprite/crate.json");

	var id:Int = 0;

	public function new(id:Int, X:Float, Y:Float) {
		super(X, Y);
		this.id = id;
		Aseprite.loadAllAnimations(this, AssetPaths.crate__json);
		var vOffset = height - 32;
		width = 32;
		height = 32;
		offset.y = vOffset;
	}

	public function handleGameResult(r:GameBoardMoveResult, board:GameBoard):FlxTween {
		var dest = r.endPos;
		var t = Type.getClass(r);
		if (t == Move || t == Slide) {
			return FlxTween.linearMotion(this, x, y, dest[0] * 32, dest[1] * 32, 0.6);
		}
		return null;
	}

	public function getId():Int {
		return id;
	}
}
