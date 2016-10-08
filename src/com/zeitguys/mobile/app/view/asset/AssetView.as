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
		 * @usedby set clip() Once we actually have a clip (either because a DisplayObject was passed in the constructor, or the clip has been set by the parent asset/screen).
		 * 
		 * Consider waiting for {@link #activate()} before defining event listeners.
		 */
		public function init():void {
				
			// Generally, we assume assets are built enabled. So, we only call onDisabled(), not onEnabled();
			if (_disabled) {
				trace("  / " + _clipName + " starting DISABLED");
				onDisabled();
			}
		}
		
		/**
		 * Override in child classes.
		 * This method is called __every__ time a screen is displayed (switched to from another screen), just before localize() is run.
		 * Use this method to setup things that the localizer needs to know about. 
		 */
		public function setupBeforeLocalize():void {
			for each (var asset:AssetView in _childAssets) {
				asset.setupBeforeLocalize();
			}
		}
		
		/**
		 * Override in child classes.
		 * This method is called __every__ time a screen is displayed (switched to from another screen) just after localize() is run.
		 * This is where you should do things like initialize the screen's model, and perform set-ups that should happen every time the screen is displayed.
		 */
		public function setupAfterLocalize():void {
			for each (var asset:AssetView in _childAssets) {
				asset.setupAfterLocalize();
			}
		}
		
		/**
		 * Override in child classes.
		 * 
		 * This method is called when a screen is displayed and a reset request has been dispatched (usually through a ScreenRouter call from
		 * the previous screen).
		 * 
		 * The current implementation of ScreenRouter defaults `resetView` to `true`, so unless explicitly set to `false`, ALL
		 * `setScreen()` calls WILL also call `reset()` on the ScreenView, and thus on all child assets.
		 * 
		 * For now, you should assume `reset()` will be called EVERY TIME the current screen is switched to.
		 * This is usually a Good Thing.
		 */
		public function reset():void {
			for each (var asset:AssetView in _childAssets) {
				asset.reset();
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
		 * Activate asset and all registered child assets.
		 * 
		 * Called by {@link ScreenView.activate()} or {@link AssetView.activate()} from a parent AssetView.
		 * 
		 * Override in child classes, remembering to end with a call to `super.activate()`.
		 * 
		 * Any asset that has interactivity should DEFER setting any event listeners until the asset has been activated.
		 * Similarly, it should disable any event listeners on deactivation.
		 * 
		 * Note that activating / deactivating an asset is NOT the same as enabling / disabling an asset, and you should
		 * always check the {@link /_disabled} status of the asset before doing anything.
		 * 
		 * @see get activatable() for a best practice shortcut test to determine whether to follow through with any `activate` actions.
		 * 
		 */
		public function activate() {
			if ( !_active){
				if (! _disabled){
					// Activate any child assets that have been properly added to this clip
					for each (var childAsset:AssetView in _childAssets) {
						childAsset.activate();
					}
					
					_active = true;
					
					trace("  + " + _clipName + " ACTIVATED");
				} else {
					trace("  + " + _clipName + " NOT activated (disabled)");
				}
			} else {
				trace("  + " + _clipName + " SKIPPING activation");
			}
		}
		
		/**
		 * Deactivate asset and all registered child assets.
		 * 
		 * Override in child classes to remove event listeners etc, remembering to call `super.deactivate()` at the end.
		 */
		public function deactivate() {
			if (_active) {
				// Deactivate any child assets that have been properly added to this clip
				for each (var childAsset:AssetView in _childAssets) {
					childAsset.deactivate();
				}	
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
				
				if (_active) {
					deactivate();
				}

				onDisabled();

				trace("  - " + id + " DISABLED");
			} else {
				trace("  - " + id + " DISABLE skipped (already disabled)");
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
				trace("  + " + id + " ENABLE skipped (already enabled)");
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
		 * Not the same as checking `_active`, this will tell you if the item 
		 * has been activated AND is not disabled.
		 */
		public function get isActive():Boolean {
			return _active && (! _disabled);
		}
		
		public function get isEnabled():Boolean {
			return ! _disabled;
		}
		
		/**
		 * Shortcut to make for easier reading `activate()` overrides.
		 * 
		 * Child classes should test against `activatable()` before performing any
		 * activate activities such as adding event listeners.
		 */
		public function get activatable():Boolean {
			return !_active && !_disabled;
		}
		
		/**
		 * Convenience getter. Child classes can test against this as a best practice
		 * before performing any `deactivate()` tasks, just to avoid doing redundant work.
		 */
		public function get deactivatable():Boolean {
			return _active;
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
		 * 
		 * @uses init() if the clip has not yet been initialized, will call {@link init()}, to kick off asset definition.
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
			
			_parentScreen = _parentAsset.screen;
		}
		
		public function get parentAsset():AssetView {
			return _parentAsset;
		}
		
		public function get screen():ScreenView {
			return _parentScreen;
		}
		
		/**
		 * Traverses up the parentAsset chain to locate the ScreenView that this asset currently
		 * appears on.
		 * 
		 * Once the Screen is found, it gets set as the _parentScreen for this asset.
		 * 
		 * @param	child
		 * @return
		 */
		protected function getParentScreen(child:AssetView = null):ScreenView {
			if (! child) {
				child = this;
			}
			
			if (child.screen) {
				_parentScreen = child.screen;
				return child.screen;
			} else {
				if (child.parentAsset) {
					return getParentScreen(child.parentAsset);
				}
			}
			
			return null;
		}
		
		
		override public function localize(localizer:Localizer):void {
			trace("Localizing Asset '" + id + "'");
			
			_numberFormatter = localizer.numberFormatter;
			
			if (_textFieldName && _textField) {
				setText(_textField, getAssetComponentText(localizer, _textFieldName));
			}
			
			if (_childAssets.length) {
				for each (var childAsset:AssetView in _childAssets) {
					childAsset.localize(localizer);
				}
			}
			
			super.localize(localizer);
		}
		
		/**
		 * Convenience function that interacts with the Localizer to obtain the text for this asset. Tries to pull in the bundleID,
		 * the screenName and the Asset's id to pass to the localizer so it can fetch the corresponding text string from the 
		 * localization XML file.
		 * 
		 * @see Localizer.getAssetComponentText()
		 * 
		 * @param	localizer The Localizer instance
		 * @param	component The ID of the component within this ScreenAsset that we're localizing.
		 * @param	componentID Optional. If multiple components with the same name are present within the asset, provide the unique ID to help the Localizer target the correct string.
		 * @return
		 */
		protected function getAssetComponentText(localizer:Localizer, component:String, componentID:String = ""):String {
			var parentScreen:ScreenView = getParentScreen(this);
			
			if (parentScreen){
				return localizer.getAssetComponentText(parentScreen.bundle.id, parentScreen.name, id, component, componentID);
			} else {
				throw new IllegalOperationError("Calling getAssetComponentText() on an asset that is not attached to any screen.");
			}
		}
		
	}

}