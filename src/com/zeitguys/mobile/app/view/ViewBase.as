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
		
		protected var _clipOrigX:Number;
		protected var _clipOrigY:Number;
		
		private var _clip:DisplayObject;
		private var _clipName:String;
		
		private static var __app:AppBase;
		
		
		public function ViewBase(clip:DisplayObject = null) {
			if (clip) {
				_clip = clip;
				_clipName = _clip.name;
			}
		}
		
		protected function _setClip(clipDisplayObject:DisplayObject):void {
			_clip = clipDisplayObject;
			_clipName = _clip.name;
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
		
		protected function setClipName(clipName:String):void {
			_clipName = clipName;
		}
		
		public function get name():String {
			return _clipName;
		}
		
		/**
		 * Convenience method. Casts the clip as a MovieClip if it can. 
		 */
		public function get movieClip():MovieClip {
			if (hasClip && clip is MovieClip) {
				return MovieClip(clip);
			}
			
			return null;
		}
		
		public function get parentClip():DisplayObjectContainer {
			if (_clip) {
				return _clip.parent;
			}
			
			return null;
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
		 * @return	Whether the setText operation was successful or not.
		 */
		public function setText(textField:*, textOrHTML:String, variables:Object = null, isHTML:Boolean = false, autoSize:Boolean = true):Boolean {
			var field:TextField;
			
			if (textOrHTML === null) {
				textOrHTML = "";
			}
			
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
				if (textOrHTML && TextUtils.hasHtmlEntities(textOrHTML)) {
					isHTML = true;
					textOrHTML = TextUtils.convertEntities(textOrHTML);	
				}
				
				setTextFieldContent(field, parseVariables(textOrHTML, variables), isHTML, autoSize);
				
				return true;
			} else {
				trace("ViewBase.setText() WARNING: Could not find appropriate TextField (" + textField.name + ") in " + _clipName + ".");
			}
			
			return false;
		}
		
		/**
		 * @uses TextUtils.setTextFieldContent()
		 * 
		 * Sets the TextField's .text or .htmlText property. Includes the additional logic for preserving the TextFormat / setting the stylesheet.
		 * 
		 * Maybe override in child classes if you need to change the way autosize / stylesheets / textFormats are handled
		 * on a case-by-case basis.
		 * 
		 * @param	field
		 * @param	textOrHTML
		 * @param	isHTML
		 * @param	autoSize
		 * @return
		 */
		protected function setTextFieldContent(field:TextField, textOrHTML:String, isHTML:Boolean = false, autoSize:Boolean = true):void {
			return TextUtils.setTextFieldContent(field, textOrHTML, isHTML, autoSize);
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
			if (textToParse){
				var matches:Array = textToParse.match(/%%\w+%%/g);
				
				for each (var variable:String in matches) {
					variable = variable.replace(/%/g, "");
					textToParse = textToParse.replace(new RegExp("%%" + variable + "%%"), getTextVariable(variable, variables));
				}
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
	}

}