package com.zeitguys.mobile.app.view.asset.ui {
	import com.zeitguys.mobile.app.view.asset.AssetView;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	
	/**
	 * Base View for all Button-type assets.
	 * 
	 * Of particular interest:
	 * 
	 * @see onButtonDown()
	 * @see onButtonUp()
	 * @see doOnClick()
	 * 
	 * @author TomAuger
	 */
	public class ButtonAssetView extends AssetView {
		public static const EVENT_BUTTON_PRESS:String = 'button-pressed';
		
		protected var _onClickCallback:Function;
		
		private var _clickableElement:DisplayObject;
		
		public function ButtonAssetView(clipName:String, onClickCallback:Function = null, disabled:Boolean = false, localizableTextFieldName:String = "") {
			_onClickCallback = onClickCallback;
			
			super(clipName, disabled, localizableTextFieldName);
		}
		
		
		
		/**
		 * Override in child classes to change the visual state when the button is down
		 */
		protected function onButtonDown():void {
			trace("[B] Button DOWN");
		}
		
		/**
		 * Override in child classes to revert the visual state
		 */
		protected function onButtonUp():void {
			trace("[B] Button UP");
		}
		
		/**
		 * Override in child classes if you wish to add arguments passed to the callback.
		 */
		protected function doOnClick():void {
			trace("[B] CLICK! (" + this + ":" + name + ")");
			
			if (_onClickCallback is Function) {
				_onClickCallback();
			}
		}
		
		
		
		override public function init():void {
			_clickableElement = clip;
			
			super.init();
		}
		
		override public function activate() {
			if (isActivatable) {
				trace("  ++ ADDING event listeners for " + name);
				if (_clickableElement is DisplayObjectContainer) {
					DisplayObjectContainer(_clickableElement).mouseChildren = false;
					DisplayObjectContainer(_clickableElement).mouseEnabled = true;
				}
				
				if (_clickableElement is Sprite) {
					Sprite(_clickableElement).buttonMode = true;
				}
				_clickableElement.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown, false, 0, true);
			}
			
			super.activate();
		}
		
		override public function deactivate() {
			if (isDeactivatable) {
				trace("  -- REMOVING event listeners for " + name);
				if (_clickableElement is DisplayObjectContainer) {
					DisplayObjectContainer(_clickableElement).mouseEnabled = false;
				}
				
				if (_clickableElement is Sprite) {
					Sprite(_clickableElement).buttonMode = false;
				}
			
				_clickableElement.removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDown, false);
				_clickableElement.stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUp, false);
				
				// Reset the visual state, for kicks.
				onButtonUp();
			}
			
			super.deactivate();
		}
		
		
		
		protected function onMouseDown(event:MouseEvent):void {
			_clickableElement.removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			
			if (isActive){
				onButtonDown();
			}
			
			// Separate this, in case it's onButtonDown() that disables the button! (It shouldn't but you never know.)
			if (isActive) {
				_clickableElement.stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			}
		}
		
		/**
		 * Respond to MOUSE_UP event and dispatch `onButtonUp()` and `doOnclick()` if not disabled.
		 * 
		 * @param	event
		 */
		protected function onMouseUp(event:MouseEvent):void {
			_clickableElement.stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			
			if (isActive) {
				onButtonUp();
				
				// It's only a press if the release occurs over the actual button.
				if (event.target == _clickableElement){
					doOnClick();
					
					dispatchEvent(new Event(EVENT_BUTTON_PRESS));
				}
			}
			
			// Separate this in case doOnClick initiates a screen switch.
			if (isActive) {
				_clickableElement.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			}
		}
		
		/**
		 * Override the default autoSize and force autoSize to false, to allow proper centering.
		 * 
		 * @param	field
		 * @param	textOrHTML
		 * @param	isHTML
		 * @param	autoSize
		 */
		override protected function setTextFieldContent(field:TextField, textOrHTML:String, isHTML:Boolean = false, autoSize:Boolean = false):void {
			super.setTextFieldContent(field, textOrHTML, isHTML, false);
		}
		
		
		public function get label():String {
			if (_textField) {
				return _textField.text;
			}
			
			return name;
		}
		
		public function set label(text:String):void {
			if (_textField) {
				_textField.text = text;
			}
		}
	}

}