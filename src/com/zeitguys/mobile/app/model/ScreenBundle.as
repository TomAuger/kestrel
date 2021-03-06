package com.zeitguys.mobile.app.model {
	import com.zeitguys.mobile.app.AppBase;
	import com.zeitguys.mobile.app.error.FlashConstructionError;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import com.zeitguys.mobile.app.view.ScreenView;
	import flash.net.URLRequest;
	/**
	 * A ScreenBundle corresponds to an SWF file with a bunch of "Screens" on Frame 1. Each Screen is its own MovieClip with a distinct instance name.
	 * 
	 * @author TomAuger
	 */
	public class ScreenBundle {
		protected var _id:String;
		protected var _index:uint;
		protected var _screens:Vector.<ScreenView> = new Vector.<ScreenView>();
		protected var _swfURL:URLRequest;
		protected var _swf:DisplayObjectContainer;
		
		protected var _loaded:Boolean = false;
		
		// Holds all the bundles defined for this app. Each bundle MUST have a unique ID.
		static protected var __bundles:Object = [];
		
		/**
		 * Constructor. Creates a new ScreenBundle and registers its ID.
		 * 
		 * Stashes all the screens defined in `screens`.
		 * 
		 * @param	id Must be unique.
		 * @param	swf [DisplayObjectContainer|String|URLRequest] Either the SWF object or a URL string that the loader can use.
		 * @param	screens The Screen objects associated with this Bundle.
		 */
		public function ScreenBundle(id:String, swf:*, screens:Vector.<ScreenView>) {
			if (id) {
				// Make sure the ID is unique
				if (!__bundles[id]){
					_id = id;
					
					// Add to the static list so we check uniqueness
					__bundles[id] = this;
				} else {
					throw new Error("Cannot create ScreenBundle: a bundle with id '" + id + "' has already been registered.");
				}
			} else {
				throw new Error("ScreenBundle ID cannot be blank.");
			}
			
			// Register each screen and add it to the list of screens.
			if (screens) {
				for each (var screen:ScreenView in screens) {
					addScreen(screen);
				}
			}
			
			
			// Handle the different Types that swf can handle or throw a TypeError.
			// We have to do this AFTER we store the screens
			if (swf) {
				if (swf is DisplayObjectContainer) {
					_swf = DisplayObjectContainer(swf);
					
					setBundleLoaded();
				} else if (swf is String) {
					_swfURL = new URLRequest(swf);
				} else if (swf is URLRequest) {
					_swfURL = swf;
				} else {
					throw new TypeError("'swf' argument must be a DisplayObjectContainer, a URLRequest or a URL String.");
				}
			}
		}
		
		/**
		 * Add the screen to the end of the screen list, and set the Bundle 
		 * on the Screen, as well as the bundleIndex, so the Screen knows where
		 * it sits in the Bundle.
		 * 
		 * @param	screen
		 */
		public function addScreen(screen) {
			screen.bundle = this;
			screen.bundleIndex = _screens.length;
			_screens.push(screen);
		}
		
		/**
		 * Sets the index of this ScreenBundle within the ScreenRouter's list of bundles.
		 */
		public function set index(i:uint):void {
			_index = i;
		}
		
		/**
		 * Get the index of this ScreenBundle within the ScreenRouter's list of bundles.
		 */
		public function get index():uint {
			return _index;
		}
		
		public function get screenCount():uint {
			return _screens.length;
		}
		
		
		public function getScreenByID(screenID:String):ScreenView {
			for each (var screen:ScreenView in _screens) {
				if (screen.id == screenID) {
					return screen;
				}
			}
			
			throw new RangeError("Screen with ID: '" + screenID + "' is not available in this Bundle.");
		}
		
		public function getScreenByIndex(index:uint):ScreenView {
			if (_screens.length > index) {
				return _screens[index];
			}
			return null;
		}
		
		/**
		 * Digs through the Bundle's SWF and locates a MovieClip by name. Generally used by ScreenView to locate its clip.
		 * @see ScreenView()
		 * 
		 * @param	clipName
		 * @return
		 */
		public function getClipByName(clipName:String):DisplayObjectContainer {
			if (_swf && loaded){
				for (var i:uint = 0, l:uint = _swf.numChildren; i < l; ++i) {
					var child:DisplayObject = _swf.getChildAt(i);
					if (child is DisplayObjectContainer) {
						if (child.name == clipName) {
							return DisplayObjectContainer(child);
						}
					}
				}
				
				throw new FlashConstructionError(_swf.name, clipName, "Cannot find Screen clip '" + clipName + "' in ScreenBundle '" + id + "'");
			} else {
				throw new Error("Attempting to access unloaded ScreenBundle");
			}
		}
		
		/**
		 * Lets each ScreenView know that its Bundle has been loaded, so it can go ahead and "locate" its MovieClip.
		 * 
		 * Also strips all children right out of the SWF
		 */
		protected function prepareScreens():void {
			for each (var screen:ScreenView in _screens) {
				screen.prepare();
			}
			
			onScreensPrepared();
		}
		
		/**
		 * Any tasks that need to be done after all the screens in this bundle have been prepared.
		 */
		protected function onScreensPrepared():void {
			
		}
		
		public function registerScreen(screen:ScreenView):void {
			
		}
		
		public function getScreenNames():Array {
			return new Array();
		}
		
		public function get screens():Vector.<ScreenView> {
			return _screens;
		}
		
		public function get id():String {
			return _id;
		}
		
		public function get loaded():Boolean {
			return _loaded;
		}
		
		/**
		 * Use this to access the bundle's SWF asset.
		 */
		public function get asset():DisplayObjectContainer {
			return _swf;
		}
		
		public function set asset(SWF:DisplayObjectContainer):void {
			_swf = SWF;
		}
		
		public function get request():URLRequest {
			if (_swfURL) {
				return _swfURL;
			} else {
				return null;
			}
		}

		/**
		 * Sets the loaded property of the Bundle.
		 * If its previous state was not loaded, then it also triggers the prepare() method of all associated ScreenViews
		 * 
		 * @param isLoaded Typically this is set to 'true'
		 */
		public function setBundleLoaded():void {
			if (! _loaded) {
				trace("Bundle '" + id + "' LOADED.");
				
				_loaded = true;
				
				_swf.stopAllMovieClips();
				
				prepareScreens();
				trace("--------------------------------------");
			}
		}
		
		public function debugBundle():void {
			trace("Debugging Bundle " + id + "\n--------------------");
			for each (var screen:ScreenView in _screens) {
				trace(screen.id);
			}
		}
	}

}