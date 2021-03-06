package com.zeitguys.mobile.app.view {
	import com.zeitguys.mobile.app.view.asset.AssetView;
	import flash.display.DisplayObject;
	import flash.errors.IllegalOperationError;
	import flash.text.TextField;
	
	/**
	 * FlexGroups are the way we can make the vertical position of items dependent on the size (height) of the items above it.
	 * A FlexGroup is a hierarchy of FlexItems, with each FlexItem set as the child of the FlexItem above it. A child FlexItem's
	 * vertical (y) position will be based on the y-position and height of its parent FlexItem.
	 * 
	 * The FlexGroup provides some convenience functions for instantiating FlexItems and adding them to the FlexGroup,
	 * to create more compact code when setting up your views.
	 * 
	 * As a convenience, FlexItems can be localized. After any change to the FlexItem heights, you must call {@link FlexGroup.update()}
	 * to force the FlexGroup to re-adjust the vertical positions of its elements.
	 * 
	 * @author TomAuger
	 */
	public class FlexGroup {
		public static const DIRECTION_DOWN = "down";
		public static const DIRECTION_LEFT = "left";
		
		protected var _flexItems:Vector.<FlexItem> = new Vector.<FlexItem>;
		protected var _backgroundItem:DisplayObject;
		protected var _screen:ScreenView;
		protected var _parentView:ViewBase;
		
		protected var _flexDirection:String = DIRECTION_DOWN;
		
		protected var _lowestItem:FlexItem;
		protected var _groupInitBottomY:int;
		
		protected var _backgroundInitY:int;
		protected var _backgroundBottomOffsetY:int;
		
		public function FlexGroup(parentView:ViewBase = null) {
			_parentView = parentView;
			
			if (_parentView && _parentView is ScreenView) {
				_screen = ScreenView(_parentView);
			}
		}
		
		public function set backgroundItem(item:DisplayObject):void {
			_backgroundItem = item;
			
			_backgroundInitY = _backgroundItem.y;
			_backgroundBottomOffsetY = _backgroundItem.y + _backgroundItem.height - _groupInitBottomY;
		}
		
		public function set flexDirection(direction:String):void {
			if ([DIRECTION_DOWN, DIRECTION_LEFT].indexOf(direction) == -1) {
				throw new RangeError("Flex Direction '" + direction + "' not supported.");
			}
			
			_flexDirection = direction;
		}
	
		/**
		 * Creates and adds a new FlexItem to the FlexGroup by providing only its source clip.
		 * 
		 * @see FlexItem constructor.
		 * 
		 * This is a convenience method to simplify the creation of flex items. It returns the FlexItem that was created
		 * so it can be referenced more easily by the calling class, for example, when referencing the parent item (which itself, must be a FlexItem).
		 * 
		 * @param	clip
		 * @param	parentItem
		 * @param	textField
		 * @return
		 */
		public function addClip(clip:DisplayObject, parentItem:FlexItem = null, textFieldName:String = ""):FlexItem {
			return addItem(new FlexItem(clip, parentItem, textFieldName));
		}
		
		/**
		 * Adds a new FlexItem to the FlexGroup by providing its source AssetView. Also takes care of registering the asset
		 * with the ScreenView or with the parent Asset, depending on whether the asset is a ScreenAssetView or just an AssetView.
		 * 
		 * @see FlexItem()
		 * 
		 * @param	asset
		 * @param	parentItem
		 * @param	textFieldName
		 * @return
		 */
		public function addAsset(asset:AssetView, parentItem:FlexItem = null, textFieldName:String = ""):FlexItem {
			if (asset is AssetView) {
				registerAssetWithScreen(AssetView(asset));
			} else {
				if (parentView is AssetView){
					AssetView(parentView).addAsset(asset);
				}
			}
			
			return addItem(new FlexItem(asset, parentItem, textFieldName));
		}
		
		/**
		 * Convenience function to avoid having to explicitly reference `_screen`. 
		 * 
		 * @see ScreenView.registerAsset()
		 * 
		 * Registers the asset with the ScreenView, so the ScreenView can automatically update the asset when, for example, the screen is activated/deactivated.
		 * 
		 * @param	asset
		 * @return
		 */
		public function registerAssetWithScreen(asset:AssetView):AssetView {
			if (_screen) {
				_screen.registerAsset(asset);
			} else {
				throw new IllegalOperationError("Attempting to register asset with its Screen, but this FlexGroup is not attached to a Screen. (Are you attempting to nest a ScreenAssetView inside another ScreenAssetView?)");
			}
			
			return asset;
		}
		
		/**
		 * For convenience, returns the FlexItem we passed in.
		 * @param	flexItem
		 * @return
		 */
		public function addItem(flexItem:FlexItem):FlexItem {
			_flexItems.push(flexItem.setGroup(this));
			
			if (flexItem.parent) {
				flexItem.parent.addChild(flexItem);
			}
			
			// Determine whether this clip is lower than all the others to determine the bottom bound of the FlexGroup
			if (! _lowestItem || flexItem.bottomY > _groupInitBottomY) {
				_groupInitBottomY = flexItem.bottomY;
				_lowestItem = flexItem;
				
				if (_backgroundItem) {
					_backgroundBottomOffsetY = _backgroundItem.y + _backgroundItem.height - _groupInitBottomY;
				}
			}
			
			return flexItem;
		}
		
		/**
		 * Removes all Flex Items from the group
		 * @TODO Do proper garbage collection
		 * @return
		 */
		public function removeAllItems():Boolean {
			for each ( var item:FlexItem in _flexItems) {
				item = null;
			}
			_flexItems = new Vector.<FlexItem>;
			return false;
		}
		
		/**
		 * Updates only top-level (no parent) items.
		 * Children are updated downstream.
		 * 
		 * @see FlexItem.update()
		 * @see FlexItem.updateChildren()
		 */
		public function update():void {		
			if (! _flexItems.length) {
				return;
			}
			
			for each (var item:FlexItem in _flexItems) {
				if (! item.hasParent) {
					item.update();
				}
			}
			
			// Recalculate the lowest item, so we can properly scale the background.
			_lowestItem = getLowestItem();
			
			//Now handle scaling the background
			if (_backgroundItem) {
				_backgroundItem.height = _lowestItem.bottomY + _backgroundBottomOffsetY - _backgroundInitY;
			}
		}
		
		public function getLowestItem():FlexItem {
			var lowestItem:FlexItem;
			
			for each (var item:FlexItem in _flexItems) {
				if (! lowestItem || item.bottomY > lowestItem.bottomY) {
					lowestItem = item;
				}
			}
			
			_lowestItem = lowestItem;
			
			return lowestItem;
		}
		
		public function get items():Vector.<FlexItem> {
			return _flexItems;
		}
		
		public function get groupBottomY():int {
			if (_lowestItem) {
				return _lowestItem.bottomY;
			} else {
				return undefined;
			}
		}
		
		public function get screen():ScreenView {
			return _screen;
		}
		
		public function get parentView():ViewBase {
			return _parentView;
		}
	}

}