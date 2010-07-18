package org.lala.events 
{
	import flash.events.Event;
	
	/**
	 * ...
	 * @author 
	 */
	public class MukioPlaylistEvent extends Event
	{
		public static var ADDITEM:String = 'addItem';//add a playlist item
		
		private var _dta:Object;
		
		public function MukioPlaylistEvent(type:String,data:Object,bbl:Boolean=false,ccb:Boolean=false) 
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