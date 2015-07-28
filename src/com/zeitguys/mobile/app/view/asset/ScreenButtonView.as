package com.zeitguys.mobile.app.view.asset {
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	/**
	 * ...
	 * @author TomAuger
	 */
	public class ScreenButtonView extends ScreenAssetView {
		public static const EVENT_BUTTON_PRESS:String = 'button-pressed';
		
		private var _onPressCallback:Function;
		
		public function ScreenButtonView(clipName:String, onPressCallback:Function = null, disabled:Boolean = false) {
			_onPressCallback = onPressCallback;
			
			super(clipName, disabled);
		}
		
		override public function init():void {
			_clip.mouseChildren = false;
			
			super.init();
		}
		
		override public function activate() {
			_clip.addEventListener(MouseEvent.MOUSE_UP, onMouseUp, false, 0, true);
			
			super.activate();
		}
		
		override public function deactivate() {
			_clip.removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			
			super.deactivate();
		}
		
		protected function onMouseUp(event:MouseEvent):void {
			dispatchEvent(new Event(EVENT_BUTTON_PRESS));
			
			doOnPressCallback();
		}
		
		protected function doOnPressCallback():void {
			if (_onPressCallback is Function) {
				_onPressCallback();
			}
		}
	}

}