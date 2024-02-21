package meta.data.scripts;

import flixel.addons.transition.FlxTransitionableState;
import flixel.util.FlxColor;
import flixel.ui.FlxBar;
import flixel.FlxG;
import flixel.system.FlxSound;
import flixel.tweens.*;
import flixel.*;
import hscript.*;
import lime.utils.Assets;
import lime.app.Application;
import meta.data.scripts.Globals.*;
import flixel.addons.display.FlxRuntimeShader;
import openfl.display.BlendMode;
import meta.data.*;
import meta.states.*;
import meta.states.editors.*;
import gameObjects.*;
#if sys
import flash.media.Sound;
import sys.FileSystem;
import sys.io.File;
#end

using StringTools;

class FunkinHScript extends FunkinScript
{
	public static final hscriptExts = ["hx","hxs","hscript"];
	static var parser:Parser = new Parser();
	public static var defaultVars:Map<String,Dynamic> = new Map<String, Dynamic>();


	public static function init() // BRITISH
	{
		parser.allowMetadata = true;
		parser.allowJSON = true;
		parser.allowTypes = true;
	}

	public static function fromString(script:String, ?name:String = "Script", ?additionalVars:Map<String, Any>)
	{
		parser.line = 1;
		var expr:Expr;
		try
		{
			expr = parser.parseString(script, name);
		}
		catch (e:haxe.Exception)
		{
			var errMsg = 'Error parsing hscript! '#if hscriptPos + '$name:' + parser.line + ', ' #end + e.message;
			#if desktop
			Application.current.window.alert(errMsg, "Error on haxe script!");
			#end
			trace(errMsg);

			expr = parser.parseString("", name);
		}
		return new FunkinHScript(expr, name, additionalVars);
	}
	public static function parseString(script:String, ?name:String = "Script")
	{
		return parser.parseString(script, name);
	}

	public static function fromFile(file:String, ?name:String, ?additionalVars:Map<String, Any>)
	{
		if (name == null)
			name = file;
		return fromString(Paths.getContent(file), name, additionalVars);
	}
	
	public static function parseFile(file:String, ?name:String)
	{
		if (name == null)
			name = file;
		return parseString(File.getContent(file), name);
	}

	var interpreter:Interp = new Interp();

