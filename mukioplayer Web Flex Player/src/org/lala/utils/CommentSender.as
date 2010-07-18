package org.lala.utils 
{
	import flash.events.EventDispatcher;
	import flash.events.TimerEvent;
	import flash.utils.Timer;

	import com.jeroenwijering.events.*;
	import com.jeroenwijering.utils.*;
	import com.jeroenwijering.plugins.*;
	import com.jeroenwijering.models.*;
	import com.jeroenwijering.player.*;
	
	import org.lala.events.*;
	import org.lala.models.*;
	import org.lala.plugins.*;
	import org.lala.utils.*;
	/**
	 * ...
	 * @author 
	 * manage the comment send mission
	 */
	public class CommentSender extends EventDispatcher
	{
		public static var COLDTIME:int = 3000;//five seconds until counld send next comment
		private var _mode:int = 1;
		private var _color:int = 0xffffff;
		private var _size:int = 25;
		private var _userId:String = 'aristotle_1987@126.com';
		
		private var coldTime:Timer;
		private var bBusy:Boolean = false;
		private var nColdmsec:Number = CommentSender.COLDTIME;
		
		private var latestComment:String = '';
		private var commentUI:CommentListSender;
		private var getter:CommentGetter;
		public function CommentSender(cui:CommentListSender,gtr:CommentGetter) 
		{
			commentUI = cui;
			commentUI.addEventListener( CommentListViewEvent.SENDCOMMENT, sendCommentHandler);
			commentUI.addEventListener( CommentListViewEvent.SENDPOPOCOMMENT, sendPopoCommentHandler);
			commentUI.addEventListener( CommentListViewEvent.PREVIEWCOMMENT, previewCommentHandler);
			
			getter = gtr;
			coldTime = new Timer(CommentSender.COLDTIME / 20, 20);
			coldTime.addEventListener(TimerEvent.TIMER_COMPLETE, coldDownHandler);
			coldTime.addEventListener(TimerEvent.TIMER, coldTrickHandler);
			
			
		}
		private function coldTrickHandler(evt:TimerEvent):void
		{
			nColdmsec -= CommentSender.COLDTIME / 20;
			var str:String = String(nColdmsec / 1000);
			if (str.length == 3)
			{
				str = str.concat('0');
			}else
			if (str.length == 2)
			{
				str = str.concat('00');
			}else
			if (str.length == 1)
			{
				str = str.concat('.00');
			}
			
			commentUI.dispatchCommentListViewEvent(CommentListViewEvent.COLDTRICKER, {'enable':false,'label':str+'s CD' } );
		}
		private function coldDownHandler(evt:TimerEvent):void
		{
			bBusy = false;
			nColdmsec = CommentSender.COLDTIME;
			commentUI.dispatchCommentListViewEvent(CommentListViewEvent.COLDTRICKER, {'enable':true,'label':'发表' } );
		}
		public function set mode(mod:int):void
		{
			_mode = mod;
		}
		public function set color(clr:int):void
		{
			_color = clr;
		}
		public function set size(sz:Number):void
		{
			_size = sz;
			//trace("set size _size : " + _size);
		}
		public function get mode():int
		{
			return _mode
		}
		public function get color():int
		{
			return _color
		}
		public function get size():Number
		{
			return _size;
		}
		private function previewCommentHandler(evt:CommentListViewEvent):void
		{
			var tmp:Object = { 'stime':evt.data.stime,
			'text':evt.data.text,
			'mode':evt.data.mode,
			'color':evt.data.color,
			'size':evt.data.size,
			'date':Strings.date(),
			'border':true,
			'prev':true};

			getter.preview(tmp);
		}
		private function sendCommentHandler(evt:CommentListViewEvent):void
		{
			if (!evt.data.am)
			{
				if (latestComment == evt.data.text || bBusy)
				{
					return;
				}
				
				var tmp:Object = { 'stime':evt.data.stime,
				'text':evt.data.text,
				'mode':_mode,
				'color':_color,
				'size':_size,
				'date':Strings.date(),
				'border':true};

				getter.send(tmp);
				latestComment = evt.data.text;
				
				if (getter.loadable)//事实上应该是sendable,但是没有设这个变量,用loadable将就下也不是不可以
				{
					bBusy = true;
					coldTime.reset();
					coldTime.start();
				}
			}
			else
			{
				tmp = { 'stime':evt.data.stime,
				'text':evt.data.text,
				'mode':evt.data.mode,
				'color':evt.data.color,
				'size':evt.data.size,
				'date':Strings.date(),
				'border':true};

				getter.send(tmp);
				latestComment = evt.data.text;
				
			}

		}
		
		private function sendPopoCommentHandler(event:CommentListViewEvent):void
		{
			getter.sendPopo(event.data);
		}
		
	}

}