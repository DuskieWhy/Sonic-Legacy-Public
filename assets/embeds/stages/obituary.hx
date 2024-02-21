
var fakerBG:Array<FlxSprite> = [];
var scaryBG:Array<FlxSprite> = [];
var thirdBG:Array<FlxSprite> = [];


var video:PsychVideoSprite;
var cutscene:PsychVideoSprite;
var p3Video:PsychVideoSprite;


var kickingAnim:FlxSprite;
var rabbitHead:FlxSprite;
var introAnim:FlxSprite;


var playText:Alphabet;
var boring:FlxSprite;
var boringAlphaBet:Alphabet;
var boringAlphaBet2:Alphabet;


var black:FlxSprite;
var braindeadBF:FlxSprite;
var monitor:FlxSprite;
var blackBars:Array<FlxSprite> = [];
var _static:FlxSprite;

var crtShader = newShader('CRT');
var heatShader:FlxRuntimeShader;

function onLoad(){

    addPhase1();

    addPhase2();

    addPhase3();

    //for (i in fakerBG) i.visible = false;

    for(i in scaryBG) i.visible = false;

    for(i in thirdBG) i.visible = false;

    if (!ClientPrefs.data.lowQuality) {
        heatShader = newShader('heatShader');
    }

    black = new FlxSprite();
    ObjectTools.generateGraphic(black,FlxG.width,FlxG.height,0xFF000000);
    black.cameras = [game.camOther];
    add(black);

    _static = new FlxSprite();
    _static.frames = Paths.getSparrowAtlas('static');
    _static.animation.addByPrefix('idle', 'static idle', 24, true);
    _static.animation.play('idle');
    _static.screenCenter();
    _static.cameras = [game.camOther];
    _static.visible = false;
    add(_static);

    playText = new Alphabet(0,0,'Do you want to play with me?',true, false, 0.0, 0.7);
    add(playText);
    playText.screenCenter();
    playText.cameras = [game.camOther];
    playText.visible = false;

    var boringOffset = 50;
    boring = new FlxSprite().loadGraphic(Paths.image('stages/obituary/boring'));
    add(boring);
    ObjectTools.setScale(boring,0.7);
    boring.screenCenter();
    boring.x += boringOffset;
    boring.cameras = [game.camOther];

    boringAlphabet = new Alphabet(0,0,"you're",true, false, 0.0);
    add(boringAlphabet);
    boringAlphabet.screenCenter();
    boringAlphabet.x += -boring.width + boringOffset;
    boringAlphabet.cameras = [game.camOther];

    boringAlphabet2 = new Alphabet(0,0,"me",true, false, 0.0);
    add(boringAlphabet2);
    boringAlphabet2.screenCenter();
    boringAlphabet2.x += (boring.width/1.25) + boringOffset;
    boringAlphabet2.cameras = [game.camOther];
    
    boring.visible = boringAlphabet.visible = boringAlphabet2.visible = false;
    black.visible = false;

    var blackBar = new FlxSprite();
    ObjectTools.generateGraphic(blackBar,FlxG.width,65,0xFF000000);
    add(blackBar);
    blackBar.cameras = [game.camOther];
    blackBars.push(blackBar);

    var blackBar = new FlxSprite(0,FlxG.height-65);
    ObjectTools.generateGraphic(blackBar,FlxG.width,65,0xFF000000);
    add(blackBar);
    blackBar.cameras = [game.camOther];
    blackBars.push(blackBar);

    var blackBar = new FlxSprite();
    ObjectTools.generateGraphic(blackBar,310,FlxG.height,0xFF000000);
    add(blackBar);
    blackBar.cameras = [game.camOther];
    blackBars.push(blackBar);

    var blackBar = new FlxSprite(980);
    ObjectTools.generateGraphic(blackBar,310,FlxG.height,0xFF000000);
    add(blackBar);
    blackBar.cameras = [game.camOther];
    blackBars.push(blackBar);

    fuckassOverlay = new FlxSprite().loadGraphic(Paths.image('stages/obituary/p2/fuckassOverlay'));
    add(fuckassOverlay);
    ObjectTools.setScale(fuckassOverlay,0.7);
    fuckassOverlay.screenCenter();
    fuckassOverlay.visible = false;
    fuckassOverlay.alpha = 0.7;
    addObjectBlend(fuckassOverlay,"add");
    fuckassOverlay.cameras = [game.camOther];

    braindeadBF = new FlxSprite();
    braindeadBF.frames = Paths.getSparrowAtlas('stages/obituary/p1/bfreflection');
    braindeadBF.animation.addByPrefix('i','braindead',24);
    braindeadBF.animation.play('i');
    braindeadBF.cameras = [game.camOther];
    braindeadBF.screenCenter();
    add(braindeadBF);
    braindeadBF.scale.set(0.85,0.85);

    monitor = new FlxSprite(199.9, -26.6);
    monitor.frames = Paths.getSparrowAtlas('userinterface/desktop/bgLayers');
    monitor.animation.addByPrefix('on','monitorOn instance 1',12);
    monitor.animation.addByPrefix('off','monitorOff instance 1',12);
    monitor.animation.play('on');
    add(monitor);
    monitor.cameras = [game.camOther];
    // game.camOther.zoom = 2.2;
    braindeadBF.alpha = 0;
    monitor.visible = false;
    for (i in blackBars) i.visible = false;


    cutscene = new PsychVideoSprite();
    cutscene.load(Paths.video('cutscene-1'), [PsychVideoSprite.muted]);
    cutscene.scrollFactor.set();
    add(cutscene);
    cutscene.antialiasing = ClientPrefs.data.antialiasing;
    cutscene.cameras = [game.camHUD];
    foreground.add(cutscene);
    cutscene.addCallback('onEnd',()->{
        game.isCameraOnForcedPos = false;
        game.camZooming = true;
        game.triggerEventNote('Obituary','im hungry','');
        cutscene.destroy();
    });

    game.skipCountdown = true;
}

