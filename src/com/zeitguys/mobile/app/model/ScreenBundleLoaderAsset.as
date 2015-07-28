package com.zeitguys.mobile.app.model {
	import flash.display.DisplayObjectContainer;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.net.URLRequest;
	import flash.system.ApplicationDomain;
	import flash.system.LoaderContext;
	
	/**
	 * ...
	 * @author TomAuger
	 */
	public class ScreenBundleLoaderAsset extends LoaderAsset {
		protected var _bundle:ScreenBundle;
		protected var _displayLoader:Loader;
		protected var _loaderInfo:LoaderInfo;
		
		/**
		 * A ScreenBundle can come pre-loaded (if it is on the main SWF). In this case, there will be no corresponding URLRequest
		 * @param	urlRequest Optional. The URL at which this bundle's SWF can be found, relative to the main app.
		 */
		public function ScreenBundleLoaderAsset(urlRequest:URLRequest = null, screenBundle:ScreenBundle = null, onLoadCompleteCallback:Function = null, onLoadErrorCallback:Function = null) {
			_bundle = screenBundle;
			
			if (urlRequest) {
				super(urlRequest, onLoadCompleteCallback, onLoadErrorCallback);
				
				_displayLoader = new Loader();
				_loaderInfo = _displayLoader.contentLoaderInfo;
				
				_loaderInfo.addEventListener(ProgressEvent.PROGRESS, onLoadProgress);
				_loaderInfo.addEventListener(Event.COMPLETE, onLoadComplete);
				_loaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onLoadError);
			}
		}
		
		/**
		 * Loads the SWF. Requires a bundle to be set, otherwise we have no way of knowing what to do with the asset once loaded.
		 * Some bundles come pre-loaded (like MainAssetBundle). If that's the case then just skip straight to {@link AssetLoader.setItemLoaded()}
		 * @return
		 */
		override public function load():Boolean {
			if (! _bundle) {
				throw new ReferenceError("ScreenBundleAssetLoader is missing its ScreenBundle.");
			} else {
				if (_bundle.loaded) {
					_loader.setItemLoaded(this);
					__destroy();
				} else {
					trace("Loading Bundle Asset: " + _request.url);
			
					try {
						_displayLoader.load(_request, new LoaderContext(false, ApplicationDomain.currentDomain, null));
					} catch (error:String) {
						trace("LoaderAsset load error: " + error);
						
						doLoadErrorCallback(error.toString());
						
						_loader.setItemLoadError(this, error.toString());
						
						__destroy();
						return false;
					}
					
					return true;
				}
			}
			
			return false;
		}
		
		override protected function loadComplete():void {
			if ( _loaderInfo.content is DisplayObjectContainer ){
				_bundle.asset = DisplayObjectContainer(_loaderInfo.content);
				_bundle.setBundleLoaded();
			}
		}
		
		override protected function doLoadCompleteCallback():void {
			_onLoadComplete(_bundle, _assetLoaded);
		}
		
		override protected function doLoadErrorCallback(errorMsg:String):void {
			_onLoadError(_bundle, errorMsg);
		}
		
		override protected function __destroy():void {
			if (_displayLoader) {
				_displayLoader.removeEventListener(ProgressEvent.PROGRESS, onLoadProgress);
				_displayLoader.removeEventListener(Event.COMPLETE, onLoadComplete);
				_displayLoader.removeEventListener(IOErrorEvent.IO_ERROR, onLoadError);
			}
			
			_displayLoader = null;
			_loaderInfo = null;
			_bundle = null;
			
			super.__destroy();
		}
	}

}