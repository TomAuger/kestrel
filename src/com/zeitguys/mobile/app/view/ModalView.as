package com.zeitguys.mobile.app.view {
	import com.zeitguys.mobile.app.error.FlashConstructionError;
	import com.zeitguys.mobile.app.model.ILocalizable;
	import com.zeitguys.mobile.app.model.vo.ModalButtonData;
	import com.zeitguys.util.ClipUtils;
	import com.zeitguys.util.TextUtils;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import flash.utils.Dictionary;
	
	/**
	 * ...
	 * @author TomAuger
	 */
	public class ModalView extends ViewBase {
		public static const EVENT_CLOSE:String = 'close';
		
		public static const BUTTON_OK:String = 'ok';
		public static const BUTTON_CANCEL:String = 'cancel';
		public static const BUTTON_MISC:String = 'misc';
		
		public static const ALIGNMENT_CENTERED:String = 'alignment-centered';
		
		protected var _parent:DisplayObjectContainer;
		protected var _bodyText:TextField;
		protected var _bg:MovieClip;
		
		protected var _flexGroup:FlexGroup = new FlexGroup;
		
		protected var _buttons:Vector.<ModalButtonData> = new Vector.<ModalButtonData>;
		protected var _buttonLookup:Object = { };
		protected var _pressedButton:String;
		
		public function ModalView(parentClip:DisplayObjectContainer, bodyText:String, buttons:Vector.<ModalButtonData> = null ) {
			_parent = parentClip;
			
			defineTextFields();
			defineButtons(buttons);
			defineBackground();
			
			defineFlexItems();
			
			populateModal(bodyText, buttons);
			updateFlexGroup();
			alignModal(alignmentMode);
			
			//setupInteractivity();
			//
			//displayModal();
		}
		
		public function open():void {
			activate();
			
			displayModal();
		}
		
		/**
		 * Closes and destroys the modal.
		 * 
		 * Generally called by the modal itself on button click, but could theoretically be called by the view or the app directly
		 * to force the dialog to close (for example, due to a timer event, or perhaps the app losing focus).
		 * 
		 * @see /doButtonUp()
		 * 
		 * @TODO There's a bit of an issue with how this all plays out. The modal is deactivated AFTER it's closed, which seems weird,
		 * and IS weird from a trace standpoint. The issue is with how the modal is DESTROYED - we don't want to destroy the data in
		 * the modal until after the app has had a chance to process the result of the modal click - ie, after EVENT_CLOSE is reponded to.
		 * 
		 * This leaves us in an ackward situation at best. We want to keep the modal in some kind of suspended state that will deactivate
		 * before the app has a chance to bring the screen back, but not destroy until that piece is done.
		 * 
		 * From a trace point it's a bit weird. The problem is that if for some really weird reason you invoke the same modal as the
		 * result of dismissing that modal, the app hangs, because the modal activates itself and then immediately deactivates itself
		 * as the result of the previous `deactivate()` that wasn't processed yet.
		 * 
		 * Bottom line: don't chain the same modal off itself! For now.
		 */
		public function close():void {
			var buttonData:ModalButtonData = getButtonByID(_pressedButton);
			
			removeModal();
			
			dispatchEvent(new Event(EVENT_CLOSE));
			
			if (buttonData && buttonData.hasCallback) {
				doButtonUpCallback(buttonData.callback);
			}
			
			__destroy();
		}
		
		/**
		 * Define any non-button TextFields.
		 * 
		 * Maybe override in child classes if you need, for example, a Header as well as a Body text.
		 */
		protected function defineTextFields():void {
			_bodyText = new TextField();
		}
		
		/**
		 * Define all the buttons in the modal, as dictated by the `buttons` Vector.
		 * 
		 * Probably no need to override this in child classes unless you want a completely custom modal.
		 * 
		 * @param	buttons
		 */
		protected function defineButtons(buttons:Vector.<ModalButtonData>):void {
			var i:uint, l:uint,
				buttonIndex:uint,
				buttonData:ModalButtonData;
			
			if (buttons){
				for (i = 0, l = buttons.length; i < l; ++i) {
					buttonData = buttons[i];
					if (! buttonData.hasClip) {
						buttonData.clip = createButtonClip(buttonData.id);
					}
					
					if (buttonData.hasClip){
						buttonIndex = _buttons.push(buttonData) - 1;
						_buttonLookup[buttons[i].id] = buttonIndex;
					} else {
						throw new Error("Button definition '" + buttonData.id + "' has no associated MovieClip.");
					}
				}
			}
			
			// Make sure we have an "OK" button
			if (_buttons.length < 1) {
				_buttons.push(new ModalButtonData(BUTTON_OK, "OK", null, createButtonClip(BUTTON_OK)));
				_buttonLookup[BUTTON_OK] = buttonIndex;
			}
		}
		
		/**
		 * Override in child classes. Creates the button MovieClip, or gets it from the _clip.
		 * 
		 * @param	buttonID
		 * @return
		 */
		protected function createButtonClip(buttonID:String):MovieClip {
			return new MovieClip;
		}
		
		/**
		 * Override in child classes that have a background. Used by the FlexGroup to define the modal background.
		 * 
		 * In order for the background to scale properly, make sure it is 9-sliced if it has non-square corners.
		 */
		protected function defineBackground():void {
			_bg = new MovieClip;
		}
		
		/**
		 * Probably don't override in child classes. Based on your TextFields, Buttons and background,
		 * creates the Flex list so that the dialog can properly grow and shrink according to the amount
		 * of text in each field.
		 * 
		 * If your custom modal needs to insert something (like a separator), seriously consider using
		 * the filter {@link filterDefineFlexItems()} rather than overriding this method.
		 * 
		 * @param	parentItem
		 * @return
		 */
		protected function defineFlexItems(parentItem:FlexItem = null):FlexItem {
			var buttonParentItem:FlexItem,
				i:uint, l:uint;
			
			if (_bodyText) {
				parentItem = filterDefineFlexItems(_flexGroup.addClip(_bodyText, parentItem));
			}
			
			if (_buttons.length) {
				buttonParentItem = parentItem;
				
				for (i = 0, l = _buttons.length; i < l; ++i) {
					if (_buttons.length > maxButtonsInRow) {
						// Vertical layout - each FlexItem is the parent of the next
						parentItem = filterDefineFlexItems(_flexGroup.addClip(_buttons[i].clip, parentItem));
					} else {
						// Horizontal layout - all FlexItems are children of the same parent
						parentItem = filterDefineFlexItems(_flexGroup.addClip(_buttons[i].clip, buttonParentItem));
					}	
				}
			} else {
				throw new Error("A dialog must define at least 1 button!");
			}
			
			if (_bg && _bg.parent) {
				_flexGroup.backgroundItem = _bg;
			}
			
			return parentItem;
		}
		
		/**
		 * Use this filter if you need to insert some other clip in-between the existing FlexItems.
		 * 
		 * Be sure to return the item(s) that you create in the filter, so that you don't break the chain.
		 * 
		 * Insert an item __after__ its parent item using this pattern:
		 * <pre>
		 * 	if ('myClip' == parentItem.displayObject.name){
		 *     return _flexGroup.addItem({{item}}, parentItem);
		 *  }
		 * </pre>
		 * 
		 * Of course you can use `flexGroup.addClip()` as well.
		 * 
		 * @param	parentItem
		 * @return
		 */
		protected function filterDefineFlexItems(parentItem:FlexItem):FlexItem {
			return parentItem;
		}
		
		/**
		 * Override this in child classes to control the threshold that switches
		 * between horizontal and vertical display. (ie: simple modal vs. action sheet).
		 */
		protected function get maxButtonsInRow():uint {
			return 2;
		}
		
		/**
		 * Maybe override in child classes if you have additional text fields that you
		 * need to populate or have some really custom button code that doesn't match
		 * the pattern.
		 * 
		 * You'll probably want to call `super.populateModal()` at some point to make sure
		 * you don't lose the magic here.
		 * 
		 * @see /setTextFieldContent() for a good way to actually set the text and keep the formatting.
		 * 
		 * @param	bodyText
		 * @param	buttons
		 */
		protected function populateModal(bodyText:String, buttons:Object):void {
			var buttonData:ModalButtonData,
				labelTextField:TextField;
			
			
			setBodyText(bodyText);
	
			for each (buttonData in _buttons) {
				labelTextField = TextField(getRequiredChildByName("label", TextField, buttonData.clip));
				TextUtils.setTextFieldContent(labelTextField, buttonData.label);
			}
		}
		
		/**
		 * Override in child functions that need to do something before or after the FlexGroup updates.
		 * 
		 * Just remember to call `_flexGroup.update()`!
		 */
		protected function updateFlexGroup():void {
			_flexGroup.update();
		}
		
		/**
		 * Override in child classes to support other alignments.
		 * 
		 * Alignment calculations are based on top left registration.
		 * 
		 * @param	alignment
		 */
		protected function alignModal(alignment:String):void {
			switch(alignment) {
				// May need to take status bar into account for iOS6
				case ALIGNMENT_CENTERED :
					_clip.x = _parent.stage.stageWidth / 2 - (_clip.width / 2);
					_clip.y = _parent.stage.stageHeight / 2 - (_clip.height / 2);
					break;
				default :
					throw new RangeError("'" + alignment + "' is not a recognized Modal alignment.");
			}
		}
		
		/**
		 * Override in child classes that need to set a different default alignment mode.
		 */
		protected function get alignmentMode():String {
			return ALIGNMENT_CENTERED;
		}
		
		/**
		 * Define the button listeners. Must be mirrored in {@link __destroy()}.
		 * 
		 * Probably no need to override this in child classes, unless you have additional interactivity
		 * that is not covered by simple button clicks.
		 * 
		 * The pattern here is threefold:
			 * MOUSE_DOWN to set the current pressed button
			 * MOUSE_UP with a check to only process if its target is the same button as was pressed
			 * RELEASE_OUTSIDE to handle releasing the press anywhere outside the originally pressed button.
		 * This pattern allows the user to soft-cancel the interaction by rolling off the 
		 * originally pressed button before releasing. This provides a nicer UX.
		 */
		public function activate() {
			trace("[M] + Activating MODAL"); 
			var buttonData:ModalButtonData;
			
			if (_buttons) {
				for each (buttonData in _buttons) {
					buttonData.clip.addEventListener(MouseEvent.MOUSE_DOWN, onButtonDown, false, 0, true);
					buttonData.clip.addEventListener(MouseEvent.MOUSE_UP, onButtonUp, false, 0, true);
					buttonData.clip.addEventListener(MouseEvent.RELEASE_OUTSIDE, onButtonReleaseOutside, false, 0, true);
					
					buttonData.clip.mouseChildren = false;
				}
			}
		}
		
		/**
		 * Override in a child class - used for disabling interactivity in the Modal
		 */
		public function deactivate():void {
			trace("[M] - Deactivating MODAL");
			var buttonData:ModalButtonData;
			
			if (_buttons) {
				for each (buttonData in _buttons) {
					renderButtonUp(buttonData);
					buttonData.clip.removeEventListener(MouseEvent.MOUSE_DOWN, onButtonDown, false);
					buttonData.clip.removeEventListener(MouseEvent.MOUSE_UP, onButtonUp, false);
					buttonData.clip.removeEventListener(MouseEvent.RELEASE_OUTSIDE, onButtonReleaseOutside, false);
				}
			}
		}
		
		/**
		 * Override in child classes to actually turn the MovieClips on, or add them to the displayList.
		 */
		protected function displayModal():void {
			
		}
		
		/**
		 * Override in child classes to turn off the MovieClips and remove them from the displayList.
		 */
		protected function removeModal():void {
			
		}
		
		/**
		 * Do not override. You probably want {@link /renderButtonDown()}.
		 * 
		 * @param	event
		 */
		protected function onButtonDown(event:MouseEvent):void {
			var buttonData:ModalButtonData = getButtonByID(event.currentTarget.name);
			
			if (buttonData) {
				_pressedButton = buttonData.id;
				
				renderButtonDown(buttonData);
			}
		}
		
		/**
		 * Use this to update the visuals when the button is depressed.
		 * Do not perform any business logic here.
		 * 
		 * @param	buttonData
		 */
		protected function renderButtonDown(buttonData:ModalButtonData):void {
			
		}
		
		/**
		 * Handle button up if the button we release over is the same as the button pressed.
		 * 
		 * Do not override. You probably want {@link /renderButtonUp()} for visuals and
		 * {@link doButtonUp()} (maybe) to actually handle the click.
		 * 
		 * @param	event
		 */
		protected function onButtonUp(event:MouseEvent):void {
			var buttonData:ModalButtonData = getButtonByID(event.currentTarget.name);
			
			if (buttonData && buttonData.id == _pressedButton) {
				renderButtonUp(buttonData);
				doButtonUp(buttonData);
			}
		}
		
		/**
		 * ...otherwise reset the originally pressed button.
		 * 
		 * @param	event
		 */
		protected function onButtonReleaseOutside(event:MouseEvent):void {
			var buttonData:ModalButtonData = getButtonByID(_pressedButton);
			
			renderButtonUp(buttonData);
			_pressedButton = "";
		}
		
		/**
		 * Use this to exclusively update the visual state of the button.
		 * 
		 * @param	buttonData
		 */
		protected function renderButtonUp(buttonData:ModalButtonData):void {
			
		}
		
		/**
		 * Maybe override in child classes, but you might consider overriding {@link /close()} instead.
		 * 
		 * Override if you want to do something that would only be triggered by
		 * an actual click within the dialog box as opposed to a manual close by the App / ScreenView.
		 * 
		 * @param	buttonData
		 */
		protected function doButtonUp(buttonData:ModalButtonData):void {
			close();
			
			_pressedButton = "";
		}
		
		/**
		 * Override in child classes if you want to add arguments to the callback.
		 * 
		 * @param	callback
		 */
		protected function doButtonUpCallback(callback:Function):void {
			callback();
		}
		
		/**
		 * Subclasses __must__ extend this if they add any additional listeners,
		 * Dictionaries, or other constructs that may contain references that would
		 * persist after the modal is disposed.
		 * 
		 * For good measure, I generally just null everything that is defined as a class variable,
		 * but that's probably overkill.
		 */
		protected function __destroy():void {
			deactivate();
			
			_buttons = null;
			_clip = null;
			_pressedButton = "";
		}
		
		public function get buttons():Vector.<ModalButtonData> {
			return _buttons;
		}
		
		/**
		 * Convenience function that uses the lookup hash to return the `ModalButtonData`
		 * 
		 * @param	buttonID
		 * @return
		 */
		public function getButtonByID(buttonID:String):ModalButtonData {
			if (_buttonLookup.hasOwnProperty(buttonID)) {
				return _buttons[_buttonLookup[buttonID]];
			}
			
			return null;
		}
		
		public function getButtonIndex(button:*):uint {
			var buttonID:String;
			
			if (button is ModalButtonData) {
				buttonID = ModalButtonData(button).id;
			} else if (button is String) {
				buttonID = button;
			}
			
			if (! buttonID) {
				throw new ArgumentError("Argument must be a valid ModalButtonData object or the button's ID as a String");
			}
			
			return _buttonLookup[buttonID];
		}
		
		public function setBodyText(bodyText):void {
			if (_bodyText && bodyText){
				TextUtils.setTextFieldContent(_bodyText, bodyText);
			}
		}
		
		/**
		 * Used by the App or the ScreenView to figure out which button was pressed to exit the Modal,
		 * in the case where a custom callback was not provided, and just the default EVENT_CLOSE
		 * was used to signal the termination of the modal.
		 */
		public function get pressedButton():String {
			return _pressedButton;
		}
	}

}