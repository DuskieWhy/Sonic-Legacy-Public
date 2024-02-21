package meta.states.desktop;
//oww
//guys... i rember how to source!

import gameObjects.shader.ColorSwap;
import meta.data.CoolUtil;
import flixel.tweens.FlxEase;
import flixel.math.FlxMath;
import flixel.tweens.FlxTween;
import flixel.text.FlxText;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxTimer;
import flixel.FlxObject;
import flixel.addons.transition.FlxTransitionableState;
import flixel.FlxCamera;
import gameObjects.PsychVideoSprite;
import gameObjects.StupidFuckingCursorDumb;
import gameObjects.Character;
import lime.utils.Assets;
import haxe.Json;

class DesktopCreditsState extends MusicBeatState 
{
    var taskbar:FlxSprite;
    var screen:FlxSprite;
    var monitor:FlxSprite;
    var newCursor:StupidFuckingCursorDumb;
    var windowOverlay:FlxCamera;
    var windowView:FlxCamera;
    var camCRT:FlxCamera;
    var mx = 199.9;
    var my = -26.6;

    var scrollBTNdown:FlxSprite;
    var scrollBTNup:FlxSprite;
    var windowBTNdisabled:FlxSprite;
    var windowBTNx:FlxSprite;

    var scrollbarMid:FlxSprite;
    var scrollbarBottom:FlxSprite;
    var scrollbarTop:FlxSprite;


    var gayPeople:Array<FlxSprite> = [];
    var gayPeopleNames:Array<FlxSprite> = [];
    var gayPeopleIcons:Array<FlxSprite> = [];

    var menuItems:Array<String> = ['play', 'gallery', 'options', 'credits'];

    var scrollY:Float = 0.0;
    var scrollYmax:Float = 1000;
    var buddyListMode:Bool = true;

    static var buddyScrollY:Float=0;
    var kidScrollY:Float=0;

    static var curBuddyScrollY:Float;
    var curKidScrollY:Float=0;

    static var reload:Bool = false;

    var creditspadDummy:FlxSprite;
    var mouseHitbox:FlxSprite;
    var returnbutton:FlxSprite;

    function monitorStuff() {
        screen = new FlxSprite(mx+97.6, my+103.75);
        screen.frames = Paths.getSparrowAtlas('userinterface/desktop/monitorParts');
        screen.animation.addByPrefix("idle", "wallpaper", 12, true);
        screen.animation.play("idle");
        add(screen); 

        final offsets:Array<Array<Float>> = [
            [0,0],
            [0,-3],
            [0,3],
            [13,0]
        ];

        for(i => name in menuItems) {
            
            var entry = new FlxSprite(0, my + 158);
            entry.frames = Paths.getSparrowAtlas('userinterface/desktop/icons');
            entry.animation.addByPrefix(name, name, 12, true);
            entry.animation.play(name);
            entry.updateHitbox();
            entry.screenCenter(X);
            entry.x -= 246;
            entry.y += (i * 110);
            entry.x += offsets[i][0];
            entry.y += offsets[i][1];
            i++;
            add(entry);
        }
        
        taskbar = new FlxSprite(mx+83.3, my+547.7);
        taskbar.frames = Paths.getSparrowAtlas('userinterface/desktop/monitorParts');
        taskbar.animation.addByPrefix("idle", "taskbar", 12, true);
        taskbar.animation.play("idle");
        add(taskbar); 
    }

    public var buddies:Array<{name:String, professions:String, contributions:String, quote:String}> = [];

