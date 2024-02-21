package meta.data;

import flixel.FlxG;
import flixel.util.FlxSave;
import flixel.util.FlxColor;
import flixel.input.keyboard.FlxKey;
import flixel.graphics.FlxGraphic;
import meta.data.*;
import meta.states.*;
import meta.data.Controls.KeyboardScheme;

@:structInit class SaveVars {

	//editor colors
	public var editorUIColor:FlxColor = FlxColor.fromRGB(102, 163, 255);
	public var editorGradColors:Array<FlxColor> = [FlxColor.fromRGB(83, 21, 78), FlxColor.fromRGB(21, 62, 83)];
	public var editorBoxColors:Array<FlxColor> = [FlxColor.fromRGB(58, 112, 159), FlxColor.fromRGB(138, 173, 202)];
	public var editorGradVis:Bool = true;
	public var chartPresetList:Array<String> = ["Default"];
	public var chartPresets:Map<String, Array<Dynamic>> = [ //i dont think this needs to be dynamic but sure ig
		"Default" => [[FlxColor.fromRGB(0,0,0), FlxColor.fromRGB(0,0,0)], false, [FlxColor.fromRGB(255,255,255), FlxColor.fromRGB(210, 210, 210)], FlxColor.fromRGB(250,250,250)]
	];

	//graphics
	public var lowQuality:Bool = false;
	public var framerate:Int = 120;
	public var antialiasing:Bool = true;

	//loading
	public var cacheOnGPU:Bool = false;
	public var multicoreLoading:Bool = false;
	public var loadingThreads:Int = Math.floor(Std.parseInt(Sys.getEnv("NUMBER_OF_PROCESSORS"))/2);


	//visuals and ui
	public var timeBarType:String = 'Time Left';
	public var flashing:Bool = true;
	public var camZooms:Bool = true;
	public var hideHud:Bool = false;
	public var noteSplashes:Bool = true;
	public var pauseMusic:String = 'Tea Time';
	public var showFPS:Bool = true;
	public var healthBarAlpha:Float = 1;
	public var camMovement:Bool = true;

	//gameplay
	public var controllerMode:Bool = false;
	public var downScroll:Bool = false;
	public var middleScroll:Bool = false;
	public var opponentStrums:Bool = true;
	public var ghostTapping:Bool = true;
	public var noReset:Bool = false;
	public var hitsoundVolume:Float = 0;
	public var ratingOffset:Int = 0;
	public var epicWindow:Int = 22;
	public var sickWindow:Int = 45;
	public var goodWindow:Int = 90;
	public var badWindow:Int = 135;
	public var safeFrames:Float = 10;
	public var comboOffset:Array<Int> = [0, 0, 0, 0];
	public var gameplaySettings:Map<String, Dynamic> = [
		'scrollspeed' => 1.0,
		'scrolltype' => 'multiplicative',
		// anyone reading this, amod is multiplicative speed mod, cmod is constant speed mod, and xmod is bpm based speed mod.
		// an amod example would be chartSpeed * multiplier
		// cmod would just be constantSpeed = chartSpeed
		// and xmod basically works by basing the speed on the bpm.
		// iirc (beatsPerSecond * (conductorToNoteDifference / 1000)) * noteSize (110 or something like that depending on it, prolly just use note.height)
		// bps is calculated by bpm / 60
		// oh yeah and you'd have to actually convert the difference to seconds which I already do, because this is based on beats and stuff. but it should work
		// just fine. but I wont implement it because I don't know how you handle sustains and other stuff like that.
		// oh yeah when you calculate the bps divide it by the songSpeed or rate because it wont scroll correctly when speeds exist.
		'songspeed' => 1.0,
		'healthgain' => 1.0,
		'healthloss' => 1.0,
		'instakill' => false,
		'practice' => false,
		'botplay' => false,
		'opponentplay' => false
	];


	//note shit
	public var noteOffset:Int = 0;
	public var noteSkin:String = 'Vanilla';
	public var arrowHSV:Array<Array<Int>> = [[0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0]];
	public var quantHSV:Array<Array<Int>> = [
		[0, -20, 0], // 4th
		[-130, -20, 0], // 8th
		[-80, -20, 0], // 12th
		[128, -30, 0], // 16th
		[-120, -70, -35], // 20th
		[-80, -20, 0], // 24th
		[50, -20, 0], // 32nd
		[-80, -20, 0], // 48th
		[160, -15, 0], // 64th
		[-120, -70, -35], // 96th
		[-120, -70, -35]// 192nd
	];
	public var quantStepmania:Array<Array<Int>> = [
		[10, -20, 0], // 4th
		[-110, -40, 0], // 8th
		[140, -20, 0], // 12th
		[50, 25, 0], // 16th
		[0, -100, -50], // 20th
		[-80, -40, 0], // 24th
		[-180, 10, -10], // 32nd
		[-35, 50, 30], // 48th
		[160, -15, 0], // 64th
		[-120, -70, -35], // 96th
		[-120, -70, -35]// 192nd
	];


	//temp this is temp i repeat this is temp
	public var swapNoteOption:Bool = false;
	
}

class ClientPrefs {
	public static var data:SaveVars = {};
	public static var defaultData:SaveVars = {};

