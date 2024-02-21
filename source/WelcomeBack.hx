package;

import meta.states.substate.desktoptions.ResetSubstate;
import gameObjects.Alphabet;
import flixel.FlxState;

import flixel.addons.transition.FlxTransitionSprite.GraphicTransTileDiamond;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.transition.TransitionData;
import meta.states.substate.transitions.SwipeTransitionSubstate;


class WelcomeBack extends FlxState
{

    var text:Alphabet;

    override function create() 
    {
        super.create();

        text = new Alphabet(0,0,'HELLO AGAIN FRIEND',true,false);
        add(text);
        text.screenCenter();
        text.visible = false;

        ResetSubstate.destroyData(true,true);
        ClientPrefs.loadPrefs();
        ProgressionHandler.load();

        new FlxTimer().start(2,Void->{
            text.visible = true;
            new FlxTimer().start(4,Void->{
                text.visible = false;
                new FlxTimer().start(1,Void->{FlxG.switchState(new meta.states.TitleState());});
            });
        });

        FlxTransitionableState.defaultTransIn = SwipeTransitionSubstate;
        FlxTransitionableState.defaultTransOut = SwipeTransitionSubstate;

    }
}

