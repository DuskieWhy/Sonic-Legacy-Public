package meta.states; 

import flixel.graphics.frames.FlxBitmapFont;
import flixel.text.FlxBitmapText;
import flixel.FlxGame;
import flixel.FlxObject;
import flixel.FlxSubState;
import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxRect;
import flixel.ui.FlxBar;
import flixel.util.FlxSort;
import flixel.util.FlxStringUtil;
import flixel.group.FlxSpriteGroup;
import flixel.input.keyboard.FlxKey;
import flixel.util.FlxSave;
import haxe.Json;
import openfl.Lib;
import openfl.display.BlendMode;
import openfl.events.KeyboardEvent;
import lime.utils.Assets;
import openfl.utils.Assets as OpenFlAssets;
import meta.data.Section.SwagSection;
import meta.data.Song.SwagSong;
import meta.data.Song;
import meta.data.scripts.FunkinLua;
import meta.data.scripts.FunkinLua.ModchartSprite;
import meta.data.Achievements;
import meta.data.StageData.StageFile;
import meta.data.Achievements.AchievementObject;
import meta.data.WeekData;
import gameObjects.Note.EventNote;
import gameObjects.DialogueBoxPsych;
import gameObjects.shader.GlitchShader.Fuck;
import gameObjects.shader.GlitchShader.GlitchShaderB;
import gameObjects.shader.GlitchShader.GlitchShaderA;
import flixel.system.FlxAssets.FlxShader;
import openfl.filters.ShaderFilter;
import openfl.display.Shader;
import gameObjects.shader.*;
import gameObjects.*;
import meta.states.*;
import meta.states.substate.*;
import meta.states.editors.*;
import modchart.*;
import meta.data.scripts.*;
import math.*;

import sys.thread.Thread;


#if sys
import sys.FileSystem;
#end
typedef PreloadResult = {
	var thread:Thread;
	var asset:String;
	@:optional var terminated:Bool;
}

typedef AssetPreload = {
	var path:String;
	@:optional var type:String;
	@:optional var library:String;
	@:optional var terminate:Bool;
}

class PlayState extends MusicBeatState
{
	public var modManager:ModManager;

	var noteRows:Array<Array<Array<Note>>> = [[],[]];
	
	public var whosTurn:String = '';
	public static var STRUM_X = 42;
	public static var STRUM_X_MIDDLESCROLL = -278;
	public static var arrowSkin:String = '';
	public static var arrowSkins:Array<String> = [];
	public static var ratingStuff:Array<Dynamic> = [
		['You Suck!', 0.2], //From 0% to 19%
		['Shit', 0.4], //From 20% to 39%
		['Bad', 0.5], //From 40% to 49%
		['Bruh', 0.6], //From 50% to 59%
		['Meh', 0.69], //From 60% to 68%
		['Nice', 0.7], //69%
		['Good', 0.8], //From 70% to 79%
		['Great', 0.9], //From 80% to 89%
		['Sick!', 1], //From 90% to 99%
		['Perfect!!', 1] //The value on this one isn't used actually, since Perfect is always "1"
	];
	public var modchartTweens:Map<String, FlxTween> = new Map<String, FlxTween>();
	public var modchartSprites:Map<String, ModchartSprite> = new Map<String, ModchartSprite>();
	public var modchartTimers:Map<String, FlxTimer> = new Map<String, FlxTimer>();
	public var modchartSounds:Map<String, FlxSound> = new Map<String, FlxSound>();
	public var modchartTexts:Map<String, ModchartText> = new Map<String, ModchartText>();
	public var modchartSaves:Map<String, FlxSave> = new Map<String, FlxSave>();
	public var modchartObjects:Map<String, FlxSprite> = new Map<String, FlxSprite>();

	//event variables
	#if (haxe >= "4.0.0")
	public var hscriptGlobals:Map<String, Dynamic> = new Map();
	#else
	public var hscriptGlobals:Map<String, Dynamic> = new Map<String, Dynamic>();
	#end

	private var isCameraOnForcedPos:Bool = false;
	#if (haxe >= "4.0.0")
	public var boyfriendMap:Map<String, Boyfriend> = new Map();
	public var extraMap:Map<String, Character> = new Map();
	public var dadMap:Map<String, Character> = new Map();
	public var gfMap:Map<String, Character> = new Map();
	#else
	public var boyfriendMap:Map<String, Boyfriend> = new Map<String, Boyfriend>();
	public var dadMap:Map<String, Character> = new Map<String, Character>();
	public var gfMap:Map<String, Character> = new Map<String, Character>();
	public var extraMap:Map<String, Character> = new Map<String, Character>();
	#end

	public var variables:Map<String, Dynamic> = new Map();

	public var BF_X:Float = 770;
	public var BF_Y:Float = 100;
	public var DAD_X:Float = 100;
	public var DAD_Y:Float = 100;
	public var GF_X:Float = 400;
	public var GF_Y:Float = 130;

	public var songSpeedTween:FlxTween;
	public var songSpeed(default, set):Float = 1;
	public var songSpeedType:String = "multiplicative";
	public var noteKillOffset:Float = 350;

	public var boyfriendGroup:FlxSpriteGroup;
	public var dadGroup:FlxSpriteGroup;
	public var gfGroup:FlxSpriteGroup;
	public static var curStage:String = '';
	public var stage:Stage;
	public static var isPixelStage:Bool = false;
	public static var SONG:SwagSong = null;
	public static var isStoryMode:Bool = false;
	public static var storyWeek:Int = 0;
	public static var storyPlaylist:Array<String> = [];
	public static var storyDifficulty:Int = 1;

	public var spawnTime:Float = 3000;

	public var vocals:FlxSound;

	public var dad:Character = null;
	public var gf:Character = null;
	public var boyfriend:Boyfriend = null;

	public var notes:FlxTypedGroup<Note>;
	public var unspawnNotes:Array<Note> = [];
	public var eventNotes:Array<EventNote> = [];

	private var strumLine:FlxSprite;

	//Handles the new epic mega sexy cam code that i've done
	private var camFollow:FlxPoint;
	private var camFollowPos:FlxObject;
	private static var prevCamFollow:FlxPoint;
	private static var prevCamFollowPos:FlxObject;

	public var playFields:FlxTypedGroup<PlayField>;
	@:isVar
	public var strumLineNotes(get, null):Array<StrumNote>;
	function get_strumLineNotes(){
		var notes:Array<StrumNote> = [];
		if(playFields!=null && playFields.length>0){
			for(field in playFields.members){
				for(sturm in field.members)
					notes.push(sturm);
				
			}
		}
		return notes;
	}
	public var opponentStrums:PlayField;
	public var playerStrums:PlayField;

	public var grpNoteSplashes:FlxTypedGroup<NoteSplash>;

	public var camZooming:Bool = false;
	public var camZoomingMult:Float = 1;
	public var camZoomingDecay:Float = 1;
	private var curSong:String = "";

	public var gfSpeed:Int = 1;
	public var health:Float = 1;
	public var displayedHealth:Float = 1;
	public var combo:Int = 0;

	public var healthBar:FlxBar;
	var songPercent:Float = 0;

	public var timeBarBG:AttachedSprite;
	public var timeBar:FlxBar;

	public var ratingsData:Array<Rating> = [];
	public var epics:Int = 0;
	public var sicks:Int = 0;
	public var goods:Int = 0;
	public var bads:Int = 0;
	public var shits:Int = 0;

	private var generatedMusic:Bool = false;
	public var endingSong:Bool = false;
	public var startingSong:Bool = false;
	private var updateTime:Bool = true;
	public static var changedDifficulty:Bool = false;
	public static var chartingMode:Bool = false;
	public static var startOnTime:Float = 0;

	public var shaderUpdates:Array<Float->Void> = [];

	//Gameplay settings
	public var healthGain:Float = 1;
	public var healthLoss:Float = 1;
	public var instakillOnMiss:Bool = false;
	public var cpuControlled(default, set):Bool = false;
	public var practiceMode:Bool = false;

	public var botplaySine:Float = 0;
	public var botplayTxt:FlxText;

	public var iconP1:HealthIcon;
	public var iconP2:HealthIcon;
	public var camHUD:FlxCamera;
	public var camOverlay:FlxCamera; // shit that should go above all else and not get affected by camHUD changes, but still below camOther (pause menu, etc)
	public var camGame:FlxCamera;
	public var camOther:FlxCamera;
	public var cameraSpeed:Float = 1;

	public var allowedToUpdateScoreTXT:Bool = true;

	var stageData:StageFile;

	var dialogue:Array<String> = ['blah blah blah', 'coolswag'];
	var dialogueJson:DialogueFile = null;

	public var songScore:Int = 0;
	public var songHits:Int = 0;
	public var songMisses:Int = 0;

	public var timeTxt:FlxText;
	public var timeBitmapTxt:FlxBitmapText;

	var topBar:FlxSprite;
	var bottomBar:FlxSprite;

	public static var campaignScore:Int = 0;
	public static var campaignMisses:Int = 0;
	public static var seenCutscene:Bool = false;
	public static var deathCounter:Int = 0;

	public var defaultCamZoom:Float = 1.05;

	// how big to stretch the pixel art assets
	public static var daPixelZoom:Float = 6;
	private var singAnimations:Array<String> = ['singLEFT', 'singDOWN', 'singUP', 'singRIGHT'];

	public var inCutscene:Bool = false;
	public var ingameCutscene:Bool = false;
	public var skipCountdown:Bool = false;
	public var songLength:Float = 0;
	public var barSongLength:Float = 0;

	public var boyfriendCameraOffset:Array<Float> = null;
	public var opponentCameraOffset:Array<Float> = null;
	public var girlfriendCameraOffset:Array<Float> = null;

	#if desktop
	// Discord RPC variables
	var storyDifficultyText:String = "";
	var detailsText:String = "";
	var detailsPausedText:String = "";
	#end

	//Achievement shit
	var keysPressed:Array<Bool> = [];
	var boyfriendIdleTime:Float = 0.0;
	var boyfriendIdled:Bool = false;

	// Script shit
	public static var instance:PlayState;
	public var luaArray:Array<FunkinLua> = [];
	public var funkyScripts:Array<FunkinScript> = [];
	public var hscriptArray:Array<FunkinHScript> = [];

	//script stage stuff
	public var bgStuff:FlxTypedGroup<BGSprite>;
	public var fgStuff:FlxTypedGroup<BGSprite>;

	public var notetypeScripts:Map<String, FunkinScript> = []; // custom notetypes for scriptVer '1'
	public var eventScripts:Map<String, FunkinScript> = []; // custom events for scriptVer '1'
	public var stageScripts:Map<String, FunkinHScript> = [];

	public var noteskinScript:FunkinHScript;
	public var scriptedNoteOffsets:Array<FlxPoint> = [];
	public var scriptedStrumOffsets:Array<FlxPoint> = [];

	private var luaDebugGroup:FlxTypedGroup<DebugLuaText>;
	public var introSoundsSuffix:String = '';

	// Debug buttons
	private var debugKeysChart:Array<FlxKey>;
	private var debugKeysCharacter:Array<FlxKey>;

	// Less laggy controls
	private var keysArray:Array<Dynamic>;
	public var focusedChar:Character;

	// shader stuffs ig
	public var glitchA:GlitchShaderA;
	public var glitchB:GlitchShaderB;
	public var glitchC:Fuck;
	public var glitchD:DistortGlitchShader;

	var precacheList:Map<String, String> = new Map<String, String>();

	public var camTween:FlxTween;
	public var camHUDAlphaTween:FlxTween;


	var subtitleText:FlxText = new FlxText();

	public var uiGroup:FlxSpriteGroup = new FlxSpriteGroup();
	public var noteGroup:FlxTypedGroup<FlxBasic> = new FlxTypedGroup<FlxBasic>();

	//camera utility
	public var zoomsPerBeat:Int = 4;
	public var camOffset:Float = 30;
	public var forcedCharFocus:Null<Character> = null;

	public function set_cpuControlled(val:Bool){
		if(playFields!=null && playFields.members.length > 0){
			for(field in playFields.members){
				if(field.isPlayer)
					field.autoPlayed = val;
				
			}
		}
		return cpuControlled = val;
	}
	function buildStage(stageName:String){
		switch (stageName)
		{
			default:
				bgStuff = new FlxTypedGroup<BGSprite>();
				fgStuff = new FlxTypedGroup<BGSprite>();

				add(bgStuff);
		}
	}

	function setStageData(stageData:StageFile){
		defaultCamZoom = stageData.defaultZoom;
		FlxG.camera.zoom = defaultCamZoom;
		isPixelStage = stageData.isPixelStage;
		BF_X = stageData.boyfriend[0];
		BF_Y = stageData.boyfriend[1];
		GF_X = stageData.girlfriend[0];
		GF_Y = stageData.girlfriend[1];
		DAD_X = stageData.opponent[0];
		DAD_Y = stageData.opponent[1];


		if(stageData.camera_speed != null)
			cameraSpeed = stageData.camera_speed;

		boyfriendCameraOffset = stageData.camera_boyfriend;
		if(boyfriendCameraOffset == null) //Fucks sake should have done it since the start :rolling_eyes:
			boyfriendCameraOffset = [0, 0];

		opponentCameraOffset = stageData.camera_opponent;
		if(opponentCameraOffset == null)
			opponentCameraOffset = [0, 0];

		girlfriendCameraOffset = stageData.camera_girlfriend;
		if(girlfriendCameraOffset == null)
			girlfriendCameraOffset = [0, 0];

		if(boyfriendGroup==null)
			boyfriendGroup = new FlxSpriteGroup(BF_X, BF_Y);
		else{
			boyfriendGroup.x = BF_X;
			boyfriendGroup.y = BF_Y;
		}
		if(dadGroup==null)
			dadGroup = new FlxSpriteGroup(DAD_X, DAD_Y);
		else{
			dadGroup.x = DAD_X;
			dadGroup.y = DAD_Y;
		}

		if(gfGroup==null)
			gfGroup = new FlxSpriteGroup(GF_X, GF_Y);
		else{
			gfGroup.x = GF_X;
			gfGroup.y = GF_Y;
		}
	}

	function returnCharacterPreload(characterName:String):Array<AssetPreload>{
		var char = Character.getCharacterFile(characterName);
		var name:String = 'icons/' + char.healthicon;
		if(!Paths.fileExists('images/' + name + '.png', IMAGE)) name = 'icons/icon-' + char.healthicon; //Older versions of psych engine's support
		if(!Paths.fileExists('images/' + name + '.png', IMAGE)) name = 'icons/icon-face'; //Prevents crash from missing icon

		return [
			{path: char.image}, // spritesheet
			{path: name} // icon
		];
	}

	override public function create()
	{

		Paths.clearStoredMemory();

		// for lua
		instance = this;
	
		debugKeysChart = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_1'));
		debugKeysCharacter = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_2'));
		PauseSubState.songName = null; //Reset to default

		keysArray = [
			ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_left')),
			ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_down')),
			ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_up')),
			ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_right'))
		];


		var rating:Rating = new Rating('sick');
		rating.score = 350;
		rating.noteSplash = true;
		ratingsData.push(rating);

		var rating:Rating = new Rating('good');
		rating.ratingMod = 0.7;
		rating.score = 200;
		rating.noteSplash = false;
		ratingsData.push(rating);

		var rating:Rating = new Rating('bad');
		rating.ratingMod = 0.4;
		rating.score = 100;
		rating.noteSplash = false;
		ratingsData.push(rating);

		var rating:Rating = new Rating('shit');
		rating.ratingMod = 0;
		rating.score = 50;
		rating.noteSplash = false;
		ratingsData.push(rating);

		// For the "Just the Two of Us" achievement
		for (i in 0...keysArray.length)
		{
			keysPressed.push(false);
		}

		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		// Gameplay settings
		healthGain = ClientPrefs.getGameplaySetting('healthgain', 1);
		healthLoss = ClientPrefs.getGameplaySetting('healthloss', 1);
		instakillOnMiss = ClientPrefs.getGameplaySetting('instakill', false);
		practiceMode = ClientPrefs.getGameplaySetting('practice', false);
		cpuControlled = ClientPrefs.getGameplaySetting('botplay', false);

		// var gameCam:FlxCamera = FlxG.camera;
		camGame = new FlxCamera();
		camHUD = new FlxCamera();
		camOverlay = new FlxCamera();
		camOther = new FlxCamera();
		camOverlay.bgColor.alpha = 0;
		camHUD.bgColor.alpha = 0;
		camOther.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camHUD,false);
		FlxG.cameras.add(camOverlay,false);
		FlxG.cameras.add(camOther,false);
		grpNoteSplashes = new FlxTypedGroup<NoteSplash>();

		//FlxG.cameras.setDefaultDrawTarget(camGame, true);

		persistentUpdate = true;
		persistentDraw = true;

		if (SONG == null)
			SONG = Song.loadFromJson('tutorial');

		Conductor.mapBPMChanges(SONG);
		Conductor.changeBPM(SONG.bpm);

		arrowSkin = SONG.arrowSkin;
		scriptedNoteOffsets = [];
		scriptedStrumOffsets = [];
		
		for(i in 0...4){
			scriptedNoteOffsets.push(new FlxPoint(0, 0));
			scriptedStrumOffsets.push(new FlxPoint(0, 0));
		}
		if(SONG.arrowSkin != ''){
			for(ext in FunkinHScript.hscriptExts){
				if(FileSystem.exists(Paths.noteskin('${SONG.arrowSkin}.$ext'))){
					noteskinScript = FunkinHScript.fromFile(Paths.noteskin('${SONG.arrowSkin}.$ext'));
				}else if(FileSystem.exists(Paths.modsNoteskin('${SONG.arrowSkin}.$ext'))){
					//Noteskin doesn't exist in assets, trying mods folder
					noteskinScript = FunkinHScript.fromFile(Paths.modsNoteskin('${SONG.arrowSkin}.$ext'));
				}else{
					//Noteskin doesn't exist in assets or mods folder, returning null
					trace('noteskin script doesnt exist: ${Paths.noteskin('${SONG.arrowSkin}.$ext')}');
					// if(ext == 'hscript')
					// 	FlxG.switchState(new meta.states.substate.CrashReportSubstate(FlxG.state, 'Noteskin not found.', 'noteskin script doesnt exist: ${Paths.noteskin('${SONG.arrowSkin}.$ext')}'));
					// ^^ this is stupid why did i think to do this
				}
			}
			trace(arrowSkins);	
		}

		if(noteskinScript != null){
			noteskinScript.call("offset", [scriptedNoteOffsets, scriptedStrumOffsets]);

			// scriptedNoteOffsets = noteskinScript.call('noteOffsets', [[new FlxPoint(0, 0), new FlxPoint(0, 0), new FlxPoint(0, 0), new FlxPoint(0, 0)]]);
			var skins = ['bfSkin', 'dadSkin'];
			arrowSkins = [];
			for(skin in skins){
				if(noteskinScript.call(skin, []) != null)		
					arrowSkins.push(noteskinScript.call(skin, []))
				else
					arrowSkins.push('NOTE_assets');
			}
			arrowSkin = noteskinScript.call('arrowSkin', []);	
			trace(scriptedNoteOffsets);
			trace(scriptedStrumOffsets);

		}else{
			arrowSkins = ['NOTE_assets', 'NOTE_assets'];
		}


		#if desktop
		storyDifficultyText = CoolUtil.difficulties[storyDifficulty];

		// String that contains the mode defined here so it isn't necessary to call changePresence for each mode
		if (isStoryMode)
		{
			detailsText = "Jooouyouse :    )";
		}
		else
		{
			detailsText = "Freeplay";
		}

		// String for when the game is paused
		detailsPausedText = "Paused - " + detailsText;
		#end

		topBar = new FlxSprite(0, -170).makeGraphic(FlxG.width, 170, FlxColor.BLACK);
		bottomBar = new FlxSprite(0, FlxG.height).makeGraphic(FlxG.width, 170, FlxColor.BLACK);


		GameOverSubstate.resetVariables();
		var songName:String = Paths.formatToSongPath(SONG.song);

		curStage = SONG.stage;
		if (SONG.stage == null || SONG.stage.length < 1)
			SONG.stage = 'stage';
		curStage = SONG.stage;
		
		stage = new Stage(curStage);
		stageData = stage.stageData;
		setStageData(stageData);

		setOnScripts('stage', stage);
		
		#if loadBenchmark
		var startLoadTime = Sys.time();
		#end

