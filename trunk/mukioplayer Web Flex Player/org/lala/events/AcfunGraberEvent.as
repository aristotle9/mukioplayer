package org.lala.events 
{
	import flash.events.Event;
	
	/**
	 * ...
	 * @author 
	 */
	public class AcfunGraberEvent extends Event
	{
		public static var COMPLETE:String = 'complete';
		public static var ADDITEM:String = 'addItem';//add Playlist item from html
		public static var CLEARITEMS:String = 'clearItems';
		public static var HTMLINFO:String = 'htmlInfo';
		
		private var _dta:Object;
		
		public function AcfunGraberEvent(type:String,data:Object,bbl:Boolean=false,ccb:Boolean=false) 
		{
			super(type, bbl, ccb);
			_dta = data;
		}
		public function get data():Object
		{
			return _dta;
		}
	}

}