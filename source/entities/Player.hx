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

class Player extends FlxSprite implements GameRenderObject {
	public static var anims = AsepriteMacros.tagNames("assets/aseprite/player.json");
	public static var layers = AsepriteMacros.layerNames("assets/aseprite/player.json");

	public static var STAND = "Stand";
	public static var RUN = "Run";
	public static var SLIP = "Slip";
	public static var DROP = "Splash";
	public static var PUSH = "Push";

	var id:Int = 0;
	var speed:Float = 150;
	var playerNum = 0;

	var lastPosition = FlxPoint.get();

	var animPrefix = "";

	public function new(id:Int, X:Float, Y:Float) {
		super(X, Y);
		this.id = id;
		// This call can be used once https://github.com/HaxeFlixel/flixel/pull/2860 is merged
		// FlxAsepriteUtil.loadAseAtlasAndTags(this, AssetPaths.player__png, AssetPaths.player__json);
		Aseprite.loadAllAnimations(this, AssetPaths.player__json);
		// animation.onFrameChange.add((anim, frame, index) -> {
		// 	if (eventData.exists(index)) {
		// 		trace('frame $index has data ${eventData.get(index)}');
		// 	}
		// });

		animation.onFrameChange.add(onWalkFrame);
		animation.onFrameChange.add(onFallFrame);

		animation.onFinish.add((name) -> {
			if (name == anims.Splash) {
				animPrefix = STAND;
				animation.play(anims.StandDown);
				kill();
			}
		});
		var vOffset = height - 32;
		width = 32;
		height = 32;

		offset.y = vOffset;
	}

	function onWalkFrame(name:String, frameNumber:Int, frameIndex:Int) {
        trace('Animation: $name, Frame: $frameNumber, Index: $frameIndex');
        
        // Play footstep sound on specific frames
		if (name == anims.RunDown || name == anims.RunUp || name == anims.RunSide) {
			if (frameNumber == 2 || frameNumber == 5) {
				FmodPlugin.playSFX(FmodSFX.BearStepCrunchOnly);
        	}
		}
    }

	function onFallFrame(name:String, frameNumber:Int, frameIndex:Int) {
        trace('Animation: $name, Frame: $frameNumber, Index: $frameIndex');
        
        // Play footstep sound on specific frames
		if (name == anims.Splash) {
			if (frameNumber == 0) {
				FmodPlugin.playSFX(FmodSFX.BearFall);
        	}
			if (frameNumber == 3) {
				FmodPlugin.playSFX(FmodSFX.BearSplash);
        	}
		}
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

	var standBuffer = 2;
	var currentBuff = 0;

	function updateCurrentAnimation() {
		if (animation.name != null && animation.name == anims.Splash) {
			// XXX: Hacky, but we don't want to be able to cancel this one
			return;
		}

		// player only moves in cardinal directions with potential modifiers

		var pDiff = getPosition(FlxPoint.weak()).subtractPoint(lastPosition);

		FlxG.watch.addQuick("pDiff: ", pDiff);

		var intendedAnim = animPrefix;

		if (pDiff.length == 0) {
			// we allow animations to play for a couple frames to make transitions
			// feel better visually
			currentBuff++;
			if (currentBuff >= standBuffer) {
				intendedAnim = "Stand";
			}
		} else {
			currentBuff = 0;
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

		playAnimIfNotAlready(intendedAnim, false);
	}

	function playAnimIfNotAlready(name:String, playInReverse:Bool, ?forceAnimationRefresh:Bool):Bool {
		if (animation.curAnim == null || animation.curAnim.name != name || forceAnimationRefresh) {
			animation.play(name, true, playInReverse);
			// animation.timeScale = 2.0;
			return true;
		}
		return false;
	}

	public function handleGameResult(r:GameBoardMoveResult, board:GameBoard):Completable {
		var dest = r.endPos;
		facing = FlxDirectionFlags.fromInt(r.dir.asFacing());

		var tweenDuration = 0.6;
		var t = Type.getClass(r);
		switch (t) {
			case Move | Push | Slide:
				switch (t) {
					case Move:
						animPrefix = RUN;
						TODO.sfx('bear walks one tile');
					case Push:
						animPrefix = PUSH;
						TODO.sfx('bear pushes block. block and bear both move');
						// pushing blocks is hard work
						tweenDuration *= 2.0;
					case Slide:
						TODO.sfx('bear slip/slides across one tile');
						animPrefix = SLIP;
					default:
						// eh?
				}
				return new TweenCompletable(FlxTween.linearMotion(this, x, y, dest[0] * 32, dest[1] * 32, tweenDuration));

			case Drop:
				animPrefix = DROP;
				animation.play(anims.Splash);
				TODO.sfx('bear walks into water splash');
				return new AnimationCompletable(animation, anims.Splash);
			case WheelSpin:
				// TODO: this should be the "spin wheels" animation and probably needs to be a AnimationCompletable instead of tween
				animPrefix = PUSH;
				TODO.sfx('bear tries to push block but cannot');
				return new TweenCompletable(FlxTween.linearMotion(this, x, y, x, y, tweenDuration));
			case Shove:
				// TODO: this should be the "shove" animation and probably needs to be a AnimationCompletable instead of tween
				TODO.sfx('bear pushes block (block moves, bear does not)');
				animPrefix = PUSH;
				return new TweenCompletable(FlxTween.linearMotion(this, x, y, x, y, tweenDuration));
			case Win:
				// TODO: play transition stuff
			default:
				// do nothing
		}

		// The animation for walking takes 0.6 seconds to loop. So that's the basis for why this is 0.6
		// Ideally, we see what animation is to be played here, and we base this tween off of how long that animation takes.
		// return FlxTween.linearMotion(this, x, y, dest[0] * 32, dest[1] * 32, 0.6);
		return null;
	}

	public function getId():Int {
		return id;
	}
}
