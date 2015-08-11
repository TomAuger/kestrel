package com.zeitguys.util 
{
	import flash.text.StyleSheet;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import flash.text.TextLineMetrics;
	/**
	 * Utilities for manipulating text and typography, mainly to get around some of the (very poor) idiosyncracies of the
	 * Flash type engine. It's a bad scene man, but I've put the blood and sweat into working around it. So here it is.
	 * 
	 * @author Tom Auger
	 */
	public class TextUtils {
		static public var styleSheet:StyleSheet;
		
		/**
		 * Sets the TextField's .text or .htmlText property. Includes the additional logic for preserving the TextFormat / setting the stylesheet.
		 * 
		 * Maybe override in child classes if you need to change the way autosize / stylesheets / textFormats are handled
		 * on a case-by-case basis.
		 * 
		 * @param	field
		 * @param	content
		 * @param	isHTML
		 */
		static public function setTextFieldContent(field:TextField, content:String, isHTML:Boolean = false, autoSize:Boolean = true):void {
			var htmlCheck:Boolean = false, 
				tf:TextFormat,
				metrics:TextLineMetrics,
				visibleLines:uint;
			
			// Determine whether the supplied text is HTML or just plain text
			try {
				var xml:XML = new XML(content);
				// It will pass if it's only text, so we need to make sure there are children.
				if ( xml.children().length()) htmlCheck = true;
			} catch (err:Error) {
				// Malformed means it's HTML
				htmlCheck = true;
			}

			// A lot of issues can be created by things like leading. This is a workaround.
			field.autoSize = TextFieldAutoSize.LEFT;
			
			if (isHTML || htmlCheck) {
				// Remove excess white space
				field.condenseWhite = true;
				
				field.styleSheet = TextUtils.styleSheet;
				
				field.htmlText = content;
				
				// Calculate visible lines for HTML text. Very weird, but this is what works in my testing.
				visibleLines = field.numLines - Math.min(field.bottomScrollV, field.maxScrollV);
			} else {
				// Stash the TextFormat
				tf = field.getTextFormat();
				field.styleSheet = null;
				field.defaultTextFormat = tf;
				
				// Allow white space and newlines.
				field.condenseWhite = false;
				
				field.text = content;
				field.setTextFormat(tf);
				
				// Calculate visible lines for plain text. Simple.
				visibleLines = field.numLines;
			}
			
			if (autoSize) {
				if (visibleLines < 2) {
					metrics = field.getLineMetrics(0);
					
					field.autoSize = TextFieldAutoSize.NONE;
					
					// Adjust the single line size to compensate for leading + obligatory 2px padding.
					field.height = field.textHeight - metrics.leading + 4;
				}
			}
		}
	}
}