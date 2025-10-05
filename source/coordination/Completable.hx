package coordination;

import flixel.util.FlxAxes;
import bitdecay.flixel.spacial.Cardinal;
import flixel.FlxSprite;
import flixel.animation.FlxAnimationController;
import flixel.animation.FlxAnimation;
import flixel.tweens.FlxTween;

interface Completable {
	public function isDone():Bool;
}

class TweenCompletable implements Completable {
	var t:FlxTween;

	public function new(t:FlxTween) {
		this.t = t;
	}

	public function isDone():Bool {
		return t.finished;
	}
}

class AnimationCompletable implements Completable {
	var animation:FlxAnimationController;
	var done:Bool = false;

	public function new(a:FlxAnimationController, name:String, ?callback:Void->Void) {
		animation = a;
		animation.onFinish.addOnce((n) -> {
			if (n == name) {
				done = true;
			}
			if (callback != null) {
				callback();
			}
		});
	}

	public function isDone():Bool {
		return done;
	}
}

class BumpCompletable implements Completable {
	var t:FlxTween;

	public function new(obj:FlxSprite, dir:Cardinal) {
		var axes:FlxAxes;
		switch (dir) {
			case N | S:
				axes = FlxAxes.Y;
			default:
				axes = FlxAxes.X;
		}
		this.t = FlxTween.shake(obj, 0.05, 0.2, axes);
	}

	public function isDone():Bool {
		return t.finished;
	}
}

class NeverCompletable implements Completable {
	public function new() {}

	public function isDone():Bool {
		return false;
	}
}
