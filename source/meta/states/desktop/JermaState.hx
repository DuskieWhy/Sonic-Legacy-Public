package meta.states.desktop;

import flixel.FlxSubState;
import gameObjects.StupidFuckingCursorDumb;
import gameObjects.PsychVideoSprite;
import meta.states.substate.transitions.FadeTransition;
import sys.thread.Thread;
import sys.thread.Mutex;
import meta.states.substate.MusicBeatSubstate;
import flixel.system.FlxSound;
import gameObjects.Alphabet;
import gameObjects.FNFSprite;
import flixel.math.FlxMath;
import flixel.group.FlxSpriteGroup;

//menus kinda gross but its whatever
//TODO
//fix dialogue on long dialogue
class JermaState extends MusicBeatState
{
    public var camTween:FlxTween;

    public static var instance:JermaState;
    public static var inSubMenu:Bool = false;
    var introControlLock:Bool = true;

    //camera and cursor stuff
    var nextCamera:FlxCamera;
    var cursorCamera:FlxCamera; //required due to zooms
    public var animatedCursor:StupidFuckingCursorDumb;

    //dialogue
    var dialogueBox:FlxSprite;
    var dialogueText:Alphabet = null;
    var dialogueFinishJob:Void->Void = null;

    //sprites
    var staticOverlay:FlxSprite;
    var jerma:FNFSprite;
    var selectableGroup:Array<FNFSprite> = [];
    var bejeweled:FlxSprite;
    var davenald:FlxSprite;
    var tvStatic:FlxSprite;
    var curSelected:Int = -1;

    //dw about this
    final _realTMR:Float = 50;
    var _imSorryTmr:Float = 0;

    //secondtmr
    final _daveTMRReset:Float = 10;
    var _daveTMR:Float = 0;
    static var seenDave:Bool = false;
    static var eggXIsComing:Float = 0;

    //tmr for when jerma will start saying stuff
    final _TMR:Float = 20;
    var _waitTmr:Float = 0;

    //jerma dialogue stuff
    var tags:Map<Int,String> = new Map();
    var jermaDialogue:Map<String,Array<String>> = [
        'intro' => ['What can I do for ya?','idle'],
        'images' => ['Oh these? GREAT memories! Wish I was as lucky as they are, heh heh.','lookleft'],

        'tape' => ["Oh, you're a music man are ya? i'm something of a connoisseur of the arts myself. Here are some tunes I was able to record... Don't ask how I got em.",'point','false'],
        'book' => ["Ooh, trying to study up, are we?",'heh','false'],
        'tv' => ["i fucking love tvs AHAHAHAHAHHAHAHAHA",'laugh','false'],
        
        'wait1' => ["Out with it, kid! You're not the only one gettin blue balls here... ",'hmm'],
        'wait2' => ["I haven't got all day, mate. Ask me something, or get lost",'hmm'],
        'wait3' => ["Ohh, brother.",'hmm'],

        'bejeweled' => ['oh shit bejeweled jerma gif, oh fuck yeah','lookleft'],
        'davenald' => ['oh what the fuck what the fuck was that what was that, oh my god what was that','thereitisAgain'],
        'davenald1' => ['dude fuck there it is again what IS THAT!!!','thereitisAgain'],
        'pain' => ['LIFE IS PAIN I HATE','']
    ];


    //threaded precaching
    var cachingMutex:Mutex;
    public function cacheSubStates() {
        cachingMutex = new Mutex();
        var subAssetPaths = ['tape/buttons','tape/st_bg','tape/tapeplayer','gallery/tvgal','gallery/remotegal'];

        //caching the gallery
        for (i in 0...37)  subAssetPaths.push('gallery/images/$i');
        
        //cool thing right this little setup doesnt actually work with gpu caching! awesome right? so whatever later we make a real asset caching system
        Thread.create(()-> {
            cachingMutex.acquire();
            for (i in 0...subAssetPaths.length) {
                Paths.image('userinterface/jerma/${subAssetPaths[i]}',null,false);
            }
            
            var videos = ['lobotomy','run','paige','towthecrimes'];
            for (i in 0...videos.length) {
                var video = new PsychVideoSprite(false);
                video.load(Paths.video('${videos[i]}')); 
            }

                
            cachingMutex.release();
        });

        Thread.create(()-> {
            cachingMutex.acquire();
            //temp solution later i want to do a more robust caching setup
            Paths.music('Shady Face');
            Paths.music('Shady FaceAmbience');
            if (instance != null) playMenuSong();

            Paths.inst('2torial');
            Paths.voices('2torial');

            Paths.inst('Obituary');
            Paths.voices('Obituary');

            Paths.music('options');
            Paths.music('freakyMenu-rodent');
            Paths.music('MainTheme');
            Paths.music('Legacytrueintro');


            cachingMutex.release();
        });
        
        
    }

    public static var inst:FlxSound = null;
    public static var vocals:FlxSound = null;

    public static function playMenuSong() {

        inst.loadEmbedded(Paths.music('Shady FaceAmbience'),true);
        vocals.loadEmbedded(Paths.music('Shady Face'),true);
        inst.fadeTween.cancelTween();
        vocals.fadeTween.cancelTween();
        inst?.play();
        vocals?.play(); 
        inst?.fadeIn(1,0,0.7);
        vocals?.fadeIn(1,0,0.7); 

    }

    public static function initFlxSounds() 
    {
        inst = new FlxSound();
        vocals = new FlxSound();
        FlxG.sound.list.add(inst);
        FlxG.sound.list.add(vocals);
    }

