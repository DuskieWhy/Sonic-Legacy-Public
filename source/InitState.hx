import meta.states.MusicBeatState;
import meta.states.substate.transitions.SwipeTransitionSubstate;
import meta.states.substate.transitions.FadeTransition;
import flixel.addons.transition.FlxTransitionableState;
import meta.states.TitleState;
import meta.states.StoryMenuState;
import meta.data.Highscore;
import meta.data.PlayerSettings;
import meta.data.WeekData;
import flixel.input.keyboard.FlxKey;
import flixel.FlxState;


class InitState extends FlxState
{

    public static var muteKeys:Array<FlxKey> = [FlxKey.ZERO];
	public static var volumeDownKeys:Array<FlxKey> = [FlxKey.NUMPADMINUS, FlxKey.MINUS];
	public static var volumeUpKeys:Array<FlxKey> = [FlxKey.NUMPADPLUS, FlxKey.PLUS];
	

    override function create() 
    {

        meta.data.scripts.FunkinHScript.init();
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();

		Paths.pushGlobalMods();
		WeekData.loadTheFirstEnabledMod();

		FlxG.game.focusLostFramerate = 60;
		FlxG.sound.muteKeys = muteKeys;
		FlxG.sound.volumeDownKeys = volumeDownKeys;
		FlxG.sound.volumeUpKeys = volumeUpKeys;
		FlxG.keys.preventDefaultKeys = [TAB];

		PlayerSettings.init();
		
		#if DISCORD_ALLOWED
		if (!DiscordClient.isInitialized)
		{
			DiscordClient.initialize();
			Application.current.onExit.add (function (exitCode) {
				DiscordClient.shutdown();
			});
		}
		#end

		FlxG.signals.gameResized.add((width,height)->{
			@:privateAccess {
				if (FlxG.cameras != null)for (cam in FlxG.cameras.list) if (cam != null && cam._filters != null) Main.resetSpriteCache(cam.flashSprite);
				if (FlxG.game != null) Main.resetSpriteCache(FlxG.game);
			}
		});

		super.create();

		FlxG.save.bind('funkin', 'ninjamuffin99');

		ClientPrefs.loadPrefs();

		Highscore.load();

		ProgressionHandler.load();

		if(FlxG.save.data != null && FlxG.save.data.fullscreen)
		{
			FlxG.fullscreen = FlxG.save.data.fullscreen;
		}
	
		if (FlxG.save.data.weekCompleted != null)
		{
			StoryMenuState.weekCompleted = FlxG.save.data.weekCompleted;
		}

		trace(FlxG.save.data.isRodent);
		if (FlxG.save.data.isRodent != null) {
			FlxTransitionableState.defaultTransIn = SwipeTransitionSubstate;
			FlxTransitionableState.defaultTransOut = SwipeTransitionSubstate;
			FlxG.switchState(new WelcomeBack());
		}
        else if (!ProgressionHandler.isRodent) {
            trace('new freaking state for supa evil');
            
			FlxTransitionableState.defaultTransIn = FadeTransition;
			FlxTransitionableState.defaultTransOut = FadeTransition;
			MusicBeatState.switchState(new meta.states.desktop.LegacyTitleState());
        }
        else {
			FlxTransitionableState.defaultTransIn = SwipeTransitionSubstate;
			FlxTransitionableState.defaultTransOut = SwipeTransitionSubstate;
			MusicBeatState.switchState(new TitleState());
        }



    }
}