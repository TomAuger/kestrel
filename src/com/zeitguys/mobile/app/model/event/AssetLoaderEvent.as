package com.zeitguys.kestrel.app.model.event {
	import com.zeitguys.kestrel.app.model.AssetLoader;
	import com.zeitguys.kestrel.app.model.LoaderAsset;
	import flash.events.Event;
	
	/**
	 * Event called by AssetLoader.
	 * @author Tom Auger
	 */
	public class AssetLoaderEvent extends Event {
		public static var ASSET_LOADED:String = 'asset-loaded'; // A specific asset has been loaded
		public static var ASSET_LOAD_ERROR:String = 'asset-load-error';
		public static var LOADING_COMPLETE:String = 'loading-complete'; // The queue is completely emptied (does not necessarily mean all assets loaded successfully).
		public static var LOADING_PROGRESS:String = 'asset-loading-progress'; // Dispatched regularly during loading. Data contains total bytes and progress bytes.
		
		private var _target:LoaderAsset;
		private var _loader:AssetLoader;
		private var _data:Object = {};
		
		/**
		 * 
		 * @param	type
		 * @param	loader A reference to the AssetLoader
		 * @param	asset Optional. The asset that this even targets. LOADING_COMPLETE is for the entire queue, so will not contain a reference to a LoaderAsset item.
		 * @param	data Optional. An object that can contain information specific to the event. At the moment, it is up to the Dispatching class to determine what goes in this data Object.
		 * @param	bubbles Default
		 * @param	cancelable Default
		 */
		public function AssetLoaderEvent(type:String, loader:AssetLoader, asset:LoaderAsset = null, data:Object = null, bubbles:Boolean = false, cancelable:Boolean = false):void {
			super(type, bubbles, cancelable);
			_target = asset;
			_loader = loader;
			if (data){
				_data = data;
			}
		}
		
		public function get asset():LoaderAsset {
			return _target;
		}
		
		public function get loader():AssetLoader {
			return _loader;
		}
		
		public function get data():Object {
			return _data;
		}
		
		override public function clone():Event {
			return new AssetLoaderEvent(type, _loader, _target, bubbles, cancelable);
		}
		
		override public function toString():String {
			return formatToString("AssetLoaderEvent", "type", "loader", "target", "bubbles", "cancelable", "eventPhase");
		}
	}
}