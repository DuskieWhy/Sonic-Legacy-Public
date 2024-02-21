package meta.ui;

import flixel.math.FlxPoint;
import flixel.graphics.frames.FlxBitmapFont;
import flixel.text.FlxBitmapText;
import flixel.ui.FlxBar;
import meta.data.Highscore;
import meta.states.PlayState;

class ExeUI extends BaseUI
{

    var healthBarOverlay:FlxSprite;
    var healthBarStitch:FlxSprite; 

    var scoreNum:FlxBitmapText;
    var cmboNum:FlxBitmapText;
    var accNum:FlxBitmapText;
    var cmboBreaks:FlxSprite;
    var score:FlxSprite;
    var acc:FlxSprite;

    final spacing:Float = (7*2);
    final numSpacing = new FlxPoint(7,11);

    var isFlashing:Bool = false;

    override function createUI() 
    {
        healthBarOverlay = new FlxSprite().loadGraphic(Paths.image('ui/hpBar-exe'));
        healthBarOverlay.screenAlignment(ClientPrefs.data.downScroll ? TOPMID : BOTTOMMID);
        healthBarOverlay.y += ClientPrefs.data.downScroll ? -20 : 20;
        healthBarOverlay.flipY = ClientPrefs.data.downScroll;

        createHPbar(healthBarOverlay.x + 33,healthBarOverlay.y + (ClientPrefs.data.downScroll ? 71 : 21), 607, 35);
        healthBar.createFilledBar(FlxColor.fromRGB(71, 63, 75), FlxColor.fromRGB(237, 28, 36));
        healthBar.updateFilledBar();
		healthBar.updateBar();

        healthBarStitch = new FlxSprite().loadGraphic(Paths.image('ui/stitchMiddleEXE'));
        healthBarStitch.y = healthBar.y + 15;

        final scoreY:Float = (ClientPrefs.data.downScroll ? 100 : camHUD.height * 0.91);

        score = new FlxSprite().loadImage('ui/score');
        cmboBreaks = new FlxSprite().loadImage('ui/cmbo');
        acc = new FlxSprite().loadImage('ui/acc');
        
        cmboNum = new FlxBitmapText(FlxBitmapFont.fromMonospace(Paths.image('ui/nums'),'0123456789:',numSpacing));
        cmboNum.text = '01';

        scoreNum = new FlxBitmapText(FlxBitmapFont.fromMonospace(Paths.image('ui/nums'),'0123456789:',numSpacing));
        scoreNum.text = '01';

        accNum = new FlxBitmapText(FlxBitmapFont.fromMonospace(Paths.image('ui/ratings'),'xsabcde:',new FlxPoint(18,19)));
        accNum.text = 'x';

        for (i in [cmboBreaks,cmboNum,score,scoreNum,acc,accNum]) {i.setScale(2); i.y = scoreY + 25;}
        accNum.centerOnSprite(acc,Y);


        healthBarOverlay.alpha = healthBarStitch.alpha = healthBar.alpha = ClientPrefs.data.healthBarAlpha;

        //TEMP SOLUTION
        if(ClientPrefs.data.timeBarType == 'Song Name') {
			if (PlayState.SONG.song == 'Obituary') {
                PlayState.instance.timeTxt.text = 'obituary';
			}
		}

        repositionScore();
        onUpdateScore();

    }
    

    //this funciton kinda sucks imma do smth better about this later
    override public function sort()
    {
        var dumpExclusions = [current.botplayTxt,current.timeTxt,current.timeBitmapTxt,current.timeBarBG,current.timeBar];
        for (i in uiGroup) if (!dumpExclusions.contains(i)) remove(i);

        for (i in [healthBar,healthBarStitch,healthBarOverlay,iconP1,iconP2,acc,score,cmboBreaks,accNum,scoreNum,cmboNum]) add(i);



        current.timeTxt.visible = false;
        current.timeBitmapTxt.visible = !current.timeTxt.visible;

        //TEMP SOLUTION
        if(ClientPrefs.data.timeBarType == 'Song Name') {
            if (PlayState.SONG.song == 'Obituary') {
                current.timeTxt.text = 'Obituary';
                current.timeTxt.visible = true;
                current.timeBitmapTxt.visible = !current.timeTxt.visible;
            }
        }
    }

    override function update(elapsed:Float) {

        super.update(elapsed);
        healthBarStitch.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01)) - 7;
        
    }

    override function onBeatHit() 
    {
        if (isFlashing) {
            if (curBeat % 2 == 0) {
                score.color = FlxColor.RED;
                cmboBreaks.color = FlxColor.RED;
                acc.color = FlxColor.RED;
            }
            else {
                score.color = FlxColor.WHITE;
                cmboBreaks.color = FlxColor.WHITE;
                acc.color = FlxColor.WHITE;
            }
        }
        
    }

    override function onEventTrigger(eventName:String, val1:String, val2:String) 
    {
        switch (eventName) {
            case 'Obituary':
                switch (val1) {
                    case 'flashinghud':
                        isFlashing = true;
                }


        }
    }

    override function onUpdateScore() 
    {
        cmboNum.text = '$songMisses';
        scoreNum.text = '$songScore';

       // trace(ratingPercent * 100);

        if ((ratingPercent * 100) == 100 && songMisses == 0) accNum.text = 'x';
        else if ((ratingPercent * 100) > 95) accNum.text = 's';
        else if ((ratingPercent * 100) > 90) accNum.text = 'a';
        else if ((ratingPercent * 100) > 80) accNum.text = 'b'
        else if ((ratingPercent * 100) > 70) accNum.text = 'c';
        else if ((ratingPercent * 100) > 60) accNum.text = 'd';
        else if ((ratingPercent * 100) > 50) accNum.text = 'e';
        
        repositionScore();

    }

    function repositionScore() 
    {
        for (i in [cmboNum,scoreNum]) i.updateHitbox();

        cmboBreaks.x = (FlxG.width - (cmboBreaks.width + cmboNum.width +spacing))/2;
        cmboNum.x = cmboBreaks.x + cmboBreaks.width;

        score.x = cmboBreaks.x - score.width - spacing - scoreNum.width;
        scoreNum.x = score.x + score.width;

        acc.x = cmboBreaks.x + cmboBreaks.width + spacing + cmboNum.width;
        accNum.x = acc.x + acc.width;

    }
    
}