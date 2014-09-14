package com.zeitguys.app.error {
	
	/**
	 * Use this error if we're expecting a MovieClip to contain certain named instances, but the designer has not provided them.
	 *
	 * @author TomAuger
	 */
	public class FlashConstructionError extends Error {
		
		public function FlashConstructionError(parentName:String, missingChildName:String, context:String = "") {
			var message:String = "'" + parentName + "' does not contain an asset with an instance name of '" + missingChildName + "'";
			if (context) {
				message += " (" + context + ")";
			}
			message += ".";
			
			super(message);
		}
	
	}

}