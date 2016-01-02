package com.zeitguys.mobile.app.model {
	import com.zeitguys.mobile.app.AppBase;
	import flash.display.DisplayObject;
	import com.zeitguys.mobile.app.view.ScreenView;
	import flash.errors.IllegalOperationError;
	
	/**
	 * The App's Main Screen is the one in the base FLA that is compiled in flash to author/publish the app.
	 * 
	 * If this main app contains ScreenViews in addition to its splash screen, then use MainScreenBundle instead of ScreenBundle.
	 * This strips out all clips from the SWF with the exception of the loader screen. 
	 * 
	 * Implements a quasi-Singleton pattern, in that it checks to see whether you've instantiated it more than
	 * once and throws an IllegalOperationError if it does.
	 * 
	 * @author TomAuger
	 */
	public class MainScreenBundle extends ScreenBundle {
		protected static var __mainSWF:AppBase;
		protected static var __instance:MainScreenBundle;
		
		public function MainScreenBundle(id:String, screens:Vector.<ScreenView>) {
			if (! __instance){
				if (__mainSWF) {
					super(id, __mainSWF, screens);
					__instance = this;
				} else {
					throw new IllegalOperationError("Cannot instantiate MainScreenBundle until the App has called `setApp()`");
				}
			} else {
				throw new IllegalOperationError("Cannot instantiate more than one MainScreenBundle per App.");
			}
		}
		
		/**
		 * AppBase uses this to set a reference to the main SWF, so we don't have to do it in our ScreenList
		 * when defining the MainScreenBundle.
		 */
		public static function setApp(swf:AppBase):void {
			__mainSWF = swf;
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