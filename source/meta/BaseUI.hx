package meta;

import gameObjects.HealthIcon;
import flixel.group.FlxSpriteGroup;
import flixel.FlxObject;
import flixel.ui.FlxBar;
import meta.states.PlayState;
import flixel.FlxBasic;

//not done!
class BaseUI extends FlxBasic 
{

    public function new() {
        super(); 
        current = PlayState.instance;
        current.uiHandler.push(this);
        createHPbar();
    }
    private var current:PlayState = PlayState.instance;

    private var songMisses(get,never):Float;
    private var songScore(get,never):Float;
    private var ratingPercent(get,never):Float;
    private var ratingName(get,never):String;
    private var ratingFC(get,never):String;
    private var camHUD(get,never):FlxCamera;

	public var healthBar(get, never):FlxBar;
    public var iconP1(get, never):HealthIcon;
    public var iconP2(get, never):HealthIcon;
    public var uiGroup(get, never):FlxSpriteGroup;

    public var curBeat(get,never):Int;
    // public var curStep:Int = 0;
    // public var curSection:Int = 0;

    public function createUI() {}
    public function sort() {}
    public function onUpdateScore() {}
    public function onHealthChange() {}
    public function onBeatHit() {}

    public function onEventTrigger(eventName:String,val1:String,val2:String) {}

    public function add(i:FlxSprite) {PlayState.instance.uiGroup.add(i);}
    public function remove(i:FlxSprite) {PlayState.instance.uiGroup.remove(i);}
    public function createHPbar(x:Float=0,y:Float=0,width:Int=100,height:Int=100,filldir:FlxBarFillDirection=RIGHT_TO_LEFT) {PlayState.instance.updateHPBar(x,y,width,height,filldir);}

    function get_iconP1():HealthIcon {return PlayState.instance.iconP1;}
    function get_iconP2():HealthIcon {return PlayState.instance.iconP2;}
    function get_healthBar():FlxBar {return PlayState.instance.healthBar;}
    function get_uiGroup():FlxSpriteGroup {return PlayState.instance.uiGroup;}

    function get_songMisses():Float {return PlayState.instance.songMisses;}
    function get_songScore():Float {return PlayState.instance.songScore;}
    function get_ratingName():String {return PlayState.instance.ratingName;}
    function get_ratingFC():String {return PlayState.instance.ratingFC;}
    function get_ratingPercent():Float {return PlayState.instance.ratingPercent;}

    function get_camHUD():FlxCamera {return PlayState.instance.camHUD;}

    public function getVar(obj:String):FlxObject
    {
        var object = Reflect.getProperty(this,obj);
        return object;
    }

    public static function getCurrentUI() {
        return PlayState.instance.uiHandler[0];
    }

    function get_curBeat():Int {
        @:privateAccess
        return PlayState.instance.curBeat;
    }
    

        
    

}