package states;

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
    	var ldtk = new LdtkProject();

        var anchor = ldtk.toc.FirstLevel[0];

        var level = ldtk.all_worlds.Default.getLevelAt(anchor.worldX, anchor.worldY);

        var levelsVisited = new Array<String>();
        while (level != null) {
            if (levelsVisited.contains(level.iid)) {
                QLog.critical('level cycle detected at ${level.iid}');
            }

            levelsVisited.push(level.iid);

            makeButtonForLevel(level);

            var exits = level.l_Objects.all_Exit;
            if (exits.length == 0 || exits[0].f_Next == null) {
                return;
            }

            level = ldtk.getLevel(exits[0].f_Next.levelIid);
        }
    }

    function makeButtonForLevel(level:Level) {
        var key = Aseprite.getSliceKey(AssetPaths.levelSelect_9__json, slices.Slice_1_0);

        var label = new FlxBitmapText('${levelNum++}');
        label.scale.set(3, 3);
        label.autoSize = false;
        label.fieldWidth = 8;

        var t = new FlxUISpriteButton(0, 0, label, () -> {
            FlxG.switchState(() -> new PlayState(level.identifier));
        });
        Aseprite.loadAllAnimations(t, AssetPaths.levelSelect_9__json);
        var sliceRect = [Std.int(key.center.x), Std.int(key.center.y), Std.int(key.center.w), Std.int(key.center.h)];
        // t.loadGraphicSlice9([AssetPaths.levelSelect_9__png, AssetPaths.levelSelect_9__png, AssetPaths.levelSelect_9__png], cast key.bounds.x, cast key.bounds.y, [cast key.center.x, cast key.center.y, cast key.center.w, cast key.center.h], [0, 0, 0]);
        t.loadGraphicSlice9([AssetPaths.levelSelect_9__png,AssetPaths.levelSelect_9__png,AssetPaths.levelSelect_9__png], cast key.bounds.w + 20, cast key.bounds.h, [sliceRect,sliceRect,sliceRect], FlxUI9SliceSprite.TILE_BOTH, -1, false, cast key.bounds.w, cast key.bounds.h);
        // var btn = new FlxUI9SliceSprite(0, 0, AssetPaths.levelSelect_9__png, new Rectangle(key.bounds.x, key.bounds.y, key.bounds.w, key.bounds.h));
		// Aseprite.loadSlice(btn, AssetPaths.items__json, slices.Slice_1_0);
        // t.label.scale.set(4, 4);
        t.autoCenterLabel();
        label.alignment = RIGHT;
        Align.center(t.label, t);

        add(t);
        levelButtons.push(t);

        buttonOffsets.set(t, FlxG.random.float(0, Math.PI * 2));
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
