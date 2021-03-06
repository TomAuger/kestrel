package com.zeitguys.mobile.app.view 
{
	import com.zeitguys.mobile.app.model.ScreenBundle;
	import com.zeitguys.mobile.ios.MultiResolutionApp;
	import flash.events.Event;
	
	/**
	 * ...
	 * @author TomAuger
	 */
	public class MultiResolutionScreenView extends ScreenView {
		
		public function MultiResolutionScreenView(clip:*, bundle:ScreenBundle=null) {
			super(clip, bundle);
		}
		
/*		override protected function onClipLoaded():void {
			// This is a good time to set the asset scale
			if (app is MultiResolutionApp) {
				var assetScale:Number = MultiResolutionApp(app).getAssetScale();
				if (1 != assetScale) {
					_clip.scaleX = _clip.scaleY = assetScale;
				}
			}
			
			super.onClipLoaded();
		}*/
		
		/**
		 * Returns the scale multiplier that should be used on assets (esp loaded images).
		 * 
		 * @TODO Allow recognition of asset resolution to change the value that's returned.
		 * 
		 * @param	assetResolution Not currently supported.
		 * @return
		 */
		public function getAssetScale(assetResolution:String = ""):Number {
			if (isDeviceRetina) {
				return 1;
			}
			// If the app is not retina, we need to scale UP assets to fit the SWF size (Retina)
			return 2;
		}
		
		public function get isDeviceRetina():Boolean {
			return MultiResolutionApp(app).isRetina;
		}
	}

}