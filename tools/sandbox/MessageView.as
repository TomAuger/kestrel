package
{
	import com.zeitguys.util.DebugUtils;
	
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.text.TextField;
	
	/**
	 * Handy class for converting a textfield on the stage into a message area that you can
	 * send debug messages to. Particularly useful for mobile development where you don't want
	 * to send everything to trace.
	 * 
	 * Use `msg.add()` to add a new message to the queue.
	 * 
	 * If you send an Object to the MessageView, it will use DebugUtils to trace the DisplayList
	 * (if it's a DisplayObject), or print_r (thanks Eric!) if it's some other kind of Object.
	 * 
	 * @author Tom Auger
	 */
	public class MessageView extends EventDispatcher 
	{
		private static const TEXTFIELD_NAME:String = 'txt_message';
		
		protected var _autoscroll:Boolean = true;
		
		private static var __instance;
		private var _text:TextField;
		
		
		public static function getInstance():MessageView {
			if (! __instance) {
				__instance = new MessageView();
			}
			
			return __instance;
		}
		
		public function init(messageClip:MovieClip, autoscroll:Boolean = true):void {
			var child:DisplayObject = messageClip.getChildByName(TEXTFIELD_NAME);
			if (child && child is TextField) {
				_text = TextField(child);
				_text.text = "";
			} else {
				throw new Error("Cannot find TextField named '" + TEXTFIELD_NAME + "'");
			}
			
			_autoscroll = autoscroll;
		}
		
		public function add(message:*):void {
			if (! (message is String)) {
				if (message is DisplayObject) {
					message = DebugUtils.debugClip(DisplayObject(message), false);
				} else {
					message = DebugUtils.print_r(message, "", false);
				}
			}
			
			
			if (_text) {
				_text.appendText(message + "\n");
			} else {
				throw new Error("MessageView has not yet been initialized with init()");
			}
			
			if (_autoscroll) {
				_text.scrollV = _text.maxScrollV;
			}
		}
		
		public function set autoscroll(scroll:Boolean):void {
			_autoscroll = scroll;
		}
		
		public function MessageView() 
		{
			
		}
		
	}

}