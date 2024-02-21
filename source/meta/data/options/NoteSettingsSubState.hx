package meta.data.options;

import flash.text.TextField;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
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
import openfl.Lib;
import meta.data.*;

using StringTools;

class NoteSettingsSubState extends BaseOptionsMenu
{
	public function new()
	{
		title = 'Notes';
		rpcTitle = 'Note Settings Menu'; //for Discord Rich Presence

		var option:Option = new Option('Note Skin', //Name
			'Changes how notes look. Quants change colour depending on the beat it\'s at, while vanilla is normal FNF', //Description
			'noteSkin', //Save data variable name
			'string', //Variable type
			'Vanilla',
			['Vanilla','Quants', 'QuantStep']
		); //Default value
		addOption(option);

		var option:Option = new Option('Customize',
			'Change your note colours\n[Press Enter]',
			'swapNoteOption',
			'button',
			true);
		option.callback = function(){
			switch(ClientPrefs.data.noteSkin){
				case 'Quants':
					openSubState(new QuantNotesSubState());
				case 'QuantStep':
					openSubState(new QuantNotesSubState());
				default:
					openSubState(new NotesSubState());
			}
		}
		addOption(option);

		super();
	}

}
