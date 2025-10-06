package states;

import bitdecay.flixel.spacial.Align;
import collectables.Collectables;
import entities.Tile;
import bitdecay.flixel.sorting.ZSorting;
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
import gameboard.GameBoardMoveResult;
import todo.TODO;
import flixel.group.FlxGroup;
import flixel.math.FlxRect;
import flixel.group.FlxGroup.FlxTypedGroup;
import entities.CameraTransition;
import levels.ldtk.Level;
import levels.ldtk.Ldtk.LdtkProject;
import achievements.Achievements;
import entities.Player;
#if debug
import entities.PlayerWin;
import flixel.math.FlxPoint;
#end
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
	var TRANSITIONING = "transitioning";
}

class PlayState extends FlxTransitionableState {
	public static var ME:PlayState = null;

	var player:Player;
	var bgGroup = new FlxGroup();
	var tileGroup = new FlxTypedGroup<Tile>();
	var midGroundGroup = new FlxGroup();
	var actionGroup = new FlxTypedGroup<FlxSprite>();
	var uiGroup = new FlxGroup();
	var activeCameraTransition:CameraTransition = null;

	var transitions = new FlxTypedGroup<CameraTransition>();

	var ldtk = new LdtkProject();
	var level:Level;
	var gameBoard:GameBoard;

	var interactState:InteractState = RESOLVING;
	var pendingResolutions = new Array<Completable>();
	var pendingPhases = new Array<Array<GameBoardMoveResult>>();

	var startingLevel:String = "";

	public function new(levelIID:String = "") {
		super();
		startingLevel = levelIID;

		ME = this;
	}

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
		add(tileGroup);
		add(midGroundGroup);
		add(actionGroup);
		add(uiGroup);
		add(transitions);

		// Begin HUD
		var hudOffset = 24;

		// Seals collected
		var sealsCollectedTxt = new FlxBitmapText(hudOffset, hudOffset);
		sealsCollectedTxt.scale.set(3, 3);
		sealsCollectedTxt.scrollFactor.set(0, 0);
		EventBus.subscribe(SealCollected, (e) -> {
			sealsCollectedTxt.text = '(${e.num_collected}/${e.total}) Seals';
		});
		uiGroup.add(sealsCollectedTxt);

		// Undo
		var undoBtn = new FlxButton(0, hudOffset, null, () -> {
			if (interactState == AWAITING_INPUT) {
				QLog.notice('undo');
				undo();
			}
		});
		undoBtn.loadGraphic(AssetPaths.undo__png);
		undoBtn.scrollFactor.set(0, 0);
		uiGroup.add(undoBtn);

		// Restart
		var restartBtn = new FlxButton(0, hudOffset, null, () -> {
			if (interactState == AWAITING_INPUT) {
				QLog.notice('reset');
				reset();
			}
		});
		restartBtn.loadGraphic(AssetPaths.restart__png);
		restartBtn.scrollFactor.set(0, 0);
		uiGroup.add(restartBtn);

		// Level Select
		var lvlSelectBtn = new FlxButton(0, hudOffset, null, () -> {
			if (interactState == AWAITING_INPUT) {
				QLog.notice('back to level select');
				FlxG.switchState(() -> new LevelSelect());
			}
		});
		lvlSelectBtn.loadGraphic(AssetPaths.exit__png);
		lvlSelectBtn.scrollFactor.set(0, 0);
		uiGroup.add(lvlSelectBtn);

		restartBtn.screenCenter(X);
		Align.stack(undoBtn, restartBtn, LEFT, hudOffset);
		Align.stack(lvlSelectBtn, restartBtn, RIGHT, hudOffset);
		// End HUD

		loadLevel(startingLevel);

