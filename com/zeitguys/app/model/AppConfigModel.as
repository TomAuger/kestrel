package com.zeitguys.app.model {
	import com.zeitguys.util.DebugUtils;
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
		
		public var localStorage:SharedObject;
		
		protected var _data:XML;
		
		protected var _isLoaded:Boolean;
		
		protected var _url:String;
		
		protected var _stylesheet:StyleSheet = new StyleSheet();
		
		private var _request:URLRequest;
		private var _loader:URLLoader = new URLLoader();
		protected var _assetLoader:AssetLoader = AssetLoader.getInstance();
		
		
		public function get isLoaded():Boolean {
			return _isLoaded;
		}
		
		public function get theme():Object {
			if (_data) {
				return Object(_data.child('theme'));
			}
			return { };
		}
		
		public function get styleSheet():StyleSheet {
			return _stylesheet;
		}
		
		public function AppConfigModel(url:String = "") {
			_url = url;
			localStorage = SharedObject.getLocal( LOCAL_STORAGE_ID );
		}
		/**
		 * If a URL is provided, load the XML file, otherwise short-circuit and complete.
		 * 
		 * @param	url
		 */
		public function load():void {
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
		 * @param	event
		 */
		protected function onLoadComplete(event:Event):void {
			trace("AppConfig Load COMPLETE.\n---------------------------------------");
			_data = new XML(_loader.data);
			_isLoaded = true;
			dispatchEvent(new Event(EVENT_CONFIG_LOADED));
			if (_data.elements('theme').elements('stylesheet')) {
				initializeStylesheet();
			}
			removeListeners();
		}
		
		private function initializeStylesheet():void {
			var cssLoader:CSSLoaderAsset = new CSSLoaderAsset(new URLRequest(_data.elements('theme').elements('stylesheet')), onStylesLoaded, onStylesError);
			_assetLoader.addItem(cssLoader);
		}
		
		private function onStylesLoaded(stylesheet:StyleSheet):void {
			_stylesheet = stylesheet;
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
		
		public function get defaultLanguage():String {
			trace(_data.child('languages').attribute('default_language'));
			return _data.child('languages').attribute('default_language');
		}
		
		public function get currentLanguage():String {
			trace();
			trace();
			trace();
			trace( 'current language', localStorage.data['language']);
			trace();
			trace();
			trace();
			return localStorage.data['language'];
		}
		
		public function set currentLanguage(language:String):void {
			trace('setting app language to remember', language);
			localStorage.data['language'] = language;
		}
		
		public function get languages():Array {
			var languages:XMLList = _data.child('languages').children();
			var output:Array = new Array();
			for (var i:uint = 0; i < languages.length(); i++) {
				output.push({ value: languages[i].attribute('code'), label: languages[i] });
			}
			return output;
		}
		
		public function getLanguageLabel(language:String = ''):String {
			language ||= defaultLanguage;
			for (var i:uint = 0; i < languages.length; i++) {
				if (language == languages[i].value) {
					return languages[i].label;
				}
			}
			return '';
		}
		
		public function get data():XML {
			return _data;
		}
	}

}