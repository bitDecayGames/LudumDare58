package entities;

import flixel.util.FlxTimer;
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
				var tweenDuration = 0.5;
				if (t == Push) {
					// getting pushed is hard work
					tweenDuration *= 2.0;
				} else if (t == Slide) {
					FmodPlugin.playSFX(FmodSFX.PushIceSlide);
				}
				return new TweenCompletable(FlxTween.linearMotion(this, x, y, dest[0] * 32, dest[1] * 32, tweenDuration));
			case Drop:
				
				FlxTimer.wait(0.25, () -> {
					FmodPlugin.playSFX(FmodSFX.BearSplash);
				});
				kill();
				new Splash(x, y);
				return null;
			case Bump:
				return new BumpCompletable(this, r.dir);
			case Die:
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
