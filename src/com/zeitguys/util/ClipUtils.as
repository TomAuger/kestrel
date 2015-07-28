package com.zeitguys.util {
	import com.zeitguys.kestrel.app.error.FlashConstructionError;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	
	/**
	 * ...
	 * @author TomAuger
	 */
	public class ClipUtils {
		/**
		 * Dig through the display hierarchy of the clip to find a child DisplayObject with the requested instance name.
		 * 
		 * @throws FlashConstructionError if no matching asset is found.
		 * 
		 * @param	clipName
		 * @param	parentClip Required. The search takes too long if we let the scope be the entire app, so you must provide a parent clip (usually Screen)
		 * @return
		 */
		public static function getRequiredChildByName(clipName:String, parentClip:DisplayObjectContainer, asClass:Class = null):DisplayObject {
			var clip:DisplayObject = ClipUtils.getDescendantByName(clipName, parentClip);
			if (! clip) {
				throw new FlashConstructionError(parentClip.name, clipName);
			}
			
			if (asClass) {
				if (! (clip is asClass)) {
					throw new FlashConstructionError(parentClip.name, clipName, "as " + ObjectUtils.getClassName(asClass));
				}
			}
			
			return clip;
		}
		
		
		
		/**
		 * Recursively dig through the provided parent DisplayObjectContainer to find a clip with the spcified instance name.
		 * 
		 * This method throws no error and only returns `null` if no matching clip found. If you want automatic error and type-checking,
		 * use {@link /getRequiredChildByName()} instead.
		 * 
		 * @param	clipName
		 * @param	parent
		 * @param	maxDepth Used to limit recursion. Will not dig deeper than that many levels.
		 * @return
		 */
		public static function getDescendantByName(clipName:String, parent:DisplayObjectContainer, maxDepth:uint = 12):DisplayObject {
			var childContainers:Vector.<DisplayObjectContainer> = new Vector.<DisplayObjectContainer>;
			
			for (var i:uint = 0, l:uint = parent.numChildren; i < l; ++i) {
				var item:DisplayObject = parent.getChildAt(i);
				
				if (item.name == clipName) {
					return item;
				} else if (item is DisplayObjectContainer) {
					childContainers.push(DisplayObjectContainer(item));
				}
			}
			
			if (maxDepth){
				for (i = 0, l = childContainers.length; i < l; ++i) {
					item = ClipUtils.getDescendantByName(clipName, childContainers[i], maxDepth - 1)
					if (item) {
						return item;
					}
				}
			}
			
			return null;
		}
		
		
		
		
		
		
		public function ClipUtils() {
		
		}
	
	}

}