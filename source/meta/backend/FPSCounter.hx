package meta.backend;

import meta.data.*;
import haxe.Timer;
import openfl.events.Event;
import openfl.text.TextField;
import openfl.text.TextFormat;
import flixel.math.FlxMath;
#if flash
import openfl.Lib;
#end

#if openfl
import openfl.system.System;
#end

class FPSCounter extends TextField
{
	/**
		The current frame rate, expressed using frames-per-second
	**/
	public var currentFPS(default, null):Int;

	@:noCompletion private var times:Array<Float>;

	public var memoryMegas(get, never):Float;
	var deltaTimeout:Float = 0.0;

	public function new(x:Float = 10, y:Float = 10, color:Int = 0x000000)
	{
		super();

		this.x = x;
		this.y = y;

		currentFPS = 0;
		selectable = false;
		mouseEnabled = false;
		defaultTextFormat = new TextFormat("_sans", 14, color);
		autoSize = LEFT;
		multiline = true;
		text = "FPS: ";

		times = [];

	}

	// Event Handlers
	private override  function __enterFrame(deltaTime:Float):Void
	{
		if (deltaTimeout > 1000) {
			deltaTimeout = 0.0;
			return;
		}

		var now:Float = haxe.Timer.stamp() * 1000;
		times.push(now);
		while (times[0] < now - 1000) times.shift();

		currentFPS = times.length < FlxG.updateFramerate ? times.length : FlxG.updateFramerate;		

		text = 'FPS: $currentFPS \nMemory: ${flixel.util.FlxStringUtil.formatBytes(memoryMegas)}';	
		textColor = 0xFFFFFFFF;
		if (currentFPS <= FlxG.drawFramerate / 2) textColor = 0xFFFF0000;
		
		deltaTimeout += deltaTime;

	}

	inline function get_memoryMegas():Float { //more accurate
		#if cpp 
		return cpp.vm.Gc.memInfo64(cpp.vm.Gc.MEM_INFO_USAGE);
		#else
		return cast(System.totalMemory, UInt);
		#end
	}
}
