package states;

import haxe.ds.Vector;
import flixel.util.FlxDirectionFlags;
import flixel.ui.FlxButton;
import bitdecay.flixel.spacial.Cardinal;
import input.SimpleController;
import gameboard.GameBoardState;
import gameboard.GameBoard;
import todo.TODO;
import flixel.group.FlxGroup;
import flixel.math.FlxRect;
import flixel.group.FlxGroup.FlxTypedGroup;
import entities.CameraTransition;
import levels.ldtk.Level;
import levels.ldtk.Ldtk.LdtkProject;
import achievements.Achievements;
import entities.Player;
import events.gen.Event;
import events.EventBus;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.transition.FlxTransitionableState;
import flixel.text.FlxBitmapText;
import ui.hud.SealsCollectedText;

using states.FlxStateExt;

class PlayState extends FlxTransitionableState {
	var player:Player;
	var midGroundGroup = new FlxGroup();
	var uiGroup = new FlxGroup();
	var activeCameraTransition:CameraTransition = null;

	var transitions = new FlxTypedGroup<CameraTransition>();

	var ldtk = new LdtkProject();
	var gameBoard:GameBoard;

	override public function create() {
		super.create();

		FlxG.camera.pixelPerfectRender = true;

		Achievements.onAchieve.add(handleAchieve);
		EventBus.subscribe(ClickCount, (c) -> {
			QLog.notice('I got me an event about ${c.count} clicks having happened.');
		});

		// QLog.error('Example error');

		// Build out our render order
		add(midGroundGroup);
		add(uiGroup);
		add(transitions);

		var sealsCollectedTxt = new SealsCollectedText();
		uiGroup.add(sealsCollectedTxt);
		var undoBtn = new FlxButton(50, 100, "Undo", () -> {
			gameBoard.undo();
		});
		uiGroup.add(undoBtn);

		loadLevel("Level_0");
	}

	function loadLevel(levelName:String) {
		unload();

		var level = new Level(levelName);
		FmodPlugin.playSong(level.raw.f_Music);


		var gbState = level.initialBoardState;

		var spawnObj = gbState.findObjType(SPAWN);
		var playerObj = new GameBoardObject();
		playerObj.type = PLAYER;
		playerObj.index = spawnObj.index;
		gbState.addObj(playerObj);
		gbState.removeObj(spawnObj);

		gameBoard = new GameBoard(gbState);

		// TODO Remove when hooked into GameBoard
		EventBus.fire(new SealCollected(1, 3));

		// TODO: build our new tile map with proper rendering so the tiles look nice.
		// The ones in the level.terrainLayer are editor tiles for now
		midGroundGroup.add(level.terrainLayer);
		FlxG.worldBounds.copyFrom(level.terrainLayer.getBounds());

		player = new Player(level.spawnPoint.x, level.spawnPoint.y);
		//camera.follow(player);
		add(player);

		for (t in level.camTransitions) {
			transitions.add(t);
		}

		for (_ => zone in level.camZones) {
			if (zone.containsPoint(level.spawnPoint)) {
				setCameraBounds(zone);
			}
		}

		EventBus.fire(new PlayerSpawn(player.x, player.y));
	}

	function unload() {
		for (t in transitions) {
			t.destroy();
		}
		transitions.clear();

		for (o in midGroundGroup) {
			o.destroy();
		}
		midGroundGroup.clear();
	}

	function handleAchieve(def:AchievementDef) {
		add(def.toToast(true));
	}

	function movePlayer(facing: FlxDirectionFlags, pos: Vector<Int>) {
		QLog.notice('  -pos: ${pos}');
		player.x = pos[0] * 32;
		player.y = pos[1] * 32;
		player.facing = facing;
	}

	override public function update(elapsed:Float) {
		super.update(elapsed);

		// if (FlxG.mouse.justPressed) {
		// 	EventBus.fire(new Click(FlxG.mouse.x, FlxG.mouse.y));
		// }

		var moveDir = Cardinal.NONE;
		if (SimpleController.just_released(UP)) {
			moveDir = Cardinal.N;
		} else if (SimpleController.just_released(RIGHT)) {
			moveDir = Cardinal.E;
		} else if (SimpleController.just_released(DOWN)) {
			moveDir = Cardinal.S;
		} else if (SimpleController.just_released(LEFT)) {
			moveDir = Cardinal.W;
		}

		if (moveDir != Cardinal.NONE) {
			var results = gameBoard.move(moveDir);
			for (phase in results) {
				for (res in phase) {
					if (Std.isOfType(res, Move)) {
						var move = cast(res, Move);
						if (move.gameObj.type == PLAYER) {
							var facing = FlxDirectionFlags.fromInt(moveDir.asFacing());
							movePlayer(facing, move.endPos);
						}
					}
				}
			}
		}

		FlxG.collide(midGroundGroup, player);
		handleCameraBounds();

		TODO.sfx('scarySound');
	}

	function handleCameraBounds() {
		if (activeCameraTransition == null) {
			FlxG.overlap(player, transitions, (p, t) -> {
				activeCameraTransition = cast t;
			});
		} else if (!FlxG.overlap(player, activeCameraTransition)) {
			var bounds = activeCameraTransition.getRotatedBounds();
			for (dir => camZone in activeCameraTransition.camGuides) {
				switch (dir) {
					case N:
						if (player.y < bounds.top) {
							setCameraBounds(camZone);
						}
					case S:
						if (player.y > bounds.bottom) {
							setCameraBounds(camZone);
						}
					case E:
						if (player.x > bounds.right) {
							setCameraBounds(camZone);
						}
					case W:
						if (player.x < bounds.left) {
							setCameraBounds(camZone);
						}
					default:
						QLog.error('camera transition area has unsupported cardinal direction ${dir}');
				}
			}
		}
	}

	public function setCameraBounds(bounds:FlxRect) {
		camera.setScrollBoundsRect(bounds.x, bounds.y, bounds.width, bounds.height);
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
