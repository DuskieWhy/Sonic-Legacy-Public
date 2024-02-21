package meta.states.desktop;

import meta.data.options.OptionsState;
import flixel.FlxSubState;
import flixel.addons.display.FlxRuntimeShader;
import flixel.tweens.FlxEase;
import flixel.math.FlxMath;
import flixel.tweens.FlxTween;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.text.FlxTypeText;
import flixel.text.FlxText;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxTimer;
import meta.data.CoolUtil;
import gameObjects.StupidFuckingCursorDumb;

class DesktopOptionsState extends MusicBeatState
{

    var inSubState:Bool = false;

    public static var instance:DesktopOptionsState;
    public static var monitor:FlxSprite;
    public static var newCursor:StupidFuckingCursorDumb;
    public var screen:FlxSprite;
    public var taskbar:FlxSprite;

    public var display:FlxCamera;
    public var camCRT:FlxCamera;
    public var camControls:FlxCamera;

    public static var canSelect:Bool = false;

    public var statIntroTXT:FlxText;
    public var cmdTypeTXT:FlxTypeText;
    public var selectorArrow:FlxText;

    public var curSelected:Int = 0;
    public var inMain:Bool = true;

    public var cmd:FlxSprite;
    var mainOptionsList:Array<Array<String>> = [["NOTES", "Change the colors of your notes ingame."], 
    ["CONTROLS", "Change the controls used throughout the PC."], 
    ["DELAY-COMBO", "Change the delay offset and combo positions."], 
    ["GRAPHICS", "Change the graphics settings used ingame."], 
    ["VISUALS-UI", "Change the UI preferences and framerate."], 
    ["GAMEPLAY", "Change specific gameplay prefences used while playing through the PC."], 
    ["LOADING", "Change the settings for how content is loaded."],
    ['GAMEPLAY-PREFERENCES',"Change gameplay Modifiers."],
    ['RESET',"Reset Progression\n\nFor more information on tools see the command-line reference in the online help."]
    ];
    var mainOptionsGrp:Array<FlxText> = [];

    public static var closeBox:FlxSprite;

