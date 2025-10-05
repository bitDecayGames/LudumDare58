package states;

import flixel.math.FlxMath;
import bitdecay.flixel.graphics.AsepriteMacros;
import bitdecay.flixel.graphics.Aseprite;
import flixel.addons.display.FlxBackdrop;
import config.Configure;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.addons.transition.FlxTransitionableState;
import flixel.text.FlxText.FlxTextAlign;
import flixel.text.FlxBitmapText;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;
import haxefmod.flixel.FmodFlxUtilities;
import misc.FlxTextFactory;
import ui.MenuBuilder;

using states.FlxStateExt;

class CreditsState extends FlxTransitionableState {
	var _allCreditElements:Array<FlxSprite>;

	var _btnMainMenu:FlxButton;

	var _txtCreditsTitle:FlxBitmapText;
	var _txtThankYou:FlxBitmapText;
	var _txtRole:Array<FlxBitmapText>;
	var _txtCreator:Array<FlxBitmapText>;

	// Quick appearance variables
	private var backgroundColor = FlxColor.BLACK;

	static inline var entryLeftMargin = 50;
	static inline var entryRightMargin = 50;
	static inline var entryVerticalSpacing = 25;

	var waterBG:FlxBackdrop;

	var toolingImages = [
		AssetPaths.FLStudioLogo__png,
		AssetPaths.FmodLogoWhite__png,
		AssetPaths.HaxeFlixelLogo__png,
		// AssetPaths.pyxel_edit__png,
		AssetPaths.aseprite__png
	];

	override public function create():Void {
		super.create();
		bgColor = backgroundColor;
		camera.pixelPerfectRender = true;

		waterBG = new FlxBackdrop(AssetPaths.waterTile__png);
		Aseprite.loadAllAnimations(waterBG, AssetPaths.waterTile__json);
		var anims = AsepriteMacros.tagNames("assets/aseprite/waterTile.json");
		waterBG.scale.set(2, 2);
		waterBG.animation.play(anims.animate);
		add(waterBG);

		// _allCreditElements.push(waterBG);

		// Button

		_btnMainMenu = MenuBuilder.createTextButton("Main Menu", clickMainMenu);
		_btnMainMenu.setPosition(FlxG.width - _btnMainMenu.width, FlxG.height - _btnMainMenu.height);
		_btnMainMenu.updateHitbox();
		add(_btnMainMenu);

		// Credits

		_allCreditElements = new Array<FlxSprite>();

		_txtCreditsTitle = FlxTextFactory.make("Credits", FlxG.width / 4, FlxG.height / 2, 40, FlxTextAlign.CENTER);
		center(_txtCreditsTitle);
		add(_txtCreditsTitle);

		_txtRole = new Array<FlxBitmapText>();
		_txtCreator = new Array<FlxBitmapText>();

		_allCreditElements.push(_txtCreditsTitle);

		for (entry in Configure.getCredits()) {
			AddSectionToCreditsTextArrays(entry.sectionName, entry.names, _txtRole, _txtCreator);
		}

		var creditsVerticalOffset = FlxG.height;

		for (flxText in _txtRole) {
			flxText.setPosition(entryLeftMargin, creditsVerticalOffset);
			creditsVerticalOffset += entryVerticalSpacing;
		}

		creditsVerticalOffset = FlxG.height;

		// placeholders to get credits to align properly
		creditsVerticalOffset += entryVerticalSpacing;
		creditsVerticalOffset += entryVerticalSpacing;

		for (flxText in _txtCreator) {
			flxText.setPosition(FlxG.width - flxText.width - entryRightMargin, creditsVerticalOffset);
			creditsVerticalOffset += entryVerticalSpacing;
		}

		for (toolImg in toolingImages) {
			var display = new FlxSprite();
			display.loadGraphic(toolImg);
			// scale them to be about 1/4 of the height of the screen
			var scale = (FlxG.height / 4) / display.height;
			if (display.width * scale > FlxG.width) {
				// in case that's too wide, adjust accordingly
				scale = FlxG.width / display.width;
			}
			display.scale.set(scale, scale);
			display.updateHitbox();
			display.setPosition(0, creditsVerticalOffset);
			center(display);
			add(display);
			creditsVerticalOffset += Math.ceil(display.height) + entryVerticalSpacing;
			_allCreditElements.push(display);
		}

		_txtThankYou = FlxTextFactory.make("Thank you!", FlxG.width / 2, creditsVerticalOffset + FlxG.height / 2, 40, FlxTextAlign.CENTER);
		_txtThankYou.alignment = FlxTextAlign.CENTER;
		center(_txtThankYou);
		add(_txtThankYou);
		_allCreditElements.push(_txtThankYou);
	}

	private function AddSectionToCreditsTextArrays(role:String, creators:Array<String>, finalRoleArray:Array<FlxBitmapText>,
			finalCreatorsArray:Array<FlxBitmapText>) {
		var roleText = FlxTextFactory.make(role, 0, 0, 24);
		add(roleText);
		finalRoleArray.push(roleText);
		finalRoleArray.push(roleText);
		_allCreditElements.push(roleText);

		if (finalCreatorsArray.length != 0) {
			// placeholders to get credits to align properly
			finalCreatorsArray.push(new FlxBitmapText());
			finalCreatorsArray.push(new FlxBitmapText());
		}

		for (creator in creators) {
			// Make an offset entry for the roles array
			finalRoleArray.push(new FlxBitmapText());

			var creatorText = FlxTextFactory.make(creator, 0, 0, 24, FlxTextAlign.RIGHT);
			add(creatorText);
			finalCreatorsArray.push(creatorText);
			_allCreditElements.push(creatorText);
		}
	}

	var sineTimer = 0.0;
	var waveSpeed = 3;
	var waveDepth = 75;
	var stopTriggered = false;

	override public function update(elapsed:Float):Void {
		super.update(elapsed);

		sineTimer += elapsed * waveSpeed;

		var mod = FlxMath.fastSin(sineTimer) * waveDepth;

		// Stop scrolling when "Thank You" text is in the center of the screen
		if (stopTriggered || _txtThankYou.y + _txtThankYou.height / 2 < FlxG.height / 2) {
			waterBG.velocity.set();

			stopTriggered = true;

			_allCreditElements[_allCreditElements.length-1].y -= (mod) * elapsed;
			return;
		}

		for (element in _allCreditElements) {
			if (FlxG.keys.pressed.SPACE || FlxG.mouse.pressed) {
				element.y -= (120 + mod) * elapsed;
			} else {
				element.y -= (30 + mod) * elapsed;
			}
		}

		if (FlxG.keys.pressed.SPACE || FlxG.mouse.pressed) {
			waterBG.velocity.set(0, -120);
		} else {
			waterBG.velocity.set(0, -30);
		}
	}

	private function center(o:FlxObject) {
		o.x = (FlxG.width - o.width) / 2;
	}

	function clickMainMenu():Void {
		FmodFlxUtilities.TransitionToState(new MainMenuState());
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
