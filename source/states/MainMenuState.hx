package states;

import flixel.FlxObject;
import flixel.util.FlxGradient;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxGridOverlay;
import flixel.effects.FlxFlicker;
import lime.app.Application;
import states.editors.MasterEditorMenu;
import options.OptionsState;

enum MainMenuColumn {
	LEFT;
	CENTER;
	RIGHT;
}

class MainMenuState extends MusicBeatState
{
	public static var psychEngineVersion:String = '1.0a';
	public static var unknownEngineVersion:String = '3.0a';
	public static var curSelected:Int = 0;
	public static var curColumn:MainMenuColumn = CENTER;
	
	private var camMenu:FlxCamera;

	var menuItems:FlxTypedGroup<FlxSprite>;
	var leftItem:FlxSprite;
	var rightItem:FlxSprite;

	//Centered/Text options
	var optionShit:Array<String> = [
		'play',
		#if MODS_ALLOWED 'mods', #end
		'credits'
	];

	var leftOption:String = #if ACHIEVEMENTS_ALLOWED 'achievements' #else null #end;
	var rightOption:String = 'options';
	
	var bg:FlxSprite = new FlxSprite(-80).loadGraphic(Paths.image('menuBG'));
	var middle:FlxSprite = new FlxSprite(0).loadGraphic(Paths.image('menuMid'));
	
	var grid:FlxBackdrop = new FlxBackdrop(FlxGridOverlay.createGrid(95, 80, 190, 160, true, 0x33FC03DB, 0x0));
	
	var gradientBar:FlxSprite = new FlxSprite(0, 0).makeGraphic(FlxG.width, 300, 0xFFAA00AA);

	var camFollow:FlxObject;

	override function create()
	{
		#if MODS_ALLOWED
		Mods.pushGlobalMods();
		#end
		Mods.loadTopMod();

		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence.
		DiscordClient.changePresence("In the Menus", null);
		#end
		
		if(FlxG.sound.music != null)
			if (!FlxG.sound.music.playing)
			{	
				FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
        		FlxG.sound.music.time = 9400;
				FlxTween.tween(FlxG.sound.music, {volume: 1}, 0.4);
			}
			
		camMenu = initPsychCamera();
		FlxCamera.defaultCameras = [camMenu];

		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

		persistentUpdate = persistentDraw = true;

		var yScroll:Float = 0.25;
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.scrollFactor.set(0, yScroll);
		bg.setGraphicSize(Std.int(bg.width * 1.175));
		bg.updateHitbox();
		bg.screenCenter();
		add(bg);
		
		gradientBar = FlxGradient.createGradientFlxSprite(Math.round(FlxG.width), 512, [0x00ff0000, 0x55AE59E4, 0xAA19ECFF], 1, 90, true);
		gradientBar.y = FlxG.height - gradientBar.height;
		add(gradientBar);
		gradientBar.scrollFactor.set(0, 0);
		
		grid.velocity.set(45, 16);
		grid.alpha = 0;
		FlxTween.tween(grid, {alpha: 1}, 0.5, {ease: FlxEase.quadOut});
		add(grid);
		grid.scrollFactor.set(0, 0.07);
		
		middle.scrollFactor.x = 0;
		middle.scrollFactor.y = 0;
		middle.setGraphicSize(Std.int(middle.width * 0.75));
		middle.updateHitbox();
		middle.screenCenter();
		middle.antialiasing = true;
		add(middle);

		camFollow = new FlxObject(0, 0, 1, 1);
		add(camFollow);

		menuItems = new FlxTypedGroup<FlxSprite>();
		add(menuItems);

		for (num => option in optionShit)
		{
			var item:FlxSprite = createMenuItem(option, 0, (num * 140) + 90);
			item.y += (4 - optionShit.length) * 70; // Offsets for when you have anything other than 4 items
			item.screenCenter(X);
		}

		if (leftOption != null)
			leftItem = createMenuItem(leftOption, 60, 490);
		if (rightOption != null)
		{
			rightItem = createMenuItem(rightOption, FlxG.width - 60, 490);
			rightItem.x -= rightItem.width;
		}

		var psychVer:FlxText = new FlxText(12, FlxG.height - 24, 0, "Psych Engine v" + psychEngineVersion, 12);
		psychVer.scrollFactor.set();
		psychVer.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(psychVer);
		var unknownVer:FlxText = new FlxText(12, FlxG.height - 24, 1250, "Unknown Engine v" + unknownEngineVersion + " | Friday Night Funkin' v" + Application.current.meta.get('version'), 12);
		unknownVer.scrollFactor.set();
		unknownVer.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(unknownVer);
		var micdUpVer:FlxText = new FlxText(12, FlxG.height - 24,  FlxG.width - 24, "Mic'd Up v2.0.3", 12);
		micdUpVer.scrollFactor.set();
		micdUpVer.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(micdUpVer);
		
		changeItem();

		#if ACHIEVEMENTS_ALLOWED
		// Unlocks "Freaky on a Friday Night" achievement if it's a Friday and between 18:00 PM and 23:59 PM
		var leDate = Date.now();
		if (leDate.getDay() == 5 && leDate.getHours() >= 18)
			Achievements.unlock('friday_night_play');

		#if MODS_ALLOWED
		Achievements.reloadList();
		#end
		#end
		
		#if desktop
		MusicBeatState.windowNameSuffix = " - Main Menu";
		#end

		super.create();
		
		new FlxTimer().start(1, function(tmr:FlxTimer)
		{
			selectable = true;
		});

		camMenu.follow(camFollow, null, 9);
	}

