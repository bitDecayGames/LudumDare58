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

class PlayerWin extends FlxSprite {
	public static var anims = AsepriteMacros.tagNames("assets/aseprite/player.json");
	public static var layers = AsepriteMacros.layerNames("assets/aseprite/player.json");

	var isBloody = true; // must be true so the first time we call setBloody(false) it actually works

	public function new(X:Float, Y:Float, jumpTo:FlxPoint, isBloody:Bool, goLeft:Bool) {
		super(X, Y);
		this.isBloody = !isBloody;
		setBloody(isBloody);
		@:privateAccess
		PlayState.ME.actionGroup.add(this);

		var off = height - 32;
		width = 32;
		height = 32;
		offset.y = off;

		var walkDist = 20;
		var jumpDist = 100;
		if (goLeft) {
			flipX = true;
			walkDist *= -1;
			jumpDist *= -1;
		}
		animation.play(anims.TransitionPrep);
		animation.onFinish.addOnce((_) -> {
			TODO.sfx('talk to edge with live saver on');
			animation.play(anims.TransitionWalk);
			FlxTween.linearMotion(this, x, y, x + walkDist, y, 1, true, {
				onComplete: (_) -> {
					TODO.sfx('jumps off ice');
					animation.play(anims.TransitionJump);
					FlxTween.quadMotion(this, x, y, x + jumpDist * .5, y - Math.abs(jumpDist) * .7, jumpTo.x, jumpTo.y, 1, true, {
						onComplete: (_) -> {
							TODO.sfx('splash into water with life saver on');
							animation.play(anims.TransitionFloat);
							FlxTween.linearMotion(this, jumpTo.x, jumpTo.y, jumpTo.x + jumpDist * .5, jumpTo.y, 1, true, {
								onComplete: (_) -> {
									// TODO: MW transition to next level
									PlayState.ME.transist();
								}
							});
						}
					});
				}
			});
		});
	}

	function setBloody(isBloody:Bool) {
		if (this.isBloody == isBloody) {
			// do nothing since it is already set
			return;
		}
		if (isBloody) {
			Aseprite.loadAllAnimations(this, AssetPaths.playerBloody__json);
		} else {
			Aseprite.loadAllAnimations(this, AssetPaths.player__json);
		}
		this.isBloody = isBloody;
	}

	public override function destroy() {
		PlayState.ME.remove(this);
		animation.destroy();
		super.destroy();
	}
}
