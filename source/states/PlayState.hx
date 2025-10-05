package states;

import coordination.Completable;
import entities.GameRenderObject;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import bitdecay.flixel.graphics.AsepriteMacros;
import bitdecay.flixel.graphics.Aseprite;
import flixel.addons.display.FlxBackdrop;
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

using states.FlxStateExt;

enum abstract InteractState(String) {
	var RESOLVING = "resolving";
	var AWAITING_INPUT = "awaitingInput";
}

class PlayState extends FlxTransitionableState {
	var player:Player;
	var bgGroup = new FlxGroup();
	var midGroundGroup = new FlxGroup();
	var uiGroup = new FlxGroup();
	var activeCameraTransition:CameraTransition = null;

	var transitions = new FlxTypedGroup<CameraTransition>();

	var ldtk = new LdtkProject();
	var level:Level;
	var gameBoard:GameBoard;

	var objectMap = new Map<Int, GameRenderObject>();

	var interactState:InteractState = RESOLVING;
	var pendingResolutions = new Array<Completable>();
	var pendingPhases = new Array<Array<GameBoardMoveResult>>();

	override public function create() {
		super.create();

		FlxG.camera.pixelPerfectRender = true;

		Achievements.onAchieve.add(handleAchieve);
		EventBus.subscribe(ClickCount, (c) -> {
			QLog.notice('I got me an event about ${c.count} clicks having happened.');
		});

		// QLog.error('Example error');

		// Build out our render order
		add(bgGroup);
		add(midGroundGroup);
		add(uiGroup);
		add(transitions);

		// Begin HUD
		var hudOffset = 24;

		// Seals collected
		var sealsCollectedTxt = new FlxBitmapText(0, FlxG.height - hudOffset);
		sealsCollectedTxt.screenCenter(X);
		sealsCollectedTxt.scrollFactor.set(0, 0);
		EventBus.subscribe(SealCollected, (e) -> {
			sealsCollectedTxt.text = '(${e.num_collected}/${e.total}) Seals';
		});
		uiGroup.add(sealsCollectedTxt);

		// Undo
		var undoBtn = new FlxButton(0, hudOffset, null, () -> {
			QLog.notice('undo');
			undo();
		});
		undoBtn.loadGraphic(AssetPaths.undo__png);
		undoBtn.screenCenter(X);
		undoBtn.x -= hudOffset * 2;
		undoBtn.scrollFactor.set(0, 0);
		uiGroup.add(undoBtn);

		// Restart
		var restartBtn = new FlxButton(0, hudOffset, null, () -> {
			QLog.notice('reset');
			gameBoard.reset();
		});
		restartBtn.loadGraphic(AssetPaths.restart__png);
		restartBtn.screenCenter(X);
		restartBtn.x += hudOffset * 2;
		restartBtn.scrollFactor.set(0, 0);
		uiGroup.add(restartBtn);
		// End HUD

		loadLevel("Level_0");

		FlxG.watch.add(this, "interactState", "Game State: ");
	}

	function loadLevel(levelName:String) {
		unload();

		var waterBG = new FlxBackdrop(AssetPaths.waterTile__png);
		Aseprite.loadAllAnimations(waterBG, AssetPaths.waterTile__json);
		var anims = AsepriteMacros.tagNames("assets/aseprite/waterTile.json");
		waterBG.animation.play(anims.animate);
		waterBG.velocity.set(10, -5);
		bgGroup.add(waterBG);

		level = new Level(levelName);
		FmodPlugin.playSong(level.raw.f_Music);

		var gbState = level.initialBoardState;

		var playerObj = new GameBoardObject();
		playerObj.type = PLAYER;
		playerObj.index = gbState.xyToIndex(level.spawnPointCell[0], level.spawnPointCell[1]);
		gbState.addObj(playerObj);

		player = new Player(level.spawnPoint.x, level.spawnPoint.y);
		// camera.follow(player);
		add(player);

		bind(playerObj, player);

		gameBoard = new GameBoard(gbState);

		// TODO Remove when hooked into GameBoard
		EventBus.fire(new SealCollected(1, 3));

		// TODO: build our new tile map with proper rendering so the tiles look nice.
		// The ones in the level.terrainLayer are editor tiles for now
		midGroundGroup.add(level.terrainLayer);
		FlxG.worldBounds.copyFrom(level.terrainLayer.getBounds());

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

		for (o in bgGroup) {
			o.destroy();
		}
		bgGroup.clear();

		for (o in midGroundGroup) {
			o.destroy();
		}
		midGroundGroup.clear();
	}

	function handleAchieve(def:AchievementDef) {
		add(def.toToast(true));
	}

	override public function update(elapsed:Float) {

		switch interactState {
			case RESOLVING:
				var phaseDone = true;
				for (t in pendingResolutions) {
					if (!t.isDone()) {
						phaseDone = false;
						break;
					}
				}
				if (phaseDone) {
					pendingResolutions = [];
					prepNextResolutionPhase();

					if (pendingResolutions.length == 0) {
						interactState = AWAITING_INPUT;
					}
				}
			case AWAITING_INPUT:
				var moveDir = Cardinal.NONE;
				if (SimpleController.pressed(UP) || SimpleController.just_released(UP)) {
					moveDir = Cardinal.N;
				} else if (SimpleController.pressed(RIGHT) || SimpleController.just_released(RIGHT)) {
					moveDir = Cardinal.E;
				} else if (SimpleController.pressed(DOWN) || SimpleController.just_released(DOWN)) {
					moveDir = Cardinal.S;
				} else if (SimpleController.pressed(LEFT) || SimpleController.just_released(LEFT)) {
					moveDir = Cardinal.W;
				}

				if (moveDir != Cardinal.NONE) {
					var results = gameBoard.move(moveDir);
					QLog.notice('Results - ${results}');
					pendingPhases = results;
					prepNextResolutionPhase();
					interactState = RESOLVING;
				}
		}

		super.update(elapsed);


		FlxG.collide(midGroundGroup, player);
		handleCameraBounds();

		TODO.sfx('scarySound');
	}

	function undo() {
		gameBoard.undo();
		gameBoard.current.iterTilesObjs((idx: Int, x:Int, y:Int, tile: Null<TileType>, objs: Array<GameBoardObject>) -> {
			// Reset tile
			level.terrainLayer.setTileIndex(idx, tile, true);
			// Reset game objects
			for (o in objs) {
				var gro = objectMap.get(o.id);
				if (gro != null) {
					var spr: FlxSprite = cast gro;
					spr.setPosition(x * 32, y * 32);
				}
			}
		});
	}

	function bind(boardObj:GameBoardObject, renderObj:GameRenderObject) {
		objectMap.set(boardObj.id, renderObj);
	}

	function prepNextResolutionPhase() {
		if (pendingPhases.length == 0) {
			return;
		}

		var phase = pendingPhases.shift();
		for (m in phase) {
			if (!objectMap.exists(m.gameObj.id)) {
				QLog.warn('got move result with no mapped object: ${m}');
				continue;
			}

			var t = objectMap[m.gameObj.id].handleGameResult(m, gameBoard);
			if (t != null) {
				pendingResolutions.push(t);
			}
		}
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
