package com.zeitguys.util {
	import flash.utils.getDefinitionByName;
	import flash.utils.getQualifiedClassName;
	
	/**
	 * ...
	 * @author TomAuger
	 */
	public class ObjectUtils {
		
		/**
		 * Determines whether the childClass is in the inheritance chain of the parentClass. Both classes must be declared
		 * within the current ApplicationDomain for this to work.
		 * 
		 * @param	childClass
		 * @param	parentClass
		 * @param	mustBeChild
		 */
		public static function inheritsFrom(childClass:*, parentClass:*, mustBeChild:Boolean = false) {
			var child:Class,
				parent:Class;
				
			if (childClass is Class) {
				child = childClass;
			} else if (childClass is String){
				child = getDefinitionByName(childClass) as Class;
			}
			
			if (! child) {
				throw new ArgumentError("childClass must be a valid class name or a Class");
			}
			
			if (parentClass is Class) {
				parent = parentClass;
			} else if (parentClass is String){
				parent = getDefinitionByName(parentClass) as Class;
			}
			
			if (! parent) {
				throw new ArgumentError("parentClass must be a valid class name or a Class");
			}
			
			if (parent.prototype.isPrototypeOf(child.prototype)) {
				return true;
			} else {
				if (mustBeChild) {
					return false;
				} else {
					if (parent.prototype === child.prototype) {
						return true;
					}
				}
			}
			
			return false;
		}
		
		public static function getClassName(obj:Object):String {
			var className:String = getQualifiedClassName(obj);
			var parts:Array = className.split("::");
			if (parts.length) {
				return parts[parts.length - 1];
			} else {
				return className;
			}
		}
		
		public function ObjectUtils() {
		
		}
	
	}

}