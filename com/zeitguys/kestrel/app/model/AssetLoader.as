package com.zeitguys.kestrel.app.model {
	import com.zeitguys.kestrel.app.model.event.AssetLoaderEvent;
	import flash.errors.IllegalOperationError;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.filesystem.File;
	
	/**
	 * The Asset Loader base class is used to manage and enqueue all assets that should be loaded at runtime.
	 * 
	 * The AssetLoader is a Singleton. This allows screens (such as the loading screen) to access it and its events.
	 * 
	 * @see AssetLoaderEvent for a list of events that the AssetLoader can dispatch.
	 * 
	 * LoaderAssets are added to the queue using addItem.
	 * 
	 * @see LoaderAssets for the LoaderAsset base class. Individual asset types extend this class and provide specific functionality, particularly once the load is complete.
	 * 
	 * The Queue is kicked off automatically once the first asset is added to it. Other assets can be added during the load.
	 * 
	 * @TODO it is undefined what would happen if the queue emptied (loading complete) and then another asset were added to it afterward. This may become an issue in some cases.
	 * 
	 * @author TomAuger
	 */
	public class AssetLoader extends EventDispatcher 
	{
		private const STATUS_STOPPED = 'stopped';
		private const STATUS_STARTED = 'started';
		
		
		protected var _queue:Vector.<LoaderAsset> = new Vector.<LoaderAsset>;
		
		protected var _status:String = STATUS_STOPPED;
		protected var _queueCount:uint = 0;
		protected var _loadErrors:uint = 0;
		protected var _loadSuccesses:uint = 0;
		
		protected var _bytesLoaded:uint = 0;
		protected var _bytesTotal:uint = 0;
		
		private static var __instance:AssetLoader;
		
		public static function getInstance():AssetLoader {
			if (! __instance) {
				__instance = new AssetLoader();
			}
			
			return __instance;
		}
		
		public function AssetLoader() {
			if (__instance) {
				throw new IllegalOperationError("AssetLoader is a singleton. Access with getInstance()");
			}
		}
		
		/**
		 * Adds a LoaderAsset item to the queue. If the queue is empty, kick off loading.
		 * @param	item
		 * @return	The new length of the queue.
		 */
		public function addItem(item:LoaderAsset):uint {
			if (!File.applicationDirectory.resolvePath(item.url).exists)
				return 0;
				
			// Attach the loader reference to the LoaderAsset
			item.loader = this;
			
			// Add this files size to our overall loader progress
			updateBytesTotal(File.applicationDirectory.resolvePath(item.url).size);
			
			_queue.push(item);
			_queueCount++;
			
			if (item.loaded) {
				trace("Asset added to QUEUE (pre-loaded)");
				setItemLoaded(item);
			} else {
				trace("Asset added to QUEUE: '" + item.url + "'.");
			}
			
			if (STATUS_STOPPED == status) {
				loadNextItem();
				return _queue.length + 1; // loadNextItem() removes the item from the queue, so we have to send +1
			}
			
			return _queue.length;
		}
		
		/**
		 * Called by each LoaderAsset item when loading is complete.
		 * 
		 * Dispatches AssetLoaderEvent.ASSET_LOADED
		 * 
		 * @see AssetLoader.loadComplete()
		 * 
		 * @param	item
		 */
		public function setItemLoaded(item:LoaderAsset):void {
			_loadSuccesses++;
			
			dispatchEvent(new AssetLoaderEvent(AssetLoaderEvent.ASSET_LOADED, this, item));
			
			loadNextItem();
		}
		
		/**
		 * Called by each LoaderAsset when there is an error. Advances the queue.
		 * 
		 * @param	item
		 * @param	error
		 */
		public function setItemLoadError(item:LoaderAsset, error:String):void {
			_loadErrors++;
			
			dispatchEvent(new AssetLoaderEvent(AssetLoaderEvent.ASSET_LOAD_ERROR, this, item, { errorMsg:error } ));
			
			loadNextItem();
		}
		
		/**
		 * !! Current Unused
		 * Called by a LoaderAsset the first time it triggers a ProgressEvent.PROGRESS
		 * 
		 * @param	newBytesTotal
		 */
		public function updateBytesTotal(newBytesTotal:uint):void {
			this._bytesTotal += newBytesTotal;
		}
		/**
		 * Called by a LoaderAsset the first time it triggers a ProgressEvent.PROGRESS
		 * 
		 * @param	newBytesTotal
		 */
		public function setBytesTotal(newBytesTotal:uint):void {
			this._bytesTotal = newBytesTotal;
			this._bytesLoaded = 0;
			updateBytesLoaded(0);
		}
		
		/**
		 * Called by a LoaderAsset when progressing through a load.
		 * 
		 * @param	newBytesLoaded - the new amount of bytes loaded on this object
		 */
		public function updateBytesLoaded(newBytesLoaded:uint):void {
			this._bytesLoaded += newBytesLoaded;
			var eventData:Object = {
				 bytesLoaded: this._bytesLoaded,
				 bytesTotal: this._bytesTotal
			};
			dispatchEvent(new AssetLoaderEvent(AssetLoaderEvent.LOADING_PROGRESS, this, null, eventData));
		}
		
		
		protected function loadNextItem() {
			var asset:LoaderAsset;
			
			if (_queue.length) {
				if (STATUS_STOPPED == status) {
					status = STATUS_STARTED;
				}
				
				asset = _queue.shift();
				
				if (! asset.load()) {
					trace("Loading Error: " + asset.url);
					loadNextItem();
				}
			} else {
				closeQueue();
			}
		}
		
		/**
		 * Queue has finished loading all items. Some items may have errored out and thus been skipped, so use the data field to determine how many errors etc. there were.
		 */
		protected function closeQueue() {
			var eventData:Object = {
				 numQueued: _queueCount,
				 numSuccesses: _loadSuccesses,
				 numErrors: _loadErrors
			};
			
			trace("AssetLoader queue CLOSED. Queued: " + _queueCount + ", Successes: " + _loadSuccesses + ", Errors: " + _loadErrors);
			
			dispatchEvent(new AssetLoaderEvent(AssetLoaderEvent.LOADING_COMPLETE, this, null, eventData));
			
			// I'm just thinkin' we should reset the counts here.
			_queueCount = _loadSuccesses = _loadErrors = 0;
			
			status = STATUS_STOPPED;
		}
		
		protected function get status():String {
			return _status;
		}
		
		protected function set status(status:String):void {
			if (_status !== status){
				_status = status;
				trace("ASSET LOADER " + status);
			}
		}
		
		/**
		 * Other classes can query whether the queue has started.
		 */
		public function get started():Boolean {
			return STATUS_STARTED == _status;
		}
		
		/**
		 * Other classes can query whether the queue is emptied.
		 * Recommend listening for AssetLoaderEvent.LOADING_COMPLETE instead of polling this property.
		 */
		public function get complete():Boolean {
			return (STATUS_STOPPED == _status && 0 == _queue.length);
		}
		public function get queue():Number {
			return _queue.length;
		}
		
	}

}