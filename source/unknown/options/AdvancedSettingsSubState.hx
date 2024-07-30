package options;

class AdvancedSettingsSubState extends BaseOptionsMenu
{
	var blackBG:FlxSprite;
	var coolText:Alphabet;
	var timer:FlxTimer;
	
	public function new()
	{
		title = Language.getPhrase('advanced_menu', 'Advanced Settings');
		rpcTitle = 'Advanced Settings Menu'; //for Discord Rich Presence
		
		blackBG = new FlxSprite().makeGraphic(1, 1, 0xFF000000);
		blackBG.setGraphicSize(FlxG.width, FlxG.height);
		blackBG.updateHitbox();
		blackBG.alpha = 0;

		coolText = new Alphabet(FlxG.width / 2, (FlxG.height / 2) - 25, "", true);
		coolText.alignment = CENTERED;
		coolText.alpha = 0;

		timer = new FlxTimer();
		
		#if !mobile
		var option:Option = new Option('FPS Counter',
			'If unchecked, hides FPS Counter.',
			'showFPS',
			BOOL);
		addOption(option);
		option.onChange = onChangeCounter;
		
		var option:Option = new Option('Memory Counter',
			'If unchecked, hides Memory Counter.',
			'showMem',
			 BOOL);
		addOption(option);
		option.onChange = onChangeCounter;

		var option:Option = new Option('Memory Peak Counter',
			'If unchecked, hides Memory Peak Counter.',
			'showMemPeak',
			BOOL);
		addOption(option);
		option.onChange = onChangeCounter;
		
		var option:Option = new Option('Commit Counter',
			'If unchecked, hides current build commit number.',
			'showBuild',
			BOOL);
		addOption(option);
		option.onChange = onChangeCounter;
		#end
		
		#if DISCORD_ALLOWED
		var option:Option = new Option('Discord Rich Presence',
			"Uncheck this to prevent accidental leaks, it will hide the Application from your \"Playing\" box on Discord",
			'discordRPC',
			BOOL);
		addOption(option);
		#end

		#if CHECK_FOR_UPDATES
		var option:Option = new Option('Check for Updates',
			'On Release builds, turn this on to check for updates when you start the game.',
			'checkForUpdates',
			BOOL);
		addOption(option);
		#end

		var option:Option = new Option('Vocal Resync Indicator',
			"If checked, it'll enable an indicator for syncing of the song vocals. Don't know why you'd need it, but it's there.",
			'vocalResyncIndicator',
			BOOL);
		addOption(option);

		var option:Option = new Option('idk what to put here uhhh',
			'this toggles downscroll ill work on this menu later',
			'downScroll',
			BOOL);
		addOption(option);

		super();
	}
	
	#if !mobile
	function onChangeCounter()
	{
		if(Main.fpsVar != null) {
			Main.fpsVar.showFPS = ClientPrefs.data.showFPS;
			Main.fpsVar.showMem = ClientPrefs.data.showMem;
			Main.fpsVar.showMemPeak = ClientPrefs.data.showMemPeak;
			Main.fpsVar.showBuild = ClientPrefs.data.showBuild;
		}
	}
	#end
	
	#if CHECK_FOR_UPDATES
	function onPressUpdates()
	{
	}
	#end
}