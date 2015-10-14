package com.zeitguys.mobile.app.view {
	import com.zeitguys.mobile.app.AppBase;
	import com.zeitguys.mobile.app.model.vo.ModalButtonData;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	
	/**
	 * ...
	 * @author TomAuger
	 */
	public class ModalFactory {
		private const DEFAULT_BUTTON_NAME:String = "button_"; // used as the ID of a button whose callback is defined without an ID.
		
		protected var _app:AppBase;
		
		public function ModalFactory(app:AppBase) {
			_app = app;
		}
		
		public function getModal(modalText:String, modalArgs:Array):ModalView {
			var buttons:Vector.<ModalButtonData> = parseModalArgs(modalArgs);
			
			return new ModalView(_app, getModalClip(buttons), modalText, buttons);
		}
		
		/**
		 * Override in child classes to return the appropriate clip based on the button data.
		 * 
		 * This abstract method just assembles the minimum requirements so that ModalView doesn't throw a FlashConstructionError
		 * 
		 * @param	buttons
		 * @return
		 */
		protected function getModalClip(buttons:Vector.<ModalButtonData>):* {
			var modalClip:Sprite = new Sprite();
			var okButton:MovieClip = new MovieClip();
			
			modalClip.name = "Modal_" + ModalView.__instanceNumber++;
			okButton.name = "ok";
			
			modalClip.addChild(okButton);
			
			return modalClip;
		}
		
		protected function parseModalArgs(modalArgs:Array):Vector.<ModalButtonData> {
			var buttons:Vector.<ModalButtonData> = new Vector.<ModalButtonData>,
				labels:Array = [],
				callbacks:Vector.<Function> = new Vector.<Function>,
				numButtons:uint = 0,
				buttonData:ModalButtonData;
			
			//trace("---------------------------------------------\nInstantiating new MODAL DIALOG");
			
			for each (var arg in modalArgs) {
				switch(typeof arg) {
					case "string" :
						labels.push(arg);
						break;
					case "function" :
						callbacks.push(arg);
						break;
					case "object" :
						// Reset so we can use it as a test later
						buttonData = null;
						
						if (arg is ModalButtonData) {
							buttonData = arg;
						} else {
							if (arg.label) {
								if (! arg.id) {
									arg.id = generateButtonID(buttons.length + Math.max(labels.length, callbacks.length));
								}
							}
							
							if (arg.id) {
								arg.label ||= idToLabel(arg.id);
								buttonData = new ModalButtonData(arg.id, arg.label, arg.callback);
							} else {
								throw new ArgumentError("Modal button definition is missing an ID. Please provide an `id` element in your construction object.");
							}
						}
						
						if (buttonData) {
							buttons = buttons.concat(compileFreeModalArgs(labels, callbacks, buttons.length));
							buttons.push(buttonData);
							labels.length = callbacks.length = 0;
						}
						break;
				}
			}
			
			// Sloop up any remaining free args
			if (labels.length || callbacks.length) {
				buttons = buttons.concat(compileFreeModalArgs(labels, callbacks, buttons.length));
			}
			return buttons;
		}
		
		/**
		 * Takes the currently defined labels and callbacks and creates {@link ModalButtonData} instances for each pair.
		 * 
		 * If the callbacks exceed the labels, then new IDs and labels will be created, first by using up the pool of
		 * default labels, then by using the DEFAULT_BUTTON_NAME and adding a unique number to it.
		 * 
		 * @param	labels
		 * @param	callbacks
		 * @param	numExistingButtons
		 * @return
		 */
		protected function compileFreeModalArgs(labels:Array, callbacks:Vector.<Function>, numExistingButtons:uint):Vector.<ModalButtonData> {
			var buttons:Vector.<ModalButtonData> = new Vector.<ModalButtonData>,
				l:uint = Math.max(labels.length, callbacks.length),
				i:uint,
				buttonData:ModalButtonData,
				id:String,
				label:String,
				callback:Function;
				
			for (i = 0; i < l; ++i) {
				label = null;
				
				// Get a label.
				if (i < labels.length) {
					label = labels[i];
				}
				
				id = generateButtonID(buttons.length + numExistingButtons);
				
				// If we haven't got a label, create one from the ID
				if (! label) {
					label = idToLabel(id);
				}
				
				if (i < callbacks.length) {
					callback = callbacks[i];
				} else {
					callback = null;
				}
				
				trace("Free args interpreted as id: " + id + " label: " + label + " callback:", callback);
				
				buttons.push(new ModalButtonData(id, label, callback));
			}
			
			return buttons;
		}
		
		protected function generateButtonID(buttonIndex:uint):String {
			//  If we haven't used up all our default buttons, grab the ID from the defaultButton
			if (buttonIndex < defaultButtons.length) {
				return defaultButtons[buttonIndex];
			}
			
			// If we've run out of defaultButtons, use the default text and append a unique number to it.
			return DEFAULT_BUTTON_NAME + (buttonIndex + 1);
		}
		
		/**
		 * Gets the list of default button IDs to be used in case we define only callbacks.
		 * 
		 * Override in child classes that support additional default buttons. Either redefine the whole list,
		 * or concatenate `super.defaultButtons` to the new list.
		 */
		protected function get defaultButtons():Array {
			return [
				ModalView.BUTTON_OK,
				ModalView.BUTTON_CANCEL,
				ModalView.BUTTON_MISC
			];
		}
		
		protected function labelToID(label:String):String {
			return label.toLowerCase().replace(/\W+/g, "_");
		}
	
		protected function idToLabel(id:String):String {
			var label:String = id,
				chunks:Array = id.split(/_+/);
				
			// Pure cheese. But we want ok to read OK, ok? OK.
			if ('ok' == id) {
				return "OK";
			}
			
			if (chunks.length) {
				chunks.forEach(function(c:String, i:uint, a:Array):void {
					a[i] = c.replace(/^(\w)/, function(){ return arguments[1].toUpperCase(); });
				});
				
				label = chunks.join(" ");
			}
			
			return label;
		}
	}

}