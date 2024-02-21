package meta.states; 

import flixel.addons.display.FlxBackdrop;
#if desktop
import sys.thread.Thread;
#end
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.input.keyboard.FlxKey;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.transition.FlxTransitionSprite.GraphicTransTileDiamond;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.transition.TransitionData;
import haxe.Json;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
#if MODS_ALLOWED
import sys.FileSystem;
import sys.io.File;
#end
//import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup;
import flixel.input.gamepad.FlxGamepad;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxSound;
import flixel.system.ui.FlxSoundTray;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import lime.app.Application;
import openfl.Assets;
import meta.data.*;
import meta.data.options.*;
import meta.states.*;
import meta.states.substate.*;
import gameObjects.*;
import gameObjects.shader.*;
import flixel.effects.FlxFlicker;

using StringTools;

class TitleState extends MusicBeatState
{
	public static var initialized:Bool = false;


	var rSonicOverlay:FlxSprite;
	var rSonic:FlxSprite;
	var rLogo:FlxSprite;
	var rLogoBop:FlxTween = null;
	var camBop:FlxTween = null;

	var pressStartTxt:FlxText;

	var pressSine:Float = 0.0;

	var blackScreen:FlxSprite;

	var rShowTitle:Bool = false;

	override public function create():Void
	{

		MainMenuState.fromTitle = true;
		if(!initialized)
		{
			persistentUpdate = true;
			persistentDraw = true;
		}

		FlxG.mouse.visible = false;
		#if FREEPLAY
		MusicBeatState.switchState(new FreeplayState());
		#elseif CHARTING
		MusicBeatState.switchState(new ChartingState());
		#else

		new FlxTimer().start(1, function(tmr:FlxTimer)
		{
			startIntro();
		});

		#end
	}

	var danceLeft:Bool = false;

	function startIntro()
	{
		if (!initialized)
		{
			// FlxTransitionableState.defaultTransIn = FadeTransitionSubstate;
			// FlxTransitionableState.defaultTransOut = FadeTransitionSubstate;

			if(FlxG.sound.music == null) {

				FlxG.sound.playMusic(ProgressionHandler.getMenuMusic(), 0);

				FlxG.sound.music.fadeIn(1.5, 0.0, 1.0);
			}
		}

		Conductor.changeBPM(128);
		persistentUpdate = true;


		var bg = new FlxBackdrop(Paths.image('userinterface/title/city'));
		bg.velocity.x = 100;
		bg.antialiasing = ClientPrefs.data.antialiasing;
		add(bg);

		rSonicOverlay = new FlxSprite(500, -100).loadGraphic(Paths.image('userinterface/title/sonic'));
		rSonicOverlay.antialiasing = ClientPrefs.data.antialiasing;
		rSonicOverlay.scale.set(0.9, 0.9);
		rSonicOverlay.updateHitbox();
		rSonicOverlay.blend = MULTIPLY;
		rSonicOverlay.clipRect = new FlxRect(0,0,rSonicOverlay.width-250,rSonicOverlay.height);
		add(rSonicOverlay);

		var bar = new FlxSprite().generateGraphic(FlxG.width,124, FlxColor.BLACK);
		add(bar);

		var bar = new FlxSprite(0,FlxG.height-124).generateGraphic(FlxG.width,124, FlxColor.BLACK);
		add(bar);



		rSonic = new FlxSprite(532, -65).loadGraphic(Paths.image('userinterface/title/sonic'));
		rSonic.antialiasing = ClientPrefs.data.antialiasing;
		rSonic.scale.set(0.675, 0.675);
		add(rSonic);

		rLogo = new FlxSprite(-160, 170).loadGraphic(Paths.image('userinterface/title/rodentraplogo'));
		rLogo.antialiasing = ClientPrefs.data.antialiasing;
		rLogo.scale.set(0.675, 0.675);
		add(rLogo);

		pressStartTxt = new FlxText(188, 510, 0, "Press ENTER to start!", 32);
		pressStartTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		pressStartTxt.scrollFactor.set();
		pressStartTxt.borderSize = 1.25;
		pressStartTxt.antialiasing = ClientPrefs.data.antialiasing;
		add(pressStartTxt);
			

		blackScreen = new FlxSprite((FlxG.width * -1) / 2, (FlxG.height * -1)).makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
		add(blackScreen);

		if (closedState)
			{
				rShowTitle = true;
				blackScreen.visible = false;
			}

		if (initialized) skippedIntro = true;
		else initialized = true;

	}