	override public function scriptTrace(text:String) {
		var posInfo = interpreter.posInfos();
		haxe.Log.trace(text, posInfo);
	}
	public function new(parsed:Expr, ?name:String = "Script", ?additionalVars:Map<String, Any>)
	{
		scriptType = 'hscript';
		scriptName = name;

		setDefaultVars();
		set("Std", Std);
		set("Type", Type);
		set("Math", Math);
		set("script", this);
		set("StringTools", StringTools);
		set("scriptTrace", function(text:String){
			scriptTrace(text);
		});
		set("newMap", function(){ // maps aren't really a thing during runtime i think
			return new Map<Dynamic, Dynamic>();
		});

		set("ObjectTools", FlxObjectTools);
		set("Assets", Assets);
		set("OpenFlAssets", openfl.utils.Assets);
		set("FlxG", flixel.FlxG);
		set("state", flixel.FlxG.state);
		set("FlxSprite", flixel.FlxSprite);
		set("FlxCamera", flixel.FlxCamera);
		set("FlxMath", flixel.math.FlxMath);
		set("FlxText", flixel.text.FlxText);
		set("FlxTextBorderStyle", flixel.text.FlxText.FlxTextBorderStyle);
		set("FlxSound", FlxSound);
		set("FlxTimer", flixel.util.FlxTimer);
		set("FlxColor", { // same case as maps?
			toRGBArray: function(color:FlxColor){return [color.red, color.green, color.blue];}, 
			setHue: function(color:FlxColor, hue){
				color.hue = hue;
				return color;
			},

			fromCMYK: FlxColor.fromCMYK,
			fromHSL: FlxColor.fromHSL,
			fromHSB: FlxColor.fromHSB,
			fromInt: FlxColor.fromInt,
			fromRGBFloat: FlxColor.fromRGBFloat,
			fromString: FlxColor.fromString,
			fromRGB: FlxColor.fromRGB
		});
		set("FlxTween", FlxTween);
		set("FlxEase", FlxEase);
		set("FlxSave", flixel.util.FlxSave); // should probably give it 1 save instead of giving it FlxSave
		set("FlxBar", flixel.ui.FlxBar);

		set("LEFT_TO_RIGHT", LEFT_TO_RIGHT);
		set("RIGHT_TO_LEFT", RIGHT_TO_LEFT);
		set("TOP_TO_BOTTOM", TOP_TO_BOTTOM);
		set("BOTTOM_TO_TOP", BOTTOM_TO_TOP);
		set("HORIZONTAL_INSIDE_OUT", HORIZONTAL_INSIDE_OUT);
		set("HORIZONTAL_OUTSIDE_IN", HORIZONTAL_OUTSIDE_IN);
		set("VERTICAL_INSIDE_OUT", VERTICAL_INSIDE_OUT);
		set("VERTICAL_OUTSIDE_IN", VERTICAL_OUTSIDE_IN);

		set("FlxAxes", {
			X: flixel.util.FlxAxes.X,
			Y: flixel.util.FlxAxes.Y,
			XY: flixel.util.FlxAxes.XY
		});

		set("Dynamic", Dynamic);

		set("getClass", function(className:String)
		{
			return Type.resolveClass(className);
		});
		set("getEnum", function(enumName:String)
		{
			return Type.resolveEnum(enumName);
		});
		set("importClass", function(className:String)
		{
			// importClass("flixel.util.FlxSort") should give you FlxSort.byValues, etc
			// whereas importClass("scripts.Globals.*") should give you Function_Stop, Function_Continue, etc
			// i would LIKE to do like.. flixel.util.* but idk if I can get everything in a namespace
			var classSplit:Array<String> = className.split(".");
			var daClassName = classSplit[classSplit.length-1]; // last one
			if (daClassName == '*'){
				var daClass = Type.resolveClass(className);
				while(classSplit.length > 0 && daClass==null){
					daClassName = classSplit.pop();
					daClass = Type.resolveClass(classSplit.join("."));
					if(daClass!=null)break;
				}
				if(daClass!=null){
					for(field in Reflect.fields(daClass)){
						set(field, Reflect.field(daClass, field));
					}
				}else{
					FlxG.log.error('Could not import class ${daClass}');
					scriptTrace('Could not import class ${daClass}');
				}
			}else{
				var daClass = Type.resolveClass(className);
				set(daClassName, daClass);	
			}
		});
		set("addHaxeLibrary", function(libName:String, ?libPackage:String = ''){
			try{
				var str:String = '';
				if (libPackage.length > 0)
					str = libPackage + '.';

				set(libName, Type.resolveClass(str + libName));
			}
			catch (e:Dynamic){
				
			}
		}); 

		set("importEnum", function(enumName:String)
		{
			// same as importClass, but for enums
			// and it cant have enum.*;
			var splitted:Array<String> = enumName.split(".");
			var daEnum = Type.resolveClass(enumName);
			if (daEnum!=null)
				set(splitted.pop(), daEnum);
			
		});

		set("importScript", function(){
			// unimplemented lol
			throw new haxe.exceptions.NotImplementedException();
		});

		for(variable => arg in defaultVars){
			set(variable, arg);
		}

		// Util
		set("makeSprite", function(?x:Float, ?y:Float, ?image:String)
		{
			var spr = new FlxSprite(x, y);
			spr.antialiasing = ClientPrefs.data.antialiasing;

			return image == null ? spr : spr.loadGraphic(Paths.image(image));
		});
		set("makeAnimatedSprite", function(?x:Float, ?y:Float, ?image:String, ?spriteType:String){
			var spr = new FlxSprite(x, y);
			spr.antialiasing = ClientPrefs.data.antialiasing;

			if(image != null && image.length > 0){
				/*
				switch(spriteType)
				{
					case "texture" | "textureatlas" | "tex":
						spr.frames = AtlasFrameMaker.construct(image);
					case "texture_noaa" | "textureatlas_noaa" | "tex_noaa":
						spr.frames = AtlasFrameMaker.construct(image, null, true);
					case "packer" | "packeratlas" | "pac":
						spr.frames = Paths.getPackerAtlas(image);
					default:*/
						spr.frames = Paths.getSparrowAtlas(image);
				//}
			}

			return spr;
		});

		set("Main", Main);
		set("Lib", openfl.Lib);

		set("FlxRuntimeShader", FlxRuntimeShader);
		set("newShader", function(fragFile:String = null, vertFile:String = null){ // returns a FlxRuntimeShader but with file names lol
			var runtime:FlxRuntimeShader = null;

			try{				
				runtime = new FlxRuntimeShader(
					fragFile==null ? null : Paths.getContent(Paths.exists(Paths.modsShaderFragment(fragFile)) ? Paths.modsShaderFragment(fragFile) : Paths.shaderFragment(fragFile)), 
					vertFile==null ? null : Paths.getContent(Paths.exists(Paths.modsShaderVertex(vertFile)) ? Paths.modsShaderVertex(vertFile) : Paths.shaderVertex(vertFile))
				);
			}catch(e:Dynamic){
				trace("Shader compilation error:" + e.message);
			}

			return runtime==null ? new FlxRuntimeShader() : runtime;
		});

		// set("Shaders", gameObjects.shader.Shaders);

		@:privateAccess
		{
			var state:Any = flixel.FlxG.state;
			set("state", flixel.FlxG.state);

			if((state is PlayState) && state == PlayState.instance)
			{
				var state:PlayState = PlayState.instance;

				set("game", state);
				set("global", state.variables);
				set("getInstance", getInstance);

			}
			else if ((state is ChartingState) && state == ChartingState.instance){
				var state:ChartingState = ChartingState.instance;
				set("game", state);
				set("global", state.variables);
				set("getInstance", function()
				{
					return flixel.FlxG.state;
				});
			}else{
				set("game", null);
				set("global", null);
				set("getInstance", function(){
					return flixel.FlxG.state;
				});
			}
		}

		// FNF-specific things
		set("Paths", Paths);
		set("AttachedSprite", AttachedSprite);
		set("AttachedText", AttachedText);
		set("Conductor", Conductor);
		set("Note", Note);
		set("Song", Song);
		set("StrumNote", StrumNote);
		set("NoteSplash", NoteSplash);
		set("ClientPrefs", ClientPrefs);
		set("Alphabet", Alphabet);
		set("BGSprite", BGSprite);
		set("CoolUtil", CoolUtil);
		set("Character", Character);
		set("Boyfriend", Boyfriend);
		set("GradientBumpSprite", gameObjects.stageObjects.GradientBump);
		set("FNFSprite", gameObjects.FNFSprite);
		set("SubModifier", modchart.SubModifier);
		set("NoteModifier", modchart.NoteModifier);
		set("EventTimeline", modchart.EventTimeline);
		set("ModManager", modchart.ModManager);
		set("Modifier", modchart.Modifier);
		set("StepCallbackEvent", modchart.events.StepCallbackEvent);
		set("CallbackEvent", modchart.events.CallbackEvent);
		set("ModEvent", modchart.events.ModEvent);
		set("EaseEvent", modchart.events.EaseEvent);
		set("SetEvent", modchart.events.SetEvent);
		
		set("StageData", StageData);
		set("PlayState", PlayState);
		set("FunkinLua", FunkinLua);
		set("FunkinHScript", FunkinHScript);
		set("HScriptSubstate", HScriptSubstate);
		set("GameOverSubstate", meta.states.substate.GameOverSubstate);
		set("HealthIcon", HealthIcon);

		set("PsychVideoSprite", PsychVideoSprite);

		set('setTransInOut',(transIn:Bool,transOut:Bool)->{
			FlxTransitionableState.skipNextTransIn = transIn;
			FlxTransitionableState.skipNextTransOut = transOut;		
		});

		set('addShader',function(shader,?camera){ApplyShaderToCamera(shader,camera);});
		set('removeShader',function(shader,?camera){RemoveShaderFromCamera(shader,camera);});
		set('clearShader',function(?camera){ClearShadersFromCamera(camera);});

		set("ScriptState", HScriptState);
		set("newScriptedState", function(stateName:String){
			return new HScriptState(fromFile(Paths.modFolders('states/$stateName.hscript')));
		});
		
		set("add", PlayState.instance.add);

		set("addObjectBlend", function(shit:Dynamic, shit2:String){
			shit.blend = blendModeFromString(shit2);
		});
		// set("buildStage", PlayState.instance.buildStage);
		
		if (additionalVars != null){
			for (key in additionalVars.keys())
				set(key, additionalVars.get(key));
		}

		trace('Loaded script ${scriptName}');
		try{
			interpreter.execute(parsed);
		}catch(e:haxe.Exception){
			trace('${scriptName}: '+ e.details());
			FlxG.log.error("Error running hscript: " + e.message);
		}
	}
	
