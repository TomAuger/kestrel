package com.zeitguys.app.model {
	import flash.display.Bitmap;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.net.URLRequest;
	import flash.system.LoaderContext;
	import flash.system.ApplicationDomain
	
	/**
	 * Loads an image and returns the bitmap.
	 * 
	 * onLoadCompleteCallback(imageBitmap:Bitmap, assetDidLoad:Boolean);
	 * 
	 * @author TomAuger
	 */
	public class ImageLoaderAsset extends ClipLoaderAsset {
		protected var _imageBitmap:Bitmap;
		
		public function ImageLoaderAsset(urlRequest:URLRequest, onLoadCompleteCallback:Function = null, onLoadErrorCallback:Function = null) {
			super(urlRequest, onLoadCompleteCallback, onLoadErrorCallback);
		}
		
		override protected function loadComplete():void {
			if ( _clipLoaderInfo.content is Bitmap ) {
				_imageBitmap = Bitmap(_clipLoaderInfo.content);
			} else {
				trace("Image Loader error: content is not a Bitmap! It is a: " + _clipLoaderInfo.content.toString());
			}
		}
		
		override protected function doLoadCompleteCallback():void {
			_onLoadComplete(_imageBitmap, _assetLoaded);
		}
		
		override protected function doLoadErrorCallback(errorMsg:String):void {
			_onLoadError(errorMsg);
		}
		
		override protected function __destroy():void {
			_imageBitmap = null;
			
			super.__destroy();
		}
	
	}

}