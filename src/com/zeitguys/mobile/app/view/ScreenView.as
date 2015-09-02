package com.zeitguys.mobile.app.view {
	import com.zeitguys.mobile.app.AppBase;
	import com.zeitguys.mobile.app.controller.ScreenRouter;
	import com.zeitguys.mobile.app.model.ILocalizable;
	import com.zeitguys.mobile.app.model.Localizer;
	import com.zeitguys.mobile.app.model.ScreenBundle;
	import com.zeitguys.mobile.app.model.vo.ModalButtonData;
	import com.zeitguys.mobile.app.view.asset.AssetView;
	import com.zeitguys.mobile.app.view.transition.TransitionBase;
	import com.zeitguys.mobile.app.view.ViewBase;
	import com.zeitguys.util.ObjectUtils;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.errors.IllegalOperationError;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	/**
	 * Base class for all ScreenViews across the app (cross-platform).
	 * 
	 * The following hooks are available for child classes to extend, throughout the lifecycle and startup of the screen:
	 * * (Constructor): the screen is added to the queue, and usually loading of its assets starts. Generally we don't do anything here; maybe define the screen model.
	 * 
	 * * onClipLoaded: the screen is loaded and its clip has been transferred to clip. Does not have access to Stage yet.
	 * 
	 * * initStage: Called ONCE per screen, when the screen clip has been added to a DisplayList. That doesn't necessarily mean that it is currently visible. However, it DOES mean that the View has access to all its DisplayObjects, so this is generally where you assign Assets
	 * 
	 * * setupBeforeLocalize: called EVERY time the screen is switched to. Good place to setup variables, etc that might be needed by localize()
	 * * localize: the screen is requesting its locale information. This generally happens after initStage, and is asynchronous, but will always happen before setup. Only do localization activities here.
	 * * setupAfterLocalize: called EVERY time the screen is switched to. Good place to do things with strings that have just been localized.
	 * 
	 * * reset: Potentially called EVERY time the screen is switched to, if the ScreenController is requesting a screen reset. This should reset the View and possibly the Model as well. If you want the screen to reset when requested, but not every time (such as Back button functionality), then reset your View and Model here.
	 *
	 * * activate: Called potentially many times during the lifecycle of a screen. The screen is now active. This is a good place to add event listeners. Each asset then gets activated in turn. You can decide whether to activate the screen first or the assets.
	 * * deactivate: the screen has been deactivated, either because we're leaving the screen or because we're pausing the app, or we have a modal up. Remove any event listeners you have added, here.
	 * 
	 * @author TomAuger
	 */
	public class ScreenView extends ViewBase {
		public static const EVENT_SCREEN_LOADED:String = 'screen-loaded';
		public static const EVENT_SCREEN_READY:String = 'screen-ready';
		public static const EVENT_SCREEN_ACTIVATED:String = 'screen-activated';
		public static const EVENT_SCREEN_DEACTIVATED:String = 'screen-deactivated';
		public static const EVENT_SCREEN_PAUSED:String = 'screen-paused';
		
		protected const STATUS_NOT_READY = "not-ready";
		protected const STATUS_SCREEN_LOADED = "loaded";
		protected const STATUS_READY = "ready";
		protected const STATUS_ACTIVATED = "activated";
		protected const STATUS_PAUSED = "paused";
		protected const STATUS_DEACTIVATED = "deactivated";
		
		protected var _bundle:ScreenBundle;
		protected var _screenRouter:ScreenRouter;
		protected var _assets:Vector.<AssetView> = new Vector.<AssetView>; // @TODO refactor to <AssetView>
		protected var _textFields:Array = [];
		
		public var bundleIndex:uint;
		
		protected var _id:String;
		protected var _bundleLoaded:Boolean = false;
		protected var _screenLoaded:Boolean = false;
		protected var _screenReady:Boolean = false;
		protected var _screenActivated:Boolean = false; // use status to tell whether a screen has been activated. This is used to determine whether first-run initialization activites should take place
		
		protected var _screenArgs:Object = { };
		protected var _TransitionOut:Class;
		protected var _DefaultTransition:Class;
		
		protected var _flexGroups:Vector.<FlexGroup> = new Vector.<FlexGroup>;
		protected var _screenModals:Object = { };
		
		protected var _status:String = STATUS_NOT_READY;
		
		public function ScreenView(screenClip:*, bundle:ScreenBundle = null) {
			if (bundle) {
				// Use the setter with all its special sauce
				this.bundle = bundle;
			}
			
			if (screenClip is DisplayObjectContainer) {
				setClip(DisplayObjectContainer(screenClip));
			} else if (screenClip is String) {
				setClipName(String(screenClip));
				if (_bundleLoaded) {
					setClip(_bundle.getClipByName(name));
				}
			}
			
			_id = generate_id();
			
			// Set the default transition for leaving this screen to TransitionBase (no transition).
			// Child classes should override this default if your app has a unique transition.
			if (! _TransitionOut) {
				_TransitionOut = TransitionBase;
			}
			
			prepare();
		}
		
		
		
		
		
		
		/* ===========================================================================================================
		 *                                                  WORKFLOW
		/* ===========================================================================================================*/
		
		/**
		 * Maybe override in child classes.
		 * The Screen's Bundle has been loaded and the MovieClip associated with this Screen has been assigned to clip.
		 * But the clip may not yet be on any stage, so don't use any reference to stage here.
		 * 
		 * @see #init() If you need a reference to the stage for any reason.
		 */
		protected function onClipLoaded():void {
			
		}
		
		
		/**
		 * Maybe override in child classes.
		 * Screen has just been added to stage, possibly a long time before the screen is ever displayed or used (in the case of the main SWF's clips)
		 * 
		 * This is NOT a good place to initialize the model, or do things that should happen _every time_ we (re)visit this screen, because init() will typically only be called ONCE.
		 * 
		 * Upon completion, screen will be "Ready".
		 */
		protected function initStage():void {
			defineAssets();
			setScreenReady();
			
			trace(id + " INITIALIZED");
		}
		
		/**
		 * Override in child classes.
		 * 
		 * Screen has been added to the stage and it's time to connect all the DisplayObjects created in Flash with
		 * the AssetView classes that give them functionality. This is the place to do it, using {@link addAsset()},
		 * {@link addAssets()} (for more than one asset at a time), or {@link addFlexAsset()}
		 */
		protected function defineAssets():void {
			// Abstract class.
		}
		
		/**
		 * Override in child classes.
		 * This method is called __every__ time a screen is displayed (switched to from another screen), just before localize() is run.
		 * Use this method to setup things that the localizer needs to know about. 
		 * 
		 * @TODO: refactor to work with all AssetViews not just ScreenAssetViews.
		 */
		public function setupBeforeLocalize():void {
			trace("--------------------------------------\n" + id + " SETTING UP (before localization)");
			
			for each (var asset:AssetView in _assets) {
				asset.setupBeforeLocalize();
			}
		}
		
		/**
		 * Localize all assets. Child classes may wish to override and localize other
		 * items as well. Just remember to call super.localize() as well!
		 */
		override public function localize(localizer:Localizer):void {
			trace("LOCALIZING Screen '" + id + "'");
			
			var modalID:String,
				item:Object,
				modal:ModalView,
				button:ModalButtonData;
			
			
			defineModals(localizer);
			
			//if (_screenModals.length) {
				//trace("Localizing Screen Modals.");
			//}
				//
			//for (modalID in _screenModals) {
				//item = _screenModals[modalID];
				//if (item is ModalView) {
					//modal = ModalView(item);
					//
					//// Got the modal. Localize it.
					//modal.setBodyText(localizer.getModalComponentText(modalID, 'body'));
					//
					//for each (button in modal.buttons) {
						//button.label = localizer.getModalComponentText(modalID, button.id);
					//}
				//} else {
					//throw new Error("Error with Screen Modals structure.");
				//}
			//}
			
			for each(var asset:ILocalizable in _assets) {
				asset.localize(localizer);
			}
			
			// Lastly, update all the FlexGroups
			for each (var flexGroup:FlexGroup in _flexGroups) {
				flexGroup.update();
			}
		}
		
		
		
		/**
		 * Abstract method. Override in child classes as needed. This is the best place to define your Screen's Modals,
		 * using addModal().
		 * 
		 * @param	localizer
		 */
		protected function defineModals(localizer:Localizer):void {
			
		}
		
		/**
		 * Override in child classes.
		 * This method is called __every__ time a screen is displayed (switched to from another screen) just after localize() is run.
		 * This is where you should do things like initialize the screen's model, and perform set-ups that should happen every time the screen is displayed.
		 */
		public function setupAfterLocalize():void {
			for each (var asset:AssetView in _assets) {
				asset.setupAfterLocalize();
			}
			
			trace(id + " SETUP (after localization) COMPLETE\n--------------------------------------");
		}
		
		/**
		 * Override in child classes.
		 * 
		 * This method is called when a screen is displayed and a reset request has been dispatched (usually through a ScreenController call from
		 * the previous screen).
		 * 
		 * Use reset() if the decision whether to reset the screen needs to be made by the previous screen before switching to the current one.
		 */
		public function reset():void {
			for each (var asset:AssetView in _assets) {
				asset.reset()
			}
			
			trace(id + " RESET");
		}
		
		
		
		
		/**
		 * Called by AppBase.screenTransitionComplete().
		 * 
		 * Resets the current `TransitionOut` to the `DefaultTransition`, then calls {@link activate()}.
		 * 
		 * Child screens may override this to do things post transition, but prior to activation.
		 * 
		 * If you are running any animations on the screen after the transition, but before activation,
		 * you may use `super.onTransitionComplete()` as your animation complete callback.
		 */
		public function onTransitionComplete():void {
			_TransitionOut = _DefaultTransition;
			
			// If the app is bricked or suspending, then this will not fire.
			if (app.isReady){
				activate();
			}
		}
		
		/**
		 * Override in child classes.
		 * Screen has finished transitioning and has been activated. Note that this could happen multiple times within one screen "session" if the app is shutdown or paused.
		 * This is where you should add any event listeners for interactivity, start animations, etc.
		 * 
		 * Be sure to call super.activate() at the END of your override, or you won't get automatic asset activation, which is pretty central to how this whole thing works. 
		 * Many child classes (eg: {@link ScrollingScreenView} have built-in logic here, so, really, super.activate();
		 */
		public function activate():void {
			if (! app.isModal) {
				activateAssets();
				
				trace(id + " ACTIVATED\n--------------------------------------");
			} else {
				trace(id + " NOT ACTIVATED: currently MODAL.");
			}
		}
		
		public function activateAssets():void {
			trace(id + " ACTIVATING Assets");
			for each (var asset:AssetView in _assets) { 
				asset.activate();
			}
		}
		
		/**
		 * Override in child classes when you wnat to handle reactivation from app paused state.
		 */
		public function resume():void {
			trace(id + " RESUMING");
			
			activate();
		}
		
		/**
		 * Called when a modal dialog is invoked on this screen.
		 * 
		 * Child classes can override this method in order to do something specifially
		 * when a modal is invoked.
		 * 
		 * Remember to call super.enterModal().
		 */
		public function enterModal():void {
			trace(id + " entering MODAL");
			
			deactivate();
		}
		
		/**
		 * Called when a modal dialog is dismissed on this screen.
		 * 
		 * Child classes can override this method in order to restore anything
		 * that might have been halted on {@link /enterModal()}.
		 * 
		 * Remember to call super.exitModal().
		 */
		public function exitModal():void {
			trace(id + " exiting MODAL");
			
			activate();
		}
		
		/**
		 * Override in child classes when you want to handle deactivation due to app pausing.
		 */
		public function pause():void {
			trace(id + " PAUSED");
			
			deactivate();
		}
		
		/**
		 * All child classes must override `deactivate()` to unregister event listeners
		 * and kill any processes that should not be running when the screen is not active.
		 * 
		 * Screens are deactivated when:
			 * The app is paused
			 * The app goes modal
			 * The screen starts to transition out
		 *
		 * Remember to call super.deactivate() so all registered screen assets
		 * are automatically deactivated as well.
		 */
		public function deactivate():void {
			deactivateAssets();
			
			trace(id + " DEACTIVATED");
		}
		
		/**
		 * Deactivate all screen assets. Called by {@link /deactivate()}
		 */
		private function deactivateAssets():void {
			trace("--------------------------------------\n" + id + " DEACTIVATING Assets");
			for each (var asset:AssetView in _assets) {
				asset.deactivate();
			}
		}
		
		/**
		 * Child classes should override this if they wish to trigger an action
		 * upon leaving the screen. This is called after {@link /deactivate()},
		 * so you must assume that all assets are deactivated, event
		 * listeners have been killed etc.
		 */
		public function onTransitionOut():void {
			
		}
		
		
		
		
		
		
		/* ===========================================================================================================
		 *                                          ASSETS and FLEXGROUPS
		/* ===========================================================================================================*/
		
		
		
		/**
		 * Adds an asset to the Screen, but only if the asset hasn't already been added!
		 * 
		 * Used by {@link FlexGroup.registerAssetWithScreen()}.
		 * 
		 * @param	asset
		 * @return
		 */
		public function registerAsset(asset:AssetView):AssetView {
			if (_assets.indexOf(asset) == -1) {
				addAsset(asset);
			}
			
			return asset;
		}
		
		/**
		 * Adds a single asset to the asset list. It's important to add assets to the ScreenView using this method
		 * to let the ScreenView know about the assets. This is particularly relevant during the localize()
		 * activate() and deactivate() phases.
		 * 
		 * @param	asset
		 * @return
		 */
		protected function addAsset(asset:AssetView):AssetView {
			asset.screen = this;
			_assets.push(asset);
			
			return asset;
		}
		
		protected function addFlexGroup():FlexGroup {
			var flexGroup:FlexGroup = new FlexGroup(this);
			_flexGroups.push(flexGroup);
			
			return flexGroup;
		}
		
		/**
		 * Convenience method that:
			 * adds an Asset to the screen (see {@link /addAsset})
			 * intantiates a FlexItem for the Asset
			 * adds the FlexItem to the FlexGroup
			 * returns the FlexItem (so it can be used as the parent of some other FlexItem, or be used to register event listeners against, etc)
			 * 
		 * At this point, probably the preferred method of adding assets to a Screen, if the assets are in a FlexGroup.
		 * 
		 * @param	flexGroup
		 * @param	asset
		 * @param	parentItem
		 * @return
		 */
		protected function addFlexAsset(flexGroup:FlexGroup, asset:AssetView, parentItem:FlexItem = null):FlexItem {
			return flexGroup.addAsset(addAsset(asset), parentItem);
		}
		
		
		
		
		
		
		/**
		 * Sets both the default transitioni and the current TransitionOut.
		 * 
		 * The difference between the two is that TransitionOut is reset to the default
		 * transition whenever onTransitionComplete() runs.
		 */
		protected function set DefaultTransition(TransitionClass:Class):void {
			if (ObjectUtils.inheritsFrom(TransitionClass, TransitionBase)) {
				_DefaultTransition = _TransitionOut = TransitionClass;
			} else {
				throw new ArgumentError(TransitionClass + " must inherit from TransitionBase");
			}
		}
		
		/**
		 * Call this before onTransitionComplete() to set the transition when leaving this screen.
		 */
		public function set TransitionOut(TransitionClass:Class):void {
			if (ObjectUtils.inheritsFrom(TransitionClass, TransitionBase)) {
				_TransitionOut = TransitionClass;
			} else {
				throw new ArgumentError(TransitionClass + " must inherit from TransitionBase");
			}
		}
		
		/**
		 * Used by the TransitionManager to get the transition used to transition out this screen.
		 * 
		 * Make sure you set the transition before any calls to ScreenRouter.setScreen()
		 */
		public function get TransitionOut():Class {
			return _TransitionOut;
		}
		
		
		
		
		
		/**
		 * Screen has been loaded and now we are sure to have a clip. But it may not yet be added to the stage.
		 * 
		 * @see /onClipLoaded()
		 * 
		 * @param	event
		 */
		private function onScreenLoaded():void {
			// This is a good time to capture the original coordinates of the clip.
			_clipOrigX = clip.x;
			_clipOrigY = clip.y;
			
			onClipLoaded();
			
			if (clip.parent) { 
				onAdded();
			} else {
				clip.addEventListener(Event.ADDED, onAdded, false, 0, true);
			}
		}
		
		/**
		 * Initialize the screen. This sequences all the start-up activities that will
		 * occur with the screen, possibly long before it is ever displayed.
		 * 
		 * 
		 * @see		#initStage() for an easier way to add Screen-specific start-up activities (such as setting default values, etc)
		 * 
		 * @param	event
		 */
		private function onAdded(event:Event = null):void {
			if (event){
				clip.removeEventListener(Event.ADDED, onAdded);
			}
			
			initStage();
		}
		
		public function set bundle(bundle:ScreenBundle):void {
			_bundle = bundle;
			
			if (hasClip) {
				if (_bundle.loaded && name) {
					setClip(bundle.getClipByName(name));
					if (clip) {
						prepare();
					}
				}
			}
			
			_id = generate_id();
		}
		
		public function get bundle():ScreenBundle {
			return _bundle;
		}
		
		public function get router():ScreenRouter {
			return app.router;
		}
		
		/**
		 * Generally used by the App to send messages to the ScreenView,
		 * usually from the previous screen, to establish the context of the
		 * incoming screen.
		 * 
		 * Avoid using this mechanism for sharing large amounts of data across screens.
		 * The best practice is to create a shared model (often a Singleton)
		 * that multiple ScreenView instances can access.
		 */
		public function set screenArgs(args:Object):void {
			_screenArgs = args;
		}
		
		/**
		 * Get all args set 
		 */
		public function get screenArgs():Object {
			return _screenArgs;
		}
		
		/**
		 * Get a single arg's value.
		 * 
		 * @param	arg Argument name (key)
		 * @param	failOnArgNotExists Generally will throw an error if you try to access an arg that is not defined. If you're not sure it will be defined, you can set this to false and bypass the error. However, it is recommended that you explicitly test using hasArg() first.
		 * @return
		 */
		public function getScreenArg(arg:String, failOnArgNotExists:Boolean = true):* {
			if (hasScreenArg(arg)) {
				return _screenArgs[arg];
			} else {
				if (failOnArgNotExists){
					throw new ArgumentError("Screen arg '" + arg + "' is not defined.");
				}
			}
			
			return null;
		}
		
		/**
		 * Set an individual Screen Argument. If you have multiple ScreenArgs to set at once,
		 * consider just using {@link set screenArgs()} and pass the complete object.
		 * 
		 * @param	arg Argument name (key)
		 * @param	value
		 */
		public function setScreenArg(arg:String, value:*):void {
			_screenArgs[arg] = value;
		}
		
		/**
		 * Tests whether the arg has been set by the previous screen.
		 * 
		 * @param	arg
		 * @return
		 */
		public function hasScreenArg(arg:String):Boolean {
			return _screenArgs.hasOwnProperty(arg);
		}
		
		/**
		 * Prepares the screen by ensuring that it has a proper clip (once the Bundle has loaded).
		 * If all is ready, will fire {@link #setScreenLoaded()} which will trigger EVENT_SCREEN_LOADED
		 */
		public function prepare():void {
			if (! screenLoaded) {
				if (_bundle && _bundle.loaded) {
					_bundleLoaded = true;
				}
				
				if (_bundleLoaded && ! hasClip && name) {
					setClip(_bundle.getClipByName(name));
				}
				
				if (_bundleLoaded && hasClip){
					setScreenLoaded();
				}
			}
		}
		
		protected function set status(status:String):void {
			if (status !== _status) {
				_status = status;
				trace("Screen '" + id + "' STATUS: " + status);
				
				switch(_status) {
					case STATUS_SCREEN_LOADED:
						dispatchEvent(new Event(EVENT_SCREEN_LOADED));
						break;
						
					case STATUS_READY:
						dispatchEvent(new Event(EVENT_SCREEN_READY));
						break;
				}
			}
		}
		
		public function get screenLoaded():Boolean {
			return _screenLoaded;
		}
		
		protected function setScreenLoaded():void {
			if (! _screenLoaded) {
				_screenLoaded = true;
				
				status = STATUS_SCREEN_LOADED;
				onScreenLoaded();
			}
		}
		
		protected function setScreenReady():void {
			if  (! _screenReady) {
				_screenReady = true;
				
				status = STATUS_READY;
			}
		}
		
		
		
		/**
		 * Define the list of assets (buttons, textboxes, interactive elements) that are present in this Screen.
		 * @param	assets
		 */
		protected function addAssets(assets:Vector.<AssetView>):void {
			for each(var asset:AssetView in assets) {
				addAsset(asset);
			}
		}
		
		/**
		 * Convenience function that interacts with the Localizer to obtain the text for this asset. Automatically provides the
		 * bundleID, the screenName and the id of the asset to make for more compact and readable code when localizing asset types
		 * defined in subclasses of ScreenAssetView.
		 * 
		 * @see Localizer.getAssetComponentText()
		 * 
		 * @param	localizer The Localizer instance
		 * @param 	assetID The ID of the Asset we're localizing
		 * @param	component The ID of the component within this ScreenAsset that we're localizing.
		 * @param	componentID Optional. If multiple components with the same name are present within the asset, provide the unique ID to help the Localizer target the correct string.
		 * @return
		 */
		protected function getAssetComponentText(localizer:Localizer, assetID:String, component:String, componentID:String = ""):String {
			return localizer.getAssetComponentText(bundle.id, name, assetID, component, componentID);
		}
		
		
		private function generate_id():String {
			var id:String = "";
			if (_bundle) {
				id += _bundle.id;
			} else {
				id += "<no_bundle>"
			}
			id += "__";
			
			if (name) {
				id += name;
			} else {
				id += "<no_clip>";
			}
			
			return id;
		}
		
		/**
		 * The ID of the screen is a concatenation of its bundle and its clipname, eg: main__home
		 */
		public function get id():String {
			return _id;
		}		
		
		
		
		
		/* ===========================================================================================================
		 *                                                   MODALS
		/* ===========================================================================================================*/
		
		protected function addModal(id:String, bodyText:String = "", ... modalArgs):ModalView {
			trace("Adding Screen Modal [" + id + "]");
			
			var modal:ModalView = app.getModal.apply(this, [bodyText].concat(modalArgs));
			_screenModals[id] = modal;
			
			return modal;
		}
		
		protected function getModal(id:String):ModalView {
			if (_screenModals.hasOwnProperty(id)) {
				return ModalView(_screenModals[id]);
			} else {
				throw new RangeError("Modal with ID '" + id + "' has not been defined!");
			}
		}
		
		protected function setModal(id:String):ModalView {
			var modal:ModalView = getModal(id);
			
			app.currentModal = modal;
			
			return modal;
		}
		
		protected function getModalComponentText(localizer:Localizer, alertID:String, component:String):String {
			return localizer.getModalComponentText(alertID, component);
		}
		
		
		
	}

}