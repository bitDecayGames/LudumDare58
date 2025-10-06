package entities;

import todo.TODO;
import collectables.Collectables;
import flixel.util.FlxTimer;
import flixel.FlxG;
import coordination.Completable;
import gameboard.GameBoard;
import gameboard.GameBoardMoveResult;
import flixel.tweens.FlxTween;
import flixel.FlxSprite;
import bitdecay.flixel.graphics.Aseprite;
import bitdecay.flixel.graphics.AsepriteMacros;

class Seal extends FlxSprite implements GameRenderObject {
	public static var anims = AsepriteMacros.tagNames("assets/aseprite/seal.json");
	private static var fromLay = [anims.LayBlink, anims.StandTransition];
	private static var fromLayBlink = [anims.Yawn, anims.Lay];
	private static var fromStand = [anims.StandBlink, anims.StandTurn, anims.LayTransition];
	private static var fromStandSide = [anims.StandTurnBack, anims.BlinkL];

	var id:Int = 0;
	private var animTimer:FlxTimer;

	public function new(id:Int, X:Float, Y:Float) {
		super(X, Y);
		this.id = id;
		Aseprite.loadAllAnimations(this, AssetPaths.seal__json);
		width = 32;
		height = 32;
		offset.y = 12;

		setupAnimations();
	}

	function setupAnimations() {
		if (animTimer != null) {
			animTimer.cancel();
		}

		animation.play(anims.Lay);

		animation.onFinish.add((name) -> {
			if (this != null && this.animation != null) {
				if (name == anims.StandBlink) {
					animation.play(anims.Stand);
				} else if (name == anims.Yawn) {
					animation.play(anims.LayBlink);
				} else if (name == anims.BlinkL) {
					animation.play(anims.StandL);
				} else if (name == anims.LayTransition) {
					animation.play(anims.Lay);
				} else if (name == anims.StandTransition) {
					animation.play(anims.Stand);
				} else if (name == anims.StandTurn) {
					animation.play(anims.StandL);
				} else if (name == anims.StandTurnBack) {
					animation.play(anims.Stand);
				}
			}
		});

		var loopTime = FlxG.random.float(1.5, 3);
		animTimer = FlxTimer.loop(loopTime, (_) -> {
			if (this != null && this.animation != null) {
				if (animation.curAnim.name == anims.Dead) {
					animation.play(anims.Dead, true);
					return;
				}
				
				var curAnimName = animation.curAnim.name;
				var nextAnimName:String = curAnimName;

				if (curAnimName == anims.Lay) {
					nextAnimName = FlxG.random.getObject(fromLay);
				} else if (curAnimName == anims.LayBlink) {
					nextAnimName = FlxG.random.getObject(fromLayBlink);
				} else if (curAnimName == anims.Stand) {
					nextAnimName = FlxG.random.getObject(fromStand);
				} else if (curAnimName == anims.StandL) {
					nextAnimName = FlxG.random.getObject(fromStandSide);
				}

				animation.play(nextAnimName);
			}
		}, 0);
	}

	public function handleGameResult(r:GameBoardMoveResult, board:GameBoard):Completable {
		var t = Type.getClass(r);
		if (t == Collect && animation.curAnim.name != anims.Dead) {
			animation.play(anims.Dead);
			FmodPlugin.playSFX(FmodSFX.SealCrunch2);
			Collectables.incrCollect();
		} else if (t == Bump) {
			return new BumpCompletable(this, r.dir);
		} else if (t == Die) {
			kill();
			return null;
		}
		return null;
	}

	public function getId():Int {
		return id;
	}

	override function revive() {
		super.revive();

		setupAnimations();
	}

	override function destroy() {
		super.destroy();

		animTimer.cancel();
	}
}
