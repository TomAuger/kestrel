package com.zeitguys.app.view {
	import com.zeitguys.app.error.FlashConstructionError;
	import com.zeitguys.app.view.asset.ScreenAssetView;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.text.StyleSheet;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	
	/**
	 * An atomic portion of a FlexGroup.
	 * 
	 * A FlexItem corresponds to a single element - like a ScreenAssetView, TextField, icon, or graphic, and often a component of a larger element - like a button or content box.
	 * The FlexItem's y-position is fixed relative to the bottom of its parent FlexItem. If it has no parent, it is assumed to be at the "top" of the hierarchy.
	 * 
	 * FlexItems to not have to contain a ScreenAssetView, but can (and often should). FlexItems do not have to contain localizable text, but can. 
	 * Text can be localized directly (see {@link /setText()}) or through the ScreenAssetView (see {@link ScreenAssetView.setText()}).
	 * 
	 * @author TomAuger
	 */
	public class FlexItem extends ViewBase {
		protected var _asset:ScreenAssetView;
		protected var _flexGroup:FlexGroup;
		protected var _parent:FlexItem;
		protected var _children:Vector.<FlexItem> = new Vector.<FlexItem>;
		protected var _textField:TextField;
		protected var _textFieldName:String;
		
		protected var _initY:int;
		protected var _initX:int;
		/**
		 * The distance from the initial Y-position of the item to the bottom of its parent item.
		 */
		protected var _parentBottomOffsetY:int;
		
		/**
		 * Constructor. Creates a new FlexItem. FlexItems are pretty useless unless they're part of a FlexGroup
		 * @param	item The ScreenAssetView or DisplayObject associated with this FlexItem. Often, this is a TextField, but it can also be a MovieClip.
		 * @param	parentItem Optional. If this FlexItem is to move vertically as content and heights above it change, the item immediately above it must be provided as the parentItem.
		 * @param	textField Optional. If the item is a TextField, this argument should be omitted. If the item is a container, and you want to be able to localize the (single) textField inside that container, provide the instance name of that TextField.
		 */
		public function FlexItem(item:*, parentItem:FlexItem = null, textField:String = "" ) {
			if (item is ScreenAssetView) {
				_asset = ScreenAssetView(item);
				_clip = _asset.clip;
			} else if (item is DisplayObject) {
				_clip = DisplayObject(item);
				_asset = null;
			} else {
				throw new ArgumentError("Attempting to instantiate FlexItem with a non-DisplayObject and non-ScreenAssetView : " + item.toString());
			}
			
			_parent = parentItem;
			
			if (textField) {
				_textField = getRequiredTextFieldByName(textField);
				_textFieldName = textField;
			} else {
				if (_clip is TextField) {
					_textField = TextField(_clip);
					_textFieldName = _clip.name;
				}
			}
			
			_initY = _clip.y;
			_initX = _clip.x;
			
			// Do this before we measure any heights, because height will change!
			adjustTextFieldHeight();
			
			if (_parent) {
				_parentBottomOffsetY = _initY - _parent.bottomY;
			}
			
			//trace("%% FlexItem CREATED: " + _clip.name + " initY: " + _initY);
		}
		
		public function setGroup(group:FlexGroup):FlexItem {
			_flexGroup = group;
			
			return this;
		}
		
		/**
		 * Convenience function to chain a clip to the end of this one. This clip becomes the parent of the chained clip.
		 * 
		 * @param	clip
		 * @param	textField
		 * @return
		 */
		public function chainClip(clip:DisplayObject, textField:String = ""):FlexItem {
			return _flexGroup.addClip(clip, this, textField);
		}
		
		/**
		 * Chain the next asset so that it is a child of this asset.
		 * 
		 * @param	asset
		 * @param	textField
		 * @return
		 */
		public function chainAsset(asset:ScreenAssetView, textField:String = ""):FlexItem {
			return _flexGroup.addAsset(_flexGroup.registerAssetWithScreen(asset), this, textField);
		}
	
		/**
		 * Convenience function to set the text of the TextField during localization.
		 * 
		 * This allows the ScreenAssetView to keep references to the FlexItems, to be used
		 * for localization purposes, rather than a parallel list of the TextFields or ScreenAssetViews
		 * that need to be localized separately.
		 * 
		 * If the FlexItem has an asset (ie: if it was added with {@link FlexGroup.addAsset()} rather than {@link FlexGroup.addClip()}, then it will use {@link ScreenAssetView.setText()}
		 * instead, which is vastly preferable as it allows variable substitution and handles Flash text weirdness a lot more robustly.
		 * 
		 * If the asset is a TextField, then it will set the text in that TextField, otherwise, it will expect you to provide a textField within the FlexItem constructor.
		 * 
		 * @param	newText
		 * @param 	forceBlank If `newText` is empty, setting this to true will force the TextField to update with the empty string, otherwise the TextField is left alone.
		 */
		public function setItemText(newText:String = "", forceBlank:Boolean = false):void {
			setText(_textField, newText);
			
		}
		
		/**
		 * Compensation for AutoSize / negative line spacing issues.
		 */
		protected function adjustTextFieldHeight():void {
			if (_textField){
				if (_textField.maxScrollV > 1){
					_textField.autoSize = TextFieldAutoSize.LEFT;
				} else {
					_textField.autoSize = TextFieldAutoSize.NONE;
					_textField.height = _textField.textHeight - Number(_textField.getTextFormat().leading);
				}
			}
		}
		
		/**
		 * @see FlexGroup.update()
		 * 
		 * Called by FlexGroup.update(), after content in the FlexGroup has changed.
		 * 
		 * Updates must happen from top-to-bottom, so this is a walker, which should start with the FlexItems that have no parent.
		 */
		public function update() {
			if (parent) {
				_clip.y = parent.bottomY + _parentBottomOffsetY;
			}
			
			//trace("%% FlexItem UPDATED: " + _clip.name + " clipY: " + _clip.y);
			
			if (hasChildren) {
				updateChildren();
			}
		}
		
		/**
		 * Recurse through the tree, updating any children of this item.
		 */
		public function updateChildren() {
			for each (var child:FlexItem in _children) {
				child.update();
			}
		}
		
		public function get parent():FlexItem {
			return _parent;
		}
		
		public function get hasParent():Boolean {
			return _parent != null;
		}
		
		public function addChild(item:FlexItem):void {
			_children.push(item);
		}
		
		public function get hasChildren():Boolean {
			return _children.length > 0;
		}
		
		public function get children():Vector.<FlexItem> {
			return _children;
		}
		
		public function get bottomY():int {
			return _clip.y + _clip.height;
		}
		
		public function get textFieldName():String {
			return _textFieldName;
		}
		
		public function get hasLocalizableTextField():Boolean {
			if (_textField) {
				return true;
			}
			
			return false;
		}
		
		public function get localizableTextField():TextField {
			return _textField;
		}
		
		/**
		 * Convenience getter function. If we know the asset is a MovieClip,
		 * this saves one cast. If there's an asset, but it's not a MovieClip, we'll get nothing, so check carefully.
		 */
		override public function get clip():DisplayObject {
			if (_clip is MovieClip) {
				return MovieClip(_clip);	
			}
			
			return null;
		}
		
		/**
		 * I hate this - it should be get clip() but that would mean so much refactoring it's not even funny.
		 */
		public function get displayObject():DisplayObject {
			return _clip;
		}
		
		public function get asset():ScreenAssetView {
			return _asset;
		}
		
		/**
		 * Dig through the display hierarchy of the main asset clip to find a TextField with the requested instance name.
		 * 
		 * @see /getRequiredChildByName()
		 * 
		 * @throws FiashConstructionError if it finds an asset but the asset is not a TextField
		 * 
		 * @param	clipName
		 * @return
		 */
		protected function getRequiredTextFieldByName(clipName:String):TextField {
			if (_clip is DisplayObjectContainer){
				var clip:DisplayObject = getDescendantByName(clipName, DisplayObjectContainer(_clip));
				
				if (! clip) {
					throw new FlashConstructionError(_clip.name, clipName);
				}
				
				if (clip is TextField) {
					return TextField(clip);
				} else {
					throw new FlashConstructionError(_clip.name, clipName, "as TextField");
				}
			} else {
				throw new FlashConstructionError(_clip.name, clipName, "asset is not a DisplayObjectContainer!");
			}
		}
	}

}