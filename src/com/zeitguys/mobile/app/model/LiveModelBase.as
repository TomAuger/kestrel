package com.zeitguys.mobile.app.model 
{
	import com.zeitguys.util.DebugUtils;
	import flash.errors.IllegalOperationError;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	
	/**
	 * Base class that can be used by Models to implement ILiveModel and take advantage
	 * of LocalStorage helper functions.
	 * 
	 * @author Tom Auger
	 */
	public class LiveModelBase extends EventDispatcher implements ILiveModel {
		
		private var _watchedFields:Object = { };
		
		
		
		/**
		 *  ILiveModel ===========================================================================
		 */
		
		 /**
		  * Live Listeners use this to register callbacks that are called when the field
		  * they are watching get updated.
		  * 
		  * The callback takes 1 untyped argument: the value that is being updated.
		  * 
		  * @param	callback
		  * @param	fieldName
		  */
		public function registerLiveCallback(callback:Function, fieldName:String):void {
			var fieldCallbacks:Array = _watchedFields[fieldName] || [];
			
			if (fieldCallbacks.indexOf(callback) == -1) {
				fieldCallbacks.push(callback);
			}
			
			_watchedFields[fieldName] = fieldCallbacks;
		}
		
		/**
		 * Unregister a callback against a given field.
		 * 
		 * Be sure to use this method on disposal to release the reference to the callback
		 * so the listener object can be garbage collected.
		 * 
		 * @param	callback
		 * @param	fieldName
		 */
		public function unregisterLiveCallback(callback:Function, fieldName:String):void {
			var fieldCallbacks:Array;
			var callbackIndex:int;
			
			if (fieldName && fieldName in _watchedFields) {
				fieldCallbacks = _watchedFields[fieldName];
			}
			
			callbackIndex = fieldCallbacks.indexOf(callback);
			if (callbackIndex > -1) {
				fieldCallbacks.splice(callbackIndex, 1);
			}
			
			if (fieldCallbacks.length) {
				_watchedFields[fieldName] = fieldCallbacks;
			} else {
				delete _watchedFields[fieldName];
			}
		}
		
		/**
		 * Update the field you're watching.
		 * 
		 * IMPORTANT WARNING: this will in all likelihood call the corresponding setter
		 * method on the model, which will in turn probably trigger `notifyLiveListeners()`
		 * which will update your listener. If you're not careful, you can easily create
		 * an infinite loop if your listener's callback calls a setter that then updates 
		 * the live field again, and so on. Consider instead setting the property
		 * directly on your listener, and triggering any visual updates on the UI manually.
		 * 
		 * @param	fieldName
		 * @param	newValue
		 */
		public function updateLiveField(fieldName:String, newValue:*):void {
			if (fieldName in this) {
				this[fieldName] = newValue;
			} else {
				throw new ArgumentError("Cannot update Live Field '" + fieldName + "' on model " + this + ": property or method is not valid.");
			}
		}
		
		/**
		 * Listeners can call the getter or get the value of the property.
		 * 
		 * @param	fieldName
		 * @return
		 */
		public function getLiveFieldValue(fieldName:String):* {
			if (fieldName in this) {
				return (this[fieldName]);
			} else {
				throw new ArgumentError("Live Field '" + fieldName + "' in " + this + " is not a valid property or method");
			}
		}
		
		/**
		 * LiveModels can call this on any update for fields that are watched.
		 * 
		 * @param	fieldName
		 */
		protected function notifyLiveListeners(fieldName:String):void {
			var fieldCallbacks:Array = getCallbacksForLiveField(fieldName);
			
			if ((fieldName in this) && fieldCallbacks.length) {
				for each (var callback:Function in fieldCallbacks) {
					if (callback is Function) {
						callback.call(this, this[fieldName]);
					}
				}
			} else {
				throw new ArgumentError("Live Field '" + fieldName + "' in " + this + " is not a valid property or method");
			}
		}
		
		protected function getCallbacksForLiveField(fieldName):Array {
			if (fieldName in _watchedFields) {
				return _watchedFields[fieldName];
			}
			
			return null;
		}
		
		
		
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
			return LocalStorage.fetch(key, required, LOCAL_STORAGE_ID);
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