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

class ExitObj extends FlxSprite implements GameRenderObject {
	public static var anims = AsepriteMacros.tagNames("assets/aseprite/lifesaver.json");
	public static var layers = AsepriteMacros.layerNames("assets/aseprite/lifesaver.json");

	var id:Int = 0;
	var goLeft:Bool;
	var jumpTo:FlxPoint;
	var player:Player;

	public function new(id:Int, X:Float, Y:Float, jumpTo:FlxPoint, player:Player) {
		super(X, Y);
		this.id = id;
		this.jumpTo = jumpTo;
		this.player = player;
		if (X < jumpTo.x) {
			goLeft = false;
		} else {
			goLeft = true;
		}
		Aseprite.loadAllAnimations(this, AssetPaths.lifesaver__json);
	}

	public function handleGameResult(r:GameBoardMoveResult, board:GameBoard):Completable {
		var t = Type.getClass(r);
		switch (t) {
			case Win:
				new PlayerWin(x, y, jumpTo, player.isBloody, goLeft);
				return new NeverCompletable();
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
