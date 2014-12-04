package com.zeitguys.kestrel.app.controller {
	import com.zeitguys.kestrel.app.view.ScreenView;
	import com.zeitguys.kestrel.app.view.ViewBase;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.events.EventDispatcher;
	import flash.events.MouseEvent;
	import flash.utils.Dictionary;
	
	/**
	 * Save for a rainy day.
	 * 
	 * Controller class that collects all button click logic and centralizes scroll detection.
	 * 
	 * Incomplete. Got bogged down in _active and _disabled logic as usual.
	 * 
	 * @author TomAuger
	 */
	public class ButtonController extends EventDispatcher {
		// Workaround. App library needs some kind of scrolling screen view or something. Maybe the App should know it's scrolling or something.
		private const EVENT_SCROLL_STATUS_CHANGED = 'scroll-status-changed';
		
		protected var _clickableItems:Vector.<DisplayObject> = new Vector.<DisplayObject>;
		protected var _itemCallbacks:Dictionary = new Dictionary(true);
		protected var _screen:ScreenView;
		
		private var _disabled:Boolean;
		private var _isScrolling:Boolean;
		private var _active:Boolean;
		
		public function ButtonController(parentItem:ScreenView) {
			_parentItem = parentItem;
		}
		
		public function registerClickableItem(clip:DisplayObject, onClickCallback:Function = null, onPressCallback:Function = null, onReleaseCallback:Function = null) {
			if (_clickableItems.indexOf(clip) == -1) {
				_clickableItems.push(clip);
				_itemCallbacks[clip] = {
					onClick : onClickCallback,
					onPress : onPressCallback,
					onRelease : onReleaseCallback
				}
				
				// Disable mouse children for the clickable item.  Consider making this optional.
				if (clip is DisplayObjectContainer){
					DisplayObjectContainer(clip).mouseChildren = false;
				}
			}
		}
	
		public function activate():void {
			var clip:DisplayObject;
			
			trace("  ++ ADDING event listeners for buttons in " + _parentItem.clipName);
			for each(clip in _clickableItems){
				clip.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown, false, 0, true);
			}
		}
		
		public function deactivate():void {
			var clip:DisplayObject;
			
			trace("  -- REMOVING event listeners for " + _clipName);
			for each(clip in _clickableItems){
				clip.removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDown, false);
				clip.removeEventListener(MouseEvent.MOUSE_UP, onMouseUp, false);
			}
			
			_screen.removeEventListener('scroll-status-changed', onScrollStatus, false);
		}
		
		
		
		
		protected final function getCallback(clip:DisplayObject, callbackName:String):Function {
			var callbacks:Object = _itemCallbacks(clip);
			
			if (callbacks.hasOwnProperty(callbackName) && callbacks[callbackName] is Function) {
				return Function(callbacks[callbackName]);
			}
			
			return null;
		}
		
		protected function doCallback(clip:DisplayObject, callbackName):Boolean {
			var callback:Function = getCallback(clip, callbackName);
			
			if (callback && callback is Function) {
				callback();
				
				return true;
			}
			
			return false;
		}
		
		
		/**
		 * @TODO - from here on down, incomplete. The code is still straight out of ContentButtonView.
		 * 
		 * @param	event
		 */
		protected function onMouseDown(event:MouseEvent):void {
			trace("                                                              Mouse Down. Removing listener");
			clip.removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			
			if (! _disabled){
				doCallback(event.currentTarget, "onPress");
			}
			
			// Separate this, in case it's the onMouseDown that disables the button!
			if (! _disabled) {
				trace("                                                              Adding Mouse Up listener to Stage");
				_clickableElement.stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
				
				// We need to be able to cancel a button press if the screen scrolls.
				if (screen is ScrollingScreenView) {
					trace("                                                              Adding Scroll listener");
					screen.addEventListener(ScrollingScreenView.EVENT_SCROLL_STATUS_CHANGED, onScrollStatus, false, 0, true);
					_isScrolling = ScrollingScreenView(screen).isScrolling;
				}
			} else {
				trace("                                                              Disabled. Doing nothing further");
			}
		}
		
		/**
		 * 
		 * @param	event
		 */
		protected function onScrollStatus(event:Event):void {
			if (ScrollingScreenView(screen).isScrolling) {
				trace("                                                              Scrolling. Removing Mouse Up listener from Stage");
				_isScrolling = true;
				_clickableElement.stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
				
				if (! _disabled) {
					onButtonUp();
				}
			} else {
				if (! _disabled) {
					trace("                                                              Not scrolling. removing Scroll listener. Adding Mouse Down listener");
					screen.removeEventListener(ScrollingScreenView.EVENT_SCROLL_STATUS_CHANGED, onScrollStatus, false);
					_clickableElement.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown, false, 0, true);
				}
			}
		}
		
		/**
		 * Respond to MOUSE_UP event and dispatch `onButtonUp()` and `doOnclick()` if not disabled.
		 * 
		 * @param	event
		 */
		protected function onMouseUp(event:MouseEvent):void {
			trace("                                                              Mouse Up. Removing listener from Stage");
			_clickableElement.stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			
			if (screen is ScrollingScreenView) {
				trace("                                                              Removing Scroll listener");
				screen.removeEventListener(ScrollingScreenView.EVENT_SCROLL_STATUS_CHANGED, onScrollStatus, false);	
			}
			
			if (! _disabled && _active) {
				trace("                                                              MOUSE - " + _clickableElement.name + " responding to MouseUp");
				onButtonUp();
				doOnClick();
				
				dispatchEvent(new Event(EVENT_BUTTON_PRESS));
			} else {
				trace("                                                              MOUSE - " + _clipName + " disabled; MouseUp ignored.");
			}
			
			// Separate check, in case doOnClick() disables the button (which will often be the case if the button click switches screens).
			if (! _disabled && _active) {
				trace("                                                              End of cycle. Adding Mouse Down listener");
				_clickableElement.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown, false, 0, true);
			}
		}
	}

}