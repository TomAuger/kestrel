package com.zeitguys.mobile.ios {
	import flash.errors.IllegalOperationError;
	/**
	 * Defines iOS-specific multi-resolution detection and asset manipulation features.
	 * 
	 * @TODO This needs to come out of iOS and be abstracted into app. Then over-written with iOS-specific stuff like retina.
	 * I'll need to wait until I do an Android project before I get to this though, realistically.
	 * @author TomAuger
	 */
	public class MultiResolutionApp extends App {
		public static const RESOLUTION_NORMAL:String = "normal";
		public static const RESOLUTION_RETINA:String = "retina";
		
		private var _deviceResolution:String = RESOLUTION_RETINA;
		private var _assetResolution:String = RESOLUTION_RETINA;
		
		public function MultiResolutionApp(){
			super();
		}
		
		override protected function init():void {
			getDeviceResolution();
			trace("Device resolution detected as: " + _deviceResolution);
			
			super.init();
		}
		
		/**
		 * Cheesy method of determining device resolution.
		 * 
		 * @TODO more comprehensive testing across all cases, orientations and devices.
		 * 
		 * @return Device resolution string.
		 */
		private function getDeviceResolution():String {
			var width:uint = appWidth;
			
			if (width < 640) {
				_deviceResolution = RESOLUTION_NORMAL;
			} else {
				_deviceResolution = RESOLUTION_RETINA;
			}
			
			return _deviceResolution;
		}
		
		public function get deviceResolutionString():String {
			if (_deviceResolution) {
				return _deviceResolution;
			} else {
				throw new ReferenceError("MultiResolutionApp.deviceResolutionString() called before app added to stage. Can't determine resolution.");
			}
		}
		
		/**
		 * Use this method to scale any assets or math based on the device resolution and the asset resolution.
		 * 
		 * Asset resolution refers to the resolution (Retina / Normal) that an asset is saved as. In general, you'll use the 
		 * same rule for the entire app, so you should just set {@link /assetResolution} in your endpoint app class' constructor.
		 * 
		 * However, sometimes you'll know that an asset was saved at a specific resolution that may or may not match the
		 * overall application's resolution. In that case, provide `assetResolution` in the method arguments.
		 * 
		 * @param String Optional. One of RESOLUTION_NORMAL | RESOLUTION_RETINA
		 * 
		 * @return Multiplier. Generally apply it directly to `displayObject.scaleX` and `displayObject.scaleY`
		 */
		public function getAssetScale(assetResolution:String = ""):Number {
			assetResolution ||= _assetResolution;
			
			if (_deviceResolution && assetResolution) {
				if (_deviceResolution == assetResolution) {
					return 1;
				} else if (assetResolution == RESOLUTION_NORMAL) {
					return 2.0;
				} else {
					return 0.5;
				}
			} else {
				throw new IllegalOperationError("Attempting to call get assetScale() before setting device and asset resolution.");
			}
		}
		
		public function get isRetina():Boolean {
			var resolutionString:String = deviceResolutionString;
			
			if (RESOLUTION_RETINA == resolutionString) {
				return true;
			}
			
			return false;
		}
		
		public function set assetResolution(resolutionString:String):void {
			if ([RESOLUTION_NORMAL, RESOLUTION_RETINA].indexOf(resolutionString) == -1) {
				throw new RangeError("'" + resolutionString + "' is not a valid resolution string.");
			} else {
				_assetResolution = resolutionString;
			}
		}
		
		override public function get statusBarHeight():uint {
			if (RESOLUTION_NORMAL == _deviceResolution) {
				return STATUS_BAR_HEIGHT_NORMAL;
			} else {
				return STATUS_BAR_HEIGHT_RETINA;
			}
		}
	}

}