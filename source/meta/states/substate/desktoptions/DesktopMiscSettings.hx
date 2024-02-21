package meta.states.substate.desktoptions;
import meta.states.*;
import meta.states.substate.*;
import meta.data.options.*;

class DesktopMiscSettings extends DesktopBaseOptions
{
	public function new()
	{
		var maxThreads:Int = Std.parseInt(Sys.getEnv("NUMBER_OF_PROCESSORS"));
		if(maxThreads > 1){
			var option:DesktopOption = new DesktopOption('Multi-thread Loading', //Name
				'If checked, the mod can use multiple threads to speed up loading times on some songs.\nRecommended to leave on, unless it causes crashing', //Description
				'multicoreLoading', //Save data variable name
				'bool', //Variable type
				false
			); //Default value
			addOption(option);

			var option:DesktopOption = new DesktopOption('Loading Threads', //Name
				'How many threads the game can use to load graphics when using Multi-thread Loading.\nThe maximum amount of threads depends on your processor', //Description
				'loadingThreads', //Save data variable name
				'int', //Variable type
				Math.floor(maxThreads/2)
			); //Default value

			option.minValue = 1;
			option.maxValue = Std.parseInt(Sys.getEnv("NUMBER_OF_PROCESSORS"));
			option.displayFormat = '%v';

			addOption(option);
		}else{
			// if you guys ever add more options to misc that dont rely on the thread count
			var option:DesktopOption = new DesktopOption("Not enough threads.", //Name
				"Usually there'd be options about multi-thread loading, but you only have 1 thread to use so no real use", //Description
				'', //Save data variable name
				'label', //Variable type
				true
			); //Default value
			addOption(option);
		}

		var option:DesktopOption = new DesktopOption('GPU Caching',
		'If enabled, allows assets to be cached directly to the GPU. helps Performance',
		'cacheOnGPU',
		'bool',
		'false',
		);
		addOption(option);
		/*
		var option:Option = new Option('Persistent Cached Data',
			'If checked, images loaded will stay in memory\nuntil the game is closed, this increases memory usage,\nbut basically makes reloading times instant.',
			'imagesPersist',
			'bool',
			false);
		option.onChange = onChangePersistentData; //Persistent Cached Data changes FlxGraphic.defaultPersist
		addOption(option);
		*/

		super();
	}

}