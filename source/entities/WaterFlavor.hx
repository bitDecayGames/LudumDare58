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
		PlayState.ME.add(this);
	}

	public override function destroy() {
		PlayState.ME.remove(this);
		animation.destroy();
		super.destroy();
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
		PlayState.ME.add(this);
	}

	public override function destroy() {
		PlayState.ME.remove(this);
		animation.destroy();
		super.destroy();
	}
}

class JumpingFish extends FlxSprite {
	public static var anims = AsepriteMacros.tagNames("assets/aseprite/jumpingFish.json");
	public static var layers = AsepriteMacros.layerNames("assets/aseprite/jumpingFish.json");

	public function new(X:Float, Y:Float) {
		super(X, Y);
		Aseprite.loadAllAnimations(this, AssetPaths.jumpingFish__json);
		// var vOffset = height - 24;
		// width = 32;
		// height = 32;
		animation.play(anims.all_frames);
		PlayState.ME.add(this);
	}

	public override function destroy() {
		PlayState.ME.remove(this);
		animation.destroy();
		super.destroy();
	}
}
