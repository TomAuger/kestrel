package com.zeitguys.mobile.app.view {
	import com.zeitguys.mobile.app.AppBase;
	import com.zeitguys.mobile.app.model.ILocalizable;
	import com.zeitguys.mobile.app.model.Localizer;
	import com.zeitguys.mobile.app.view.asset.AssetView;
	import com.zeitguys.util.TextUtils;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.errors.IllegalOperationError;
	import flash.events.EventDispatcher;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextLineMetrics;
	
	import com.zeitguys.util.ClipUtils;
	
	/**
	 * Base View that all ScreenViews and AssetViews inherit from.
	 * 
	 * @TODO - AppTheme needs to go, and we need to figure out how to load stylesheets in a more universal way.
	 * 
	 * @author TomAuger
	 */
	public class ViewBase extends EventDispatcher implements ILocalizable {
		/**
		 * Holds all the Text Variables (%%VARIABLE_NAME%%) that might be defined in a localization file or in a model.
		 */
		public var textVariables:Object = { };
		
		protected var _clip:DisplayObject;
		protected var _clipName:String;
		protected var _clipOrigX:Number;
		protected var _clipOrigY:Number;
		
		protected static var __app:AppBase;
		
		
		public function ViewBase(clip:DisplayObject = null) {
			if (clip) {
				_clip = clip;
				_clipName = _clip.name;
			}
		}
		
		public function set clip(clipDisplayObject:DisplayObject):void {
			_clip = clipDisplayObject;
		}
		
		public function get clip():DisplayObject {
			if (_clip){
				return _clip;
			} else {
				throw new IllegalOperationError("'" + _clipName + "' has not yet been defined! Why are you asking for it now?");
			}
		}
		
		public function get hasClip():Boolean {
			if (_clip) {
				return true;
			}
			
			return false;
		}
		
		/**
		 * Convenience method. Casts the clip as a MovieClip if it can. 
		 */
		public function get movieClip():MovieClip {
			if (clip && clip is MovieClip) {
				return clip as MovieClip;
			}
			
			return null;
		}
		
		public function get parentClip():DisplayObjectContainer {
			if (_clip) {
				return _clip.parent;
			}
			
			return null;
		}
	
		public function get id():String {
			return _clipName;
		}
		
		public static function setApp(app:AppBase):void {
			__app = app;
		}
		
		public function get app():AppBase {
			return __app;
		}
		
		public function get x():Number {
			if (_clip){
				return _clip.x;
			}
			
			return NaN;
		}
		
		public function set x(pixelsX:Number):void {
			if (_clip){
				_clip.x = pixelsX;
			} else {
				throw new IllegalOperationError("Attempting to set clip's x-position before the clip has been located.");
			}
		}
		
		public function get y():Number {
			if (_clip){
				return _clip.y;
			}
			
			return NaN;
		}
		
		public function set y(pixelsY:Number):void {
			if (_clip){
				_clip.y = pixelsY;
			} else {
				throw new IllegalOperationError("Attempting to set clip's y-position before the clip has been located.");
			}
		}
		
		public function get origX():Number {
			return _clipOrigX;
		}
		
		public function get origY():Number {
			return _clipOrigY;
		}
		
		
		/* ===========================================================================================================
		 *                                                 LOCALIZATION
		/* ===========================================================================================================*/
		
		/**
		 * Override in child classes. This is the only time the View gets a reference to the Localizer,
		 * so this is where you localize all of the text within the View.
		 * 
		 * @param	localizer
		 */
		public function localize(localizer:Localizer):void {
			
		}
		
		/**
		 * Set the text of a textField within the asset, or of the asset itself (if the asset is a TextField instance).
		 * 
		 * TODO: Do a check for something like containsHtmlEntities() on the text, and if it does, use the .htmlText route instead of .text
		 * 
		 * @see /parseVariables() for more on how to leverage %%VARIABLE_NAME%% variable substitution.
		 * 
		 * @param	textField String|TextField Optional. If blank, will attempt to use the asset's _clip. If String, will look through the _clip's display list for the first DisplayObject with the string as its instance name
		 * @param	textOrHTML The new text.
		 * @param 	variables Optional. Key-value pairs of text variables that can be substituted at runtime. See {@link parseVariables()}.
		 * @param	isHTML Optional.
		 * @param 	autoSize Optional.
		 */
		public function setText(textField:*, textOrHTML:String, variables:Object = null, isHTML:Boolean = false, autoSize:Boolean = true):void {
			var field:TextField;
			
			if (textField == null) {
				if (_clip) {
					if (_clip is TextField){	
						textField = TextField(_clip);
					}
				} else {
					trace("ViewBase.setText() WARNING: attempting to use ViewBase's clip, but clip has not yet been defined.");
				}
			}
			
			if (textField is TextField) {
				field = textField;
			} else if (textField is String) {
				if (_clip is DisplayObjectContainer){
					field = getDescendantByName(textField, DisplayObjectContainer(_clip)) as TextField
				} else {
					throw new IllegalOperationError("'" + _clipName + "' is not a DisplayObjectContainer.");
				}
			}
			
			if (field) {
				if (hasHtmlEntities( textOrHTML) ) {
					isHTML = true;
					textOrHTML = convertEntities(textOrHTML);	
				}
				
				TextUtils.setTextFieldContent(field, parseVariables(textOrHTML, variables), isHTML, autoSize);
			} else {
				trace("ViewBase.setText() WARNING: Could not find appropriate TextField (" + textField.name + ") in " + _clipName + ".");
			}
		}
		
		public function get clipName():String {
			trace("Deprecated: `ViewBase.get clipName()`. Use `ViewBase.get name()` instead.");
			return _clipName;
		}
		
		public function get name():String {
			return _clipName;
		}
		
		
		/**
		 * Looks through the supplied string for occurrences of %%VARIABLE_NAME%% and replaces them with the values of
		 * the corresponding variables.
		 * 
		 * There are a number of ways you can set text variables prior to the call to parseVariables():
			 * 1. call {@link /setTextVariable()} prior to the call to parseVariables()
			 * 2. pass the variable and value as a key-value pair in the optional `variables` argument
			 * 3. directly write to textVariables. This is probably a bit heavy-handed for most cases
			 * 4. override getTextVariable() in a child class. I'm not sure why you would need to do this, but the option is there. Just sayin'.
		 * 
		 * Used by {@link /setText()}. Generally, you won't need to call parseVariables directly if you can use setText() to actually set the text on the
		 * given TextField.
		 * 
		 * Often you won't even use setText() because you'll let the ScreenAssetView's {@link /localize()} method take care of everything for you. In that case,
		 * your best option is to call {@link /setTextVariable()} within your child ScreenAssetView's overridden `localize()` method, prior to calling `super.localize(localizer)`.
		 * 
		 * @param	textToParse
		 * @param	variables Optional.
		 * @return
		 */
		protected function parseVariables(textToParse:String, variables:Object = null):String {
			var matches:Array = textToParse.match(/%%\w+%%/g);
			
			for each (var variable:String in matches) {
				variable = variable.replace(/%/g, "");
				textToParse = textToParse.replace(new RegExp("%%" + variable + "%%"), getTextVariable(variable, variables));
			}
			
			return textToParse;
		}
		
		/**
		 * Set a specific text variable. Converts the value to a String (passed value must be of a type that supports toString())
		 * 
		 * @param	variableName
		 * @param	value
		 */
		public function setTextVariable(variableName:String, value:*):void {
			textVariables[variableName] = value.toString();
		}
		
		/**
		 * Returns the variable string given a variable name.
		 * 
		 * @param	variableName
		 * @param	variables Optional. If set, will look here first to find the variable, otherwise, looks up the variable in _variables.
		 * @return
		 */
		public function getTextVariable(variableName:String, variables:Object = null):String {
			if (variables && variables.hasOwnProperty(variableName)) {
				return variables[variableName];
			}
			
			if (textVariables.hasOwnProperty(variableName)) {
				return textVariables[variableName];
			}
			
			return "%%" + variableName + "%%";
		}
		
		protected function trimText(text:String, maxLength:uint = 25, append:String = "..."):String {
			if (append) {
				maxLength -= append.length;
			}
			
			if (text.length > maxLength) {
				text = text.substr(0, maxLength);
				
				if (append) {
					text += append;
				}
			}
			
			return text;
		}
		
		
		
		
		
		
		/* ===========================================================================================================
		 *                                             DISPLAYLIST UTILITIES
		/* ===========================================================================================================*/
		
		/**
		 * Dig through the display hierarchy of the clip to find a child DisplayObject with the requested instance name.
		 * 
		 * @throws FlashConstructionError if no matching asset is found.
		 * 
		 * @param	clipName
		 * @return
		 */
		protected function getRequiredChildByName(clipName:String, asClass:Class = null, parentClip:DisplayObjectContainer = null):DisplayObject {
			var clip:DisplayObject;
			
			if (! parentClip) {
				if (_clip && _clip is DisplayObjectContainer) {
					parentClip = DisplayObjectContainer(_clip);
				} else {
					throw new IllegalOperationError("Called getRequiredChildByName() with no parentClip, and this View's clip has not yet been defined.");
				}
			}
			
			if (parentClip && parentClip is DisplayObjectContainer){
				clip = ClipUtils.getRequiredChildByName(clipName, parentClip, asClass);
			} else {
				throw new IllegalOperationError("'" + parentClip + "' is not a DisplayObjectContainer.");
			}
			
			return clip;
		}
		
		/**
		 * @see ClipUtils.getDescendantByName()
		 * 
		 * @param	childName
		 * @param	parentClip
		 * @return
		 */
		protected function getDescendantByName(childName:String, parentClip:DisplayObjectContainer = null):DisplayObject {
			if (parentClip == null) {
				if (_clip is DisplayObjectContainer){
					parentClip = DisplayObjectContainer(_clip);
				} else {
					throw new ArgumentError("Argument 'parentClip' not supplied and this View is not a DisplayObjectContainer.");
				}
			}
			return ClipUtils.getDescendantByName(childName, parentClip);
		}
		
		/**
		 * Attach the ViewBase's _clip to a parent container.
		 * 
		 * @param	parentClip
		 * @return
		 */
		public function attachTo(parentClip:DisplayObjectContainer, index:int = -1):uint {
			if (_clip) {
				if (index < 0) {
					parentClip.addChild(_clip);
				} else {
					parentClip.addChildAt(_clip, index);
				}
				return parentClip.getChildIndex(_clip);
			} else {
				throw new ReferenceError("Attempting to attach a View before it has been assigned a clip.");
			}
		}
		
		public function detach():void {
			if (_clip.parent) {
				_clip.parent.removeChild(_clip);
			}
		}
		
		
		
		
		
		/**
		 * Override in child classes.
		 * 
		 * Allows us to add a filter. Extend this in subclasses, remembering to call parent.addFilter() at the end of the overridden method.
		 * 
		 * @param	filterName
		 * @param	filterCallback
		 */
		public function addFilter(filterName:String, filterCallback:Function):void {
			
		}

		
		/**
		 * Convert HTML entities within html text.
		 * 
		 * @param	str
		 * @return
		 */
		
		private var entityMap:Object = { '&nbsp;':'&#160;', '&iexcl;':'&#161;', '&cent;':'&#162;', '&pound;':'&#163;', '&curren;':'&#164;', '&yen;':'&#165;', '&brvbar;':'&#166;', '&sect;':'&#167;', '&uml;':'&#168;', '&copy;':'&#169;', '&ordf;':'&#170;', '&laquo;':'&#171;', '&not;':'&#172;', '&shy;':'&#173;', '&reg;':'&#174;', '&macr;':'&#175;', '&deg;':'&#176;', '&plusmn;':'&#177;', '&sup2;':'&#178;', '&sup3;':'&#179;', '&acute;':'&#180;', '&micro;':'&#181;', '&para;':'&#182;', '&middot;':'&#183;', '&cedil;':'&#184;', '&sup1;':'&#185;', '&ordm;':'&#186;', '&raquo;':'&#187;', '&frac14;':'&#188;', '&frac12;':'&#189;', '&frac34;':'&#190;', '&iquest;':'&#191;', '&Agrave;':'&#192;', '&Aacute;':'&#193;', '&Acirc;':'&#194;', '&Atilde;':'&#195;', '&Auml;':'&#196;', '&Aring;':'&#197;', '&AElig;':'&#198;', '&Ccedil;':'&#199;', '&Egrave;':'&#200;', '&Eacute;':'&#201;', '&Ecirc;':'&#202;', '&Euml;':'&#203;', '&Igrave;':'&#204;', '&Iacute;':'&#205;', '&Icirc;':'&#206;', '&Iuml;':'&#207;', '&ETH;':'&#208;', '&Ntilde;':'&#209;', '&Ograve;':'&#210;', '&Oacute;':'&#211;', '&Ocirc;':'&#212;', '&Otilde;':'&#213;', '&Ouml;':'&#214;', '&times;':'&#215;', '&Oslash;':'&#216;', '&Ugrave;':'&#217;', '&Uacute;':'&#218;', '&Ucirc;':'&#219;', '&Uuml;':'&#220;', '&Yacute;':'&#221;', '&THORN;':'&#222;', '&szlig;':'&#223;', '&agrave;':'&#224;', '&aacute;':'&#225;', '&acirc;':'&#226;', '&atilde;':'&#227;', '&auml;':'&#228;', '&aring;':'&#229;', '&aelig;':'&#230;', '&ccedil;':'&#231;', '&egrave;':'&#232;', '&eacute;':'&#233;', '&ecirc;':'&#234;', '&euml;':'&#235;', '&igrave;':'&#236;', '&iacute;':'&#237;', '&icirc;':'&#238;', '&iuml;':'&#239;', '&eth;':'&#240;', '&ntilde;':'&#241;', '&ograve;':'&#242;', '&oacute;':'&#243;', '&ocirc;':'&#244;', '&otilde;':'&#245;', '&ouml;':'&#246;', '&divide;':'&#247;', '&oslash;':'&#248;', '&ugrave;':'&#249;', '&uacute;':'&#250;', '&ucirc;':'&#251;', '&uuml;':'&#252;', '&yacute;':'&#253;', '&thorn;':'&#254;', '&yuml;':'&#255;', '&fnof;':'&#402;', '&Alpha;':'&#913;', '&Beta;':'&#914;', '&Gamma;':'&#915;', '&Delta;':'&#916;', '&Epsilon;':'&#917;', '&Zeta;':'&#918;', '&Eta;':'&#919;', '&Theta;':'&#920;', '&Iota;':'&#921;', '&Kappa;':'&#922;', '&Lambda;':'&#923;', '&Mu;':'&#924;', '&Nu;':'&#925;', '&Xi;':'&#926;', '&Omicron;':'&#927;', '&Pi;':'&#928;', '&Rho;':'&#929;', '&Sigma;':'&#931;', '&Tau;':'&#932;', '&Upsilon;':'&#933;', '&Phi;':'&#934;', '&Chi;':'&#935;', '&Psi;':'&#936;', '&Omega;':'&#937;', '&alpha;':'&#945;', '&beta;':'&#946;', '&gamma;':'&#947;', '&delta;':'&#948;', '&epsilon;':'&#949;', '&zeta;':'&#950;', '&eta;':'&#951;', '&theta;':'&#952;', '&iota;':'&#953;', '&kappa;':'&#954;', '&lambda;':'&#955;', '&mu;':'&#956;', '&nu;':'&#957;', '&xi;':'&#958;', '&omicron;':'&#959;', '&pi;':'&#960;', '&rho;':'&#961;', '&sigmaf;':'&#962;', '&sigma;':'&#963;', '&tau;':'&#964;', '&upsilon;':'&#965;', '&phi;':'&#966;', '&chi;':'&#967;', '&psi;':'&#968;', '&omega;':'&#969;', '&thetasym;':'&#977;', '&upsih;':'&#978;', '&piv;':'&#982;', '&bull;':'&#8226;', '&hellip;':'&#8230;', '&prime;':'&#8242;', '&Prime;':'&#8243;', '&oline;':'&#8254;', '&frasl;':'&#8260;', '&weierp;':'&#8472;', '&image;':'&#8465;', '&real;':'&#8476;', '&trade;':'&#8482;', '&alefsym;':'&#8501;', '&larr;':'&#8592;', '&uarr;':'&#8593;', '&rarr;':'&#8594;', '&darr;':'&#8595;', '&harr;':'&#8596;', '&crarr;':'&#8629;', '&lArr;':'&#8656;', '&uArr;':'&#8657;', '&rArr;':'&#8658;', '&dArr;':'&#8659;', '&hArr;':'&#8660;', '&forall;':'&#8704;', '&part;':'&#8706;', '&exist;':'&#8707;', '&empty;':'&#8709;', '&nabla;':'&#8711;', '&isin;':'&#8712;', '&notin;':'&#8713;', '&ni;':'&#8715;', '&prod;':'&#8719;', '&sum;':'&#8721;', '&minus;':'&#8722;', '&lowast;':'&#8727;', '&radic;':'&#8730;', '&prop;':'&#8733;', '&infin;':'&#8734;', '&ang;':'&#8736;', '&and;':'&#8743;', '&or;':'&#8744;', '&cap;':'&#8745;', '&cup;':'&#8746;', '&int;':'&#8747;', '&there4;':'&#8756;', '&sim;':'&#8764;', '&cong;':'&#8773;', '&asymp;':'&#8776;', '&ne;':'&#8800;', '&equiv;':'&#8801;', '&le;':'&#8804;', '&ge;':'&#8805;', '&sub;':'&#8834;', '&sup;':'&#8835;', '&nsub;':'&#8836;', '&sube;':'&#8838;', '&supe;':'&#8839;', '&oplus;':'&#8853;', '&otimes;':'&#8855;', '&perp;':'&#8869;', '&sdot;':'&#8901;', '&lceil;':'&#8968;', '&rceil;':'&#8969;', '&lfloor;':'&#8970;', '&rfloor;':'&#8971;', '&lang;':'&#9001;', '&rang;':'&#9002;', '&loz;':'&#9674;', '&spades;':'&#9824;', '&clubs;':'&#9827;', '&hearts;':'&#9829;', '&diams;':'&#9830;', '"':'&#34;', '&':'&#38;', '<':'&#60;', '>':'&#62;', '&OElig;':'&#338;', '&oelig;':'&#339;', '&Scaron;':'&#352;', '&scaron;':'&#353;', '&Yuml;':'&#376;', '&circ;':'&#710;', '&tilde;':'&#732;', '&ensp;':'&#8194;', '&emsp;':'&#8195;', '&thinsp;':'&#8201;', '&zwnj;':'&#8204;', '&zwj;':'&#8205;', '&lrm;':'&#8206;', '&rlm;':'&#8207;', '&ndash;':'&#8211;', '&mdash;':'&#8212;', '&lsquo;':'&#8216;', '&rsquo;':'&#8217;', '&sbquo;':'&#8218;', '&ldquo;':'&#8220;', '&rdquo;':'&#8221;', '&bdquo;':'&#8222;', '&dagger;':'&#8224;', '&Dagger;':'&#8225;', '&permil;':'&#8240;', '&lsaquo;':'&#8249;', '&rsaquo;':'&#8250;', '&euro;':'&#8364;' };

		public function convertEntities(str:String):String {
			var re:RegExp = /&\w*;/g
			var entitiesFound:Array = str.match(re);
			var entitiesConverted:Object = {};    

			var len:int = entitiesFound.length;
			var oldEntity:String;
			var newEntity:String;
			for (var i:int = 0; i < len; i++)
			{
				oldEntity = entitiesFound[i];
				newEntity = entityMap[oldEntity];

				if (newEntity && !entitiesConverted[oldEntity])
				{
					str = str.split(oldEntity).join(newEntity);
					entitiesConverted[oldEntity] = true;
				}
			}

			return str;
		}
		
		/**
		 * Check to see if HTML Entities are within the string passed.
		 * @param	str
		 * @return
		 */
		public function hasHtmlEntities(str:String):Boolean {
			var re:RegExp = /&\w*;/g
			return Boolean(str.match(re).length);
		}
	}

}