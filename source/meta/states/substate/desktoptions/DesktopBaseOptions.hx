package meta.states.substate.desktoptions;

import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import lime.utils.Assets;
import flixel.FlxSubState;
import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxSave;
import haxe.Json;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import flixel.input.keyboard.FlxKey;
import flixel.graphics.FlxGraphic;
import meta.data.*;
import meta.states.*;
import meta.states.substate.*;
import gameObjects.*;
import meta.data.options.DesktopOption;

import meta.states.desktop.*;


class DesktopBaseOptions extends MusicBeatSubstate
{
	private var curOption:DesktopOption = null;
	private var curSelected:Int = 0;
	private var optionsArray:Array<DesktopOption>;

	private var grpOptions:FlxTypedGroup<FlxText>;
	private var checkboxGroup:FlxTypedGroup<AttachedFlxText>;
	private var grpTexts:FlxTypedGroup<AttachedFlxText>;

	private var boyfriend:Character = null;
	private var descBox:FlxSprite;
	private var descText:FlxText;

    public var startX:Float;
    public var startY:Float;
    public var selectorArrow:FlxText;

    public var canSelect:Bool = false;

    public function new(startX:Float = 0, startY:Float = 0)
    {
        super();
        this.startX = startX;
        this.startY = startY;

        grpOptions = new FlxTypedGroup<FlxText>();
		add(grpOptions);

		grpTexts = new FlxTypedGroup<AttachedFlxText>();
		add(grpTexts);

		checkboxGroup = new FlxTypedGroup<AttachedFlxText>();
		add(checkboxGroup);

        for (i in 0...optionsArray.length)
            {
                var optionText:FlxText = new FlxText(startX, startY, 646, optionsArray[i].name);
                optionText.setFormat(Paths.font("cmd.ttf"), 16, FlxColor.WHITE, LEFT);
                optionText.setPosition(355.5, 252.15 + (20 * i));
                optionText.ID = i;
                optionText.alpha = 0;
                grpOptions.add(optionText);
    
                if(optionsArray[i].type == 'bool') {
                    var checkbox:AttachedFlxText = new AttachedFlxText(0,0, 'TRUE');
                    checkbox.setFormat(Paths.font("cmd.ttf"), 16, FlxColor.WHITE, LEFT);
                    checkbox.sprTracker = optionText;
                    checkbox.copyAlpha = true;
                    checkbox.ID = i;
                    checkbox.isCheckBox = true;
                    checkbox.setOffsets(300, 0);
                    checkboxGroup.add(checkbox);
                } else if(optionsArray[i].type != 'button' && optionsArray[i].type != 'label') {
                    var valueText:AttachedFlxText = new AttachedFlxText(0,0, '' + optionsArray[i].getValue(),);
                    valueText.setFormat(Paths.font("cmd.ttf"), 16, FlxColor.WHITE, LEFT);
                    valueText.setPosition(optionText.x, optionText.y);
                    valueText.setOffsets(300, 0);
                    valueText.sprTracker = optionText;  
                    valueText.copyAlpha = true;
                    valueText.ID = i;
                    grpTexts.add(valueText);
                    optionsArray[i].setChild(valueText);
                }
                new FlxTimer().start(0.06125 * i, function(t:FlxTimer){
                    optionText.alpha = 1;
                    if(i == optionsArray.length - 1) canSelect = true;
                });
                updateTextFrom(optionsArray[i]);
            }

        selectorArrow = new FlxText(0,0, 636, ">");
        selectorArrow.setFormat(Paths.font("cmd.ttf"), 16, FlxColor.RED, LEFT);
        selectorArrow.setPosition(335.5, grpOptions.members[0].y);
        add(selectorArrow);

        changeSelection();
        reloadCheckboxes();
        cameras = [DesktopOptionsState.instance.display];
    }

    public function addOption(option:DesktopOption) {
		if(optionsArray == null || optionsArray.length < 1) optionsArray = [];
		optionsArray.push(option);
	}