    override function create() {
        buddies = Json.parse(Assets.getText(Paths.json('fart'))).credits;

        windowView = new FlxCamera(0,0,540,387);
        windowView.bgColor = 0xFFFFFFFF;
        FlxG.cameras.add(windowView,false);

        windowOverlay = new FlxCamera(0);
        windowOverlay.bgColor = 0;
        FlxG.cameras.add(windowOverlay,false);

        camCRT = new FlxCamera(0);
        camCRT.bgColor = 0;
        FlxG.cameras.add(camCRT,false);

        // FlxG.mouse.visible=true;

        FlxG.camera.zoom = 1;

        monitorStuff();

        var creditspad = new FlxSprite(mx+140, my+100);
        creditspad.loadGraphic(Paths.image("credits/creditspad"));
        creditspad.updateHitbox();
        creditspad.screenCenter(XY);
        add(creditspad);

        creditspadDummy = new FlxSprite(mx+140, my+100);
        creditspadDummy.loadGraphic(Paths.image("credits/creditspadDummy"));
        creditspadDummy.updateHitbox();
        creditspadDummy.screenCenter(XY);
        add(creditspadDummy);

        var cX:Float = creditspad.x;
        var cY:Float = creditspad.y;

        scrollBTNup = new FlxSprite(cX+524.15,cY+83.8);
        scrollBTNup.frames = Paths.getSparrowAtlas('credits/padButtons');
        scrollBTNup.animation.addByIndices("idle", "scrollBTNup", [0], "", 1, true);
        scrollBTNup.animation.addByIndices("click", "scrollBTNup", [1], "", 1, true);
        scrollBTNup.animation.play("idle");
        scrollBTNup.updateHitbox();
        add(scrollBTNup);
        
        scrollBTNdown = new FlxSprite(cX+524.15,cY+403.45);
        scrollBTNdown.frames = Paths.getSparrowAtlas('credits/padButtons');
        scrollBTNdown.animation.addByIndices("idle", "scrollBTNdown", [0], "", 1, true);
        scrollBTNdown.animation.addByIndices("click", "scrollBTNdown", [1], "", 1, true);
        scrollBTNdown.animation.play("idle");
        scrollBTNdown.updateHitbox();
        add(scrollBTNdown);

        windowBTNdisabled = new FlxSprite(cX+415.8,cY+26.5);
        windowBTNdisabled.frames = Paths.getSparrowAtlas('credits/padButtons');
        windowBTNdisabled.animation.addByIndices("idle", "windowBTNdisabled", [0], "", 1, true);
        windowBTNdisabled.animation.play("idle");
        windowBTNdisabled.updateHitbox();
        add(windowBTNdisabled);

        windowBTNx = new FlxSprite(cX+503.75,cY+26.5);
        windowBTNx.frames = Paths.getSparrowAtlas('credits/padButtons');
        windowBTNx.animation.addByIndices("idle", "windowBTNx", [0], "", 1, true);
        windowBTNx.animation.addByIndices("click", "windowBTNx", [1], "", 1, true);
        windowBTNx.animation.play("idle");
        windowBTNx.updateHitbox();
        add(windowBTNx);
        
        windowView.x=cX+22;
        windowView.y=cY+64;
        
        monitor = new FlxSprite(mx,my);
        monitor.frames = Paths.getSparrowAtlas('userinterface/desktop/bgLayers');
        monitor.animation.addByPrefix("on", "monitorOn", 12, true);
        monitor.animation.play("on");
        monitor.updateHitbox();
        monitor.cameras=[camCRT];
        add(monitor);

        scrollbarMid = new FlxSprite(scrollBTNup.x+2, 100);
        scrollbarMid.loadGraphic(Paths.image("credits/scrollbarMid"));
        add(scrollbarMid);
    
        scrollbarBottom = new FlxSprite(scrollbarMid.x, 100);
        scrollbarBottom.loadGraphic(Paths.image("credits/scrollbarBottom"));
        scrollbarBottom.updateHitbox();
        add(scrollbarBottom);
    
        scrollbarTop = new FlxSprite(scrollbarMid.x, 100);
        scrollbarTop.loadGraphic(Paths.image("credits/scrollbarTop"));
        scrollbarTop.updateHitbox();
        add(scrollbarTop);
    
        for (fuck in [creditspad,scrollBTNup,scrollBTNdown,windowBTNdisabled,windowBTNx,scrollbarMid,scrollbarBottom,scrollbarTop])
            fuck.cameras = [windowOverlay];

        mouseHitbox = new FlxSprite(0,0);
        mouseHitbox.makeGraphic(12, 12, 0xFF0000FF);
        mouseHitbox.cameras = [windowView];
        mouseHitbox.visible = false;
        mouseHitbox.scrollFactor;
        add(mouseHitbox);

        addMyFellas();

        if (!reload){
            creditspadDummy.visible = false;
            windowOverlay.visible = false;
            windowView.visible = false;

            buddyScrollY=0;
            curBuddyScrollY=0;

            new FlxTimer().start(0.5, function(t0:FlxTimer){
                creditspadDummy.visible = true;
                creditspadDummy.scale.set(0.2, 1.25);
                new FlxTimer().start(0.06125, function(t2:FlxTimer){
                    creditspadDummy.scale.set(1.25, 0.5);
                    new FlxTimer().start(0.06125, function(t3:FlxTimer){
                        creditspadDummy.scale.set(1.125, 1.125);
                        FlxTween.tween(creditspadDummy.scale, {x: 1, y: 1}, 0.25, {ease: FlxEase.elasticOut, onComplete: Void -> {
                            new FlxTimer().start(0.125, function(t4:FlxTimer){
                                windowOverlay.visible = true;
                                windowView.visible = true   ;
                            });
                        }});
                    });
                });
            });
        }


        newCursor = new StupidFuckingCursorDumb(0,0);
        add(newCursor); 

        for (i in members) {
            if (i is FlxSprite && !(i is FlxText)) {
                var s = cast(i,FlxSprite);
                s.antialiasing = SaveData.antialiasing;
            }
        }
        
        super.create();
    }

