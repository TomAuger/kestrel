package com.zeitguys.app.model 
{
	import com.zeitguys.util.DebugUtils;
	import flash.errors.IllegalOperationError;
	import flash.net.SharedObject;
	/**
	 * ...
	 * @author EricHolmes
	 */
	public class LocalStorage {
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
		 * @return
		 */
		public static function load(storageID:String, id:String = ""):Object {
			var so:SharedObject = SharedObject.getLocal(storageID);
			
			if (id) {
				if (so.data.hasOwnProperty(id)){
					return so.data[id];
				} else {
					trace("!! SharedObject error: Object '" + storageID + "' data does not have key '" + id + "'.");
				}
			}
			
			return so.data;
		}
		
	}
}