    override function create() {
        instance = this;

        persistentUpdate = true;

        display = new FlxCamera();
        display.bgColor = 0;
        FlxG.cameras.add(display,false);
        display.zoom = 1;
        
        var path = Paths.getContent(Paths.exists(Paths.modsShaderFragment('CRT')) ? Paths.modsShaderFragment('CRT') : Paths.shaderFragment('CRT'));
        var crt = new FlxRuntimeShader(path);
        crt.setFloat('warp',3.5);
        ApplyShaderToCamera(crt,display);
    
        camCRT = new FlxCamera();
        camCRT.bgColor = 0;
        FlxG.cameras.add(camCRT,false);

        camControls = new FlxCamera();
        camControls.bgColor = 0;
        FlxG.cameras.add(camControls,false);

        monitor = new FlxSprite(199.9, -26.6);
        monitor.frames = Paths.getSparrowAtlas('userinterface/desktop/bgLayers');
        monitor.animation.addByPrefix("on", "monitorOn", 12, true);
        monitor.animation.play("on");
        monitor.updateHitbox();

        monitor.cameras = [camCRT];
        screen = new FlxSprite(monitor.x+97.6, monitor.y+103.75);
        screen.frames = Paths.getSparrowAtlas('userinterface/desktop/monitorParts');
        screen.animation.addByPrefix("on", "screenOn", 12, true);
        screen.animation.addByPrefix("idle", "wallpaper", 12, true);
        screen.animation.play("idle");
        taskbar = new FlxSprite(monitor.x+83.3, monitor.y+547.7);
        taskbar.frames = Paths.getSparrowAtlas('userinterface/desktop/monitorParts');
        taskbar.animation.addByPrefix("idle", "taskbar", 12, true);
        taskbar.animation.play("idle");
        add(screen);
        add(taskbar);

        cmd = new FlxSprite().loadGraphic(Paths.image("userinterface/cmd"));
        cmd.setGraphicSize(Std.int(cmd.width * 2));
        cmd.updateHitbox();
        cmd.setPosition(((screen.width - cmd.width) / 2) + screen.x, ((screen.height - cmd.height) / 2) + screen.y- 40);
        add(cmd);
        cmd.visible = false;

        statIntroTXT = new FlxText(0, 0, 636, "C:\\Users\\boyfriend> ");
        statIntroTXT.setFormat(Paths.font("cmd.ttf"), 32, FlxColor.WHITE, LEFT);
        statIntroTXT.setPosition(335.5, 212.15);
        statIntroTXT.visible = false;
        add(statIntroTXT);
        
        var soundz:Array<FlxSound> = [];
        cmdTypeTXT = new FlxTypeText(0,0, 366, "help");
        for(i in 1...5) soundz.push(FlxG.sound.load(Paths.sound('keyboard/click$i')));
        cmdTypeTXT.sounds = soundz;
        cmdTypeTXT.setFormat(Paths.font("cmd.ttf"), 32, FlxColor.WHITE, LEFT);
        cmdTypeTXT.setPosition(626, 212.15);
        cmdTypeTXT.visible = false;
        add(cmdTypeTXT);
        
        for(i in 0...mainOptionsList.length) {
            var txt = new FlxText(0,0, 636, '${mainOptionsList[i][0]}      ${mainOptionsList[i][1]}');
            txt.setFormat(Paths.font("cmd.ttf"), 16, FlxColor.WHITE, LEFT);
            txt.setPosition(355.5, 212.15 + cmdTypeTXT.height + (cmdTypeTXT.height * (i * 0.5)));
            trace(cmdTypeTXT.height);
            txt.visible = false;
            txt.ID = i;
            add(txt);
            mainOptionsGrp.push(txt);
        }

        selectorArrow = new FlxText(0,0, 636, ">");
        selectorArrow.setFormat(Paths.font("cmd.ttf"), 16, FlxColor.RED, LEFT);
        selectorArrow.setPosition(335.5, mainOptionsGrp[0].y);
        selectorArrow.visible = false;
        add(selectorArrow);
        

        new FlxTimer().start(1, function(t0:FlxTimer){
            new FlxTimer().start(0.25, function(t1:FlxTimer){
                cmd.visible = true;
                cmd.scale.set(0.2, 1.25);
                new FlxTimer().start(0.06125, function(t2:FlxTimer){
                    cmd.scale.set(1.25, 0.5);
                    new FlxTimer().start(0.06125, function(t3:FlxTimer){
                        cmd.scale.set(1.125, 1.125);
                        FlxTween.tween(cmd.scale, {x: 1, y: 1}, 0.25, {ease: FlxEase.elasticOut, onComplete: Void -> {
                            new FlxTimer().start(0.125, function(t4:FlxTimer){
                                statIntroTXT.visible = true;
                                new FlxTimer().start(0.5, function(t5:FlxTimer){
                                    cmdTypeTXT.visible = true;
                                    cmdTypeTXT.start();
                                    cmdTypeTXT.completeCallback = function(){
                                        for(i in 0...mainOptionsGrp.length) {
                                            new FlxTimer().start(0.06125 * i, function(t6:FlxTimer){
                                                mainOptionsGrp[i].visible = true;
                                            });
                                        }
                                        selectorArrow.visible = true;
                                        canSelect = true;
                                    }
                                });
                            });
                        }});
                    });
                });
            });
        });

        closeBox = new FlxSprite(870, 179).makeGraphic(60, 30, FlxColor.RED);
        closeBox.visible = false;
        add(closeBox);

        addIcons();

        add(monitor);

        newCursor = new StupidFuckingCursorDumb(0,0,null,0.4,0.4);
        newCursor.mouseLockon = false;
        add(newCursor); 

        var array = [cmd,cmdTypeTXT,statIntroTXT,selectorArrow];
        for (i in mainOptionsGrp) array.push(i);

        for (i in array) {
            i.cameras = [display];
        }
        super.create();


        for (i in members) {
            if (i is FlxSprite && !(i is FlxText)) {
                var s = cast(i,FlxSprite);
                s.antialiasing = SaveData.antialiasing;
            }
        }
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
            entry.ID = i;
            entry.x += offsets[i][0];
            entry.y += offsets[i][1];
            i++;
            add(entry);
        }

    
    }

    override function update(elapsed:Float) {
        super.update(elapsed);

        newCursor.setPosition(FlxG.mouse.x, FlxG.mouse.y);

        if (!inSubState) {
            if (controls.BACK && inMain) {
                if (!OptionsState.onPlayState) {
                    FlxTransitionableState.skipNextTransIn = true;
                    FlxTransitionableState.skipNextTransOut = true;
                    DesktopMenuState.fromMenu = true;
                    DesktopMenuState.whichMenu = "options";
                    FlxG.switchState(new DesktopMenuState());
                }
                else {
                    FlxG.mouse.visible = false;
                    meta.data.StageData.loadDirectory(PlayState.SONG);
                    MusicBeatState.switchState(new PlayState());
                    FlxG.sound.music.volume = 0;
                }

            }
    
            if(canSelect && FlxG.mouse.overlaps(closeBox) && FlxG.mouse.justPressed){
                FlxTransitionableState.skipNextTransIn = true;
                FlxTransitionableState.skipNextTransOut = true;
                DesktopMenuState.fromMenu = true;
                DesktopMenuState.whichMenu = "song";
                FlxG.switchState(new DesktopMenuState());
            }
    
            cmd.updateHitbox();
            cmd.screenCenter();
    
            if(canSelect){
                if(controls.UI_UP_P)
                    changeSelection(-1);
                if(controls.UI_DOWN_P)
                    changeSelection(1);
                if(controls.ACCEPT)
                    selectOption(curSelected, mainOptionsList);    
            }
        }


    }

    function selectOption(option:Int, list:Dynamic){
        if(inMain){
            //FlxG.sound.play(Paths.sound('scroll'));

            for(i in 0...mainOptionsGrp.length) mainOptionsGrp[i].visible = false;
            cmdTypeTXT.resetText(mainOptionsList[option][0]);
            cmdTypeTXT.start();
            selectorArrow.visible = false;
            cmdTypeTXT.completeCallback = function(){
                new FlxTimer().start(0.5, function(t:FlxTimer){
                    inSubState = true;
                    switch(mainOptionsList[option][0]){
                        case "NOTES":
                            openSubState(new meta.states.substate.desktoptions.DesktopNoteSettingsSubstate());
                        case "CONTROLS":
                            for (camera in [display,camCRT,FlxG.camera]){
                                    FlxTween.tween(FlxG.camera, {alpha: 0}, 1, {ease: FlxEase.cubeIn});
                                    FlxTween.tween(newCursor, {alpha: 0}, 1, {ease: FlxEase.cubeIn});
                                    FlxTween.tween(camera, {zoom: 4}, 1, {ease: FlxEase.cubeIn, onComplete: Void -> {
                                        openSubState(new meta.data.options.ControlsSubState());
                                }});
                            }
                        case "DELAY-COMBO":
                            LoadingState.loadAndSwitchState(new meta.data.options.NoteOffsetState());
        
                        case "GRAPHICS":
                            openSubState(new meta.states.substate.desktoptions.DesktopGraphicsSettings());
        
                        case "VISUALS-UI":
                            openSubState(new meta.states.substate.desktoptions.DesktopVisualsUISettings());
         
                        case "GAMEPLAY":
                            openSubState(new meta.states.substate.desktoptions.DesktopGameplaySettings());
        
                        case "LOADING":
                            openSubState(new meta.states.substate.desktoptions.DesktopMiscSettings());
                        case 'GAMEPLAY-PREFERENCES':
                            openSubState(new meta.states.substate.desktoptions.GameplayPrefs());     
                        case "RESET":
                            openSubState(new meta.states.substate.desktoptions.ResetSubstate());
        
                    }
                });
            }

        }

    }

    function changeSelection(change:Int){

        curSelected = FlxMath.wrap(curSelected + change,0,mainOptionsList.length-1);

        selectorArrow.y = mainOptionsGrp[curSelected].y;
        FlxG.sound.play(Paths.sound('keyboard/click${FlxG.random.int(1,3)}'));
        //array lengths arent ints ??????? what?????????????

    }

    override function closeSubState() {
        inSubState = false;
        super.closeSubState();
    }
    public function returning(){
        for (camera in [display,camCRT,FlxG.camera]){
            FlxTween.tween(camera, {zoom: 1}, 1, {ease: FlxEase.cubeOut});
            FlxTween.tween(newCursor, {alpha: 1}, 1, {ease: FlxEase.cubeOut});
            FlxTween.tween(FlxG.camera, {alpha: 1}, 1, {ease: FlxEase.cubeOut});
        }
        canSelect = false;
        cmdTypeTXT.visible = true;
        cmdTypeTXT.resetText('help');
        cmdTypeTXT.start();
        cmdTypeTXT.completeCallback = function(){
            for(i in 0...mainOptionsGrp.length) {
                new FlxTimer().start(0.06125 * i, function(t6:FlxTimer){
                    mainOptionsGrp[i].visible = true;
                });
            }
            selectorArrow.visible = true;
            canSelect = true;
        }
        trace('return');
    }
}