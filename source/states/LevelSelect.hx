package states;

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

using states.FlxStateExt;

class LevelSelect extends FlxTransitionableState {

    var levelNum = 1;
    var levelButtons = new Array<FlxSprite>();

	override public function create():Void {
		super.create();
		bgColor = FlxColor.TRANSPARENT;
		FlxG.camera.pixelPerfectRender = true;

		FmodPlugin.playSong(FmodSong.LetsGo);

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
            if (exits.length == 0) {
                return;
            }

            level = ldtk.getLevel(exits[0].f_Next.levelIid);
        }
    }

    function makeButtonForLevel(level:Level) {
        var btn = new FlxButton('Lvl ${levelNum++}', () -> {
			FlxG.switchState(() -> new PlayState(level.identifier));
		});
        levelButtons.push(btn);
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
            nextX += b.width + spacing;
        }
    }

	override public function update(elapsed:Float):Void {
		super.update(elapsed);
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
