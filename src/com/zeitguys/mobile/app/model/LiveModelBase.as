package com.zeitguys.mobile.app.model 
{
	import flash.errors.IllegalOperationError;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	
	/**
	 * Base class that can be used by Models to implement ILiveModel and take advantage
	 * of LocalStorage helper functions.
	 * 
	 * @author Tom Auger
	 */
	public class LiveModelBase extends EventDispatcher {
		
		
		
		
		
		
		
		
		
		
		/**
		 *  LOCAL STORAGE ===========================================================================
		 */
		
		 /**
		  * Should be unique per model, otherwise your storage keys could collide.
		  */
		protected function get LOCAL_STORAGE_ID():String {
			throw new Error("Abstract class. LiveModelBase subclasses must override `get LOCAL_STORAGE_ID()`");
			return "KestrelLiveModel";
		}
		
		/**
		 * Retrieve a single value from the App Config local storage.
		 * 
		 * Leverages basic cacheing for performance.
		 * 
		 * @param	key
		 * @param	required If `true`, will throw an error if the key is missing.
		 * @return
		 */
		protected function getLocal(key:String, required:Boolean = false):* {
			LocalStorage.fetch(key, required, LOCAL_STORAGE_ID);
		}
		
		/**
		 * Store a single value to the App Config local storage, and stash it in the cache as well.
		 * 
		 * @param	key
		 * @param	value
		 */
		protected function setLocal(key:String, value:*):void {
			trace("Saving '" + key + "' to LocalStorage");
			LocalStorage.stash(key, value, LOCAL_STORAGE_ID);
		}
		
		
		public function LiveModelBase() {
			
		}
		
	}

}