    var introTmr:FlxTimer;

    function addMyFellas(){
        //all my fellas !!!
        // fuck off paige

        for (i in 0...buddies.length){

            var entry = new FlxSprite(0, 0);
            entry.frames = Paths.getSparrowAtlas('credits/creditbutton');
            entry.animation.addByIndices("idle", "server button", [0], "", 1, true);
            entry.animation.addByIndices("click", "server button", [1], "", 1, true); //dont flip this......
            entry.animation.play("idle");
            entry.updateHitbox();
            entry.height=(entry.height/2);
            // entry.color = 0xFFFF0000;
            entry.setPosition(15, 50 + (i * ((entry.height*2)+10)));
            gayPeople.push(entry);
            entry.ID = i;
            add(entry);
            
            var names = new FlxText(75, 60, FlxG.width, 'hi');
            names.setFormat(Paths.font(font), 30);
            names.setPosition(entry.x+110,entry.y+(entry.height/2)-30);
            names.color = 0xFF908D7F;
            names.ID = i;
            gayPeopleNames.push(names);
            add(names);
            names.text = buddies[i].name;
            
            var scale:Float = 0.45;

            var icon = new FlxSprite(entry.x+10, entry.y);
            icon.loadGraphic(Paths.image("credits/icons/" + buddies[i].name));
            icon.scale.set(scale,scale);
            icon.updateHitbox();
            icon.centerOffsets();
            icon.x = entry.x-80 + Std.int((entry.width - icon.width)/4);
            icon.y = entry.y-10 + Std.int((entry.height - icon.height)/2);
            // portrait.antialiasing=true;
            gayPeopleIcons.push(icon);
            add(icon);
            
            for (t in [entry,names,icon])
                t.cameras=[windowView];
        }

        scrollYmax=87*buddies.length;

    }

    function killMyFellas(){
            //murdered....
            for (entry in gayPeople) {
                remove(entry);
            }
            for (names in gayPeopleNames) {
                remove(names);
            }
            for (icon in gayPeopleIcons) {
                remove(icon);
            }
    }

    var boyfriendMode:Bool = false;
    var evilMode:Bool = false;
    var bf:Character;
    var bubble:FlxSprite; 
    var wahBox:FlxSprite;
    var spongebob:FlxSprite;
    var classified:FlxSprite;
    var peace:FlxSprite;
    var spongebVIDEO:PsychVideoSprite;

    var sturmVid:PsychVideoSprite;