    public static function destroyFlxSound(sound:FlxSound,fadeout:Bool = false)
    {
        if (sound == null) return;

        sound?.fadeTween.cancelTween();
        if (fadeout){
            sound?.fadeOut(0.7,0, Void->{destroyFlxSound(sound);});
            return;
        }
        
        sound?.stop();
        sound?.destroy();
        sound = null;
    }

    override function destroy() {
        destroyFlxSound(inst);
        destroyFlxSound(vocals);
    
        TapeSubstate.resetVars();

        super.destroy();
    }

    override function create() {
        resetTmrs();

        persistentUpdate = true;

        instance = this;

        if (inst == null) initFlxSounds();

        cacheSubStates();

        if (FlxG.sound.music != null) {
            FlxG.sound.music.fadeTween.cancelTween();
            FlxG.sound.music.fadeOut(0.4,0, Void -> {FlxG.sound.music.stop(); FlxG.sound.music = null;});
        }

        var bookshelf = new FlxSprite(855,-35).loadImage('userinterface/jerma/bookshelf');
        add(bookshelf);

        makeSelectable('tape',932,231,[16,17]);

        makeSelectable('book',926,45,[15.5,10.5]);

        var xLeftOffset:Float = -70;
        var tvOffsetY:Float = 20;
        var tvOffset:Float = 95;

        var cloudbg = new FlxSprite(168 + xLeftOffset,240 + tvOffsetY).generateGraphic(188,131,0xFF240000);
        add(cloudbg);

        var clouds = new FlxSprite(169 + xLeftOffset,246 + tvOffsetY).loadFrames('userinterface/jerma/cloude');
        clouds.addAnimByPrefix('i','cloudmov instance 1',24);
        clouds.playAnim('i');
        add(clouds);

        var tvcharacters = new FlxSprite(183 + xLeftOffset,256 + tvOffsetY).loadFrames('userinterface/jerma/tvcharacters');
        tvcharacters.addAnimByPrefix('i','tkescreen instance 1',24);
        tvcharacters.playAnim('i');
        add(tvcharacters);

        bejeweled = new FlxSprite().loadFrames('userinterface/jerma/bejelewed');
        bejeweled.addAnimByPrefix('i','bejelewed i',20,true);
        bejeweled.graphicSize(cloudbg.width,cloudbg.height);
        bejeweled.setPosition(cloudbg.x,cloudbg.y);
        add(bejeweled);
        bejeweled.alpha = 0;

        davenald = new FlxSprite().loadImage('userinterface/jerma/davenald');
        davenald.graphicSize(cloudbg.width,cloudbg.height);
        davenald.setPosition(cloudbg.x,cloudbg.y);
        add(davenald);
        davenald.alpha = 0;

        tvStatic = new FlxSprite().loadFrames('static');
        tvStatic.addAnimByPrefix('i','static idle',24);
        tvStatic.playAnim('i');
        tvStatic.graphicSize(cloudbg.width,cloudbg.height);
        tvStatic.setPosition(cloudbg.x,cloudbg.y);
        add(tvStatic);
        tvStatic.alpha = 0;

        makeSelectable('tv',129 + xLeftOffset,137 + tvOffset + tvOffsetY,[-0.5,11.5 + tvOffset],0, -200);
        selectableGroup[selectableGroup.length-1].addOffset('idle',0,tvOffset);

        var tvlight = new FlxSprite(100 + xLeftOffset,180 + tvOffsetY).loadImage('userinterface/jerma/TVLight');
        add(tvlight);

        var tvshimmer = new FlxSprite(259 + xLeftOffset,249 + tvOffsetY).loadImage('userinterface/jerma/TVshimmer');
        tvshimmer.alpha = 0.2;
        add(tvshimmer);

        var imgOffset:Float = -50;
        makeSelectable('images',143 + xLeftOffset + 25,-90 + imgOffset - 10 + tvOffsetY,[23.5,35.5 + imgOffset]);
        selectableGroup[selectableGroup.length-1].addOffset('idle',0,imgOffset);

        if (FlxG.random.bool(0.00001 + eggXIsComing)) {
            var realimages = new FlxSprite(143 + xLeftOffset + 25 + 25,-90 - 10 + tvOffsetY + 25).loadImage('userinterface/jerma/realestimages');
            add(realimages);
        }
        eggXIsComing += 0.00002;

        jerma = new FNFSprite(-200,88);
        jerma.loadFrames('userinterface/jerma/jerma');
        jerma.addAnimByPrefix('idle','jermaidle');
        jerma.addAnimByPrefix('laugh','laugh');
        jerma.addAnimByPrefix('hmm','jermahmm');
        jerma.addAnimByPrefix('point','jermastinkyfinger');
        jerma.addAnimByPrefix('heh','jermaheh');
        jerma.addAnimByPrefix('lookleft','jermaleft');
        jerma.addAnimByPrefix('what','huhwhat');
        jerma.addAnimByPrefix('thereitisAgain','thereitisagain');
        jerma.addOffset('laugh',0,94);
        jerma.addOffset('hmm',1,18);
        jerma.addOffset('point',0,27);
        jerma.addOffset('heh',0,19);
        jerma.addOffset('lookleft',0,2);

        jerma.addOffset('what',6,5);
        jerma.addOffset('thereitisAgain',6,3);

        jerma.playAnim('idle');
        add(jerma);

        var painful = FlxG.random.bool(0.1);
        if (painful) {
            var painJerma = new FlxSprite(jerma.x,jerma.y-50).loadImage('userinterface/jerma/jermapain');
            add(painJerma);
            jerma.visible = false;
       }


        var overlay = new FlxSprite(78).loadImage('userinterface/jerma/overlay');
        add(overlay);
        overlay.scrollFactor.set();

        dialogueBox = new FlxSprite(0,jerma.y + jerma.height).loadImage('userinterface/jerma/jermaspeech');
        dialogueBox.y += -dialogueBox.height + -180;
        dialogueBox.centerOnSprite(jerma,X);
        add(dialogueBox);
        dialogueBox.visible = false;
    
        for (i in members) {
            if (i is FlxSprite) {
                var spr = cast(i,FlxSprite);
                spr.antialiasing = SaveData.antialiasing;
            }
        }
        

        nextCamera = new FlxCamera();
        nextCamera.bgColor.alpha = 0;
        FlxG.cameras.add(nextCamera,false);

        cursorCamera = new FlxCamera();
        cursorCamera.bgColor.alpha = 0;
        FlxG.cameras.add(cursorCamera,false);  //tbh we maybe shoudlve? idk made this a openfl sprite that is laid over the game
        animatedCursor = new StupidFuckingCursorDumb();

        animatedCursor.mouseLockon = true;

        staticOverlay = new FlxSprite().loadFrames('userinterface/jerma/jermstati');
        staticOverlay.addAnimByPrefix('i','jermstati i',16,true);
        staticOverlay.playAnim('i');
        staticOverlay.angle = 90;
        staticOverlay.graphicSize(0,FlxG.width*1.5);
        staticOverlay.screenCenter();
        staticOverlay.alpha = 0.0075;
        staticOverlay.blend = ADD;
        add(staticOverlay);
        staticOverlay.cameras = [cursorCamera];

        add(animatedCursor);

        FadeTransition.nextCamera = nextCamera;


        init(painful);
        

        super.create();

    }

