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

class PushBlock extends FlxSprite implements GameRenderObject {
	public static var anims = AsepriteMacros.tagNames("assets/aseprite/crate.json");
	public static var layers = AsepriteMacros.layerNames("assets/aseprite/crate.json");

	var id:Int = 0;

	public function new(id:Int, X:Float, Y:Float) {
		super(X, Y);
		this.id = id;
		Aseprite.loadAllAnimations(this, AssetPaths.crate__json);
		var vOffset = height - 24;
		width = 32;
		height = 32;
		offset.y = vOffset;
	}

	public function handleGameResult(r:GameBoardMoveResult, board:GameBoard):Completable {
		var dest = r.endPos;
		var t = Type.getClass(r);
		switch (t) {
			case Move | Push | Slide:
				var tweenDuration = 0.6;
				if (t == Push) {
					// getting pushed is hard work
					tweenDuration *= 2.0;
					TODO.sfx('block is pushed one tile. Might be overlap with player push sound effect');
				} else if (t == Slide) {
					TODO.sfx('crate block slides across ice one tile');
				}
				return new TweenCompletable(FlxTween.linearMotion(this, x, y, dest[0] * 32, dest[1] * 32, tweenDuration));
			case Drop:
				TODO.sfx('crate block falls into water');
				// TODO: splash animation?
				kill();
				return null;
			default:
				// eh?
		}
		return null;
	}

	public function getId():Int {
		return id;
	}
}