		FlxG.watch.add(this, "interactState", "Game State: ");
	}

	public function transist() {
		if (level.nextLevel != "") {
			levelTransition(level.nextLevel);
		} else {
			FlxG.switchState(() -> new CreditsState());
		}
	}

	public function levelTransition(levelName:String) {
		interactState = TRANSITIONING;
		camera.fade(() -> {
			loadLevel(levelName);
			camera.fade(true);
			interactState = RESOLVING;
		});
	}

	function loadLevel(levelName:String) {
		unload();

		if (levelName == "") {
			var anchor = ldtk.toc.FirstLevel[0];
			levelName = ldtk.all_worlds.Default.getLevelAt(anchor.worldX, anchor.worldY).iid;
		}

		var waterBG = new FlxBackdrop(AssetPaths.waterTile__png);
		Aseprite.loadAllAnimations(waterBG, AssetPaths.waterTile__json);
		var anims = AsepriteMacros.tagNames("assets/aseprite/waterTile.json");
		waterBG.animation.play(anims.animate);
		waterBG.velocity.set(10, -5);
		bgGroup.add(waterBG);

		// var waterBGSmall = new FlxBackdrop(AssetPaths.waterTile__png);
		// Aseprite.loadAllAnimations(waterBGSmall, AssetPaths.waterTile__json);
		// var anims = AsepriteMacros.tagNames("assets/aseprite/waterTile.json");
		// waterBGSmall.animation.play(anims.animate);
		// waterBGSmall.velocity.set(12, -6);
		// // waterBGSmall.scale.set(2, 2);
		// waterBGSmall.scale.set(.5, 0.5);
		// waterBGSmall.alpha = 0.3;
		// bgGroup.add(waterBGSmall);

		// var waterBGMed = new FlxBackdrop(AssetPaths.waterTile__png);
		// Aseprite.loadAllAnimations(waterBGMed, AssetPaths.waterTile__json);
		// var anims = AsepriteMacros.tagNames("assets/aseprite/waterTile.json");
		// waterBGMed.animation.play(anims.animate);
		// waterBGMed.velocity.set(-1, -6);
		// // waterBGSmall.scale.set(2, 2);
		// waterBGMed.scale.set(.25, 0.25);
		// waterBGMed.alpha = 0.3;
		// bgGroup.add(waterBGMed);

		level = new Level(levelName);
		// FmodPlugin.playSong(level.raw.f_Music);
		for (waterFlavor in level.waterFlavor) {
			bgGroup.add(waterFlavor);
		}

		var gbState = level.initialBoardState;

		// add all of the render objects to the scene
		player = level.player;
		actionGroup.add(player);
		for (tile in level.tiles) {
			tileGroup.add(tile);
		}
		for (collectable in level.collectables) {
			actionGroup.add(collectable);
		}
		for (block in level.blocks) {
			actionGroup.add(block);
		}
		for (hazard in level.hazards) {
			actionGroup.add(hazard);
		}
		for (exit in level.exits) {
			actionGroup.add(exit);
		}

		Collectables.initLevel(level.name, level.collectables.length);

		gameBoard = new GameBoard(gbState);

		FlxG.worldBounds.copyFrom(level.getBounds());

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
		pendingResolutions = [];

		for (t in transitions) {
			t.destroy();
		}
		transitions.clear();

		for (o in bgGroup) {
			o.destroy();
		}
		bgGroup.clear();

		for (o in tileGroup) {
			o.destroy();
		}
		tileGroup.clear();

		for (o in midGroundGroup) {
			o.destroy();
		}
		midGroundGroup.clear();

		for (o in actionGroup) {
			o.destroy();
		}
		actionGroup.clear();
	}

	function handleAchieve(def:AchievementDef) {
		add(def.toToast(true));
	}

	override public function update(elapsed:Float) {
		switch interactState {
			case TRANSITIONING:
				// nothing to do. just wait for our transition to end
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
				#if debug
				handleRightClick();
				#end
				var moveDir = Cardinal.NONE;
				if (player.alive) {
					if (SimpleController.pressed(UP) || SimpleController.just_released(UP)) {
						moveDir = Cardinal.N;
					} else if (SimpleController.pressed(RIGHT) || SimpleController.just_released(RIGHT)) {
						moveDir = Cardinal.E;
					} else if (SimpleController.pressed(DOWN) || SimpleController.just_released(DOWN)) {
						moveDir = Cardinal.S;
					} else if (SimpleController.pressed(LEFT) || SimpleController.just_released(LEFT)) {
						moveDir = Cardinal.W;
					}
				}

				if (moveDir != Cardinal.NONE) {
					var results = gameBoard.move(moveDir);
					QLog.notice('Results - ${results}');
					pendingPhases = results;
					prepNextResolutionPhase();
					interactState = RESOLVING;
				}

				if (FlxG.keys.justPressed.R) {
					reset();
				}
				if (FlxG.keys.justPressed.U || FlxG.keys.justPressed.Z) {
					undo();
				}
				#if debug
				if (FlxG.keys.justPressed.SPACE) {
					var mousePos = FlxG.mouse.getWorldPosition();
					new PlayerWin(mousePos.x, mousePos.y, FlxPoint.get(mousePos.x + 100, mousePos.y), true, false);
				}
				#end
		}
		super.update(elapsed);

		actionGroup.sort(ZSorting.getSort(VerticalReference.BOTTOM));

		FlxG.collide(midGroundGroup, player);
		handleCameraBounds();
	}

	function syncRenderState() {
		gameBoard.current.iterTilesObjs((idx:Int, x:Int, y:Int, tile:Null<TileType>, objs:Array<GameBoardObject>) -> {
			// Reset tile
			if (tile != null) {
				var t = level.tilesById.get(idx);
				if (!t.alive) {
					t.revive();
				}
				t.setTileType(tile);
			}
			// Reset game objects
			for (o in objs) {
				var gro = level.renderObjectsById.get(o.id);
				if (gro != null) {
					var spr:FlxSprite = cast gro;
					spr.revive();
					spr.setPosition(x * 32, y * 32);
				}
			}
		});
	}

	function undo() {
		var prevCount = gameBoard.current.countObjByType(COLLECTABLE);
		gameBoard.undo();
		var newCount = gameBoard.current.countObjByType(COLLECTABLE);
		syncRenderState();
		// Reset collectables
		Collectables.incrCollect(prevCount - newCount);
	}

	function reset() {
		gameBoard.reset();
		syncRenderState();
		// Reset collectables
		Collectables.resetCollected();
	}

	function handleRightClick() {
		if (FlxG.mouse.justPressedRight) {
			var mousePos = FlxG.mouse.getWorldPosition();
			for (tile in tileGroup) {
				if (tile != null && tile.overlapsPoint(mousePos)) {
					var results = gameBoard.teleport(tile.cellX, tile.cellY);
					QLog.notice('Results - ${results}');
					pendingPhases = results;
					prepNextResolutionPhase();
					interactState = RESOLVING;
					return;
				}
			}
		}
	}

	function prepNextResolutionPhase() {
		if (pendingPhases.length == 0) {
			return;
		}

		var phase = pendingPhases.shift();
		for (m in phase) {
			if (m.gameObj != null) {
				var obj = level.renderObjectsById.get(m.gameObj.id);
				if (obj == null) {
					QLog.warn('got move result with no mapped object: ${m}');
					continue;
				}
				var t = obj.handleGameResult(m, gameBoard);
				if (t != null) {
					pendingResolutions.push(t);
				}
			} else if (m is Crumble) {
				level.tilesById.get(gameBoard.current.xyToIndex(m.startPos[0], m.startPos[1])).handleGameResult(m, gameBoard);
			} else if (m is Melt) {
				level.tilesById.get(gameBoard.current.xyToIndex(m.startPos[0], m.startPos[1])).handleGameResult(m, gameBoard);
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
