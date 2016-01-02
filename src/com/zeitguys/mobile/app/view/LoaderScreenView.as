package com.zeitguys.mobile.app.view 
{
	import assets.ProgressBarAssetView;
	import com.zeitguys.mobile.app.model.AssetLoader;
	import com.zeitguys.mobile.app.model.event.AssetLoaderEvent;
	import com.zeitguys.mobile.app.model.ScreenBundle;
	import com.zeitguys.mobile.app.view.ScreenView;
	import com.zeitguys.mobile.app.view.ViewBase;
	
	/**
	 * Base class for Loader screens.
	 * @author Tom Auger
	 */
	public class LoaderScreenView extends ScreenView {
		protected var _assetLoader:AssetLoader = AssetLoader.getInstance();
		protected var _progressPercent:Number = -1;
		
		public function LoaderScreenView(screenClip:*, bundle:ScreenBundle=null) {
			super(screenClip, bundle);
		}
		
		override public function activate():void {
			super.activate();
			
			_assetLoader.addEventListener(AssetLoaderEvent.LOADING_PROGRESS, setLoadProgress, false, 0, true);
		}
		
		override public function deactivate():void {
			_assetLoader.removeEventListener(AssetLoaderEvent.LOADING_PROGRESS, setLoadProgress);
			
			super.deactivate();
		}
		
		protected function setLoadProgress(event:AssetLoaderEvent):void {
			_progressPercent = event.progressPercent;
			
			onLoadProgress(_progressPercent, event.asset.assetName, event.asset.assetURL, event.data.bytesLoaded, event.data.bytesTotal);
		}
		
		/**
		 * Child classes can override this to update a progress bar, update some
		 * text on the screen, etc.
		 * 
		 * @see AssetLoaderEvent and AssetLoader for more info on progressData
		 * 
		 * @param	progress Number (from 0..1) where 1 = 100% loaded
		 * @param	currentAssetName The name (last part of URL) of the asset currently being loaded
		 * @param	currentAssetURL The currently loaded asset's URL
		 */
		protected function onLoadProgress(progress:Number, currentAssetName:String, currentAssetURL:String, bytesLoaded:uint, bytesTotal:uint):void {
			trace("... " + (Math.round(progress * 10000)/100) + "% Loaded (" + currentAssetName + ")");
		}
	}

}