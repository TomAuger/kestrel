package com.zeitguys.mobile.app.view.asset 
{
	import com.zeitguys.mobile.app.error.FlashConstructionError;
	import com.zeitguys.mobile.app.model.Localizer;
	import com.zeitguys.mobile.app.view.ScreenView;
	import com.zeitguys.mobile.app.view.ViewBase;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.errors.IllegalOperationError;
	import flash.globalization.NumberFormatter;
	import flash.text.TextField;
	
	/**
	 * Base class for all Kestrel "Assets". AssetViews decorate DisplayObjects.
	 * 
	 * @author Tom Auger
	 */
	public class AssetView extends ViewBase {
		protected var _parentAsset:AssetView;
		protected var _parentScreen:ScreenView;
		protected var _childAssets:Vector.<AssetView> = new Vector.<AssetView>;
		
		protected var _numberFormatter:NumberFormatter;
		
		protected var _initialized:Boolean = false;
		protected var _active:Boolean = false;
		protected var _disabled:Boolean = false;
		
		protected var _textFieldName:String;
		protected var _textField:TextField;
		
		public function AssetView(assetClip:*, disabled:Boolean = false, localizableTextFieldName:String = "") {
			if (assetClip is DisplayObject) {
				_clipName = DisplayObject(assetClip).name;
				clip = assetClip;
			} else if (assetClip is String) {
				_clipName = assetClip;
			} else {
				throw new ArgumentError("Constructor argument 'clip' must be a DisplayObject instance name (String) or an actual DisplayObject instance");
			}
			
			
			if (localizableTextFieldName) {
				_textFieldName = localizableTextFieldName;
			}
			
			_disabled = disabled;
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
		
		public function get isActivated():Boolean {
			return _active;
		}
		
		public function get isEnabled():Boolean {
			return ! _disabled;
		}
		
		
		
		public function addAsset(newAsset:AssetView):AssetView {
			newAsset.parentAsset = this;
			_childAssets.push(newAsset);
			
			return newAsset;
		}
		
		
		/**
		 * Associate the appropriate DisplayObject with this asset, based on the clipName that was passed in the constructor.
		 * 
		 * @return
		 */
		protected function findClip(parentClip:DisplayObjectContainer):Boolean {
			if (! _clip){
				clip = getRequiredChildByName(_clipName, null, parentClip);
			}
			
			return true;
		}
		
		/**
		 * Sets the DisplayObject that this Asset is associated with. This is generally
		 * a Sprite or MovieClip that contains the artwork for this Asset, and may
		 * even contain other nested DisplayObjectContainers destined to become
		 * child AssetViews of this Asset.
		 */
		override public function set clip(clipDisplayObject:DisplayObject):void {
			super.clip = clipDisplayObject;
			
			if (_textFieldName && _clipName !== _textFieldName && clip is DisplayObjectContainer) {
				_textField = TextField(getRequiredChildByName(_textFieldName, TextField, DisplayObjectContainer(_clip)));
			} else {
				if (_clip is TextField) {
					_textField = TextField(_clip);
				}
			}
			
			// Store the clip's original coords.
			_clipOrigX = _clip.x;
			_clipOrigY = _clip.y;
			
			if (! _initialized) {
				init();
				_initialized = true;
			}
		}
		
		/**
		 * Sets the parent AssetView, and if the clip has been deferred (such as when the AssetView is instantiated
		 * with just the instance name of the clip, instead of the actual clip), then will attempt to set the clip
		 * by searching through the parentAsset's clip's display hierarchy.
		 */
		public function set parentAsset(asset:AssetView):void {
			_parentAsset = asset;
			
			if (! _clip) {
				if (_parentAsset.clip && _parentAsset.clip is DisplayObjectContainer) {
					clip = _parentAsset.getRequiredChildByName(_clipName);
				} else {
					throw new IllegalOperationError("Setting parentAsset, but the parentAsset's clip has not yet been set.");
				}
			}
		}
		
		public function get parentAsset():AssetView {
			return _parentAsset;
		}
		
		public function get screen():ScreenView {
			if (! _parentScreen) {
				_parentScreen = getParentScreen(this);
			}
			
			return _parentScreen;
		}
		
		protected function getParentScreen(child:AssetView = null):ScreenView {
			var parentAsset:AssetView
			
			if (! child) {
				child = this;
			}
			
			parentAsset = child.parentAsset;
			
			if (parentAsset) {
				if (parentAsset is ScreenView) {
					return ScreenView(parentAsset);
				} else {
					return getParentScreen(parentAsset);
				}
			}
			
			return null; // Nothing found
		}
		
	}

}