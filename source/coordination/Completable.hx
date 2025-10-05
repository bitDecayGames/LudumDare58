package coordination;

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

    public function new(a:FlxAnimationController, name:String) {
        animation = a;
        animation.onFinish.addOnce((n) -> { 
            if (n == name) {
                done = true;
            }
        });
    }

    public function isDone():Bool {
        return done;
    }
}