package com.zeitguys.util {
	
	/**
	 * Static classes for Debug. 
	 * @author EricHolmes
	 */
	public class DebugUtils {
		private static var __instance:DebugUtils;
		
		public function DebugUtils() { }
		
		/*
		* Print_r 
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
	
	}
}