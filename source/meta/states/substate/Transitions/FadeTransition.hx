package meta.states.substate.transitions;

import flixel.addons.transition.TransitionSubstate;
import flixel.addons.transition.FlxTransitionSprite.TransitionStatus;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.math.FlxMath;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import flixel.FlxG;
import flixel.util.FlxColor;

class FadeTransition extends TransitionSubstate
{
  var _finalDelayTime:Float = 0.0;

  public static var defaultCamera:FlxCamera;
  public static var nextCamera:FlxCamera;

  var curStatus:TransitionStatus;

  var fade:FlxSprite;

  public function new(){
    super();
  }

  public override function destroy():Void
  {
    super.destroy();
    finishCallback = null;

    fade?.destroy();
  }

  function onFinish(f:FlxTimer):Void
  {
    if (finishCallback != null)
    {
      finishCallback();
      finishCallback = null;
    }
  }

  function delayThenFinish():Void
  {
    new FlxTimer().start(_finalDelayTime, onFinish); // force one last render call before exiting
  }

  public override function update(elapsed:Float){
    super.update(elapsed);
  }


  override public function start(status: TransitionStatus){
    var curCamera = nextCamera!=null?nextCamera:(defaultCamera!=null?defaultCamera:FlxG.cameras.list[FlxG.cameras.list.length - 1]);
    cameras = [curCamera];
    nextCamera = null;
    curStatus=status;

    var zoom:Float = FlxMath.bound(curCamera.zoom,0.001);
    var width:Int = Math.ceil(curCamera.width/zoom);
    var height:Int = Math.ceil(curCamera.height/zoom);

    fade = new FlxSprite().makeGraphic(1,1,FlxColor.BLACK);
    fade.setGraphicSize(width,height);
    fade.updateHitbox();
    fade.screenCenter();
    fade.scrollFactor.set();
    add(fade);

    
    var duration:Float = .48;
    var targetAlpha:Float = 1;
    switch(status){
      case IN:

        fade.alpha = 0;

      case OUT:
        targetAlpha = 0;

      default:
    }

    FlxTween.tween(fade,{alpha: targetAlpha},duration, {onComplete: Void-> {
      delayThenFinish();
    }});

  }
}
