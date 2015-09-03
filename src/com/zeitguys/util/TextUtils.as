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
		
		
		
		/**
		 * Convert HTML entities within html text.
		 * 
		 * @param	str
		 * @return
		 */
		
		private static var entityMap:Object = { '&nbsp;':'&#160;', '&iexcl;':'&#161;', '&cent;':'&#162;', '&pound;':'&#163;', '&curren;':'&#164;', '&yen;':'&#165;', '&brvbar;':'&#166;', '&sect;':'&#167;', '&uml;':'&#168;', '&copy;':'&#169;', '&ordf;':'&#170;', '&laquo;':'&#171;', '&not;':'&#172;', '&shy;':'&#173;', '&reg;':'&#174;', '&macr;':'&#175;', '&deg;':'&#176;', '&plusmn;':'&#177;', '&sup2;':'&#178;', '&sup3;':'&#179;', '&acute;':'&#180;', '&micro;':'&#181;', '&para;':'&#182;', '&middot;':'&#183;', '&cedil;':'&#184;', '&sup1;':'&#185;', '&ordm;':'&#186;', '&raquo;':'&#187;', '&frac14;':'&#188;', '&frac12;':'&#189;', '&frac34;':'&#190;', '&iquest;':'&#191;', '&Agrave;':'&#192;', '&Aacute;':'&#193;', '&Acirc;':'&#194;', '&Atilde;':'&#195;', '&Auml;':'&#196;', '&Aring;':'&#197;', '&AElig;':'&#198;', '&Ccedil;':'&#199;', '&Egrave;':'&#200;', '&Eacute;':'&#201;', '&Ecirc;':'&#202;', '&Euml;':'&#203;', '&Igrave;':'&#204;', '&Iacute;':'&#205;', '&Icirc;':'&#206;', '&Iuml;':'&#207;', '&ETH;':'&#208;', '&Ntilde;':'&#209;', '&Ograve;':'&#210;', '&Oacute;':'&#211;', '&Ocirc;':'&#212;', '&Otilde;':'&#213;', '&Ouml;':'&#214;', '&times;':'&#215;', '&Oslash;':'&#216;', '&Ugrave;':'&#217;', '&Uacute;':'&#218;', '&Ucirc;':'&#219;', '&Uuml;':'&#220;', '&Yacute;':'&#221;', '&THORN;':'&#222;', '&szlig;':'&#223;', '&agrave;':'&#224;', '&aacute;':'&#225;', '&acirc;':'&#226;', '&atilde;':'&#227;', '&auml;':'&#228;', '&aring;':'&#229;', '&aelig;':'&#230;', '&ccedil;':'&#231;', '&egrave;':'&#232;', '&eacute;':'&#233;', '&ecirc;':'&#234;', '&euml;':'&#235;', '&igrave;':'&#236;', '&iacute;':'&#237;', '&icirc;':'&#238;', '&iuml;':'&#239;', '&eth;':'&#240;', '&ntilde;':'&#241;', '&ograve;':'&#242;', '&oacute;':'&#243;', '&ocirc;':'&#244;', '&otilde;':'&#245;', '&ouml;':'&#246;', '&divide;':'&#247;', '&oslash;':'&#248;', '&ugrave;':'&#249;', '&uacute;':'&#250;', '&ucirc;':'&#251;', '&uuml;':'&#252;', '&yacute;':'&#253;', '&thorn;':'&#254;', '&yuml;':'&#255;', '&fnof;':'&#402;', '&Alpha;':'&#913;', '&Beta;':'&#914;', '&Gamma;':'&#915;', '&Delta;':'&#916;', '&Epsilon;':'&#917;', '&Zeta;':'&#918;', '&Eta;':'&#919;', '&Theta;':'&#920;', '&Iota;':'&#921;', '&Kappa;':'&#922;', '&Lambda;':'&#923;', '&Mu;':'&#924;', '&Nu;':'&#925;', '&Xi;':'&#926;', '&Omicron;':'&#927;', '&Pi;':'&#928;', '&Rho;':'&#929;', '&Sigma;':'&#931;', '&Tau;':'&#932;', '&Upsilon;':'&#933;', '&Phi;':'&#934;', '&Chi;':'&#935;', '&Psi;':'&#936;', '&Omega;':'&#937;', '&alpha;':'&#945;', '&beta;':'&#946;', '&gamma;':'&#947;', '&delta;':'&#948;', '&epsilon;':'&#949;', '&zeta;':'&#950;', '&eta;':'&#951;', '&theta;':'&#952;', '&iota;':'&#953;', '&kappa;':'&#954;', '&lambda;':'&#955;', '&mu;':'&#956;', '&nu;':'&#957;', '&xi;':'&#958;', '&omicron;':'&#959;', '&pi;':'&#960;', '&rho;':'&#961;', '&sigmaf;':'&#962;', '&sigma;':'&#963;', '&tau;':'&#964;', '&upsilon;':'&#965;', '&phi;':'&#966;', '&chi;':'&#967;', '&psi;':'&#968;', '&omega;':'&#969;', '&thetasym;':'&#977;', '&upsih;':'&#978;', '&piv;':'&#982;', '&bull;':'&#8226;', '&hellip;':'&#8230;', '&prime;':'&#8242;', '&Prime;':'&#8243;', '&oline;':'&#8254;', '&frasl;':'&#8260;', '&weierp;':'&#8472;', '&image;':'&#8465;', '&real;':'&#8476;', '&trade;':'&#8482;', '&alefsym;':'&#8501;', '&larr;':'&#8592;', '&uarr;':'&#8593;', '&rarr;':'&#8594;', '&darr;':'&#8595;', '&harr;':'&#8596;', '&crarr;':'&#8629;', '&lArr;':'&#8656;', '&uArr;':'&#8657;', '&rArr;':'&#8658;', '&dArr;':'&#8659;', '&hArr;':'&#8660;', '&forall;':'&#8704;', '&part;':'&#8706;', '&exist;':'&#8707;', '&empty;':'&#8709;', '&nabla;':'&#8711;', '&isin;':'&#8712;', '&notin;':'&#8713;', '&ni;':'&#8715;', '&prod;':'&#8719;', '&sum;':'&#8721;', '&minus;':'&#8722;', '&lowast;':'&#8727;', '&radic;':'&#8730;', '&prop;':'&#8733;', '&infin;':'&#8734;', '&ang;':'&#8736;', '&and;':'&#8743;', '&or;':'&#8744;', '&cap;':'&#8745;', '&cup;':'&#8746;', '&int;':'&#8747;', '&there4;':'&#8756;', '&sim;':'&#8764;', '&cong;':'&#8773;', '&asymp;':'&#8776;', '&ne;':'&#8800;', '&equiv;':'&#8801;', '&le;':'&#8804;', '&ge;':'&#8805;', '&sub;':'&#8834;', '&sup;':'&#8835;', '&nsub;':'&#8836;', '&sube;':'&#8838;', '&supe;':'&#8839;', '&oplus;':'&#8853;', '&otimes;':'&#8855;', '&perp;':'&#8869;', '&sdot;':'&#8901;', '&lceil;':'&#8968;', '&rceil;':'&#8969;', '&lfloor;':'&#8970;', '&rfloor;':'&#8971;', '&lang;':'&#9001;', '&rang;':'&#9002;', '&loz;':'&#9674;', '&spades;':'&#9824;', '&clubs;':'&#9827;', '&hearts;':'&#9829;', '&diams;':'&#9830;', '"':'&#34;', '&':'&#38;', '<':'&#60;', '>':'&#62;', '&OElig;':'&#338;', '&oelig;':'&#339;', '&Scaron;':'&#352;', '&scaron;':'&#353;', '&Yuml;':'&#376;', '&circ;':'&#710;', '&tilde;':'&#732;', '&ensp;':'&#8194;', '&emsp;':'&#8195;', '&thinsp;':'&#8201;', '&zwnj;':'&#8204;', '&zwj;':'&#8205;', '&lrm;':'&#8206;', '&rlm;':'&#8207;', '&ndash;':'&#8211;', '&mdash;':'&#8212;', '&lsquo;':'&#8216;', '&rsquo;':'&#8217;', '&sbquo;':'&#8218;', '&ldquo;':'&#8220;', '&rdquo;':'&#8221;', '&bdquo;':'&#8222;', '&dagger;':'&#8224;', '&Dagger;':'&#8225;', '&permil;':'&#8240;', '&lsaquo;':'&#8249;', '&rsaquo;':'&#8250;', '&euro;':'&#8364;' };

		public static function convertEntities(str:String):String {
			var re:RegExp = /&\w*;/g
			var entitiesFound:Array = str.match(re);
			var entitiesConverted:Object = {};    

			var len:int = entitiesFound.length;
			var oldEntity:String;
			var newEntity:String;
			for (var i:int = 0; i < len; i++)
			{
				oldEntity = entitiesFound[i];
				newEntity = entityMap[oldEntity];

				if (newEntity && !entitiesConverted[oldEntity])
				{
					str = str.split(oldEntity).join(newEntity);
					entitiesConverted[oldEntity] = true;
				}
			}

			return str;
		}
		
		/**
		 * Check to see if HTML Entities are within the string passed.
		 * @param	str
		 * @return
		 */
		public static function hasHtmlEntities(str:String):Boolean {
			return Boolean(str.match(/&\w*;/) || str.match(/<[a-zA-Z ="']+>/));
		}
	}
}