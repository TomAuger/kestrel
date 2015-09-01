package com.zeitguys.mobile.app.view {
	import com.zeitguys.mobile.app.error.FlashConstructionError;
	import com.zeitguys.mobile.app.view.asset.AssetView;
	import com.zeitguys.util.ClipUtils;
	import com.zeitguys.util.TextUtils;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.errors.IllegalOperationError;
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
	public class FlexItem {
		protected var _clip:DisplayObject;
		protected var _clipName:String;
		protected var _asset:AssetView;
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
			_parent = parentItem;
			
			if (textField) {
				_textFieldName = textField;
			}
			
			if (item is AssetView) {
				_asset = AssetView(item);
				if (_asset.hasClip){
					clip = _asset.clip;
				}
			} else if (item is DisplayObject) {
				clip = DisplayObject(item);
				_asset = null;
			} else {
				throw new ArgumentError("Attempting to instantiate FlexItem with a non-DisplayObject and non-ScreenAssetView : " + item.toString());
			}
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
		public function chainAsset(asset:AssetView, textField:String = ""):FlexItem {
			return _flexGroup.addAsset(asset, this, textField);
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
		 * @param	newText The String we want to appear in the TextField
		 */
		public function setItemText(newText:String = ""):void {
			if (asset) {
				asset.setText(localizableTextField, newText);
			} else {
				TextUtils.setTextFieldContent(localizableTextField, newText);
			}
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
			// Force update of clip if we haven't already
			if (clip){
				if (_textField) {
					return true;
				}
			}
			
			return false;
		}
		
		public function get localizableTextField():TextField {
			// Force update of clip
			if (clip){
				return _textField;
			}
			
			return null;
		}
		
		/**
		 * Set the FlexItem's AssetView clip. If we defined a text field when we created the FlexItem,
		 * then we'll go looking for that now, or if the Clip itself is a TextField, then we'll add
		 * that as the FlexItem's textfield for localization purposes.
		 * 
		 * We also set up initial X and Y coordinates, and set up the parent offsets.
		 */
		public function set clip(clipDisplayObject:DisplayObject):void {
			_clip = clipDisplayObject;
			
			_clipName = _clip.name;
			
			if (_textFieldName) {
				_textField = getRequiredTextFieldByName(_textFieldName);
			} else {
				if (_clip is TextField) {
					_textField = TextField(_clip);
					_textFieldName = _clip.name;
				}
			}
			
			// Do this before we measure any heights, because height will change!
			adjustTextFieldHeight();
			
			_initY = _clip.y;
			_initX = _clip.x;
			
			if (_parent) {
				// I wonder whether this is potentially "too late" in some cases?
				_parentBottomOffsetY = _initY - _parent.bottomY;
			}
		}
		
		/**
		 * Access the FlexItem's AssetView clip. If we haven't done so yet (because the clip wasn't defined yet when we added
		 * the new Asset to the FlexItem), we have the chance to go and get it now.
		 * 
		 * @uses FlexItem.set clip() so if this is the first time we have access to the clip, we set up all the other stuff we need to do.
		 */
		public function get clip():DisplayObject {
			if (! _clip) {
				if (_asset && _asset.hasClip) {
					clip = _asset.clip;
				} else {
					throw new IllegalOperationError("Trying to access FlexItem's asset clip, but it has not yet been defined.");
				}
			}
			
			return _clip;
		}
		
		public function get asset():AssetView {
			return _asset;
		}
		
		public function get screenAsset():AssetView {
			return _asset as AssetView;
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
		
		/**
		 * @see ClipUtils.getDescendantByName()
		 * 
		 * @param	childName
		 * @param	parentClip
		 * @return
		 */
		protected function getDescendantByName(childName:String, parentClip:DisplayObjectContainer = null):DisplayObject {
			if (parentClip == null) {
				if (_clip is DisplayObjectContainer){
					parentClip = DisplayObjectContainer(_clip);
				} else {
					throw new ArgumentError("Argument 'parentClip' not supplied and this FlexItems's _clip is not a DisplayObjectContainer.");
				}
			}
			return ClipUtils.getDescendantByName(childName, parentClip);
		}
	}

}