	//Every key has two binds, add your key bind down here and then add your control on options/ControlsSubState.hx and Controls.hx
	public static var keyBinds:Map<String, Array<FlxKey>> = [
		//Key Bind, Name for ControlsSubState
		'note_left'		=> [A, LEFT],
		'note_down'		=> [S, DOWN],
		'note_up'		=> [W, UP],
		'note_right'	=> [D, RIGHT],
		'dodge' => [SPACE],

		'ui_left'		=> [A, LEFT],
		'ui_down'		=> [S, DOWN],
		'ui_up'			=> [W, UP],
		'ui_right'		=> [D, RIGHT],

		'accept'		=> [SPACE, ENTER],
		'back'			=> [BACKSPACE, ESCAPE],
		'pause'			=> [ENTER, ESCAPE],
		'reset'			=> [R, NONE],

		'volume_mute'	=> [ZERO, NONE],
		'volume_up'		=> [NUMPADPLUS, PLUS],
		'volume_down'	=> [NUMPADMINUS, MINUS],

		'debug_1'		=> [SEVEN, NONE],
		'debug_2'		=> [EIGHT, NONE]
	];

	public static var defaultKeys:Map<String, Array<FlxKey>> = null;

	public static function loadDefaultKeys() {
		defaultKeys = keyBinds.copy();
		//trace(defaultKeys);
	}

	public static function saveSettings() {
		for (key in Reflect.fields(data))
			Reflect.setField(FlxG.save.data, key, Reflect.field(data, key));

		
		FlxG.save.data.achievementsMap = Achievements.achievementsMap;
		FlxG.save.data.henchmenDeath = Achievements.henchmenDeath;

		FlxG.save.flush();

		var save:FlxSave = new FlxSave();
		save.bind('controls_v2', 'ninjamuffin99'); //Placing this in a separate save so that it can be manually deleted without removing your Score and stuff
		save.data.customControls = keyBinds;
		save.flush();
		FlxG.log.add("Settings saved!");
	}

	public static function loadPrefs() {
		var excludedKeys = ['gameplaySettings','chartPreset'];

		for (key in Reflect.fields(data))
			if (!excludedKeys.contains(key) && Reflect.hasField(FlxG.save.data, key))
				Reflect.setField(data, key, Reflect.field(FlxG.save.data, key));


		if(Main.fpsVar != null) Main.fpsVar.visible = data.showFPS;

		#if (!html5 && !switch)
		if(FlxG.save.data.framerate == null) {
			final refreshRate:Int = FlxG.stage.application.window.displayMode.refreshRate;
			data.framerate = Std.int(FlxMath.bound(refreshRate, 60, 240));
		}
		#end

		if(data.framerate > FlxG.drawFramerate) {
			FlxG.updateFramerate = data.framerate;
			FlxG.drawFramerate = data.framerate;
		}
		else {
			FlxG.drawFramerate = data.framerate;
			FlxG.updateFramerate = data.framerate;
		}

		if(FlxG.save.data.loadingThreads != null) {
			data.loadingThreads = FlxG.save.data.loadingThreads;
			if(data.loadingThreads > Math.floor(Std.parseInt(Sys.getEnv("NUMBER_OF_PROCESSORS")))){
				data.loadingThreads = Math.floor(Std.parseInt(Sys.getEnv("NUMBER_OF_PROCESSORS")));
				FlxG.save.data.loadingThreads = data.loadingThreads;
			}
		}

		if(FlxG.save.data.chartPreset != null)
		{
			var savedMap:Map<String, Dynamic> = FlxG.save.data.chartPresets;
			for (name => value in savedMap)
			{
				data.chartPresets.set(name, value);
			}
		}

		if(FlxG.save.data.gameplaySettings != null)
		{
			var savedMap:Map<String, Dynamic> = FlxG.save.data.gameplaySettings;
			for (name => value in savedMap)
			{
				data.gameplaySettings.set(name, value);
			}
		}

		// flixel automatically saves your volume!
		if(FlxG.save.data.volume != null)
		{
			FlxG.sound.volume = FlxG.save.data.volume;
		}
		if (FlxG.save.data.mute != null)
		{
			FlxG.sound.muted = FlxG.save.data.mute;
		}

		var save:FlxSave = new FlxSave();
		save.bind('controls_v2', 'ninjamuffin99');
		if(save != null && save.data.customControls != null) {
			var loadedControls:Map<String, Array<FlxKey>> = save.data.customControls;
			for (control => keys in loadedControls) {
				keyBinds.set(control, keys);
			}
			reloadControls();
		}
	}

	inline public static function getGameplaySetting(name:String, defaultValue:Dynamic):Dynamic {
		return /*PlayState.isStoryMode ? defaultValue : */ (data.gameplaySettings.exists(name) ? data.gameplaySettings.get(name) : defaultValue);
	}

	public static function reloadControls() {
		PlayerSettings.player1.controls.setKeyboardScheme(KeyboardScheme.Solo);

		InitState.muteKeys = copyKey(keyBinds.get('volume_mute'));
		InitState.volumeDownKeys = copyKey(keyBinds.get('volume_down'));
		InitState.volumeUpKeys = copyKey(keyBinds.get('volume_up'));
		FlxG.sound.muteKeys = InitState.muteKeys;
		FlxG.sound.volumeDownKeys = InitState.volumeDownKeys;
		FlxG.sound.volumeUpKeys = InitState.volumeUpKeys;
	}
	public static function copyKey(arrayToCopy:Array<FlxKey>):Array<FlxKey> {
		var copiedArray:Array<FlxKey> = arrayToCopy.copy();
		var i:Int = 0;
		var len:Int = copiedArray.length;

		while (i < len) {
			if(copiedArray[i] == NONE) {
				copiedArray.remove(NONE);
				--i;
			}
			i++;
			len = copiedArray.length;
		}
		return copiedArray;
	}
}
