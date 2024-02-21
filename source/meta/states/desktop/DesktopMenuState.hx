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
import gameObjects.StupidFuckingCursorDumb;

class DesktopMenuState extends MusicBeatState 
{
    static var _initialized:Bool = false;

    static var _firstTime:Bool = true;

    var taskbar:FlxSprite;
    var screen:FlxSprite;
    var curtains:FlxSprite;
    var pizza:FlxSprite;
    var box:FlxSprite;
    var pc:FlxSprite;
    var lotion:FlxSprite;
    var wires2:FlxSprite;
    var mixer:FlxSprite;
    var bottle:FlxSprite;
    var phone:FlxSprite;
    var wires3:FlxSprite;
    var tissues:FlxSprite;
    var wires1:FlxSprite;
    var can1:FlxSprite;
    var can2:FlxSprite;
    var monitor:FlxSprite;
    var keyboard:FlxSprite;
    var newCursor:StupidFuckingCursorDumb;

    var screenOff:FlxSprite;
    var monitorPower:FlxSprite;
    var powerOnSound:FlxSound;

    var camCursor:FlxCamera;

    var anims:Array<String> = ["curtains", "pizza", "box", "pc", "lotion", "wires2", "mixer", "bottle", "phone", "wires3", "tissues", "wires1", "can1", "can2", "monitor", "keyboard"];
    
    public static var fromMenu:Bool;
    public static var whichMenu:String;

    var whoUpIntroingRn:Bool = true;
    function initSets() {
        curtains = new FlxSprite(-842.35, -637.1);
        pizza = new FlxSprite(5.95, -31.4);
        box = new FlxSprite(1178.6, -39.5);
        pc = new FlxSprite(959.45, -218.8);
        lotion = new FlxSprite(1539.2, 168.15);
        wires2 = new FlxSprite(918.2, 504.25);
        mixer = new FlxSprite(1254.7, 466.75);
        bottle = new FlxSprite(14.65, 243.1);
        phone = new FlxSprite(-564.15, -24.75);
        wires3 = new FlxSprite(-370.3, 377.8);
        tissues = new FlxSprite(-767.7, 440.8);
        wires1 = new FlxSprite(40.6, 536.85);
        can1 = new FlxSprite(-0.1, 500.65);
        can2 = new FlxSprite(-140.8, 579.3);
        monitor = new FlxSprite(199.9, -26.6);
        keyboard = new FlxSprite(-446.35, 679);
    
        curtains.scrollFactor.set(0.4, 0.4);
        pizza.scrollFactor.set(0.6, 0.6);
        box.scrollFactor.set(0.6, 0.6);
        pc.scrollFactor.set(0.75, 0.75);
        lotion.scrollFactor.set(0.8, 0.8);
        wires2.scrollFactor.set(0.9, 0.9);
        mixer.scrollFactor.set(0.9, 0.9);
        bottle.scrollFactor.set(0.85, 0.85);
        phone.scrollFactor.set(0.8, 0.8);
        wires3.scrollFactor.set(0.9, 0.9);
        tissues.scrollFactor.set(0.95, 0.95);
        wires1.scrollFactor.set(0.9, 0.9);
        can1.scrollFactor.set(0.9, 0.9);
        can2.scrollFactor.set(0.95, 0.95);
        monitor.scrollFactor.set(1,1);
        keyboard.scrollFactor.set(1.2, 1.2);
    }
    
    function addSets(cock:FlxSprite, i) {
        cock.frames = Paths.getSparrowAtlas('userinterface/desktop/bgLayers');
        cock.animation.addByPrefix("on", anims[i] + "On", 12, true);
        cock.animation.addByPrefix("off", anims[i] + "Off", 12, true);
        cock.animation.play("off");
        cock.updateHitbox();
        add(cock);
    }

    public var lightSwitch:Bool = false;

    function lights() {
    
        lightSwitch = !lightSwitch;
    
        for (shits in [curtains, pizza, box, pc, lotion, wires2, mixer, bottle, phone, wires3, tissues, wires1, can1, can2, monitor, keyboard]){
            shits.animation.play(lightSwitch?"on":"off");
        }
    
        screenOff.visible = !lightSwitch;

        if(screenOff.visible){
            // FlxG.sound.music.pause(); 
            FlxG.sound.music.fadeTween.cancelTween();
            // if(powerOnSound.active) powerOnSound.stop();
        }else{
            FlxG.sound.music.resume();
            // powerOnSound.play(false, 0.4);
        };
    
    }

