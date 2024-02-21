package meta.data;

import flixel.system.FlxAssets.FlxShader;
import flixel.math.FlxPoint;
import flixel.FlxG;
import openfl.utils.Assets;
import lime.utils.Assets as LimeAssets;
import lime.utils.AssetLibrary;
import lime.utils.AssetManifest;
import flixel.system.FlxSound;
import meta.states.*;
#if sys
import sys.io.File;
import sys.FileSystem;
#else
import openfl.utils.Assets;
#end
import math.*;
import modchart.*;

using StringTools;

class CoolUtil
{
	inline public static function scale(x:Float, l1:Float, h1:Float, l2:Float, h2:Float):Float
		return ((x - l1) * (h2 - l2) / (h1 - l1) + l2);
	inline public static function clamp(n:Float, l:Float, h:Float)
	{ //isnt this just bound?
		if (n > h)
			n = h;
		if (n < l)
			n = l;
		return n;
	}

	public static function rotate(x:Float, y:Float, angle:Float, ?point:FlxPoint):FlxPoint
	{
		var p = point == null ? FlxPoint.weak() : point;
		p.set((x * Math.cos(angle)) - (y * Math.sin(angle)), (x * Math.sin(angle)) + (y * Math.cos(angle)));
		return p;
	}


	public static var defaultDifficulties:Array<String> = [
		'Easy',
		'Normal',
		'Hard'
	];
	public static var defaultDifficulty:String = 'Normal'; //The chart that has no suffix and starting difficulty on Freeplay/Story Mode

	public static var difficulties:Array<String> = [];
	
	inline public static function quantizeAlpha(f:Float, interval:Float){
		return Std.int((f+interval/2)/interval)*interval;
	}
	
	inline public static function quantize(f:Float, interval:Float){
		return Std.int((f+interval/2)/interval)*interval;
	}
	
	public static function getDifficultyFilePath(num:Null<Int> = null)
	{
		if(num == null) num = PlayState.storyDifficulty;

		var fileSuffix:String = difficulties[num];
		if(fileSuffix != defaultDifficulty)
		{
			fileSuffix = '-' + fileSuffix;
		}
		else
		{
			fileSuffix = '';
		}
		return Paths.formatToSongPath(fileSuffix);
	}

	public static function difficultyString():String
	{
		return difficulties[PlayState.storyDifficulty].toUpperCase();
	}

	public static function coolTextFile(path:String):Array<String>
	{
		var daList:Array<String> = [];
		#if sys
		if(FileSystem.exists(path)) daList = File.getContent(path).trim().split('\n');
		#else
		if(Assets.exists(path)) daList = Assets.getText(path).trim().split('\n');
		#end

		for (i in 0...daList.length)
		{
			daList[i] = daList[i].trim();
		}

		return daList;
	}
	public static function listFromString(string:String):Array<String>
	{
		var daList:Array<String> = [];
		daList = string.trim().split('\n');

		for (i in 0...daList.length)
		{
			daList[i] = daList[i].trim();
		}

		return daList;
	}
	public static function dominantColor(sprite:flixel.FlxSprite):Int{
		var countByColor:Map<Int, Int> = [];
		for(col in 0...sprite.frameWidth){
			for(row in 0...sprite.frameHeight){
			  var colorOfThisPixel:Int = sprite.pixels.getPixel32(col, row);
			  if(colorOfThisPixel != 0){
				  if(countByColor.exists(colorOfThisPixel)){
				    countByColor[colorOfThisPixel] =  countByColor[colorOfThisPixel] + 1;
				  }else if(countByColor[colorOfThisPixel] != 13520687 - (2*13520687)){
					 countByColor[colorOfThisPixel] = 1;
				  }
			  }
			}
		 }
		var maxCount = 0;
		var maxKey:Int = 0;//after the loop this will store the max color
		countByColor[flixel.util.FlxColor.BLACK] = 0;
			for(key in countByColor.keys()){
			if(countByColor[key] >= maxCount){
				maxCount = countByColor[key];
				maxKey = key;
			}
		}
		return maxKey;
	}

	public static function numberArray(max:Int, ?min = 0):Array<Int>
	{
		var dumbArray:Array<Int> = [];
		for (i in min...max)
		{
			dumbArray.push(i);
		}
		return dumbArray;
	}

	//uhhhh does this even work at all? i'm starting to doubt
	public static function precacheSound(sound:String, ?library:String = null):Void {
		Paths.sound(sound, library);
	}

	public static function precacheMusic(sound:String, ?library:String = null):Void {
		Paths.music(sound, library);
	}

	public static function browserLoad(site:String) {
		#if linux
		Sys.command('/usr/bin/xdg-open', [site]);
		#else
		FlxG.openURL(site);
		#end
	}

	//hate that im using dynamic but blablabla shader effects garbade
	public static function addShaderToCamera(shader:Dynamic,?camera:flixel.FlxCamera) 
	{
		var shad:openfl.filters.ShaderFilter = null;
		if (shader is FlxShader) shad = new openfl.filters.ShaderFilter(shader);
		else {
			//this sucks shader effects are genuinely a stupid setup stop using them
			var shaderToApply:gameObjects.shader.Shaders.ShaderEffect = shader;
			shad = new openfl.filters.ShaderFilter(shaderToApply.shader);
		}
		if (camera == null) camera = FlxG.cameras.list[0];
		@:privateAccess {
			if (camera._filters == null) camera._filters = [];
			camera._filters.push(shad);
		}
	}

	public static function removeShaderFromCamera(shader:Dynamic,?camera:flixel.FlxCamera) 
	{

		var shaderToRemove:Dynamic = shader;
		if (!(shader is FlxShader)) shaderToRemove = shaderToRemove.shader;
		if (camera == null) camera = FlxG.cameras.list[0];
		@:privateAccess {
			if (camera._filters == null) return;
			for (i in camera._filters) {
				if (i is openfl.filters.ShaderFilter) {
					var filter = cast(i,openfl.filters.ShaderFilter);
					if (filter.shader == shaderToRemove) camera._filters.remove(i); break;
					
				}
			}
		}
	}

	public static function clearShadersFromCamera(?camera:flixel.FlxCamera) {
		if (camera == null) camera = FlxG.cameras.list[0];
		@:privateAccess {
			if (camera._filters == null) return;
			while (camera._filters.length > 0) camera._filters.pop();
		}
	}

	public static function betterLerp(value:Float,desiredValue:Float,ratio:Float) {
		return FlxMath.lerp(value,desiredValue,FlxMath.bound(ratio * 60 * FlxG.elapsed, 0, 1));
	}
	
}
