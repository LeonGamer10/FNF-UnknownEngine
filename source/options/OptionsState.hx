package options;

import states.MainMenuState;
import backend.StageData;

class OptionsState extends MusicBeatState
{
	var options:Array<String> = [
		'Note Colors',
		'Controls',
		'Adjust Delay and Rating Pop-up',
		'Graphics',
		'Visuals',
		'Gameplay',
		#if TRANSLATIONS_ALLOWED 'Language', #end
		'Advanced'
	];
	private var grpOptions:FlxTypedGroup<Alphabet>;
	private static var curSelected:Int = 0;
	public static var menuBG:FlxSprite;
	public static var onPlayState:Bool = false;

	var selectable:Bool = false;
	var menuMusic:FlxSound;
	var description:FlxText;

	function openSelectedSubstate(label:String) {
		switch(label)
		{
			case 'Note Colors':
				openSubState(new options.NotesSubState());
			case 'Controls':
				openSubState(new options.ControlsSubState());
			case 'Graphics':
				openSubState(new options.GraphicsSettingsSubState());
			case 'Visuals':
				openSubState(new options.VisualsSettingsSubState());
			case 'Gameplay':
				openSubState(new options.GameplaySettingsSubState());
			case 'Advanced':
				openSubState(new options.AdvancedSettingsSubState());
			case 'Adjust Delay and Rating Pop-up':
				MusicBeatState.switchState(new options.NoteOffsetState());
			case 'Language':
				openSubState(new options.LanguageSubState());
		}
	}

	var selectorLeft:Alphabet;
	var selectorRight:Alphabet;

	override function create()
	{
		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Options Menu", null);
		#end
		
		menuMusic = new FlxSound();
		menuMusic.loadEmbedded(Paths.music(Paths.formatToSongPath(ClientPrefs.data.pauseMusic)), true, true);
		menuMusic.volume = 0;
		menuMusic.play(false, FlxG.random.int(0, Std.int(menuMusic.length / 2)));

		FlxG.sound.list.add(menuMusic);
		
		if (!FlxG.sound.music.playing && ClientPrefs.data.pauseMusic != 'None') {
			FlxG.sound.playMusic(Paths.music(Paths.formatToSongPath(ClientPrefs.data.pauseMusic)), menuMusic.volume);
			FlxTween.tween(FlxG.sound.music, {volume: 1}, 0.8);
		}
		
		else if (!FlxG.sound.music.playing && !onPlayState && ClientPrefs.data.pauseMusic == 'None')
			FlxG.sound.playMusic(Paths.music('freakyMenu'));
			
		else if (!FlxG.sound.music.playing && onPlayState && ClientPrefs.data.pauseMusic == 'None')
			FlxG.sound.music.volume = 0;

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuOption'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.updateHitbox();
		
		var side:FlxSprite = new FlxSprite(0).loadGraphic(Paths.image('optSide'));
		side.scrollFactor.x = 0;
		side.scrollFactor.y = 0;
		side.antialiasing = true;
		side.x = 0;

		description = new FlxText(20, 69, FlxG.width / 2, "", 48);
		description.scrollFactor.x = 0;
		description.scrollFactor.y = 0;
		description.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		description.alignment = LEFT;
		description.x = 20;
		description.y = 924;
		description.borderSize = 2;

		bg.screenCenter();
		add(bg);
		add(side);
		add(description);

		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);

		for (num => option in options)
		{
			var optionText:Alphabet = new Alphabet(0, 0, Language.getPhrase('options_$option', option), true);
			optionText.scaleX = optionText.scaleY = 0.8;
			optionText.screenCenter();
			optionText.y += (80 * (num - (options.length / 2))) + 40;
			grpOptions.add(optionText);
		}

		selectorLeft = new Alphabet(0, 0, '>', true);
		selectorLeft.scaleX = selectorLeft.scaleY = 0.8;
		add(selectorLeft);
		selectorRight = new Alphabet(0, 0, '<', true);
		selectorRight.scaleX = selectorRight.scaleY = 0.8;
		add(selectorRight);
		
		new FlxTimer().start(0.22, function(tmr:FlxTimer)
		{
			FlxG.camera.zoom = 3;
			FlxTween.tween(FlxG.camera, {zoom: 1}, 1.5, {ease: FlxEase.expoInOut});
			FlxTween.tween(description, {y: 624}, 2.9, {ease: FlxEase.expoInOut});
		});
		
		new FlxTimer().start(1.3, function(tmr:FlxTimer)
		{
			selectable = true;
		});

		changeSelection();
		ClientPrefs.saveSettings();
		
		#if desktop
		MusicBeatState.windowNameSuffix = " - Options Menu";
		#end

		super.create();
	}

	override function closeSubState()
	{
		super.closeSubState();
		ClientPrefs.saveSettings();
		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Options Menu", null);
		#end
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (selectable)
		{
			if (controls.UI_UP_P)
				changeSelection(-1);
			if (controls.UI_DOWN_P)
				changeSelection(1);

			updateTexts();

			if (controls.BACK)
			{
				FlxG.sound.play(Paths.sound('cancelMenu'));
				FlxTween.tween(FlxG.camera, {zoom: 3}, 1, {ease: FlxEase.expoInOut});
				FlxTween.tween(FlxG.sound.music, {volume: 0}, 0.4);
				if(onPlayState)
				{
					StageData.loadDirectory(PlayState.SONG);
					LoadingState.loadAndSwitchState(new PlayState());
				}
				else MusicBeatState.switchState(new MainMenuState());
			}
			else if (controls.ACCEPT) openSelectedSubstate(options[curSelected]);
		}
	}

	function updateTexts()
	{
		switch (options[curSelected])
		{
			case 'Note Colors':
				description.text = Language.getPhrase('description_note_colors', "NOTE COLORS:\nChange the colors of the funny\nnotes.");
			case 'Controls':
				description.text = Language.getPhrase('description_controls', "CONTROLS:\nChange your controls, however\nyou want.");
			case 'Adjust Delay and Rating Pop-up':
				description.text = Language.getPhrase('description_adjust_delay_and_rating_pop-up', "ADJUST DELAY AND RATING POP-UP:\nChange the offset of the rating\npopup or audio delay.");
			case 'Graphics':
				description.text = Language.getPhrase('description_graphics', "GRAPHICS:\nChange how the graphics work in\ngame.");
			case 'Visuals':
				description.text = Language.getPhrase('description_visuals', "VISUALS:\nChange the UI, menus, or audio\nof the game.");
			case 'Gameplay':
				description.text = Language.getPhrase('description_gameplay', "GAMEPLAY: \nChange how in song gameplay\nworks.");
			case 'Language':
				description.text = Language.getPhrase('description_language', "LANGUAGE: \nSelect your preferred language.");
			case 'Advanced':
				description.text = Language.getPhrase('description_advanced', "ADVANCED: \nAdvanced options that do\nnot fit the above categories.");
		}
	}

	function changeSelection(change:Int = 0)
	{
		curSelected = FlxMath.wrap(curSelected + change, 0, options.length - 1);

		for (num => item in grpOptions.members)
		{
			item.targetY = num - curSelected;
			item.alpha = 0.6;
			if (item.targetY == 0)
			{
				item.alpha = 1;
				selectorLeft.x = item.x - 63;
				selectorLeft.y = item.y;
				selectorRight.x = item.x + item.width + 15;
				selectorRight.y = item.y;
			}
		}
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}

	override function destroy()
	{
		ClientPrefs.loadPrefs();
		FlxG.sound.music.stop();
		
		super.destroy();
	}
}