    function playMenuSong() {FlxG.sound.playMusic(ProgressionHandler.getMenuMusic());}
    
    override function create() {

        //kay gibz u can shut up about the memory usage now
        Paths.clearStoredMemory();
        Paths.clearUnusedMemory();

        if (FlxG.sound.music == null) playMenuSong();

        powerOnSound = new FlxSound().loadEmbedded(Paths.sound('pcPowerOn'));
        
        camCursor = new FlxCamera(0);
        camCursor.bgColor = 0;
        FlxG.cameras.add(camCursor,false);


        newCursor = new StupidFuckingCursorDumb(0,0,camCursor);
        add(newCursor); 

        initSets();
    
        var sets = [curtains, pizza, box, pc, lotion, wires2, mixer, bottle, phone, wires3, tissues, wires1, can1, can2, monitor, keyboard];
        for (i in 0...sets.length) {
            addSets(sets[i], i);
            // trace(sets[i]);
        }		

        FlxG.mouse.visible = false;

        monitorStuff();
        addIcons();

        #if debug
        var txt = new FlxText(0,0,0,'press 1 to go to nromal menu',24);
        add(txt);
        txt.scrollFactor.set();
        #end

        if (_initialized && fromMenu) skipIntro();

        if (fromMenu){
            switch (whichMenu){
                case "song", "options", "credits":
                    for (i in entryGroup) i.visible = true;
                    FlxTween.tween(FlxG.camera, {zoom: 0.6}, 3, {ease: FlxEase.quintInOut, onComplete: Void -> {
                        zz = zoom = FlxG.camera.zoom;
                        canSelect = true;
                        tweenLerpVal();
                    }});		
                    unDimEverythingButTheMonitor();
                case "jerma":
                    FlxTween.tween(FlxG.camera, {zoom: 0.6}, 3, {ease: FlxEase.quintInOut, onComplete: Void -> {
                        zz = zoom = FlxG.camera.zoom;
                        canSelect = true;
                        tweenLerpVal();
                    }});		
                    unDimEverythingButTheMonitor();
            }
            trace("hello, i have come back from " + whichMenu);
            fromMenu = false;
            whichMenu = "AWESOME MENU";
        } else {
            FlxG.sound.list.add(powerOnSound);
            powerOnSound.play(false, 0.4);
            FlxTween.tween(FlxG.camera, {zoom: 0.6}, 3, {ease: FlxEase.quintInOut});
        }

        super.create();

        _initialized = true;



        for (i in members) {
            if (i is FlxSprite && !(i is FlxText)) {
                var s = cast(i,FlxSprite);
                s.antialiasing = SaveData.antialiasing;
            }
        }

    }

    var introTmr:FlxTimer;

    function monitorStuff() {
        var mx = monitor.x;
        var my = monitor.y;
    
        screen = new FlxSprite(mx+97.6, my+103.75);
        screen.frames = Paths.getSparrowAtlas('userinterface/desktop/monitorParts');
        screen.animation.addByPrefix("on", "screenOn", 12, true);
        screen.animation.addByPrefix("idle", "wallpaper", 12, true);
        screen.animation.play("on");
        insert(members.indexOf(monitor), screen); 
        
        taskbar = new FlxSprite(mx+83.3, my+547.7);
        taskbar.frames = Paths.getSparrowAtlas('userinterface/desktop/monitorParts');
        taskbar.animation.addByPrefix("idle", "taskbar", 12, true);
        taskbar.animation.play("idle");
        taskbar.visible = false;
        insert(members.indexOf(monitor), taskbar); 
    
        screenOff = new FlxSprite(screen.x, screen.y);
        screenOff.makeGraphic(684, 591, 0xFF000000);
        screenOff.visible = true;
        insert(members.indexOf(monitor), screenOff); 
    
        monitorPower = new FlxSprite(mx + 697, my + 664);
        monitorPower.makeGraphic(69, 69, 0xFFFF0000);
        monitorPower.visible = false;
        add(monitorPower);
    
        introTmr = new FlxTimer().start(1.5, function(yeah:FlxTimer)
        {
            screenOff.visible = false;
            lights();

            introTmr = new FlxTimer().start(1.5, function(man:FlxTimer)
            {
                screen.animation.play("idle");

                introTmr = new FlxTimer().start(0.5, function(among:FlxTimer)
                {
                    taskbar.visible = true;       
                    FlxG.sound.play(Paths.sound('windowsXP'), 0.6);

                    introTmr = new FlxTimer().start(0.25, function(us:FlxTimer)
                    {       
                        
                        zz = zoom = FlxG.camera.zoom;           
                        canSelect = true;
                        whoUpIntroingRn=false;
                        tweenLerpVal();
                    });
                });
            });
        });  
    }

    

