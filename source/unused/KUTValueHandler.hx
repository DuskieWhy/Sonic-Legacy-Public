package meta.states;

import flixel.FlxG;
import flixel.text.FlxText;
import flixel.util.FlxTimer;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import meta.states.*;

class KUTValueHandler extends MusicBeatState
{
    var theKutText:FlxText;
    var theEvilValue:Float = 0;
    var theEvilTime:Bool = false;

    override public function create(){
        if(FlxG.save.data.KUTValue == null){
            FlxG.save.data.KUTValue = FlxG.random.int(1, 100);
            FlxG.save.flush();    
                
            theKutText = new FlxText(0, 0, 0, "", 32);
            theKutText.alpha = 0;
            theKutText.text = FlxG.save.data.KUTValue;
            theKutText.screenCenter();
            add(theKutText);

            FlxTween.tween(theKutText, {alpha: 1}, 5, {onComplete:function(shit:FlxTween){
                FlxTween.tween(theKutText, {alpha: 0}, 5, {onComplete: function(poop:FlxTween){
                    MusicBeatState.switchState(new MainMenuState());
                }});
            }});
        }else{
            trace(FlxG.save.data.KUTValue);
            MusicBeatState.switchState(new MainMenuState());
        }

    }
}