    function init(painful:Bool = false) 
    {
        FlxG.camera.scroll.set(-75,-300);
        FlxG.camera.zoom = 2;
        camLocked = true;
        lerpValue = 0;
        FlxTween.tween(FlxG.camera, {"scroll.y": -50,zoom: 1.1},2, {ease: FlxEase.cubeOut, onComplete: Void -> {
            camLocked = false;
            xx = -75;
            yy = -50;
            //FlxTween.tween(this, {lerpValue: 0.04},0.7);
            introControlLock = false;

            var dataPath = 'intro';
            if (painful) {
                dataPath = null; 
                (FlxG.sound.play(Paths.sound('jerma/$dataPath'))).onComplete = ()->{Sys.exit(0);};
            }

            var getdata = jermaDialogue.get(dataPath);
            startDialogue(getdata[0],getdata[1],dataPath);
            FlxG.cameras.remove(nextCamera);
        }});
    }

    override function update(elapsed:Float) {
        super.update(elapsed);


        if (!inSubMenu) 
        {
            //only when shady face is playing
            if (dialogueText == null) {_waitTmr-=elapsed; _imSorryTmr-=elapsed; _daveTMR-=elapsed;}
            if (_waitTmr < 0) {
                var tag = 'wait' + FlxG.random.int(1,3);
                var getdata = jermaDialogue.get(tag);
                if (TapeSubstate.currentSong == 'Shady Face') {
                    startDialogue(getdata[0],getdata[1],tag,false);
                }
                else 
                {
                    jerma.playAnim(getdata[1]);
                }

                dialogueFinishJob = null;
            }

           // trace(_imSorryTmr);

            if (_daveTMR < 0) {
                if (FlxG.random.bool(0.005) && davenald.alpha == 0) {
                    resetTmrs();
                    tvStatic.alpha = 1;
                    davenald.alpha = 1;
                    var randomLength = FlxG.random.float(2,3);
                    new FlxTimer().start(randomLength-1.25,Void->{
                        jerma.playAnim('what');
                    });

                    new FlxTimer().start(randomLength,Void->{
                        tvStatic.alpha = 1; 
                        davenald.alpha = 0;
                        new FlxTimer().start(0.5,Void->{
                            var tag = 'davenald';
                            if (seenDave) tag+='1';
                            var getdata = jermaDialogue.get(tag);
                            startDialogue(getdata[0],getdata[1],tag);
                            dialogueFinishJob = null;
                            seenDave = true;
                        });
                    });
                }
            }


            if (_imSorryTmr < 0) {
                resetTmrs();
                tvStatic.alpha = 1;
                bejeweled.alpha = 1;
                bejeweled.playAnim('i');
                var getdata = jermaDialogue.get('bejeweled');
                startDialogue(getdata[0],getdata[1],'bejeweled');
                dialogueFinishJob = ()->{camLocked = false;tvStatic.alpha = 1; bejeweled.alpha = 0;}
            }

            if (tvStatic.alpha != 0) {tvStatic.alpha = lerp(tvStatic.alpha,0,0.2);}


            camMovement();

            if (controls.BACK && !introControlLock) {
                FlxG.sound.play(Paths.sound('SEL_back'));
                DesktopMenuState.fromMenu = true;
                DesktopMenuState.whichMenu = "jerma";
                MusicBeatState.switchState(new DesktopMenuState());
            }


            if (dialogueText != null) {
                if (dialogueText.finishedText && !_deletingDialogue) {
                    finishDialogue();
                }
            }

            var forceAnimReset = true;
            if (dialogueText == null && !introControlLock) {
                forceAnimReset = false;
                for (i in selectableGroup) {
                    var current:Bool = (i.ID == curSelected);
                    if (FlxG.mouse.overlaps(i)) {
                        if (!current) selectObject(i.ID);
                        if (FlxG.mouse.justPressed) {
                            triggerResponse(i.ID);
                        }
                    }
                }
            }
            resetAnims(forceAnimReset);

            if (FlxG.mouse.x >=1047 && FlxG.mouse.x <= 1140 && FlxG.mouse.y >=357 && FlxG.mouse.y <= 438 && FlxG.mouse.justPressed) FlxG.sound.play(Paths.sound('jerma/squish'));

        }

        // if (inst != null && vocals != null) {
        //     if ((inst.time > vocals.length) || (vocals.time > inst.length)) {
        //         inst.time = 0;
        //         vocals.time = 0;
        //         trace('recorrecting this stupid shit');
        //     }
        //     else {
        //         vocals.time = inst.time;
        //     }
        // }
        
    }