		if(ClientPrefs.data.multicoreLoading){ // should probably move all of this to its own preload class
			#if loadBenchmark
			var currentTime = Sys.time();
			trace("started preload at " + currentTime);
			#end
			var shitToLoad:Array<AssetPreload> = [
				{path: "sick"},
				{path: "good"},
				{path: "bad"},
				{path: "shit"},
				{path: "healthBar", library: "shared"},
				{path: "hpBar", library: "shared"},
				{path: "ui/hpBar-exe"},
				{path: "combo"}
			];
			for (number in 0...10)
				shitToLoad.push({path: 'num$number'});


			for(i in arrowSkins){
				if(i!=null && i.trim()!='' && i.length > 0){
					shitToLoad.push({
						path: i
					});
				}
			}


			if(SONG.splashSkin != null && SONG.splashSkin.length > 0){
				shitToLoad.push({
					path: SONG.splashSkin
				});
			}else{
				shitToLoad.push({
					path: "noteSplashes"
				});
			}

			shitToLoad.push({
				path: "NOTE_assets"
			});

			if(isPixelStage){
				for (number in 0...10)
					shitToLoad.push({path: 'pixelUI/num${number}-pixel', library: "shared"});

				shitToLoad.push({path: "pixelUI/sick-pixel", library: "shared"});
				shitToLoad.push({path: "pixelUI/good-pixel", library: "shared"});
				shitToLoad.push({path: "pixelUI/bad-pixel", library: "shared"});
				shitToLoad.push({path: "pixelUI/shit-pixel", library: "shared"});
				shitToLoad.push({path: "pixelUI/combo-pixel", library: "shared"});

				shitToLoad.push({
					path: "pixelUI/NOTE_assets",
					library: "shared",
				});
				if(ClientPrefs.data.noteSkin=='Quants'){
					shitToLoad.push({
						path: "pixelUI/QUANTNOTE_assets",
						library: "shared"
					});
				}
			}else{
				if(ClientPrefs.data.noteSkin=='Quants'){
					shitToLoad.push({
						path: "QUANTNOTE_assets"
					});
				}
			}


			if(ClientPrefs.data.timeBarType != 'Disabled'){
				shitToLoad.push({
					path: "timeBar",
					library: "shared"
				});
			}
			if(stageData.preloadStrings != null){
				var lib = stageData.directory.trim().length > 0?stageData.directory:null;
				for(i in stageData.preloadStrings)
					shitToLoad.push({path: i, library: lib });
			}

			if(stageData.preload != null){
				for(i in stageData.preload)
					shitToLoad.push(i);
			}

			var characters:Array<String> = [
				SONG.player1,
				SONG.player2
			];
			if(!stageData.hide_girlfriend){
				characters.push(SONG.gfVersion);
			}

			for(character in characters){
				for(data in returnCharacterPreload(character))
					shitToLoad.push(data);

			}

			for(event in getEvents()){
				for(data in preloadEvent(event)){ // preloads everythin for events
					if(!shitToLoad.contains(data))
						shitToLoad.push(data);
				}
			}

			shitToLoad.push({
				path: '${Paths.formatToSongPath(SONG.song)}/Inst',
				type: 'SONG'
			});

			if (SONG.needsVoices)
				shitToLoad.push({
					path: '${Paths.formatToSongPath(SONG.song)}/Voices',
					type: 'SONG'
				});

			// TODO: go through shitToLoad and clear it of repeats as to not waste time loadin shit that already exists
			var dupes:Array<String> = [];
			for(shit in shitToLoad) {
				if (dupes.contains(shit.path)) {
					shitToLoad.remove(shit);
					trace('heh. just removed a dupe of ${shit.path}. no need to thank me');
					continue;
				}
				dupes.push(shit.path);
			}
	


			var threadLimit:Int = ClientPrefs.data.loadingThreads; //Math.floor(Std.parseInt(Sys.getEnv("NUMBER_OF_PROCESSORS")));
			if(shitToLoad.length>0 && threadLimit > 1){
				// thanks shubs -neb
				for(shit in shitToLoad)
					if(shit.terminate)shit.terminate=false; // do not

				var count = shitToLoad.length;

				if(threadLimit > shitToLoad.length)threadLimit=shitToLoad.length; // only use as many as it needs

				var sprites:Array<FlxSprite> = [];
				var threads:Array<Thread> = [];

				var finished:Bool = false;
				trace("loading " + count + " items with " + threadLimit + " threads");
				var main = Thread.current();
				var loadIdx:Int = 0;
				for (i in 0...threadLimit) {
					var thread:Thread = Thread.create( () -> {
						while(true){
							var toLoad:Null<AssetPreload> = Thread.readMessage(true); // get the next thing that should be loaded
							if(toLoad!=null){
								if(toLoad.terminate==true)break;
								// just loads the graphic
								#if traceLoading
								trace("loading " + toLoad.path);
								#end
								switch(toLoad.type){
									case 'SOUND':
										Paths.returnSound("sounds", toLoad.path, toLoad.library);
										#if traceLoading
										trace("loaded " + toLoad);
										#end
									case 'MUSIC':
										Paths.returnSound("music", toLoad.path, toLoad.library);
										#if traceLoading
										trace("loaded " + toLoad);
										#end
									case 'SONG':
										Paths.returnSound("songs", toLoad.path, toLoad.library);
										#if traceLoading
										trace("loaded " + toLoad);
										#end
									default:
										#if traceLoading
										trace('grabbin da graphic ${toLoad.library}:${toLoad.path}');
										#end
										var graphic = Paths.returnGraphic(toLoad.path, toLoad.library, true);
										#if traceLoading
										trace(graphic);
										#end
										if(graphic!=null){
											var sprite = new FlxSprite().loadGraphic(graphic);
											sprite.alpha = 0.001;
											add(sprite);
											sprites.push(sprite);
											#if traceLoading
											trace("loaded " + toLoad, graphic, sprite);
											#end
										}#if traceLoading
										else
											trace("Could not load " + toLoad);

										#end
								}
								#if traceLoading
								trace("getting next asset");
								#end
								main.sendMessage({ // send message so that it can get the next thing to load
									thread: Thread.current(),
									asset: toLoad,
									terminated: false
								});
							}
						}
						main.sendMessage({ // send message so that it can get the next thing to load
							thread: Thread.current(),
							asset: '',
							terminated: true
						});
						return;
					});
					threads.push(thread);
				}
				for(thread in threads)
					thread.sendMessage(shitToLoad.pop()); // gives the thread the top thing to load

				while(loadIdx < count){
					var res:Null<PreloadResult> = Thread.readMessage(true); // whenever a thread loads its asset, it sends a message to get a new asset for it to load
					if(res!=null){
						if(res.terminated){
							if(threads.contains(res.thread)){
								threads.remove(res.thread); // so it wont have a message sent at the end
							}
						}else{
							loadIdx++;
							#if traceLoading
							trace("loaded " + loadIdx + " out of " + count);
							#end
							if(shitToLoad.length > 0)
								res.thread.sendMessage(shitToLoad.pop()); // gives the thread the next thing it should load
							else
								res.thread.sendMessage({path: '', library:'', terminate: true}); // terminate the thread

						}

					}
				};
				trace(loadIdx, count);
				var idx:Int = 0;
				for(t in threads){
					t.sendMessage({path: '', library: '', terminate: true}); // terminate all threads
					trace("terminating thread " + idx);
					idx++;
				}

				finished = true;
				#if loadBenchmark
				var finishedTime = Sys.time();
				trace("preloaded in " + (finishedTime - currentTime) + " (at " + finishedTime + ")");
				#else
				trace("preloaded");
				#end
				for(sprite in sprites)
					remove(sprite);
			}
		}
		// buildStage(curStage);
		// STAGE SCRIPTS
		stage.buildStage();
		#if LUA_ALLOWED
		for (script in stage.luaArray){
			luaArray.push(script);
			funkyScripts.push(script);
		}
		#end
		for (script in stage.hscriptArray){
			hscriptArray.push(script);
			funkyScripts.push(script);
			trace(script.scriptName);
		}

		if(isPixelStage) {
			introSoundsSuffix = '-pixel';
		}

		if (callOnHScripts("onAddSpriteGroups", []) != Globals.Function_Stop)
			{
				add(stage);
	
				add(gfGroup);
				add(dadGroup);
				add(boyfriendGroup);
	
				add(stage.foreground);
			}
		// if(fgStuff != null)
		// 	add(fgStuff);

		glitchA = new GlitchShaderA();
		glitchB = new GlitchShaderB();
		glitchC = new Fuck();
		glitchD = new DistortGlitchShader();


		setOnHScripts('glitchA', glitchA);
		setOnHScripts('glitchB', glitchB);
		setOnHScripts('glitchC', glitchC);
		setOnHScripts('glitchD', glitchD);
		
		setOnHScripts('camGame', camGame);
		setOnHScripts('camHUD', camHUD);
		setOnHScripts('camOverlay', camOverlay);
		setOnHScripts('camOther', camOther);

		#if LUA_ALLOWED
		luaDebugGroup = new FlxTypedGroup<DebugLuaText>();
		luaDebugGroup.cameras = [camOther];
		add(luaDebugGroup);
		#end

		// "GLOBAL" SCRIPTS
		var filesPushed:Array<String> = [];
		var foldersToCheck:Array<String> = [Paths.getPreloadPath('scripts/')];

		#if MODS_ALLOWED
		foldersToCheck.insert(0, Paths.mods('scripts/'));
		if(Paths.currentModDirectory != null && Paths.currentModDirectory.length > 0)
			foldersToCheck.insert(0, Paths.mods(Paths.currentModDirectory + '/scripts/'));

		for(mod in Paths.getGlobalMods())
			foldersToCheck.insert(0, Paths.mods(mod + '/scripts/'));
		#end

		for (folder in foldersToCheck)
		{
			if(FileSystem.exists(folder))
			{
				for (file in FileSystem.readDirectory(folder))
				{	
					if(!filesPushed.contains(file)){
						if(file.endsWith('.lua'))
						{
							#if LUA_ALLOWED
							var script = new FunkinLua(folder + file);
							luaArray.push(script);
							funkyScripts.push(script);
							filesPushed.push(file);
							#end
						}
						else{
							for(ext in FunkinHScript.hscriptExts){
								if(file.endsWith('.$ext')){
									var script = FunkinHScript.fromFile(folder + file);
									hscriptArray.push(script);
									funkyScripts.push(script);
									filesPushed.push(file);
									break;
								}
							}
						}
					}
				}
			}
		}

		var gfVersion:String = SONG.gfVersion;
		if(gfVersion == null || gfVersion.length < 1)
		{
			switch (curStage)
			{
				case 'mall' | 'mallEvil':
					gfVersion = 'gf-christmas';
				case 'school' | 'schoolEvil':
					gfVersion = 'gf-pixel';
				default:
					gfVersion = 'gf';
			}

			switch(Paths.formatToSongPath(SONG.song))
			{
				case 'stress':
					gfVersion = 'pico-speaker';
			}
			SONG.gfVersion = gfVersion; //Fix for the Chart Editor
		}

		if (!stageData.hide_girlfriend)
		{
			gf = new Character(0, 0, gfVersion);
			startCharacterPos(gf);
			gf.scrollFactor.set(0.95, 0.95);
			gfGroup.add(gf);
			startCharacterLua(gf.curCharacter, gf);

			setOnScripts('gf', gf);
			setOnScripts('gfGroup', gfGroup);
		}

		dad = new Character(0, 0, SONG.player2);
		startCharacterPos(dad, true);
		dadGroup.add(dad);
		startCharacterLua(dad.curCharacter, dad);
		dadMap.set(dad.curCharacter, dad);

		boyfriend = new Boyfriend(0, 0, SONG.player1);
		startCharacterPos(boyfriend);
		boyfriendGroup.add(boyfriend);

		setOnScripts('dad', dad);
		setOnScripts('dadGroup', dadGroup);

		setOnScripts('boyfriend', boyfriend);
		setOnScripts('boyfriendGroup', boyfriendGroup);


		startCharacterLua(boyfriend.curCharacter, boyfriend);
		boyfriendMap.set(boyfriend.curCharacter, boyfriend);

		var camPos:FlxPoint = new FlxPoint(girlfriendCameraOffset[0], girlfriendCameraOffset[1]);
		if(gf != null)
		{
			camPos.x += gf.getGraphicMidpoint().x + gf.cameraPosition[0];
			camPos.y += gf.getGraphicMidpoint().y + gf.cameraPosition[1];
		}else{
			camPos.set(opponentCameraOffset[0], opponentCameraOffset[1]);
			camPos.x += dad.getGraphicMidpoint().x + dad.cameraPosition[0];
			camPos.y += dad.getGraphicMidpoint().y + dad.cameraPosition[1];
		}

		if(dad.curCharacter.startsWith('gf')) {
			dad.setPosition(GF_X, GF_Y);
			if(gf != null)
				gf.visible = false;
		}



		var file:String = Paths.json(songName + '/dialogue'); //Checks for json/Psych Engine dialogue
		if (OpenFlAssets.exists(file)) {
			dialogueJson = DialogueBoxPsych.parseDialogue(file);
		}

		var file:String = Paths.txt(songName + '/' + songName + 'Dialogue'); //Checks for vanilla/Senpai dialogue
		if (OpenFlAssets.exists(file)) {
			dialogue = CoolUtil.coolTextFile(file);
		}
		var doof:DialogueBox = new DialogueBox(false, dialogue);
		// doof.x += 70;
		// doof.y = FlxG.height * 0.5;
		doof.scrollFactor.set();
		doof.finishThing = startCountdown;
		doof.nextDialogueThing = startNextDialogue;
		doof.skipDialogueThing = skipDialogue;

		Conductor.songPosition = -5000;

		strumLine = new FlxSprite(ClientPrefs.data.middleScroll ? STRUM_X_MIDDLESCROLL : STRUM_X, 50).makeGraphic(FlxG.width, 10);
		// if(ClientPrefs.data.downScroll) strumLine.y = FlxG.height - 150;
		strumLine.scrollFactor.set();

		//welcome to datas new supa fucking ui system
		createUIClass();

		add(uiGroup);
		uiGroup.scrollFactor.set();
		uiGroup.visible = !ClientPrefs.data.hideHud;

		add(noteGroup);

		var showTime:Bool = (ClientPrefs.data.timeBarType != 'Disabled');
		timeTxt = new FlxText(STRUM_X + (FlxG.width / 2) - 248, 19, 400, "", 32);
		timeTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		timeTxt.scrollFactor.set();
		timeTxt.alpha = 0;
		timeTxt.borderSize = 2;
		timeTxt.visible = showTime;
		if(ClientPrefs.data.downScroll) timeTxt.y = FlxG.height - 44;

		timeBitmapTxt = new FlxBitmapText(FlxBitmapFont.fromMonospace(Paths.image('ui/nums'),'0123456789:',new FlxPoint(7,11)));
		timeBitmapTxt.scrollFactor.set();
		timeBitmapTxt.visible = showTime;
		timeBitmapTxt.fieldWidth = FlxG.width;
		timeBitmapTxt.setScale(2);

		if(ClientPrefs.data.timeBarType == 'Song Name') {
			var songName = SONG.song;
			if (songName == 'Obituary') {
				songName = 'Free-4-Me';
			}
			timeTxt.text = songName;

		}


		updateTime = showTime;

		timeBarBG = new AttachedSprite('timeBar');
		timeBarBG.x = timeTxt.x;
		timeBarBG.y = timeTxt.y + (timeTxt.height / 4);
		timeBarBG.scrollFactor.set();
		timeBarBG.alpha = 0;
		timeBarBG.visible = showTime;
		timeBarBG.color = FlxColor.BLACK;
		timeBarBG.xAdd = -4;
		timeBarBG.yAdd = -4;
		uiGroup.add(timeBarBG);

		timeBar = new FlxBar(timeBarBG.x + 4, timeBarBG.y + 4, LEFT_TO_RIGHT, Std.int(timeBarBG.width - 8), Std.int(timeBarBG.height - 8), this,
			'songPercent', 0, 1);
		timeBar.scrollFactor.set();
		timeBar.createFilledBar(0xFF000000, 0xFFFFFFFF);
		timeBar.numDivisions = 800; //How much lag this causes?? Should i tone it down to idk, 400 or 200?
		timeBar.alpha = 0;
		timeBar.visible = showTime;
		uiGroup.add(timeBar);

		uiGroup.add(timeTxt);
		timeBitmapTxt.centerOnSprite(timeBar);
		timeBitmapTxt.y +=2;
		uiGroup.add(timeBitmapTxt);

		timeBarBG.sprTracker = timeBar;

		playFields = new FlxTypedGroup<PlayField>();
		noteGroup.add(playFields);
		noteGroup.add(grpNoteSplashes);

		if(ClientPrefs.data.timeBarType == 'Song Name')
		{
			timeTxt.size = 24;
			timeTxt.y += 3;
		}

		var splash:NoteSplash = new NoteSplash(100, 100, 0);
		grpNoteSplashes.add(splash);
		splash.alpha = 0.0;
		// startCountdown();

		generateSong(SONG.song);
		modManager = new ModManager(this);
		hscriptSetDefault("modManager", modManager);

		/*
		#if LUA_ALLOWED
		for (notetype in noteTypeMap.keys())
		{
			#if MODS_ALLOWED
			var luaToLoad:String = Paths.modFolders('custom_notetypes/' + notetype + '.lua');
			if(FileSystem.exists(luaToLoad))
			{
				var lua:FunkinLua = new FunkinLua(luaToLoad);
				luaArray.push(lua);
				funkyScripts.push(lua);
			}
			else
			{
				luaToLoad = Paths.getPreloadPath('custom_notetypes/' + notetype + '.lua');
				if(FileSystem.exists(luaToLoad))
				{
					var lua:FunkinLua = new FunkinLua(luaToLoad);
					luaArray.push(lua);
					funkyScripts.push(lua);
				}
			}
			#elseif sys
			var luaToLoad:String = Paths.getPreloadPath('custom_notetypes/' + notetype + '.lua');
			if(OpenFlAssets.exists(luaToLoad))
			{
				var lua:FunkinLua = new FunkinLua(luaToLoad);
				luaArray.push(lua);
				funkyScripts.push(lua);
			}
			#end
		}
		for (event in eventPushedMap.keys())
		{
			#if MODS_ALLOWED
			var luaToLoad:String = Paths.modFolders('custom_events/' + event + '.lua');
			if(FileSystem.exists(luaToLoad))
			{
					var lua:FunkinLua = new FunkinLua(luaToLoad);
					luaArray.push(lua);
					funkyScripts.push(lua);
			}
			else
			{
				luaToLoad = Paths.getPreloadPath('custom_events/' + event + '.lua');
				if(FileSystem.exists(luaToLoad))
				{
					var lua:FunkinLua = new FunkinLua(luaToLoad);
					luaArray.push(lua);
					funkyScripts.push(lua);
				}
			}
			#elseif sys
			var luaToLoad:String = Paths.getPreloadPath('custom_events/' + event + '.lua');
			if(OpenFlAssets.exists(luaToLoad))
			{
				var lua:FunkinLua = new FunkinLua(luaToLoad);
				luaArray.push(lua);
				funkyScripts.push(lua);
			}
			#end
		}
		#end*/
		noteTypeMap.clear();
		noteTypeMap = null;
		eventPushedMap.clear();
		eventPushedMap = null;

		// After all characters being loaded, it makes then invisible 0.01s later so that the player won't freeze when you change characters
		// add(strumLine);

		camFollow = new FlxPoint();
		camFollowPos = new FlxObject(0, 0, 1, 1);
	

		snapCamFollowToPos(camPos.x, camPos.y);
		if (prevCamFollow != null)
		{
			camFollow = prevCamFollow;
			prevCamFollow = null;
		}
		if (prevCamFollowPos != null)
		{
			camFollowPos = prevCamFollowPos;
			prevCamFollowPos = null;
		}
		add(camFollowPos);

