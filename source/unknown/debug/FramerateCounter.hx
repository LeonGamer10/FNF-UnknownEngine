package debug;

import flixel.FlxG;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.system.System;
import macros.GitCommitMacro;

/**
	The FPS class provides an easy-to-use monitor to display
	the current frame rate of an OpenFL project
**/
class FramerateCounter extends TextField
{
	/**
		The current frame rate, expressed using frames-per-second
	**/
	public static var currentFPS(default, null):Int;
	
	/**
		The current memory usage (WARNING: this is NOT your total program memory usage, rather it shows the garbage collector memory)
	**/
	public var memoryMegas(get, never):Float;
	
	/**
		The current memory peak
	**/
	private var memPeak:Float;
	
	public var showFPS:Bool = true;
	public var showMem:Bool = false;
	public var showMemPeak:Bool = false;
	public var showBuild:Bool = false;
	
	public static var fontName:String = "_sans";

	@:noCompletion private var times:Array<Float>;

	public function new(x:Float = 10, y:Float = 10, color:Int = 0x000000)
	{
		super();

		this.x = x;
		this.y = y;

		currentFPS = 0;
		selectable = false;
		mouseEnabled = false;
		defaultTextFormat = new TextFormat(fontName, 12, color);
		autoSize = LEFT;
		multiline = true;
		text = "FPS: ";

		times = [];
		
		showFPS = ClientPrefs.data.showFPS;
		showMem = ClientPrefs.data.showMem;
		showMemPeak = ClientPrefs.data.showMemPeak;
		showBuild = ClientPrefs.data.showBuild;
	}

	var deltaTimeout:Float = 0.0;

	// Event Handlers
	private override function __enterFrame(deltaTime:Float):Void
	{
		// prevents the overlay from updating every frame, why would you need to anyways
		if (deltaTimeout > 1000) {
			deltaTimeout = 0.0;
			return;
		}

		final now:Float = haxe.Timer.stamp();
		times.push(now);
		while (times[0] < now - 1000) times.shift();

		currentFPS = times.length < FlxG.drawFramerate ? times.length : FlxG.drawFramerate;		
		updateText();
		deltaTimeout += deltaTime;
	}

	public dynamic function updateText():Void { // so people can override it in hscript
		if (memoryMegas > memPeak) memPeak = memoryMegas;
		text = (showFPS ? 'FPS: ${currentFPS}' : "")
			+ (showMem ? '\nRAM: ${flixel.util.FlxStringUtil.formatBytes(memoryMegas)}' : "")
			+ (showMemPeak ? '\nRAM Peak: ${flixel.util.FlxStringUtil.formatBytes(memPeak)}' : "")
			+ (showBuild ? '\nUnknown Engine Alpha - Build ${GitCommitMacro.commitNumber} (${GitCommitMacro.commitHash})' : "");

		textColor = 0xFFFFFFFF;
		if (ClientPrefs.data.colorblindMode == "Invert")
			textColor = 0xFF000000;
		if (currentFPS < FlxG.drawFramerate * 0.5)
			textColor = 0xFFFF0000;
	}
	inline function get_memoryMegas():Float
		return cast(System.totalMemory, UInt);
}