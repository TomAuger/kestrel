package com.zeitguys.mobile.app.view.transition {
	import com.zeitguys.mobile.app.AppBase;
	import com.zeitguys.util.ObjectUtils;
	import flash.desktop.NotificationType;
	import flash.display.MovieClip;
	import flash.events.Event;
	import com.zeitguys.mobile.app.view.ScreenView;
	import flash.geom.Rectangle;
	
	/**
	 * Manages transitions between Screens.
	 * 
	 * The actual Transitions themeselves are defined as "modules": classes that extend the TransitionBase base class.
	 * The Transition manager delegates the actual transition itself to the Transition module.
	 * 
	 * TransitionManager is an actual MovieClip that sits at the root level of the app and contains the current screen.
	 * Any screen that's visible is a child of the TransitionManager.
	 * 
	 * Generally, the TransitionManager holds two screens: the "outgoing" screen and the "incoming" screen.
	 * The only time this isn't true is the first time a screen is transitioned (the first screen), in which
	 * case there's only the "incoming" screen.
	 * 
	 * Transitions are triggered via TransitionManager.transition(), passing in a reference to the new screen.
	 * The previous (ie: "outgoing") screen is already known by TransitionManager, being stored in _previousScreen.
	 * 
	 * Apps / Routers listen for `EVENT_TRANSITION_COMPLETE` to know when to continue (for example, when
	 * to Activate the screen assets). 
	 * 
	 * @author TomAuger
	 */
	public class TransitionManagerBase extends MovieClip {
		public static const EVENT_TRANSITION_COMPLETE:String = 'transition-complete';
		
		protected const TRANSITION_ORDER_OUT_FIRST:String = 'transition-out-first';
		protected const TRANSITION_ORDER_IN_FIRST:String = 'transition-in-first';
		/**
		 * Whether to trigger the out transition before the in transition. May make a slight difference in timing. Can be changed in child classes.
		 */
		protected var _transitionOrder:String = TRANSITION_ORDER_OUT_FIRST;
		
		protected var _transitionModule:TransitionBase;
		protected var _TransitionModuleClass:Class; // just for traces, really.
		protected var _defaultTransition:Class;
		
		protected var _previousScreen:ScreenView;
		protected var _currentScreen:ScreenView;
		
		protected var _transitioning:Array = [];
		
		private var _stageDimensions:Rectangle;
		private var _app:AppBase;
		
		/**
		 * Constructor.
		 * 
		 * @param	stageRect Stage dimensions
		 * @param	app Reference to the main Kestrel app
		 * @param	defaultTransition Optional. If set, will set the default transition if not defined in the ScreenView.
		 * 				Note that ScreenView defines TransitionBase as its default transition. Primarily used for the transition
		 * 				to the very first screen (from the Splash screen).
		 */
		public function TransitionManagerBase(stageRect:Rectangle, app:AppBase, defaultTransition:Class = null) {
			_stageDimensions = stageRect;
			_app = app;
			
			this.name = "KestrelTransitionManager"; // makes debugging / traces nicer.
			
			if (defaultTransition) {
				if (ObjectUtils.inheritsFrom(defaultTransition, TransitionBase)) {
					_defaultTransition = defaultTransition;
				} else {
					throw new ArgumentError(defaultTransition + " must inherit from TransitionBase, or leave empty.");
				}
			} else {
				_defaultTransition = TransitionBase;
			}
			
			addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		
		
		/**
		 * Transitions the old screen to the new screen.
		 * 
		 * The current screen becomes `_previousScreen` and the incoming (new) screen
		 * becomes the `_currentScreen`.
		 * 
		 * TransitionManager kicks off transitions with `registerTransitionIn()` and `registerTransitionOut()`
		 * which push both transitions onto the _transitioning stack (a poor man's Promise, really).
		 * 
		 * It's up to the transition module to close the loop and call `completeTransitionIn()` and `completeTransitionOut()`
		 * in order for the TransitionManager to know when the transition has completed and to fire `EVENT_TRANSITION_COMPLETE`.
		 * 
		 * @param	newScreen
		 */
		public function transition(newScreen:ScreenView):void {
			if (_currentScreen) {
				if (newScreen !== _currentScreen) {
					_previousScreen = _currentScreen;
					_currentScreen = newScreen;
					
					setTransitionModule(_previousScreen.TransitionOut);
					
					
					trace("-------------------------------------------\nStarting TRANSITION", _TransitionModuleClass);
					if (_transitionOrder == TRANSITION_ORDER_OUT_FIRST) {
						registerTransitionOut();
						transitionModule.transitionOut();
						
						registerTransitionIn();
						transitionModule.transitionIn();
					} else {
						registerTransitionIn();
						transitionModule.transitionIn();
						
						registerTransitionOut();
						transitionModule.transitionOut();
					}
				} else {
					trace("Transition SKIPPED: new screen IS current screen.");
					transitionComplete();
				}
			} else {
				_currentScreen = newScreen;
				setTransitionModule(_defaultTransition);
				
				trace("-------------------------------------------\nStarting FIRST TRANSITION", _TransitionModuleClass);
				registerTransitionIn();
				transitionModule.startFirstTransition();
			}
		}
		
		
		/**
		 * Sets the transition module, and passes the current screen and previous screen to it.
		 * 
		 * Note that we're passing the Class (name) itself, not an instance of TransitionBase. This method
		 * instantiates the TransitionClass and assigns it to _transitionModule;
		 * 
		 * Can only be called after {@link /transition()} because otherwise _currentScreen and _previousScreen will
		 * not be valid.
		 */
		protected function setTransitionModule(TransitionClass:Class = null):void {
			if (! TransitionClass) {
				TransitionClass = _defaultTransition;
			}
			
			if (ObjectUtils.inheritsFrom(TransitionClass, TransitionBase)) {
				_transitionModule = new TransitionClass(this, _currentScreen, _previousScreen);
				_TransitionModuleClass = TransitionClass;
			} else {
				throw new ArgumentError(TransitionClass + " must inherit from TransitionBase.");
			}
		}
		
		
		/**
		 * Must be called by Transition modules when the outgoing screen's transition is complete.
		 * 
		 * Calls {@link checkAllTransitionsComplete()} to trigger `EVENT_TRANSITION_COMPLETE` if both
		 * the outgoing and incoming screens' transitions have completed.
		 */
		public function completeTransitionOut():void {
			_transitionModule.transitionOutComplete();
			
			_transitioning.shift();
			checkAllTransitionsComplete();
		}
		
		/**
		 * Must be called by Transition modules when the incoming screen's transition is complete.
		 * 
		 * Calls {@link checkAllTransitionsComplete()} to trigger `EVENT_TRANSITION_COMPLETE` if both
		 * the outgoing and incoming screens' transitions have completed.
		 */
		public function completeTransitionIn():void {
			_transitionModule.transitionInComplete();
			
			_transitioning.shift();
			checkAllTransitionsComplete();
		}
		
		
		
		
		public function getStageDimensions():Rectangle {
			return _stageDimensions;
		}
		
		public function get stageWidth():Number {
			return _stageDimensions.width;
		}
		
		public function get stageHeight():Number {
			return _stageDimensions.height;
		}
		
		public function get app():AppBase {
			return _app;
		}
		
		
		/**
		 * Override in child classes.
		 */
		protected function initialize():void {
			trace("TransitionManager INITIALIZED!");
		}
		
		
		private function init(event:Event):void {
			removeEventListener(Event.ADDED_TO_STAGE, init);
			
			initialize();
		}
		
		protected function get transitionModule():TransitionBase {
			return _transitionModule;
		}
		
		/**
		 * Outgoing transition for previousScreen.
		 * @see #transitionOut() for a more convenient way for child classes to define the transition out
		 */
		private function registerTransitionOut():void {	
			_transitioning.push(true);
		}
		
		private function registerTransitionIn():void {
			_transitioning.push(true);
		}
		
		protected function checkAllTransitionsComplete():void {
			if (0 === _transitioning.length) {
				transitionComplete();
			}
		}
		
		private function transitionComplete():void {
			trace("Screen transition COMPLETE.\n--------------------------------------");
			dispatchEvent(new Event(EVENT_TRANSITION_COMPLETE));
		}
		
	}

}