package com.zeitguys.mobile.app.view.asset 
{
	import com.zeitguys.mobile.app.error.FlashConstructionError;
	import com.zeitguys.mobile.app.view.ViewBase;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.globalization.NumberFormatter;
	import flash.text.TextField;
	
	/**
	 * Base class for all Kestrel "Assets". AssetViews decorate DisplayObjects.
	 * 
	 * @author Tom Auger
	 */
	public class AssetView extends ViewBase {
		
		protected var _numberFormatter:NumberFormatter;
		
		protected var _active:Boolean = false;
		protected var _disabled:Boolean = false;
		
		protected var _textFieldName:String;
		protected var _textField:TextField;
		
		public function AssetView(clip:*, disabled:Boolean = false, localizableTextFieldName:String = "") {
			if (clip is DisplayObject) {
				_clipName = DisplayObject(clip).name;
				_clip = clip;
			} else if (clip is String) {
				// Store the name. We can't find the actual clip until we have added the Screen
				_clipName = clip;
			} else {
				throw new ArgumentError("Constructor argument 'clip' must be a DisplayObject instance name (String) or an actual DisplayObject instance");
			}
			
			
			if (localizableTextFieldName) {
				_textFieldName = localizableTextFieldName;
			}
			
			_disabled = disabled;
		}
		
		
		
		/**
		 * Associate the appropriate DisplayObject with this asset, based on the clipName that was passed in the constructor.
		 * 
		 * @return
		 */
		protected function findClip(parent:DisplayObjectContainer):Boolean {
			if (! _clip){
				clip = getRequiredChildByName(_clipName, null, parent);
			}
			
			return true;
		}
		
		
		override public function set clip(clipDisplayObject:DisplayObject):void {
			super.clip = clipDisplayObject;
			
			if (_textFieldName && _clipName !== _textFieldName && clip is DisplayObjectContainer) {
				_textField = TextField(getRequiredChildByName(_textFieldName, TextField, DisplayObjectContainer(_clip)));
			} else {
				if (_clip is TextField) {
					_textField = TextField(_clip);
				}
			}
			
			// Store the clip's original coords.
			_clipOrigX = _clip.x;
			_clipOrigY = _clip.y;
		}
		
	}

}