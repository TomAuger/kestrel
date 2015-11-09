package com.zeitguys.mobile.app.model {
	import flash.errors.IOError;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.net.URLRequest;
	/**
	 * A LoaderAsset represents one item that is loaded using the AssetLoader.
	 * This base class should be extended to accommodate different types of assets.
	 * 
	 * When overrideing this class to provide a specific asset loader, be sure to:
		 * Override the load() method
		 * Override the __destroy() method and then call super.__destroy()
		 * Override the onCallback methods to pass appropriate data back to the host class.
	 * 
	 * You can respond to a successful load or a load error in a couple of ways:
	 * 1. use the onLoadComplete and onLoadError callbacks. These can be defined in the constructor, or using the setter methods.
	 *    Use this approach if you are interested in specific asset.
	 * 2. listen for AssetLoaderEvents on the AssetLoader itself. 
	 *    The event's `asset` property contains a reference to the asset that just completed.
	 * 
	 * @author TomAuger
	 */
	public class LoaderAsset
	{
		protected var _request:URLRequest;
		protected var _loader:AssetLoader;
		
		protected var _assetLoaded:Boolean = false;
		protected var _onLoadComplete:Function;
		protected var _onLoadError:Function;
		
		protected var _lastBytesLoaded:uint = 0;
		
		/**
		 * Initialize the LoaderAsset. Optionally, add some callbacks for success and error. These are optional, and are not the only
		 * way to be notified when a load is complete.
		 * 
		 * @param	urlRequest
		 * @param	onLoadComplete Optional. Callback executed when load complete.
		 * @param	onLoadError Optional. Callback executed when a load error is encountered. If missing, will execute onLoadComplete, and it's up to the handler to check item.loaded, but won't have access to error message.
		 */
		public function LoaderAsset(urlRequest:URLRequest, onLoadCompleteCallback:Function = null, onLoadErrorCallback:Function = null) {
			_request = urlRequest;
			_onLoadComplete = onLoadCompleteCallback;
			_onLoadError = onLoadErrorCallback;
		}		
		
		/**
		 * Initiates loading of asset. Must be overridden in child AssetLoader class.
		 * 
		 * The code here doesn't really do anything, but shows you the basic structure of what you need to do with the load() method:
			 * 
			 * 1. Trace some output
			 * 2. Wrap a try...catch
			 * 3. Implement loading using whatever type of loader (URLLoader, Loader, SWFLoader etc) you are using
			 * 4. Handle load errors, calling the error callback and setting the AssetLoaders's load error
			 * 5. Destroy the object on load error
		 * 
		 * @return	Success.
		 */
		public function load():Boolean {
			trace("Loading Asset: " + _request.url);
			
			try {
				// Obviously, change this part to actually load something.
				throw new IOError("Loading method not implemented.");
			} catch (error:String) {
				trace("LoaderAsset load error: " + error);
				
				doLoadErrorCallback(error.toString());
				
				_loader.setItemLoadError(this, error.toString());
				
				// Don't forget the cleanup. We don't want a pile of AssetLoaders floating around in memory after their day in the sun is over.
				__destroy();
				
				return false;
			}
			
			return true;
		}
		
		/**
		 * Must be called by the AssetLoader class in order to give this asset a reference to its Loader.
		 * Used to notify the AssetLoader when a loadComplete or a loadError occurs.
		 */
		public function set loader(loader:AssetLoader):void {
			_loader = loader;
		}
		
		/**
		 * Maybe override in child classes.
		 * 
		 * Use this method to manipulate the Asset, for example, set its "loaded" property, store data, and
		 * assign the LoaderAsset.data to the appropriate property in the asset (for example, if it has a "clip" property).
		 */
		protected function loadComplete():void {
			
		}
		
		/**
		 * Execute the loadCompleteCallback, set by the class that initiated the load of this LoaderAsset
		 * 
		 * Override in child classes, if you wish to change the signature of the callback.
		 * function onLoadCompleteCallback(item:LoaderAsset, success:Boolean);
		 * 
		 * Note that if an error callback hasn't been defined, and an onLoadComplete callback has,
		 * the onLoadComplete callback will get executed. In this case, it is important to check
		 * the 'success' argument.
		 */
		protected function doLoadCompleteCallback():void {
			_onLoadComplete(this, _assetLoaded);
		}
		
		/**
		 * Override in child classes. Called before any _loadError callback is executed.
		 */
		protected function loadError():void {
			
		}
		
		/**
		 * Override in child classes to change signature of the onLoadError callback.
		 * Note that if an error callback has not been defined, we will call onLoadComplete even on load error.
		 */
		protected function doLoadErrorCallback(errorMsg:String):void {
			_onLoadError(this, errorMsg);
		}
		
		
		/**
		 * Returns the "loaded" status of the item. Items that have not been loaded, or have encountered a load error will return false;
		 */
		public function get loaded():Boolean {
			return _assetLoaded;
		}
		
		/**
		 * Returns the URL for this asset.
		 */
		public function get url():String {
			return _request.url;
		}
		
		
		/**
		 * Called by a progress in load.
		 * @param	event
		 */
		protected function onLoadProgress(event:ProgressEvent):void {
			var currentBytesLoaded:uint = event.bytesLoaded - _lastBytesLoaded;
			_loader.updateBytesLoaded(currentBytesLoaded);
			_lastBytesLoaded = event.bytesLoaded;
		}
		
		/**
		 * Called by a successful load.
		 * @param	event
		 */
		protected function onLoadComplete(event:Event):void {
			trace("Load complete: " + _request.url);
			
			_assetLoaded = true;
			
			loadComplete();
			
			if (_onLoadComplete is Function) {
				doLoadCompleteCallback();
			}
			_loader.setItemLoaded(this);
			
			__destroy();
		}
		
		/**
		 * Called by a URLLoader error. This is not the only place an error can be triggered - see try..catch within {@link #load()} method.
		 * @param	event
		 */
		protected function onLoadError(event:IOErrorEvent):void {
			trace("Loader error: " + event.text);
			
			_assetLoaded = false;
			
			loadError();
			if (_onLoadError is Function){
				doLoadErrorCallback(event.text);
			} else {
				if (_onLoadComplete is Function) {
					doLoadCompleteCallback();
				}
			}
			_loader.setItemLoadError(this, event.text);
			
			__destroy();
		}
		
		/**
		 * Important for memory management. When the LoaderAsset is complete, we don't want any references hanging around.
		 * The LoaderAsset is completely removed (in theory) and only the clip remains - having been transferred to the
		 * Screen or other element that required it.
		 */
		protected function __destroy():void {
			_loader = null;
			_request = null;
			
			_onLoadComplete = null;
			_onLoadError = null;
		}
		
		public function get assetURL():String {
			return _request.url;
		}
		
		public function get assetName():String {
			return assetURL.match(/[^\/\\]+$/)[0];
		}
		
	}

}