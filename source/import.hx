#if !macro
//flixel
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.system.FlxSound;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxTimer;
import flixel.FlxBasic;
import flixel.math.FlxPoint;

#if VIDEOS_ALLOWED
import hxvlc.flixel.*;
import hxvlc.openfl.*;
#end

#if DISCORD_ALLOWED
import meta.backend.Discord;
import meta.backend.Discord.DiscordClient;
#end

import meta.backend.Discord.DiscordHandler;

import meta.data.Paths;
import meta.data.ClientPrefs;
import meta.data.ClientPrefs.data as SaveData;
import meta.backend.ProgressionHandler;
import meta.data.Conductor;
import meta.data.CoolUtil;
import meta.data.Highscore;

import meta.data.CoolUtil.addShaderToCamera as ApplyShaderToCamera;
import meta.data.CoolUtil.removeShaderFromCamera as RemoveShaderFromCamera;
import meta.data.CoolUtil.clearShadersFromCamera as ClearShadersFromCamera;

import meta.data.CoolUtil.betterLerp as lerp;

using StringTools;
using meta.FlxObjectTools;
#end