package entities;

import flixel.FlxSprite;

class Star extends FlxSprite {
	public function new(X:Float, Y:Float, on:Bool = false) {
		super(X - width * .5, Y - height * .5);
		scale.set(2, 2);
		setOn(on);
	}

	public function setOn(value:Bool) {
		if (value) {
			loadGraphic(AssetPaths.starOn__png);
		} else {
			loadGraphic(AssetPaths.starOff__png);
		}
	}
}
