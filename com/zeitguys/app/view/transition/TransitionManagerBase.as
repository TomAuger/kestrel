package com.zeitguys.app.view.transition 
{
	import com.zeitguys.util.ObjectUtils;
	import flash.desktop.NotificationType;
	import flash.display.MovieClip;
	import flash.events.Event;
	import com.zeitguys.app.view.ScreenView;
	import flash.geom.Rectangle;
	
	/**
	 * ...
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
		
		protected var _previousScreen:ScreenView;
		protected var _currentScreen:ScreenView;
		
		protected var _transitioning:Array = [];
		
		private static var __stageDimensions:Rectangle;
		
		public function TransitionManagerBase(stageRect:Rectangle) {
			__stageDimensions = stageRect;
			
			addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		
		
		
		/**
		 * Transitions the old screen to the new screen.
		 * @param	newScreen
		 */
		public function transition(newScreen:ScreenView, TransitionClass:Class = null):void {
			trace("-------------------------------------------\nStarting TRANSITION", TransitionClass);
			
			if (_currentScreen) {
				if (newScreen !== _currentScreen) {
					_previousScreen = _currentScreen;
					_currentScreen = newScreen;
					
					startTransition(TransitionClass);
					
					if (_transitionOrder == TRANSITION_ORDER_OUT_FIRST) {
						startTransitionOut();
						startTransitionIn();
						_transitionModule.transitionOut();
						_transitionModule.transitionIn();
					} else {
						startTransitionIn();
						startTransitionOut();
						_transitionModule.transitionIn();
						_transitionModule.transitionOut();
					}
				} else {
					trace("Transition SKIPPED: new screen IS current screen.");
				}
			} else {
				_currentScreen = newScreen;
				startTransition(TransitionClass);
				
				startTransitionIn();
				_transitionModule.startFirstTransition();
			}
		}
		
		public function getStageDimensions():Rectangle {
			return __stageDimensions;
		}
		
		public function get stageWidth():Number {
			return __stageDimensions.width;
		}
		
		public function get stageHeight():Number {
			return __stageDimensions.height;
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
		
		
		/**
		 * Sets the transition module, and passes the current screen and previous screen to it.
		 * 
		 * Can only be called after {@link /transition()} because otherwise _currentScreen and _previousScreen will
		 * not be valid.
		 */
		private function set transitionModule(TransitionClass:Class):void {
			if (ObjectUtils.inheritsFrom(TransitionClass, TransitionBase)) {
				_transitionModule = new TransitionClass(this, _currentScreen, _previousScreen);
			} else {
				throw new ArgumentError(TransitionClass + " must inherit from TransitionBase.");
			}
		}
		
		/**
		 * Sets the transition class. Child classes may wish to change the default behaviour to "remember"
		 * the previous transition.
		 * 
		 * @param	TransitionClass
		 */
		protected function startTransition(TransitionClass:Class = null):void {
			if (TransitionClass) {
				transitionModule = TransitionClass;
			} else {
				transitionModule = TransitionBase;
			}
		}
		
		/**
		 * Outgoing transition for previousScreen.
		 * @see #transitionOut() for a more convenient way for child classes to define the transition out
		 */
		private function startTransitionOut():void {	
			_transitioning.push(true);
		}
		
		/**
		 * Incoming transition for currentScreen.
		 * 
		 * @see #transitionIn()
		 */
		private function startTransitionIn():void {
			_transitioning.push(true);
		}
		
		public function endTransitionOut():void {
			_transitionModule.transitionOutComplete();
			
			_transitioning.shift();
			checkTransitionComplete();
		}
		
		public function endTransitionIn():void {
			_transitionModule.transitionInComplete();
			
			_transitioning.shift();
			checkTransitionComplete();
		}
		
		protected function checkTransitionComplete():void {
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