    public var bfAnims:Array<String> = ["singUP","singLEFT","singDOWN","singRIGHT","singUP-alt","singLEFT-alt","singDOWN-alt","singRIGHT-alt"];

    var name:FlxText;
    var portrait:FlxSprite;
    var professions:FlxText;
    var contributions:FlxText;
    var quote:FlxText;
    var font:String="There Comic.ttf";
    var silly:FlxSound;
    function whoIsThisKid(id:Int) {
        var fieldWidth:Float=windowView.width-140;

        name = new FlxText(75, 100, fieldWidth, buddies[id].name);
        name.setFormat(Paths.font(font), 48);
        name.color=0xFF000000;
        name.alignment="center";
        add(name);
        
        portrait = new FlxSprite(0, name.y+name.height+30);
        portrait.loadGraphic(Paths.image("credits/portraits/" + buddies[id].name));
        add(portrait);

        professions = new FlxText(75, portrait.y+portrait.height+20, fieldWidth, buddies[id].professions);
        professions.setFormat(Paths.font(font), 30);
        professions.color=0xFF000000;
        professions.alignment="center";
        add(professions);

        contributions = new FlxText(75, professions.y+professions.height+20, fieldWidth, buddies[id].contributions);
        contributions.setFormat(Paths.font(font), 20);
        contributions.color=0xFF7F7F7F;
        contributions.alignment="center";
        add(contributions);

        quote = new FlxText(75, contributions.y+contributions.height+20, fieldWidth, buddies[id].quote);
        quote.setFormat(Paths.font(font), 15);
        quote.color=0xFFC3C3C3;
        quote.alignment="center";
        add(quote);

        returnbutton = new FlxSprite(30, 30);
        returnbutton.frames = Paths.getSparrowAtlas('credits/returnbutton');
        returnbutton.animation.addByIndices("idle", "return", [0], "", 1, true);
        returnbutton.animation.addByIndices("click", "return", [1], "", 1, true);
        returnbutton.animation.play("idle");
        returnbutton.updateHitbox();
        returnbutton.cameras=[windowView];
        add(returnbutton);
    

        for (t in [name,portrait,professions,contributions,quote]){
            t.cameras=[windowView];
            centerInWindow(t);
        }
        var shader = new ColorSwap();
        shader.saturation=-5;

        scrollYmax=quote.y-(windowView.height/1.5);

        switch (buddies[id].name) {
            case 'Sturm':

                sturmVid = new PsychVideoSprite(false);
                sturmVid.load(Paths.video('deterrence'),[]);
                sturmVid.play();

                sturmVid.addCallback(ONEND,()->{
                    FlxTween.tween(sturmVid,{alpha: 0},1);
                });
                sturmVid.addCallback(ONFORMAT,()->{
                    sturmVid.graphicSize(contributions.width - 100);
                    centerInWindow(sturmVid);
                    sturmVid.y = contributions.y+300;
                    scrollYmax=sturmVid.y;
                    sturmVid.hide();
                    sturmVid.pause();
                });
                sturmVid.shader = shader.shader;
                add(sturmVid);
                sturmVid.cameras=[windowView];
                
            case 'TemmieZoneNG':
                scrollYmax=quote.y + (windowView.height/1.5);
            case "Funkin' Team":
                boyfriendMode=true;
                bf = new Character(0, contributions.y+100);

                bf.cameras=[windowView];
                centerInWindow(bf);
                bf.x-=40;
                add(bf); 
                quote.y = bf.y+550+30;
                scrollYmax=quote.y-(windowView.height/1.5);
                bf.shader = shader.shader;
            case 'DuskieWhy':
                evilMode = true;
            case 'Gibz':
                var vid = new PsychVideoSprite(false);
                vid.load(Paths.video('fucking burning in hell'),[PsychVideoSprite.looping,PsychVideoSprite.muted]);
                vid.play();
                vid.addCallback(ONFORMAT,()->{
                    vid.graphicSize(contributions.width - 100);
                    centerInWindow(vid);
                    vid.y = contributions.y+100;
                    scrollYmax=vid.y;
                });
                vid.shader = shader.shader;
                add(vid);
                vid.cameras=[windowView];

            case 'Adrix':
                var adrixfuckingDied = new FlxSprite().loadImage('credits/images/adrix');
                adrixfuckingDied.graphicSize(contributions.width - 100);
                adrixfuckingDied.cameras=[windowView];
                centerInWindow(adrixfuckingDied);

                adrixfuckingDied.y = contributions.y+200;
                add(adrixfuckingDied);
                adrixfuckingDied.shader = shader.shader;
                scrollYmax=adrixfuckingDied.y;

            case 'Data':
                var data = new FlxSprite().loadImage('credits/images/data');
                data.graphicSize(contributions.width - 100);
                data.cameras=[windowView];
                centerInWindow(data);

                data.y = contributions.y+200;
                add(data);
                data.shader = shader.shader;
                scrollYmax=data.y;
            case 'Rhysamath':
                silly = new FlxSound().loadEmbedded('assets/images/credits/images/rhy.ogg', true);
                silly.play();
                FlxG.sound.list.add(silly);
                silly.volume = 0;
                silly.fadeTween.cancelTween();
                silly.fadeIn(1.25,0,0.3);
            case 'Red3127':
                var red = new FlxSprite().loadImage('credits/images/red3');
                red.graphicSize(contributions.width - 100);
                red.cameras=[windowView];
                centerInWindow(red);

                red.y = contributions.y+200;
                add(red);
                red.shader = shader.shader;
                scrollYmax=red.y;

            case 'PaigeyPaper':
                var sussy = new FlxSprite().loadImage('credits/paige/paige');
                sussy.cameras=[windowView];
                centerInWindow(sussy);
                sussy.y = portrait.y+portrait.height;
                add(sussy);

                silly = new FlxSound().loadEmbedded('assets/images/credits/paige/silly.ogg', true);
                silly.play();
                FlxG.sound.list.add(silly);
                silly.volume = 0;
                silly.fadeTween.cancelTween();
                silly.fadeIn(1.5,0,0.05);

        }



        if(evilMode){ //heeyyy... why does she get her OWN mode, and i don't! grrrrr......... -paige
            bubble = new FlxSprite().loadGraphic(Paths.image("credits/ava/bubble"));
            bubble.cameras=[windowView];
            bubble.scale.set(0.25, 0.25);
            centerInWindow(bubble);
            bubble.y = quote.y;
            bubble.shader = shader.shader;
            add(bubble);

            var quote2 = new FlxText(75, contributions.y+contributions.height+20, fieldWidth, "Thank you mr krabs, spongebob, patrick, gary, squidward");
            quote2.setFormat(Paths.font(font), 15);
            quote2.color=0xFFC3C3C3;
            quote2.alignment="center";
            centerInWindow(quote2);
            quote2.y = bubble.y + bubble.height + 50;
            quote2.cameras=[windowView];
            add(quote2);

            spongebVIDEO = new PsychVideoSprite();
            spongebVIDEO.load(Paths.video('spongebob'), [PsychVideoSprite.looping]);
            spongebVIDEO.cameras=[windowView];
            spongebVIDEO.scale.set(0.25, 0.1);
            add(spongebVIDEO);
            spongebVIDEO.y = quote2.y + quote2.height - (quote2.height * 15);
            spongebVIDEO.play();
            spongebVIDEO.alpha = 1;
            spongebVIDEO.shader = shader.shader;

            var quote3 = new FlxText(75, contributions.y+contributions.height+20, fieldWidth, "and even that evil fuck plankton. I also would like to thank Marco Antonio for making Mario's Madness. FNF Classified releases tomorrow, so make sure you check it out!");
            quote3.setFormat(Paths.font(font), 15);
            quote3.color=0xFFC3C3C3;
            quote3.alignment="center";
            centerInWindow(quote3);
            quote3.y = quote3.y + quote3.height + (quote3.height * 5);
            quote3.cameras=[windowView];
            add(quote3);

            classified = new FlxSprite().loadGraphic(Paths.image('credits/ava/classified'));
            classified.cameras = [windowView];
            classified.scale.set(0.25, 0.25);
            centerInWindow(classified);
            classified.y = quote3.y - (classified.height / 4);
            add(classified);
            classified.shader = shader.shader;

            var quote4 = new FlxText(75, contributions.y+contributions.height+20, fieldWidth, "theWahBox (composer of French Fries, Burgers and a few FAF songs) says hi! Make sure to squeeze.. @Victor, shut the hell up. I get it. youre so ugly. god. ugh. Thank you to Yoshi, Mario, and of course Sonic the Hedgehog, for making all of my dreams come true. I would also like to thank Burgers for being the worst thing ever made by anyone, they taste so groosssssss 👎. I can't believe I'm finally here, this is what we've ALL been waiting for. You're CRAZY; CRAZY! SUPER CRAZY! I CAN'T BELIEVE YOU THINK BURGERS BY WAHBOX IS A GOOD SONG!!!!! hey now I just appreciate good music. FUck you. UUGGHH");
            quote4.setFormat(Paths.font(font), 15);
            quote4.color=0xFFC3C3C3;
            quote4.alignment="center";
            centerInWindow(quote4);
            quote4.y = classified.y + classified.height - (quote4.height * 2);
            quote4.cameras=[windowView];
            add(quote4);

            wahBox = new FlxSprite().loadGraphic(Paths.image('credits/ava/wahbox'));
            wahBox.cameras=[windowView];
            wahBox.scale.set(0.25, 0.25);
            centerInWindow(wahBox);
            wahBox.y = quote4.y + (wahBox.height / 8) - 100;
            add(wahBox);
            wahBox.shader = shader.shader;

            var quote5 = new FlxText(75, contributions.y+contributions.height+20, fieldWidth, "Look man I dont sell burgers here WAAAHHHWAWHHHHHWHAHAHWAWAWAWAWAW Hop on VS a shitty laptop and Vs kanye by duskiewhy, and make sure to play therapissed and use the camera lua script by ashstat. Listen to flame war by redtv, something something fried frick insult, this is what you get for breaking my chips @vortex, fuck off LOSER. Love all my friends, you're all great !!! ESPECIALLY girlfriend fnf . Thank you. Seriously. Play hit single, subscribe to my youtube, donate to my paypal, use my creator code, and make sure to hit that follow button. Peace out.");
            quote5.setFormat(Paths.font(font), 15);
            quote5.color=0xFFC3C3C3;
            quote5.alignment="center";
            centerInWindow(quote5);
            quote5.y = wahBox.y + wahBox.height - (quote5.height * 0.75) - 150;
            quote5.cameras=[windowView];
            add(quote5);


            scrollYmax=quote5.y;
        }
    }