    inline function resetTmrs(resetthatTimer:Bool = true) {
        if (resetthatTimer) _imSorryTmr = _realTMR;
        
        _waitTmr = _TMR;
        _daveTMR = _daveTMRReset;
    }

    function triggerResponse(id:Int) { 

        var anim = tags.get(id); //gross but im lazy now
        var data = jermaDialogue.get(anim);

        switch (anim) {
            case 'book':
                dialogueFinishJob = () -> {
                    camLocked = true;
                    trace('hi');
                    openSubState(new BookSubstate());
                    jermaDialogue.get(anim)[2] = 'true';
                }
                
            case 'tape':
               // TapeSubstate.preloadSongs();
                dialogueFinishJob = () -> {
                    camLocked = true;

                    //canceltweensof wasnt workuing?
                    camTween = FlxTween.tween(FlxG.camera,{zoom:1.25},0.25,{ease: FlxEase.sineInOut});
                    FlxG.camera.fade(FlxColor.BLACK,0.25,false,()->{
                        FlxG.camera.fade(FlxColor.BLACK,0.25,true);
                        openSubState(new TapeSubstate());
                    });
                    jermaDialogue.get(anim)[2] = 'true';
                }
            case 'tv':
                dialogueFinishJob = () -> {
                    camLocked = true;
                    camTween = FlxTween.tween(FlxG.camera,{zoom:1.25},0.25,{ease: FlxEase.sineInOut});
                    FlxG.camera.fade(FlxColor.BLACK,0.25,false,()->{
                        FlxG.camera.fade(FlxColor.BLACK,0.25,true);
                        openSubState(new GallerySubstate());
                    });
                    jermaDialogue.get(anim)[2] = 'true';

                }
            default:
                dialogueFinishJob = null;
        }
        FlxG.sound.play(Paths.sound('SEL_select'));

        if (data[2] != null && data[2] == 'true') {
            dialogueFinishJob();
            return;
        }
        startDialogue(data[0],data[1],anim);

        
    }

    //decided to add the mouse anim logic to this lol. Actually works pretty well too i think
    function resetAnims(forced:Bool = false) {
        if (forced) {for (i in selectableGroup) i.playAnim('idle'); animatedCursor.mouseInterest = false; return;}

        var counter:Int = 0;
        for (i in selectableGroup) {
            if (!FlxG.mouse.overlaps(i)) {
                counter++;
            }
        }
        if (counter == selectableGroup.length) {
            curSelected = -1;
            for (i in selectableGroup) i.playAnim('idle');
            animatedCursor.mouseInterest = false;
        }
        else {
            animatedCursor.mouseInterest = true;
        }
    }
    
    function selectObject(ID:Int) {
        curSelected = ID;
        for (i in selectableGroup) {
            if (i.ID == ID) {
                i.playAnim('select',false);
            }
            else {
                i.playAnim('idle',true);
            }
        }
    }


    function startDialogue(dialogue:String,jermaAnim:String,?key:String,resetTimer:Bool = true) {
        if (_deletingDialogue) return;

        inst.fadeTween.cancelTween();
        vocals.fadeTween.cancelTween();

        inst.fadeOut(1,0.3);
        vocals.fadeOut(1,0.3);      
        
        resetTmrs(resetTimer);
        camLocked = true;
        lerpValue = 0;

        FlxTween.tween(FlxG.camera,{'scroll.x': jerma.x + 150, "scroll.y": jerma.y - 100},1, {ease: FlxEase.circInOut, onComplete: Void -> {
            xx = FlxG.camera.scroll.x;
            yy = FlxG.camera.scroll.y;
        }});


        var wordLength:Float = dialogue.length;
        var wordScale = 0.6;
        var time:Float = 0.045;
        var isLongText:Bool = false;

        if (wordLength >= 100) {
            //maybe account for dialogue overlapping itself but i feel that like wont happen ever?
            wordScale = 0.45;
            isLongText = true;


        }


        

        if (key != null) {
            try {
                FlxG.sound.play(Paths.sound('jerma/$key'));
                var soundLength:Float = Paths.sound('jerma/$key').length;
                time = soundLength/wordLength;
                time /=1000;
                time *= 0.6;
                //trace(time);
                trace(wordLength);
            
            }
            catch(e) {}
        }

        jerma.playAnim(jermaAnim);
        dialogueBox.visible = true;
        dialogueText = new Alphabet(dialogueBox.x-40, dialogueBox.y + 40, dialogue, false,true,time,wordScale,true);
        if (isLongText) {
            dialogueText.verticalSpacing = 45;
            @:privateAccess {
                dialogueText.LONG_TEXT_ADD = -20;
            }
        }

        add(dialogueText);

    }

    var _deletingDialogue:Bool = false;
    function finishDialogue() {
        if (_deletingDialogue) return;
        _deletingDialogue = true;

        new FlxTimer().start(2, Void -> {
            inst.fadeTween.cancelTween();
            vocals.fadeTween.cancelTween();
    
            inst.fadeIn(1,inst.volume,0.7);
            vocals.fadeIn(1,vocals.volume,0.7);      

            if(dialogueText != null) {
                dialogueText.killTheTimer();
                dialogueText.kill();
                remove(dialogueText);
                dialogueText.destroy();
                dialogueText = null;
                _deletingDialogue = false; 
            }
            dialogueBox.visible = false;
            jerma.playAnim('idle');

            FlxTween.tween(this, {lerpValue: 0.04},0.7);
            if(dialogueFinishJob != null) dialogueFinishJob();
            else {camLocked = false;}
        });

    }

