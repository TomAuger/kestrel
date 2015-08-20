package {
	import com.zeitguys.util.DebugUtils;
	
	import flash.desktop.NativeApplication;
	import flash.events.Event;
	import flash.display.MovieClip;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.display.StageQuality;
	import flash.ui.Multitouch;
	import flash.ui.MultitouchInputMode;
	
	import MessageView;
	
	/**
	 * Simple mobile sandbox base class for getting up and running and scratching out an idea
	 * or working out a problem, unfettered by Kestrel.
	 * 
	 * @author Tom Auger
	 */
	public class MobileSandboxBase extends MovieClip {
		private var msg:MessageView;
		
		public function MobileSandboxBase() {
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			stage.quality = StageQuality.BEST;
			
			stage.addEventListener(Event.DEACTIVATE, deactivate);
			
			// touch or gesture?
			Multitouch.inputMode = MultitouchInputMode.TOUCH_POINT;
			
			// Get our MessageView instance so we can write stuff out to the device easily.
			msg = MessageView.getInstance();
			msg.init(MovieClip(this.getChildByName("mc_message_box")));
			
			start();
		}
		
		/**
		 * Override in child classes to actually do stuff!
		 */
		protected function start() {
			msg.add("Welcome to the Mobile Sandbox!");
		}
		
		private function deactivate(e:Event):void 
		{
			// make sure the app behaves well (or exits) when in background
			NativeApplication.nativeApplication.exit();
		}
		
	}
	
}