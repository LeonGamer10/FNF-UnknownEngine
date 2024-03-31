package substates;

import flixel.FlxObject;

import states.StoryMenuState;
import states.FreeplayState;
import states.editors.ChartingState;

import backend.WeekData;
import backend.Highscore;
import backend.Song;

import objects.Note;

class ChartSubstate extends MusicBeatSubstate
{
    var menuItems:FlxTypedGroup<FlxSprite>;
    var optionShit:Array<String> = ['standard', 'flip', 'chaos'];
    var selectedSomethin:Bool = false;
    public static var curSelected:Int = 0;
    var camFollow:FlxObject;

    var boombox:FlxSprite = new FlxSprite(0,0).loadGraphic(Paths.image('Boombox'));
    var chartTypeBG:FlxSprite;
	
	public static var flip:Bool = false;
	public static var chaos:Bool = false;

    public function new()
    {
        super();
		
		chartTypeBG = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		chartTypeBG.alpha = 0;
		add(chartTypeBG);
		chartTypeBG.scrollFactor.set();

        FlxTween.tween(chartTypeBG, {alpha: 0.5}, 0.5, {ease: FlxEase.quartInOut});

        menuItems = new FlxTypedGroup<FlxSprite>();
        add(menuItems);
        
		var tex = Paths.getSparrowAtlas('chartTypes');

		for (i in 0...optionShit.length)
		{
			var menuItem:FlxSprite = new FlxSprite(-250, 30);
			menuItem.frames = tex;
            menuItem.animation.addByPrefix('idle', optionShit[i] + " idle", 24, true);
            menuItem.animation.addByPrefix('select', optionShit[i] + " select", 24, true);
			menuItem.animation.play('idle');
			menuItem.ID = i;
			menuItems.add(menuItem);
            menuItem.y = 720 + i * menuItem.height;
			menuItem.scrollFactor.set();
            menuItem.antialiasing = true;
            menuItem.scrollFactor.x = 0;
            menuItem.scrollFactor.y = 1;

            menuItem.x = 2000;
            FlxTween.tween(menuItem, { x: 800}, 0.15, { ease: FlxEase.expoInOut });
        }

        camFollow = new FlxObject(0, 0, 1, 1);
		add(camFollow);

        new FlxTimer().start(0.1, function(tmr:FlxTimer)
			{
				selectable = true;
                FlxG.camera.follow(camFollow, null, 7.5);
			});
    }

    var selectable:Bool = false;

    override function update(elapsed:Float)
    {
        super.update(elapsed);

        boombox.screenCenter();

        if (selectable && !selectedSomethin)
        {
            if (controls.UI_UP_P)
            {
                FlxG.sound.play(Paths.sound('scrollMenu'));
                changeItem(-1);
            }
    
            if (controls.UI_DOWN_P)
            {
                FlxG.sound.play(Paths.sound('scrollMenu'));
                changeItem(1);
            }

            if (controls.BACK)
            {
                FlxG.resetState();
                selectedSomethin = true;
            }
        
            if (controls.ACCEPT)
            {
                selectedSomethin = true;
				
				#if !SHOW_LOADING_SCREEN FlxG.sound.playMusic(Paths.music("titleShoot")); #end
				
				FlxTween.tween(chartTypeBG, {alpha: 1}, 1.3, {ease: FlxEase.quartInOut});

                if (optionShit[curSelected] == 'flip')
				{
					flip = true;
					chaos = false;
				}
				else if (optionShit[curSelected] == 'chaos')
				{
					flip = false;
					chaos = true;
				}
				else
				{
					flip = false;
					chaos = false;
				}
				
                FlxG.sound.play(Paths.sound('confirmMenu'));

                #if sys
				DiscordClient.changePresence("Time to play!", null);
                #end

				#if !SHOW_LOADING_SCREEN 
				FlxG.sound.music.fadeOut(2.1, 0);
				#else 
				FlxG.sound.music.fadeOut(2.1, 0.3); 
				#end

                FlxTween.tween(FlxG.camera, { zoom:1.4}, 1.3, { ease: FlxEase.quartInOut});
                FlxTween.tween(camFollow, { y:5000}, 1.3, { ease: FlxEase.quartInOut});

				boombox.antialiasing = ClientPrefs.data.antialiasing;
                add(boombox);
			    boombox.scale.set(0,0);
                boombox.scrollFactor.set();
			    boombox.alpha = 0;

				FlxTween.tween(boombox, { alpha:1, 'scale.x':0.5, 'scale.y':0.5}, 1.3, { ease: FlxEase.quartInOut});

			    new FlxTimer().start(2.1, function(tmr:FlxTimer)
				{
					boombox.visible = false;
					chartTypeBG.visible = false;
					FreeplayState.bg.visible = false;
					
					LoadingState.prepareToSong();
					
					LoadingState.loadAndSwitchState(new PlayState());
					
					#if !SHOW_LOADING_SCREEN FlxG.sound.music.stop(); #end
					FreeplayState.stopMusicPlay = true;
				});
            }
        }

        menuItems.forEach(function(spr:FlxSprite)
            {
                if (spr.ID == curSelected && !selectedSomethin && selectable)
                {
                    camFollow.y = FlxMath.lerp(camFollow.y, spr.getGraphicMidpoint().y, 0.32/(ClientPrefs.data.framerate/60));
                    camFollow.x = 0;
                    spr.x = FlxMath.lerp(spr.x, -1300, 0.32/(ClientPrefs.data.framerate/60));
                }

                spr.x = FlxMath.lerp(spr.x, 600, 0.32/(ClientPrefs.data.framerate/60));
            });
    }

    function changeItem(huh:Int = 0)
        {
            curSelected += huh;
        
            if (curSelected >= menuItems.length)
                curSelected = 0;
            if (curSelected < 0)
                curSelected = menuItems.length - 1;

            menuItems.forEach(function(spr:FlxSprite)
                {
                    spr.animation.play('idle');
        
                    if (spr.ID == curSelected)
                    {
                        spr.animation.play('select'); 
                    }
            
                    spr.updateHitbox();
                });
        }
}