    var xx:Float = 0;
    var yy:Float = 0;
    var camLocked:Bool = false;
    var lerpValue:Float = 0.04;
    function camMovement() {
        if (camLocked) return;

        var yOffset:Float = -100;
        if (dialogueText != null && !dialogueText.finishedText || _deletingDialogue) yOffset = -50;
            
        var newX = ((FlxG.mouse.screenX - (FlxG.width/2)) / 15) - 75;
        var newY = ((FlxG.mouse.screenY - (FlxG.height/2)) / 15) + yOffset;

        xx = lerp(xx, newX,lerpValue);
        yy = lerp(yy, newY,lerpValue);

        FlxG.camera.scroll.x = xx;
        FlxG.camera.scroll.y = yy;
        //if (!introControlLock) {
            FlxG.camera.zoom = lerp(FlxG.camera.zoom,1.1,0.1);
        //}
    }

    function makeSelectable(name:String,x:Float,y:Float,offsets:Array<Float>,widthAdd:Float = 0,heightAdd:Float = 0) 
    {
        var i:FNFSprite = new FNFSprite(x,y);
        i.loadFrames('userinterface/jerma/$name');
        i.addAnimByPrefix('idle','i');
        i.addAnimByPrefix('select','select', 24);
        i.playAnim('idle');
        i.addOffset('select',offsets[0],offsets[1]);
        add(i);
        i.ID = selectableGroup.length;
        selectableGroup.push(i);
        i.width = i.frameWidth + widthAdd;
        i.height = i.frameHeight + heightAdd;
        tags.set(i.ID,name);
    }


    override function openSubState(sub:FlxSubState) {
        if (sub is GallerySubstate || sub is TapeSubstate || sub is BookSubstate) inSubMenu = true;
        camTween.cancelTween();
        super.openSubState(sub);
    }
    override function closeSubState() {
        inSubMenu = false;
        lerpValue = 0;
        FlxTween.tween(this,{lerpValue: 0.04},0.7);
        if (!introControlLock) camLocked = false;
        super.closeSubState();
    }
}



//------------------------[GALLERY]------------------------//
class GallerySubstate extends MusicBeatSubstate {

    var remote:FlxSprite;
    var tv:FlxSprite;

    var images:FlxSpriteGroup = new FlxSpriteGroup();

    var hitboxes:FlxSpriteGroup = new FlxSpriteGroup();
    var currentImage:Int = 0;
    var leavingMenu:Bool = false;

    var staticD:FlxSprite;

    var curVideo:PsychVideoSprite;

    //ducttape
    var videoPaths:Map<Int,String> = new Map();

    public function new() {
        super();
        FlxG.camera.zoom = 1;

        var black = new FlxSprite().generateGraphic(FlxG.width,FlxG.height,FlxColor.BLACK);
        black.scrollFactor.set();
        add(black);

        var staticButBehind = new FlxSprite().loadFrames('static');
        staticButBehind.addAnimByPrefix('i','static idle',12);
        staticButBehind.playAnim('i');
        staticButBehind.setScale(0.5,0.6);
        add(staticButBehind);
        staticButBehind.alpha = 0.2;
        staticButBehind.scrollFactor.set();


        add(images);

        staticD = new FlxSprite().loadFrames('static');
        staticD.addAnimByPrefix('i','static idle',24);
        staticD.playAnim('i');
        staticD.setScale(0.5,0.6);
        staticD.scrollFactor.set();
        add(staticD);
        staticD.alpha = 0;

        tv = new FlxSprite().loadImage('userinterface/jerma/gallery/tvgal');
        tv.scrollFactor.set();
        add(tv);
        tv.screenCenter();

        staticButBehind.centerOnSprite(tv);
        //staticButBehind.x += -50;
        staticD.centerOnSprite(tv);
        //staticD.x += -50;

        remote = new FlxSprite().loadFrames('userinterface/jerma/gallery/remotegal');
        remote.addAnimByPrefix('0','remote0002',24,false);
        remote.addAnimByPrefix('1','remote0003',24,false);
        remote.addAnimByPrefix('2','remote0001',24,false);
        remote.addAnimByPrefix('idle','remote0000',24,false);  
        remote.playAnim('idle');
        remote.scrollFactor.set();
        add(remote);
        remote.screenAlignment(BOTTOMRIGHT);
        remote.y += 40;


        for (i in 0...37) {
            var image = new FlxSprite(tv.x + 83, tv.y + 72).loadImage('userinterface/jerma/gallery/images/$i');
            image.graphicSize(774);
            if (image.height > 567) image.graphicSize(0,567);
            image.centerOnSprite(tv);
            image.y += -30;
            images.add(image);
            image.scrollFactor.set();
            image.alpha = 0;
       }

       var videos = ['lobotomy','run', 'paige','towthecrimes'];
       for (i in 0...videos.length) {
            var video = new PsychVideoSprite(false);
            video.load(Paths.video('${videos[i]}'));
            video.addCallback(ONFORMAT,()-> {
                video.graphicSize(774); 
                if (video.height > 567) video.graphicSize(0,567);
                video.centerOnSprite(tv);
                video.y += -50;
                video.x += -50;
            });
            video.scrollFactor.set();
            video.alpha = 0;
            images.add(video);
            videoPaths.set(images.length-1,videos[i]);

            video.addCallback(ONSTART,()-> {
                JermaState.inst?.pause();
                JermaState.vocals?.pause();
            });
            video.addCallback(ONEND,()->{
                JermaState.inst?.resume();
                JermaState.vocals?.resume();
            });
            
       }

        var leftBox = new FlxSprite(remote.x + 42,remote.y + 93).generateGraphic(106,174);
        hitboxes.add(leftBox);
        leftBox.ID = 0;

        var rightBox = new FlxSprite(remote.x + 142,remote.y + 93).generateGraphic(106,174);
        hitboxes.add(rightBox);
        rightBox.ID = 1;

        var powerOff = new FlxSprite(remote.x + 170,remote.y + 13).generateGraphic(79,65);
        hitboxes.add(powerOff);
        powerOff.ID = 2;

        for (i in hitboxes) i.scrollFactor.set();
        clickedOption(1,true);

    }

