
var grp:Array<FlxSprite> = [];

var cutscene:PsychVideoSprite;

var introAnim:FlxSprite;

var black:FlxSprite;

function onLoad(){

    addBG();

    black = new FlxSprite();
    ObjectTools.generateGraphic(black,FlxG.width,FlxG.height,0xFF000000);
    black.cameras = [game.camOther];
    add(black);

    black.visible = false;

    cutscene = new PsychVideoSprite();
    cutscene.load(Paths.video('cutscene'), [PsychVideoSprite.muted]);
    cutscene.scrollFactor.set();
    add(cutscene);
    cutscene.antialiasing = ClientPrefs.data.antialiasing;
    cutscene.cameras = [game.camHUD];
    foreground.add(cutscene);
    cutscene.addCallback('onEnd',()->{
        camGame.visible = false;
        camHUD.visible = false;
        cutscene.destroy();
    });

    game.skipCountdown = true;
}

function onSongStart(){
    game.isCameraOnForcedPos = true;
    game.camHUD.alpha = 0;

    var x = 260;
    var y = 350;
    game.camFollow.set(x,y);
    game.camFollowPos.setPosition(x,y);
    game.camGame.zoom = 1.25;
    FlxTween.tween(game.camFollow, {y: 616},0.4, {ease: FlxEase.sineInOut,startDelay: 0.1});

    var spr = grp[grp.length-1];
    FlxTween.tween(spr, {alpha: 0.3},1.2);

    game.dad.visible = false;
    introAnim.animation.play('intro');
}

function onUpdate(elapsed:Float) {

}

function onEvent(eventName, value1, value2){
    switch (eventName) {
        case '':
            switch (value1) {
                case 'startIntro':
                    game.isCameraOnForcedPos = true;
                    game.camHUD.alpha = 0;
                
                    var x = 260;
                    var y = 350;
                    game.camFollow.set(x,y);
                    game.camFollowPos.setPosition(x,y);
                    game.camGame.zoom = 1.25;
                    FlxTween.tween(game.camFollow, {y: 616},0.4, {ease: FlxEase.sineInOut,startDelay: 0.1});
                
                    var spr = grp[grp.length-1];
                    FlxTween.tween(spr, {alpha: 0.3},1.2);
                
                    game.dad.visible = false;
                    introAnim.animation.play('intro');

                case 'end':
                    game.isCameraOnForcedPos = true;
                    var spr = grp[grp.length-1];
                    FlxTween.tween(spr, {alpha: 0.3},0.7, {ease: FlxEase.cubeIn});
                    FlxTween.tween(game.camFollowPos, {x: 350, y: 616},0.6, {ease: FlxEase.cubeIn});
                    FlxTween.tween(game.camGame, {zoom: 1.5},0.6, {ease: FlxEase.cubeIn, onComplete: function (f:FlxTween) {
    
                        cutscene.alpha = 1;
                        cutscene.play();
                        //game.camOther.flash(0.25,0xFFFFFFFF);
                        game.triggerEventNote('Camera Flash','camOther','0.25');
                    }});

                case 'lookright':
                    FlxTween.tween(game.camFollow, {x: 500},0.7, {ease: FlxEase.sineInOut});
                    FlxTween.tween(game.camGame, {zoom: 1.},0.7, {ease: FlxEase.sineInOut});
                    var spr = grp[grp.length-1];
                    FlxTween.tween(spr, {alpha: 1},0.7, {ease: FlxEase.sineInOut});
                case 'begin':
                    var x = game.dad.getMidpoint().x + 150 + game.dad.cameraPosition[0] + game.opponentCameraOffset[0];
                    var y = game.dad.getMidpoint().y - 100 + game.dad.cameraPosition[1] + game.opponentCameraOffset[1];

                    FlxTween.tween(game.camFollowPos, {x: x,y: y},1.3, {ease: FlxEase.sineInOut});
                    FlxTween.tween(game.camGame, {zoom: 0.65},1.3, {ease: FlxEase.sineInOut});
                    
                    game.camHUD.zoom = 1.2;
                    FlxTween.tween(game.camHUD, {alpha: 1,zoom: 1},1.3, {ease: FlxEase.sineInOut, onComplete: function (f:FlxTween) {
                        game.isCameraOnForcedPos = false;
                    }});       

            }
    }
}


function addBG() {
    addObject('whatsupthesky',0.825,[0.4,0.4],'xy',[-100,0],false,1);

    addObject1('biggerbackrocks','bgFiles',0.825,[0.5,0.5],'xy',[0,0],false,1,12);
    
    addObject1('backrocks','bgFiles',0.825,[0.5,0.5],'xy',[-50,0],false,1,12);

    addObject1('agua','waterfall',0.825,[0.5,0.5],'xy',[0,0],false,1,12);

    addObject1('mmmpalms','bgFiles',0.825,[0.85,0.85],'xy',[0,0],false,1,12);

    addObject1('ground','bgFiles',0.825,[1,1],'x',[0,500],false,1,12);

    introAnim = new FlxSprite(-22,362);
    introAnim.frames = Paths.getSparrowAtlas('stages/obituary/p1/Sonic_Turn');
    introAnim.antialiasing = ClientPrefs.data.antialiasing;
    introAnim.animation.addByPrefix('intro', 'intro', 24, false);
    introAnim.animation.finishCallback = function (n:String) {
        game.dad.visible = true;
        introAnim.visible = false;
        introAnim.destroy();
        introAnim = null;
    }
    foreground.add(introAnim);

    addObject1('frontobjects','bgFiles',1,[1.25,1.25],'x',[210 + 150,400],true,1,12);
}


//quick and dirty setup
function addObject(path:String,scale:Float,scrollF:Array<Float>,centerAxis:String,offsets:Array<Float>,isForeground:Bool,phase:Int) {
    var dir = 'obituary';
    if (phase == 1) dir = 'sunset'; 
    var f = new FlxSprite().loadGraphic(Paths.image('stages/' + dir + '/' + path));
    ObjectTools.setScale(f,scale);
    f.scrollFactor.set(scrollF[0],scrollF[1]);
    if (centerAxis == 'x') f.screenCenter(FlxAxes.X);
    else if (centerAxis == 'y') f.screenCenter(FlxAxes.Y);
    else if (centerAxis == 'xy') f.screenCenter();
    f.x += offsets[0];
    f.y += offsets[1];
    if (isForeground) foreground.add(f);
    else add(f);
    grp.push(f);
    f.antialiasing = ClientPrefs.data.antialiasing;
}

function addObject1(image:String,path:String,scale:Float,scrollF:Array<Float>,centerAxis:String,offsets:Array<Float>,isForeground:Bool,phase:Int,fps:Int) {
    var dir = 'obituary';
    if (phase == 1) dir = 'sunset'; 
    var f = new FlxSprite();
    f.frames = Paths.getSparrowAtlas('stages/' + dir + '/' + path);
    f.animation.addByPrefix('i',image,fps);
    f.animation.play('i');
    
    ObjectTools.setScale(f,scale);
    f.scrollFactor.set(scrollF[0],scrollF[1]);
    if (centerAxis == 'x') f.screenCenter(FlxAxes.X);
    else if (centerAxis == 'y') f.screenCenter(FlxAxes.Y);
    else if (centerAxis == 'xy') f.screenCenter();
    f.x += offsets[0];
    f.y += offsets[1];
    if (isForeground) foreground.add(f);
    else add(f);
    grp.push(f);
    f.antialiasing = ClientPrefs.data.antialiasing;
}
