package com.zeitguys.util {
	
	/**
	 * Static classes for Number manipulation. 
	 * @author TomAuger
	 */
	public class MathUtils {
		private static var __instance:MathUtils;
		
		public function MathUtils() { }
		
		public static const LOG10:Number = Math.log(10);
		
		public static function toFloat(number:Number, precision:uint = 0):Number {
			var factor = Math.pow(10, precision);
			return Math.round(number * factor) / factor;
		}
		
		public static function arraySum(array:Array):Number {
			var total:Number = 0;
			
			for each (var element:* in array) {
				total += parseFloat(element);
			}
			
			return total;
		}
		
		public static function log10(n:Number):Number {
			return Math.log(n) / LOG10;
		}
		
		public static function getDB(power:Number, reference:Number):Number {
			return 10 * log10(power / reference);
		}
		
		public static function power2DB(power:Number):Number {
			return 20.0 * log10(power / 1.0);
		}
		
		public static function db2Power(db:Number):Number {
			return Math.pow(10, (db / 20));
		}
	
	}
}