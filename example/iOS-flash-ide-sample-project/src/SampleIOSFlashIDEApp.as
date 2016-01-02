package {
	import com.zeitguys.mobile.ios.App;
	
	/**
	 * Sample mobile Kestrel app, showcasing the most barebones Kestrel usage.
	 * 
	 * See additional examples for more involved use cases, including loading external SWF assets,
	 * working with transitions, and complex Screen interactions.
	 * 
	 * @author TomAuger
	 */
	public class SampleIOSFlashIDEApp extends App {
		
		public function SampleIOSFlashIDEApp() {
			super();
		
		}
		
		override protected function initialize():void {
			screenList = new SampleAppScreenList();
		}
	
	}

}