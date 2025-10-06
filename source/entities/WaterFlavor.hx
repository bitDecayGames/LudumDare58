package entities;

import flixel.math.FlxRandom;
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

final r:FlxRandom = new FlxRandom();

function bob(obj:FlxSprite) {
	var radius = r.int(2, 7);
	var duration = 3 + radius * .5;
	FlxTween.circularMotion(obj, obj.x, obj.y, radius, 0, radius % 2 == 0, duration, {type: LOOPING});
}

class IceBlock1 extends FlxSprite {
	public static var anims = AsepriteMacros.tagNames("assets/aseprite/ice1.json");
	public static var layers = AsepriteMacros.layerNames("assets/aseprite/ice1.json");

	public function new(X:Float, Y:Float) {
		super(X, Y);
		Aseprite.loadAllAnimations(this, AssetPaths.ice1__json);
		// var vOffset = height - 24;
		// width = 32;
		// height = 32;
		animation.play(anims.animate);

		bob(this);

		@:privateAccess
		PlayState.ME.actionGroup.add(this);
	}
}

class IceBlock2 extends FlxSprite {
	public static var anims = AsepriteMacros.tagNames("assets/aseprite/ice2.json");
	public static var layers = AsepriteMacros.layerNames("assets/aseprite/ice2.json");

	public function new(X:Float, Y:Float) {
		super(X, Y);
		Aseprite.loadAllAnimations(this, AssetPaths.ice2__json);
		// var vOffset = height - 24;
		// width = 32;
		// height = 32;
		animation.play(anims.animate);

		bob(this);

		@:privateAccess
		PlayState.ME.actionGroup.add(this);
	}
}

class JumpingFish extends FlxSprite {
	public static var anims = AsepriteMacros.tagNames("assets/aseprite/jumpingFish.json");
	public static var layers = AsepriteMacros.layerNames("assets/aseprite/jumpingFish.json");

	private var currentTimer:FlxTimer;

	public function new(X:Float, Y:Float) {
		super(X, Y);
		Aseprite.loadAllAnimations(this, AssetPaths.jumpingFish__json);
		// var vOffset = height - 24;
		// width = 32;
		// height = 32;
		visible = false;
		currentTimer = FlxTimer.wait(r.float(1, 10), () -> {
			if (this != null && this.animation != null) {
				visible = true;
				animation.play(anims.animate);
				animation.onFinish.add((_) -> {
					visible = false;
					animation.pause();
					currentTimer = FlxTimer.wait(r.float(1, 10), () -> {
						if (this != null && this.animation != null) {
							visible = true;
							animation.play(anims.animate);
						}
					});
				});
			}
		});

		@:privateAccess
		PlayState.ME.actionGroup.add(this);
	}
}