    var entryGroup:Array<FlxSprite> = [];
    var menuItems:Array<String> = ['play', 'gallery', 'options', 'credits'];

    function addIcons(){
        
        final offsets:Array<Array<Float>> = [
            [0,0],
            [0,-3],
            [0,3],
            [13,0]
        ];

        for(i => name in menuItems) {
            
            var entry = new FlxSprite(0, monitor.y + 158);
            entry.frames = Paths.getSparrowAtlas('userinterface/desktop/icons');
            entry.animation.addByPrefix(name, name, 12, true);
            entry.animation.play(name);
            entry.updateHitbox();
            entry.screenCenter(X);
            entry.x -= 246;
            entry.y += (i * 110);
            entry.visible = false;
            // entry.color = 0xFF9999FF;
            entryGroup.push(entry);
            entry.ID = i;
            entry.x += offsets[i][0];
            entry.y += offsets[i][1];
            i++;



            // trace(i);
            insert(members.indexOf(screenOff), entry); 
            // add(entry);
        }
        
        for (entry in entryGroup) {
            var isSelected = (entry.ID == curSelected);
        }
    
    }
    
    var curSelected:Int = -1;

    function updateSelection(f:Int) {
    
        curSelected = f;
        //  FlxG.sound.play(Paths.sound('scroll'), 0.6); // this was taken from the saster birthday bash mod lmao
    
        for (entry in entryGroup) {
            var isSelected = (entry.ID == curSelected);
            FlxTween.cancelTweensOf(entry);
            FlxTween.color(entry, 0.01, entry.color, isSelected ? 0xFF9999FF : 0xFFFFFFFF);
        }
    
    }

    var canSelect = false;

    override function update(elapsed:Float) {

        #if debug
        if (FlxG.keys.justPressed.ONE) FlxG.switchState(new MainMenuState());
        #end

        if (FlxG.keys.justPressed.ENTER && !canSelect) skipIntro();

        super.update(elapsed);
        
        if (canSelect){
            for (entry in entryGroup) {
                entry.visible = true;
                var isSelected = (entry.ID == curSelected);

                if (lightSwitch) {
                    if (FlxG.mouse.overlaps(entry)){
                        if (!isSelected) {
                            if (FlxG.mouse.justPressed && canSelect && !outOfRange) updateSelection(entry.ID);
                        }
                        selectedSomething();
                    }
                }
            }

            mouseLook();
        }

        newCursor.mouseWaiting = !canSelect;

        // trace(entryGrou)
        if (FlxG.mouse.overlaps(monitorPower)){
            if (FlxG.mouse.justPressed){
                lights();
                FlxG.sound.play(Paths.sound('monitorClick'), 0.6);
            }
            // trace("hahaha lol");
            newCursor.mouseInterest=true;
        } else if (FlxG.mouse.overlaps(entryGroup[0]) || FlxG.mouse.overlaps(entryGroup[1]) || FlxG.mouse.overlaps(entryGroup[2]) || FlxG.mouse.overlaps(entryGroup[3])){ //hhelp me
            if (lightSwitch) newCursor.mouseInterest=true;
        } else newCursor.mouseInterest=false;
        
    }

