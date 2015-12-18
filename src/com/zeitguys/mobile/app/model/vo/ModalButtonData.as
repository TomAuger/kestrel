package com.zeitguys.mobile.app.model.vo {
	import flash.display.MovieClip;
	
	/**
	 * ...
	 * @author TomAuger
	 */
	public class ModalButtonData {
		protected var _clip:MovieClip;
		protected var _label:String;
		protected var _id:String;
		protected var _callback:Function;
		protected var _disabled:Boolean;
		
		public function ModalButtonData(id:String, label:String = "", callback:Function = null, clip:MovieClip = null, disabled:Boolean = false ) {
			_id = id;
			_clip = clip;
			_label = label;
			_disabled = disabled;
			
			if (callback is Function) {
				_callback = callback;
			}
		}
		
		public function get clip():MovieClip {
			return _clip;
		}
		
		public function set clip(mc:MovieClip):void {
			_clip = mc;
		}
		
		public function get hasClip():Boolean {
			return ! (_clip == null);
		}
		
		public function get label():String {
			return _label;
		}
		
		public function set label(l:String) {
			_label = label;
		}
		
		public function get id():String {
			return _id;
		}
		
		public function get callback():Function {
			return _callback;
		}
		
		public function get hasCallback():Boolean {
			if (_callback is Function) {
				return true;
			}
			
			return false;
		}
		
		public function get disabled():Boolean {
			return _disabled;
		}
		
		public function set disabled(off:Boolean):void {
			_disabled = off;
		}
	
	}

}