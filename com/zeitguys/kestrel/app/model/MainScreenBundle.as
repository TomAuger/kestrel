package com.zeitguys.kestrel.app.model {
	import flash.display.DisplayObject;
	import com.zeitguys.kestrel.app.view.ScreenView;
	
	/**
	 * The App's Main Screen is the one in the base FLA that is compiled in flash to author/publish the app.
	 * 
	 * If this main app contains ScreenViews in addition to its splash screen, then use MainScreenBundle instead of ScreenBundle.
	 * This strips out all clips from the SWF with the exception of the loader screen. 
	 * 
	 * @author TomAuger
	 */
	public class MainScreenBundle extends ScreenBundle {
		
		public function MainScreenBundle(id:String, swf:*, screens:Vector.<ScreenView>) {
			super(id, swf, screens);
		
		}
		
		override protected function onScreensPrepared():void {
			trace("STRIPPING out main screen bundle children.");
			// strip out any children of the host SWF EXCEPT for the loader screen!
			var toDelete:Vector.<DisplayObject> = new Vector.<DisplayObject>;
			
			for (var i:uint = 0, l:uint = _swf.numChildren; i < l; ++i) {
				var clip:DisplayObject = _swf.getChildAt(i);
				
				if ("loader" != clip.name) {
					toDelete.push(clip);
				}
			}
			
			for each (clip in toDelete) {
				_swf.removeChild(clip);
			}
		}
	
	}

}