function onSongStart(){
    PlayState.instance.barSongLength = 92250;
    game.isCameraOnForcedPos = true;
    game.camHUD.alpha = 0;

    var x = 260;
    var y = 350;
    game.camFollow.set(x,y);
    game.camFollowPos.setPosition(x,y);
    game.camGame.zoom = 1.25;
    FlxTween.tween(game.camFollow, {y: 616},0.4, {ease: FlxEase.sineInOut,startDelay: 0.1});

    var spr = fakerBG[fakerBG.length-1];
    FlxTween.tween(spr, {alpha: 0.3},1.2);

    game.dad.visible = false;
    introAnim.animation.play('intro');
}

var itime:Float = 0;

function onUpdate(elapsed:Float) {
    if (rabbithead != null) {
        if (rabbithead.visible && rabbithead.animation.curAnim.curFrame > 19) {
            rabbithead.visible = false;
        }
    }
    itime+=elapsed;
    heatShader.setFloat('iTime', itime);



}




var atweenIthinklol:FlxTween;
function onEvent(eventName, value1, value2){
    if (eventName == '') {

        switch (value1) {
            case 'start':



            case 'end':
                game.isCameraOnForcedPos = true;
                game.camZooming = false;
                var spr = fakerBG[fakerBG.length-1];
                var time = 0.4;
                var delay = 0.2;
                //og y 616;
                FlxTween.tween(spr, {alpha: 0.3},time, {ease: FlxEase.quadIn, startDelay: delay});
                FlxTween.tween(game.camFollowPos, {x: 350, y: 580},time, {ease: FlxEase.quadIn, startDelay: delay});
                FlxTween.tween(game.camGame, {zoom: 1.5},time, {ease: FlxEase.quadIn, startDelay: delay, onComplete: function (f:FlxTween) {
                    spr.alpha = 1;
                    cutscene.alpha = 1;
                    cutscene.play();
                    game.canReset = false;
                    game.triggerEventNote('Camera Flash','camOther','0.25');
                    game.camHUD.zoom = 1.05;
                    FlxTween.tween(game.camHUD,{zoom: 1},0.4, {ease: FlxEase.quadOut});
                }});

            case 'lookright':
                FlxTween.tween(game.camFollow, {x: 500},0.7, {ease: FlxEase.sineInOut});
                FlxTween.tween(game.camGame, {zoom: 1.},0.7, {ease: FlxEase.sineInOut});
                var spr = fakerBG[fakerBG.length-1];
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
    
    if(eventName == 'Obituary'){
        switch(value1){
            case 'prepkick':
                var x = game.dad.getMidpoint().x + 150 + game.dad.cameraPosition[0] + game.opponentCameraOffset[0];
                var y = game.dad.getMidpoint().y - 100 + game.dad.cameraPosition[1] + game.opponentCameraOffset[1];
                y += 100;
                x += 100;
                game.isCameraOnForcedPos = true;

                FlxTween.tween(game.camFollowPos, {x: x,y: y},0.2, {ease: FlxEase.sineInOut});
            case 'endZoom':
                game.camOther.zoom = 2.2;
                monitor.visible = true;

                setTransInOut(true,true);

                for (i in blackBars) i.visible = true;

                FlxTween.tween(game.camHUD, {alpha: 0},0.3, {ease: FlxEase.sineOut});
                FlxTween.tween(game.camOther, {zoom: 1},1.25, {ease: FlxEase.sineOut});

                game.isCameraOnForcedPos = true;
                game.camFollow.x = game.dad.getGraphicMidpoint().x + ((game.boyfriend.getGraphicMidpoint().x - game.dad.getGraphicMidpoint().x)/2);
                game.zoomsPerBeat = 11111111;
                FlxTween.cancelTweensOf(game.camGame);
                FlxTween.tween(game.camGame, {zoom: 0.36},1.25, {ease: FlxEase.sineOut, onUpdate: function (f:FlxTween) {
                    game.defaultCamZoom = game.camGame.zoom;
                    trace(game.camGame.zoom);
                }});
                addShader(crtShader);

                FlxTween.tween(fuckassOverlay, {alpha: 0},0.5, {ease: FlxEase.sineOut});

                FlxTween.num(0, 5.0, 3.5, {ease: FlxEase.sineOut, onUpdate: function(v:FlxTween){
                    crtShader.data.warp.value = [v.value];
                }});

            case 'end':
                monitor.animation.play('off');
                black.alpha = 1;
                black.visible = true;
                FlxTween.tween(braindeadBF, {alpha: 1},0.4, {startDelay: 0.4});
                FlxTween.tween(braindeadBF, {alpha: 0},0.4, {startDelay: 5});

            case 'laugh':
                switch (value2) {
                    case 'kick':
                        dad.visible = false;
                        kickingAnim.visible = true;
                        kickingAnim.animation.play('kick');
                        FlxG.sound.play(Paths.sound('windUpKick'),0.75);
                        rabbithead.animation.play('play');
                        rabbithead.animation.finishCallback = function (n:String) {
                            rabbithead.visible = false;
                        }

                    case 'laugh':
                        kickingAnim.animation.play('laugh',true);
                    case 'end':
                        kickingAnim.animation.play('return');
                        kickingAnim.animation.finishCallback = function (n:String) {
                            kickingAnim.visible = false;
                            dad.visible = true;
                        }

                }
            case 'boring':
                switch (value2) {
            
                    case 'look':
                        dad.playAnim('gameover');
                        dad.stunned = true;

                    case 'boring':
                        boring.visible = true;
                        boringAlphabet.visible = true;
                        boringAlphabet2.visible = true;
                        black.visible = true;

                    case 'end':
                        boring.visible = false;
                        boringAlphabet.visible = false;
                        boringAlphabet2.visible = false;
                        black.visible = false;
                        dad.stunned = false;

                }
            case 'letsPlay':
                var val:Bool = value2 == 'true' ? true : false;
                black.visible = val;
                playText.visible = val;
                if (!val) {
                    game.triggerEventNote('Obituary','fade in','');
                    game.triggerEventNote('changeUI','ExeUI','');
                    game.canReset = true;
                }
            case 'im hungry':
                FlxG.camera.zoom = 0.65;
                game.defaultCamZoom = 0.65;
                new FlxTimer().start(0.1, Void -> {
                    for(i in fakerBG){
                        i.color = 0xFFFFFFFF;
                        i.alpha = 1;
                        FlxTween.color(i, 0.75, 0xFFFFFFFF, 0xFF464646, {ease: FlxEase.quadInOut});
                    }
                    game.triggerEventNote('tweenCamZoom','0.8,1','quadInOut');

                    new FlxTimer().start(0.05,Void-> {
                        dad.animation.play('idle-alt', true);
                        dad.specialAnim = true;
                    });

                });
                

                dad.animation.finishCallback = function(shit:String){
                    dad.animation.play('idle-alt-evil');
                };
               
            case 'fade in':
                for(i in fakerBG){
                    i.visible = false;
                    FlxTween.color(i, 0.1, 0xFF606060, 0xFF000000, {ease: FlxEase.quadInOut});
                }
                for(i in scaryBG){
                    i.visible = true;                    
                }
                if (!ClientPrefs.data.lowQuality) {
                    video.play();
                }

                game.defaultCamZoom = 0.65;
                game.camGame.zoom = 0.65;
                FlxTween.tween(game, {barSongLength: PlayState.instance.songLength}, 3, {ease: FlxEase.quadInOut});
                camHUD.alpha = 1;
                // if (atweenIthinklol != null) atweenIthinklol.cancel();
                // atweenIthinklol = FlxTween.tween(camHUD, {alpha: 1}, 0.00001, {ease: FlxEase.quadOut});

            case 'fade in but real':
                black.visible = true;
                black.alpha = 0;
                FlxTween.tween(black, {alpha: 1}, 2.5, {ease: FlxEase.quadInOut}); 

            case 'cut to black':
                black.visible = true;
                black.alpha = 1;
                game.triggerEventNote('Obituary','static','');

            case 'zoom out':
                game.defaultCamZoom = 1.75;
                var time:Float = 6;
                FlxTween.num(game.defaultCamZoom, 0.65, time, {ease: FlxEase.quadOut, onUpdate: function(v:FlxTween){
                    game.defaultCamZoom = v.value;
                }});
                FlxTween.tween(black, {alpha: 0}, time, {ease: FlxEase.quadInOut, oncComplete: function(v:FlxTween){
                    black.visible = false;
                }});

                for(i in scaryBG) i.visible = false;
                for(i in thirdBG) i.visible = true;
                if (!ClientPrefs.data.lowQuality) {
                    p3Video.play();
                }

                killVideo(video);

                modManager.setValue('alpha',1,1);
                //modManager.setValue('opponentSwap',1);
            case 'static':
                _static.visible = true;
                _static.alpha = FlxG.random.float(0.125, 1.0);
                new FlxTimer().start(0.25, function(shit:Float){
                    _static.visible = false;
                });

            case 'evil':
                game.camHUD.flash(0xFFFF0000, 0.5);
                modManager.setValue('drunk',0.2);
                if (!ClientPrefs.data.lowQuality) {
                    addShader(heatShader);
                }

                fuckassOverlay.visible = true;
            case 'ow':
                game.boyfriend.stunned = true;
                game.boyfriend.playAnim('hurt');
                if (game.health > 1) {
                    game.health = 1;
                }
                else {
                    game.health = 0.1;
                }
   
                game.triggerEventNote('Add Camera Zoom','0.09','');
                game.camHUD.shake(0.025,0.25);
                FlxG.sound.play(Paths.sound('ow'),0.5);


        }
    }
}

function addPhase3() {
    if (!ClientPrefs.data.lowQuality) {
        p3Video = new PsychVideoSprite(false);
        p3Video.load(Paths.video('makeaGif'), [PsychVideoSprite.looping,PsychVideoSprite.muted]);
        p3Video.addCallback('onFormat',()->{
            p3Video.scale.set(2,2.5);
            trace('fuck');
            p3Video.y += -150;
            p3Video.x += 100;
        });
        p3Video.scrollFactor.set(0.5, 0.5);
        add(p3Video);
        thirdBG.push(p3Video);
    }

    var p3Offsets:Array<Float> = [100,100];

    addObject1('henges3','p2/bgFiles',0.825,[0.8,0.8],'xy',[-50+p3Offsets[0],-120+p3Offsets[1]],false,3,12);

    if (!ClientPrefs.data.lowQuality) {
        addObject1('Smoke1','p2/smoke',0.825,[0.7,0.7],'0',[-275,-150],false,3,24);

        addObject1('Smoke2','p2/smoke',0.825,[0.7,0.7],'0',[1000,-125],false,3,24);
    }


    var firebgbottom = new FlxSprite();
    ObjectTools.generateGraphic(firebgbottom,3813,767,0xFFF4260A);
    firebgbottom.scrollFactor.set(0.8,0.8);
    firebgbottom.screenCenter();
    add(firebgbottom);
    thirdBG.push(firebgbottom);

    var firebgbottomL = new FlxSprite();
    ObjectTools.generateGraphic(firebgbottomL,3813,767,0xFFF4260A);
    firebgbottomL.scrollFactor.set(0.8,0.8);
    firebgbottomL.screenCenter();
    ObjectTools.graphicSize(firebgbottomL,1000,767);
    firebgbottomL.x += 500;
    add(firebgbottomL);
    thirdBG.push(firebgbottomL);

    var fireBG = new FlxSprite();
    fireBG.frames = Paths.getSparrowAtlas('stages/obituary/p2/FireBG');
    fireBG.animation.addByPrefix('i','FIRE instancia 1',24);
    fireBG.animation.play('i');
    ObjectTools.setScale(fireBG,0.825);
    fireBG.screenCenter();
    fireBG.scrollFactor.set(0.8,0.8);
    fireBG.y += -50;
    add(fireBG);
    thirdBG.push(fireBG);

    firebgbottom.y = fireBG.y + fireBG.height - 250;
    firebgbottomL.y = fireBG.y + fireBG.height - 350;

    addObject1('pike1','p2/bgFiles',0.825,[0.9,0.9],'xy',[-610+p3Offsets[0],100+p3Offsets[1]],false,3,12);

    addObject1('pike2','p2/bgFiles',0.825,[0.9,0.9],'xy',[-210+p3Offsets[0],100+p3Offsets[1]],false,3,12);

    addObject1('pike3','p2/bgFiles',0.825,[0.9,0.9],'xy',[610+p3Offsets[0],0+p3Offsets[1]],false,3,12);

    addObject1('floor3','p2/bgFiles',0.825,[1,1],'xy',[-50+p3Offsets[0],200+p3Offsets[1]],false,3,12);

    addObject1('head','p2/bgFiles',0.825,[1,1],'xy',[-334+p3Offsets[0],535+p3Offsets[1]],true,3,12);

    addObject1('fgLEFT','p2/bgFiles',0.825,[1.25,1.25],'xy',[-1200+p3Offsets[0],700+p3Offsets[1]],true,3,12);

    addObject1('fgRIGHT','p2/bgFiles',0.825,[1.25,1.25],'xy',[1200+p3Offsets[0],600+p3Offsets[1]],true,3,12);

}


function addPhase2() {
    //video sky for optimize
    if (!ClientPrefs.data.lowQuality) {
        video = new PsychVideoSprite(false);
        video.load(Paths.video('fire'), [PsychVideoSprite.looping,PsychVideoSprite.muted]);
        video.scale.set(2,2);
        video.scrollFactor.set(0.5, 0.5);
        video.y += 100;
        add(video);
        scaryBG.push(video);
    }


    addObject1('mountains','p1/bgFiles',0.825,[0.5,0.425],'xy',[0,-100],false,2,12);

    addObject1('water','p1/bgFiles2',0.825,[0.5,0.5],'xy',[0,-95],false,2,12);

    addObject1('Sun','p1/bgFiles2',0.875,[0.5,0.5],'xy',[0,-380],false,2,12);

    addObject1('frontmountains','p1/bgFiles',0.875,[0.5,0.5],'xy',[0,75],false,2,12);

    addObject1('ground','p1/bgFiles',0.875,[1,1],'x',[0,500],false,2,12);

    addObject1('plants','p1/bgFiles',0.875,[1,1],'xy',[-50,225],false,2,12);

    addObject1('fellas1','p1/bgFiles',0.875,[1,1],'x',[0,650],false,2,12);

    addObject1('fellas2','p1/bgFiles',0.875,[1,1],'x',[0,650],true,2,12);

    rabbithead = new FlxSprite(320,515);
    rabbithead.frames = Paths.getSparrowAtlas('stages/obituary/p1/Bunny_Kick');
    rabbithead.animation.addByPrefix('play','rabbit head',24,false);
    ObjectTools.setScale(rabbithead,0.75);
    rabbithead.antialiasing = ClientPrefs.data.antialiasing;
    foreground.add(rabbithead);
    scaryBG.push(rabbithead);

    rabbithead.animation.finishCallback = function (n:String) {
        rabbithead.destroy();
    }

    kickingAnim = new FlxSprite(-160,275);
    kickingAnim.frames = Paths.getSparrowAtlas('stages/obituary/p1/X_Kick');
    kickingAnim.antialiasing = ClientPrefs.data.antialiasing;
    kickingAnim.animation.addByIndices('kick', 'kickx', [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22], "", 24, false);
    kickingAnim.animation.addByIndices('laugh', 'kickx', [21,22,23,24,25], "", 24, false);
    kickingAnim.animation.addByIndices('return', 'kickx', [26,27], "", 24, false);
    ObjectTools.setScale(kickingAnim,0.9);
    foreground.add(kickingAnim);
    kickingAnim.visible = false;

    kickingAnim.animation.finishCallback = function (n:String) {
        if (n == 'return') kickingAnim.destroy();
    }


    var treeOffset:Array<Float> = [55,-49];

    addObject1('trees','p1/bgFiles',0.875,[1,1],'xy',[-50 + treeOffset[0],200 + treeOffset[1]],false,2,12);

    if (!ClientPrefs.data.lowQuality) {
        var birdsAnim = new FlxSprite();
        birdsAnim.frames = Paths.getSparrowAtlas('stages/obituary/p1/birds1');
        birdsAnim.animation.addByPrefix('i', 'birds', 12, true);
        birdsAnim.animation.play('i');
        ObjectTools.setScale(birdsAnim,0.765);
        birdsAnim.screenCenter();
        birdsAnim.y += 30 + treeOffset[1];
        birdsAnim.x += -55+ treeOffset[0];
        birdsAnim.antialiasing = ClientPrefs.data.antialiasing;
        add(birdsAnim);
        scaryBG.push(birdsAnim);
    
    }

    //setgraphicsize stuff
    var f = new FlxSprite();
    f.frames = Paths.getSparrowAtlas('stages/obituary/p1/bgFiles');
    f.animation.addByPrefix('i','frontshit',24);
    f.animation.play('i');
    f.setGraphicSize(3885);
    f.updateHitbox();
    f.scrollFactor.set(1.25,1.25);
    f.screenCenter();
    f.x += 210 + 150;
    f.y += 400;
    foreground.add(f);
    scaryBG.push(f);
    f.antialiasing = ClientPrefs.data.antialiasing;
}


function addPhase1() {
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
    if (phase == 1) fakerBG.push(f);
    else if (phase == 2)scaryBG.push(f);
    else if (phase == 3)thirdBG.push(f);
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
    if (phase == 1) fakerBG.push(f);
    else if (phase == 2)scaryBG.push(f);
    else if (phase == 3)thirdBG.push(f);
    f.antialiasing = ClientPrefs.data.antialiasing;
}

function killVideo(vid:PsychVideoSprite) {
    vid.stop();
    vid.destroy();
    vid = null;
}