	function createMenuItem(name:String, x:Float, y:Float):FlxSprite
	{
		var menuItem:FlxSprite = new FlxSprite(x, y);
		menuItem.frames = Paths.getSparrowAtlas('mainmenu/menu_$name');
		menuItem.animation.addByPrefix('idle', '$name idle', 24, true);
		menuItem.animation.addByPrefix('selected', '$name selected', 24, true);
		menuItem.animation.play('idle');
		menuItem.updateHitbox();
		
		menuItem.antialiasing = ClientPrefs.data.antialiasing;
		menuItem.scrollFactor.set();
		menuItems.add(menuItem);
		return menuItem;
	}

	var selectable:Bool = false;
	var selectedSomethin:Bool = false;

	var holdTime:Float = 0;

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music.volume < 0.8)
			FlxG.sound.music.volume = Math.min(FlxG.sound.music.volume + 0.5 * elapsed, 0.8);

		if (!selectedSomethin && selectable)
		{
			var shiftMult:Int = 1;
			if (FlxG.keys.pressed.SHIFT)
				shiftMult = 3;

			if (FlxG.mouse.wheel != 0)
				changeItem(-FlxG.mouse.wheel);

			if (controls.UI_UP_P)
			{
				changeItem(-shiftMult);
				holdTime = 0;
			}

			if (controls.UI_DOWN_P)
			{
				changeItem(shiftMult);
				holdTime = 0;
			}

			if (controls.UI_DOWN || controls.UI_UP)
			{
				var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
				holdTime += elapsed;
				var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);

				if (holdTime > 0.5 && checkNewHold - checkLastHold > 0)
				{
					changeItem((checkNewHold - checkLastHold) * (controls.UI_UP ? -shiftMult : shiftMult));
				}
			}

			switch(curColumn)
			{
				case CENTER:
					if(controls.UI_LEFT_P && leftOption != null)
					{
						curColumn = LEFT;
						changeItem();
					}
					else if(controls.UI_RIGHT_P && rightOption != null)
					{
						curColumn = RIGHT;
						changeItem();
					}

				case LEFT:
					if(controls.UI_RIGHT_P)
					{
						curColumn = CENTER;
						changeItem();
					}

				case RIGHT:
					if(controls.UI_LEFT_P)
					{
						curColumn = CENTER;
						changeItem();
					}
			}

			if (controls.BACK)
			{
				selectedSomethin = true;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new TitleState());
				
				#if desktop
				MusicBeatState.windowNameSuffix = "";
				#end
			}

			if (controls.ACCEPT)
			{
				FlxG.sound.play(Paths.sound('confirmMenu'));
				if (optionShit[curSelected] != 'donate')
				{
					selectedSomethin = true;

					var item:FlxSprite;
					var option:String;
					switch(curColumn)
					{
						case CENTER:
							option = optionShit[curSelected];
							item = menuItems.members[curSelected];

						case LEFT:
							option = leftOption;
							item = leftItem;

						case RIGHT:
							option = rightOption;
							item = rightItem;
					}

					FlxTween.tween(FlxG.camera, {zoom: 10}, 1.6, {ease: FlxEase.expoIn});
					FlxTween.tween(bg, {angle: 90}, 1.6, {ease: FlxEase.expoIn});
					
					FlxFlicker.flicker(item, 1, 0.06, false, false, function(flick:FlxFlicker)
					{
						switch (option)
						{
							case 'play':
								MusicBeatState.switchState(new GamemodesMenuState());

							#if MODS_ALLOWED
							case 'mods':
								MusicBeatState.switchState(new ModsMenuState());
							#end

							#if ACHIEVEMENTS_ALLOWED
							case 'achievements':
								MusicBeatState.switchState(new AchievementsMenuState());
							#end

							case 'credits':
								MusicBeatState.switchState(new CreditsState());
							case 'options':
								MusicBeatState.switchState(new OptionsState());
								OptionsState.onPlayState = false;
								if (PlayState.SONG != null)
								{
									PlayState.SONG.arrowSkin = null;
									PlayState.SONG.splashSkin = null;
									PlayState.stageUI = 'normal';
								}
								FlxG.sound.music.stop();
								FlxG.sound.music == null;
						}
					});
					
					for (memb in menuItems)
					{
						if(memb == item)
							continue;

						FlxTween.tween(memb, {alpha: 0}, 0.4, {ease: FlxEase.quadOut});
					}
				}
				else CoolUtil.browserLoad('https://ninja-muffin24.itch.io/funkin');
			}
			#if desktop
			if (controls.justPressed('debug_1'))
			{
				selectedSomethin = true;
				MusicBeatState.switchState(new MasterEditorMenu());
			}
			#end
		}

		super.update(elapsed);
	}

	function changeItem(change:Int = 0)
	{
		if(change != 0) curColumn = CENTER;
		curSelected = FlxMath.wrap(curSelected + change, 0, optionShit.length - 1);
		FlxG.sound.play(Paths.sound('scrollMenu'));

		for (item in menuItems)
		{
			item.animation.play('idle');
			item.centerOffsets();
		}

		var selectedItem:FlxSprite;
		switch(curColumn)
		{
			case CENTER:
				selectedItem = menuItems.members[curSelected];
			case LEFT:
				selectedItem = leftItem;
			case RIGHT:
				selectedItem = rightItem;
		}
		selectedItem.animation.play('selected');
		selectedItem.centerOffsets();
		camFollow.y = selectedItem.getGraphicMidpoint().y;
	}
}
