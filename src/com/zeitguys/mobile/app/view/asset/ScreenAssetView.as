package com.zeitguys.mobile.app.view.asset {
	import com.zeitguys.mobile.app.error.FlashConstructionError;
	import com.zeitguys.mobile.app.model.ILocalizable;
	import com.zeitguys.mobile.app.model.Localizer;
	import com.zeitguys.mobile.app.view.ViewBase
	import com.zeitguys.mobile.app.view.ScreenView;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.errors.IllegalOperationError;
	import flash.events.EventDispatcher;
	import flash.globalization.NumberFormatter;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import flash.utils.getDefinitionByName;
	import flash.utils.getQualifiedClassName;
	
	/**
	 * Base class for all screen assets.
	 * 
	 * A screen asset represents a collection of related elements (text and graphics) that can been attached to a screen. The class is self-localizing:
	 * during the ScreenView's localize() phase, all Assets that have been registered to that ScreenView have their localize() method called.
	 * 
	 * It is the responsibility of the Asset to know about its TextFields, their labels, and what their corresponding XML identifier is, though
	 * by convention the TextField's label and the XML element share the same name.
	 * 
	 * The Asset is attached to the screen using the screen setter method. This is critical, as the asset may actually be instantiated well in advance
	 * of the Screen's SWF being available. No functionality (such as event listener registration) that depends on a particular MovieClip or Flash element
	 * within the asset should be invoked until after the SWF has been attached. The `init()` method is the perfect place to start, as it is called by `set screen()`.
	 * 
	 * ScreenViews that use ScreenAssetViews must be sure to add themselves to the asset using `ScreenAssetView.set screen()`. This is handled automatically by the base
	 * ScreenView class within its {@link ScreenView/addAsset()} method.
	 *  
	 * Extend this class to create assets with specific characteristics and behaviours such as text boxes, buttons and interactive components.
	 * 
	 * ScreenAssetViews should **not** be nested within other ScreenAssetViews: they are meant to be first-class citizens of the ScreenView. They can, however contain 
	 * any other assets that extend ViewBase (such as AssetView).
	 *
	 * @see ScreenView.defineAssets()
	 *
	 * @author TomAuger
	 */
	public class ScreenAssetView extends AssetView {
		
		protected var _screen:ScreenView;
		
		public function ScreenAssetView(clip:*, disabled:Boolean = false, localizableTextFieldName:String = "", screenView:ScreenView = null ) {
			super(clip, disabled, localizableTextFieldName);
			
			if (screenView) {
				screen = screenView;
			}
		}
		
		/**
		 * Assigns this Asset to a Screen and initializes the Asset.
		 * 
		 * Most often called by {@link ScreenView.addAsset()} or indirectly via {@link FlexGroup.registerAssetWithScreen()}.
		 * 
		 * Can also be called directly if a ScreenView is passed in the ScreenAssetView's constructor.
		 * 
		 * @uses #findClip() to locate the asset (by name) within the ScreenView's MovieClip.
		 * 
		 * @triggers AssetView.init()
		 */
		public function set screen(screen:ScreenView):void {
			_screen = screen;
			
			findClip(DisplayObjectContainer(screen.clip));
		}
		
		override public function get screen():ScreenView {
			if (_screen) {
				return _screen;
			}
			
			return null;
		}
		
		public function get bundleID():String {
			return _screen.bundle.id;
		}
		
		public function get screenName():String {
			return _screen.name;
		}
		
		
		
		
		
		/* ===========================================================================================================
		 *                                                 LOCALIZATION
		/* ===========================================================================================================*/
		
		/**
		 * Override in child classes to fetch locale strings from the Localizer using localizer.localize()
		 * for the specific text fields within the asset.
		 * 
		 * @param	localizer
		 * @return	Success.
		 */
		override public function localize(localizer:Localizer):void {
			trace("Localizing " + id);
			
			_numberFormatter = localizer.numberFormatter;
			
			if (_textFieldName && _textField) {
				setText(_textField, getAssetComponentText(localizer, _textFieldName));
			}
			
			super.localize(localizer);
		}
		
		
		/**
		 * Convenience function that interacts with the Localizer to obtain the text for this asset. Automatically provides the
		 * bundleID, the screenName and the id of the asset to make for more compact and readable code when localizing asset types
		 * defined in subclasses of ScreenAssetView.
		 * 
		 * @see Localizer.getAssetComponentText()
		 * 
		 * @param	localizer The Localizer instance
		 * @param	component The ID of the component within this ScreenAsset that we're localizing.
		 * @param	componentID Optional. If multiple components with the same name are present within the asset, provide the unique ID to help the Localizer target the correct string.
		 * @return
		 */
		override protected function getAssetComponentText(localizer:Localizer, component:String, componentID:String = ""):String {
			return localizer.getAssetComponentText(bundleID, screenName, id, component, componentID);
		}
	}

}