    function clickedOption(id:Int,noAnim:Bool = false) {

        if (id == 0 || id == 1) {
            //stops the video if u had swapped off
            if (images.members[currentImage] is PsychVideoSprite) {
                var vid = cast(images.members[currentImage],PsychVideoSprite);
                vid.pause();
                if (!JermaState.inst?.playing) {
                    JermaState.inst?.resume();
                    JermaState.vocals?.resume();
                }
            }

            var currentID = id;
            if (id == 0) currentID = -1;
            currentImage = FlxMath.wrap(currentImage + currentID, 0, images.length-1);
            for (i in 0...images.length) {
                images.members[i].alpha = 0;
                if (i == currentImage) {
                    images.members[i].alpha = 1;
                    if (images.members[i] is PsychVideoSprite) {
                        var vid = cast(images.members[i],PsychVideoSprite);
                        vid.load(Paths.video(videoPaths.get(i)));
                        vid.play();
                    }
                }
            }
            staticD.alpha = 1;
        }

        if (!noAnim) {
            remote.y += 10;
            remote.playAnim('$id');
            FlxG.sound.play(Paths.sound('SEL_move'));
        }

        if (id == 2) leavingMenu = true;
    }


    function leaveMenu() {
        if (!JermaState.inst?.playing) {
            JermaState.inst?.resume();
            JermaState.vocals?.resume();
        }
        FlxG.camera.fade(FlxColor.BLACK,0.25,false,()->{
            FlxG.camera.zoom = 1.5;
            FlxG.camera.fade(FlxColor.BLACK,0.25,true);
            close();
        });

    }

    override function update(elapsed:Float) {

        if (FlxG.camera.zoom != 1) {
            FlxG.camera.zoom = 1;
        }

        if (FlxG.mouse.overlaps(hitboxes)) {
            for (i in hitboxes) {
                if (FlxG.mouse.overlaps(i) && FlxG.mouse.justPressed) clickedOption(i.ID);
            }
            JermaState.instance.animatedCursor.mouseInterest = true;
        }
        else {
            JermaState.instance.animatedCursor.mouseInterest = false;
        }

        if (FlxG.mouse.justReleased || controls.UI_LEFT_R || controls.NOTE_RIGHT_R) {

            remote.playAnim('idle');

            if (leavingMenu) {
                leaveMenu();
            }
        };

        if (controls.UI_RIGHT_P) clickedOption(1);
        if (controls.UI_LEFT_P) clickedOption(0);
        if (controls.BACK) {
            clickedOption(2);
            leaveMenu();
        };

        staticD.alpha = lerp(staticD.alpha,0,0.2);

        remote.y = lerp(remote.y,482,0.3);

        super.update(elapsed);
    }
}

//------------------------[TAPESUBSTATE]------------------------//
class TapeSubstate extends MusicBeatSubstate {

    public static var currentSelection:Int = 0;
    public static var currentSong:String = 'Shady Face';
    
    static var mutex:Mutex = new Mutex();

    static var clickedPlay:Bool = true;
    static var clickedPause:Bool = false;

    var buttons:FlxSprite;
    var wood:FlxSprite;
    var tapePlayer:FlxSprite;
    var songName:FlxText;
    var songNameFrame:FlxSprite;
    var hitboxes:Array<FlxSprite> = [];

    //TEMP?
    var songs:Array<String> = ['Shady Face','2torial','Obituary','Fake Menu Theme','Fake Options Theme','Fake Intro Song','Intro'];

    //gross system but whatever ig..
    var songPath:Map<String,Array<Dynamic>> = [
        '2torial' => [Paths.inst('2torial'),Paths.voices('2torial')],
        'Obituary' => [Paths.inst('Obituary'),Paths.voices('Obituary')],
        'Fake Menu Theme' => [Paths.music('freakyMenu-rodent')],
        'Fake Options Theme' => [Paths.music('options')],
        'Fake Intro Song' => [Paths.music('MainTheme')],
        'Shady Face' => [Paths.music('Shady Face'),Paths.music('Shady FaceAmbience')],
        'Intro' => [Paths.music('Legacytrueintro')]
    ];

    var songCredits:Map<String,String> = [
        '2torial' => 'BWEND',
        'Obituary' => 'BWEND AND STURM',
        'Shady Face' => 'STURM',
        'Intro' => 'STURM',
        'Fake Menu Theme' => 'MARSTARBRO',
        'Fake Options Theme' => 'MARSTARBRO',
        'Fake Intro Song' => 'MARSTARBRO'
    ];

