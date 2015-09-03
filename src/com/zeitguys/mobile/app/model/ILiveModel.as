package com.zeitguys.mobile.app.model {
	
	/**
	 * Interface for ILiveModel implementation.
	 * 
	 * @author Tom Auger
	 */
	public interface ILiveModel {
		function registerLiveCallback(callback:Function, fieldName:String):void;
		function unregisterLiveCallback(callback:Function, fieldName:String):void;
		function updateLiveField(fieldName:String, newValue:*):void;
		function getLiveFieldValue(fieldName:String):*
	}
	
}