    function selectedSomething() {
        if (FlxG.mouse.justPressed && canSelect && !outOfRange) {
             FlxG.sound.play(Paths.sound('SEL_misc1'), 1);
            canSelect = false;
    
            FlxTween.tween(FlxG.camera.scroll, {x:0, y:0}, 2, {ease: FlxEase.quadOut});
    
            switch (menuItems[curSelected]) {
                case 'play':
                    trace("play");
                    var time = 1.25;
                    new FlxTimer().start(time, Void -> {screenOff.visible = true;});
                    FlxTween.tween(FlxG.camera, {zoom: 1}, 1, {startDelay: 1, ease: FlxEase.quintInOut, onComplete: Void -> {
                        FlxTransitionableState.skipNextTransIn = true;
                        FlxTransitionableState.skipNextTransOut = true;
                        FlxG.switchState(new DesktopSongSelectState());
                    }});		
                    dimEverythingButTheMonitor();
    
                case 'gallery':
                    var time = 1.25;
                    new FlxTimer().start(time, Void -> {screenOff.visible = true;});
                    FlxTween.tween(FlxG.camera, {zoom: 2.5}, time, {startDelay: 1, ease: FlxEase.cubeIn, onComplete: Void -> {
                        new FlxTimer().start(0.7, Void -> {MusicBeatState.switchState(new JermaState());});
                       
                    }});		
                    dimEverythingButTheMonitor();
                case 'options':
                    trace("opins");
                    FlxTween.tween(FlxG.camera, {zoom: 1}, 1, {startDelay: 1, ease: FlxEase.quintInOut, onComplete: Void -> {
                        FlxTransitionableState.skipNextTransIn = true;
                        FlxTransitionableState.skipNextTransOut = true;
                        OptionsState.onPlayState = false;
                        FlxG.switchState(new DesktopOptionsState());
                    }});		
                    dimEverythingButTheMonitor();
                case 'credits':
                    trace("reddits");
                    FlxTween.tween(FlxG.camera, {zoom: 1}, 1, {startDelay: 1, ease: FlxEase.quintInOut, onComplete: Void -> {
                        FlxTransitionableState.skipNextTransIn = true;
                        FlxTransitionableState.skipNextTransOut = true;
                        FlxG.switchState(new DesktopCreditsState());
                    }});		
                    dimEverythingButTheMonitor();
            }
            
            // FlxG.camera.zoom = lerp(FlxG.camera.zoom, 1, 1);
        }
    }
    
    function dimEverythingButTheMonitor() {
    
        for (shits in [curtains, pizza, box, pc, lotion, wires2, mixer, bottle, phone, wires3, tissues, wires1, can1, can2, keyboard]){
            shits.alpha = 1;
            FlxTween.tween(shits, {alpha: 0}, 1, {startDelay: 1, ease: FlxEase.circIn});
        }
        
    }    

    function unDimEverythingButTheMonitor() {
    
        for (shits in [curtains, pizza, box, pc, lotion, wires2, mixer, bottle, phone, wires3, tissues, wires1, can1, can2, keyboard]){
            shits.alpha = 0;
            FlxTween.tween(shits, {alpha: 1}, 1, {startDelay: 1, ease: FlxEase.circOut});
        }
        
    }    

    var xx:Float = 0;
    var yy:Float = 0;
    var zoom:Float = 1;
    var zz:Float = 1;
    var outOfRange = false;

    var mx:Float = 0;
    var my:Float = 0;

    var lerpVal = 0.04;
    function mouseLook() {
    
        mx = (FlxG.mouse.screenX - 640) / 10;
        my = (FlxG.mouse.screenY - 320) / 10;
    
        xx = lerp(xx, mx,lerpVal);
        yy = lerp(yy, my, lerpVal);
        zz = lerp(zz, zoom, (lerpVal/4)*3);
    
        FlxG.camera.scroll.x = xx;
        FlxG.camera.scroll.y = yy;
        FlxG.camera.zoom = zz;
    
        // trace(mx, my);
    
        if (mx >= 33 || mx <= -33 || my >= 32 || my <= -26){
            zoom = 0.5;
            outOfRange = true;
        } else {
            zoom = 0.6;
            outOfRange = false;
        }
    }

    function skipIntro(){

        if(whoUpIntroingRn){
            trace("skip");
            whoUpIntroingRn=false;

            if (!lightSwitch) lights();
            screen.animation.play("idle");
            taskbar.visible = true;

            introTmr?.cancel();

            zz = zoom = FlxG.camera.zoom;
            if (!fromMenu){
                canSelect = true;
                FlxTween.cancelTweensOf(FlxG.camera);
                tweenLerpVal();
            }
        }
    }

    function tweenLerpVal() {
        lerpVal = 0;
        FlxTween.tween(this,{lerpVal: 0.04},0.7);
    }


}