	function blendModeFromString(blend:String):BlendMode {
		switch(blend.toLowerCase().trim()) {
			case 'add': return ADD;
			case 'alpha': return ALPHA;
			case 'darken': return DARKEN;
			case 'difference': return DIFFERENCE;
			case 'erase': return ERASE;
			case 'hardlight': return HARDLIGHT;
			case 'invert': return INVERT;
			case 'layer': return LAYER;
			case 'lighten': return LIGHTEN;
			case 'multiply': return MULTIPLY;
			case 'overlay': return OVERLAY;
			case 'screen': return SCREEN;
			case 'shader': return SHADER;
			case 'subtract': return SUBTRACT;
		}
		return NORMAL;
	}
	
	override public function stop(){
		// idk if there's really a stop function or anythin for hscript so
		if (interpreter != null && interpreter.variables != null)
			interpreter.variables.clear();

		interpreter = null;
	}

	override public function get(varName:String): Dynamic
	{
		return interpreter.variables.get(varName);
	}

	override public function set(varName:String, value:Dynamic):Void
	{
		interpreter.variables.set(varName, value);
	}

	public function exists(varName:String)
	{
		return interpreter.variables.exists(varName);
	}
	
	override public function call(func:String, ?parameters:Array<Dynamic>):Dynamic
	{
		var returnValue:Dynamic = executeFunc(func, parameters, this);
		if (returnValue == null)
			return Function_Continue;
		return returnValue;
	}

