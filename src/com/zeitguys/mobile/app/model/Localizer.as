package com.zeitguys.mobile.app.model {
	import com.zeitguys.util.DebugUtils;
	import flash.errors.IllegalOperationError;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.globalization.DateTimeFormatter;
	import flash.globalization.LocaleID;
	import flash.globalization.NumberFormatter;
	import flash.net.URLRequest;
	import flash.system.Capabilities;
	
	/**
	 * Localizer proxy and queue.
	 * 
	 * Use this class to localize all text.
	 * 
	 * Upon instantiation, will leverage AssetLoader to load an XML file. Other classes that implement ILocalizable register their desire to 
	 * be localized by calling localize() and passing a self-reference. If the XML file for the requested language is not yet ready,
	 * the localization request is queued. When the XML is ready, Localizer dequeues all the requests and calls localize() on each
	 * registered ILocalizable object, passing itself. 
	 * 
	 * This saves having to register callbacks or event listeners for every class that wants to localize a string.
	 * 
	 * @author TomAuger
	 */
	public class Localizer extends EventDispatcher {
		public static const EVENT_LANGUAGE_CHANGED:String = 'language-changed';
		
		protected var _xmlFileBaseName:String = "";
		protected var _currentLanguageCode:String;
		protected var _defaultLanguageCode:String;
		protected var _localeID:LocaleID;
		
		protected var _XML:Object = { };
		protected var _loader:AssetLoader = AssetLoader.getInstance();
		protected var _localizationQueue:Object = { };
		
		protected var _emptyXML:XMLList;
		
		private static var __instance:Localizer;
		
		
		/**
		 * Constructor. Should only use once. Error is thrown if instantiated multiple times.
		 * @param	target
		 */
		public function Localizer(xmlFileBaseName:String, defaultLanguageCode:String = "en_US", loadNow:Boolean = true) {
			if (__instance) {
				throw new IllegalOperationError("Localizer has already been instantiated. Get a reference to the instance instead.");
			}
			
			_xmlFileBaseName = xmlFileBaseName;
			_defaultLanguageCode = defaultLanguageCode;
			
			if (loadNow) {
				load(_defaultLanguageCode);	
			}
		}
		
		/**
		 * Load the XML file for a specific language code.
		 * 
		 * @param	xmlFileBaseName Optional. If not provided, will use the default one provided in the constructor
		 * @param	languageCode Optional. If not provided, will choose the current language
		 */
		public function load(languageCode:String = "", xmlFileBaseName:String = ""):void {
			var path:String = xmlFileBaseName || _xmlFileBaseName;
			var url:URLRequest;
			languageCode ||= _defaultLanguageCode;
			
			path += languageCode + ".xml";
			url = new URLRequest(path);
			
			// Look inside our _XML object to see whether this language
			// has already been loaded. If not, load it already!
			if (!_XML[languageCode]) {
				var asset:XMLLoaderAsset = new XMLLoaderAsset(url, languageCode, onLoadComplete, onLoadError);
				// If the item didn't get queued, it means the file doesn't exist.
				if (0 == _loader.addItem(asset)) {
					// Short-circuit if we've already tried the default language code and it doesn't exist.
					if (languageCode == _defaultLanguageCode) {
						throw new ReferenceError("Cannot load XML file: Please supply a XML translation file for " + _defaultLanguageCode + ".");
					}
					
					trace("Cannot load XML file for requested language (" + languageCode + "). Loading default language code (" + _defaultLanguageCode + ").");
					load(_defaultLanguageCode);
				}
			} else {
				onLoadComplete(languageCode);
			}
		}
		
		/**
		 * 
		 * @param	target
		 * @param	languageCode Optional. Use the current language code if not defined.
		 */
		public function localize(target:ILocalizable, languageCode:String = ""):void {
			languageCode ||= currentLanguage;
			
			if (! hasXMLForLanguage(languageCode) || (_localizationQueue[languageCode] && _localizationQueue[languageCode].length)) {
				if (! _localizationQueue[languageCode]) {
						_localizationQueue[languageCode] = [target];
				} else {
					_localizationQueue[languageCode].push(target);
				}
			} else {
				target.localize(this);
			}
		}
		
		
		
		public function setLanguageWithFallback(languageCode:String = ""):String {
			return setLanguage(selectLanguageWithFallback(languageCode));
		}
		
		/**
		 * Loads the language XML if necessary and then sets the current language and
		 * fires EVENT_LOAD_COMPLETE
		 * 
		 * @param	languageCode
		 */
		public function setLanguage(languageCode:String) {
			load(languageCode);
		}
		
		/**
		 * Attempts to set the language to the requested language. If language code isn't supplied, (or doesn't exist)
		 * then will use fallbacks to set the language.
		 * 
		 * You can listen for the return language code to determine which language ended up being selected.
		 * 
		 * @param	languageCode
		 */
		public function selectLanguageWithFallback(languageCode:String = ""):String {
			var newLanguageCode:String = languageCode;
			
			newLanguageCode ||= Capabilities.language;
			newLanguageCode ||= _defaultLanguageCode;
			
			return newLanguageCode;
		}
		
		public function get currentLanguage():String {
			return _currentLanguageCode || _defaultLanguageCode;
		}
		
		public function get numberFormatter():NumberFormatter {
			return new NumberFormatter(_localeID.name);
		}
		
		public function get datetimeFormatter():DateTimeFormatter {
			return new DateTimeFormatter(_localeID.name);
		}
		
		
		
		
		
		/**
		 * @TODO	Probably should load the XML if it isn't present. Maybe?
		 * @param	languageCode
		 * @return
		 */
		public function getXMLForLanguage(languageCode:String = ""):XML {
			languageCode ||= currentLanguage;
			
			return XML(_XML[languageCode]);
		}
		
		public function hasXMLForLanguage(languageCode:String):Boolean {
			return _XML.hasOwnProperty(languageCode);
		}
		
		/**
		 * Abstract method. Child classes must implement this method to map to their XML file structure.
		 * 
		 * Get a single string that corresponds to one element (component) of an asset, identified by ID, Screen ID and Bundle ID.
		 * 
		 * @param	bundleID
		 * @param	screenID
		 * @param	assetID
		 * @param	component
		 * @param	componentID Optional. If the XML contains two sibling components of the same name, they must have an ID to distinguish them.
		 * @return
		 */
		public function getHeaderComponentText(bundleID:String, screenID:String, component:String, componentID:String = ""):String {
			throw new Error("Abstract method. Must override in child classes.");
		}
		
		/**
		 * Abstract method. Child classes must implement this method to map to their XML file structure.
		 * 
		 * Get a single string that corresponds to one element (component) of an asset, identified by ID, Screen ID and Bundle ID.
		 * 
		 * @param	bundleID
		 * @param	screenID
		 * @param	assetID
		 * @param	component
		 * @param	componentID Optional. If the XML contains two sibling components of the same name, they must have an ID to distinguish them.
		 * @return
		 */
		public function getAssetComponentText(bundleID:String, screenID:String, assetID:String, component:String, componentID:String = ""):String {
			throw new Error("Abstract method. Must override in child classes.");
		}
		
		/**
		 * Abstract method. Child classes must implement this method to map to their XML file structure.
		 * 
		 * Get content for alerts
		 * 
		 * @param	languageCode
		 * @param	xml
		 */
		public function getModalComponentText(alertID:String, component:String):String {
			throw new Error("Abstract method. Must override in child classes.");
		}
		
		
		
		
		
		
		
		
		protected function set language(languageCode:String) {
			if (languageCode != _currentLanguageCode) {
				_currentLanguageCode = languageCode;
				_localeID = new LocaleID(languageCode);
				
				trace("Localizer current language changed to '" + languageCode + "'.");
				dispatchEvent(new Event(EVENT_LANGUAGE_CHANGED));
			}
		}
		
		protected function get xml():XML {
			if (currentLanguage){
				return XML(_XML[currentLanguage]);
			}
			
			return null;
		}
		
		/**
		 * Process the queue for the given language code.
		 * 
		 * @param	languageCode
		 * @param	xml
		 */
		protected function onLoadComplete(languageCode:String, xml:XML = null):void {
			trace("Content loaded for LANGUAGE: " + languageCode);
			
			if (xml) {
				_XML[languageCode] = xml;
			}
			
			// Store current language and dispatch EVENT_LANGUAGE_CHANGED
			language = languageCode;
			
			// Any items in the queue for this language code? If so, process 'em!
			if (_localizationQueue[languageCode] && _localizationQueue[languageCode].length) {
				while (_localizationQueue[languageCode].length) {
					var item:ILocalizable = ILocalizable(_localizationQueue[languageCode].shift());
					item.localize(this);
				}
			}
		}
		
		/**
		 * Pretty sure your app is broken if you can't load your localization file.
		 * 
		 * @param	languageCode
		 * @param	error
		 */
		protected function onLoadError(languageCode:String, error:String):void {
			throw new Error("Fatal Error: localization file not found.");
		}
	}

}