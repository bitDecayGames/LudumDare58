package entities;

import flixel.util.FlxTimer;
import flixel.FlxG;
import coordination.Completable;
import gameboard.GameBoard;
import gameboard.GameBoard.GameBoardMoveResult;
import flixel.tweens.FlxTween;
import flixel.FlxSprite;
import bitdecay.flixel.graphics.Aseprite;
import bitdecay.flixel.graphics.AsepriteMacros;

class Seal extends FlxSprite implements GameRenderObject {
	public static var anims = AsepriteMacros.tagNames("assets/aseprite/seal.json");
	private static var fromLay = [
		anims.LayBlink,
		anims.Stand,
		anims.Yawn,
	];
	private static var fromStand = [
		anims.StandBlink,
		anims.StandTurn,
		anims.LayTransition,
	];

	var id:Int = 0;
	private var animTimer: FlxTimer;

	public function new(id:Int, X:Float, Y:Float) {
		super(X, Y);
		this.id = id;
		Aseprite.loadAllAnimations(this, AssetPaths.seal__json);
		width = 32;
		height = 32;
		offset.y = 12;

		animation.play(anims.Lay);

		var loopTime = FlxG.random.float(3, 6);
		animTimer = FlxTimer.loop(loopTime, (_)-> {
			var curAnimName = animation.curAnim.name;
			var nextAnimName:String = anims.Lay;

			if (curAnimName == anims.Lay) {
				nextAnimName = FlxG.random.getObject(fromLay);
			} else if (curAnimName == anims.LayBlink ||
				curAnimName == anims.Yawn ||
				curAnimName == anims.LayTransition) {
				nextAnimName = anims.Lay;
			} else if (curAnimName == anims.Stand) {
				nextAnimName = FlxG.random.getObject(fromStand);
			} else if (curAnimName == anims.LayBlink ||
				curAnimName == anims.StandBlink ||
				curAnimName == anims.StandTurn) {
				nextAnimName = anims.Stand;
			}

			animation.play(nextAnimName);
		}, 0);
	}

	public function handleGameResult(r:GameBoardMoveResult, board:GameBoard):Completable {
		// var dest = r.endPos;
		// var t = Type.getClass(r);
		// if (t == Move || t == Slide) {
		// 	return new TweenCompletable(FlxTween.linearMotion(this, x, y, dest[0] * 32, dest[1] * 32, 0.6));
		// }
		return null;
	}

	public function getId():Int {
		return id;
	}
}
