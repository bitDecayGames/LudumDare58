package states;

import collectables.Collectables;
import flixel.addons.ui.FlxUI9SliceSprite;
import bitdecay.flixel.spacial.Align;
import bitdecay.flixel.graphics.AsepriteMacros;
import bitdecay.flixel.graphics.Aseprite;
import flixel.addons.ui.FlxUISpriteButton;
import flixel.text.FlxBitmapText;
import ui.MenuBuilder;
import com.bitdecay.analytics.Bitlytics;
import bitdecay.flixel.transitions.SwirlTransition;
import bitdecay.flixel.transitions.TransitionDirection;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.transition.FlxTransitionableState;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.util.FlxSpriteUtil;
import haxefmod.flixel.FmodFlxUtilities;
import input.SimpleController;
import states.AchievementsState;

using states.FlxStateExt;

class MainMenuState extends FlxTransitionableState {
	public static var slices = AsepriteMacros.sliceNames("assets/aseprite/levelSelect_9.json");

	var startButton:FlxButton;
	var handleInput = true;

	override public function create():Void {
		super.create();
		bgColor = FlxColor.TRANSPARENT;
		FlxG.camera.pixelPerfectRender = true;

		var bgImage = new FlxSprite(AssetPaths.title__png);
		bgImage.scale.set(camera.width / bgImage.width, camera.height / bgImage.height);
		bgImage.screenCenter();
		add(bgImage);

		// // This can be swapped out for an image instead
		// startButton = MenuBuilder.createTextButton("Play", clickPlay, MenuSelect, MenuHover);
		// startButton.screenCenter(X);
		// startButton.y = FlxG.height * .6;
		// add(startButton);

		var label = new FlxBitmapText('Play');
		label.scale.set(3, 3);
		label.autoSize = false;
		label.fieldWidth = 8;

		var key = Aseprite.getSliceKey(AssetPaths.levelSelect_9__json, slices.Slice_1_0);

		var t = new FlxUISpriteButton(0, 0, label, clickPlay);
		Aseprite.loadAllAnimations(t, AssetPaths.levelSelect_9__json);
		var sliceRect = [
			Std.int(key.center.x),
			Std.int(key.center.y),
			Std.int(key.center.w),
			Std.int(key.center.h)
		];
		t.loadGraphicSlice9([
			AssetPaths.levelSelect_9__png,
			AssetPaths.levelSelect_9__png,
			AssetPaths.levelSelect_9__png
		], 100,
			cast key.bounds.h, [sliceRect, sliceRect, sliceRect], FlxUI9SliceSprite.TILE_BOTH, -1, false, cast key.bounds.w, cast key.bounds.h);
		// t.label.scale.set(4, 4);
		t.screenCenter(X);
		t.y = FlxG.height * .7;
		t.autoCenterLabel();
		label.alignment = CENTER;
		Align.center(t.label, t);
		add(t);

		var credLabel = new FlxBitmapText('Credits');
		credLabel.scale.set(3, 3);
		credLabel.autoSize = false;
		credLabel.fieldWidth = 8;

		var c = new FlxUISpriteButton(0, 0, credLabel, clickCredits);
		Aseprite.loadAllAnimations(c, AssetPaths.levelSelect_9__json);
		var sliceRect = [
			Std.int(key.center.x),
			Std.int(key.center.y),
			Std.int(key.center.w),
			Std.int(key.center.h)
		];
		c.loadGraphicSlice9([
			AssetPaths.levelSelect_9__png,
			AssetPaths.levelSelect_9__png,
			AssetPaths.levelSelect_9__png
		], 100,
			cast key.bounds.h, [sliceRect, sliceRect, sliceRect], FlxUI9SliceSprite.TILE_BOTH, -1, false, cast key.bounds.w, cast key.bounds.h);
		c.screenCenter(X);
		c.y = t.y + t.height + 10;
		c.autoCenterLabel();
		credLabel.alignment = CENTER;
		Align.center(c.label, c);
		add(c);

		// FmodPlugin.playSong(FmodSong.LetsGo);

		// we will handle transitions manually
		transOut = null;
	}

	override public function update(elapsed:Float):Void {
		super.update(elapsed);

		if (FlxG.keys.pressed.D && FlxG.keys.justPressed.M) {
			// Keys D.M. for Disable Metrics
			Bitlytics.Instance().EndSession(false);
			FmodPlugin.playSFX(FmodSFX.MenuSelect);
			trace("---------- Bitlytics Stopped ----------");
		}

		if (handleInput && SimpleController.just_pressed(START)) {
			handleInput = false;
			FlxSpriteUtil.flicker(startButton, 0, 0.25);
			new FlxTimer().start(1, (t) -> {
				clickPlay();
			});
		}

		Collectables.checkForProdDebugKey(elapsed);
	}

	function clickPlay():Void {
		FmodFlxUtilities.TransitionToState(new LevelSelect());
	}

	// If we want to add a way to go to credits from main menu, call this
	function clickCredits():Void {
		FmodFlxUtilities.TransitionToState(new CreditsState());
	}

	// If we want to add a way to go to achievements from main menu, call this
	function clickAchievements():Void {
		FmodFlxUtilities.TransitionToState(new AchievementsState());
	}

	override public function onFocusLost() {
		super.onFocusLost();
		this.handleFocusLost();
	}

	override public function onFocus() {
		super.onFocus();
		this.handleFocus();
	}
}
