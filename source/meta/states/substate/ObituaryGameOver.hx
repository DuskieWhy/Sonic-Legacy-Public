package meta.states.substate;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSubState;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import gameObjects.*;
import meta.states.*;
import meta.data.*;

class ObituaryGameOver extends MusicBeatSubstate
{
	public var boyfriend:Boyfriend;
	var camFollow:FlxPoint;
	var camFollowPos:FlxObject;
	var updateCamera:Bool = false;
	var playingDeathSound:Bool = false;

	var stageSuffix:String = "";

	public static var characterName:String = 'bf-dead';
	public static var deathSoundName:String = 'fnf_loss_sfx';
	public static var loopSoundName:String = 'gameOver';
	public static var endSoundName:String = 'gameOverEnd';

	public static var instance:ObituaryGameOver;

	public static function resetVariables() {
		characterName = 'bf-dead';
		deathSoundName = 'fnf_loss_sfx';
		loopSoundName = 'gameOver';
		endSoundName = 'gameOverEnd';
	}


	override function create()
	{
		instance = this;
		PlayState.instance.callOnScripts('onGameOverStart', []);

		super.create();
	}

	var death:Alphabet;
	var retry:Alphabet = null;

	public function new(x:Float = 0, y:Float = 0, camX:Float = 0, camY:Float = 0)
	{
		super();

		PlayState.instance.setOnScripts('inGameOver', true);

		Conductor.songPosition = 0;

		// boyfriend = new Boyfriend(x, y, characterName);
		// boyfriend.x += boyfriend.positionArray[0];
		// boyfriend.y += boyfriend.positionArray[1];
		// add(boyfriend);

		//camFollow = new FlxPoint(boyfriend.getGraphicMidpoint().x, boyfriend.getGraphicMidpoint().y);

		(FlxG.sound.play(Paths.sound('obDeath2'))).onComplete = () -> {
			coolStartDeath();
			var text:Array<Array<String>> = [
				['This approach','excites me','Shall we go again?'],
				['A new game to play','with an older face','to greet'],
				['Nothing like the','first round','Or am I mistaken?']
		
			];

			var theTxt:Int = FlxG.random.int(0,2);
			for (i in 0...text.length) {
				var d = new Alphabet(0,0,text[theTxt][i],true,false,0);
				d.screenCenter();
				d.y += (100 * (i - (text.length / 2)));
				add(d);
			}
			retry = new Alphabet(0,0,'retry?',true);
			retry.color = FlxColor.YELLOW;
			retry.screenCenter();
			retry.y += (100 * (3 - (3 / 2)));
			add(retry);

			retry.visible = false;
			new FlxTimer().start(5, Void-> {retry.visible = true;});


		};

		
		//Conductor.changeBPM(100);
		// FlxG.camera.followLerp = 1;
		// FlxG.camera.focusOn(FlxPoint.get(FlxG.width / 2, FlxG.height / 2));
		FlxG.camera.scroll.set();
		FlxG.camera.target = null;
		FlxG.camera.zoom = 1;


		//boyfriend.playAnim('firstDeath');

		camFollowPos = new FlxObject(0, 0, 1, 1);
		camFollowPos.setPosition(FlxG.camera.scroll.x + (FlxG.camera.width / 2), FlxG.camera.scroll.y + (FlxG.camera.height / 2));
		add(camFollowPos);

		


	}

	var isFollowingAlready:Bool = false;
	override function update(elapsed:Float)
	{
		PlayState.instance.callOnScripts('onUpdate', [elapsed]);
		PlayState.instance.callOnHScripts('update', [elapsed]);
		super.update(elapsed);

		PlayState.instance.callOnScripts('onUpdatePost', [elapsed]);
		if(updateCamera) {
			var lerpVal:Float = FlxMath.bound(elapsed * 0.6, 0, 1);
			camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));
		}

		if (controls.ACCEPT && retry?.visible)
		{
			endBullshit();
		}

		if (controls.BACK)
		{
			FlxG.sound.music.stop();
			PlayState.deathCounter = 0;
			PlayState.seenCutscene = false;

			ProgressionHandler.loadMainMenuState();

			// if (PlayState.isStoryMode)
			// 	if (ProgressionHandler.isRodent) MusicBeatState.switchState(new StoryMenuState());
			// else
			// 	MusicBeatState.switchState(new FreeplayState());

			FlxG.sound.playMusic(ProgressionHandler.getMenuMusic());
			PlayState.instance.callOnScripts('onGameOverConfirm', [false]);
		}

		if (FlxG.sound.music.playing)
		{
			Conductor.songPosition = FlxG.sound.music.time;
		}
		PlayState.instance.callOnLuas('onUpdatePost', [elapsed]);
	}

	override function beatHit()
	{
		super.beatHit();

		//FlxG.log.add('beat');
	}

	var isEnding:Bool = false;

	function coolStartDeath(?volume:Float = 1):Void
	{
		FlxG.sound.playMusic(Paths.music('obituaryDeath'), volume);
	}

	function endBullshit():Void
	{
		if (!isEnding)
		{
			isEnding = true;
			//boyfriend.playAnim('deathConfirm', true);
			FlxG.sound.music.stop();
			FlxG.sound.play(Paths.music(endSoundName));
			new FlxTimer().start(0.7, function(tmr:FlxTimer)
			{
				FlxG.camera.fade(FlxColor.BLACK, 2, false, function()
				{
					MusicBeatState.resetState();
				});
			});
			PlayState.instance.callOnLuas('onGameOverConfirm', [true]);
		}
	}
}
