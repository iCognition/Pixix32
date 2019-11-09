package
{
	import com.icognition.genie.classes.NewsFlashFetcher;
	import com.icognition.genie.configurations.PixixConfig;
	import com.icognition.genie.mvc.view.PixixApplication;
	import com.icognition.genie.mvc.view.scenes.GenieStaticPreloader;
	import com.icognition.genie.workers.GenieWorker;
	import com.myflashlabs.utils.worker.WorkerManager;
	
	import flash.desktop.NativeApplication;
	import flash.display.StageAlign;
	import flash.display.StageDisplayState;
	import flash.display.StageScaleMode;
	import flash.display3D.Context3DProfile;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.filesystem.File;
	import flash.geom.Rectangle;
	import flash.system.Capabilities;
	import flash.system.WorkerState;
	import flash.ui.Keyboard;
	
	import configurations.Config;
	
	import lib.LoaderSystem;
	
	import mvc.view.BaseSprite;
	
	import starling.core.Starling;
	import starling.display.DisplayObject;
	import starling.events.Event;
	
	import utils.MyResource;
	
	[SWF(frameRate = "60", backgroundColor = 0xd3d3d3)]
	
	public class Pixix extends BaseSprite
	{
		private var mainApp:PixixApplication;
		private var preloader:GenieStaticPreloader;
		
		/**WORKERS**/
		/*private var worker:Worker;
		private var workerToMain:MessageChannel;
		private var mainToWorker:MessageChannel;
		private var mainToWorkerImageBytes:MessageChannel;
		private var mainToWorkerAudioBytes:MessageChannel;
		private var conditionMutex:Mutex;
		private var condition:Condition;
		private var workerThread:WorkerThread;*/
		
		private var _myWorker:WorkerManager;
		private var locationArray:Array;
		private var newsFlash:NewsFlashFetcher;
		
		public function Pixix()
		{
			super();
		}
		
		override protected function init(e:flash.events.Event):void
		{
			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.displayState = StageDisplayState.FULL_SCREEN_INTERACTIVE;
			
			stage.addEventListener(flash.events.Event.RESIZE, onStageResize);
			
			this.removeEventListener(flash.events.Event.ADDED_TO_STAGE, init);
			
			iOS = Capabilities.manufacturer.indexOf("iOS") != -1;
			
			var sys:String =  Capabilities.manufacturer.toLowerCase();
			
			if(sys.indexOf("windows")>=0)
			{
				Config.system = "windows";
			}
			else if(sys.indexOf("mac")>=0)
			{
				Config.system = "ios";
			}
			else if(sys.indexOf("linux")>=0)
			{
				Config.system = "linux";
			}
			else
			{
				Config.system = "android";
			}
			
			sw = Config.STAGE_WIDTH = 1080;//screenSetup.stageWidth;
			sh = Config.STAGE_HEIGHT = 1920;//screenSetup.stageHeight;
			
			Config.appBounds = new Rectangle(0,0,stage.fullScreenWidth, stage.fullScreenHeight);
			Config.baseRectangle = new Rectangle(0,0,Config.STAGE_WIDTH, Config.STAGE_HEIGHT);
			Config.FPS = this.stage.frameRate;
			
			scaleFactor = stage.fullScreenWidth/Config.baseRectangle.width;
			Config.scaleId = scaleId = Config.calculateScaleId(scaleFactor);//screenSetup.assetScale;//screenSetup.scale;//Config.calculateScaleId(scaleFactor);
			
			Starling.multitouchEnabled = true; // useful on mobile devices
			
			//updateViewport(stage.fullScreenWidth, stage.fullScreenHeight);
			createSplash();
			
			// init the Manager and pass the class you want to use as your Worker
			_myWorker = new WorkerManager(GenieWorker, loaderInfo.bytes, this);
			//_myWorker.addEventListener(
			
			// listen to your worker state changes
			_myWorker.addEventListener(flash.events.Event.WORKER_STATE, onWorkerState);
			
			// fire up the Worker
			_myWorker.start();
			
		}
		
		protected function onStageResize(event:flash.events.Event):void
		{
			trace("ON STAGE RESIZE!");
			trace("dimension of stage target: " + event.target.width, event.target.height);
		}
		
		protected function onWorkerState(event:flash.events.Event):void
		{
			//DebugLog.log("worker state = " + _myWorker.state)
			
			// if the worker state is 'running', you can start communicating
			if (_myWorker.state == WorkerState.RUNNING)
			{
				initialize();
				//throw new Error();
				// create your own commands in your worker class, Worker1, i.e "forLoop" in this sample and pass in as many parameters as you wish
				//_myWorker.command("forLoop", onProgress, onResult, 10000);
			}
		}
		
		
		private function onProgress($progress:Number):void
		{
			//DebugLog.log("progress: " + $progress);
		}
		
		private function onResult($result:Number):void
		{
			//DebugLog.log("$result: " + $result);
			
			// terminate the worker when you're done with it.
			_myWorker.terminate();
		}
		
		override protected function initialize():void
		{
			super.initialize();
			
			//start loading here
			loaderSystem = new LoaderSystem(MyResource.getInstance().assetManager);
			
			/**UNCOMMENT IF THERE ARE ASSETS IN THE ASSETS FOLDER**/
			
			//loaderSystem.addQue("assets/audio");
			loaderSystem.addQue("assets/textures/");
			//loaderSystem.addQue("assets/fonts");
			loaderSystem.addQue("assets/data");
			//loaderSystem.addQue("assets/bitmapfonts");
			loaderSystem.addQue("assets/audio");
			
			var storage:File = File.applicationStorageDirectory;
			assetManager.enqueue( storage.resolvePath(PixixConfig.DEFAULT_DIRECTORY+"/jot_textures/") );
			
			
			//call starling to start, pass your main class for starling
			startStarling(PixixApplication, false);
			
		}
		override protected function startStarling(appClass:Class, isDebug:Boolean = true):void
		{
			//Starling.multitouchEnabled = true;
			starlingClass = appClass;
			
			//screenSetup = new ScreenSetup(stage.fullScreenWidth, stage.fullScreenHeight);
			//viewPort = screenSetup.viewPort;
			
			myStarling = new Starling(starlingClass, stage, viewPort, null, "auto", Context3DProfile.BASELINE_EXTENDED);
			myStarling.viewPort = viewPort;
			myStarling.stage.stageWidth = Config.STAGE_WIDTH;
			myStarling.stage.stageHeight = Config.STAGE_HEIGHT;
			myStarling.simulateMultitouch = true;
			
			//FocusManager.setEnabledForStage(Starling.current.stage, false);
			//var denFac:ScreenDensityScaleFactorManager = new ScreenDensityScaleFactorManager(myStarling);
			
			if(isDebug)
			{
				
				myStarling.enableErrorChecking = isDebug;
				myStarling.showStats = isDebug;
				myStarling.showStatsAt("left", "bottom", 3);
			}
			
			myStarling.addEventListener(starling.events.Event.ROOT_CREATED,
				
				function(event:Object, myApp:DisplayObject):void
				{
					app = myApp as starlingClass;
					updateViewport(stage.fullScreenWidth, stage.fullScreenHeight);
					
					trace("CONFIG SCALE ["+Config.scaleId+"] SCALEFACTOR ["+Starling.contentScaleFactor+"] FS["+stage.fullScreenWidth+"]["+stage.fullScreenHeight+"] STARLING["+Starling.current.stage.stageWidth+"]["+Starling.current.stage.stageHeight+"] FS/STARLING["+stage.fullScreenWidth/Starling.current.stage.stageWidth+"]["+stage.fullScreenHeight/Starling.current.stage.stageHeight+"]");
					app.startPreloader(loaderSystem, startApp);
					
					removeSplash();
					
					
					//insert news flash system here
					/*newsFlash = new NewsFlashFetcher();
					newsFlash.addEventListener(NewsFlashFetcher.NEWS_RESULT_FAIL, onNewsFail);
					newsFlash.addEventListener(NewsFlashFetcher.NEWS_RESULT_SUCCESS, onNewsSuccess);
					newsFlash.fetchNews();*/
					
					//throw new Error();
					
				}
			);
			myStarling.start();
		}
		protected function onNewsSuccess(event:flash.events.Event):void
		{
			//trace("onNewsSuccess");
			//preloader.updateMessage(newsFlash.payload);
			startAssetManagerLoad();
		}
		
		protected function onNewsFail(event:flash.events.Event):void
		{
			//trace("onNewsFail");
			//startAssetManagerLoad();
		}
		override protected function createSplash():void
		{
			preloader = new GenieStaticPreloader();
			this.addChild(preloader);
		}
		
		override protected function removeSplash():void
		{
			preloader.destroy();
			if(preloader!=null)
			{
				if(preloader.parent!=null)
				{
					preloader.parent.removeChild(preloader);
				}
				preloader = null;
			}
			//trace("should remove splash");
		}
		override protected function readLoadRatio(e:Number):void
		{
			if(preloader)
			{
				preloader.update(e);
				
				if(e>=1)
				{
					
				}
			}
		}
		override protected function startApp():void
		{
			//initGesTouch();
			trace("start app");
			initNativeEvent();
			mainApp = app as PixixApplication;
			mainApp.workerManager = _myWorker;
			
			mainApp.commandSignal.add(
				function(e:String = ""):void
				{
					//removeSplash();
				}
			);
			mainApp.start();
		}
		
		private function initGesTouch():void
		{
			/*if (myStarling)
			{
			//				Gestouch.inputAdapter = new NativeInputAdapter(stage);
			//				Gestouch.addDisplayListAdapter(starling.display.DisplayObject, new StarlingDisplayListAdapter());
			//				Gestouch.addTouchHitTester(new StarlingTouchHitTester(myStarling), -1);
			}
			else
			{
			//DebugLog.log"WARNING: STARLING IS NOT INITIALIZED!");
			}*/
		}
		override protected function onAppActivate(event:flash.events.Event):void
		{
			super.onAppActivate(event);
			
			if(mainApp)
			{
				mainApp.onAppAlive();
			}
			
		}
		
		override protected function onAppDeactivate(event:flash.events.Event):void
		{
			super.onAppDeactivate(event);
			
			if(mainApp)
			{
				mainApp.onAppDeactivate();
			}
			
		}
		
		override protected function onAppExit(event:flash.events.Event):void
		{
			if(mainApp)
			{
				mainApp.onAppDie();
			}
		}
		
		override protected function onAppInvoked(event:flash.events.InvokeEvent):void
		{
			if(mainApp)
			{
				mainApp.onAppAlive();
				mainApp.onAppInvoke();
			}
		}
		
		override protected function initNativeEvent():void
		{
			super.initNativeEvent();
			
			trace("added back listeners");
			//if(Config.system == "android")
			//{
			NativeApplication.nativeApplication.addEventListener(KeyboardEvent.KEY_DOWN, onAppBackButton, false, 0, true);
			//}
		}
		
		protected function onAppBackButton(e:KeyboardEvent):void
		{
			if(e.keyCode == Keyboard.BACK)
			{
				trace("keyboard back: mainApp["+mainApp+"]");
				e.preventDefault();
				e.stopImmediatePropagation();
				
				if(mainApp)
				{
					mainApp.backButtonPressed();
				}
				else
				{
					NativeApplication.nativeApplication.exit();
				}
			}
		}
		
		/*protected function onOrientationChange(e:StageOrientationEvent):void
		{
		
		}*/
		
		/*protected function onOrientationChanging(e:StageOrientationEvent):void
		{
		//e.preventDefault();
		
		var isPortraitView:Boolean = 
		(e.afterOrientation == StageOrientation.UPSIDE_DOWN ||   
		e.afterOrientation == StageOrientation.DEFAULT );
		//portraitView.visible = isPortraitView;
		//landscapeView.visible = !isPortraitView;
		}*/
	}
}