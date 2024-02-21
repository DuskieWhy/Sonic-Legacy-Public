package meta.backend;

import haxe.crypto.Base64;
import openfl.media.Sound;
import openfl.utils.ByteArray;
import lime.graphics.Image;
import lime.utils.Assets;
import openfl.display.Bitmap;
import openfl.Lib;
import lime.app.Application;
import meta.states.MusicBeatState;
import flixel.FlxG;
import openfl.display.BitmapData;
import meta.states.substate.transitions.SwipeTransitionSubstate;
import meta.states.substate.transitions.FadeTransition;
import flixel.addons.transition.FlxTransitionableState;
import meta.states.desktop.*;

@:bitmap("projFiles/icon/evil/iconEXE.png") class EvilIcon extends BitmapData {}
class ProgressionHandler
{

	
	public static var songsUnlocked:Array<String> = [];
	
	@:isVar
	public static var isRodent(default,set):Bool = true;
	static function set_isRodent(value:Bool):Bool {
		if (isRodent == value) return isRodent;
		isRodent = value;
		FlxG.save.data.currentlyRodent = isRodent;
		FlxG.save.flush();

		var title = isRodent ? "Friday Night Funkin': Rodentrap" : "Sonic Legacy";
		if (FlxG.random.bool(0.7) && !isRodent) title = 'SonicEpicEdition (SEE)';
		lime.app.Application.current.window.title = title;


		if (value) {
			var icon = Image.fromBase64(Base64Data.rodentIcon,'image/png');
			Lib.current.stage.window.setIcon(icon);

			FlxTransitionableState.defaultTransIn = SwipeTransitionSubstate;
			FlxTransitionableState.defaultTransOut = SwipeTransitionSubstate;

			FlxG.sound.soundTray.volumeDownSound = 'flixel/sounds/beep';
			FlxG.sound.soundTray.volumeUpSound = 'flixel/sounds/beep';
		}
		else {
			var icon = lime.graphics.Image.fromBitmapData(new EvilIcon(0,0));
			Lib.current.stage.window.setIcon(icon);

			FlxTransitionableState.defaultTransIn = FadeTransition;
			FlxTransitionableState.defaultTransOut = FadeTransition;

			FlxG.sound.soundTray.volumeDownSound = 'assets/sounds/SEL_volume';
			FlxG.sound.soundTray.volumeUpSound = 'assets/sounds/SEL_volume';
		}

		trace('curRodentMode: ' + FlxG.save.data.currentlyRodent);

		return value;
	}
	
	public static function unlockSong(song:String):Void
	{
		if (!songsUnlocked.contains(song))
		{
			songsUnlocked.push(song);
			FlxG.save.data.songsUnlocked = songsUnlocked;
			FlxG.save.flush();
		}
	}

	public static function isSongUnlocked(songToCheck:String):Bool
	{
		if (songsUnlocked.contains(songToCheck))
			{
				return true;
			}
		else return false;
	}

	public static function destroyData():Void
	{
		songsUnlocked = [];
		FlxG.save.data.songsUnlocked = songsUnlocked;
		isRodent = true;

		FlxG.save.flush();
	}

	public static function load():Void
	{
		if (FlxG.save.data.songsUnlocked != null) songsUnlocked = FlxG.save.data.songsUnlocked;
		if (FlxG.save.data.currentlyRodent != null) isRodent = FlxG.save.data.currentlyRodent;
	}


	//------- Handy functions to make adjusting rodent fakeout more convenient -------//
	public static function getMenuMusic() 
	{
		var prefix = isRodent ? '-rodent' : '-desk';
		return Paths.music('freakyMenu' + prefix);
	}

	public static function loadMainMenuState() {
		if (isRodent) MusicBeatState.switchState(new meta.states.MainMenuState());
		else MusicBeatState.switchState(new DesktopMenuState());
	}


}