    function killThisKid() {
        for (t in [name,portrait,professions,contributions,quote]){t.destroy(); remove(t);}
        if (boyfriendMode) bf.destroy(); remove(bf);
    }

    function centerInWindow(obj:FlxObject) {
        obj.x = Std.int((windowView.width - obj.width)/2);
    }

    function setRole(role:String) {
        var color:FlxColor = 0xFFB9F1FF;
        switch (role){
            case "Director", "Co-Director": color = 0xFFF1C40F;
            case "Coder": color = 0xFFE74C3C;
            case "Charter": color = 0xFFE67E22;
            case "3D Modeller": color = 0xFFE91E63;
            case "Artist": color = 0xFF59FF3F;
            case "Voice Actor": color = 0xFF9B59B6;
            case "Musician": color = 0xFF3A21FF;
        }
        return color;
    } //sadly unused :()

    function gobackpls(backToDesktop:Bool=false){
        if (backToDesktop){
            new FlxTimer().start(0.06125, function(t0:FlxTimer){
                windowOverlay.visible = false;
                windowView.visible = false;
                new FlxTimer().start(0.06125, function(t2:FlxTimer){
                    creditspadDummy.visible = false;
                    new FlxTimer().start(0.06125, function(t3:FlxTimer){
                        FlxTransitionableState.skipNextTransIn = true;
                        FlxTransitionableState.skipNextTransOut = true;
                        DesktopMenuState.fromMenu = true;
                        DesktopMenuState.whichMenu = "credits";
                        FlxG.switchState(new DesktopMenuState());
                    });
                });
            });
        } else {
            FlxTransitionableState.skipNextTransIn = true;
            FlxTransitionableState.skipNextTransOut = true;
            FlxG.resetState();
            reload=true;
        }
    }

