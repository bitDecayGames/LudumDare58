package ui.hud;

import events.gen.Event;
import events.EventBus;
import flixel.FlxG;
import flixel.text.FlxBitmapText;

class SealsCollectedText extends FlxBitmapText {

    public function new(offset: Float = 50) {
        super(x, y);

		scrollFactor.set(0, 0);

		EventBus.subscribe(SealCollected, (e) -> {
			text = '(${e.num_collected}/${e.total}) Seals';
			x = FlxG.width - width - offset;
			y = offset;
		});
    }
}