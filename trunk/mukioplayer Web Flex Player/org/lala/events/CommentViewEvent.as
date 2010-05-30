package org.lala.events
{
	import flash.events.Event;
	
	/**
	 * ...
	 * @author 
	 */
	public class CommentViewEvent extends Event
	{
		public static var TIMER:String = 'timer';
		public static var RESIZE:String = 'resize';
		public static var PLAY:String = 'play';
		public static var PAUSE:String = 'pause';
		
		public static var TRACKTOGGLE:String = 'trackToggle';//list view to view mgr
		public static var TRACK:String = 'track';//view mgr to list view 
		public static var FILTERADD:String = 'filterAdd';//filter to list view 
		public static var FILTEINITIAL:String = 'filterInitial';//filter to list view 
		
		private var _data:Object;
		
		public function CommentViewEvent(type:String,data:Object,bbl:Boolean=false,ccb:Boolean=false) 
		{
			super(type, bbl, ccb);
			_data = data;
		}
		
		public function get data():Object
		{
			return _data;
		}
		
	}

}