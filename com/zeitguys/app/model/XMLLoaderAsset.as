package com.zeitguys.app.model {
	import flash.net.URLRequest;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.net.URLLoader;
	
	/**
	 * ...
	 * @author TomAuger
	 */
	public class XMLLoaderAsset extends TextLoaderAsset {
		
		protected var _xmlContent:XML;
		
		public function XMLLoaderAsset(urlRequest:URLRequest, languageCode:String, onLoadCompleteCallback:Function = null, onLoadErrorCallback:Function = null) {
			super(urlRequest, languageCode, onLoadCompleteCallback, onLoadErrorCallback);
		}
		
		override protected function loadComplete():void {
			_xmlContent = XML(_urlLoader.data);
		}
	
		override protected function doLoadCompleteCallback():void {
			_onLoadComplete(_languageCode, _xmlContent);
		}
		
		override protected function __destroy():void {
			_xmlContent = null;
			super.__destroy();
		}
	}

}