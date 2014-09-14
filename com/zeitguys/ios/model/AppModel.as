package com.zeitguys.ios.model 
{
	import flash.errors.IllegalOperationError;
	/**
	 * Defines pretty much everything iOS-y we need to know about the app.
	 * 
	 * 
	 * @author TomAuger
	 */
	public class AppModel {
		private static var __instance:AppModel;
		
		public static const APP_STATE_RUNNING:String = 'app-running';
		public static const APP_STATE_PAUSED:String = 'app-paused';
		public static const APP_STATE_INITIALIZING:String = 'app-initializing';
		
		
		private var _appState:String;
		private var _screenHistory:Array = new Array();
		
		public function get_instance():AppModel {
			if (! __instance) {
				__instance = new AppModel();
			}
			
			return __instance;
		}
		
		/**
		 * Constructor, if you're bad, you get to use this once. But generally, avoid.
		 */
		public function AppModel() {
			if (__instance) {
				throw new IllegalOperationError("Singleton. Please use get_instance().");
			} else {
				__instance = this;
			}
		}
		
	}

}