	var transitioning:Bool = false;

	var tmr:Float = 15;
	var playingVideo:Bool = false;

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music != null)
			Conductor.songPosition = FlxG.sound.music.time;
		// FlxG.watch.addQuick('amp', FlxG.sound.music.amplitude);

		tmr -= elapsed;

		if (tmr <= 0 && !playingVideo) {
			playingVideo = true;
			FlxG.sound.music.fadeOut(2,0, Void -> {FlxG.sound.music.destroy(); FlxG.sound.music = null;});
			var b = new FlxSprite().generateGraphic(FlxG.width,FlxG.height,FlxColor.BLACK);
			b.alpha = 0;
			add(b);
			FlxTween.tween(b, {alpha: 1},2, {onComplete: Void -> {
				var vid = new FlxVideo();
				vid.onEndReached.add(()->{
					vid.dispose();
					trace('work');

					initialized = false;

					MusicBeatState.resetState();
				},true);
				vid.load(Paths.video('intro'));
				vid.play();
			

			}});


			//play video
		}
		if (controls.UI_DOWN || controls.UI_UP || controls.UI_LEFT || controls.UI_RIGHT || controls.ACCEPT) tmr = 15;

		var pressedEnter:Bool = FlxG.keys.justPressed.ENTER || controls.ACCEPT;

		#if mobile
		for (touch in FlxG.touches.list)
		{
			if (touch.justPressed)
			{
				pressedEnter = true;
			}
		}
		#end

		var gamepad:FlxGamepad = FlxG.gamepads.lastActive;

		if (gamepad != null)
		{
			if (gamepad.justPressed.START)
				pressedEnter = true;

			#if switch
			if (gamepad.justPressed.B)
				pressedEnter = true;
			#end
		}

		if (initialized && !transitioning && skippedIntro && !playingVideo)
		{
			if(pressedEnter)
			{
				if (ClientPrefs.data.flashing) FlxG.camera.flash(FlxColor.WHITE, 1);
				FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);

				transitioning = true;
				if (pressStartTxt != null) {
					pressStartTxt.alpha = 1.0;
					pressStartTxt.color = FlxColor.YELLOW;
					FlxFlicker.flicker(pressStartTxt, 1, 0.06, true, true);
				}


				new FlxTimer().start(1, function(tmr:FlxTimer)
				{
					MusicBeatState.switchState(new MainMenuState());
					closedState = true;
				});
			}
		}

		if (initialized && !skippedIntro)
		{
			skippedIntro = true;
		}

		// if (pressStartTxt != null && FlxG.mouse.pressed)
		// 	{
		// 		pressStartTxt.x = FlxG.mouse.x;
		// 		pressStartTxt.y = FlxG.mouse.y;
		// 		trace(pressStartTxt);
		// 	}

		if (pressStartTxt != null && !transitioning)
			{
				pressSine += 80 * elapsed;
				pressStartTxt.alpha = 1 - Math.sin((Math.PI * pressSine) / 80);
			}

		super.update(elapsed);
	}

	private var sickBeats:Int = 1; //Basically curBeat but won't be skipped if you hold the tab or resize the screen
	public static var closedState:Bool = false;
	override function beatHit()
	{
		super.beatHit();
		
		if (sickBeats % 4 == 0)
			{

					if(rLogoBop != null) rLogoBop.cancel();
					rLogo.scale.set(0.725, 0.725);
					rLogoBop = FlxTween.tween(rLogo, {'scale.x': 0.675, 'scale.y': 0.675}, 0.5, {ease: FlxEase.quartOut});
	
					if(camBop != null) camBop.cancel();
					camBop = FlxTween.num(1.015, 1.0, 0.25, {ease: FlxEase.quartOut}, function(v:Float)
						{
							FlxG.camera.zoom = v;
						});
					

				if (!rShowTitle && !closedState)
					{
						rShowTitle = true;
						if (ClientPrefs.data.flashing) FlxG.camera.flash(0xD0FFFFFF, 1.25);
						blackScreen.visible = false;
					}
			}

		if(!closedState) 
		{
			sickBeats++;
		}
	}

	var skippedIntro:Bool = false;
}
