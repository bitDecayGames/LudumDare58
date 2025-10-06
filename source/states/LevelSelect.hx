package states;

import entities.Star;
import flixel.group.FlxSpriteGroup;
import flixel.group.FlxGroup;
import collectables.Collectables.CollectStats;
import flixel.math.FlxPoint;
import flixel.math.FlxMath;
import flixel.tweens.FlxTween;
import flixel.addons.display.FlxBackdrop;
import bitdecay.flixel.spacial.Align;
import flixel.text.FlxBitmapText;
import openfl.Assets;
import openfl.geom.Rectangle;
import flixel.addons.ui.FlxUI9SliceSprite;
import flixel.ui.FlxSpriteButton;
import bitdecay.flixel.graphics.AsepriteMacros;
import bitdecay.flixel.graphics.Aseprite;
import ldtk.Level;
import levels.ldtk.Ldtk.LdtkProject;
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
import flixel.addons.ui.FlxUISpriteButton;
import collectables.Collectables.SaveData;

using states.FlxStateExt;

class LevelSelect extends FlxTransitionableState {
	public static var slices = AsepriteMacros.sliceNames("assets/aseprite/levelSelect_9.json");

	var levelNum = 1;
	var levelButtons = new Array<FlxUISpriteButton>();
	var buttonCentroid = new Map<FlxSprite, FlxPoint>();
	var buttonOffsets = new Map<FlxSprite, Float>();

	override public function create():Void {
		super.create();
		bgColor = FlxColor.TRANSPARENT;
		FlxG.camera.pixelPerfectRender = true;

		// FmodPlugin.playSong(FmodSong.LetsGo);

		var waterBG = new FlxBackdrop(AssetPaths.waterTile__png);
		Aseprite.loadAllAnimations(waterBG, AssetPaths.waterTile__json);
		var anims = AsepriteMacros.tagNames("assets/aseprite/waterTile.json");
		waterBG.scale.set(2, 2);
		waterBG.animation.play(anims.animate);
		waterBG.animation.timeScale = 0.5;
		waterBG.alpha = 0.7;
		add(waterBG);

		buildButtons();

		layout();
	}

	function buildButtons() {
		var saveData = SaveData.load();
		var ldtk = new LdtkProject();

		var anchor = ldtk.toc.FirstLevel[0];

		var level = ldtk.all_worlds.Default.getLevelAt(anchor.worldX, anchor.worldY);
		var stats = new CollectStats(level.iid, level.l_Objects.all_Collectable.length);
		stats.visited = true;
		saveData.add(stats);

		var levelsVisited = new Array<String>();
		while (level != null) {
			if (levelsVisited.contains(level.iid)) {
				QLog.critical('level cycle detected at ${level.iid}');
			}

			levelsVisited.push(level.iid);

			makeButtonForLevel(level, saveData.get(level.iid));
			saveData.add(new CollectStats(level.iid, level.l_Objects.all_Collectable.length));

			var exits = level.l_Objects.all_Exit;
			if (exits.length == 0 || exits[0].f_Next == null) {
				return;
			}

			level = ldtk.getLevel(exits[0].f_Next.levelIid);
		}

		saveData.save();
	}

	function makeButtonForLevel(level:Level, stats:Null<CollectStats>) {
		var key = Aseprite.getSliceKey(AssetPaths.levelSelect_9__json, slices.Slice_1_0);

		var labelGroup = new FlxSpriteGroup();

		var label = new FlxBitmapText('${levelNum++}');
		labelGroup.add(label);
		label.scale.set(5, 5);
		label.alignment = CENTER;

		var t = new FlxUISpriteButton(0, 0, labelGroup, () -> {
			if (stats == null || !stats.visited) {
				return;
			}
			FlxG.switchState(() -> new PlayState(level.iid));
		});
		Aseprite.loadAllAnimations(t, AssetPaths.levelSelect_9__json);
		var sliceRect = [
			Std.int(key.center.x),
			Std.int(key.center.y),
			Std.int(key.center.w),
			Std.int(key.center.h)
		];
		// t.loadGraphicSlice9([AssetPaths.levelSelect_9__png, AssetPaths.levelSelect_9__png, AssetPaths.levelSelect_9__png], cast key.bounds.x, cast key.bounds.y, [cast key.center.x, cast key.center.y, cast key.center.w, cast key.center.h], [0, 0, 0]);
		t.loadGraphicSlice9([
			AssetPaths.levelSelect_9__png,
			AssetPaths.levelSelect_9__png,
			AssetPaths.levelSelect_9__png
		],
			cast key.bounds.w + 80, cast key.bounds.h + 60, [sliceRect, sliceRect, sliceRect], FlxUI9SliceSprite.TILE_BOTH, -1, false, cast key.bounds.w,
			cast key.bounds.h);
		// var btn = new FlxUI9SliceSprite(0, 0, AssetPaths.levelSelect_9__png, new Rectangle(key.bounds.x, key.bounds.y, key.bounds.w, key.bounds.h));
		// Aseprite.loadSlice(btn, AssetPaths.items__json, slices.Slice_1_0);
		// t.label.scale.set(4, 4);
		// t.autoCenterLabel();
		// label.alignment = RIGHT;
		// Align.center(t.label, t);

		add(t);
		levelButtons.push(t);

		buttonOffsets.set(t, FlxG.random.float(0, Math.PI * 2));

		if (stats == null || !stats.visited) {
			label.color = FlxColor.GRAY;
			t.color = FlxColor.GRAY;
			t.over_color = FlxColor.GRAY;
			t.down_color = FlxColor.GRAY;
			t.up_color = FlxColor.GRAY;
		} else {
			QLog.notice('Stats:${stats}');
			var starXOffset = 0;
			var starX = 30;
			var starY = 40;
			labelGroup.add(new Star(starXOffset + starX * 0, starY, stats != null && stats.completed));
			labelGroup.add(new Star(starXOffset + starX * 1, starY - 3, stats != null && stats.completed && stats.highestNumCollected >= 1));
			labelGroup.add(new Star(starXOffset + starX * 2, starY, stats != null
				&& stats.completed
				&& stats.highestNumCollected >= stats.maxNumCollectables));
			label.setPosition(starXOffset + starX * 1, 0);
		}
	}

	function layout() {
		var border = 20.0;
		var spacing = 20.0;
		var nextX = border;
		var nextY = border;
		for (b in levelButtons) {
			add(b);
			if (nextX + b.width > FlxG.width - border) {
				nextX = border;
				nextY += b.height + spacing;
			}
			b.setPosition(nextX, nextY);

			buttonCentroid.set(b, FlxPoint.get(nextX, nextY));

			nextX += b.width + spacing;
		}
	}

	var sineTimer = 0.0;
	var waveSpeed = 1;
	var waveDepth = 5;

	override public function update(elapsed:Float):Void {
		super.update(elapsed);

		sineTimer += elapsed * waveSpeed;

		for (b in levelButtons) {
			var mod = FlxMath.fastSin(sineTimer + buttonOffsets.get(b)) * waveDepth;
			var c = buttonCentroid.get(b);
			b.setPosition(c.x, c.y + mod);
			Align.center(b.label, b);

			// b.autoCenterLabel();
			// Align.center(b.label, b);
		}
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
