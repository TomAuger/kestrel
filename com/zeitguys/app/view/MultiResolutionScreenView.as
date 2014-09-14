package com.zeitguys.app.view 
{
	import com.zeitguys.app.model.ScreenBundle;
	import com.zeitguys.ios.MultiResolutionApp;
	import flash.events.Event;
	
	/**
	 * ...
	 * @author TomAuger
	 */
	public class MultiResolutionScreenView extends ScreenView 
	{
		
		public function MultiResolutionScreenView(clip:*, bundle:ScreenBundle=null) {
			super(clip, bundle);
		}
		
		override protected function onClipLoaded():void {
			// This is a good time to set the asset scale
			if (router.app is MultiResolutionApp) {
				var assetScale:Number = MultiResolutionApp(_screenRouter.app).getAssetScale();
				if (1 != assetScale) {
					_clip.scaleX = _clip.scaleY = assetScale;
				}
			}
			
			super.onClipLoaded();
		}
		
		public function getAssetScale(resolution:String = ""):Number {
			if (MultiResolutionApp(router.app).isRetina) {
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