    public function new() {
        super();

        FlxG.camera.zoom = 1;
        var xOffset:Float = -0;
        var yOffset:Float = -10;

        wood = new FlxSprite(xOffset,yOffset).loadImage('userinterface/jerma/tape/st_bg');
        wood.setScale(0.96969696969697);
        add(wood);

        tapePlayer = new FlxSprite(170 + xOffset,-30 + yOffset).loadFrames('userinterface/jerma/tape/tapeplayer');
        tapePlayer.addAnimByPrefix('i','tapeplayer');
        tapePlayer.playAnim('i');
        tapePlayer.animation.pause();
        tapePlayer.setScale(0.96969696969697);
        add(tapePlayer);   

        buttons = new FlxSprite().loadFrames('userinterface/jerma/tape/buttons');
        buttons.setScale(0.96969696969697);
        buttons.addAnimByPrefix('0','buttons0000',24,false);
        buttons.addAnimByPrefix('1','buttons0001',24,false);
        buttons.addAnimByPrefix('2','buttons0002',24,false);
        buttons.addAnimByPrefix('3','buttons0003',24,false);
        buttons.addAnimByPrefix('4','buttons0004',24,false);
        buttons.addAnimByPrefix('5','buttons0005',24,false);
        add(buttons);
        buttons.screenAlignment(BOTTOMMID);

        var buttonX = 65;
        buttons.x += buttonX;


        var hbSetup:Array<Float> = [304,444,580,711,843];
        for (i in 0...hbSetup.length) {
            var box1 = new FlxSprite(hbSetup[i],555).generateGraphic(125,160);
            box1.x += buttonX;
            box1.visible = false;
            box1.scrollFactor.set();
            box1.ID = i;
            hitboxes.push(box1);
        }

        songNameFrame = new FlxSprite();
        add(songNameFrame);

        songName = new FlxText(0,0,0,'" OBITUARY "',36);
        songName.setFormat(Paths.font("SF-Kats.ttf"), 36, 0xFFA10700,CENTER,OUTLINE,0xFFA10700);
        songName.borderSize =.25;
        add(songName);
        songName.centerOnSprite(tapePlayer);
        songName.y += 100;

        songNameFrame.generateGraphic(songName.width + 25,songName.height + 25,FlxColor.BLACK);
        songNameFrame.alpha = 0.45;
        add(songNameFrame);
        songNameFrame.centerOnSprite(songName);
        songName.visible = songNameFrame.visible = false;


        for (i in [wood,tapePlayer,buttons,songNameFrame,songName]) {
            i.scrollFactor.set();
        }

        if (clickedPlay) {continuePlaying();}

    }

    function continuePlaying() {
        updateSongName();
        tapePlayer.animation.resume();
        if (!JermaState.inst.playing)  {
            tapePlayer.animation.pause();
            buttons.playAnim('2');
        }
    }

    override function update(elapsed:Float) {
        if (FlxG.camera.zoom != 1) {
            FlxG.camera.zoom = 1;
        }

        var count=0;
        for (i in hitboxes) {
            if (FlxG.mouse.overlaps(i)) {
                JermaState.instance.animatedCursor.mouseInterest=true;
                if (FlxG.mouse.justPressed) clickedTape(i.ID);
            }
            else count++;
        }
        if (count == hitboxes.length) {
            JermaState.instance.animatedCursor.mouseInterest=false;
        }

        super.update(elapsed);
        
    }

    function clickedTape(id:Int) {
        FlxG.sound.play(Paths.sound('SEL_move'));

        var anim:String = '${id + 1}';
        if (buttons.animation.curAnim?.name == anim)  buttons.playAnim('0');   
        else buttons.playAnim(anim);

        tapeLogic(buttons.animation.curAnim.name);
    }


    function tapeLogic(anim:String) {

        if (anim == '1') {
            clickedPlay = true;
            // we hate the fucking lag spike so doing this ig
            Thread.create(() -> {
                mutex.acquire();

                JermaState.inst?.stop();
                JermaState.vocals?.stop();
                try {
                    var getSongs = songPath.get(songs[currentSelection]);
                    trace(getSongs);
                    JermaState.inst.loadEmbedded(getSongs[0],true);
                    JermaState.inst.play();
                    JermaState.inst.volume = 0.7;
    
                    if (getSongs[1] != null) {
                        JermaState.vocals.revive();
                        JermaState.vocals.loadEmbedded(getSongs[1],true);
                        JermaState.vocals.play();
                        JermaState.vocals.volume = 0.7;

                    }
                    else {

                        JermaState.vocals.kill();
                    }

                    var maxLength = JermaState.inst.length > JermaState.vocals.length ? JermaState.inst : JermaState.vocals;
                    //maxLength.onComplete = () -> {songFinishedPlaying();}

                    mutex.release();
                }
                catch (e) {
                    mutex.release();
                }

            });

            updateSongName();
            playTape(true);

            new FlxTimer().start(0.1, Void -> {buttons?.playAnim('0');});
        }

        if (anim == '2') {
            //pause logic
            if (!clickedPlay) return;
            clickedPause = true;
            if (JermaState.inst.playing) {
                playTape(false);
            }
        }

        if (anim == '3' || anim == '4') {
            var val = anim == '3' ?  -1 : 1;
            currentSelection = FlxMath.wrap(currentSelection + val,0,songs.length-1);
            new FlxTimer().start(0.1, Void -> {buttons?.playAnim('0');});
            tapeLogic('1');
        }

        if (anim == '5') {
            leaveTapeMenu();
        }

        //UNCLICKLOGIC
        if (anim == '0') {
            //unpause logic
            if (clickedPause && clickedPlay) {
                clickedPause = false;
                if (!JermaState.inst.playing) {
                    playTape(true);
                }
            }
        }
    }

    inline function songFinishedPlaying() {
        clickedPlay = false;
        tapePlayer.animation.pause();
        if (songName != null) {
            songName.visible = songNameFrame.visible = false;
        }

    }

