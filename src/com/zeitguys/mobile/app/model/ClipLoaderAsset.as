package com.zeitguys.kestrel.app.model {
	import com.zeitguys.util.ObjectUtils;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.net.URLRequest;
	import flash.events.ProgressEvent;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.system.LoaderContext;
	import flash.utils.getQualifiedClassName;
	import flash.system.ApplicationDomain;
	
	/**
	 * ...
	 * @author TomAuger
	 */
	public class ClipLoaderAsset extends LoaderAsset {
		protected var _clipLoader:Loader;
		protected var _clipLoaderInfo:LoaderInfo;
		
		public function ClipLoaderAsset(urlRequest:URLRequest, onLoadCompleteCallback:Function = null, onLoadErrorCallback:Function = null) {
			super(urlRequest, onLoadCompleteCallback, onLoadErrorCallback);
		
			_clipLoader = new Loader();
			_clipLoaderInfo = _clipLoader.contentLoaderInfo;
				
			_clipLoaderInfo.addEventListener(ProgressEvent.PROGRESS, onLoadProgress);
			_clipLoaderInfo.addEventListener(Event.COMPLETE, onLoadComplete);
			_clipLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onLoadError);
		}
		
		override public function load():Boolean {
			trace("Loading Asset: " + _request.url + " with " + ObjectUtils.getClassName(this));
	
			try {
				_clipLoader.load(_request, new LoaderContext(false, ApplicationDomain.currentDomain, null));
			} catch (error:String) {
				trace("LoaderAsset load error: " + error);
				
				doLoadErrorCallback(error.toString());
				
				_loader.setItemLoadError(this, error.toString());
				
				__destroy();
				return false;
			}
			
			return true;
		}
		
		
		
		override protected function __destroy():void {
			if (_clipLoaderInfo) {
				_clipLoaderInfo.removeEventListener(ProgressEvent.PROGRESS, onLoadProgress);
				_clipLoaderInfo.removeEventListener(Event.COMPLETE, onLoadComplete);
				_clipLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, onLoadError);
			}
			
			_clipLoader = null;
			_clipLoaderInfo = null;
			
			super.__destroy();
		}
	
	}

}