package entities;

import flixel.util.FlxDirectionFlags;
import flixel.FlxSprite;
import input.InputCalculator;
import input.SimpleController;
import bitdecay.flixel.graphics.Aseprite;
import bitdecay.flixel.graphics.AsepriteMacros;

class Player extends FlxSprite {
	public static var anims = AsepriteMacros.tagNames("assets/aseprite/characters/player.json");
	public static var layers = AsepriteMacros.layerNames("assets/aseprite/characters/player.json");
	public static var eventData = AsepriteMacros.frameUserData("assets/aseprite/characters/player.json", "Layer 1");

	public static var SLIPPING = "_slipping";
	public static var PUSHING = "_pushing";

	var speed:Float = 150;
	var playerNum = 0;

	public function new(X:Float, Y:Float) {
		super(X, Y);
		// This call can be used once https://github.com/HaxeFlixel/flixel/pull/2860 is merged
		// FlxAsepriteUtil.loadAseAtlasAndTags(this, AssetPaths.player__png, AssetPaths.player__json);
		Aseprite.loadAllAnimations(this, AssetPaths.player__json);
		animation.play(anims.right);
		animation.onFrameChange.add((anim, frame, index) -> {
			if (eventData.exists(index)) {
				trace('frame $index has data ${eventData.get(index)}');
			}
		});
	}

	override public function update(delta:Float) {
		super.update(delta);

		var inputDir = InputCalculator.getInputCardinal(playerNum);
		if (inputDir != NONE) {
			inputDir.asVector(velocity).scale(speed);
		} else {
			velocity.set();
		}

		if (SimpleController.just_pressed(Button.A, playerNum)) {
			color = color ^ 0xFFFFFF;
		}
	}

	function updateCurrentAnimation() {
		// player only moves in cardinal directions with potential modifiers

		var intendedAnim = anims.idle;

		if (facing.has(LEFT)) {
			intendedAnim = anims.left;
		} else if (facing.has(RIGHT)) {
			intendedAnim = anims.right;
		} else if (facing.has(UP)) {
			// intendedAnim = anims.up;
		} else if (facing.has(DOWN)) {
			// intendedAnim = anims.down;
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
}