    override function update(elapsed:Float) {

        if (controls.BACK) {
            if (buddyListMode) {
                gobackpls(true);
            }
            else {
                gobackpls();
            }
        }

        if (!buddyListMode && mouseHitbox.overlaps(returnbutton,windowView) && FlxG.mouse.justReleased && !mouseDrag) gobackpls();

        if (FlxG.mouse.overlaps(windowBTNx,windowOverlay) && FlxG.mouse.justReleased && !mouseDrag) gobackpls(true);


        super.update(elapsed);

        scrollbarMid.scale.y = 60 * (277/scrollYmax);
        scrollbarMid.updateHitbox();
        scrollbarMid.y = FlxMath.bound(FlxMath.remapToRange(windowView.scroll.y, 0, scrollYmax, scrollBTNup.y+scrollBTNup.height+5+scrollbarTop.height, scrollBTNdown.y-scrollbarMid.height-5-scrollbarBottom.height), scrollBTNup.y+scrollBTNup.height+5+scrollbarTop.height, scrollBTNdown.y-scrollbarMid.height-5-scrollbarBottom.height);
        scrollbarBottom.y = scrollbarMid.y+(scrollbarMid.height);
        scrollbarTop.y = scrollbarMid.y-scrollbarTop.height;


        if (sturmVid != null) {
            if (FlxG.mouse.justPressed) {
                trace('oh');
                sturmVid.play();
                FlxTween.tween(sturmVid, {alpha: 1},0.4);
            }
        }

        
        if (FlxG.mouse.overlaps(windowBTNx,windowOverlay)&&!mouseDrag){
            if(FlxG.mouse.pressed) windowBTNx.animation.play("click");
            else windowBTNx.animation.play("idle");
        } else windowBTNx.animation.play("idle");

        if (FlxG.mouse.overlaps(windowBTNdisabled,windowOverlay)&&!mouseDrag) newCursor.mouseDisabled=true;
        else newCursor.mouseDisabled=false;
        

        var mouseScreenPos = FlxG.mouse.getScreenPosition();
        var creditDummyPos = creditspadDummy.getScreenPosition();
        if (FlxMath.inBounds(mouseScreenPos.x,creditDummyPos.x,creditDummyPos.x + creditspadDummy.width) && FlxMath.inBounds(mouseScreenPos.y,creditDummyPos.y + 75,creditDummyPos.y + creditspadDummy.height-10)) {
            if (buddyListMode&&!mouseDrag){
                for (entry in gayPeople) {
                    var curSelected:Int=entry.ID;
                    if (mouseHitbox.overlaps(entry,windowView)){
                        entry.animation.play("click");
                        // if(FlxG.mouse.pressed) {
                            gayPeopleNames[curSelected].offset.set(-5,5);
                            gayPeopleIcons[curSelected].x = entry.x-75 + Std.int((entry.width - gayPeopleIcons[curSelected].width)/4);
                            gayPeopleIcons[curSelected].y = entry.y-15 + Std.int((entry.height - gayPeopleIcons[curSelected].height)/2);
                        //}
                        
                        
                        if(FlxG.mouse.justReleased){
                            trace(buddies[curSelected].name);
                            currentSelect = curSelected;
                            buddyListMode=false;
                            killMyFellas();
                            whoIsThisKid(curSelected);
                            windowView.scroll.y=curKidScrollY=kidScrollY=0;
                        }
    
                    } else {
                        entry.animation.play("idle");
                        gayPeopleNames[curSelected].offset.set(0,0);
                        gayPeopleIcons[curSelected].x = entry.x-80 + Std.int((entry.width - gayPeopleIcons[curSelected].width)/4);
                        gayPeopleIcons[curSelected].y = entry.y-10 + Std.int((entry.height - gayPeopleIcons[curSelected].height)/2);
                    }
                }
            }
        }
        else {
            for (i in gayPeople) i.animation.play("idle");
        }


        for (i in gayPeople) i.centerOffsets();


        for (guh in [scrollBTNdown,scrollBTNup]){
            if (FlxG.mouse.overlaps(guh,windowOverlay)&&!mouseDrag){
                if(FlxG.mouse.pressed) guh.animation.play("click");
                else guh.animation.play("idle");
            } else guh.animation.play("idle");
        }

        if (!buddyListMode&&!mouseDrag){
            if (mouseHitbox.overlaps(returnbutton,windowView)&&!mouseDrag){
                if (FlxG.mouse.pressed) returnbutton.animation.play("click");
                else returnbutton.animation.play("idle");
            } else returnbutton.animation.play("idle");
        }

        scrollY =(FlxG.mouse.wheel*(FlxG.keys.pressed.SHIFT?80:30));

            
        if (FlxG.mouse.overlaps(scrollbarMid,windowOverlay)) {
            if(FlxG.mouse.justPressed) mouseDrag=true; 
        }

        scrollbarDrag = FlxG.mouse.deltaY*(scrollbarMid.scale.y);

        if (mouseDrag){
            if (buddyListMode) curBuddyScrollY = FlxMath.bound(buddyScrollY += scrollbarDrag,0,scrollYmax);
            else curKidScrollY = FlxMath.bound(kidScrollY += scrollbarDrag,0,scrollYmax);
            if(FlxG.mouse.justReleased) mouseDrag=false;
        }


        if (buddyListMode){
            if (buddyScrollY <= 0) buddyScrollY=0;
            if (buddyScrollY >= scrollYmax) buddyScrollY = scrollYmax;
            buddyScrollY -= buddyListMode?scrollY:0;
            if (scrollBTNdown.animation.curAnim.name == "click") buddyScrollY+=5;
            if (scrollBTNup.animation.curAnim.name == "click") buddyScrollY-=5;
        } else {
            if (kidScrollY <= 0) kidScrollY=0;
            if (kidScrollY >= scrollYmax) kidScrollY = scrollYmax;
            kidScrollY -= !buddyListMode?scrollY:0;
            if (scrollBTNdown.animation.curAnim.name == "click") kidScrollY+=5;
            if (scrollBTNup.animation.curAnim.name == "click") kidScrollY-=5;

            if (buddies[currentSelect].name == 'Adrix') {
                adrixTmr-=elapsed;
                if (adrixTmr < 0) {
                    adrixTmr = 999999;
                    FlxG.sound.play(Paths.sound('Skibidi'));
                    var length = Paths.sound('Skibidi').length /1000;
                    length /=2;
                    new FlxTimer().start(length,Void->{
                        professions.text = 'Skibidi Artist, ' + professions.text;
                        contributions.y += 10;
                        quote.y += 10;
                    });

                    
                }
            }
        }

        windowView.scroll.y = buddyListMode?curBuddyScrollY = lerp(curBuddyScrollY, buddyScrollY, 0.4):curKidScrollY = lerp(curKidScrollY, kidScrollY, 0.4);

        // trace(buddyScrollY);

        mouseHitbox.setPosition(FlxG.mouse.x-windowView.x,FlxG.mouse.y-windowView.y+windowView.scroll.y);
        // trace(scrollY);
        if (boyfriendMode) {
            if(bf.animation.curAnim.curFrame >= 4) bf.playAnim(bfAnims[FlxG.random.int(0,bfAnims.length-1)], true, false, 0);
            bf.flipX=false;
        }
    }
}

var mouseDrag:Bool = false;
var scrollbarDrag:Float;
var adrixTmr:Float = 40;
var currentSelect:Int = 0;