package org.lala.events
{
	/**
	 * ...
	 * @author 
	 */
	import flash.events.Event;
	public class CommentListViewEvent extends Event
	{
		public static var DISPLAYTOGGLE:String = 'displayToggle';
		public static var TRACKTOGGLE:String = 'trackToggle';//list view to view
		public static var FILTERADD:String = 'filterAdd';//list view to view
		public static var FILTERDELETE:String = 'filterDelete';//list view to view
		public static var FILTERLISTENABLETOGGLE:String = 'filterListEnableToggle';//list view to view
		public static var FILTERCHECKBOXTOGGLE:String = 'filterCheckBoxToggle';//list view to view
		public static var SENDCOMMENT:String = 'sendComment';//list view to CommentSender
		public static var PREVIEWCOMMENT:String = 'previewComment';//list view to CommentSender
		
		//public static var GPBUTTONCHANGE:String = 'groupButtonStateChange';
		public static var MODESTYLESIZECHANGE:String = 'modeStyleSizeChange';
		public static var TBBUTTONCHANGE:String = 'tabButtonStateChange';
		public static var COLDTRICKER:String = 'coldTriker';//好吧,我不认识这个词
		
		//popo comment send
		public static var POPOCOMMENTSEND:String = 'popoCommentSend';//from design pad to UI
		public static var SENDPOPOCOMMENT:String = 'sendPopoComment';//from UI to Sender
		
		//public static var SETDATA:String = 'setData';
		
		private var _data:Object;
		public function CommentListViewEvent(type:String,data:Object,bbl:Boolean=false,ccb:Boolean=false) 
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