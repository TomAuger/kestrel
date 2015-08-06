package com.zeitguys.util {
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	
	/**
	 * Static classes for Debug. 
	 * @author EricHolmes, Tom Auger
	 */
	public class DebugUtils {
		private static var __instance:DebugUtils;
		
		public function DebugUtils() { }
		
		/**
		 * A clone of the PHP print_r() function. Displays the complete object hierarchy.
		 * 
		 * Only exposes user propoerties on objects. If you want a more complete picture of
		 * a DisplayObject, consider {@link debugClip()} instead.
		 * 
		 * @param	obj
		 * @param	level Optional. Used to determine indent level. If this is anything other than 0, output will be returned, not traced.
		 * @param	output Optional. Unused. Leaving it in for nostalgic reasons.
		 * @return
		 */
		public static function print_r(obj:*, level:int = 0, output:String = ""):* {
			var tabs:String = "";
			for(var i:int = 0; i < level; i++, tabs += "\t"){}
			
			for(var child:* in obj) {
				output += tabs +"["+ child +"] => "+ obj[child];
				
				var childOutput:String = print_r(obj[child], level+1);
				if(childOutput != '') output += ' {\n'+ childOutput + tabs +'}';
				
				output += "\n";
			}
			
			if(level == 0) trace(output);
			else return output;
		}
		
		/**
		 * Display the entire display list hierarchy down, starting from the provided clip.
		 * 
		 * The advantage of this function is that it will list the complete hierarchy, including any
		 * duplicate instance names. This is much more reliable than print_r
		 * 
		 * @param	clip DisplayObject or most usually DisplayObjectContainer that you want to debug
		 * @param	level Optional. Generally, leave this out - determines the indent level
		 */
		public static function debugClip(clip:DisplayObject, level:int = 0) {
			var tabs:String = "";
			var i:uint;
			var l:uint;
			var output:String = "";
			
			for (i = 0; i < level; i++, tabs += "\t") { }
		
			output += tabs + "[" + clip.name + "] => " + clip;
			
			if (clip is DisplayObjectContainer) {
				output += " {\n";
				l = DisplayObjectContainer(clip).numChildren;
				if (l) {
					for (i = 0; i < l; ++i) {
						output += debugClip(DisplayObjectContainer(clip).getChildAt(i), level + 1);						
					}
				} else {
					output += tabs + "\t" + "(no children)\n";
				}
				output += tabs + "}\n";
			} else {
				output += "\n";
			}
			
			if (level == 0) {
				trace(output);
			} else {
				return output;
			}
		}
	
	}
}