		FlxG.camera.follow(camFollowPos, LOCKON, 1);
		// FlxG.camera.setScrollBounds(0, FlxG.width, 0, FlxG.height);
		FlxG.camera.zoom = defaultCamZoom;
		FlxG.camera.focusOn(camFollow);

		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);

		FlxG.fixedTimestep = false;
		moveCameraSection();
		
		iconP1 = new HealthIcon(boyfriend.healthIcon, true);
		iconP1.setPosition(1,healthBar.y - 65);
		iconP1.alpha = ClientPrefs.data.healthBarAlpha;

		iconP2 = new HealthIcon(dad.healthIcon, false);
		iconP2.setPosition(1,healthBar.y - 65);
		iconP2.alpha = ClientPrefs.data.healthBarAlpha;

		reloadHealthBarColors();

		botplayTxt = new FlxText(400, timeBarBG.y + 55, FlxG.width - 800, "BOTPLAY", 32);
		botplayTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		botplayTxt.scrollFactor.set();
		botplayTxt.borderSize = 1.25;
		botplayTxt.visible = cpuControlled;
		uiGroup.add(botplayTxt);
		if(ClientPrefs.data.downScroll) {
			botplayTxt.y = timeBarBG.y - 78;
		}

		uiCallFunction((ui:BaseUI)-> {ui.sort();});

		doof.cameras = [camHUD];
		uiGroup.cameras = [camHUD];
		noteGroup.cameras = [camHUD];
		for (i in [topBar,bottomBar]) i.cameras = [camOther];

		setOnScripts('playFields', playFields);
		setOnScripts('grpNoteSplashes', grpNoteSplashes);
		setOnScripts('notes', notes);
		setOnScripts('healthBar', healthBar);
		setOnScripts('iconP1', iconP1);
		setOnScripts('iconP2', iconP2);
		//setOnScripts('scoreTxt', scoreTxt);
		setOnScripts('botplayTxt', botplayTxt);
		setOnScripts('timeBar', timeBar);
		setOnScripts('timeTxt', timeTxt);
		setOnScripts('doof', doof);
		setOnScripts('topBar', topBar);
		setOnScripts('bottomBar', bottomBar);


		// cameras = [FlxG.cameras.list[1]];
		startingSong = true;

		// SONG SPECIFIC SCRIPTS
		var filesPushed:Array<String> = [];
		var foldersToCheck:Array<String> = [Paths.getPreloadPath('data/' + Paths.formatToSongPath(SONG.song) + '/')];

		#if MODS_ALLOWED
		foldersToCheck.insert(0, Paths.mods('data/' + Paths.formatToSongPath(SONG.song) + '/'));
		if(Paths.currentModDirectory != null && Paths.currentModDirectory.length > 0)
			foldersToCheck.insert(0, Paths.mods(Paths.currentModDirectory + '/data/' + Paths.formatToSongPath(SONG.song) + '/'));

		for(mod in Paths.getGlobalMods())
			foldersToCheck.insert(0, Paths.mods(mod + '/data/' + Paths.formatToSongPath(SONG.song) + '/' ));// using push instead of insert because these should run after everything else
		#end

		for (folder in foldersToCheck)
		{
			if(FileSystem.exists(folder))
			{
				for (file in FileSystem.readDirectory(folder))
				{
					if(!filesPushed.contains(file)){
						if(file.endsWith('.lua'))
						{
							#if LUA_ALLOWED
							var script = new FunkinLua(folder + file);
							luaArray.push(script);
							funkyScripts.push(script);
							filesPushed.push(file);
							#end
						}
						else{
							for(ext in FunkinHScript.hscriptExts){
								if(file.endsWith('.$ext')){
									var script = FunkinHScript.fromFile(folder + file);
									hscriptArray.push(script);
									funkyScripts.push(script);
									filesPushed.push(file);
									break;
								}
							}
						}
					}
				}
			}
		}

		var daSong:String = Paths.formatToSongPath(curSong);

		if (isStoryMode && !seenCutscene)
		{
			switch (daSong)
			{
				default:
					var ret:Dynamic = callOnHScripts("doStartCountdown", []);
					trace(ret);
					if(ret != null && ret == Globals.Function_Continue)
						startCountdown();
					else
						callOnHScripts("presongCutscene", []);
			}
			seenCutscene = true;
		}
		else
		{
			var ret:Dynamic = callOnHScripts("doStartCountdown", []);
			trace(ret);
			if(ret != null && ret == Globals.Function_Continue)
				startCountdown();
			else
				callOnHScripts("presongCutscene", []);
		}
		RecalculateRating();
		updateScoreBar();

		//PRECACHING MISS SOUNDS BECAUSE I THINK THEY CAN LAG PEOPLE AND FUCK THEM UP IDK HOW HAXE WORKS
		if(ClientPrefs.data.hitsoundVolume > 0) precacheList.set('hitsound', 'sound');
		precacheList.set('missnote1', 'sound');
		precacheList.set('missnote2', 'sound');
		precacheList.set('missnote3', 'sound');

		if (PauseSubState.songName != null) {
			precacheList.set(PauseSubState.songName, 'music');
		} else if(ClientPrefs.data.pauseMusic != 'None') {
			precacheList.set(Paths.formatToSongPath(ClientPrefs.data.pauseMusic), 'music');
		}

		// Updating Discord Rich Presence.
		DiscordHandler.changePresence(detailsText, SONG.song.toLowerCase().replace('-', ' '), iconP2.getCharacter());

		if(!ClientPrefs.data.controllerMode)
		{
			FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
			FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		}

		Conductor.safeZoneOffset = (ClientPrefs.data.safeFrames / 60) * 1000;
		callOnScripts('onCreatePost', []);



		subtitleText = new FlxText(0,0,FlxG.width,'',32);
		subtitleText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(subtitleText);
		subtitleText.cameras = [camOther];
		subtitleText.visible = false;
		//subtitleText.borderSize = 1.5;

		super.create();

		if (!ClientPrefs.data.opponentStrums) {
			opponentStrums.baseAlpha = 0;
			modManager.setValue('alpha',1,1);

		}
		else if (ClientPrefs.data.middleScroll) {
			opponentStrums.baseAlpha = 0.35;
			modManager.setValue('alpha',0.65,1);
			modManager.setValue('opponentSwap',0.5);
		}
		

		Paths.clearUnusedMemory();



		for (key => type in precacheList)
		{
			//trace('Key $key is type $type');
			switch(type)
			{
				case 'image':
					Paths.image(key);
				case 'sound':
					Paths.sound(key);
				case 'music':
					Paths.music(key);
			}
		}

		#if loadBenchmark
		var endLoadTime = Sys.time();
		trace("fully loaded in " + (endLoadTime - startLoadTime));
		#end
	}

	public function createUIClass(newUI:String = '') {
		var hudClass = Type.resolveClass('meta.ui.$newUI');
		hudClass ??= meta.ui.RodentrapUI;
		Type.createInstance(hudClass,[]);

		uiCallFunction((ui:BaseUI)-> {ui.createUI();});
	}

	//testing stuff probably not gonna use lol
	function fixDoubleNotes(){
		for (i in 0...unspawnNotes.length) {
			if (unspawnNotes[i].mustPress && !unspawnNotes[i].noAnimation) {
				if (unspawnNotes[i].strumTime == unspawnNotes[i+1]?.strumTime) {
					if (unspawnNotes[i+1].noAnimation) return;
					unspawnNotes[i+1].noAnimation = true;
					trace('heh.. fixed one');
				}
			}
		}
	}

	function set_songSpeed(value:Float):Float
	{
		if(generatedMusic)
		{
			var ratio:Float = value / songSpeed; //funny word huh
			for (note in notes) note.resizeByRatio(ratio);
			for (note in unspawnNotes) note.resizeByRatio(ratio);
		}
		songSpeed = value;
		noteKillOffset = 350 / songSpeed;
		return value;
	}

	public function addTextToDebug(text:String) {
		#if LUA_ALLOWED
		luaDebugGroup.forEachAlive(function(spr:DebugLuaText) {
			spr.y += 20;
		});

		if(luaDebugGroup.members.length > 34) {
			var blah = luaDebugGroup.members[34];
			blah.destroy();
			luaDebugGroup.remove(blah);
		}
		luaDebugGroup.insert(0, new DebugLuaText(text, luaDebugGroup));
		#end
	}

	public function updateHPBar(x:Float=0,y:Float=0,width:Int=100,height:Int=100,filldir:FlxBarFillDirection=RIGHT_TO_LEFT) {
		healthBar = new FlxBar(x,y,filldir,width,height,this,'displayedHealth',0,2);
	}

	public function reloadHealthBarColors() {
		if(callOnHScripts('reloadHealthBarColors', [healthBar])!= Globals.Function_Stop)
		{

		}

		// healthBar.updateFilledBar();
		// healthBar.updateBar();
	}

	public function addCharacterToList(newCharacter:String, type:Int) {
		switch(type) {
			case 0:
				if(!boyfriendMap.exists(newCharacter)) {
					var newBoyfriend:Boyfriend = new Boyfriend(0, 0, newCharacter);
					boyfriendMap.set(newCharacter, newBoyfriend);
					boyfriendGroup.add(newBoyfriend);
					startCharacterPos(newBoyfriend);
					newBoyfriend.alpha = 0.00001;
					startCharacterLua(newBoyfriend.curCharacter, newBoyfriend);
				}

			case 1:
				if(!dadMap.exists(newCharacter)) {
					var newDad:Character = new Character(0, 0, newCharacter);
					dadMap.set(newCharacter, newDad);
					dadGroup.add(newDad);
					startCharacterPos(newDad, true);
					newDad.alpha = 0.00001;
					startCharacterLua(newDad.curCharacter, newDad);
				}

			case 2:
				if(gf != null && !gfMap.exists(newCharacter)) {
					var newGf:Character = new Character(0, 0, newCharacter);
					newGf.scrollFactor.set(0.95, 0.95);
					gfMap.set(newCharacter, newGf);
					gfGroup.add(newGf);
					startCharacterPos(newGf);
					newGf.alpha = 0.00001;
					startCharacterLua(newGf.curCharacter, newGf);
				}
		}
	}

	function startCharacterLua(name:String, char:Character)
	{
		#if LUA_ALLOWED
		var doPush:Bool = false;
		var scriptFile:String = 'characters/' + name;
		var shitters = [];
		#if MODS_ALLOWED
		var baseFile = scriptFile;
		if(FileSystem.exists(Paths.modFolders(baseFile + '.lua'))) {
			scriptFile = Paths.modFolders(baseFile+ '.lua');
			doPush = true;
		} else if(FileSystem.exists(Paths.modFolders(baseFile + '.hscript'))) {
			scriptFile = Paths.modFolders(baseFile+ '.hscript');
			doPush = true;
		} else {
			scriptFile = Paths.getPreloadPath(baseFile);
			if(FileSystem.exists(scriptFile + '.lua') || FileSystem.exists(scriptFile + '.hscript')) {
				doPush = true;
			}
		}


		#else
		scriptFile = Paths.getPreloadPath(scriptFile);
		if(Assets.exists(scriptFile)) {
			doPush = true;
		}
		#end
		if(doPush)
		{
			trace(scriptFile);
			if(scriptFile.endsWith('.lua')){
				for (lua in luaArray)
					{
						if(lua.scriptName == scriptFile) return;
					}
					var lua:FunkinLua = new FunkinLua(scriptFile);
					luaArray.push(lua);
					funkyScripts.push(lua);
			}else{
				var script:FunkinHScript = FunkinHScript.fromFile(scriptFile);
				hscriptArray.push(script);
				funkyScripts.push(script);
				script.call('onCreate', []);
				script.set('char', char);

			}
		}
		#end
	}

	public function getLuaObject(tag:String, text:Bool=true):FlxSprite {
		if(modchartObjects.exists(tag))return modchartObjects.get(tag);
		if(modchartSprites.exists(tag))return modchartSprites.get(tag);
		if(text && modchartTexts.exists(tag))return modchartTexts.get(tag);
		return null;
	}

	function startCharacterPos(char:Character, ?gfCheck:Bool = false) {
		if(gfCheck && char.curCharacter.startsWith('gf')) { //IF DAD IS GIRLFRIEND, HE GOES TO HER POSITION
			char.setPosition(GF_X, GF_Y);
			char.scrollFactor.set(0.95, 0.95);
			char.danceEveryNumBeats = 2;
		}
		char.x += char.positionArray[0];
		char.y += char.positionArray[1];
	}

	public function startVideo(name:String):Void {
		#if VIDEOS_ALLOWED
		var foundFile:Bool = false;
		var fileName:String = #if MODS_ALLOWED Paths.modFolders('videos/' + name + '.' + Paths.VIDEO_EXTS[0]); #else ''; #end
		#if sys
		if(FileSystem.exists(fileName)) {
			foundFile = true;
		}
		#end

		if(!foundFile) {
			fileName = Paths.video(name);
			#if sys
			if(FileSystem.exists(fileName)) {
			#else
			if(OpenFlAssets.exists(fileName)) {
			#end
				foundFile = true;
			}
		}

		if(foundFile) {
			inCutscene = true;
			var bg = new FlxSprite(-FlxG.width, -FlxG.height).makeGraphic(FlxG.width * 3, FlxG.height * 3, FlxColor.BLACK);
			bg.scrollFactor.set();
			bg.cameras = [camHUD];
			add(bg);

			var video = new FlxVideo();
			video.load(fileName);
			video.play();
			video.onEndReached.add(()->{remove(bg); startAndEnd();});
			return;
		}
		else
		{
			FlxG.log.warn('Couldnt find video file: ' + fileName);
			startAndEnd();
		}
		#end
		startAndEnd();
	}

	function startAndEnd()
	{
		if(endingSong){
			endSong();
		}
		else{
			startCountdown();
		}
	}

	var dialogueCount:Int = 0;
	public var psychDialogue:DialogueBoxPsych;
	//You don't have to add a song, just saying. You can just do "startDialogue(dialogueJson);" and it should work
	public function startDialogue(dialogueFile:DialogueFile, ?song:String = null):Void
	{
		// TO DO: Make this more flexible, maybe?
		if(psychDialogue != null) return;

		if(dialogueFile.dialogue.length > 0) {
			inCutscene = true;
			precacheList.set('dialogue', 'sound');
			precacheList.set('dialogueClose', 'sound');
			psychDialogue = new DialogueBoxPsych(dialogueFile, song);
			psychDialogue.scrollFactor.set();
			if(endingSong) {
				psychDialogue.finishThing = function() {
					psychDialogue = null;
					endSong();
				}
			} else {
				psychDialogue.finishThing = function() {
					psychDialogue = null;
					startCountdown();
				}
			}
			psychDialogue.nextDialogueThing = startNextDialogue;
			psychDialogue.skipDialogueThing = skipDialogue;
			psychDialogue.cameras = [camHUD];
			add(psychDialogue);
		} else {
			FlxG.log.warn('Your dialogue file is badly formatted!');
			if(endingSong) {
				endSong();
			} else {
				startCountdown();
			}
		}
	}

	var startTimer:FlxTimer;
	var finishTimer:FlxTimer = null;

	// For being able to mess with the sprites on Lua
	public var countdownReady:FlxSprite;
	public var countdownSet:FlxSprite;
	public var countdownGo:FlxSprite;

	public function startCountdown():Void
	{
		if(startedCountdown) {
			callOnScripts('onStartCountdown', []);
			return;
		}

		inCutscene = false;
		var ret:Dynamic = callOnScripts('onStartCountdown', []);
		trace(ret);
		if(ret != Globals.Function_Stop) {
			if (skipCountdown || startOnTime > 0) skipArrowStartTween = true;

			//generateStaticArrows(0, skipArrowStartTween );
			//generateStaticArrows(1, skipArrowStartTween );
			
			playerStrums = new PlayField(ClientPrefs.data.middleScroll ? (FlxG.width / 2):(FlxG.width / 2 + (FlxG.width / 4)), strumLine.y, 4, boyfriend, true, cpuControlled, 0);
			opponentStrums = new PlayField(ClientPrefs.data.middleScroll?(FlxG.width / 2):(FlxG.width/2 - (FlxG.width/4)), strumLine.y, 4, dad, false, true, 1);
			if (!ClientPrefs.data.opponentStrums) {
				opponentStrums.baseAlpha = 0;

			}
			else if (ClientPrefs.data.middleScroll) {
				opponentStrums.baseAlpha = 0.35;
			}

			opponentStrums.offsetReceptors = ClientPrefs.data.middleScroll;

			playerStrums.noteHitCallback = goodNoteHit;
			opponentStrums.noteHitCallback = opponentNoteHit;

			callOnScripts('preReceptorGeneration', []); // can be used to change field properties just before the receptors get generated, so you dont have to re-generate them

			opponentStrums.generateReceptors();
			playerStrums.generateReceptors();
			
			playerStrums.fadeIn(isStoryMode || skipArrowStartTween);
			opponentStrums.fadeIn(isStoryMode || skipArrowStartTween);

			playFields.add(opponentStrums);
			playFields.add(playerStrums);

			setOnHScripts('playerStrums', playerStrums);
			setOnHScripts('opponentStrums', opponentStrums);
			setOnHScripts('playFields', playFields);

			callOnScripts('postReceptorGeneration', [isStoryMode || skipArrowStartTween]); // incase you wanna do anything JUST after

			for (i in 0...playerStrums.length) {
				setOnLuas('defaultPlayerStrumX' + i, playerStrums.members[i].x);
				setOnLuas('defaultPlayerStrumY' + i, playerStrums.members[i].y);
			}
			for (i in 0...opponentStrums.length) {
				setOnLuas('defaultOpponentStrumX' + i, opponentStrums.members[i].x);
				setOnLuas('defaultOpponentStrumY' + i, opponentStrums.members[i].y);
				//if(ClientPrefs.data.middleScroll) opponentStrums.members[i].visible = false;
			}

			modManager.receptors = [playerStrums.members, opponentStrums.members];
			callOnHScripts('preModifierRegister', []);
			modManager.registerDefaultModifiers();
			callOnHScripts('postModifierRegister', []);

			startedCountdown = true;
			Conductor.songPosition = 0;
			Conductor.songPosition -= Conductor.crochet * 5;
			setOnLuas('startedCountdown', true);
			callOnScripts('onCountdownStarted', []);

			var swagCounter:Int = 0;


			trace(startOnTime);
			if(startOnTime < 0) startOnTime = 0;

			if (startOnTime > 0) {
				clearNotesBefore(startOnTime);
				setSongTime(startOnTime - 350);
				return;
			}
			else if (skipCountdown)
			{
				setSongTime(0);
				return;
			}

			startTimer = new FlxTimer().start(Conductor.crochet / 1000, function(tmr:FlxTimer)
			{
				if (gf != null && tmr.loopsLeft % Math.round(gfSpeed * gf.danceEveryNumBeats) == 0 && gf.animation.curAnim != null && !gf.animation.curAnim.name.startsWith("sing") && !gf.stunned)
				{
					gf.dance();
				}
				if (tmr.loopsLeft % boyfriend.danceEveryNumBeats == 0 && boyfriend.animation.curAnim != null && !boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.stunned)
				{
					boyfriend.dance();
				}
				if (tmr.loopsLeft % dad.danceEveryNumBeats == 0 && dad.animation.curAnim != null && !dad.animation.curAnim.name.startsWith('sing') && !dad.stunned)
				{
					dad.dance();
				}

				var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
				introAssets.set('default', ['ready', 'set', 'go']);
				introAssets.set('pixel', ['pixelUI/ready-pixel', 'pixelUI/set-pixel', 'pixelUI/date-pixel']);

				var introAlts:Array<String> = introAssets.get('default');
				var antialias:Bool = ClientPrefs.data.antialiasing;
				if(isPixelStage) {
					introAlts = introAssets.get('pixel');
					antialias = false;
				}

				// head bopping for bg characters on Mall

				switch (swagCounter)
				{
					case 0:
						FlxG.sound.play(Paths.sound('intro3' + introSoundsSuffix), 0.6);
					case 1:
						countdownReady = new FlxSprite().loadGraphic(Paths.image(introAlts[0]));
						countdownReady.scrollFactor.set();
						countdownReady.updateHitbox();

						if (PlayState.isPixelStage)
							countdownReady.setGraphicSize(Std.int(countdownReady.width * daPixelZoom));
						
						countdownReady.screenCenter();
						countdownReady.antialiasing = antialias;
						
						insert(members.indexOf(noteGroup), countdownReady);
						FlxTween.tween(countdownReady, {/*y: countdownReady.y + 100,*/ alpha: 0}, Conductor.crochet / 1000, {
							ease: FlxEase.cubeInOut,
							onComplete: function(twn:FlxTween)
							{
								remove(countdownReady);
								countdownReady.destroy();
							}
						});
						FlxG.sound.play(Paths.sound('intro2' + introSoundsSuffix), 0.6);
						setOnHScripts('countdownReady', countdownReady);

					case 2:
						countdownSet = new FlxSprite().loadGraphic(Paths.image(introAlts[1]));
						countdownSet.scrollFactor.set();

						if (PlayState.isPixelStage)
							countdownSet.setGraphicSize(Std.int(countdownSet.width * daPixelZoom));

						countdownSet.screenCenter();
						countdownSet.antialiasing = antialias;
						insert(members.indexOf(noteGroup), countdownSet);
						FlxTween.tween(countdownSet, {/*y: countdownSet.y + 100,*/ alpha: 0}, Conductor.crochet / 1000, {
							ease: FlxEase.cubeInOut,
							onComplete: function(twn:FlxTween)
							{
								remove(countdownSet);
								countdownSet.destroy();
							}
						});
						FlxG.sound.play(Paths.sound('intro1' + introSoundsSuffix), 0.6);
						setOnHScripts('countdownSet', countdownSet);

					case 3:
						countdownGo = new FlxSprite().loadGraphic(Paths.image(introAlts[2]));
						countdownGo.scrollFactor.set();

						if (PlayState.isPixelStage)
							countdownGo.setGraphicSize(Std.int(countdownGo.width * daPixelZoom));

						countdownGo.updateHitbox();

						countdownGo.screenCenter();
						countdownGo.antialiasing = antialias;
						insert(members.indexOf(noteGroup), countdownGo);
						FlxTween.tween(countdownGo, {/*y: countdownGo.y + 100,*/ alpha: 0}, Conductor.crochet / 1000, {
							ease: FlxEase.cubeInOut,
							onComplete: function(twn:FlxTween)
							{
								remove(countdownGo);
								countdownGo.destroy();
							}
						});
						FlxG.sound.play(Paths.sound('introGo' + introSoundsSuffix), 0.6);
						setOnHScripts('countdownGo', countdownGo);
					case 4:
				}

				notes.forEachAlive(function(note:Note) {
					note.copyAlpha = false;
					note.alpha = note.multAlpha * note.playField.baseAlpha;
				});
			
				callOnScripts('onCountdownTick', [swagCounter]);

				swagCounter += 1;
				// generateSong('fresh');
			}, 5);
		}
	}
	
	public function addBehindGF(obj:FlxObject)
	{
		insert(members.indexOf(gfGroup), obj);
	}
	public function addBehindBF(obj:FlxObject)
	{
		insert(members.indexOf(boyfriendGroup), obj);
	}
	public function addBehindDad (obj:FlxObject)
	{
		insert(members.indexOf(dadGroup), obj);
	}

	public function clearNotesBefore(time:Float)
	{
		var i:Int = unspawnNotes.length - 1;
		while (i >= 0) {
			var daNote:Note = unspawnNotes[i];
			if(daNote.strumTime - 350 < time)
			{
				daNote.active = false;
				daNote.visible = false;
				daNote.ignoreNote = true;

				if(modchartObjects.exists('note${daNote.ID}'))modchartObjects.remove('note${daNote.ID}');
				daNote.kill();
				unspawnNotes.remove(daNote);
				daNote.destroy();
			}
			--i;
		}

		i = notes.length - 1;
		while (i >= 0) {
			var daNote:Note = notes.members[i];
			if(daNote.strumTime - 350 < time)
			{
				daNote.active = false;
				daNote.visible = false;
				daNote.ignoreNote = true;

				if(modchartObjects.exists('note${daNote.ID}'))modchartObjects.remove('note${daNote.ID}');
				daNote.kill();
				notes.remove(daNote, true);
				daNote.destroy();
			}
			--i;
		}
	}

	public function setSongTime(time:Float)
	{
		if(time < 0) time = 0;

		FlxG.sound.music.pause();
		vocals.pause();

		FlxG.sound.music.time = time;
		FlxG.sound.music.play();

		vocals.time = time;
		vocals.play();
		Conductor.songPosition = time;
		songTime = time;
	}

	function startNextDialogue() {
		dialogueCount++;
		callOnScripts('onNextDialogue', [dialogueCount]);
	}

	function skipDialogue() {
		callOnScripts('onSkipDialogue', [dialogueCount]);
	}

	var previousFrameTime:Int = 0;
	var lastReportedPlayheadPosition:Int = 0;
	var songTime:Float = 0;

	function startSong():Void
	{
		startingSong = false;

		previousFrameTime = FlxG.game.ticks;
		lastReportedPlayheadPosition = 0;

		FlxG.sound.playMusic(Paths.inst(PlayState.SONG.song), 1, false);
		FlxG.sound.music.onComplete = onSongComplete;
		vocals.play();

		if(startOnTime > 0)
		{
			setSongTime(startOnTime - 500);
		}
		startOnTime = 0;

		if(paused) {
			//trace('Oopsie doopsie! Paused sound');
			FlxG.sound.music.pause();
			vocals.pause();
		}

		// Song duration in a float, useful for the time left feature
		songLength = FlxG.sound.music.length;
		barSongLength = songLength;
		FlxTween.tween(timeBar, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
		FlxTween.tween(timeTxt, {alpha: 1}, 0.5, {ease: FlxEase.circOut});



		// Updating Discord Rich Presence (with Time Left)
		DiscordHandler.changePresence(detailsText, SONG.song.toLowerCase().replace('-', ' '), iconP2.getCharacter(), true, songLength);
	
		setOnScripts('songLength', songLength);
		setOnScripts('barSongLength', barSongLength);
		callOnScripts('onSongStart', []);
		trace(barSongLength);
	}

	var debugNum:Int = 0;
	private var noteTypeMap:Map<String, Bool> = new Map<String, Bool>();
	private var eventPushedMap:Map<String, Bool> = new Map<String, Bool>();

	function shouldPush(event:EventNote){
		switch(event.event){
			default:
				if (eventScripts.exists(event.event))
				{
					var eventScript:Dynamic = eventScripts.get(event.event);
					var returnVal:Any = true;
					trace(returnVal);
					if (eventScript.scriptType == 'lua')
					{
						returnVal = callScript(eventScript, "shouldPush", [event.value1, event.value2]); 
					}
					else
					{
						returnVal = callScript(eventScript, "shouldPush", [event]); 
					}
					var fuck:Bool = returnVal != false;
					trace(returnVal, returnVal != false, fuck);
					return returnVal != false;
				}
		}
		return true;
	}

	function getEvents(){
		var songData = SONG;
		var events:Array<EventNote> = [];
		var songName:String = Paths.formatToSongPath(SONG.song);
		var file:String = Paths.json(songName + '/events');
		if (FileSystem.exists(Paths.modsJson(songName + '/events')) || FileSystem.exists(file) || OpenFlAssets.exists(file)) {
		//if () {
			var eventsData:Array<Dynamic> = Song.loadFromJson('events', songName).events;
			for (event in eventsData) //Event Notes
			{
				for (i in 0...event[1].length)
				{
					var newEventNote:Array<Dynamic> = [event[0], event[1][i][0], event[1][i][1], event[1][i][2]];
					var subEvent:EventNote = {
						strumTime: newEventNote[0] + ClientPrefs.data.noteOffset,
						event: newEventNote[1],
						value1: newEventNote[2],
						value2: newEventNote[3]
					};
					if(!shouldPush(subEvent))continue;
					events.push(subEvent);
				}
			}
		// this is mainly to shut my syntax highlighting up
		}
		

		for (event in songData.events) //Event Notes
		{
			for (i in 0...event[1].length)
			{
				var newEventNote:Array<Dynamic> = [event[0], event[1][i][0], event[1][i][1], event[1][i][2]];
				var subEvent:EventNote = {
					strumTime: newEventNote[0] + ClientPrefs.data.noteOffset,
					event: newEventNote[1],
					value1: newEventNote[2],
					value2: newEventNote[3]
				};
				if(!shouldPush(subEvent))continue;
				events.push(subEvent);
			}
		}


		return events;
	}

	private function generateSong(dataPath:String):Void
	{
		songSpeedType = ClientPrefs.getGameplaySetting('scrolltype','multiplicative');

		switch(songSpeedType)
		{
			case "multiplicative":
				songSpeed = SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed', 1);
			case "constant":
				songSpeed = ClientPrefs.getGameplaySetting('scrollspeed', 1);
		}

		var songData = SONG;
		Conductor.changeBPM(songData.bpm);

		curSong = songData.song;

		if (SONG.needsVoices)
			vocals = new FlxSound().loadEmbedded(Paths.voices(PlayState.SONG.song));
		else
			vocals = new FlxSound();

		FlxG.sound.list.add(vocals);
		FlxG.sound.list.add(new FlxSound().loadEmbedded(Paths.inst(PlayState.SONG.song)));

		setOnHScripts('vocals', vocals);
		setOnHScripts('inst', FlxG.sound.music);


		notes = new FlxTypedGroup<Note>();
		noteGroup.add(notes);

		var noteData:Array<SwagSection>;

		// NEW SHIT
		noteData = songData.notes;

		var playerCounter:Int = 0;

		var daBeats:Int = 0; // Not exactly representative of 'daBeats' lol, just how much it has looped

		/*var songName:String = Paths.formatToSongPath(SONG.song);
		var file:String = Paths.json(songName + '/events');
		#if MODS_ALLOWED
		if (FileSystem.exists(Paths.modsJson(songName + '/events')) || FileSystem.exists(file)) {
		#else
		if (OpenFlAssets.exists(file)) {
		#end
			var eventsData:Array<Dynamic> = Song.loadFromJson('events', songName).events;
			for (event in eventsData) //Event Notes
			{
				for (i in 0...event[1].length)
				{
					var newEventNote:Array<Dynamic> = [event[0], event[1][i][0], event[1][i][1], event[1][i][2]];
					var subEvent:EventNote = {
						strumTime: newEventNote[0] + ClientPrefs.noteOffset,
						event: newEventNote[1],
						value1: newEventNote[2],
						value2: newEventNote[3]
					};
					subEvent.strumTime -= eventNoteEarlyTrigger(subEvent);
					if(!shouldPush(subEvent))continue;
					eventNotes.push(subEvent);
					eventPushed(subEvent);
				}
			}
		}

		for (event in songData.events) //Event Notes
		{
			for (i in 0...event[1].length)
			{
				var newEventNote:Array<Dynamic> = [event[0], event[1][i][0], event[1][i][1], event[1][i][2]];
				var subEvent:EventNote = {
					strumTime: newEventNote[0] + ClientPrefs.noteOffset,
					event: newEventNote[1],
					value1: newEventNote[2],
					value2: newEventNote[3]
				};
				subEvent.strumTime -= eventNoteEarlyTrigger(subEvent);
				if(!shouldPush(subEvent))continue;
				eventNotes.push(subEvent);
				eventPushed(subEvent);
			}
		}*/

		// loads note types
		for (section in noteData)
		{
			for (songNotes in section.sectionNotes)
			{
				var type:Dynamic = songNotes[3];
				if(!Std.isOfType(type, String)) type = ChartingState.noteTypeList[type];

				if (!noteTypeMap.exists(type)) {
					firstNotePush(type);
					noteTypeMap.set(type, true);
				}
			}
		}

		for (notetype in noteTypeMap.keys())
		{
			var doPush:Bool = false;
			var baseScriptFile:String = 'custom_notetypes/' + notetype;
			var exts = [#if LUA_ALLOWED "lua" #end];
			for (e in FunkinHScript.hscriptExts)
				exts.push(e);
			for (ext in exts)
			{
				if (doPush)
					break;
				var baseFile = '$baseScriptFile.$ext';
				var files = [#if MODS_ALLOWED Paths.modFolders(baseFile), #end Paths.getPreloadPath(baseFile)];
				for (file in files)
				{
					if (FileSystem.exists(file))
					{
						if (ext == 'lua')
						{
							var script = new FunkinLua(file, notetype);
							luaArray.push(script);
							funkyScripts.push(script);
							notetypeScripts.set(notetype, script);
							doPush = true;
						}
						else
						{
							var script = FunkinHScript.fromFile(file, notetype);
							hscriptArray.push(script);
							funkyScripts.push(script);
							notetypeScripts.set(notetype, script);
							doPush = true;
						}
						if (doPush)
							break;
					}
				}
			}
		}

		// loads events
		for(event in getEvents()){
			if (!eventPushedMap.exists(event.event))
			{
				eventPushedMap.set(event.event, true);
				firstEventPush(event);
			}
		}

		for (event in eventPushedMap.keys())
		{
			var doPush:Bool = false;
			var baseScriptFile:String = 'custom_events/' + event;
			var exts = [#if LUA_ALLOWED "lua" #end];
			for (e in FunkinHScript.hscriptExts)
				exts.push(e);
			for (ext in exts)
			{
				if (doPush)
					break;
				var baseFile = '$baseScriptFile.$ext';
				var files = [#if MODS_ALLOWED Paths.modFolders(baseFile), #end Paths.getPreloadPath(baseFile)];
				for (file in files)
				{
					if (FileSystem.exists(file))
					{
						if (ext == 'lua')
						{
							var script = new FunkinLua(file, event);
							luaArray.push(script);
							funkyScripts.push(script);
							trace("event script " + event);
							eventScripts.set(event, script);
							script.call("onLoad", []);
							doPush = true;
						}
						else
						{
							var script = FunkinHScript.fromFile(file, event);
							hscriptArray.push(script);
							funkyScripts.push(script);
							trace("event script " + event);
							eventScripts.set(event, script);
							script.call("onLoad", []);
							doPush = true;
						}
						if (doPush)
							break;
					}
				}
			}
		}
		
		for(subEvent in getEvents()){
			subEvent.strumTime -= eventNoteEarlyTrigger(subEvent);
			eventNotes.push(subEvent);
			eventPushed(subEvent);
		}
		if(eventNotes.length > 1) { //No need to sort if there's a single one or none at all
			eventNotes.sort(sortByTime);
		}

		var lastBFNotes:Array<Note> = [null,null,null,null];
		var lastDadNotes:Array<Note> = [null,null,null,null];
		// Should populate these w/ nulls depending on keycount -neb
		for (section in noteData)
		{
			for (songNotes in section.sectionNotes)
			{
				var daStrumTime:Float = songNotes[0];
				var daNoteData:Int = Std.int(songNotes[1] % 4);

				var gottaHitNote:Bool = section.mustHitSection;

				if (songNotes[1] > 3)
				{
					gottaHitNote = !section.mustHitSection;
				}

				var oldNote:Note;
				if (unspawnNotes.length > 0)
					oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
				else
					oldNote = null;

				var pixelStage = isPixelStage;
				// var skin = arrowSkin;

				var type:Dynamic = songNotes[3];
				if(!Std.isOfType(type, String)) type = ChartingState.noteTypeList[type]; 

				// TODO: maybe make a checkNoteType n shit but idfk im lazy
				// or maybe make a "Transform Notes" event which'll make notes which don't change texture change into the specified one

				var swagNote:Note = new Note(daStrumTime, daNoteData, oldNote, false, false, gottaHitNote ? 0 : 1);
				swagNote.row = Conductor.secsToRow(daStrumTime);
				if(noteRows[gottaHitNote?0:1][swagNote.row]==null)
					noteRows[gottaHitNote?0:1][swagNote.row]=[];
				noteRows[gottaHitNote ? 0 : 1][swagNote.row].push(swagNote);
				swagNote.mustPress = gottaHitNote;					
				swagNote.sustainLength = songNotes[2];
				if(gottaHitNote){
					var lastBFNote = lastBFNotes[swagNote.noteData];
					if(lastBFNote!=null){
						if(Math.abs(swagNote.strumTime-lastBFNote.strumTime)<=3 ){
							swagNote.kill();
							continue;
						}
					}
					lastBFNotes[swagNote.noteData]=swagNote;
				}else{
					var lastDadNote = lastDadNotes[swagNote.noteData];
					if(lastDadNote!=null){
						if(Math.abs(swagNote.strumTime-lastDadNote.strumTime)<=3 ){
							swagNote.kill();
							continue;
						}
					}
					lastDadNotes[swagNote.noteData]=swagNote;
				}
				
				swagNote.gfNote = (section.gfSection && (songNotes[1]<4));


				swagNote.noteType = type;

				swagNote.scrollFactor.set();
				// swagNote.player = gottaHitNote ? 0 : 1;

				var susLength:Float = swagNote.sustainLength;

				susLength = susLength / Conductor.stepCrochet;
				swagNote.ID = unspawnNotes.length;
				modchartObjects.set('note${swagNote.ID}', swagNote);
				unspawnNotes.push(swagNote);

				if(swagNote.noteScript != null && swagNote.noteScript.scriptType == 'lua'){
					callScript(swagNote.noteScript, 'setupNote', [
						unspawnNotes.indexOf(swagNote),
						Math.abs(swagNote.noteData),
						swagNote.noteType,
						swagNote.isSustainNote,
						swagNote.ID
					]);
				}

				var floorSus:Int = Math.round(susLength);
				if(floorSus > 0) {
					for (susNote in 0...floorSus+1)
					{
						oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];

						var sustainNote:Note = new Note(daStrumTime + (Conductor.stepCrochet * susNote) + (Conductor.stepCrochet / FlxMath.roundDecimal(songSpeed, 2)), daNoteData, oldNote, true, false, gottaHitNote ? 0 : 1);
						sustainNote.mustPress = gottaHitNote;
						sustainNote.gfNote = swagNote.gfNote;
						sustainNote.noteType = type;
						if(sustainNote==null || !sustainNote.alive)break;
						sustainNote.ID = unspawnNotes.length;
						modchartObjects.set('note${sustainNote.ID}', sustainNote);
						sustainNote.scrollFactor.set();
						swagNote.tail.push(sustainNote);
						sustainNote.parent = swagNote;
						// sustainNote.player = sustainNote.parent.player;
						unspawnNotes.push(sustainNote);
						if (sustainNote.noteScript != null && sustainNote.noteScript.scriptType == 'lua')
						{
							callScript(sustainNote.noteScript, 'setupNote', [
								unspawnNotes.indexOf(sustainNote),
								Math.abs(sustainNote.noteData),
								sustainNote.noteType,
								sustainNote.isSustainNote,
								sustainNote.ID
							]);
						}

						if (sustainNote.mustPress)
						{
							sustainNote.x += FlxG.width / 2; // general offset
						}
						else if(ClientPrefs.data.middleScroll)
						{
							sustainNote.x += 310;
							if(daNoteData > 1) //Up and Right
							{
								sustainNote.x += FlxG.width / 2 + 25;
							}
						}
					}
				}

				// arrowSkin = skin;

				if (swagNote.mustPress)
				{
					swagNote.x += FlxG.width / 2; // general offset
				}
				else if(ClientPrefs.data.middleScroll)
				{
					swagNote.x += 310;
					if(daNoteData > 1) //Up and Right
					{
						swagNote.x += FlxG.width / 2 + 25;
					}
				}

			}
			daBeats += 1;
		}
		lastDadNotes = null;
		lastBFNotes = null;

		// trace(unspawnNotes.length);
		// playerCounter += 1;

		unspawnNotes.sort(sortByShit);

		checkEventNote();
		generatedMusic = true;
	}

	// everything returned here gets preloaded by the preloader up-top ^
	function preloadEvent(event:EventNote):Array<AssetPreload>{
		var preload:Array<AssetPreload> = [];
		switch(event.event){
			case "Change Character":
				return returnCharacterPreload(event.value2);
		}
		return preload;
	}

	function eventPushed(event:EventNote) {
		switch(event.event) {
			case 'Play Video':
				playVideo(event.value1, false);
			case 'Change Character':
				var charType:Int = 0;
				switch(event.value1.toLowerCase()) {
					case 'gf' | 'girlfriend' | '1':
						charType = 2;
					case 'dad' | 'opponent' | '0':
						charType = 1;
					default:
						charType = Std.parseInt(event.value1);
						if(Math.isNaN(charType)) charType = 0;
				}

				addCharacterToList(event.value2, charType);
			default:
				if (eventScripts.exists(event.event))
				{
					var eventScript:Dynamic = eventScripts.get(event.event);
					if (eventScript.scriptType == 'lua')
					{
						callScript(eventScript, "onPush",[event.value1, event.value2]); 
					}
					else
					{
						callScript(eventScript, "onPush", [event]); 
					}
				}

		}
	}

	function firstNotePush(type:String){
		switch(type){
			default:
				if (notetypeScripts.exists(type))
				{
					var script:Dynamic = notetypeScripts.get(type);
					callScript(script, "onLoad", []);
				}
		}
	}

	function firstEventPush(event:EventNote){
		switch (event.event)
		{
			default:
				// should PROBABLY turn this into a function, callEventScript(eventNote, "func") or something, idk
				if (eventScripts.exists(event.event))
				{
					var eventScript:Dynamic = eventScripts.get(event.event);
					if (eventScript.scriptType == 'lua')
					{
						callScript(eventScript, "onLoad", [event.value1, event.value2]);
					}
					else
					{
						callScript(eventScript, "onLoad", [event]);
					}
				}
		}
	}

	function eventNoteEarlyTrigger(event:EventNote):Float {
		var returnedValue:Float = callOnScripts('eventEarlyTrigger', [event.event, event.value1, event.value2]);

		if (eventScripts.exists(event.event)){
			var eventScript:Dynamic = eventScripts.get(event.event);
			if(eventScript.scriptType == 'lua'){
				returnedValue = callScript(eventScript, "getOffset", [event.value1, event.value2]);
			}else{
				returnedValue = callScript(eventScript, "getOffset", [event]);
			}
		}
		if(returnedValue != 0)
			return returnedValue;

		switch(event.event) {
			case 'Kill Henchmen': //Better timing so that the kill sound matches the beat intended
				return 280; //Plays 280ms before the actual position
		}
		return 0;
	}

	function sortByShit(Obj1:Note, Obj2:Note):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}

	function laserSort(Obj1:Float, Obj2:Float):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1, Obj2);
	}

	function sortByTime(Obj1:EventNote, Obj2:EventNote):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}

	public var skipArrowStartTween:Bool = false; //for lua

	function removeStatics(player:Int)
	{
		var isPlayer:Bool = player==1;
		for(field in playFields.members){
			if(field.isPlayer==isPlayer || player==-1){
				field.clearReceptors();
			}
		}
	}

	// player 0 is opponent player 1 is player. Set to -1 to affect both players

	function resetStrumPositions(player:Int, ?baseX:Float){
		if(!generatedMusic)return;

		var isPlayer:Bool = player == 1;
		for (field in playFields.members)
		{
			if (field.isPlayer == isPlayer || player == -1)
			{
				var x = field.baseX;
				if(baseX!=null)x = baseX;

				field.forEachAlive( function(strum:StrumNote){
					strum.x = x;
					strum.postAddedToGroup();
					if (field.offsetReceptors)
						field.doReceptorOffset(strum);
				});
			}
		}
		
	}
	function regenStaticArrows(player:Int){
		var isPlayer:Bool = player==1;
		for(field in playFields.members){
			if(field.isPlayer==isPlayer || player==-1){
				field.generateReceptors();
				field.fadeIn(true);
			}
		}
	}
	
	override function openSubState(SubState:FlxSubState)
	{
		if (paused)
		{
			if (FlxG.sound.music != null)
			{
				FlxG.sound.music.pause();
				vocals.pause();
			}

			for (tween in modchartTweens) {
				tween.active = false;
			}
			for (timer in modchartTimers) {
				timer.active = false;
			}

		}
		callOnHScripts('onSubstateOpen', []);
		super.openSubState(SubState);
	}

	override function closeSubState()
	{
		if (paused)
		{
			if (FlxG.sound.music != null && !startingSong)
			{
				resyncVocals();
			}

			FlxTimer.globalManager.forEach(function(tmr:FlxTimer) if(!tmr.finished) tmr.active = true);
			FlxTween.globalManager.forEach(function(twn:FlxTween) if(!twn.finished) twn.active = true);

			paused = false;
			callOnScripts('onResume', []);

			PsychVideoSprite.globalResume();


			if (startTimer != null && startTimer.finished)
			{
				DiscordHandler.changePresence(detailsText, SONG.song.toLowerCase().replace('-', ' '), iconP2.getCharacter(), true, songLength - Conductor.songPosition - ClientPrefs.data.noteOffset);
			}
			else
			{
				DiscordHandler.changePresence(detailsText, SONG.song.toLowerCase().replace('-', ' '), iconP2.getCharacter());
			}

		}
		callOnHScripts('onSubstateClose', []);

		super.closeSubState();
	}

	override public function onFocus():Void
	{

		if (health > 0 && !paused)
		{
			if (Conductor.songPosition > 0.0)
			{
				DiscordHandler.changePresence(detailsText, SONG.song.toLowerCase().replace('-', ' '), iconP2.getCharacter(), true, songLength - Conductor.songPosition - ClientPrefs.data.noteOffset);
			}
			else
			{
				DiscordHandler.changePresence(detailsText, SONG.song.toLowerCase().replace('-', ' '), iconP2.getCharacter());
			}
		}


		super.onFocus();
	}

	override public function onFocusLost():Void
	{

		if (health > 0 && !paused)
		{
			DiscordHandler.changePresence(detailsPausedText, SONG.song.toLowerCase().replace('-', ' '), iconP2.getCharacter());
		}


		super.onFocusLost();
	}

	function resyncVocals():Void
	{
		if(finishTimer != null) return;

		vocals.pause();

		FlxG.sound.music.play();
		Conductor.songPosition = FlxG.sound.music.time;
		vocals.time = Conductor.songPosition;
		vocals.play();

	}

	public var paused:Bool = false;
	public var canReset:Bool = true;
	var startedCountdown:Bool = false;
	var canPause:Bool = true;

	override public function update(elapsed:Float)
	{

		if (generatedMusic && !endingSong && !isCameraOnForcedPos)
		{
			moveCameraSection();
		}

		if(!inCutscene && !paused) {
			var lerpVal:Float = FlxMath.bound(elapsed * 2.4 * cameraSpeed, 0, 1);

			camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));
			if(!startingSong && !endingSong && boyfriend.animation.curAnim != null && boyfriend.animation.curAnim.name.startsWith('idle')) {
				boyfriendIdleTime += elapsed;
				if(boyfriendIdleTime >= 0.15) { // Kind of a mercy thing for making the achievement easier to get as it's apparently frustrating to some playerss
					boyfriendIdled = true;
				}
			} else {
				boyfriendIdleTime = 0;
			}
		}

		displayedHealth = health;

		for(key in notetypeScripts.keys()){
			var script = notetypeScripts.get(key);
			script.call("update", [elapsed]);
		}

		for (key in eventScripts.keys())
		{
			var script = eventScripts.get(key);
			script.call("update", [elapsed]);
		}
		
		callOnHScripts('update', [elapsed]);
		callOnScripts('onUpdate', [elapsed]);

		#if debug
		if (FlxG.keys.justPressed.SIX) {cpuControlled = !cpuControlled; botplayTxt.visible = !botplayTxt.visible;}
		#end
		super.update(elapsed);

		checkEventNote();

		setOnHScripts('curDecStep', curDecStep);
		setOnHScripts('curDecBeat', curDecBeat);
		setOnHScripts('curStep', curStep);
		setOnHScripts('curBeat', curBeat);
		

		// if(botplayTxt.visible) {
		// 	botplaySine += 180 * elapsed;
		// 	botplayTxt.alpha = 1 - Math.sin((Math.PI * botplaySine) / 180);
		// }

		if (controls.PAUSE && startedCountdown && canPause)
		{
			var ret:Dynamic = callOnScripts('onPause', []);

			FlxTimer.globalManager.forEach(function(tmr:FlxTimer) if(!tmr.finished) tmr.active = false);
			FlxTween.globalManager.forEach(function(twn:FlxTween) if(!twn.finished) twn.active = false);

			if(ret != Globals.Function_Stop) {
				
				persistentUpdate = false;
				persistentDraw = true;
				paused = true;

				PsychVideoSprite.globalPause();

				// 1 / 1000 chance for Gitaroo Man easter egg
				/*if (FlxG.random.bool(0.1))
				{
					// gitaroo man easter egg
					cancelMusicFadeTween();
					MusicBeatState.switchState(new GitarooPause());
				}
				else {*/
				if(FlxG.sound.music != null) {
					FlxG.sound.music.pause();
					vocals.pause();
				}
				openSubState(new PauseSubState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));
				//}


				DiscordHandler.changePresence(detailsPausedText, SONG.song.toLowerCase().replace('-', ' '), iconP2.getCharacter());

			}
		}

		if (!ProgressionHandler.isRodent) {
			if (FlxG.keys.anyJustPressed(debugKeysChart) && !endingSong && !inCutscene && !startingSong)
			{
				openChartEditor();
			}
		}



		var mult:Float = FlxMath.lerp(1, iconP1.scale.x, FlxMath.bound(1 - (elapsed * 27), 0, 1));
		iconP1.scale.set(mult, mult);
		iconP1.updateHitbox();

		var mult:Float = FlxMath.lerp(1, iconP2.scale.x, FlxMath.bound(1 - (elapsed * 27), 0, 1));
		iconP2.scale.set(mult, mult);
		iconP2.updateHitbox();

		var iconOffset:Int = 26;

		iconP1.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01)) + (150 * iconP1.scale.x - 150) / 2 - iconOffset;
		iconP2.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01)) - (150 * iconP2.scale.x) / 2 - iconOffset * 2;

		if (health > 2)
			health = 2;

		var percent = (health / 2) * 100;
		if (percent < 20)
			iconP1.animation.curAnim.curFrame = 1;
		else
			iconP1.animation.curAnim.curFrame = 0;

		if (percent > 80)
			iconP2.animation.curAnim.curFrame = 1;
		else
			iconP2.animation.curAnim.curFrame = 0;

		if (!ProgressionHandler.isRodent) {

			if (FlxG.keys.anyJustPressed(debugKeysCharacter) && !endingSong && !inCutscene) {
				persistentUpdate = false;
				paused = true;
				cancelMusicFadeTween();
				MusicBeatState.switchState(new CharacterEditorState(SONG.player2));
			}
		}

		if (startingSong)
		{
			if (startedCountdown)
			{
				Conductor.songPosition += FlxG.elapsed * 1000;
				if (Conductor.songPosition >= 0)
					startSong();
			}
		}
		else
		{
			Conductor.songPosition += FlxG.elapsed * 1000;

			if (!paused)
			{
				songTime += FlxG.game.ticks - previousFrameTime;
				previousFrameTime = FlxG.game.ticks;

				// Interpolation type beat
				if (Conductor.lastSongPos != Conductor.songPosition)
				{
					songTime = (songTime + Conductor.songPosition) / 2;
					Conductor.lastSongPos = Conductor.songPosition;
					// Conductor.songPosition += FlxG.elapsed * 1000;
					// trace('MISSED FRAME');
				}

				if(updateTime) {
					var curTime:Float = Conductor.songPosition - ClientPrefs.data.noteOffset;
					if(curTime < 0) curTime = 0;
					songPercent = (curTime / barSongLength);

					var songCalc:Float = (barSongLength - curTime);
					if(ClientPrefs.data.timeBarType == 'Time Elapsed') songCalc = curTime;

					var secondsTotal:Int = Math.floor(songCalc / 1000);
					if(secondsTotal < 0) secondsTotal = 0;

					if(ClientPrefs.data.timeBarType != 'Song Name')
						timeTxt.text = FlxStringUtil.formatTime(secondsTotal, false);

					if (timeBitmapTxt.visible) {
						timeBitmapTxt.text = FlxStringUtil.formatTime(secondsTotal, false);
					}
				}
			}

			// Conductor.lastSongPos = FlxG.sound.music.time;
		}

		if (camZooming)
		{
			FlxG.camera.zoom = FlxMath.lerp(defaultCamZoom, FlxG.camera.zoom, FlxMath.bound(1 - (elapsed * 3.125 * camZoomingDecay), 0, 1));
			camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, FlxMath.bound(1 - (elapsed * 3.125 * camZoomingDecay), 0, 1));
			camOverlay.zoom = camHUD.zoom;
		}

		FlxG.watch.addQuick("beatShit", curBeat);
		FlxG.watch.addQuick("stepShit", curStep);

		// RESET = Quick Game Over Screen
		if (!ClientPrefs.data.noReset && controls.RESET && canReset && !inCutscene && startedCountdown && !endingSong)
		{
			health = 0;
			trace("RESET = True");
		}
		doDeathCheck();

		modManager.updateTimeline(curDecStep);
		modManager.update(elapsed);

		if (unspawnNotes[0] != null)
		{
			var time:Float = spawnTime;//shit be werid on 4:3
			if(songSpeed < 1) time /= songSpeed;

			while (unspawnNotes.length > 0 && unspawnNotes[0].strumTime - Conductor.songPosition < time)
			{
				var dunceNote:Note = unspawnNotes[0];
				var doSpawn:Bool= true;
				if(dunceNote.noteScript != null && dunceNote.noteScript.scriptType == 'lua'){
					doSpawn = callScript(dunceNote.noteScript, "spawnNote", [dunceNote])!= Globals.Function_Stop;
				}
				if (doSpawn)
					doSpawn = callOnHScripts('onSpawnNote', [dunceNote]) != Globals.Function_Stop;
				if(doSpawn){
					if(dunceNote.desiredPlayfield!=null)
						dunceNote.desiredPlayfield.addNote(dunceNote);
					else if (dunceNote.parent != null && dunceNote.parent.playField!=null)
						dunceNote.parent.playField.addNote(dunceNote);
					else{
						for(field in playFields.members){
							if(field.isPlayer == dunceNote.mustPress){
								field.addNote(dunceNote);
								break;
							}
						}
					}
					if(dunceNote.playField==null){
						var deadNotes:Array<Note> = [dunceNote];
						for(note in dunceNote.tail)
							deadNotes.push(note);
						
						for(note in deadNotes){
							note.active = false;
							note.visible = false;
							note.ignoreNote = true;

							if (modchartObjects.exists('note${note.ID}'))modchartObjects.remove('note${note.ID}');
							note.kill();
							unspawnNotes.remove(note);
							note.destroy();
						}
						break;
					}
					notes.insert(0, dunceNote);
					dunceNote.spawned=true;
					var index:Int = unspawnNotes.indexOf(dunceNote);
					unspawnNotes.splice(index, 1);
					callOnLuas('onSpawnNote', [
						notes.members.indexOf(dunceNote),
						dunceNote.noteData,
						dunceNote.noteType,
						dunceNote.isSustainNote,
						dunceNote.ID
					]);
					callOnHScripts('onSpawnNotePost', [dunceNote]);
					if (dunceNote.noteScript != null)
					{
						var script:Dynamic = dunceNote.noteScript;
						if (script.scriptType == 'lua')
						{
							callScript(script, 'postSpawnNote', [
								notes.members.indexOf(dunceNote),
								Math.abs(dunceNote.noteData),
								dunceNote.noteType,
								dunceNote.isSustainNote,
								dunceNote.ID
							]);
						}
						else
						{
							callScript(script, "postSpawnNote", [dunceNote]);
						}
					}
				}else{
					var deadNotes:Array<Note> = [dunceNote];
					for(note in dunceNote.tail)
						deadNotes.push(note);
					
					for(note in deadNotes){
						note.active = false;
						note.visible = false;
						note.ignoreNote = true;

						if (modchartObjects.exists('note${note.ID}'))modchartObjects.remove('note${note.ID}');
						note.kill();
						unspawnNotes.remove(note);
						note.destroy();
					}
				}
			}
		}

		if(startedCountdown){
			opponentStrums.forEachAlive(function(strum:StrumNote)
				{
					var pos = modManager.getPos(0, 0, 0, curDecBeat, strum.noteData, 1, strum, [], strum.vec3Cache);
					modManager.updateObject(curDecBeat, strum, pos, 1);
					strum.x = pos.x + scriptedStrumOffsets[strum.noteData].x;
					strum.y = pos.y + scriptedStrumOffsets[strum.noteData].y;
				});
				playerStrums.forEachAlive(function(strum:StrumNote)
				{
					var pos = modManager.getPos(0, 0, 0, curDecBeat, strum.noteData, 0, strum, [], strum.vec3Cache);
					modManager.updateObject(curDecBeat, strum, pos, 0);
					strum.x = pos.x + scriptedStrumOffsets[strum.noteData].x;
					strum.y = pos.y + scriptedStrumOffsets[strum.noteData].y;
				});		
		}

		if (generatedMusic)
		{
			if (!inCutscene) {
				if(!cpuControlled) {
					keyShit();
				} else if(boyfriend.holdTimer > Conductor.stepCrochet * 0.0011 * boyfriend.singDuration && boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.animation.curAnim.name.endsWith('miss')) {
					boyfriend.dance();
					//boyfriend.animation.curAnim.finish();
				}
			}


			var fakeCrochet:Float = (60 / SONG.bpm) * 1000;
			notes.forEachAlive(function(daNote:Note)
			{
				var field = daNote.playField;

				var strumX:Float = field.members[daNote.noteData].x;
				var strumY:Float = field.members[daNote.noteData].y;
				var strumAngle:Float = field.members[daNote.noteData].angle;
				var strumDirection:Float = field.members[daNote.noteData].direction;
				var strumAlpha:Float = field.members[daNote.noteData].alpha;
				var strumScroll:Bool = field.members[daNote.noteData].downScroll;

				strumX += daNote.offsetX * (daNote.scale.x / daNote.baseScaleX);
				strumY += daNote.offsetY;
				strumAngle += daNote.offsetAngle;
				strumAlpha *= daNote.multAlpha;
				var pN:Int = daNote.mustPress ? 0 : 1;
				var pos = modManager.getPos(daNote.strumTime, modManager.getVisPos(Conductor.songPosition, daNote.strumTime, songSpeed),
					daNote.strumTime - Conductor.songPosition, curDecBeat, daNote.noteData, pN, daNote, [], daNote.vec3Cache);

					// trace(modManager.getVisPos(Conductor.songPosition, daNote.strumTime, songSpeed));

				modManager.updateObject(curDecBeat, daNote, pos, pN);
				pos.x += daNote.offsetX;
				pos.y += daNote.offsetY;
				daNote.x = pos.x + scriptedNoteOffsets[daNote.noteData].x;
				daNote.y = pos.y + scriptedNoteOffsets[daNote.noteData].y;
				if (daNote.isSustainNote)
				{
					var futureSongPos = Conductor.songPosition + 75;
					var diff = daNote.strumTime - futureSongPos;
					var vDiff = modManager.getVisPos(futureSongPos, daNote.strumTime, songSpeed);

					var nextPos = modManager.getPos(daNote.strumTime, vDiff, diff, Conductor.getStep(futureSongPos) / 4, daNote.noteData, pN, daNote, [],
						daNote.vec3Cache);
					nextPos.x += daNote.offsetX + scriptedNoteOffsets[daNote.noteData].x;
					nextPos.y += daNote.offsetY + scriptedNoteOffsets[daNote.noteData].y;
					var diffX = (nextPos.x - pos.x);
					var diffY = (nextPos.y - pos.y);
					var rad = Math.atan2(diffY, diffX);
					var deg = rad * (180 / Math.PI);
					if (deg != 0)
						daNote.mAngle = (deg + 90);
					else
						daNote.mAngle = 0;
				}

				if(field.inControl && field.autoPlayed){
					if(!daNote.wasGoodHit && !daNote.ignoreNote){
						if(daNote.isSustainNote){
							if(daNote.canBeHit)
								field.noteHitCallback(daNote, field);
							
						}else{
							if(daNote.strumTime <= Conductor.songPosition)
								field.noteHitCallback(daNote, field);
							
						}
					}
					
				}

				// Kill extremely late notes and cause misses
				if (Conductor.songPosition > noteKillOffset + daNote.strumTime){
					daNote.garbage = true;
					if (daNote.playField != null && daNote.playField.playerControls && !daNote.playField.autoPlayed && !daNote.ignoreNote && !endingSong && (daNote.tooLate || !daNote.wasGoodHit)){
						noteMiss(daNote);
					}
				}
				if (daNote.garbage)
				{
					disposeNote(daNote);
				}
			});
		}

		#if debug
		if(!endingSong && !startingSong) {
			if (FlxG.keys.justPressed.ONE) {
				KillNotes();
				FlxG.sound.music.onComplete();
			}
			if(FlxG.keys.justPressed.TWO) { //Go 10 seconds into the future :O
				setSongTime(Conductor.songPosition + 10000);
				clearNotesBefore(Conductor.songPosition);
			}
		}
		#end

		setOnLuas('cameraX', camFollowPos.x);
		setOnLuas('cameraY', camFollowPos.y);
		setOnScripts('botPlay', cpuControlled);
		callOnScripts('onUpdatePost', [elapsed]);
		for (i in shaderUpdates){
			i(elapsed);
		}
	}

	var subTimer:FlxTimer;

	//super basic buts thats fine
	public function generateSubs(text:String,length:Float) {
		subtitleText.visible = true;
		subtitleText.text = text;
		subtitleText.updateHitbox();

		subtitleText.y = FlxG.height - subtitleText.height + -150;
		
		subTimer.cancelTmr();

		subTimer = new FlxTimer().start(length, Void -> {
			subtitleText.visible = false;
			subtitleText.text = '';
		});


	}


	//todo we needa to fix the mem leak with playfield shit
	private function disposeNote(note:Note) 
	{
		note.active = false;
		note.visible = false;
		if(modchartObjects.exists('note${note.ID}'))modchartObjects.remove('note${note.ID}');
		note.kill();
		notes.remove(note, true);
		note.destroy();
		note = null;

		//trace('kill!' + note);

	}

	function openChartEditor()
	{
		persistentUpdate = false;
		paused = true;
		cancelMusicFadeTween();
		MusicBeatState.switchState(new ChartingState());
		chartingMode = true;


		DiscordHandler.changePresence("Chart Editor", null, null, true);

	}

	function updateScoreBar()
	{
		if(allowedToUpdateScoreTXT)
		{
			uiCallFunction((ui:BaseUI)-> {ui.onUpdateScore();});
		}
	}

	public var isDead:Bool = false; //Don't mess with this on Lua!!!
	function doDeathCheck(?skipHealthCheck:Bool = false) {
		if (((skipHealthCheck && instakillOnMiss) || health <= 0) && !practiceMode && !isDead)
		{
			var ret:Dynamic = callOnScripts('onGameOver', []);
			if(ret != Globals.Function_Stop) {
				boyfriend.stunned = true;
				deathCounter++;

				paused = true;

				vocals.stop();
				FlxG.sound.music.stop();

				persistentUpdate = false;
				persistentDraw = false;
				FlxTimer.globalManager.clear();
				FlxTween.globalManager.clear();
				for (tween in modchartTweens) {
					tween.active = true;
				}
				for (timer in modchartTimers) {
					timer.active = true;
				}
				switch (SONG.song.toLowerCase()) {
					case 'obituary':
						if (Conductor.songPosition >= 92527) {
							FlxG.sound.music.volume = 0;
							vocals.volume = 0;
							dad.stunned = true;
							boyfriend.stunned = true;
							boyfriend.animation?.stop();
							dad.animation?.stop();
							boyfriend.playAnim('ow',true);
							dad.playAnim('idle',true);
	
							
							FlxG.sound.play(Paths.sound('fnf_loss_sfx'));

							var sound = Paths.sound('obDeath1');
							new FlxTimer().start((sound.length * 0.001)/2,Void->{
								new FlxTimer().start((sound.length * 0.001) - 0.1, Void-> {
									triggerEventNote('Change Character','dad','p2exe');
									dad.stunned = true;
									dad.playAnim('gameover',true);
								});

								(FlxG.sound.play(sound)).onComplete = ()->{openSubState(new ObituaryGameOver());}
							});




						}
						else {
							openSubState(new GameOverSubstate(boyfriend.getScreenPosition().x - boyfriend.positionArray[0], boyfriend.getScreenPosition().y - boyfriend.positionArray[1], camFollowPos.x, camFollowPos.y));
						}
						

					default:
						openSubState(new GameOverSubstate(boyfriend.getScreenPosition().x - boyfriend.positionArray[0], boyfriend.getScreenPosition().y - boyfriend.positionArray[1], camFollowPos.x, camFollowPos.y));
				}
				

				// MusicBeatState.switchState(new GameOverState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));


				// Game Over doesn't get his own variable because it's only used here
				DiscordHandler.changePresence("Game Over - " + detailsText, SONG.song.toLowerCase().replace('-', ' '), iconP2.getCharacter());

				isDead = true;
				return true;
			}
		}
		return false;
	}

	public function checkEventNote() {
		while(eventNotes.length > 0) {
			var leStrumTime:Float = eventNotes[0].strumTime;
			if(Conductor.songPosition < leStrumTime) {
				break;
			}

			var value1:String = '';
			if(eventNotes[0].value1 != null)
				value1 = eventNotes[0].value1;

			var value2:String = '';
			if(eventNotes[0].value2 != null)
				value2 = eventNotes[0].value2;

			triggerEventNote(eventNotes[0].event, value1, value2);
			eventNotes.shift();
		}
	}

	public function getControl(key:String) {
		var pressed:Bool = Reflect.getProperty(controls, key);
		//trace('Control result: ' + pressed);
		return pressed;
	}

	function changeCharacter(name:String, charType:Int){
		switch(charType) {
			case 0:
				if(boyfriend.curCharacter != name) {
					// shiftFocus:Bool = focusedChar==boyfriend;
					var oldChar = boyfriend;
					if(!boyfriendMap.exists(name)) {
						addCharacterToList(name, charType);
					}

					var lastAlpha:Float = boyfriend.alpha;
					boyfriend.alpha = 0.00001;
					boyfriend = boyfriendMap.get(name);
					boyfriend.alpha = lastAlpha;
					//if(shiftFocus)focusedChar=boyfriend;
					iconP1.changeIcon(boyfriend.healthIcon);
					for(field in playFields.members){
						if(field.owner==oldChar)field.owner=boyfriend;
					}
				}
				setOnLuas('boyfriendName', boyfriend.curCharacter);
				setOnScripts('boyfriend', boyfriend);
				setOnScripts('boyfriendGroup', boyfriendGroup);

			case 1:
				if(dad.curCharacter != name) {
					//var shiftFocus:Bool = focusedChar==dad;
					var oldChar = dad;
					if(!dadMap.exists(name)) {
						addCharacterToList(name, charType);
					}

					var wasGf:Bool = dad.curCharacter.startsWith('gf');
					var lastAlpha:Float = dad.alpha;
					dad.alpha = 0.00001;
					dad = dadMap.get(name);
					if(!dad.curCharacter.startsWith('gf')) {
						if(wasGf && gf != null) {
							gf.visible = true;
						}
					} else if(gf != null) {
						gf.visible = false;
					}
					//if(shiftFocus)focusedChar=dad;
					dad.alpha = lastAlpha;
					iconP2.changeIcon(dad.healthIcon);
					for (field in playFields.members)
					{
						if (field.owner == oldChar)
							field.owner = dad;
					}
				}
				setOnLuas('dadName', dad.curCharacter);
				setOnScripts('dad', dad);
				setOnScripts('dadGroup', dadGroup);

			case 2:
				if(gf != null)
				{
					if(gf.curCharacter != name)
					{
						//var shiftFocus:Bool = focusedChar==gf;
						var oldChar = gf;
						if(!gfMap.exists(name))
						{
							addCharacterToList(name, charType);
						}

						var lastAlpha:Float = gf.alpha;
						gf.alpha = 0.00001;
						gf = gfMap.get(name);
						gf.alpha = lastAlpha;
						//if(shiftFocus)focusedChar=gf;
						for (field in playFields.members)
						{
							if (field.owner == oldChar)
								field.owner = gf;
						}
					}
					setOnLuas('gfName', gf.curCharacter);
					setOnScripts('gf', gf);
					setOnScripts('gfGroup', gfGroup);
				}
		}
		reloadHealthBarColors();
	}

	var tweenCamZoomTwn:FlxTween;


	public function triggerEventNote(eventName:String, value1:String, value2:String) {
		switch(eventName) {
			case 'changeUI':
				//this dump exclusion stuff sucks data todo redo it
				var uiDumpExclusions:Array<FlxSprite> = [iconP1,iconP2,botplayTxt,timeBar,timeBarBG,timeTxt,timeBitmapTxt];
				var curUI = BaseUI.getCurrentUI();
				curUI.destroy();
				
				for (i in 0...uiGroup.members.length) {
					var spr = uiGroup.members[0];
					if (!uiDumpExclusions.contains(spr)) {
						spr.kill();
						uiGroup.remove(spr, true);
						spr.destroy();
					}
				}

				createUIClass(value1);
				uiCallFunction((ui:BaseUI)-> {ui.sort();});

				// for (i in uiDumpExclusions) {
				// 	uiGroup.remove(i, true);
				// 	uiGroup.add(i);
				// }



			case 'tweenCamZoom':
				tweenCamZoomTwn.cancelTween();
				tweenCamZoomTwn = FlxTween.tween(FlxG.camera, {zoom: Std.parseFloat(value1.split(',')[0])},Std.parseFloat(value1.split(',')[1]), {ease: FunkinLua.getFlxEaseByString(value2), onUpdate: function(f:FlxTween) {
					defaultCamZoom = FlxG.camera.zoom;
				}});

			case 'Camera Flash':
				try {
					var camera:Null<FlxCamera> = Reflect.getProperty(this,value1);
					if (camera == null) camera = FlxG.camera;

					var duration = Std.parseFloat(value2.split(',')[0]);
					if(Math.isNaN(duration)) duration = 0.5;

					var color = FlxColor.fromString(value1.split(',')[0]);
					if (value2.split(',')[1] == '') color = FlxColor.WHITE;

					camera.flash(color, duration);
				}
				catch(e) {}

			case 'subtitles':
				generateSubs(value2,Std.parseFloat(value1.split(',')[0]));
			case 'Obituary':
				if (value1 == 'toggleRodent') ProgressionHandler.isRodent = false;
			case 'Play Video':
				playVideo(value1);
			case 'Change Focus':
				switch (value1.toLowerCase().trim()) {
					case 'dad' | 'opponent':
						forcedCharFocus = dad;
					case 'bf' | 'boyfriend':
						forcedCharFocus = boyfriend;
					case 'gf' | 'girlfriend':
						forcedCharFocus = gf;
					default:
						forcedCharFocus = null;
				}
			case 'Game Flash':
				var dur:Float = Std.parseFloat(value2);
				if(Math.isNaN(dur)) dur = 0.5;
				FlxG.camera.flash(FlxColor.fromString(value1), dur);
			case 'Hey!':
				var value:Int = 2;
				switch(value1.toLowerCase().trim()) {
					case 'bf' | 'boyfriend' | '0':
						value = 0;
					case 'gf' | 'girlfriend' | '1':
						value = 1;
				}

				var time:Float = Std.parseFloat(value2);
				if(Math.isNaN(time) || time <= 0) time = 0.6;

				if(value != 0) {
					if(dad.curCharacter.startsWith('gf')) { //Tutorial GF is actually Dad! The GF is an imposter!! ding ding ding ding ding ding ding, dindinding, end my suffering
						dad.playAnim('cheer', true);
						dad.specialAnim = true;
						dad.heyTimer = time;
					} else if (gf != null) {
						gf.playAnim('cheer', true);
						gf.specialAnim = true;
						gf.heyTimer = time;
					}

				}
				if(value != 1) {
					boyfriend.playAnim('hey', true);
					boyfriend.specialAnim = true;
					boyfriend.heyTimer = time;
				}

			case 'Set GF Speed':
				var value:Int = Std.parseInt(value1);
				if(Math.isNaN(value) || value < 1) value = 1;
				gfSpeed = value;
		
			case 'Add Camera Zoom':
				if(ClientPrefs.data.camZooms && FlxG.camera.zoom < 1.35) {
					var camZoom:Float = Std.parseFloat(value1);
					var hudZoom:Float = Std.parseFloat(value2);
					if(Math.isNaN(camZoom)) camZoom = 0.015;
					if(Math.isNaN(hudZoom)) hudZoom = 0.03;

					FlxG.camera.zoom += camZoom;
					camHUD.zoom += hudZoom;
				}

			case 'Camera Zoom':
				if (camTween != null)
				{
					camTween.cancel();
					camTween = null;
				}
				var val1:Float = Std.parseFloat(value1);
				if(Math.isNaN(val1)) val1 = 1;

				var targetZoom = defaultCamZoom * val1;
				if (value2 != '')
				{
					var split = value2.split(',');
					var duration:Float = 0;
					var leEase:String = 'linear';
					if(split[0] != null) duration = Std.parseFloat(split[0].trim());
					if(split[1] != null) leEase = split[1].trim();
					if(Math.isNaN(duration)) duration = 0;

					if (duration > 0)
					{
						camTween = FlxTween.tween(FlxG.camera, {zoom: targetZoom}, duration, {ease: FlxEase.circOut, onComplete:
							function (twn:FlxTween)
							{
								camTween = null;
							}
						});
					}
					else
					{
						FlxG.camera.zoom = targetZoom;
					}
				}
				defaultCamZoom = targetZoom;
				setOnHScripts('defaultCamZoom', defaultCamZoom);


			case 'HUD Fade':
				if (camHUDAlphaTween != null)
				{
					camHUDAlphaTween.cancel();
					camHUDAlphaTween = null;
				}
				var leAlpha:Float = Std.parseFloat(value1);
				if(Math.isNaN(leAlpha)) leAlpha = 1;

				var duration:Float = Std.parseFloat(value2);
				if(Math.isNaN(duration)) duration = 1;

				if (duration > 0)
				{
					camHUDAlphaTween = FlxTween.tween(camHUD, {alpha: leAlpha}, duration, {ease: FlxEase.linear, onComplete:
						function (twn:FlxTween)
						{
							camHUDAlphaTween = null;
						}
					});
				}
				else
				{
					camHUD.alpha = leAlpha;
				}

			case 'Play Animation':
				//trace('Anim to play: ' + value1);
				var char:Character = dad;
				switch(value2.toLowerCase().trim()) {
					case 'bf' | 'boyfriend':
						char = boyfriend;
					case 'gf' | 'girlfriend':
						char = gf;
					default:
						var val2:Int = Std.parseInt(value2);
						if(Math.isNaN(val2)) val2 = 0;

						switch(val2) {
							case 1: char = boyfriend;
							case 2: char = gf;
						}
				}

				if (char != null)
				{
					char.playAnim(value1, true);
					char.specialAnim = true;
				}


			case 'Camera Follow Pos':
				var val1:Float = Std.parseFloat(value1);
				var val2:Float = Std.parseFloat(value2);
				if(Math.isNaN(val1)) val1 = 0;
				if(Math.isNaN(val2)) val2 = 0;

				isCameraOnForcedPos = false;
				if(!Math.isNaN(Std.parseFloat(value1)) || !Math.isNaN(Std.parseFloat(value2))) {
					camFollow.x = val1;
					camFollow.y = val2;
					isCameraOnForcedPos = true;
				}

			case 'Alt Idle Animation':
				var char:Character = dad;
				switch(value1.toLowerCase()) {
					case 'gf' | 'girlfriend':
						char = gf;
					case 'boyfriend' | 'bf':
						char = boyfriend;
					default:
						var val:Int = Std.parseInt(value1);
						if(Math.isNaN(val)) val = 0;

						switch(val) {
							case 1: char = boyfriend;
							case 2: char = gf;
						}
				}

				if (char != null)
				{
					char.idleSuffix = value2;
					char.recalculateDanceIdle();
				}

			case 'Screen Shake':
				var valuesArray:Array<String> = [value1, value2];
				var targetsArray:Array<FlxCamera> = [camGame, camHUD];
				for (i in 0...targetsArray.length) {
					var split:Array<String> = valuesArray[i].split(',');
					var duration:Float = 0;
					var intensity:Float = 0;
					if(split[0] != null) duration = Std.parseFloat(split[0].trim());
					if(split[1] != null) intensity = Std.parseFloat(split[1].trim());
					if(Math.isNaN(duration)) duration = 0;
					if(Math.isNaN(intensity)) intensity = 0;

					if(duration > 0 && intensity != 0) {
						targetsArray[i].shake(intensity, duration);
					}
				}

			case 'Change Character':
				var charType:Int = 0;
				switch(value1) {
					case 'gf' | 'girlfriend':
						charType = 2;
					case 'dad' | 'opponent':
						charType = 1;
					default:
						charType = Std.parseInt(value1);
						if(Math.isNaN(charType)) charType = 0;
				}

				var curChar:Character = boyfriend;
				switch(charType){
					case 2:
						curChar = gf;
					case 1:
						curChar = dad;
					case 0:
						curChar = boyfriend;
				}

				var newCharacter:String = value2;
				var anim:String = '';
				var frame:Int = 0;
				if(newCharacter.startsWith(curChar.curCharacter) || curChar.curCharacter.startsWith(newCharacter)){
					if(curChar.animation!=null && curChar.animation.curAnim!=null){
						anim = curChar.animation.curAnim.name;
						frame = curChar.animation.curAnim.curFrame;
					}
				}

				changeCharacter(value2, charType);
				if(anim!=''){
					var char:Character = boyfriend;
					switch(charType){
						case 2:
							char = gf;
						case 1:
							char = dad;
						case 0:
							char = boyfriend;
					}

					if(char.animation.getByName(anim)!=null){
						char.playAnim(anim, true);
						char.animation.curAnim.curFrame = frame;
					}
				}

			case 'Change Scroll Speed':
				if (songSpeedType == "constant")
					return;
				var val1:Float = Std.parseFloat(value1);
				var val2:Float = Std.parseFloat(value2);
				if(Math.isNaN(val1)) val1 = 1;
				if(Math.isNaN(val2)) val2 = 0;

				var newValue:Float = SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed', 1) * val1;

				if(val2 <= 0)
				{
					songSpeed = newValue;
				}
				else
				{
					songSpeedTween = FlxTween.tween(this, {songSpeed: newValue}, val2, {ease: FlxEase.linear, onComplete:
						function (twn:FlxTween)
						{
							songSpeedTween = null;
						}
					});
				}

			case 'Set Property':
				try {
					var killMe:Array<String> = value1.split('.');
					if(killMe.length > 1) {
						Reflect.setProperty(FunkinLua.getPropertyLoopThingWhatever(killMe, true, true), killMe[killMe.length-1], value2);
					} else {
						Reflect.setProperty(this, value1, value2);
					}
				}
				catch(e:Dynamic) {
					FlxG.log.warn('set properoatay failed ahahaaa' + e);
				}

		}
		uiCallFunction((ui:BaseUI)->ui.onEventTrigger(eventName,value1,value2));

		callOnScripts('onEvent', [eventName, value1, value2]);
		// trace(eventName);
		if(eventScripts.exists(eventName))
			callScript(eventScripts.get(eventName), "onTrigger", [value1, value2]);

	}

	
	// i might rewrite the camera movement abit
	function moveCameraSection():Void {
		if(SONG.notes[curSection] == null) return;

		if (gf != null && SONG.notes[curSection].gfSection || (gf != null && forcedCharFocus == gf))
		{
			var cam_DISPLACEMENT = getCurCamOffset(gf);

			if (!ClientPrefs.data.camMovement) cam_DISPLACEMENT.set();
			camFollow.set(gf.getMidpoint().x, gf.getMidpoint().y);
			camFollow.x += gf.cameraPosition[0] + girlfriendCameraOffset[0] + cam_DISPLACEMENT.x;
			camFollow.y += gf.cameraPosition[1] + girlfriendCameraOffset[1] + cam_DISPLACEMENT.y;
			whosTurn = 'gf';
			callOnScripts('onMoveCamera', ['gf']);
			setOnScripts('whosTurn', whosTurn);
			cam_DISPLACEMENT.put();
			return;
		}

		if (!SONG.notes[curSection].mustHitSection)
		{
			moveCamera(true);
			callOnScripts('onMoveCamera', ['dad']);
		}
		else
		{
			moveCamera(false);
			callOnScripts('onMoveCamera', ['boyfriend']);
		}
	}
	

	public function moveCamera(isDad:Bool)
	{
		if (forcedCharFocus == dad) isDad = true;
		if (forcedCharFocus == boyfriend) isDad = false;

		var char = isDad ? dad : boyfriend;
		var cam_DISPLACEMENT = getCurCamOffset(char);
	
		if(isDad)
		{
			whosTurn = 'dad';
			camFollow.set(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100);
			camFollow.x += dad.cameraPosition[0] + opponentCameraOffset[0];
			camFollow.y += dad.cameraPosition[1] + opponentCameraOffset[1];
		}
		else
		{
			camFollow.set(boyfriend.getMidpoint().x - 100, boyfriend.getMidpoint().y - 100);
			camFollow.x -= boyfriend.cameraPosition[0] - boyfriendCameraOffset[0];
			camFollow.y += boyfriend.cameraPosition[1] + boyfriendCameraOffset[1];
			whosTurn = 'boyfriend';

		}
		setOnScripts('whosTurn', whosTurn);
		if (!ClientPrefs.data.camMovement) cam_DISPLACEMENT.set();
		camFollow.x += cam_DISPLACEMENT.x;
		camFollow.y += cam_DISPLACEMENT.y;

		cam_DISPLACEMENT.put();
	}

	function getCurCamOffset(char:Character):FlxPoint
	{
		var displace:FlxPoint = FlxPoint.get();
		if (char.animation.curAnim == null) return displace;
		if (char.animation.curAnim.curFrame < 4)  {
			switch (char.animation.curAnim.name.substring(4)) {
				case 'UP' | 'UP-alt':
					displace.y = -camOffset;
				case 'DOWN' | 'DOWN-alt':
					displace.y = camOffset;
				case 'LEFT' | 'LEFT-alt':
					displace.x = -camOffset;
				case 'RIGHT' | 'RIGHT-alt':
					displace.x = camOffset;
			}
		}
		return displace;
	}


	function snapCamFollowToPos(x:Float, y:Float) {
		camFollow.set(x, y);
	}

	//Any way to do this without using a different function? kinda dumb
	private function onSongComplete()
	{
		finishSong(false);
	}
	public function finishSong(?ignoreNoteOffset:Bool = false):Void
	{
		var finishCallback:Void->Void = endSong; //In case you want to change it in a specific song.

		updateTime = false;
		FlxG.sound.music.volume = 0;
		vocals.volume = 0;
		vocals.pause();
		if(ClientPrefs.data.noteOffset <= 0 || ignoreNoteOffset) {
			finishCallback();
		} else {
			finishTimer = new FlxTimer().start(ClientPrefs.data.noteOffset / 1000, function(tmr:FlxTimer) {
				finishCallback();
			});
		}
	}


	public var transitioning = false;
	public function endSong():Void
	{
		//Should kill you if you tried to cheat
		if(!startingSong) {
			notes.forEach(function(daNote:Note) {
				if(daNote.strumTime < songLength - Conductor.safeZoneOffset) {
					health -= 0.05 * healthLoss;
				}
			});
			for (daNote in unspawnNotes) {
				if(daNote.strumTime < songLength - Conductor.safeZoneOffset) {
					health -= 0.05 * healthLoss;
				}
			}

			if(doDeathCheck()) {
				return;
			}
		}

		timeBarBG.visible = false;
		timeBar.visible = false;
		timeTxt.visible = false;
		canPause = false;
		endingSong = true;
		camZooming = false;
		inCutscene = false;
		updateTime = false;

		deathCounter = 0;
		seenCutscene = false;

		#if ACHIEVEMENTS_ALLOWED
		if(achievementObj != null) {
			return;
		} else {
			var achieve:String = checkForAchievement(['week1_nomiss', 'week2_nomiss', 'week3_nomiss', 'week4_nomiss',
				'week5_nomiss', 'week6_nomiss', 'ur_bad',
				'ur_good', 'hype', 'two_keys', 'toastie', 'debugger']);

			if(achieve != null) {
				startAchievement(achieve);
				return;
			}
		}
		#end

		#if LUA_ALLOWED
		var ret:Dynamic = callOnScripts('onEndSong', []);
		#else
		var ret:Dynamic = Globals.Function_Continue;
		#end

		if(ret != Globals.Function_Stop && !transitioning) {
			if (SONG.validScore)
			{
				#if !switch
				var percent:Float = ratingPercent;
				if(Math.isNaN(percent)) percent = 0;
				Highscore.saveScore(SONG.song, songScore, storyDifficulty, percent);
				#end
			}

			if (chartingMode)
			{
				openChartEditor();
				return;
			}

			if (isStoryMode)
			{
				campaignScore += songScore;
				campaignMisses += songMisses;

				storyPlaylist.remove(storyPlaylist[0]);

				if (storyPlaylist.length <= 0)
				{
					FlxG.sound.playMusic(ProgressionHandler.getMenuMusic());
					FlxG.sound.music.volume = 1;

					cancelMusicFadeTween();
					// if(FlxTransitionableState.skipNextTransIn) {
					// 	CustomFadeTransition.nextCamera = null;
					// }
					if (ProgressionHandler.isRodent) MusicBeatState.switchState(new StoryMenuState());
					else MusicBeatState.switchState(new meta.states.desktop.DesktopMenuState());
					// if ()
					if(!ClientPrefs.getGameplaySetting('practice', false) && !ClientPrefs.getGameplaySetting('botplay', false)) {
						StoryMenuState.weekCompleted.set(WeekData.weeksList[storyWeek], true);

						if (SONG.validScore)
						{
							Highscore.saveWeekScore(WeekData.getWeekFileName(), campaignScore, storyDifficulty);
						}

						FlxG.save.data.weekCompleted = StoryMenuState.weekCompleted;
						FlxG.save.flush();
					}
					changedDifficulty = false;
				}
				else
				{
					var difficulty:String = CoolUtil.getDifficultyFilePath();

					trace('LOADING NEXT SONG');
					trace(Paths.formatToSongPath(PlayState.storyPlaylist[0]) + difficulty);

					var winterHorrorlandNext = (Paths.formatToSongPath(SONG.song) == "eggnog");
					if (winterHorrorlandNext)
					{
						var blackShit:FlxSprite = new FlxSprite(-FlxG.width * FlxG.camera.zoom,
							-FlxG.height * FlxG.camera.zoom).makeGraphic(FlxG.width * 3, FlxG.height * 3, FlxColor.BLACK);
						blackShit.scrollFactor.set();
						add(blackShit);
						camHUD.visible = false;

						FlxG.sound.play(Paths.sound('Lights_Shut_off'));
					}

					// FlxTransitionableState.skipNextTransIn = true;
					// FlxTransitionableState.skipNextTransOut = true;

					prevCamFollow = camFollow;
					prevCamFollowPos = camFollowPos;

					//gross but its fine?
					if (PlayState.storyPlaylist[0] == 'Obituary' && ClientPrefs.getGameplaySetting('botplay',false) && ProgressionHandler.isRodent) {
						trace('pyno');
						PlayState.storyPlaylist[0] = 'free-4-me';
					}

					PlayState.SONG = Song.loadFromJson(PlayState.storyPlaylist[0] + difficulty, PlayState.storyPlaylist[0]);
					FlxG.sound.music.stop();

					if(winterHorrorlandNext) {
						new FlxTimer().start(1.5, function(tmr:FlxTimer) {
							cancelMusicFadeTween();
							LoadingState.loadAndSwitchState(new PlayState());
						});
					} else {
						cancelMusicFadeTween();
						LoadingState.loadAndSwitchState(new PlayState());
					}
				}
			}
			else
			{
				trace('WENT BACK TO FREEPLAY??');
				cancelMusicFadeTween();
				// if(FlxTransitionableState.skipNextTransIn) {
				// 	CustomFadeTransition.nextCamera = null;
				// }
				if (ProgressionHandler.isRodent) {
					MusicBeatState.switchState(new FreeplayState());
				}
				else {
					MusicBeatState.switchState(new meta.states.desktop.DesktopSongSelectState());
				}

				meta.states.desktop.DesktopSongSelectState.fromFreeplay = true;
				FlxG.sound.playMusic(ProgressionHandler.getMenuMusic());
				FlxG.sound.music.volume = 1;
				changedDifficulty = false;
			}
			transitioning = true;
		}
	}

	#if ACHIEVEMENTS_ALLOWED
	var achievementObj:AchievementObject = null;
	function startAchievement(achieve:String) {
		achievementObj = new AchievementObject(achieve, camOther);
		achievementObj.onFinish = achievementEnd;
		add(achievementObj);
		trace('Giving achievement ' + achieve);
	}
	function achievementEnd():Void
	{
		achievementObj = null;
		if(endingSong && !inCutscene) {
			endSong();
		}
	}
	#end

	public function playVideo(name:String, ?vis:Bool = true){
		var video = new PsychVideoSprite(false);
		video.scrollFactor.set();
		video.cameras = [camHUD];
		video.visible = vis;
		video.shader = new GreenScreenShader();
		video.onEndCallback = ()->{
			trace("video gone");
			remove(video);
			video.kill();
		};

		video.onStartCallback = ()->{
			//im pr sure this is redundant now with hxvlc not starting vid until play is called but whatyever lol
			if(vis) video.visible=true;
		};

		video.load(Paths.video(name));
		video.play();
		add(video);
	}

	public function KillNotes() {
		while(notes.length > 0) {
			var daNote:Note = notes.members[0];
			daNote.active = false;
			daNote.visible = false;

			if(modchartObjects.exists('note${daNote.ID}'))modchartObjects.remove('note${daNote.ID}');
			daNote.kill();
			notes.remove(daNote, true);
			daNote.destroy();
		}
		unspawnNotes = [];
		eventNotes = [];
	}

	public var totalPlayed:Int = 0;
	public var totalNotesHit:Float = 0.0;

	public var showCombo:Bool = true;
	public var showRating:Bool = true;

	private function popUpScore(note:Note = null):Void
	{
		var noteDiff:Float = Math.abs(note.strumTime - Conductor.songPosition + ClientPrefs.data.ratingOffset);
		//trace(noteDiff, ' ' + Math.abs(note.strumTime - Conductor.songPosition));

		// boyfriend.playAnim('hey');
		vocals.volume = 1;
		var placement:String = Std.string(combo);

		var coolText:FlxObject = new FlxObject(0, 0);
		coolText.screenCenter();
		coolText.x = FlxG.width * 0.35;
		//

		var rating:FlxSprite = new FlxSprite();
		var score:Int = 350;

		//tryna do MS based judgment due to popular demand
		var daRating:Rating = Conductor.judgeNote(note, noteDiff);
		var ratingNum:Int = 0;

		totalNotesHit += daRating.ratingMod;
		note.ratingMod = daRating.ratingMod;
		if(!note.ratingDisabled) daRating.increase();
		note.rating = daRating.name;

		if(daRating.noteSplash && !note.noteSplashDisabled)
		{
			spawnNoteSplashOnNote(note);
		}

		var field:PlayField = note.playField;

		if(!practiceMode && !field.autoPlayed) {
			songScore += score;
			if(!note.ratingDisabled)
			{
				songHits++;
				totalPlayed++;
				RecalculateRating();
			}
		}

		var pixelShitPart1:String = "";
		var pixelShitPart2:String = '';

		if (PlayState.isPixelStage)
		{
			pixelShitPart1 = 'pixelUI/';
			pixelShitPart2 = '-pixel';
		}

		rating.loadGraphic(Paths.image(pixelShitPart1 + daRating.image + pixelShitPart2));
		rating.cameras = [camHUD];
		rating.screenCenter();
		rating.x = coolText.x - 40;
		rating.y -= 60;
		rating.acceleration.y = 550;
		rating.velocity.y -= FlxG.random.int(140, 175);
		rating.velocity.x -= FlxG.random.int(0, 10);
		rating.visible = (!ClientPrefs.data.hideHud && showRating);
		rating.x += ClientPrefs.data.comboOffset[0];
		rating.y -= ClientPrefs.data.comboOffset[1];

		var comboSpr:FlxSprite = new FlxSprite().loadGraphic(Paths.image(pixelShitPart1 + 'combo' + pixelShitPart2));
		comboSpr.cameras = [camHUD];
		comboSpr.screenCenter();
		comboSpr.x = coolText.x;
		comboSpr.acceleration.y = 600;
		comboSpr.velocity.y -= 150;
		comboSpr.visible = (!ClientPrefs.data.hideHud && showCombo);
		comboSpr.x += ClientPrefs.data.comboOffset[0];
		comboSpr.y -= ClientPrefs.data.comboOffset[1];


		comboSpr.velocity.x += FlxG.random.int(1, 10);
		insert(members.indexOf(playFields), rating);

		if (!PlayState.isPixelStage)
		{
			rating.setGraphicSize(Std.int(rating.width * 0.7));
			rating.antialiasing = ClientPrefs.data.antialiasing;
			comboSpr.setGraphicSize(Std.int(comboSpr.width * 0.7));
			comboSpr.antialiasing = ClientPrefs.data.antialiasing;
		}
		else
		{
			rating.setGraphicSize(Std.int(rating.width * daPixelZoom * 0.85));
			comboSpr.setGraphicSize(Std.int(comboSpr.width * daPixelZoom * 0.85));
		}

		comboSpr.updateHitbox();
		rating.updateHitbox();

		rating.scale.x = 0.785;
		rating.scale.y = 0.785;

		FlxTween.tween(rating.scale, {x: 0.7, y: 0.7}, 0.5, {ease: FlxEase.expoOut});

		var seperatedScore:Array<Int> = [];

		if(combo >= 1000) {
			seperatedScore.push(Math.floor(combo / 1000) % 10);
		}
		seperatedScore.push(Math.floor(combo / 100) % 10);
		seperatedScore.push(Math.floor(combo / 10) % 10);
		seperatedScore.push(combo % 10);

		var daLoop:Int = 0;
		for (i in seperatedScore)
		{
			var numScore:FlxSprite = new FlxSprite().loadGraphic(Paths.image(pixelShitPart1 + 'num' + Std.int(i) + pixelShitPart2));
			numScore.cameras = [camHUD];
			numScore.screenCenter();
			numScore.x = coolText.x + (43 * daLoop) - 90;
			numScore.y += 80;

			numScore.x += ClientPrefs.data.comboOffset[2];
			numScore.y -= ClientPrefs.data.comboOffset[3];

			if (!PlayState.isPixelStage)
			{
				numScore.antialiasing = ClientPrefs.data.antialiasing;
				numScore.setGraphicSize(Std.int(numScore.width * 0.5));
			}
			else
			{
				numScore.setGraphicSize(Std.int(numScore.width * daPixelZoom));
			}
			numScore.updateHitbox();

			numScore.acceleration.y = FlxG.random.int(200, 300);
			numScore.velocity.y -= FlxG.random.int(140, 160);
			numScore.velocity.x = FlxG.random.float(-5, 5);
			numScore.visible = !ClientPrefs.data.hideHud;

			//if (combo >= 10 || combo == 0)
				insert(members.indexOf(rating), numScore);

			numScore.scale.x = 0.55;
			numScore.scale.y = 0.55;
	
			callOnHScripts('popupNumScore', [numScore]);

			FlxTween.tween(numScore.scale, {x: 0.5, y: 0.5}, 0.5, {ease: FlxEase.expoOut});
			FlxTween.tween(numScore, {alpha: 0}, 0.2, {
				onComplete: function(tween:FlxTween)
				{
					numScore.destroy();
				},
				startDelay: Conductor.crochet * 0.002
			});

			callOnHScripts('popupNumScorePost', []);


			daLoop++;
		}
		/*
			trace(combo);
			trace(seperatedScore);
		 */

		// add(coolText);
		callOnHScripts('popupScore', [rating, comboSpr, note]);

		FlxTween.tween(rating, {alpha: 0}, 0.2, {
			startDelay: Conductor.crochet * 0.001
		});

		FlxTween.tween(comboSpr, {alpha: 0}, 0.2, {
			onComplete: function(tween:FlxTween)
			{
				coolText.destroy();
				comboSpr.destroy();

				rating.destroy();
			},
			startDelay: Conductor.crochet * 0.001
		});

		callOnHScripts('popupScorePost', []);


	}

	private function onKeyPress(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(eventKey);
		//trace('Pressed: ' + eventKey);
		if(cpuControlled || paused || !startedCountdown)return;

		if (key > -1 && (FlxG.keys.checkStatus(eventKey, JUST_PRESSED) || ClientPrefs.data.controllerMode))
		{
			if(!boyfriend.stunned && generatedMusic && !endingSong)
			{
				//more accurate hit time for the ratings?
				var lastTime:Float = Conductor.songPosition;
				Conductor.songPosition = FlxG.sound.music.time;

				var canMiss:Bool = !ClientPrefs.data.ghostTapping;

				var pressNotes:Array<Note> = [];

				var ghostTapped:Bool = true;
				for(field in playFields.members){
					if (field.playerControls && field.inControl && !field.autoPlayed){
						var sortedNotesList:Array<Note> = field.getTapNotes(key);
						sortedNotesList.sort((a, b) -> Std.int(a.strumTime - b.strumTime));

						if (sortedNotesList.length > 0) {
							pressNotes.push(sortedNotesList[0]);
							field.noteHitCallback(sortedNotesList[0], field);
						}
					}
				}

				if(pressNotes.length==0){
					callOnScripts('onGhostTap', [key]);
					if (canMiss) {
						noteMissPress(key);
						callOnScripts('noteMissPress', [key]);
					}
				}

				// I dunno what you need this for but here you go
				//									- Shubs

				// Shubs, this is for the "Just the Two of Us" achievement lol
				//									- Shadow Mario

				// LOOOOOL
				// 									- ava
				keysPressed[key] = true;

				//more accurate hit time for the ratings? part 2 (Now that the calculations are done, go back to the time it was before for not causing a note stutter)
				Conductor.songPosition = lastTime;
			}

			for(field in playFields.members){
				if (field.inControl && !field.autoPlayed && field.playerControls){
					var spr:StrumNote = field.members[key];
					if(spr != null && spr.animation.curAnim.name != 'confirm')
					{
						spr.playAnim('pressed');
						spr.resetAnim = 0;
					}
				}
			}

			callOnScripts('onKeyPress', [key]);
		}
		//trace('pressed: ' + controlArray);
	}

	private function onKeyRelease(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(eventKey);
		if(startedCountdown && !paused && key > -1)
		{
			for(field in playFields.members){
				if (field.inControl && !field.autoPlayed && field.playerControls)
				{
					var spr:StrumNote = field.members[key];
					if (spr != null)
					{
						spr.playAnim('static');
						spr.resetAnim = 0;
					}
				}
			}
			callOnScripts('onKeyRelease', [key]);
		}
		//trace('released: ' + controlArray);
	}

	private function getKeyFromEvent(key:FlxKey):Int
	{
		if(key != NONE)
		{
			for (i in 0...keysArray.length)
			{
				for (j in 0...keysArray[i].length)
				{
					if(key == keysArray[i][j])
					{
						return i;
					}
				}
			}
		}
		return -1;
	}

	// Hold notes
	private function keyShit():Void
	{
		// HOLDING
		var up = controls.NOTE_UP;
		var right = controls.NOTE_RIGHT;
		var down = controls.NOTE_DOWN;
		var left = controls.NOTE_LEFT;
		var controlHoldArray:Array<Bool> = [left, down, up, right];

		// TO DO: Find a better way to handle controller inputs, this should work for now
		if(ClientPrefs.data.controllerMode)
		{
			var controlArray:Array<Bool> = [controls.NOTE_LEFT_P, controls.NOTE_DOWN_P, controls.NOTE_UP_P, controls.NOTE_RIGHT_P];
			if(controlArray.contains(true))
			{
				for (i in 0...controlArray.length)
				{
					if(controlArray[i])
						onKeyPress(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, -1, keysArray[i][0]));
				}
			}
		}

		// FlxG.watch.addQuick('asdfa', upP);
		if (startedCountdown && !boyfriend.stunned && generatedMusic)
		{
			// rewritten inputs???
			
			notes.forEachAlive(function(daNote:Note)
			{
				// hold note functions
				if(!daNote.playField.autoPlayed && daNote.playField.inControl && daNote.playField.playerControls){
					if (daNote.isSustainNote && controlHoldArray[daNote.noteData] && daNote.canBeHit && !daNote.tooLate && !daNote.wasGoodHit) {
						daNote.playField.noteHitCallback(daNote, daNote.playField);
					}
				}
			});

			if (controlHoldArray.contains(true) && !endingSong) {
				#if ACHIEVEMENTS_ALLOWED
				var achieve:String = checkForAchievement(['oversinging']);
				if (achieve != null) {
					startAchievement(achieve);
				}
				#end
			}
			else if (boyfriend.holdTimer > Conductor.stepCrochet * 0.0011 * boyfriend.singDuration && boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.animation.curAnim.name.endsWith('miss'))
			{
				boyfriend.dance();
				//boyfriend.animation.curAnim.finish();
			}
		}

		// TO DO: Find a better way to handle controller inputs, this should work for now
		if(ClientPrefs.data.controllerMode)
		{
			var controlArray:Array<Bool> = [controls.NOTE_LEFT_R, controls.NOTE_DOWN_R, controls.NOTE_UP_R, controls.NOTE_RIGHT_R];
			if(controlArray.contains(true))
			{
				for (i in 0...controlArray.length)
				{
					if(controlArray[i])
						onKeyRelease(new KeyboardEvent(KeyboardEvent.KEY_UP, true, true, -1, keysArray[i][0]));
				}
			}
		}
	}


	function noteMiss(daNote:Note):Void { //You didn't hit the key and let it go offscreen, also used by Hurt Notes
		//Dupe note remove
		updateScoreBar();
		notes.forEachAlive(function(note:Note) {
			if (daNote != note && daNote.playField.playerControls && daNote.noteData == note.noteData && daNote.isSustainNote == note.isSustainNote && Math.abs(daNote.strumTime - note.strumTime) < 1) {
				disposeNote(note);
			}
		});
		combo = 0;

		if (daNote.isSustainNote) health -= (daNote.missHealth * healthLoss) / 2.75;
		else health -= daNote.missHealth * healthLoss;

		if(instakillOnMiss)
		{
			vocals.volume = 0;
			doDeathCheck(true);
		}

		//For testing purposes
		//trace(daNote.missHealth);
		songMisses++;
		vocals.volume = 0;
		if(!practiceMode) songScore -= 10;

		totalPlayed++;
		RecalculateRating();

		var char:Character = boyfriend;
		if(daNote.gfNote)char = gf;

		if(char != null && !daNote.noMissAnimation && char.hasMissAnimations)
		{
			if(char.animTimer <= 0 && !char.voicelining){
				var daAlt = '';
				if(daNote.noteType == 'Alt Animation') daAlt = '-alt';

				var animToPlay:String = singAnimations[Std.int(Math.abs(daNote.noteData))] + 'miss' + daAlt;
				char.playAnim(animToPlay, true);
				if (char.currentlyHolding) char.currentlyHolding = false;
			}
		}

		callOnLuas('noteMiss', [notes.members.indexOf(daNote), daNote.noteData, daNote.noteType, daNote.isSustainNote, daNote.ID]);
		callOnHScripts("noteMiss", [daNote]);

		if (daNote.noteScript!=null)
		{
			var script:Dynamic = daNote.noteScript;
			if (script.scriptType == 'lua')
			{
				callScript(script, 'noteMiss', [
					notes.members.indexOf(daNote),
					Math.abs(daNote.noteData),
					daNote.noteType,
					daNote.isSustainNote,
					daNote.ID
				]);
			}
			else
			{
				callScript(script, "noteMiss", [daNote]);
			}
		}
	}

	function noteMissPress(direction:Int = 1, anim:Bool = true):Void //You pressed a key when there was no notes to press for this key
	{
		if(ClientPrefs.data.ghostTapping) return; //fuck it

		if (!boyfriend.stunned)
		{
			health -= 0.05 * healthLoss;
			if(instakillOnMiss)
			{
				vocals.volume = 0;
				doDeathCheck(true);
			}

			if (combo > 5 && gf != null && gf.animOffsets.exists('sad'))
			{
				gf.playAnim('sad');
			}
			combo = 0;

			if(!practiceMode) songScore -= 10;
			if(!endingSong) {
				songMisses++;
			}
			totalPlayed++;
			RecalculateRating();

			FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2));
			// FlxG.sound.play(Paths.sound('missnote1'), 1, false);
			// FlxG.log.add('played imss note');

			/*boyfriend.stunned = true;

			// get stunned for 1/60 of a second, makes you able to
			new FlxTimer().start(1 / 60, function(tmr:FlxTimer)
			{
				boyfriend.stunned = false;
			});*/

			if(boyfriend.hasMissAnimations && anim) {
				if(boyfriend.animTimer <= 0 && !boyfriend.voicelining)
					boyfriend.playAnim(singAnimations[Std.int(Math.abs(direction))] + 'miss', true);
			}
			vocals.volume = 0;
		}
		callOnScripts('noteMissPress', [direction]);
	}

	function opponentNoteHit(note:Note, playfield:PlayField):Void
	{
		if (Paths.formatToSongPath(SONG.song) != 'tutorial')
			camZooming = true;

		var char:Character = playfield.owner;

		if(note.gfNote)
			char = gf;

		if(note.noteType == 'Hey!' && char.animOffsets.exists('hey')) {
			char.playAnim('hey', true);
			char.specialAnim = true;
			char.heyTimer = 0.6;
		} else if(!note.noAnimation) {
			var altAnim:String = "";

			var curSect:Int = Math.floor(curStep / 16);
			if (SONG.notes[curSect] != null)
			{
				if (SONG.notes[curSect].altAnim || note.noteType == 'Alt Animation') {
					altAnim = '-alt';
				}
			}

			var animToPlay:String = singAnimations[Std.int(Math.abs(note.noteData))] + altAnim;
			if(char.voicelining)char.voicelining=false;

			if(char != null)
			{
				char.holdTimer = 0;

				// TODO: maybe move this all away into a seperate function
					if (!note.isSustainNote
						&& noteRows[note.mustPress ? 0 : 1][note.row] != null
						&& noteRows[note.mustPress ? 0 : 1][note.row].length > 1
						&& note.noteType != "Ghost Note")
					{
						// potentially have jump anims?
						var chord = noteRows[note.mustPress ? 0 : 1][note.row];
						var animNote = chord[0];
						var realAnim = singAnimations[Std.int(Math.abs(animNote.noteData))] + altAnim;
						if (char.mostRecentRow != note.row)
							char.playAnim(realAnim, true);
	
						if(note.nextNote != null && note.prevNote != null){
							if (note != animNote && !note.nextNote.isSustainNote /* && !note.prevNote.isSustainNote */ && callOnHScripts('onGhostAnim', [animToPlay, note]) != Globals.Function_Stop) {
								char.playGhostAnim(chord.indexOf(note), animToPlay, true);
							}else if(note.nextNote.isSustainNote){
								char.playAnim(realAnim, true);
								char.playGhostAnim(chord.indexOf(note), animToPlay, true);

							}
						}	
						char.mostRecentRow = note.row;
					}
					else{
						if(note.noteType != "Ghost Note")
							char.playAnim(animToPlay + altAnim, true);
						else
							char.playGhostAnim(note.noteData, animToPlay + altAnim, true);
					}
					//temp for now

					if (char.pauseAnimForSustain && ((note.nextNote?.isSustainNote || note.isSustainNote)) && !note.animation.curAnim.name.contains('end')) char.currentlyHolding = true;
					else char.currentlyHolding = false;
			}
		}

		if (SONG.needsVoices){
			vocals.volume = 1;
		}

		if (playfield.autoPlayed) {
			var time:Float = 0.15;
			if(note.isSustainNote && !note.animation.curAnim.name.endsWith('end')) {
				time += 0.15;
			}
			StrumPlayAnim(playfield, Std.int(Math.abs(note.noteData)) % 4, time, note);
		} else {
			playfield.forEach(function(spr:StrumNote)
			{
				if (Math.abs(note.noteData) == spr.ID)
				{
					spr.playAnim('confirm', true, note);
				}
			});
		}

		note.hitByOpponent = true;

		callOnLuas('opponentNoteHit', [notes.members.indexOf(note), Math.abs(note.noteData), note.noteType, note.isSustainNote, note.ID]);
		callOnHScripts("opponentNoteHit", [note]);
		if (note.noteScript != null)
		{
			var script:Dynamic = note.noteScript;
			if (script.scriptType == 'lua')
			{
				callScript(script, 'opponentNoteHit',
				[
					notes.members.indexOf(note),
					Math.abs(note.noteData),
					note.noteType,
					note.isSustainNote,
					note.ID
				]);
			}
			else
			{
				callScript(script, "opponentNoteHit", [note]); 
			}
		}
		if (!note.isSustainNote)
		{
			note.garbage = true;
		}
	}
	

	function goodNoteHit(note:Note, field:PlayField):Void
	{
		if (!note.wasGoodHit)
		{
			if(field.autoPlayed && (note.ignoreNote || note.hitCausesMiss)) return;

			if (ClientPrefs.data.hitsoundVolume > 0 && !note.hitsoundDisabled)
			{
				FlxG.sound.play(Paths.sound('hitsound'), ClientPrefs.data.hitsoundVolume);
			}

			if (field.autoPlayed) {
				var time:Float = 0.15;
				if(note.isSustainNote && !note.animation.curAnim.name.endsWith('end')) {
					time += 0.15;
				}
				StrumPlayAnim(field, Std.int(Math.abs(note.noteData)) % 4, time, note);
			} else {
				field.forEach(function(spr:StrumNote)
				{
					if (Math.abs(note.noteData) == spr.ID)
					{
						spr.playAnim('confirm', true, note);
					}
				});
			}

			if(note.hitCausesMiss) {
				noteMiss(note);
				if(!note.noteSplashDisabled && !note.isSustainNote) {
					spawnNoteSplashOnNote(note);
				}


				if(!note.noMissAnimation)
				{
					switch(note.noteType) {
						case 'Hurt Note': //Hurt note
							if(field.owner.animation.getByName('hurt') != null) {
								field.owner.playAnim('hurt', true);
								field.owner.specialAnim = true;
							}
					}
				}


				note.wasGoodHit = true;
				if (!note.isSustainNote)
				{
					note.garbage = true;
				}
				return;
			}

			if (!note.isSustainNote)
			{
				combo += 1;
				popUpScore(note);
				if(combo > 9999) combo = 9999;
			}

			if (note.isSustainNote) health += (note.hitHealth * healthGain) / 6;
			else health += note.hitHealth * healthGain;

			if(!note.noAnimation) {
				var daAlt = '';
				if(note.noteType == 'Alt Animation') daAlt = '-alt';

				var animToPlay:String = singAnimations[Std.int(Math.abs(note.noteData))];

				if(note.gfNote)
				{
					if(gf != null)
					{
						gf.playAnim(animToPlay + daAlt, true);
						gf.holdTimer = 0;
					}
				}

				else if (field.owner.animTimer <= 0 && !field.owner.voicelining)
				{
					// field.owner.playAnim(animToPlay + daAlt, true);
					field.owner.holdTimer = 0;
					if (!note.isSustainNote && noteRows[note.gfNote ? 2 : note.mustPress ? 0 : 1][note.row]!=null && noteRows[note.gfNote ? 2 : note.mustPress ? 0 : 1][note.row].length > 1 && note.noteType != "Ghost Note")
						{
							// potentially have jump anims?
							var chord = noteRows[note.gfNote ? 2 : note.mustPress ? 0 : 1][note.row];
							var animNote = chord[0];
							var realAnim = singAnimations[Std.int(Math.abs(animNote.noteData))] + daAlt;
							if (field.owner.mostRecentRow != note.row)
								field.owner.playAnim(realAnim, true);
							
		
							if (note != animNote && chord.indexOf(note) != animNote.noteData)
								field.owner.playGhostAnim(chord.indexOf(note), animToPlay, true);
								// doGhostAnim('bf', animToPlay);
		
							field.owner.mostRecentRow = note.row;
						}
						else{
							if(note.noteType != "Ghost Note")
								field.owner.playAnim(animToPlay + daAlt, true);
							else
								field.owner.playGhostAnim(note.noteData, animToPlay, true);		

							if (field.owner.pauseAnimForSustain && ((note.nextNote?.isSustainNote || note.isSustainNote)) && !note.animation.curAnim.name.contains('end')) field.owner.currentlyHolding = true;
							else field.owner.currentlyHolding = false;
							
							
						}
				}

				if(note.noteType == 'Hey!') {
					if (field.owner.animTimer <= 0 && !field.owner.voicelining){
						if(field.owner.animOffsets.exists('hey')) {
							field.owner.playAnim('hey', true);
							field.owner.specialAnim = true;
							field.owner.heyTimer = 0.6;
						}
					}

					if(gf != null && gf.animOffsets.exists('cheer')) {
						gf.playAnim('cheer', true);
						gf.specialAnim = true;
						gf.heyTimer = 0.6;
					}
				}
			}

			note.wasGoodHit = true;
			vocals.volume = 1;
			var isSus:Bool = note.isSustainNote; //GET OUT OF MY HEAD, GET OUT OF MY HEAD, GET OUT OF MY HEAD
			var leData:Int = Math.round(Math.abs(note.noteData));
			var leType:String = note.noteType;
			callOnLuas('goodNoteHit', [notes.members.indexOf(note), leData, leType, isSus, note.ID]);
			callOnHScripts("goodNoteHit", [note]); // maybe have this above so you can interrupt goodNoteHit? idk we'll see
			if (note.noteScript!=null)
			{
				var script:Dynamic = note.noteScript;
				if (script.scriptType == 'lua')
				{
					callScript(script, 'goodNoteHit',
						[notes.members.indexOf(note), leData, leType, isSus, note.ID]); 
				}
				else
				{
					callScript(script, "goodNoteHit", [note]); 
				}
			}
			if (!note.isSustainNote)
			{
				note.garbage = true;
			}
		}
		updateScoreBar();
	}

	function spawnNoteSplashOnNote(note:Note) {
		if(ClientPrefs.data.noteSplashes && note != null) {
			var strum:StrumNote = note.playField.members[note.noteData];
			if(strum != null) {
				spawnNoteSplash(strum.x, strum.y, note.noteData, note);
			}
		}
	}

	public function spawnNoteSplash(x:Float, y:Float, data:Int, ?note:Note = null) {
		var quant:Bool = ClientPrefs.data.noteSkin == 'Quants' || ClientPrefs.data.noteSkin == 'QuantStep';
		var skin:String = 'noteSplashes';
		var offsets:Array<FlxPoint> = [];
		for(i in 0...4){
			offsets.push(new FlxPoint(0, 0));
		}
		if(noteskinScript != null){
			var scriptedSkin = noteskinScript.call("noteSplash", [offsets]);
			if(scriptedSkin != null) skin = scriptedSkin;
		}
		if(quant) skin = 'QUANT$skin';

		var hue:Float = ClientPrefs.data.arrowHSV[data % 4][0] / 360;
		var sat:Float = ClientPrefs.data.arrowHSV[data % 4][1] / 100;
		var brt:Float = ClientPrefs.data.arrowHSV[data % 4][2] / 100;
		if(note != null) {
			hue = note.noteSplashHue;
			sat = note.noteSplashSat;
			brt = note.noteSplashBrt;
		}

		var splash:NoteSplash = grpNoteSplashes.recycle(NoteSplash);
		splash.setupNoteSplash(x + offsets[data].x, y + offsets[data].y, data, skin, hue, sat, brt, note.playField);
		grpNoteSplashes.add(splash);

		var isPlayer:Bool = note.mustPress;

		callOnHScripts('spawnNoteSplash', [splash, data, note, isPlayer]);
	}

	private var preventLuaRemove:Bool = false;
	override function destroy() {
		preventLuaRemove = true;
		for(script in funkyScripts){
			script.call("onDestroy", []);
			script.stop();
		}
		hscriptArray = [];
		funkyScripts = [];
		luaArray = [];
		notetypeScripts.clear();
		eventScripts.clear();
		if(!ClientPrefs.data.controllerMode)
		{
			FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
			FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		}
		super.destroy();
	}

	public static function cancelMusicFadeTween() {
		if(FlxG.sound.music.fadeTween != null) {
			FlxG.sound.music.fadeTween.cancel();
		}
		FlxG.sound.music.fadeTween = null;
	}

	public function removeLua(lua:FunkinLua) {
		if(luaArray != null && !preventLuaRemove) {
			luaArray.remove(lua);
		}
	}

	var lastStepHit:Int = -1;
	override function stepHit()
	{
		super.stepHit();


		if (Math.abs(FlxG.sound.music.time - (Conductor.songPosition - Conductor.offset)) > 20
			|| (SONG.needsVoices && Math.abs(vocals.time - (Conductor.songPosition - Conductor.offset)) > 20))
		{
			resyncVocals();
		}

		if(curStep == lastStepHit) {
			return;
		}



		lastStepHit = curStep;
		setOnScripts('curStep', curStep);
		callOnScripts('onStepHit', []);
	}


	var lastBeatHit:Int = -1;

	function cinematicBars(appear:Bool) //IF (TRUE) MOMENT?????
	{
		if (appear)
		{
			add(topBar);
			add(bottomBar);
			FlxTween.tween(topBar, {y: 0}, 0.5, {ease: FlxEase.quadOut});
			FlxTween.tween(bottomBar, {y: 550}, 0.5, {ease: FlxEase.quadOut});
		}
		else
		{
			FlxTween.tween(topBar, {y: -170}, 0.5, {ease: FlxEase.quadOut});
			FlxTween.tween(bottomBar, {y: 720}, 0.5, {ease: FlxEase.quadOut, onComplete: function(fuckme:FlxTween)
			{
				remove(topBar);
				remove(bottomBar);
			}});
		}
	}


	var lastSection:Int = -1;
	override function beatHit()
	{
		super.beatHit();

		if(lastBeatHit >= curBeat) {
			//trace('BEAT HIT: ' + curBeat + ', LAST HIT: ' + lastBeatHit);
			return;
		}

		if (generatedMusic)
		{
			notes.sort(FlxSort.byY, ClientPrefs.data.downScroll ? FlxSort.ASCENDING : FlxSort.DESCENDING);
		}

		var curSect = SONG.notes[Math.floor(curStep / 16)];

		iconP1.scale.set(1.2, 1.2);
		iconP2.scale.set(1.2, 1.2);

		iconP1.updateHitbox();
		iconP2.updateHitbox();

		if (gf != null && curBeat % Math.round(gfSpeed * gf.danceEveryNumBeats) == 0 && gf.animation.curAnim != null && !gf.animation.curAnim.name.startsWith("sing") && !gf.stunned)
		{
			gf.dance();
		}
		if (curBeat % boyfriend.danceEveryNumBeats == 0 && boyfriend.animation.curAnim != null && !boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.stunned)
		{
			boyfriend.dance();
		}
		if (curBeat % dad.danceEveryNumBeats == 0 && dad.animation.curAnim != null && !dad.animation.curAnim.name.startsWith('sing') && !dad.stunned)
		{
			dad.dance();
		}

		if (zoomsPerBeat == 0) zoomsPerBeat = 11111;
		if (camZooming && ClientPrefs.data.camZooms && curBeat % zoomsPerBeat == 0)
		{
			FlxG.camera.zoom += 0.015 * camZoomingMult;
			camHUD.zoom += 0.03 * camZoomingMult;
		}



		lastBeatHit = curBeat;

		uiCallFunction((ui:BaseUI)->{ui.onBeatHit();});

		setOnScripts('curBeat', curBeat); //DAWGG?????
		callOnScripts('onBeatHit', []);
	}

	override function sectionHit()
	{
		super.sectionHit();

		if (SONG.notes[curSection] != null)
		{
			// if (generatedMusic && !endingSong && !isCameraOnForcedPos)
			// {
			// 	moveCameraSection();
			// }



			if (SONG.notes[curSection].changeBPM)
			{
				Conductor.changeBPM(SONG.notes[curSection].bpm);
				setOnScripts('curBpm', Conductor.bpm);
				setOnScripts('crochet', Conductor.crochet);
				setOnScripts('stepCrochet', Conductor.stepCrochet);
			}
			setOnScripts('mustHitSection', SONG.notes[curSection].mustHitSection);
			setOnScripts('altAnim', SONG.notes[curSection].altAnim);
			setOnScripts('gfSection', SONG.notes[curSection].gfSection);
		}
		
		setOnScripts('curSection', curSection);
		callOnScripts('onSectionHit', []);
	}

	public var closeLuas:Array<FunkinLua> = [];

	public function callOnScripts(event:String, args:Array<Dynamic>, ignoreStops:Bool = false, ?exclusions:Array<String>, ?scriptArray:Array<Dynamic>,
			?ignoreSpecialShit:Bool = true)
	{
		
		if (scriptArray == null)
			scriptArray = funkyScripts;
		if(exclusions==null)exclusions = [];
		var returnVal:Dynamic = Globals.Function_Continue;
		for (script in scriptArray)
		{
			if (exclusions.contains(script.scriptName)
				|| ignoreSpecialShit
				&& (notetypeScripts.exists(script.scriptName) || eventScripts.exists(script.scriptName) ) )
			{
				continue;
			}
			var ret:Dynamic = script.call(event, args);
			if (ret == Globals.Function_Halt)
			{
				ret = returnVal;
				if (!ignoreStops)
					return returnVal;
			};
			if (ret != Globals.Function_Continue && ret!=null)
				returnVal = ret;
		}
		if(returnVal==null)returnVal = Globals.Function_Continue;
		return returnVal;
	}

	public function setOnScripts(variable:String, arg:Dynamic, ?scriptArray:Array<Dynamic>)
	{
		if (scriptArray == null)
			scriptArray = funkyScripts;
		for (script in scriptArray)
		{
			script.set(variable, arg);
		}
	}

	public function callScript(script:Dynamic, event:String, args:Array<Dynamic>): Dynamic{
		if((script is FunkinScript)){
			return callOnScripts(event, args, true, [], [script], false);
		}else if((script is Array)){
			return callOnScripts(event, args, true, [], script, false);
		}else if((script is String)){
			var scripts:Array<FunkinScript> = [];
			for(scr in funkyScripts){
				if(scr.scriptName == script)
					scripts.push(scr);
			}
			return callOnScripts(event, args, true, [], scripts, false);
		}
		return Globals.Function_Continue;
	}
	

	public function callOnHScripts(event:String, args:Array<Dynamic>, ignoreStops = false, ?exclusions:Array<String>){
		return callOnScripts(event, args, ignoreStops, exclusions, hscriptArray);
	}
	
	public function setOnHScripts(variable:String, arg:Dynamic)
	{
		return setOnScripts(variable, arg, hscriptArray);
	}

	public function hscriptSetDefault(variable:String, arg:Dynamic)
	{
		FunkinHScript.defaultVars.set(variable, arg);
		return setOnHScripts(variable, arg);
	}

	public function callOnLuas(event:String, args:Array<Dynamic>, ignoreStops = false, ?exclusions:Array<String>){
		#if LUA_ALLOWED
		return callOnScripts(event, args, ignoreStops, exclusions, luaArray);
		#else
		return Globals.Function_Continue;
		#end
	}

	public function setOnLuas(variable:String, arg:Dynamic) {
		#if LUA_ALLOWED
		setOnScripts(variable, arg, luaArray);
		#end
	}

	function StrumPlayAnim(field:PlayField, id:Int, time:Float, ?note:Note) {
		var spr:StrumNote = field.members[id];

		if(spr != null) {
			spr.playAnim('confirm', true, note);
			spr.resetAnim = time;
		}
	}

	public var ratingName:String = '?';
	public var ratingPercent:Float;
	public var ratingFC:String;
	public function RecalculateRating() {
		setOnLuas('score', songScore);
		setOnLuas('misses', songMisses);
		setOnLuas('hits', songHits);

		var ret:Dynamic = callOnScripts('onRecalculateRating', []);
		if(ret != Globals.Function_Stop)
		{
			if(totalPlayed < 1) //Prevent divide by 0
				ratingName = '?';
			else
			{
				// Rating Percent
				ratingPercent = Math.min(1, Math.max(0, totalNotesHit / totalPlayed));
				//trace((totalNotesHit / totalPlayed) + ', Total: ' + totalPlayed + ', notes hit: ' + totalNotesHit);

				// Rating Name
				if(ratingPercent >= 1)
				{
					ratingName = ratingStuff[ratingStuff.length-1][0]; //Uses last string
				}
				else
				{
					for (i in 0...ratingStuff.length-1)
					{
						if(ratingPercent < ratingStuff[i][1])
						{
							ratingName = ratingStuff[i][0];
							break;
						}
					}
				}
			}

			// Rating FC
			ratingFC = "";
			if (sicks > 0) ratingFC = "SFC";
			if (goods > 0) ratingFC = "GFC";
			if (bads > 0 || shits > 0) ratingFC = "FC";
			if (songMisses > 0 && songMisses < 10) ratingFC = "SDCB";
			else if (songMisses >= 10) ratingFC = "Clear";
		}
		setOnLuas('rating', ratingPercent);
		setOnLuas('ratingName', ratingName);
		setOnLuas('ratingFC', ratingFC);
	}

	#if ACHIEVEMENTS_ALLOWED
	private function checkForAchievement(achievesToCheck:Array<String> = null):String
	{
		if(chartingMode) return null;

		var usedPractice:Bool = (ClientPrefs.getGameplaySetting('practice', false) || ClientPrefs.getGameplaySetting('botplay', false));
		for (i in 0...achievesToCheck.length) {
			var achievementName:String = achievesToCheck[i];
			if(!Achievements.isAchievementUnlocked(achievementName) && !cpuControlled) {
				var unlock:Bool = false;
				switch(achievementName)
				{
					case 'week1_nomiss' | 'week2_nomiss' | 'week3_nomiss' | 'week4_nomiss' | 'week5_nomiss' | 'week6_nomiss':
						if(isStoryMode && campaignMisses + songMisses < 1 && CoolUtil.difficultyString() == 'HARD' && storyPlaylist.length <= 1 && !changedDifficulty && !usedPractice)
						{
							var weekName:String = WeekData.getWeekFileName();
							switch(weekName) //I know this is a lot of duplicated code, but it's easier readable and you can add weeks with different names than the achievement tag
							{
								case 'week1':
									if(achievementName == 'week1_nomiss') unlock = true;
								case 'week2':
									if(achievementName == 'week2_nomiss') unlock = true;
								case 'week3':
									if(achievementName == 'week3_nomiss') unlock = true;
								case 'week4':
									if(achievementName == 'week4_nomiss') unlock = true;
								case 'week5':
									if(achievementName == 'week5_nomiss') unlock = true;
								case 'week6':
									if(achievementName == 'week6_nomiss') unlock = true;
							}
						}
					case 'ur_bad':
						if(ratingPercent < 0.2 && !practiceMode) {
							unlock = true;
						}
					case 'ur_good':
						if(ratingPercent >= 1 && !usedPractice) {
							unlock = true;
						}
					case 'roadkill_enthusiast':
						if(Achievements.henchmenDeath >= 100) {
							unlock = true;
						}
					case 'oversinging':
						if(boyfriend.holdTimer >= 10 && !usedPractice) {
							unlock = true;
						}
					case 'hype':
						if(!boyfriendIdled && !usedPractice) {
							unlock = true;
						}
					case 'two_keys':
						if(!usedPractice) {
							var howManyPresses:Int = 0;
							for (j in 0...keysPressed.length) {
								if(keysPressed[j]) howManyPresses++;
							}

							if(howManyPresses <= 2) {
								unlock = true;
							}
						}
					case 'toastie':
						if(/*ClientPrefs.framerate <= 60 &&*/ ClientPrefs.data.lowQuality && !ClientPrefs.data.antialiasing) {
							unlock = true;
						}
					case 'debugger':
						if(Paths.formatToSongPath(SONG.song) == 'test' && !usedPractice) {
							unlock = true;
						}
				}

				if(unlock) {
					Achievements.unlockAchievement(achievementName);
					return achievementName;
				}
			}
		}
		return null;
	}
	#end

	override public function switchTo(nextState: Dynamic){
		if(isPixelStage != stageData.isPixelStage)
			isPixelStage = stageData.isPixelStage;

		if(FlxG.sound.music!=null) // so if you leave and debug console comes up and you bring it down it wont replay the fuckin song and break EVERYTHING!!!
			FlxG.sound.music.onComplete=null;

		return super.switchTo(nextState);
	}

	var curLight:Int = -1;
	var curLightEvent:Int = -1;
}