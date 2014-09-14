package com.zeitguys.app {
	import com.zeitguys.app.model.AppConfigModel;
	import com.zeitguys.app.model.ILocalizable;
	import com.zeitguys.app.model.IScreenList;
	import com.zeitguys.app.model.Localizer;
	import com.zeitguys.app.model.ScreenRouter;
	import com.zeitguys.app.view.ModalFactory;
	import com.zeitguys.app.view.ModalView;
	import com.zeitguys.app.view.ScreenView;
	import com.zeitguys.app.view.ViewBase;
	import com.zeitguys.app.view.transition.TransitionBase;
	import com.zeitguys.app.view.transition.TransitionManagerBase;
	import com.zeitguys.util.ClipUtils;
	import com.zeitguys.util.ObjectUtils;
	
	import flash.desktop.NativeApplication;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Stage;
	import flash.display.StageAlign;
	import flash.display.StageQuality;
	import flash.display.StageScaleMode;
	import flash.errors.IllegalOperationError;
	import flash.events.Event;
	import flash.events.StageOrientationEvent;
	import flash.geom.Rectangle;
	import flash.system.Capabilities;
	import flash.text.StyleSheet;
	import flash.utils.getQualifiedClassName;
	
	/**
	 * ...
	 * @author TomAuger
	 */
	public class AppBase extends MovieClip {
		public static const EVENT_MODAL_DIALOG_CLOSED:String = 'event-modal-closed';
		
		public static const ORIENTATION_LANDSCAPE:String = "landscape";
		public static const ORIENTATION_PORTRAIT:String = "portrait";
		
		public static const APP_STATE_INITIALIZING:String = "initializing";
		public static const APP_STATE_READY:String = "ready";
		public static const APP_STATE_ACTIVE:String = "active";
		public static const APP_STATE_DEACTIVATED:String = "deactivated";
		public static const APP_STATE_SUSPENDING:String = "suspending";
		public static const APP_STATE_PAUSED:String = "paused";
		
		protected var _defaultOrientation:String;
		
		protected var _screenList:IScreenList; // Set this within child class constructor
		protected var _currentScreen:ScreenView;
		protected var _nextScreen:String;
		protected var _CurrentTransition:Class = TransitionBase;
		
		protected var _screenRouter:ScreenRouter;
		
		protected var _modalFactory:ModalFactory;
		protected var _currentModal:ModalView;
		protected var _lastModalButtonSelected:String;
		
		protected var _appConfig:AppConfigModel;
		protected var _appConfigFileURL:String;
		
		protected var _theme:Object;
		
		protected var _resumeAppDelayFrames:uint = 0;
		protected var _sleepFrames:uint = 0;
		
		private var _deviceSize:Rectangle;
		private var _osVersion:uint;
		private var _appState:String;
		
		private var _transitionManager:TransitionManagerBase;
		
		
		
		protected var _supportsAutoOrients:Boolean = true;
		
		protected var localizer:Localizer;
		
		public function AppBase() {
			super();
			
			stopAllMovieClips();
			
			_screenRouter = ScreenRouter.getInstance();
			_screenRouter.app = this;
			
			addEventListener(Event.ADDED_TO_STAGE, onAddedToStage, false, 0, true);
		}
		
		/**
		 * App base classes that inherit from AppBase can override this to hook into the initialization and do other
		 * things that should be done after the app has been added to the stage, but before the app is ready.
		 * 
		 * Endpoint child classes should avoid touching this altogether and use {@link /initialize()} instead.
		 */
		protected function init():void {
			ViewBase.setApp(this);
		}
		
		
		/**
		 * The endpoint child app should override this to do startup activities such as set the Localizer, load the ScreenList, define the transitionManager and set the first Screen.
		 * 
		 * There should be no need to call super.initialize() in the child app.
		 */
		protected function initialize():void {
			trace("Abstract method initialize() should be over-ridden in child App classes.");
			
			//localizer = new Localizer()
			//screenList = IScreenList
			//firstScreen = "screen__id"
		}
		
		/**
		 * Maybe override in child classes.
		 * 
		 * The app is being activated, usually from focus change / sleep. Use this method to do some things before the currentScreen is activated.
		 */
		protected function activateApp():void {
			
		}
		
		/**
		 * Maybe override in child classes.
		 * 
		 * The app is being deactivated, usually from focus change / sleep. Use this method to do some things after the currentScreen has been deactivated.
		 */
		protected function deactivateApp():void {
			
		}
		
		
		
		
		
		
		//-----------------------------------------------------------------------------------------------------
		
		
		/**
		 * Handles all pre-initialization of app. Calls {@link /appReady()} after config file has loaded.
		 * @param	event
		 */
		protected function onAddedToStage(event:Event):void {
			removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
			
			stage.quality = StageQuality.BEST;
			
			if (_supportsAutoOrients) {
				stage.align = StageAlign.TOP_LEFT;
				stage.scaleMode = StageScaleMode.NO_SCALE;
			}
			
			_osVersion = getDeviceOSVersion();
			trace("OS: '" + deviceOS + "' Version: " + _osVersion + " detected");
			
			_deviceSize = getDevicePixelDimensions(_defaultOrientation);
			trace("Screen Size detected at: " + _deviceSize);
			
			trace("Content offset: " + contentOffset);
			
			init();
			
			if (!_appConfig) {
				_appConfig = new AppConfigModel(_appConfigFileURL);
			}
			_appConfig.addEventListener(AppConfigModel.EVENT_CONFIG_LOADED, appReady);
			_appConfig.load();
		}
		
		public function set defaultOrientation(orientation:String):void {
			if ([ORIENTATION_LANDSCAPE, ORIENTATION_PORTRAIT].indexOf(orientation) > -1){
				_defaultOrientation = orientation;
			} else {
				throw new ArgumentError("Invalid orientation: " + orientation);
			}
		}
		
		/**
		 * Gets the dimensions of the device in pixels. Can only be called after ADDED_TO_STAGE.
		 * 
		 * @param	orientation Optional. Pass in ORIENTATION_LANDSCAPE to flip the width and height values for readability
		 * @param	OSAdjustment Optional. Whether to allow the height to be adjusted in iOS6 to remove status bar from the top
		 * @return
		 */
		public function getDevicePixelDimensions(orientation:String = ORIENTATION_PORTRAIT, OSAdjustment:Boolean = true):Rectangle {
			var dimensions:Rectangle;
			
			if (stage){
				if (ORIENTATION_LANDSCAPE == orientation){
					dimensions = new Rectangle(0, 0,
						Math.max(stage.fullScreenWidth, stage.fullScreenHeight),
						Math.min(stage.fullScreenWidth, stage.fullScreenHeight)
					)
				} else {
					dimensions = new Rectangle(0, 0,
						Math.min(stage.fullScreenWidth, stage.fullScreenHeight),
						Math.max(stage.fullScreenWidth, stage.fullScreenHeight)
					);
				}
				
				return dimensions;
			} else {
				throw new ReferenceError("Can't get dimensions until app has been added to stage. Wait until app initialized before calling this function.");
			}
		}
		
		
		public function getDeviceOSVersion():uint {
			var versionMatches:Array = Capabilities.os.match(/(\d)(\.\d)*/);
			if (versionMatches) {
				var osVersion:Number = parseFloat(versionMatches[0]);
				if (isNaN(osVersion)) {
					return 7;
				} else {
					return osVersion;
				}
			}
			return 6;
		}
		
		/**
		 * Override in OS-specific classes
		 * @return
		 */
		public function get deviceOS():String {
			var matches:Array = Capabilities.os.match(/^(.+?)\s*\d/i);
			if (matches && matches.length > 1) {
				return matches[1];
			} else {
				return "Unknown OS";
			}
		}
		
		/**
		 * @return the adjustment in pixels that the content (or TransitionManager) should be adjusted to accommodate the status bar.
		 */
		public function get contentOffset():int {
			return 0;
		}
		
		
		/**
		 * Child apps should use this method to set the URL of their config XML file, if one is needed.
		 */
		protected function set appConfigURL(appConfigFileURL:String):void {
			_appConfigFileURL = appConfigFileURL;
		}
		
		
		/**
		 * the height of the status bar. Probably override in OS-specific subclasses.
		 */
		public function get statusBarHeight():uint {
			return 0;
		}
		
		public function get osVersion():uint {
			if (_osVersion && ! isNaN(_osVersion)) {
				return _osVersion;
			} else {
				throw new IllegalOperationError("Too early to request OS Version. Wait until after init().");
			}
			
			return 0;
		}
		
		public function get appSize():Rectangle {
			return _deviceSize;
		}
		
		public function get appWidth():Number {
			return _deviceSize.width;
		}
		
		public function get appHeight():Number {
			return _deviceSize.height;
		}
		
		
		/**
		 * The app has been added to the stage and the config file is loaded. The app is ready to start loading screens and logic.
		 * 
		 * @param	event
		 */
		protected function appReady(event:Event):void {
			appState = APP_STATE_READY;
			
			initAppStateHandling();
			
			trace("App Initializing\n------------------------------------------------");
			
			initialize();
		}
		
		/**
		 * Sets up all the event listeners our app will need to behave responsibly within the iOS ecosystem...
		 */
		protected function initAppStateHandling():void {
			// Handle Tombstoneing
			NativeApplication.nativeApplication.addEventListener( Event.ACTIVATE, beginResumeApp );
			NativeApplication.nativeApplication.addEventListener( Event.DEACTIVATE, pauseApp );
			
			// Deal with orientation change
			//stage.addEventListener( StageOrientationEvent.ORIENTATION_CHANGING, onOrientationChanging );
		}
		
		/**
		 * This function initializes the resume delay timer if one is needed.
		 */
		protected function beginResumeApp( event:Event ):void {
			if (appState == APP_STATE_DEACTIVATED || appState == APP_STATE_PAUSED || appState == APP_STATE_SUSPENDING){
				trace( "BEGINNING RESUME APP." );
				// Make sure we stop our sleep counter
				removeEventListener( Event.ENTER_FRAME, appSleeping );
				
				resetResumeDelayFrames();
				if (_resumeAppDelayFrames){
					addEventListener( Event.ENTER_FRAME, resumeDelay );
				} else {
					resumeApp();
				}
			} else {
				trace( "FALSE resume app sent - are you Debugging in simulator? Ignoring." );
			}
		}
		
		protected function resetResumeDelayFrames():void {
			_resumeAppDelayFrames = 0;
		}
		
		/**
		 * The delay timer that ticks through frames. This function launches the resumeApp() event.
		 */
		protected function resumeDelay( event:Event ):void {
			trace( "RESUMING... " + _resumeAppDelayFrames + " left." );
			if ( --_resumeAppDelayFrames ) return;
			
			removeEventListener( Event.ENTER_FRAME, resumeDelay );
			resumeApp();
		}
		
		protected function resumeApp():void {
			trace( "RESUMING APP! Sleep timer at " + _sleepFrames );
			
			activateApp();
			
			if (_currentScreen) {
				_currentScreen.resume();
			}
			appState = APP_STATE_ACTIVE;
		}
		
		/**
		 * Tombstone the application.
		 * 
		 * Call this in response to Event.DEACTIVATE, or call directly using
		 * pauseApp( null ) if you want to explicitly tombstone the app (eg: before saving state)
		 */
		protected function pauseApp( event:Event ):void {
			if (_currentScreen) {
				_currentScreen.pause();
			}
			
			deactivateApp();
			appState = APP_STATE_DEACTIVATED;
			
			// Reset sleepFrames to our desired elapsed frame limit
			resetSleepFrames();
			
			// The app keeps running at a slow frame rate when Bricked.
			// We can have the app do something during this time. We can also have it do it only once
			// after SLEEP_FRAMES frames have passed.
			if (_sleepFrames) {
				appState = APP_STATE_SUSPENDING;
				
				// App will run at 4fps for a brief period of time (to allow background tasks to complete).
				NativeApplication.nativeApplication.executeInBackground = true;
				
				addEventListener( Event.ENTER_FRAME, appSleeping, false, 0, true );
			} 
			
			// If we set SLEEP_FRAMES to 0, then the timer is disabled and the app gets bricked right away.
			else {
				brickApp();
			}
		}
		
		protected function resetSleepFrames():void {
			_sleepFrames = 0;
		}
		
		/**
		 * Called on ENTER_FRAME to run a specific amount of frames and then brick the app.
		 * 
		 * Must have NativeApplication.nativeApplication.executeInBackground = true in order to actually fire.
		 * 
		 * @see brickApp()
		 */
		protected function appSleeping( event:Event ):void {
			trace( "APP SLEEPING: " + _sleepFrames + " frames to go!" );
			
			// We've hit 0
			if ( ! --_sleepFrames ){
				removeEventListener( Event.ENTER_FRAME, appSleeping );
				
				brickApp();
				
				NativeApplication.nativeApplication.executeInBackground = false;
			}
		}
		
		protected function brickApp():void {
			appState = APP_STATE_PAUSED;
		}
		
		private function set appState(state:String):void {
			if ( APP_STATE_ACTIVE == state ) {
				trace( " " );
			}
			
			trace( "APP STATE: " + state );
			_appState = state;
			
			if ( APP_STATE_DEACTIVATED == state ) {
				trace( " " );
			}
		}
		
		private function get appState():String {
			return _appState;
		}
		
		//--------------------------------------------------------------------------------------------------------
		// MODAL DIALOG BOXES
		// -------------------------------------------------------------------------------------------------------
		
		public function set modalFactory(Factory:Class):void {
			if (ObjectUtils.inheritsFrom(Factory, ModalFactory)) {
				_modalFactory = new Factory(this);
			} else {
				throw new ArgumentError("The class '" + getQualifiedClassName(Factory) + "' must extend ModalFactory.");
			}
		}
		
		public function getModal(modalText:String, ... modalArgs):ModalView {
			return _modalFactory.getModal(modalText, modalArgs);
		}
		
		/**
		 * Creates a modal dialog box. Will clear any existing modals that might already be on screen.
		 * 
		 * Call this from your ScreenView any time after `init()`, but not during `activate()` as that will
		 * just create an endless loop, since closing the modal will re-trigger `activate()`.
		 * 
		 * You can register an event listener against the App's EVENT_MODAL_DIALOG_CLOSED and then query `selectedModalButton`
		 * to figure out which button was pressed. Or you can register callbacks for each or any button using the `modalArgs`.
		 * 
		 * @param	modalText Text to display within the body of the modal. Will no be localized, so you must localize it before passing it to the modal.
		 * @param	... modalArgs
		 */
		public function setModal(modalText:String, ... modalArgs):void {
			currentModal = _modalFactory.getModal(modalText, modalArgs);
		}
		
		/**
		 * Screens can theoretically close the modal manually, bypassing the event dispatch altogether.
		 */
		public function clearModal():void {
			_currentModal.close();
		}
		
		public function set currentModal(modal:ModalView):void {
			if (_currentModal) {
				clearModal();
			}
			_currentScreen.enterModal();
			
			_lastModalButtonSelected = null;
			_currentModal = modal;
			_currentModal.addEventListener(ModalView.EVENT_CLOSE, onCurrentModalClosed, false, 0, true);
			_currentModal.open();
		}
		
		protected function onCurrentModalClosed(event:Event):void {			
			_currentModal.removeEventListener(ModalView.EVENT_CLOSE, onCurrentModalClosed, false);
			_lastModalButtonSelected = _currentModal.pressedButton;
			_currentModal = null;
			
			_currentScreen.exitModal();

			dispatchEvent(new Event(EVENT_MODAL_DIALOG_CLOSED));
		}
		
		public function get isModal():Boolean {
			return Boolean(_currentModal);
		}
		
		public function get selectedModalButton():String {
			return _lastModalButtonSelected;
		}
		
		// ==============================================================================================
		//                  Screens and Transitions
		// ==============================================================================================
		
		/**
		 * Sets and processes the screen list. No getter.
		 * Be sure to only call this AFTER the ScreenController has been instantiated, and after the app has been added to the stage.
		 * 
		 * We also set the transitionManager here, because processing the ScreenList may strip children out of the main SWF,
		 * and TransitionManager is a child of the main SWF.
		 */
		public function set screenList(list:IScreenList):void {
			_screenList = list;
			_screenRouter.processScreenList(_screenList);
			
			transitionManager = new TransitionManagerBase(getDevicePixelDimensions());
		}
		
		/**
		 * Used by the App to set the first (usually "loading") screen.
		 * Also sets up the event listener, which is really important if you want to be able to do something visually
		 * when the model changes screens.
		 */
		public function set firstScreen(screenID:String):void {
			_screenRouter.addEventListener(ScreenRouter.EVENT_SCREEN_CHANGED, onScreenChange, false, 0, true);
			_screenRouter.setScreen(screenID, false);
		}
		
		public function get router():ScreenRouter {
			return _screenRouter;
		}
		
		/**
		 * Sets the transitionManager, and adds it to the stage. Removes any previous transition manager.
		 */
		protected function set transitionManager(transitionManager:TransitionManagerBase):void {
			if (_transitionManager && _transitionManager.parent) {
				removeChild(_transitionManager);
			}
			
			_transitionManager = transitionManager;
			_transitionManager.y += contentOffset;
			
			addChild(_transitionManager);
		}
		
		protected function get transitionManager():TransitionManagerBase {
			return _transitionManager;
		}
		
		public function get CurrentTransition():Class {
			return _CurrentTransition;
		}
		
		public function set CurrentTransition(TransitionClass:Class):void {
			trace ("<--> Setting App TRANSITION to " + TransitionClass);
			_CurrentTransition = TransitionClass;
		}
		
		/**
		 * Triggered by ScreenRouter.EVENT_SCREEN_CHANGED.
		 * 
		 * @param	event
		 */
		private function onScreenChange(event:Event):void {
			_transitionManager.addEventListener(TransitionManagerBase.EVENT_TRANSITION_COMPLETE, onTransitionComplete);
			_transitionManager.transition(_screenRouter.currentScreen, CurrentTransition);
		}
		
		private function onTransitionComplete(event:Event):void {
			_transitionManager.removeEventListener(TransitionManagerBase.EVENT_TRANSITION_COMPLETE, onTransitionComplete);
			
			
			// Reset the current transition back to default
			trace("<--> RESET transition");
			CurrentTransition = TransitionBase;
			
			screenTransitionComplete(_screenRouter.currentScreen);
		}
		
		/**
		 * Child app can hook into this for additional processing once screen transition is done.
		 * 
		 * Default functionality:
			 * Always run the `setup()` method.
			 * If a screen reset is requested, run the `reset()` method on the screen.
			 * Finally, `activate()` the screen.
		 * 
		 * @param	currentScreen
		 */
		protected function screenTransitionComplete(currentScreen:ScreenView):void {
			_currentScreen = currentScreen;
			_currentScreen.onTransitionComplete();
			_currentScreen.activate();
		}
		
		
		// ========================================================================================================
		// LOCALIZATION
		// --------------------------------------------------------------------------------------------------------
		
		
		
		/**
		 * Localize something. Typically this would be an asset or a string of some sort.
		 * 
		 * @see Localizer.localize();
		 * 
		 * Safe to call this even if our app isn't localizable, since it will check first to see whether we have
		 * a Localizer defined. If there is, then lovely, go ahead and localize whatever it is you're trying to localize.
		 * 
		 * If the Localizer is defined but the locale is not yet loaded, it will enqueue all requests and then dequeue them
		 * once the XML file is loaded.
		 * 
		 * @param	target The thing we will be localizing. Usually a MovieClip, but could be anything, depending on how the Localizer is configured.
		 */
		public function localize(target:ILocalizable):void {
			if (localizer) {
				//var success:Boolean = target.localize(localizer);
				localizer.localize(target);
			}
		}
		
		public function changeLanguage(language:String, nextScreen:String = ''):void {
			_nextScreen = nextScreen;
			localizer.addEventListener(Localizer.EVENT_LANGUAGE_CHANGED, onLanguageChanged);
			localizer.language = language;
		}
		
		protected function onLanguageChanged(e:Event):void {
			localizer.removeEventListener(Localizer.EVENT_LANGUAGE_CHANGED, onLanguageChanged);
			router.setScreen(_nextScreen);
		}
		
		/**
		 * Access the current language of the localizer.
		 */
		public function get currentLanguage():String {
			if (localizer) {
				return localizer.language;
			}
			
			return "";
		}
		
		/**
		 * Change the current language of the app.
		 */
		public function set currentLanguage(language:String):void {
			localizer.language = language;
		}
		
		
		// Config
		
		
		
		public function get theme():Object {
			return _appConfig.theme;
		}
		
		
		public function get styleSheet():StyleSheet {
			return _appConfig.styleSheet;
		}
		
		
		// ClipUtils
		
		
		
		/**
		 * Dig through the display hierarchy of the clip to find a child DisplayObject with the requested instance name.
		 * 
		 * @throws FlashConstructionError if no matching asset is found.
		 * 
		 * @param	clipName
		 * @param	parentClip Required. The search takes too long if we let the scope be the entire app, so you must provide a parent clip (usually Screen)
		 * @return
		 */
		public function getRequiredChildByName(clipName:String, parentClip:DisplayObjectContainer, asClass:Class):DisplayObject {
			parentClip ||= this;
			
			return ClipUtils.getRequiredChildByName(clipName, parentClip, asClass);
		}
		
		
		
		/**
		 * Recursively dig through the provided parent DisplayObjectContainer to find a clip with the spcified instance name.
		 * 
		 * This method throws no error and only returns `null` if no matching clip found. If you want automatic error and type-checking,
		 * use {@link /getRequiredChildByName()} instead.
		 * 
		 * @param	clipName
		 * @param	parent
		 * @param	maxDepth Used to limit recursion. Will not dig deeper than that many levels.
		 * @return
		 */
		public function getDescendantByName(clipName:String, parent:DisplayObjectContainer = null, maxDepth:uint = 12):DisplayObject {
			parent ||= this;
			
			return ClipUtils.getDescendantByName(clipName, parent, maxDepth);
		}
	}

}