	public function executeFunc(func:String, ?parameters:Array<Dynamic>, ?theObject:Any, ?extraVars:Map<String,Dynamic>):Dynamic
	{
		if (extraVars == null)
			extraVars=[];
		if (exists(func))
		{
			var daFunc = get(func);
			if (Reflect.isFunction(daFunc))
			{
				var returnVal:Any = null;
				var defaultShit:Map<String,Dynamic>=[];
				if (theObject!=null)
					extraVars.set("this", theObject);
				
				for (key in extraVars.keys()){
					defaultShit.set(key, get(key));
					set(key, extraVars.get(key));
				}
				try
				{
					returnVal = Reflect.callMethod(theObject, daFunc, parameters);
				}
				catch (e:haxe.Exception)
				{
					#if sys
					Sys.println(e.message);
					#end
				}
				for (key in defaultShit.keys())
				{
					set(key, defaultShit.get(key));
				}
				return returnVal;
			}
		}
		return null;
	}
}

class HScriptSubstate extends meta.states.substate.MusicBeatSubstate
{
	public var script:FunkinHScript;

	public function new(ScriptName:String, ?additionalVars:Map<String, Any>)
	{
		super();

		var fileName = 'substates/$ScriptName.hscript';

		for (filePath in [#if MODS_ALLOWED Paths.modFolders(fileName), Paths.mods(fileName), #end Paths.getPreloadPath(fileName)])
		{
			if (!FileSystem.exists(filePath)) continue;

			// some shortcuts
			var variables = new Map<String, Dynamic>();
			variables.set("this", this);
			variables.set("add", add);
			variables.set("remove", remove);
			variables.set("getControls", function(){ return controls;}); // i get it now
			variables.set("close", close);

			if (additionalVars != null){
				for (key in additionalVars.keys())
					variables.set(key, additionalVars.get(key));
			}

			script = FunkinHScript.fromFile(filePath, variables);
			script.scriptName = ScriptName;

			break;
		}

		if (script == null){
			trace('Script file "$ScriptName" not found!');
			return close();
		}

		script.call("onLoad");
	}

	override function update(e)
	{
		if (script.call("onUpdate", [e]) == Globals.Function_Stop)
			return; 
		
		super.update(e);
		script.call("onUpdatePost", [e]);
	}

	override function close(){
		if (script != null)
			script.call("onClose");
		
		return super.close();
	}

	override function destroy()
	{
		if (script != null){
			script.call("onDestroy");
			script.stop();
		}
		script = null;

		return super.destroy();
	}
}