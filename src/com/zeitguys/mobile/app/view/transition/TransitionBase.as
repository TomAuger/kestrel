package com.zeitguys.kestrel.app.view.transition {
	import com.zeitguys.kestrel.app.view.ScreenView;
	import flash.errors.IllegalOperationError;
	import flash.events.EventDispatcher;
	
	/**
	 * ...
	 * @author TomAuger
	 */
	public class TransitionBase extends EventDispatcher {
		private var _transitionManager:TransitionManagerBase;
		private var _incomingScreen:ScreenView;
		private var _outgoingScreen:ScreenView;
		
		public function TransitionBase(transitionManager:TransitionManagerBase, incomingScreen:ScreenView, outgoingScreen:ScreenView) {
			_transitionManager = transitionManager;
			_incomingScreen = incomingScreen;
			_outgoingScreen = outgoingScreen;
		}
		
		protected function get transitionManager():TransitionManagerBase {
			return _transitionManager;
		}
		
		protected function get incomingScreen():ScreenView {
			return _incomingScreen;
		}
		
		protected function get outgoingScreen():ScreenView {
			return _outgoingScreen;
		}
		
		
		/**
		 * Only used the very first time, when there's no _previousScreen.
		 * 
		 * Generally, this should be a flat, straight-cut transition, or maybe
		 * some kind of fade-in / fade-up.
		 */
		public function startFirstTransition() {
			transitionIn();
		}
		
		
		/**
		 * Start the previous (outgoing) screen's transition out
		 */
		public function transitionOut():void {
			// No transition. Go directly to endTransitionOut().
			endTransitionOut();
		}
		
		/**
		 * Start the new (incoming) screen's transition in
		 */
		public function transitionIn():void {
			trace("--------------------------------------\nTransitioning IN: '" + _incomingScreen.id + "'.");
			
			// No transition
			endTransitionIn();
		}
		
		/**
		 * Your child transition class should call endTransitionOut() and endTransitionIn(), but probably won't want
		 * to override them, preferring instead to override transitionOutComplete() and transitionInComplete() for cleanup
		 * and detaching.
		 * 
		 * To end a transition, your child class MUST call both endTransitionOut() and endTransitionIn().
		 * 
		 * This in turn calls TransitionManagerBase.endTransitionOut() and In() respectively,
		 * which will then call your child classes transitionOutComplete() and transitionInComplete() respectively.
		 * 
		 * Once both have been accounted for, the transition is ended and TransitionManagerBase dispatches EVENT_TRANSITION_COMPLETE.
		 */
		protected function endTransitionOut():void {
			transitionManager.endTransitionOut();
		}
		
		protected function endTransitionIn():void {
			transitionManager.endTransitionIn();
		}
		
		
		/**
		 * Previous screen's transition out is complete. Perform cleanup of previous screen.
		 */
		public function transitionOutComplete():void {
			if (outgoingScreen) {
				outgoingScreen.detach();
			} else {
				throw new IllegalOperationError("outgoingScreen cannot be found! Are you killing it before transitionOutComplete() or calling endTransitionOut() twice?");
			}
			_outgoingScreen = null; // Might want to keep the previous screen in some situations.
		}
		
		/**
		 * Incoming screen's transition in is complete. You can activate the screen here, or perhaps better to defer to the app on EVENT_TRANSITION_COMPLETE.
		 */
		public function transitionInComplete():void {
			incomingScreen.attachTo(transitionManager);
			_incomingScreen = null;
		}
	
	}

}