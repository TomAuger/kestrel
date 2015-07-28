package com.zeitguys.mobile.app.model {
	import com.zeitguys.util.DebugUtils;
	import flash.net.URLRequest;
	import flash.text.StyleSheet;
	import flash.utils.getQualifiedClassName;
	
	/**
	 * ...
	 * @author TomAuger
	 */
	public class CSSLoaderAsset extends TextLoaderAsset {
		
		protected var _cssContent:StyleSheet = new StyleSheet();
		
		/**
		 * Return the StyleSheet object
		 * 
		 * @return StyleSheet
		 */
		public function get stylesheet():StyleSheet {
			return _cssContent;
		}
		
		public function CSSLoaderAsset(urlRequest:URLRequest, onLoadCompleteCallback:Function = null, onLoadErrorCallback:Function = null) {
			super(urlRequest, '', onLoadCompleteCallback, onLoadErrorCallback);
		}
		
		override protected function loadComplete():void {
			_cssContent.parseCSS(_urlLoader.data);
		}
	
		override protected function doLoadCompleteCallback():void {
			_onLoadComplete(_cssContent);
		}
		
		override protected function __destroy():void {
			_cssContent = null;
			super.__destroy();
		}
	}

}