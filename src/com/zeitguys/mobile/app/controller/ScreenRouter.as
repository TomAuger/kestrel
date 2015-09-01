package com.zeitguys.mobile.app.controller {
	import com.zeitguys.mobile.app.AppBase;
	import com.zeitguys.mobile.app.view.ScreenView;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	/**
	 * Singleton.
	 * 
	 * This is the model for the overall application flow. It should not contain any business logic about specific screens, but just what screen we're on,
	 * what our history is (in case we have "Back button" functionality, and the complete list of all screens in the app.
	 * 
	 * It also does not know anything about __how__ the screens are going to be displayed. It does not have a reference to any DisplayList and doesn't know about the TransitionManager.
	 * 
	 * The App or AppModel (if there is one) should listen for EVENT_SCREEN_CHANGED to know when to do something with `currentScreen` - like add it to the DisplayList,
	 * or, better yet, pass it to the TransitionManager.
	 * 
	 * @see /processScreenList() to understand how the screen model is initially loaded.
	 * 
	 * @author TomAuger
	 */
	public class ScreenRouter extends EventDispatcher {
		public static const EVENT_SCREEN_CHANGED:String = 'screen-changed';
		
		protected var _screenHistory:Vector.<ScreenView> = new Vector.<ScreenView>;
		protected var _screenHistoryIndex:uint = 0;
		protected var _previousScreenHistoryIndex:uint = 0;
		protected var _app:AppBase;
		protected var _currentScreenResetRequested:Boolean = false;
		protected var _screenArgs:Object = {};
		
		protected var _bundlesLoaded:Boolean = false;
		
		protected var _loader:AssetLoader = AssetLoader.getInstance();
		
		private static var __instance:ScreenRouter;
		
		/**
		 * Singleton access to model.
		 * @return The singleton instance.
		 */
		public static function getInstance():ScreenRouter {
			if (! __instance) {
				__instance = new ScreenRouter();
			}
			
			return __instance;
		}
		
		/**
		 * Set the current screen. This is the primary method of ScreenController, and should be the ONLY way that screen changes
		 * are invoked, otherwise the entire screen chain breaks down and you won't get all the benefits of the framework.
		 * 
		 * This method does not need to be called directly. Indeed, often you will use {@link /nextScreenInBundle()} and {@link /previousScreenInBundle}
		 * and similar helper methods to navigate through the screen hierarchy.
		 * 
		 * By default, will advance the history (ie: keep a reference to the previous screen in the history and increase the index) and will trigger EVENT_SCREEN_CHANGED.
		 * 
		 * @param	screen 			String|ScreenView. If String, expects a valid Screen ID.
		 * @param	resetView	
		 * @param	triggerEvent	Whether to trigger EVENT_SCREEN_CHANGED
		 * @param	args			Additional args. If there are any, 
		 */
		public function setScreen(screen:*, resetView:Boolean = true, triggerEvent:Boolean = true, args:Object = null):String {
			var newScreen:ScreenView;
			
			if (screen is ScreenView) {
				newScreen = screen;
			} else if (screen is String) {
				newScreen = getScreenByID(screen);
			} else {
				throw new TypeError("'screen' argument must be a ScreenView object or a ScreenView ID (String).");
			}
			
			if (newScreen) {
				// For uHear, we're not using History. Great idea, but totally un-necessary.
				// See uHearScreenView.onSwipeBack();
				_screenHistoryIndex = 0;
				
				// Deactivate the previous screen
				if (_screenHistory.length > _screenHistoryIndex){
					_screenHistory[_screenHistoryIndex].deactivate();
					// @TODO this is not the right place for this.
					// It should be in AppBase, since that's where we're triggering onTransitionComplete().
					// But at the moment we won't have access to the previous screen from AppBase, since
					// history is not properly implemented.
					_screenHistory[_screenHistoryIndex].onTransitionOut();
				}
				
				// Might want to increment _screenHistoryIndex here if we're using History.
				
				// Stash the screen arguments, or clear them.
				if (args) {
					screenArgs = args;
				} else {
					screenArgs = { };
				}
				
				trace("---------------------------------------------\nSetting SCREEN to: " + newScreen.id);
				_screenHistory[_screenHistoryIndex] = newScreen;
				
				//debugHistory();
				
				
				
				// If a resetView was requested, turn it on.
				// The App or screens can query this to determine whether they want to reset their view / model.
				_currentScreenResetRequested = resetView;
			
				// Run setup() every time, before localize()
				// NOTE: This is DEPRECATED!
				newScreen.setup();
				
				// Set args on the incoming screen, usually passed from the setScreen() method.
				newScreen.screenArgs = screenArgs;
				
				// Run setupBeforeLocalize() every time.
				newScreen.setupBeforeLocalize();
				
				// Register this screen for localization, when the XML is ready.
				_app.localize(newScreen);
				
				// Run setupAfterLocalize() every time.
				newScreen.setupAfterLocalize();
				
				// reset() only when requested (like through ScreenController.setScreen())
				if (resetView) {
					newScreen.reset();
				}
				
				if (triggerEvent) {
					dispatchEvent(new Event(EVENT_SCREEN_CHANGED));
				}
				
				return newScreen.id;
			}
			
			return null;
		}
		
		/**
		 * Advance to the next screen in the ScreenBundle. The default behaviour is to reset the new screen on advance.
		 * 
		 * @param	resetView
		 * @param	triggerEvent
		 * @return
		 */
		public function nextScreenInBundle(resetView:Boolean = true, triggerEvent:Boolean = true, args:Object = null):String {
			if (currentScreen) {
				var nextBundleIndex:uint = currentScreen.bundleIndex + 1;
				var nextScreen:ScreenView = currentScreen.bundle.getScreenByIndex(nextBundleIndex);
				if (nextScreen) {
					// Use setScreen() to actually trigger the screen change event.
					return setScreen(nextScreen, resetView, triggerEvent, args);
				}
			}
			return null;
		}
		
		/**
		 * Rewind to the previous screen in the ScreenBundle. The default behaviour is to not reset the previous screen.
		 * 
		 * @param	resetView
		 * @param	triggerEvent
		 * @return
		 */
		public function previousScreenInBundle(resetView:Boolean = false, triggerEvent:Boolean = true, args:Object = null):String {
			if (currentScreen) {
				var prevBundleIndex:int = currentScreen.bundleIndex - 1;
				if (prevBundleIndex > -1) {
					var prevScreen:ScreenView = currentScreen.bundle.getScreenByIndex(prevBundleIndex);
					if (prevScreen) {
						return setScreen(prevScreen, resetView, triggerEvent, args);
					}
				}
			}
			return null;
		}
		
		/**
		 * Rewind to the first screen in the ScreenBundle. The default behaviour is to reset the previous screen.
		 * 
		 * @param	resetView
		 * @param	triggerEvent
		 * @return
		 */
		public function firstScreenInBundle(resetView:Boolean = true, triggerEvent:Boolean = true, args:Object = null):String {
			if (currentScreen) {
				var firstScreen:ScreenView = currentScreen.bundle.getScreenByIndex(0);
				if (firstScreen) {
					return setScreen(firstScreen, resetView, triggerEvent, args);
				}
			}
			return null;
		}
		
		public function getScreenByID(screenID:String, bundle:ScreenBundle = null):ScreenView {
			// Extract the bundle from the screenID unless bundle provided
			if (! bundle) {
				var idParts:Array = screenID.split("__", 2);
				if (idParts.length == 2){
					bundle = ScreenBundle.getBundleByID(idParts[0]);
				} else {
					bundle = currentScreen.bundle;
				}
			}
			
			if (bundle){
				return bundle.getScreenByID(screenID);
			} else {
				// Often this is just an erroneous router.setScreen() call with a mis-spelled bundle name.
				throw new RangeError("Could not locate a bundle for '" + screenID + "'. Maybe you mis-spelled the bundle part of the screen name?");
			}
			
			return null;
		}
		
		public function get screenArgs():Object {
			return _screenArgs;
		}
		
		public function set screenArgs(args:Object):void {
			_screenArgs = args;
		}
		
		/**
		 * Constructor.
		 */
		public function ScreenRouter() {
		
		}
		
		/**
		 * Process the ScreenList, which defines the Bundles and all the Screens in each Bundle.
		 * This will also enqueue them into the AssetLoader, which may start the loader if it's not already loading something.
		 * 
		 * Note: there can be sequencing issues if you're not careful: the ScreenList already instantiates the ScreenBundles and ScreenViews,
		 * but they're not necessarily even loaded so may not yet have their assets. Look to {@link ScreenView} to see the list of hooks you have access to
		 * throughout the loading and initialization process.
		 * 
		 * @param	screenList
		 */
		public function processScreenList(screenList:IScreenList):void {
			var bundles:Vector.<ScreenBundle> = screenList.getScreenBundles();
			
			// Load the bundles
			for each (var bundle:ScreenBundle in bundles) {
				if (! bundle.loaded) {
					var asset:ScreenBundleLoaderAsset = new ScreenBundleLoaderAsset(bundle.request, bundle, onBundleLoadComplete, onBundleLoadError);
					
					_loader.addItem(asset);
				}
			}
			
			trace( "ScreenList PROCESSING complete");
		}
		
		public function onBundleLoadComplete(bundle:ScreenBundle, success:Boolean):void {
			
		}
		
		public function onBundleLoadError(bundle:ScreenBundle, error:String):void {
			trace("Bundle Load Error: " + error);
		}
		
		public function set app(app:AppBase):void {
			_app = app;
		}
		
		public function get app():AppBase {
			return _app;
		}
		
		public function get loader():AssetLoader {
			return _loader;
		}
		
		public function get bundlesLoaded():Boolean {
			return _bundlesLoaded;
		}
		
		public function get currentScreen():ScreenView {
			return _screenHistory[_screenHistoryIndex];
		}
		
		public function get currentScreenResetRequested():Boolean {
			return _currentScreenResetRequested;
		}
		
		public function get currentBundle():ScreenBundle {
			return currentScreen.bundle;
		}
		
		protected function debugHistory():void {
			trace("--------------------------------------\nHISTORY:");
			for (var i:uint = 0, l:uint = _screenHistory.length; i < l; ++i) {
				var pointer:String = "   ";
				var screen:ScreenView = _screenHistory[i];
				
				if (i == _screenHistoryIndex) pointer = "-->";
				trace(pointer + " [" + i + "] " + screen.id);
			}
			trace("--------------------------------------");
		}
		
	}

}