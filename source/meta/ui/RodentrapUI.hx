package meta.ui;

import flixel.ui.FlxBar;
import meta.data.Highscore;

class RodentrapUI extends BaseUI
{

    var healthBarOverlay:FlxSprite;
    var healthBarStitch:FlxSprite; 

    var scoreTxt:FlxText;

    override function createUI() 
    {
        
        healthBarOverlay = new FlxSprite().loadGraphic(Paths.image('hpBar'));
        healthBarOverlay.screenAlignment(ClientPrefs.data.downScroll ? TOPMID : BOTTOMMID);
        healthBarOverlay.y += ClientPrefs.data.downScroll ? -10 : 10;
        healthBarOverlay.flipY = ClientPrefs.data.downScroll;

        createHPbar(healthBarOverlay.x + 33,healthBarOverlay.y + (ClientPrefs.data.downScroll ? 63 : 9), 607, 35);
        healthBar.createFilledBar(FlxColor.fromRGB(71, 63, 75), FlxColor.fromRGB(255, 242, 0));
        healthBar.updateFilledBar();
		healthBar.updateBar();

        healthBarStitch = new FlxSprite().loadGraphic(Paths.image('stitchMiddle'));
        healthBarStitch.y = healthBar.y + 15;


        final scoreY:Float = (ClientPrefs.data.downScroll ? 100 : camHUD.height * 0.91);
        scoreTxt = new FlxText(0, scoreY + 36, FlxG.width, "", 20);
		scoreTxt.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		scoreTxt.borderSize = 1.25;

        healthBarOverlay.alpha = healthBarStitch.alpha = healthBar.alpha = ClientPrefs.data.healthBarAlpha;
        

        onUpdateScore();

    }
    
    override public function sort()
    {
        var dumpExclusions = [current.botplayTxt,current.timeTxt,current.timeBitmapTxt,current.timeBarBG,current.timeBar];
        for (i in uiGroup) if (!dumpExclusions.contains(i)) remove(i);
        
        for (i in [healthBar,healthBarStitch,healthBarOverlay,iconP1,iconP2,scoreTxt]) add(i);


        current.timeBitmapTxt.visible = false;
        current.timeTxt.visible = !current.timeBitmapTxt.visible;
    }

    override function update(elapsed:Float) {

        super.update(elapsed);
        healthBarStitch.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01)) - 7;
        
    }

    override function onUpdateScore() {
        scoreTxt.text = 'Score: ' + songScore + ' | Combo Breaks: ' + songMisses + ' | Accuracy: ' + ratingName;
        if(ratingName != '?')
            scoreTxt.text += ' (' + Highscore.floorDecimal(ratingPercent * 100, 2) + '%)' + ' - ' + ratingFC;	
    }

    
}