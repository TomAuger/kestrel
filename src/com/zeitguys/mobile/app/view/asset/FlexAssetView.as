package com.zeitguys.mobile.app.view.asset 
{
	import com.zeitguys.mobile.app.error.FlashConstructionError;
	import com.zeitguys.mobile.app.model.Localizer;
	import com.zeitguys.mobile.app.view.FlexGroup;
	import com.zeitguys.mobile.app.view.FlexItem;
	import com.zeitguys.mobile.app.view.ScreenView;
	import flash.display.DisplayObject;
	import flash.errors.IllegalOperationError;
	import flash.text.TextField;
	/**
	 * ...
	 * @author Tom Auger
	 */
	public class FlexAssetView extends AssetView {
		protected var _flexGroup:FlexGroup;
		
		private var _textFieldNames:Array = [];
		private var _localizeFlexItemFilter:Function;
		
		public function FlexAssetView(assetClip:*, localizableTextFields:Array = null, disabled:Boolean = false) {
			_flexGroup = new FlexGroup(this);
			
			if (localizableTextFields) {
				_textFieldNames = localizableTextFields;
			}
			
			super(assetClip, disabled);
		}
		
		/**
		 * Define any non-flex (ie: static) items here. Items defined here
		 * will NOT affect the size / spacing / position of the FlexItem, and
		 * will not grow the background in any way.
		 */
		protected function defineItems():void {
			// Abstract class
		}
		
		/**
		 * Maybe override in child classes.
		 * 
		 * Adds all the localizable TextFields to the FlexGroup chain, in the order that they were defined in the constructor argument.
		 * 
		 * Takes a FlexItem as argument and returns the last FlexItem in the chain.
		 * 
		 * If you override this method in a child class, you probably want to make sure you call super.defineFlexItems(parentItem) either at the top
		 * of your function or at the bottom. 
		 * 
		 * <b>It's important to remember to listen for the parentItem and to return the last FlexItem you create.</p> This allows subclasses
		 * to continue adding to the head or the tail of the chain.
		 * 
		 * If you need to insert something in the middle of the chain, see {@link #insertLocalizableTextFieldParentFilter}, and may the gods
		 * have mercy on your soul.
		 */
		protected function defineFlexItems(parentItem:FlexItem = null):FlexItem {
			for each (var textFieldName:String in _textFieldNames) {
				var clip:DisplayObject = getRequiredChildByName(textFieldName);
				
				if (clip is TextField) {
					parentItem = insertLocalizableTextFieldParentFilter(addMainFlexItem(clip, parentItem), textFieldName);
				} else {
					throw new FlashConstructionError(_clipName, textFieldName, "as TextField");
				}
			}
			
			return parentItem;
		}
		
		/**
		 * Convenience function to easily add a new FlexItem to the main FlexGroup
		 * 
		 * @param	clip (DisplayObject|String) Either the clip itself, or the clip's instance name.
		 * @param	parentItem
		 * @param	textFieldName
		 * @return
		 */
		protected function addMainFlexItem(clip:*, parentItem:FlexItem = null, textFieldName:String = ""):FlexItem {
			var element:DisplayObject;
			
			if (clip is DisplayObject) {
				element = clip;
			} else if (clip is String) {
				element = getRequiredChildByName(clip);
			} else {
				throw new ArgumentError("'clip' must be a DisplayObject or the instance name of a DisplayObject.");
			}
			
			return _flexGroup.addClip(element, parentItem, textFieldName);
		}
		
		/**
		 * Likely override in child classes, particularly if you are also overriding {@link defineItems()}, calling super.localize(localizer).
		 * 
		 * Goes through each item in the FlexGroup and localizes it. 
		 * This assumes that the TextField's name is the same as the XML element that contains the localized string.
		 * 
		 * @see ViewBase.setText() to learn how the TextField's htmlText is actually set
		 * @see ViewBase.parseVariables() to learn how text variables (like %%VARIABLE_NAME%%) are parsed in via `setText()` and {@link ScreenAssetView.setTextVariable()}
		 * @see ScreenAssetView.getAssetComponentText() to learn how the localized text is actually pulled out of the Localizer
		 * @see /applyLocalizeFlexItemFilter() to see how you can filter the text for a specific TextField at runtime from a child class.
		 * 
		 * @param	localizer
		 * @return	Success.
		 */
		override public function localize(localizer:Localizer):void {
			trace("Localizing TextFields in " + id);
			
			_numberFormatter = localizer.numberFormatter;
			
			for each (var item:FlexItem in _flexGroup.items) {
				if (item.hasLocalizableTextField){
					setText(item.localizableTextField, applyLocalizeFlexItemFilter(getAssetComponentText(localizer, item.textFieldName), localizer, id, item.textFieldName));
				}
			}
			
			_flexGroup.update();
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
		
		/**
		 * Override as needed.
		 * 
		 * Provides a clean method of inserting some other FlexItem into the FlexGroup chain as we're building it out of the localizableTextFields.
		 * Simply override this method, checking 'parentItemName' for the name of the clip you want to insert after. If you find the clip,
		 * add it to the FlexGroup using {@link #addMainFlexItem()} and returning it; if not, return the original parent item and you're golden!
		 * 
		 * @param	parentItem
		 * @param	parentItemName
		 * @return	Either the original parentItem, or the last of the new item(s) that were added in this hook.
		 */
		protected function insertLocalizableTextFieldParentFilter(parentItem:FlexItem, parentItemName:String):FlexItem {
			return parentItem;
		}
		
		/**
		 * Filters each localizable TextField's translation string. This is particularly useful for making on-the-fly changes to
		 * a small number of the textfields in an asset. 
		 * 
		 * If you find yourself doing large switch statements or loops, then maybe it's just better to override localize().
		 * 
		 * @see addFilter for how to actually add this filter in.
		 * 
		 * @param	newText
		 * @param	localizer
		 * @param	textFieldName
		 * @param	item
		 * @return
		 */
		protected function applyLocalizeFlexItemFilter(newText:String, localizer:Localizer, assetID:String, textFieldName:String):String {
			if (_localizeFlexItemFilter is Function) {
				return (_localizeFlexItemFilter(newText, localizer, assetID, textFieldName));
			}
			
			return newText;
		}
		
		/**
		 * Allows us to add a filter. Extend this in subclasses, remembering to call parent.addFilter() at the end of the overridden method.
		 * 
		 * @param	filterName
		 * @param	filterCallback
		 */
		override public function addFilter(filterName:String, filterCallback:Function):void {
			switch (filterName) {
				case "localizeFlexItem":
					if (filterCallback.length == applyLocalizeFlexItemFilter.length){
						_localizeFlexItemFilter = filterCallback;
					} else {
						throw new ArgumentError("Callback for filter '" + filterName + "' does not have the correct # arguments. Required: " + applyLocalizeFlexItemFilter.length);
					}
					break;
				default:
					super.addFilter(filterName, filterCallback);
			}
		}
		
		/**
		 * Generally, sublcasses should avoid overriding init(), using
		 * defineItems() or defineFlexItems(), repectively.
		 */
		override public function init():void {
			var bg:DisplayObject = getDescendantByName('bg');
			if (bg){
				_flexGroup.backgroundItem = bg;
			}
			
			defineItems();
			defineFlexItems();
			
			super.init();
		}
		
	}

}