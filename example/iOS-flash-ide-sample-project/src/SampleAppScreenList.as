package {
	import com.zeitguys.mobile.app.model.IScreenList;
	import com.zeitguys.mobile.app.model.MainScreenBundle;
	import com.zeitguys.mobile.app.model.ScreenBundle;
	import com.zeitguys.mobile.app.view.ScreenView;
	
	/**
	 * ...
	 * @author Tom Auger
	 */
	public class SampleAppScreenList implements IScreenList {
		
        /* INTERFACE com.zeitguys.mobile.app.model.IScreenList */
        public function getScreenBundles():Vector.<ScreenBundle> {
            return new <ScreenBundle>[
                new MainScreenBundle("main", new <ScreenView>[
                    //new ScreenView("simple_modal"),
                    //new ScreenView("activate_deactivate")
                ])
            ];
        }
    }
}