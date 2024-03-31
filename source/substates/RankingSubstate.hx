package substates;

import backend.Highscore;
import backend.StageData;
import backend.WeekData;
import backend.Song;
import backend.Section;
import backend.Rating;

import flixel.system.FlxSound;

import flixel.addons.transition.FlxTransitionableState;

import states.StoryMenuState;
import states.FreeplayState;
import states.PlayState;
import states.TitleState;
import states.editors.ChartingState;
import states.editors.CharacterEditorState;

class RankingSubstate extends MusicBeatSubstate
{
	var pauseMusic:FlxSound;

	var win:FlxSprite;
	var rank:FlxSprite = new FlxSprite(-200, 730);
	var combo:FlxSprite = new FlxSprite(-200, 730);
	
	public static var hint:FlxText;
	public static var comboRank:String = "NA";
	public static var ranking:String = "NA";
	
	var selectable:Bool = false;
	
	var rankingNum:Int = 15;

	public function new(x:Float, y:Float)
	{
		
		super();

		generateRanking();

		#if desktop
		MusicBeatState.windowNameSuffix = " - Results: " + PlayState.SONG.song;
		#end

		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence.
		DiscordClient.changePresence("Song Complete", null);
		#end

		if (!ClientPrefs.getGameplaySetting('botplay'))
			Highscore.saveRank(PlayState.SONG.song, rankingNum, PlayState.storyDifficulty);

		pauseMusic = new FlxSound().loadEmbedded(Paths.music(Paths.formatToSongPath(ClientPrefs.data.pauseMusic)), true, true);
		pauseMusic.volume = 0;
		pauseMusic.play(false, FlxG.random.int(0, Std.int(pauseMusic.length / 2)));

		FlxG.sound.list.add(pauseMusic);

		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0;
		bg.scrollFactor.set();
		add(bg);
		
		win = new FlxSprite(0, 0);
		win.frames = Paths.getSparrowAtlas('end_screen/winBump');
		win.animation.addByPrefix('jumpscare', 'win!', 24, true);
		win.animation.play('jumpscare');
		win.updateHitbox();
		win.screenCenter();
		add(win);

		FlxG.sound.play(Paths.sound('confirmMenu'));

		rank = new FlxSprite(-20, 40).loadGraphic(Paths.image('end_screen/rankings/$ranking'));
		rank.alpha = 0;
		rank.scrollFactor.set();
		add(rank);
		rank.antialiasing = true;
		rank.setGraphicSize(0, 450);
		rank.updateHitbox();
		rank.screenCenter();

		combo = new FlxSprite(-20, 40).loadGraphic(Paths.image('end_screen/rankings/$comboRank'));
		combo.alpha = 0;
		combo.scrollFactor.set();
		combo.screenCenter();
		combo.x = rank.x - combo.width / 2;
		combo.y = rank.y - combo.height / 2;
		add(combo);
		combo.antialiasing = true;
		combo.setGraphicSize(0, 130);

		var press:FlxText = new FlxText(20, 15, 0, "Press any key to continue.", 32);
		press.scrollFactor.set();
		press.setFormat(Paths.font("vcr.ttf"), 32);
		press.setBorderStyle(OUTLINE, 0xFF000000, 5, 1);
		press.updateHitbox();
		add(press);

		hint = new FlxText(20, 15, 0, "You passed. Miss no more than 10 times for SDCB.", 32);
		hint.scrollFactor.set();
		hint.setFormat(Paths.font("vcr.ttf"), 32);
		hint.setBorderStyle(OUTLINE, 0xFF000000, 5, 1);
		hint.updateHitbox();
		add(hint);
		
		if (comboRank == "MFC" && PlayState.marvelousFullRank)
			hint.text = "Congrats! You're perfect!";
		else if (comboRank == "GFC" && PlayState.goodFullRank)
			hint.text = "You're doing great! Try getting sicks at minimum for MFC.";
		else if (comboRank == "FC" && PlayState.fullRank)
			hint.text = "Good job. Try getting goods at minimum for GFC.";
		else if (comboRank == "SDCB" && PlayState.singleDigitRank)
			hint.text = "Not bad. Miss no more than 1 time for FC.";

		if (ClientPrefs.getGameplaySetting('botplay'))
		{
			hint.y -= 35;
			hint.text = "Botplay is enabled. Score and Rank weren't saved.";
		}

		if (PlayState.deathCounter >= 30)
		{
			hint.text = "skill issue\nnoob";
		}

		hint.screenCenter(X);

		hint.alpha = press.alpha = 0;

		press.screenCenter();
		press.y = 670 - press.height;

		FlxTween.tween(bg, {alpha: 0.6}, 0.4, {ease: FlxEase.quartInOut});

		new FlxTimer().start(2, function(tmr:FlxTimer)
		{
			FlxTween.tween(win, {alpha: 0}, 0.4, {ease: FlxEase.quartInOut});
			FlxTween.tween(rank, {alpha: 1}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.3});
			FlxTween.tween(combo, {alpha: 1}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.3});
			FlxTween.tween(press, {alpha: 1, y: 690 - press.height}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.6});
			FlxTween.tween(hint, {alpha: 1, y: 645 - hint.height}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.6});
			
			new FlxTimer().start(0.6, function(tmr:FlxTimer)
			{
				selectable = true;
			});
		});

		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
	}

	override function update(elapsed:Float)
	{
		if (pauseMusic.volume < 0.5)
			pauseMusic.volume += 0.01;

		super.update(elapsed);

		if (selectable)
			if (FlxG.keys.justPressed.ANY || ClientPrefs.getGameplaySetting('practice'))
			{
				PlayState.singleDigitRank = false;
				PlayState.fullRank = false;
				PlayState.alrightFullRank = false;
				PlayState.goodFullRank = false;
				PlayState.marvelousFullRank = false;
				
				if (PlayState.isStoryMode) 
				{
					Mods.loadTopMod();
					FlxG.sound.playMusic(Paths.music('freakyMenu'));
					#if DISCORD_ALLOWED DiscordClient.resetClientID(); #end

					MusicBeatState.switchState(new StoryMenuState());
					PlayState.changedDifficulty = false;
				}
				else
				{
					trace('WENT BACK TO FREEPLAY??');
					Mods.loadTopMod();
					#if DISCORD_ALLOWED DiscordClient.resetClientID(); #end

					MusicBeatState.switchState(new FreeplayState());
					FlxG.sound.playMusic(Paths.music('freakyMenu'));
					PlayState.changedDifficulty = false;
				}
			}
	}

	override function destroy()
	{
		pauseMusic.destroy();

		super.destroy();
	}

	function generateRanking():String
	{	
		var isCpu:Bool = false;
		isCpu = ClientPrefs.getGameplaySetting('botplay');
		
		if (PlayState.marvelousFullRank && !isCpu) // Marvelous Full Combo
			comboRank = "MFC";
		else if (PlayState.goodFullRank && !isCpu) // Good Full Combo
			comboRank = "GFC";
		else if (PlayState.alrightFullRank && !isCpu) // Alright Full Combo
			comboRank = "AFC";
		else if (PlayState.fullRank && !isCpu) // Regular FC
			comboRank = "FC";
		else if (PlayState.singleDigitRank && !isCpu) // Single Digit Combo Breaks
			comboRank = "SDCB";
		else if (isCpu)
			comboRank = "NA";
			
		// WIFE TIME :)))) (based on Wife3)

		var wifeConditions:Array<Bool> = [
			PlayState.accuracy >= 100, // P
			PlayState.accuracy >= 95, // X
			PlayState.accuracy >= 90, // X-
			PlayState.accuracy >= 87.75, // SS+
			PlayState.accuracy >= 85, // SS
			PlayState.accuracy >= 83.75, // SS-
			PlayState.accuracy >= 82.50, // S+
			PlayState.accuracy >= 81.00, // S
			PlayState.accuracy >= 80, // S-
			PlayState.accuracy >= 75, // A+
			PlayState.accuracy >= 70, // A
			PlayState.accuracy >= 65, // A-
			PlayState.accuracy >= 60, // B
			PlayState.accuracy >= 50, // C
			PlayState.accuracy >= 40, // D
			PlayState.accuracy < 20 // E
		];

		for (i in 0...wifeConditions.length)
		{
			var b = wifeConditions[i];
			if (b)
			{
				rankingNum = i;
				switch (i)
				{
					case 0:
						ranking = "P";
					case 1:
						ranking = "X";
					case 2:
						ranking = "X-";
					case 3:
						ranking = "SS+";
					case 4:
						ranking = "SS";
					case 5:
						ranking = "SS-";
					case 6:
						ranking = "S+";
					case 7:
						ranking = "S";
					case 8:
						ranking = "S-";
					case 9:
						ranking = "A+";
					case 10:
						ranking = "A";
					case 11:
						ranking = "A-";
					case 12:
						ranking = "B";
					case 13:
						ranking = "C";
					case 14:
						ranking = "D";
					case 15:
						ranking = "E";
				}

				if (PlayState.deathCounter >= 30 || PlayState.accuracy == 0)
					ranking = "F";
				
				if (ClientPrefs.getGameplaySetting('botplay'))
					ranking = "NA";
				break;
			}
		}
		return ranking;
	}
}
