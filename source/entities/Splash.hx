package entities;

import flixel.util.FlxTimer;
import states.PlayState;
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

class Splash extends FlxSprite {
	public static var anims = AsepriteMacros.tagNames("assets/aseprite/crateSplash.json");
	public static var layers = AsepriteMacros.layerNames("assets/aseprite/crateSplash.json");

	public function new(X:Float, Y:Float) {
		super(X, Y);
		Aseprite.loadAllAnimations(this, AssetPaths.crateSplash__json);
		// var vOffset = height - 24;
		// width = 32;
		// height = 32;
		offset.y = 30;
		animation.play(anims.animate);
		animation.onFinish.addOnce((_) -> {
			animation.pause();
			FlxTimer.wait(0.1, () -> {
				destroy();
			});
		});
		PlayState.ME.add(this);
	}

	public override function destroy() {
		PlayState.ME.remove(this);
		animation.destroy();
		super.destroy();
	}
}
