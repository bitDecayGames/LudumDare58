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

class Player extends FlxSprite implements GameRenderObject {
	public static var anims = AsepriteMacros.tagNames("assets/aseprite/player.json");
	public static var layers = AsepriteMacros.layerNames("assets/aseprite/player.json");
	// public static var eventData = AsepriteMacros.frameUserData("assets/aseprite/player.json", "Layer 1");

	public static var SLIPPING = "_slipping";
	public static var PUSHING = "_pushing";

	var speed:Float = 150;
	var playerNum = 0;

	var lastPosition = FlxPoint.get();

	public function new(X:Float, Y:Float) {
		super(X, Y);
		// This call can be used once https://github.com/HaxeFlixel/flixel/pull/2860 is merged
		// FlxAsepriteUtil.loadAseAtlasAndTags(this, AssetPaths.player__png, AssetPaths.player__json);
		Aseprite.loadAllAnimations(this, AssetPaths.player__json);
		// animation.onFrameChange.add((anim, frame, index) -> {
		// 	if (eventData.exists(index)) {
		// 		trace('frame $index has data ${eventData.get(index)}');
		// 	}
		// });
		width = 32;
		height = 32;
	}

	override public function update(delta:Float) {
		super.update(delta);

		// var inputDir = InputCalculator.getInputCardinal(playerNum);
		// if (inputDir != NONE) {
		// 	inputDir.asVector(velocity).scale(speed);
		// 	facing = inputDir.asFacing();
		// } else {
		// 	velocity.set();
		// }

		if (SimpleController.just_pressed(Button.A, playerNum)) {
			color = color ^ 0xFFFFFF;
		}

		updateCurrentAnimation();
		FlxG.watch.add(this, "facing", "Facing: ");

		lastPosition.set(x, y);
	}

	function updateCurrentAnimation() {
		// player only moves in cardinal directions with potential modifiers

		var pDiff = getPosition(FlxPoint.weak()).subtractPoint(lastPosition);

		FlxG.watch.addQuick("pDiff: ", pDiff);

		var intendedAnim = anims.StandDown;

		if (pDiff.length > 0) {
			intendedAnim = "Run";
		} else {
			intendedAnim = "Stand";
		}
		
		flipX = false;
		if (facing.has(LEFT)) {
			flipX = true;
			intendedAnim += "Side";
		} else if (facing.has(RIGHT)) {
			intendedAnim += "Side";
		} else if (facing.has(UP)) {
			intendedAnim += "Up";
		} else if (facing.has(DOWN)) {
			intendedAnim += "Down";
		}

		// TODO: check modifiers like pushing/slipping/etc
		if (true) { 
			// intendedAnim += SLIPPING;
		}

		playAnimIfNotAlready(intendedAnim, false);
	}

	function playAnimIfNotAlready(name:String, playInReverse:Bool, ?forceAnimationRefresh:Bool):Bool {
		if (animation.curAnim == null || animation.curAnim.name != name || forceAnimationRefresh) {
			animation.play(name, true, playInReverse);
			return true;
		}
		return false;
	}

	public function handleGameResult(r:GameBoardMoveResult, board:GameBoard):FlxTween {
		var dest = board.current.indexToXY(r.gameObj.index);
		facing = FlxDirectionFlags.fromInt(r.dir.asFacing());
		// The animation for walking takes 0.6 seconds to loop. So that's the basis for why this is 0.6
		// Ideally, we see what animation is to be played here, and we base this tween off of how long that animation takes.
		return FlxTween.linearMotion(this, x, y, dest[0] * 32, dest[1] * 32, 0.6);
	}
}
