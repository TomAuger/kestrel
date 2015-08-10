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
	 * within the asset should be invoked until after the SWF has been attached.
	 * 
	 * ScreenViews that use ScreenAssetViews must be sure to add themselves to the asset using set screen. This is handled automatically by the base
	 * ScreenView class within its {@link ScreenView/addAsset()} method.
	 *  
	 * Extend this class to create assets with specific characteristics and behaviours such as text boxes, buttons and interactive components.
	 * 
	 * Child classes must do the following:
		 * 
	 *
	 * @see ScreenView.defineAssets()
	 *
	 * @author TomAuger
	 */
	public class ScreenAssetView extends ViewBase {
		
		protected var _screen:ScreenView;
		protected var _numberFormatter:NumberFormatter;
		
		protected var _active:Boolean = false;
		protected var _disabled:Boolean = false;
		
		protected var _textFieldName:String;
		protected var _textField:TextField;
		
		public function ScreenAssetView(clip:*, disabled:Boolean = false, localizableTextFieldName:String = "" ) {
			if (clip is DisplayObject) {
				_clipName = DisplayObject(clip).name;
				_clip = clip;
			} else if (clip is String) {
				// Store the name. We can't find the actual clip until we have added the Screen
				_clipName = clip;
			} else {
				throw new ArgumentError("Constructor argument 'clip' must be a DisplayObject instance name (String) or an actual DisplayObject instance");
			}
			
			
			if (localizableTextFieldName) {
				_textFieldName = localizableTextFieldName;
			}
			
			_disabled = disabled;
		}
		
		/**
		 * Assigns this Asset to a Screen. 
		 * Arguably more importantly, digs through the screen's MovieClip to find this asset's MovieClip,
		 * and assigns that to _clip.
		 * 
		 * Override in child classes to provide exact path to clip.
		 * 
		 * @TODO Make this method more universal and traverse the screen's object model to find the child clip.
		 */
		public function set screen(screen:ScreenView):void {
			_screen = screen;
			
			if (findClip()) {
				if (_textFieldName && _clipName !== _textFieldName) {
					var clip:DisplayObject = getRequiredChildByName(_textFieldName);
					if (clip is TextField) {
						_textField = TextField(clip);
					} else {
						throw new FlashConstructionError(screenName, _textFieldName, "as TextField");
					}
				} else {
					if (_clip is TextField) {
						_textField = TextField(_clip);
					}
				}
				
				// Store the clip's original coords.
				_clipOrigX = _clip.x;
				_clipOrigY = _clip.y;
				
				init();
				
				// Generally, we assume assets are built enabled. So, we only call onDisabled(), not onEnabled();
				if (_disabled) {
					onDisabled();
				}
			} else {
				throw new IllegalOperationError("Unable to set the screen " + screenName + " on ScreenAsset " + _clipName);
			}
		}
		
		public function get screen():ScreenView {
			if (_screen) {
				return _screen;
			}
			
			return null;
		}
		
		/**
		 * Associate the appropriate DisplayObject with this asset, based on the clipName that was passed in the constructor.
		 * 
		 * @return
		 */
		protected function findClip():Boolean {
			if (! _clip){
				_clip = getRequiredChildByName(_clipName, null, DisplayObjectContainer(screen.clip));
			}
			
			if (_clip && _clip is DisplayObject) {
				return true;
			} else {
				throw new FlashConstructionError(_screen.id, _clipName);
				return false;
			}
		}
		
		/**
		 * The clip has been defined, and is therefore added to the DisplayList.
		 * 
		 * This may happen only once, event if the assets is accessed multiple times.
		 * 
		 * Consider waiting for {@link #activate()} before defining event listeners though.
		 */
		public function init():void {
			
		}
		
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
		protected function getAssetComponentText(localizer:Localizer, component:String, componentID:String = ""):String {
			return localizer.getAssetComponentText(bundleID, screenName, id, component, componentID);
		}
		
		
		
		
		/**
		 * Called by {@link ScreenView.activate()}. Override in child classes, calling super.activate().
		 * 
		 * Any asset that has interactivity should DEFER setting any event listeners until the asset has been activated.
		 * Similarly, it should disable any event listeners on deactivation.
		 * 
		 * Note that activating / deactivating an asset is NOT the same as enabling / disabling an asset, and you should
		 * always check the {@link /_disabled} status of the asset before doing anything.
		 * 
		 */
		public function activate() {
			if ( !_active){
				if (! _disabled){
					_active = true;
					trace("  + " + _clipName + " ACTIVATED");
				} else {
					trace("  + " + _clipName + " NOT activated (disabled)");
				}
			} else {
				trace("  + " + _clipName + " SKIPPING activation");
			}
		}
		
		public function deactivate() {
			if (_active){
				_active = false;
				
				trace("  - " + _clipName + " DEACTIVATED");
			} else {
				trace("  - " + _clipName + " SKIPPING deactivation");
			}
		}
		
		/**
		 * Disable the asset.
		 * 
		 * If the asset has already been initialized
		 */
		public function disable():void {
			if (! _disabled){
				
				_disabled = true;
				
				onDisabled();
				
				trace("  - " + id + " DISABLED");
				
				if (_active) {
					deactivate();
				}
			} else {
				trace("  - " + id + " SKIPPING disable");
			}
		}
		
		/**
		 * Enable the asset.
		 * 
		 * Will also activate the asset, if this is set before the clip has been activated.
		 * This could be problematic, so use with caution.
		 */
		public function enable():void {
			if (_disabled) { 
				_disabled = false;
				
				onEnabled();
				
				trace("  + " + id + " ENABLED");
				
				if (! _active) {
					activate();
				}
			} else {
				trace("  + " + id + " SKIPPING enable");
			}
		}
		
		public function show(enable:Boolean = true):void {
			if (enable && _disabled) {
				this.enable(); // WHY do we need 'this' here???
			}
			
			if (_clip) {
				_clip.visible = true;
			}
		}
		
		public function hide(disable:Boolean = true):void {
			if (disable && ! _disabled) {
				this.disable();
			}
			
			if (_clip) {
				_clip.visible = false;
			}
		}
		
		/**
		 * Override in child classes.
		 * 
		 * Updates the visual style of the asset when it is disabled.
		 */
		protected function onDisabled() {
			
		}
		
		/**
		 * Override in child classes.
		 * 
		 * Updates the visual style of the asset when it is (re-)enabled
		 */
		protected function onEnabled() {
			
		}
		
		
		/**
		 * Override in child classes.
		 * 
		 * Allows us to add a filter. Extend this in subclasses, remembering to call parent.addFilter() at the end of the overridden method.
		 * 
		 * @param	filterName
		 * @param	filterCallback
		 */
		public function addFilter(filterName:String, filterCallback:Function):void {
			
		}
		
	
		public function get id():String {
			return _clipName;
		}
		
		public function get bundleID():String {
			return _screen.bundle.id;
		}
		
		public function get screenName():String {
			return _screen.name;
		}
		
		public function get isActivated():Boolean {
			return _active;
		}
		
		public function get isEnabled():Boolean {
			return ! _disabled;
		}
	}

}