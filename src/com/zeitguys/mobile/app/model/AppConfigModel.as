package com.zeitguys.mobile.app.model {
	import com.zeitguys.util.DebugUtils;
	import com.zeitguys.util.TextUtils;
	import flash.errors.IllegalOperationError;
	import flash.errors.IOError;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.net.SharedObject;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.text.StyleSheet;
	/**
	 * 
	 * @author Eric Holmes
	 */
	public class AppConfigModel extends EventDispatcher {
		
		public static const EVENT_CONFIG_LOADED:String = 'app-config-loaded';
		public static const EVENT_CONFIG_ERROR:String = 'app-config-error';
		
		protected var LOCAL_STORAGE_ID:String = 'appConfig';
		private var _localStorageCache:Object = { };
		
		protected var _data:XML;
		protected var _isLoaded:Boolean;
		protected var _url:String;
		protected var _stylesheet:StyleSheet = new StyleSheet();
		
		protected var _firstRun:Boolean = true;
		
		private var _request:URLRequest;
		private var _loader:URLLoader = new URLLoader();
		protected var _assetLoader:AssetLoader = AssetLoader.getInstance();
		
		
		
		public function AppConfigModel(url:String = "") {
			_url = url;
		}
		
		/**
		 * If a URL is provided, load the XML file, otherwise short-circuit and complete.
		 * 
		 * @param	url
		 */
		public function load(url:String = ""):void {
			if (url) {
				_url = url;
			}
			
			if (_url) {
				_request = new URLRequest(_url);
				_loader.addEventListener(Event.COMPLETE, onLoadComplete);
				_loader.addEventListener(IOErrorEvent.IO_ERROR, onLoadError);
				try {
					trace("AppConfig LOADING config XML file: '" + _request.url + "'.");
					
					_loader.load(_request);
				} catch (error:String) {
					trace("AppConfig load error: " + error);
					dispatchEvent(new Event(EVENT_CONFIG_ERROR));
					removeListeners();
				}
			} else {
				_isLoaded = true;
				dispatchEvent(new Event(EVENT_CONFIG_LOADED));
				removeListeners();
			}
		}
	
	
		
		/**
		 * Called by a successful load.
		 * 
		 * Automatically loads the stylesheet if it's defined in the configuration XML.
		 * 
		 * You can also load the StyleSheet manually from the app by calling AppConfigModel.set styleSheet()
		 * 
		 * @param	event
		 */
		protected function onLoadComplete(event:Event):void {
			trace("AppConfig Load COMPLETE.\n---------------------------------------");
			_data = new XML(_loader.data);
			_isLoaded = true;
			dispatchEvent(new Event(EVENT_CONFIG_LOADED));
			
			if (_data.elements('theme').elements('stylesheet').length()) {
				loadStyleSheet(_data.elements('theme').elements('stylesheet'));
			}
			
			removeListeners();
		}
		
		public function loadStyleSheet(sheetURL:String):void {
			var sheetUrlRequest:URLRequest = new URLRequest(sheetURL);
				
			if (! sheetUrlRequest) {
				throw new Error("'" + sheetURL + "' is not a valid URL for the StyleSheet");
			}
			
			var cssLoader:CSSLoaderAsset = new CSSLoaderAsset(sheetUrlRequest, onStylesLoaded, onStylesError);
			_assetLoader.addItem(cssLoader);
		}
		
		private function onStylesLoaded(loadedStylesheet:StyleSheet):void {
			TextUtils.styleSheet = _stylesheet = loadedStylesheet;
		}
		
		public function get styleSheet():StyleSheet {
			return _stylesheet;
		}
		
		private function onStylesError():void {
			trace('CSS styles Load ERROR.');
		}
		
		/**
		 * Called by a URLLoader error. This is not the only place an error can be triggered - see try..catch within {@link #AppConfigModel()} method.
		 * @param	event
		 */
		protected function onLoadError(event:IOErrorEvent):void {
			trace("AppConfig Load error: " + event.text);
			
			dispatchEvent(new Event(EVENT_CONFIG_ERROR));
			removeListeners();
		}
		
		protected function removeListeners():void {
			if (_loader) {
				_loader.removeEventListener(Event.COMPLETE, onLoadComplete);
				_loader.removeEventListener(IOErrorEvent.IO_ERROR, onLoadError);
			}
			
			_loader = null;
			_request = null;
		}
		
		public function get currentLanguage():String {
			return getLocal('language');
		}
		
		public function set currentLanguage(language:String):void {
			setLocal('language', language);
		}
		
		public function get isLoaded():Boolean {
			return _isLoaded;
		}
		
		public function get theme():Object {
			if (_data) {
				return Object(_data.child('theme'));
			}
			return { };
		}
		
		public function get data():XML {
			return _data;
		}
		
		/**
		 * Dig into the _data XML, and optionally provide a default value if the data doesn't exist.
		 * 
		 * @param	key
		 * @param	attribute
		 * @param	defaultValue
		 * @return
		 */
		protected function getData(key:String, attribute:String = "", defaultValue:* = null):* {
			if (! _data || ! _data.child(key).length) {
				return defaultValue;
			}
			
			if (attribute) {
				return _data.child(key).attribute(attribute) || defaultValue;
			}
			
			return _data.child(key) || defaultValue;
		}
		
		/**
		 * Determines whether this is the first time the App has been run (based on
		 * the presence of a key in LocalStorage).
		 */
		public function get firstRun():Boolean {
			if (getLocal('runBefore')) {
				_firstRun = false;
			} else {
				setLocal('runBefore', true);
				
				_firstRun = true;
				trace("App FIRST RUN detected.");
			}
			
			return _firstRun;
		}
		
		/**
		 * Retrieve a single value from the App Config local storage.
		 * 
		 * Leverages basic cacheing for performance.
		 * 
		 * @param	key
		 * @param	required If `true`, will throw an error if the key is missing.
		 * @return
		 */
		protected function getLocal(key:String, required:Boolean = false):* {
			if (key in _localStorageCache) {
				return _localStorageCache[key];
			}
			
			return _localStorageCache[key] = LocalStorage.fetch(key, required, LOCAL_STORAGE_ID);
		}
		
		/**
		 * Store a single value to the App Config local storage, and stash it in the cache as well.
		 * 
		 * @param	key
		 * @param	value
		 */
		protected function setLocal(key:String, value:*):void {
			_localStorageCache[key] = value;
			
			LocalStorage.stash(key, value, LOCAL_STORAGE_ID);
		}
	}

}