    var nextAccept:Int = 5;
	var holdTime:Float = 0;
	var holdValue:Float = 0;
    override public function update(elapsed:Float)
    {
        if(canSelect){
            if (controls.UI_UP_P)
                {
                    changeSelection(-1);
                }
                if (controls.UI_DOWN_P)
                {
                    changeSelection(1);
                }
        
                if (controls.BACK) {
                    close();
                    //FlxG.sound.play(Paths.sound('cancelMenu'));
                    DesktopOptionsState.instance.returning();
                    ClientPrefs.saveSettings();
                    FlxG.log.add('settings saved');
                }

                if(FlxG.mouse.overlaps(DesktopOptionsState.closeBox) && FlxG.mouse.justPressed)
                {
                    close();
                    FlxTransitionableState.skipNextTransIn = true;
                    FlxTransitionableState.skipNextTransOut = true;
                    DesktopMenuState.fromMenu = true;
                    DesktopMenuState.whichMenu = "song";
                    FlxG.switchState(new DesktopMenuState());
                }
        
                if(nextAccept <= 0)
                    {
                        var usesCheckbox = true;
                        if(curOption.type != 'bool')
                        {
                            usesCheckbox = false;
                        }
            
                        if(usesCheckbox)
                        {
                            if(controls.ACCEPT)
                            {
                                FlxG.sound.play(Paths.sound('keyboard/click${FlxG.random.int(1,3)}'));
                                curOption.setValue((curOption.getValue() == true) ? false : true);
                                curOption.change();
                                reloadCheckboxes();
                            }
                        }else if(curOption.type == 'button'){
                            if(controls.ACCEPT)
                                curOption.callback();
                        } else if(curOption.type != 'label') {
                            if(controls.UI_LEFT || controls.UI_RIGHT) {
                                var pressed = (controls.UI_LEFT_P || controls.UI_RIGHT_P);
                                if(holdTime > 0.5 || pressed) {
                                    if(pressed) {
                                        var add:Dynamic = null;
                                        if(curOption.type != 'string') {
                                            add = controls.UI_LEFT ? -curOption.changeValue : curOption.changeValue;
                                        }
            
                                        switch(curOption.type)
                                        {
                                            case 'int' | 'float' | 'percent':
                                                holdValue = curOption.getValue() + add;
                                                if(holdValue < curOption.minValue) holdValue = curOption.minValue;
                                                else if (holdValue > curOption.maxValue) holdValue = curOption.maxValue;
            
                                                switch(curOption.type)
                                                {
                                                    case 'int':
                                                        holdValue = Math.round(holdValue);
                                                        curOption.setValue(holdValue);
            
                                                    case 'float' | 'percent':
                                                        holdValue = FlxMath.roundDecimal(holdValue, curOption.decimals);
                                                        curOption.setValue(holdValue);
                                                }
            
                                            case 'string':
                                                var num:Int = curOption.curOption; //lol
                                                if(controls.UI_LEFT_P) --num;
                                                else num++;
            
                                                if(num < 0) {
                                                    num = curOption.options.length - 1;
                                                } else if(num >= curOption.options.length) {
                                                    num = 0;
                                                }
            
                                                curOption.curOption = num;
                                                curOption.setValue(curOption.options[num]); //lol
                                                //trace(curOption.options[num]);
                                        }
                                        updateTextFrom(curOption);
                                        curOption.change();
                                        FlxG.sound.play(Paths.sound('keyboard/click${FlxG.random.int(1,3)}'));
                                    } else if(curOption.type != 'string') {
                                        holdValue += curOption.scrollSpeed * elapsed * (controls.UI_LEFT ? -1 : 1);
                                        if(holdValue < curOption.minValue) holdValue = curOption.minValue;
                                        else if (holdValue > curOption.maxValue) holdValue = curOption.maxValue;
            
                                        switch(curOption.type)
                                        {
                                            case 'int':
                                                curOption.setValue(Math.round(holdValue));
            
                                            case 'float' | 'percent':
                                                curOption.setValue(FlxMath.roundDecimal(holdValue, curOption.decimals));
                                        }
                                        updateTextFrom(curOption);
                                        curOption.change();
                                    }
                                }
            
                                if(curOption.type != 'string') {
                                    holdTime += elapsed;
                                }
                            } else if(controls.UI_LEFT_R || controls.UI_RIGHT_R) {
                                clearHold();
                            }
                        }
                        
                    if(controls.RESET)
                    {
                        for (i in 0...optionsArray.length)
                        {
        
                            var leOption:DesktopOption = optionsArray[i];
                            if(leOption.type!='button' && leOption.type != 'label'){
                                leOption.setValue(leOption.defaultValue);
                                if(leOption.type != 'bool')
                                {
                                    if(leOption.type == 'string')
                                    {
                                        leOption.curOption = leOption.options.indexOf(leOption.getValue());
                                    }
                                    updateTextFrom(leOption);
                                }
                                leOption.change();
                            }
                        }
                        FlxG.sound.play(Paths.sound('keyboard/click${FlxG.random.int(1,3)}'));
                        reloadCheckboxes();
                    }    
                }
                if(nextAccept > 0) {
                    nextAccept -= 1;
                }        
        }
		super.update(elapsed);
	}

	function clearHold()
	{
		holdTime = 0;
	}

	function changeSelection(change:Int = 0)
	{
        if (change != 0) FlxG.sound.play(Paths.sound('keyboard/click${FlxG.random.int(1,3)}'));

        curSelected = FlxMath.wrap(curSelected + change,0,optionsArray.length-1);

        selectorArrow.y = grpOptions.members[curSelected].y;

		curOption = optionsArray[curSelected]; //shorter lol
	}

    function reloadCheckboxes() {
		for (checkbox in checkboxGroup) {
			checkbox.daValue = (optionsArray[checkbox.ID].getValue() == true);
		}
	}

    function updateTextFrom(option:DesktopOption) {
		var text:String = option.displayFormat;
		var val:Dynamic = option.getValue();
		if(option.type == 'percent') val *= 100;
		var def:Dynamic = option.defaultValue;
		option.text = text.replace('%v', val).replace('%d', def);
    }
}
