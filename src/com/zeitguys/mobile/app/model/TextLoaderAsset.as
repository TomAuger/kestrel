package com.zeitguys.mobile.app.model {
	import flash.net.URLRequest;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.net.URLLoader;
	
	/**
	 * ...
	 * @author TomAuger
	 */
	public class TextLoaderAsset extends LoaderAsset {
		protected var _languageCode:String;
		protected var _urlLoader:URLLoader = new URLLoader();
		
		protected var _content:Object;
		
		public function TextLoaderAsset(urlRequest:URLRequest, languageCode:String, onLoadCompleteCallback:Function = null, onLoadErrorCallback:Function = null) {
			_languageCode = languageCode;
			
			super(urlRequest, onLoadCompleteCallback, onLoadErrorCallback);
			
			_urlLoader.addEventListener(ProgressEvent.PROGRESS, onLoadProgress);
			_urlLoader.addEventListener(Event.COMPLETE, onLoadComplete);
			_urlLoader.addEventListener(IOErrorEvent.IO_ERROR, onLoadError);
		}
		
		override public function load():Boolean {
			trace("Loading Text Asset: " + _request.url);
			
			try {
				_urlLoader.load(_request);
			} catch (error:String) {
				trace("LoaderAsset load error: " + error);
				
				doLoadErrorCallback(error.toString());
				
				_loader.setItemLoadError(this, error.toString());
				
				__destroy();
				
				return false;
			}
			
			return true;
		}
		
		override protected function loadComplete():void {
			_content = _urlLoader.data;
		}
	
		override protected function doLoadCompleteCallback():void {
			_onLoadComplete(_languageCode, _content);
		}
		
		
		override protected function __destroy():void {
			if (_urlLoader) {
				_urlLoader.removeEventListener(ProgressEvent.PROGRESS, onLoadProgress);
				_urlLoader.removeEventListener(Event.COMPLETE, onLoadComplete);
				_urlLoader.removeEventListener(IOErrorEvent.IO_ERROR, onLoadError);
			}
			
			_urlLoader = null;
			_content = null;
			
			super.__destroy();
		}
	}

}