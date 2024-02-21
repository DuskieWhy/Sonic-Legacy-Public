package meta.states.desktop;
//help me bro...... i forgot how to do source code modding.........
// suucks to suuucck

import meta.states.substate.MusicBeatSubstate;
import meta.data.options.OptionsState;
import flixel.tweens.FlxEase;
import flixel.math.FlxMath;
import flixel.tweens.FlxTween;
import flixel.text.FlxText;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxTimer;
import flixel.addons.transition.FlxTransitionableState;
import flixel.FlxCamera;
import flixel.effects.FlxFlicker;
import meta.states.substate.transitions.FadeTransition;

class LegacyTitleState extends MusicBeatState 
{

    var handTop:FlxSprite;
    var handBot:FlxSprite;
    var startGame:FlxSprite;
    var logo:FlxSprite;

    var music:FlxSound;
    var allowedToEnter:Bool = false;
    
    override function create() {
        FlxG.camera.zoom = 0.35;
        FlxG.mouse.visible = false;

        music = new FlxSound();
        FlxG.sound.list.add(music);
        music.loadEmbedded(Paths.music('Legacytrueintro'));
        music.play();
        music.volume = 0.7;
        music.onComplete = forceComplete;

        FlxG.mouse.visible = false;
        
        handTop = new FlxSprite();
        handTop.loadGraphic(Paths.image("userinterface/title/handTop"));
        handTop.scrollFactor.set(0.5,0.5);
        add(handTop);

        handBot = new FlxSprite();
        handBot.loadGraphic(Paths.image("userinterface/title/handBot"));
        handBot.scrollFactor.set(0.5,0.5);
        add(handBot);

        logo = new FlxSprite();
        logo.loadGraphic(Paths.image("userinterface/title/logo"));
        logo.updateHitbox();
        logo.screenCenter(XY);
        logo.alpha = 0;
        add(logo);

        startGame = new FlxSprite();
        startGame.frames = Paths.getSparrowAtlas('userinterface/title/startGame');
        startGame.animation.addByIndices("idle", "startGame", [0], "", 1, false);
        startGame.animation.addByIndices("press", "startGame", [1], "", 1, true);
        startGame.animation.play("idle");
        startGame.scrollFactor.set(1.5,2);
        add(startGame);

        super.create();

        for (g in [handTop,handBot,startGame]){
            g.updateHitbox();
            g.screenCenter(XY);
            g.scale.set(0,0);
            g.alpha = 0;
            FlxTween.tween(g.scale, {x: 1, y:1}, 1, {ease: FlxEase.quintInOut});
        }

        FlxTween.tween(logo, {alpha: 1}, 0.5, {ease: FlxEase.quintInOut});
        
        startGame.y = logo.y+1012.9;

        new FlxTimer().start(0.2, function(start:FlxTimer){
                FlxTween.tween(FlxG.camera, {zoom: 0.4}, 2, {ease: FlxEase.sineOut});

                FlxTween.tween(handTop,{alpha:1},1,{ease: FlxEase.sineInOut,startDelay: 1});
                FlxTween.tween(handBot,{alpha:1},1,{ease: FlxEase.sineInOut,startDelay: 1});
    
                FlxTween.tween(startGame, {y: logo.y + 1237.75}, 2, {ease: FlxEase.quintInOut});
                FlxTween.tween(handTop, {x: logo.x + 97.6, y: logo.y + 34}, 2, {ease: FlxEase.quintInOut});
                FlxTween.tween(handBot, {x: logo.x + 1069.75, y: logo.y + 639}, 2, {ease: FlxEase.quintInOut});
                new FlxTimer().start(1.6,Void->{
                    wiggle = true;
                    FlxTween.tween(this, {wiggleDistance: 15}, 1, {ease: FlxEase.quadInOut});
    
                    FlxTween.tween(startGame,{alpha:1},1,{ease: FlxEase.sineInOut});
                    new FlxTimer().start(0.8,Void->{allowedStartFade=true; allowedToEnter = true;});
    
                });
                
                
            });

        for (i in members) {
            if (i is FlxSprite){var spr = cast(i,FlxSprite); spr.antialiasing = SaveData.antialiasing;}
        }
        
        // FlxTransitionableState.defaultTransIn = FadeTransition;
        // FlxTransitionableState.defaultTransOut = FadeTransition;

    }

    function forceComplete() {
        allowedToEnter = false;
        transitioning = true;
        FlxFlicker.flicker(startGame, 4, 0.06, true,true);
        FlxG.sound.play(Paths.sound('VERY_intro_sound'));

        new FlxTimer().start(3, function(tmr:FlxTimer){
            music.fadeTween.cancelTween();
            music.fadeOut(1.5);
                FlxG.camera.fade(0xFF000000, 1, false, () -> {
                    new FlxTimer().start(1, function(tmr:FlxTimer){
                        FlxTransitionableState.skipNextTransIn = true;
                        FlxTransitionableState.skipNextTransOut = true;
                        killMusic(); //what happened
                        FlxG.switchState(new DesktopMenuState());
                    });
                });
            });
    }

    override function update(elapsed:Float) {
        if (controls.ACCEPT && allowedToEnter) {
            forceComplete();
        }

      // if(FlxG.keys.justPressed.EIGHT) FlxG.save.erase();

        #if debug
        if (FlxG.keys.justPressed.R){
            FlxTransitionableState.skipNextTransIn = true;
            FlxTransitionableState.skipNextTransOut = true;
            FlxG.resetState();
        }
        #end

        super.update(elapsed);
        
        weewoo += elapsed * 2.8;
        FlxG.camera.scroll.y = 50 + Math.cos(weewoo) * 10;

        if (wiggle){
            doWiggle(handTop, logo.x + 97.6, logo.y + 34, weewoo, wiggleDistance);
            doWiggle(handBot, logo.x + 1069.75, logo.y + 639, weewoo, wiggleDistance, true);
        } else weewoo = 0;
        
        if (!transitioning){
            if (wiggle && allowedStartFade){
                pressSine += 80 * elapsed;
                startGame.alpha = 1 - Math.sin((Math.PI * pressSine) / 80);
            }
        } else {
            startGame.animation.play("press",true);
            startGame.alpha = 1;
        }
    }

    var transitioning:Bool = false;
    var wiggle:Bool = false;
    var wiggleDistance:Float = 0;
    var weewoo:Float = 0;
    var pressSine:Float = 80;
    var allowedStartFade:Bool = false;

    function doWiggle(spr:FlxSprite, x:Float, y:Float, weewwoo:Float, mul:Float, reverse:Bool = false){
        if (reverse) spr.setPosition(x - Math.sin(weewwoo) * mul, y - Math.cos(weewwoo) * mul);
        else spr.setPosition(x + Math.sin(weewwoo) * mul, y + Math.cos(weewwoo) * mul);
        spr.angle = Math.sin(weewwoo) * (mul/7.5);
    }

    function killMusic() {
        music.fadeTween.cancelTween();
        music.stop();
        music.onComplete = null;
    }
}

