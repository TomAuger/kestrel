package com.zeitguys.ios {
	import com.zeitguys.app.AppBase;
	import flash.geom.Rectangle;
	import flash.system.Capabilities;
	
	/**
	 * Handles everything to do with iOS Apps.
	 * @author TomAuger
	 * @TODO refactor non-iOS stuff into AppBase
	 */
	public class App extends AppBase {
		protected const STATUS_BAR_HEIGHT_NORMAL:uint = 20;
		protected const STATUS_BAR_HEIGHT_RETINA:uint = 40;
		
		public function App() {
			super();
		}
		
		override public function get statusBarHeight():uint {
			return STATUS_BAR_HEIGHT_RETINA;
		}
		
		/**
		 * iOS 6 apps need to accommodate the status bar, while iOS 7+ apps tuck under the status bar.
		 * @param	orientation
		 * @param	OSAdjustment
		 * @return
		 */
		override public function getDevicePixelDimensions(orientation:String = ORIENTATION_PORTRAIT, OSAdjustment:Boolean = true):Rectangle {
			var dimensions:Rectangle = super.getDevicePixelDimensions(orientation, OSAdjustment);
					
			if (osVersion < 7 && OSAdjustment) {
				// ScrollingScreenView works better without. Not liking this, but we'll leave it for now.
				//dimensions.height -= statusBarHeight;
			}
			
			return dimensions;
		}
		
		/**
		 * The amount that TransitionManager should be adjusted to accommodate the status bar in iOS 6, and on the simulator.
		 */
		override public function get contentOffset():int {
			if ("iPhone OS" == deviceOS && osVersion < 7 || "Windows" == deviceOS) {
				return -statusBarHeight;
			} else {
				return 0;
			}
		}
		
		/**
		 * It appears that the timer starts counting the instant the app starts to "grow",
		 * so we're really only ready after about 20 frames or so.
		 */
		override protected function resetResumeDelayFrames():void {
			_resumeAppDelayFrames = 20;
		}
	}

}