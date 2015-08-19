package com.zeitguys.mobile.app.model {
	import com.zeitguys.util.DebugUtils;
	import flash.display.DisplayObject;
	import flash.errors.IllegalOperationError;
	import flash.net.SharedObject;
	/**
	 * Wrapper for storing local persistent data.
	 * 
	 * Default implementation leverages SharedObjects, but can be overridden in child classes to
	 * use File storage instead.
	 * 
	 * SharedObjects on iOS don't appear to flush() automatically upon application exit, so
	 * the storage methods in this class flush after every write (`save()` and `stash()`).
	 * 
	 * Currently there is very little difference between the save/load and the stash/fetch methods
	 * other than that save/load expect and return Objects rather than individual data types. In the future
	 * save and load might become a bit more robust and include serialization options, or leverage
	 * the filesystem instead of SharedObjects.
	 * 
	 * @author Eric Holmes, Tom Auger
	 */
	public class LocalStorage {
		public static const DEFAULT_STORAGE_ID:String = "KestrelLocalStorage";
		
		private static const SO_MIN_DISK_SIZE:uint = 8192; // 8 Mb
		
		/**
		 * Save data to one of the local storage items
		 * @param	storageID
		 * @param	data
		 * @param	id
		 * @return	the ID or the generated ID for future reference.
		 */
		public static function save(storageID:String, data:Object, id:String = ""):String {
			var so:SharedObject = SharedObject.getLocal(storageID);
			
			id ||= new Date().getTime().toString();
			
			so.data[id] = data;
			so.flush(SO_MIN_DISK_SIZE);
			
			return id;
		}
		
		/**
		 * Loads data from the localstorage object specified.
		 * 
		 * @param	storageID
		 * @param	id
		 * @param 	required If `true`, an exception is thrown if the requested key (id) does not exist on the SharedObject
		 * @return
		 */
		public static function load(storageID:String, id:String = "", required:Boolean = false ):Object {
			var so:SharedObject = SharedObject.getLocal(storageID);
			
			if (id) {
				if (so.data.hasOwnProperty(id)){
					return so.data[id];
				} else {
					if (required){
						trace("!! SharedObject error: Object '" + storageID + "' data does not have key '" + id + "'.");
					} else {
						return null;
					}
				}
			}
			
			return so.data;
		}
		
		/**
		 * Store a single value into LocalStorage.
		 * 
		 * @param	id
		 * @param	value
		 * @param	storageID
		 */
		public static function stash(id:String, value:*, storageID:String = DEFAULT_STORAGE_ID) {
			if (value is DisplayObject) {
				throw new ArgumentError("You may not store DisplayObjects using LocalStorage. Serialize your data and use `save()` instead.");
			}
			
			var so:SharedObject = SharedObject.getLocal(storageID);
			
			so.data[id] = value;
			so.flush(SO_MIN_DISK_SIZE);
		}
		
		/**
		 * Retrieve a single value from LocalStorage.
		 * 
		 * @param	id
		 * @param	required
		 * @param	storageID
		 * @return
		 */
		public static function fetch(id:String, required:Boolean = false, storageID:String = DEFAULT_STORAGE_ID):* {
			var so:SharedObject = SharedObject.getLocal(storageID);
			
			if (so.data.hasOwnProperty(id)) {
				return so.data[id];
			} else {
				if (required){
					trace("!! SharedObject error: Object '" + storageID + "' data does not have key '" + id + "'.");
				} else {
					return null;
				}
			}
		}
		
		/**
		 * Deletes data from the local storage object
		 * 
		 * @param	storageID
		 * @param	id
		 * @return
		 */
		public static function remove(storageID:String, id:String = ""):Object {
			var so:SharedObject = SharedObject.getLocal(storageID);
			
			if (id) {
				if (so.data.hasOwnProperty(id)) {
					return delete so.data[id];
				} else {
					trace("!! SharedObject error: Object '" + storageID + "' data does not have key '" + id + "'.");
				}
			}
			
			return false;
		}
		
	}
}