    function leaveTapeMenu() {
        FlxG.camera.fade(FlxColor.BLACK,0.25,false,()->{
            FlxG.camera.zoom = 1.5;
            FlxG.camera.fade(FlxColor.BLACK,0.25,true);
            close();
        });
    }

    function updateSongName() {
        songName.text = '" ${songs[currentSelection].toUpperCase()} "' + '\n" COMPOSED BY ${songCredits.get(songs[currentSelection])} "';
        songName.updateHitbox();
        songName.centerOnSprite(tapePlayer);
        songName.y += 100;
        songNameFrame.graphicSize(songName.width + 25,songName.height + 25);
        songNameFrame.centerOnSprite(songName);
        songName.visible = songNameFrame.visible = true;
        currentSong = songs[currentSelection];
    }

    function playTape(v:Bool) {

        if (v) {
            tapePlayer.animation.resume();
            JermaState.inst.resume();
            JermaState.vocals.resume();
        } 
        else {
            tapePlayer.animation.pause();
            JermaState.inst.pause();
            JermaState.vocals.pause();
        }
    }

    public static function resetVars() 
    {
        clickedPause = false;
        clickedPlay = true;
        currentSelection = 0;
        currentSong = 'Shady Face';
    }
}
// ------------------------[BOOK SUBSTATE]------------------------ //
class BookSubstate extends MusicBeatSubstate {
    var black:FlxSprite;
    var book:FlxSprite;
    var canSelect:Bool = false;
    var inBook:Bool = false;
    var tmr:Float = 15;
    var inSound:Bool = false;
    var blabbingAboutX:FlxSound;
    public function new(){
        super();
        black = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
        black.scrollFactor.set();
        black.alpha = 0;
        add(black);

        book = new FlxSprite().loadFrames('userinterface/jerma/info');
        book.addAnimByPrefix('idle', 'open', 24, true);
        book.addAnimByPrefix('open', 'idle', 24, true);
        book.playAnim('idle', true);
        book.setScale(0.8);
        book.y = FlxG.height + book.height;
        book.x = (FlxG.width - book.width)/2;
        book.x += -200;
        book.scrollFactor.set();
        add(book);

        blabbingAboutX = new FlxSound();
        FlxG.sound.list.add(blabbingAboutX);


        FlxTween.tween(book, {y: ((FlxG.height - book.height) / 2) + 50}, 0.75, {ease: FlxEase.circOut, onComplete: function(s:FlxTween){
            canSelect = true;
        }});
        FlxTween.tween(black, {alpha: 0.5}, 1, {ease: FlxEase.quadOut});
    }
    override public function update(elapsed:Float){
        if((controls.BACK || FlxG.mouse.justPressed) && canSelect && book.getCurAnimName() == 'open'){
            canSelect = false;
            book.y+=20;
            FlxTween.tween(book,{y:book.y-20},0.4,{ease:FlxEase.expoOut,onComplete: Void->{
                book.playAnim('idle');
                FlxTween.tween(book, {x:((FlxG.width-book.width)/2) + -200},0.4, {ease: FlxEase.circInOut, onComplete: Void->{
                    FlxTween.tween(book, {y: FlxG.height + book.height}, 0.75, {ease: FlxEase.backIn});
                    FlxTween.tween(black, {alpha: 0}, 1.3, {ease: FlxEase.backOut, onComplete:Void->{
                        blabbingAboutX.onComplete = null;
                        JermaState.destroyFlxSound(blabbingAboutX);
                        fadeAudioUp();


                        close();
                    }});
                }});
            }});

        }
        if(canSelect) {
            //this is bad but who cares ig 
            //later we rewrite
            var overlap = FlxMath.inBounds(FlxG.mouse.screenX,411,871) && FlxMath.inBounds(FlxG.mouse.screenY,100,655);
            if (book.getCurAnimName() == 'open') overlap = FlxG.mouse.overlaps(book);
            
            if (overlap) {
                mouseInterest(true);
                if (FlxG.mouse.justPressed) {
    
                    if (book.getCurAnimName() == 'idle') {
                        canSelect = false;
                        book.y += 20;
                        FlxTween.tween(book,{y: book.y - 20},0.4, {ease: FlxEase.expoOut});
                        FlxTween.tween(book, {x: ((FlxG.width-book.width)/2)},0.4, {ease: FlxEase.circInOut,onComplete: Void->{
                            inBook = true;
                            book.playAnim('open');
                            FlxG.sound.play(Paths.sound('jerma/book/page${FlxG.random.int(1,5)}'));
                            canSelect = true;
                        }});
                    }
                }
            }
            else {mouseInterest(false);}

        }
        else {
            mouseInterest(false);
        }
        super.update(elapsed);


        if (inBook && !inSound) {
            tmr-=elapsed;
            if (tmr < 0) {
                tmr = 15;
                inSound = true;

                JermaState.inst.fadeTween.cancelTween();
                JermaState.vocals.fadeTween.cancelTween();
                JermaState.inst.fadeOut(1,0.3);
                JermaState.vocals.fadeOut(1,0.3);   


                blabbingAboutX.loadEmbedded(Paths.sound('jerma/bookwaiting'));
                blabbingAboutX.play();
                blabbingAboutX.onComplete = fadeAudioUp;

                
            }
        }

    }

    function fadeAudioUp() {
        JermaState.inst.fadeTween.cancelTween();
        JermaState.vocals.fadeTween.cancelTween();
        JermaState.inst.fadeIn(1,JermaState.inst.volume,0.7);
        JermaState.vocals.fadeIn(1,JermaState.vocals.volume,0.7); 
    }

    inline function mouseInterest(v:Bool) {
        JermaState.instance.animatedCursor.mouseInterest = v;

    }
}

