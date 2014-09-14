package com.zeitguys.ios.view {
	import com.zeitguys.app.model.vo.ModalButtonData;
	import com.zeitguys.app.view.ModalView;
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	
	/**
	 * ...
	 * @author TomAuger
	 */
	public class IOSModalView extends ModalView {
		protected var _overlay:Sprite = new Sprite();
		
		public function IOSModalView(parentClip:DisplayObjectContainer, bodyText:String, buttons:Vector.<ModalButtonData> = null) {
			super(parentClip, bodyText, buttons);
		}
		
		override protected function displayModal():void {
			renderOverlay();
			
			_parent.addChild(_overlay);
			_parent.addChild(_clip);
		}
		
		protected function renderOverlay():void {
		
		}
		
		override protected function removeModal():void {
			_parent.removeChild(_clip);
			_parent.removeChild(_overlay);
		}
		
		override protected function __destroy():void {
			super.__destroy();
			
			_overlay = null;
		}
	}

}