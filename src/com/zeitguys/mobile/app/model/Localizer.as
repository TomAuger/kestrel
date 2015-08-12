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
		
		public var defaultLanguage:String = "en";
		
		protected var _xmlFileBaseName:String = "";
		protected var _languageCode:String;
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
		public function Localizer(xmlFileBaseName:String, languageCode:String = "", loadNow:Boolean = false) {
			if (__instance) {
				throw new IllegalOperationError("Localizer has already been instantiated. Get a reference to the instance instead.");
			}
			
			_xmlFileBaseName = xmlFileBaseName;
			
			setLanguage(languageCode);
			
			_localeID = new LocaleID(_languageCode);
			
			if (loadNow) {
				load();	
			}
		}

		/**
		 * Once AppConfig is loaded, we read and store the default language provided by the config.xml file
		 * @param	e
		 */
		public function setDefaultLanguage(language:String = 'en'):void {
			defaultLanguage = language;
		}
		/**
		 * Sets the Localizer's language - the order of priority is the following:
		 *  1. Specified language
		 *  2. User's manual language selection (language dropdown)
		 *  3. Device System Language
		 *  4. Default language (en)
		 * 
		 * @param	languageCode Optional. The language code to be used.
		 */
		public function setLanguage(languageCode:String = ""):String {
			
			if (languageCode){
				_languageCode = languageCode;
			} else if (Capabilities.language) {
				// System setting
				_languageCode = Capabilities.language;
			} else {
				// Fallback of default language
				_languageCode = defaultLanguage;
			}
			
			return _languageCode;
		}
		
		/**
		 * Sets the language and dispatches EVENT_LANGUAGE_CHANGED if the language
		 * has, indeed, changed. Indeed.
		 * 
		 * @param	newLanguage the new language code to be used
		 */
		public function set language(newLanguage:String):void {
			// New valid Language
			var newLang:String = setLanguage(newLanguage);
			trace('tried '+newLanguage+', set to ' + newLang);
			if (setLanguage(newLanguage) == newLanguage) {
				// We need to load the XML file
				load();
			}
		}
		
		public function get language():String {
			return _languageCode;
		}
		
		/**
		 * Load the XML file for a specific language code.
		 * 
		 * @param	xmlFileBaseName Optional. If not provided, will use the default one provided in the constructor
		 * @param	languageCode Optional. If not provided, will choose the current language
		 */
		public function load(xmlFileBaseName:String = "", languageCode:String = ""):void {
			var path:String = xmlFileBaseName || _xmlFileBaseName;
			var url:URLRequest;
			
			languageCode = languageCode || _languageCode;
			
			if (languageCode) {
				path += "_" + languageCode + ".xml";
				url = new URLRequest(path);
				
				// Look inside our _XML object to see whether this language
				// has already been loaded. If not, load it already!
				if (!_XML[languageCode]) {
					var asset:XMLLoaderAsset = new XMLLoaderAsset(url, languageCode, onLoadComplete, onLoadError);
					if (0 == _loader.addItem(asset)) {
						if (_languageCode == defaultLanguage) {
							throw new ReferenceError("Cannot load XML file: Please supply a XML translation file for "+_languageCode+".");
						}
						trace('xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx');
						trace('Language (' + languageCode + ') not supported - loading default language');
						trace('xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx');
						_languageCode = defaultLanguage;
						load();
					}
				} else {
					onLoadComplete(languageCode);
				}
			} else {
				throw new ReferenceError("Cannot load XML file: languageCode not defined.");
			}
		}
		
		/**
		 * 
		 * @param	target
		 * @param	languageCode Optional. Use the current language code if not defined.
		 */
		public function localize(target:ILocalizable, languageCode:String = ""):void {
			languageCode ||= _languageCode;
			
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
		
		public function get xml():XML {
			if (_languageCode){
				return XML(_XML[_languageCode]);
			}
			
			return null;
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
			languageCode ||= _languageCode;
			
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
		
		/**
		 * Process the queue for the given language code.
		 * 
		 * @param	languageCode
		 * @param	xml
		 */
		public function onLoadComplete(languageCode:String, xml:XML = null):void {
			trace("Content loaded for LANGUAGE: " + languageCode);
			if (xml) {
				_XML[languageCode] = xml;
			}
			// Any items in the queue for this language code? If so, process 'em!
			if (_localizationQueue[languageCode] && _localizationQueue[languageCode].length) {
				while (_localizationQueue[languageCode].length) {
					var item:ILocalizable = ILocalizable(_localizationQueue[languageCode].shift());
					item.localize(this);
				}
			}
			dispatchEvent(new Event(EVENT_LANGUAGE_CHANGED));
		}
		
		/**
		 * Pretty sure your app is broken if you can't load your localization file.
		 * 
		 * @param	languageCode
		 * @param	error
		 */
		public function onLoadError(languageCode:String, error:String):void {
			throw new Error("Fatal Error: localization file not found.");
		}
	}

}