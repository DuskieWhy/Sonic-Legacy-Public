package gameObjects;

import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import meta.data.*;
import meta.states.*;

class StupidFuckingCursorDumb extends FlxSprite
{
	public var mouseInterest:Bool;
	public var mouseDisabled:Bool;
    public var mouseWaiting:Bool;
    public var mouseLockon:Bool = true;

	public function new(x:Float = 0, y:Float = 0, ?camera:FlxCamera, scaleX:Float = 0.4, scaleY:Float = 0.4) {
		super(x, y);
        if (camera == null) camera = FlxG.cameras.list[FlxG.cameras.list.length-1];

        frames = Paths.getSparrowAtlas('userinterface/cursor');
        animation.addByPrefix("idle", "idle0", 1, true);
        animation.addByPrefix("idleClick", "idleClick", 1, true);
        animation.addByPrefix("hand", "hand0", 1, true);
        animation.addByPrefix("handClick", "handClick", 1, true);
        animation.addByPrefix("waiting", "waiting", 8, true);
        animation.addByPrefix("disabledClick", "disabledClick", 1, true);
        animation.addByPrefix("disabled", "disabled", 1, true);
        animation.play("idle");
        cameras = [camera];
        scale.x = scaleX;
        scale.y = scaleY;
        updateHitbox();
        antialiasing = ClientPrefs.data.antialiasing;
	}

    override function update(elapsed:Float){
        super.update(elapsed);

        if (mouseLockon) setPosition(FlxG.mouse.getScreenPosition(camera).x, FlxG.mouse.getScreenPosition(camera).y);
        
        if (mouseWaiting) {
            animation.play("waiting");
        } else {
            animation.play(mouseInterest?"hand":"idle",true);
            if (mouseDisabled) {
                animation.play("disabled",true);
                if (FlxG.mouse.pressed) animation.play("disabledClick",true);
                if (FlxG.mouse.justPressed) FlxG.sound.play(Paths.sound('windowsXPding'), 0.6);
            } else {
                if (FlxG.mouse.pressed) animation.play(mouseInterest?"handClick":"idleClick",true);
                if (FlxG.mouse.justPressed) FlxG.sound.play(Paths.sound('windowsXPclick'), 1);
            }
            
        }

    }
}
