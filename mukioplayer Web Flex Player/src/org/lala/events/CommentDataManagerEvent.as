package org.lala.events
{
	import flash.events.Event;
	
	/**
	 * ...
	 * @author 
	 */
	public class CommentDataManagerEvent extends Event
	{
		//modes of comments
		public static var NORMAL_FLOW_RTL:String = '1';
		public static var BIG_BLUE_FLOW_RTL:String = '2';//CDFF
		public static var NORMAL_ORANGE_FLOW_RTL:String = '3';//E17004
		public static var NORMAL_BOTTOM_DISPLAY:String = '4';
		public static var NORMAL_GREEN_TOP_DISPLAY:String = '5';//3CAC01
		public static var NORMAL_FLOW_LTR:String = '6';//reverse comments
		
		public static var POPO_NORMAL:String = 'normal';//zoome style
		public static var POPO_THINK:String = 'think';//zoome style
		public static var POPO_LOUD:String = 'loud';//zoome style
		public static var POPO_BOTTOM_SUBTITLE:String = 'subtitlebottom';//zoome style
		public static var POPO_TOP_SUBTITLE:String = 'subtitletop';//zoome style

		public static var ADDONE:String = 'addOne';
		public static var SETDATA:String = 'setData';
		public static var NEW:String = 'new';

		private var _dta:Object;
		
		public function CommentDataManagerEvent(type:String,data:Object,bbl:Boolean=false,ccb:Boolean=false) 
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