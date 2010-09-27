package org.lala.utils 
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.TimerEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLVariables;
	import flash.utils.Timer;
	import com.adobe.serialization.json.JSON;
	
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
	 * get or send comments
	 * ...
	 * @author 
	 */
	public class CommentGetter extends EventDispatcher
	{
		public static var baseURL:String='';
		
		private var xmlLoader:URLLoader;
		private var xmlLoader2:URLLoader;
		private var listviewready:Boolean = false;
		private var commentviewready:Boolean = false;
		private var id:String;
		private var type:String;
		private var length:int = 0;
		private var bfile:Boolean = false;
		private var bnico:Boolean = false;
		private var bnewload:Boolean = false;
		private var _loadable:Boolean = true;
		
		//private var fms:Fms;
		private var userName:String;
		
		
		public function CommentGetter() 
		{
			xmlLoader = new URLLoader();
			xmlLoader.addEventListener(Event.COMPLETE, xmlHandler);
			xmlLoader.addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
			
			xmlLoader2 = new URLLoader();
			xmlLoader2.addEventListener(Event.COMPLETE, xmlHandler);
			xmlLoader2.addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
			
			userName = "chxs" + Math.floor(Math.random() * 1000000);
			
			//loadTimer = new Timer(CommentGetter.commentLoadInterval);
			//loadTimer.addEventListener(TimerEvent.TIMER, loadTimerHandler);
			
		}
		public function load(_id:String='',_type:String='',bf:Boolean=false,bnic:Boolean=false,bn:Boolean=false,lb:Boolean=true):void
		{
			id = _id;
			type = _type;
			bfile = bf;
			bnico = bnic;
			bnewload = bn;
			_loadable = lb;
			
			if (bn)
			{
				length = 0;
				dispatchEvent(new CommentDataManagerEvent(CommentDataManagerEvent.NEW, null));
				bnewload = false;
			}
			
			//if (fms)
			//{
				//fms.removeEventListener(FmsEvent.ACCEPTMSG, recieveMsgHandler);
				//fms = null;
			//}
			
			//if (!bfile && _loadable)
			//{
				//var obj:Object = {
				//username:userName,
				//playType:'video',
				//sortSina:'new',
				//movieID:id
				//};
				//
				//fms = new Fms(obj);
				//fms.addEventListener(FmsEvent.ACCEPTMSG, recieveMsgHandler);
//
			//}
			
			if (_loadable)
			{
				xmlLoader.load(new URLRequest(bfile ? id : xmlPath));
				xmlLoader2.load(new URLRequest(getXmlUrl2(id)));//第二重字幕
			}
			
			//trace("bfile ? id : getXmlUrl(id) : " + bfile ? id : getXmlUrl(id));
		}
		
		//private function recieveMsgHandler(evt:FmsEvent):void
		//{
			//if (evt.data.username == userName)
			//{
				//return;
			//}
			//var tmp:Object = {
			//'username:', evt.data.username,
			//'mode': uint(evt.data.mode),
			//'stime':parseFloat(evt.data.playTime),
			//'size':uint(evt.data.fontsize),
			//'color': uint(evt.data.color),
			//'date': evt.data.times,
			//'text':String(evt.data.message).replace(/(\/n|\\n|\n|\r\n)/g, "\r"),
			//'border':false,
			//'id':length ++
			//};
//			trace("tmp Text : " + tmp.text);
			//dispatchEvent(new CommentDataManagerEvent(tmp.mode, tmp));
			//dispatchEvent(new CommentDataManagerEvent(CommentDataManagerEvent.ADDONE, tmp));
		//}
		
		public function set loadable(lb:Boolean):void
		{
			_loadable = lb;
		}
		public function get loadable():Boolean
		{
			return _loadable;
		}
		
		public function preview(data:Object):void
		{
			data['text'] = String(data.text).replace(/(\/n|\\n|\n|\r\n)/g, "\r");
			dispatchEvent(new CommentDataManagerEvent(data.mode, data));
			
		}
		public function send(data:Object):void
		{
			data['text'] = String(data.text).replace(/(\/n|\\n|\n|\r\n)/g, "\r");
			data['id'] = length ++;
			dispatchEvent(new CommentDataManagerEvent(data.mode, data));
			dispatchEvent(new CommentDataManagerEvent(CommentDataManagerEvent.ADDONE, data));
			
			if (bfile || !_loadable)
			{
				return;
			}
			var postVariables:URLVariables = new URLVariables();
			postVariables.playerID = id;
			//postVariables.vid = id;
			postVariables.message = data.text;
			postVariables.color = data.color;
			postVariables.fontsize = data.size;
			postVariables.mode = data.mode;
			postVariables.playTime = data.stime;
			postVariables.date = data.date;
			
			var postRequest:URLRequest = new URLRequest(serverPath);
			postRequest.method = 'POST';
			postRequest.data = postVariables;
			var postLoader : URLLoader = new URLLoader();
			postLoader.addEventListener(IOErrorEvent.IO_ERROR,ioErrorHandler);
			try {
				postLoader.load(postRequest);
			}
			catch (e:Error)
			{
				trace('post Error');
			}
			
			//if (fms)
			//{
				//var obj:Object = {
					//'username':userName,
					//'mode':data.mode,
					//'color':data.color,
					//'fontsize':data.size,
					//'message':data.text,
					//'playTime':data.stime,
					//'times':data.date
				//};
				//fms.sendMsg(obj);
			//}
		}
		
		public function sendPopo(data:Object):void
		{
			data['id'] = length ++;
			dispatchEvent(new CommentDataManagerEvent(data.style + data.position, data));
			dispatchEvent(new CommentDataManagerEvent(CommentDataManagerEvent.ADDONE, data))
			
			//以静态文件形式加载的弹幕没有提交功能
			if (bfile || !_loadable)
			{
				return;
			}
			
			var textData:Array = [
			data.text,
			data.x,
			data.y,
			data.alpha,
			data.style,
			data.duration,
			data.inStyle,
			data.outStyle,
			data.position,
			data.tStyle,
			data.tEffect,
			];
			var postVariables:URLVariables = new URLVariables();
			postVariables.playerID = id;
			//postVariables.vid = id;
			postVariables.message = JSON.encode(textData);
			postVariables.color = data.color;
			postVariables.fontsize = data.size;
			postVariables.mode = data.mode;
			postVariables.playTime = data.stime;
			postVariables.date = data.date;
			
			var postRequest:URLRequest = new URLRequest(serverPath);
			postRequest.method = 'POST';
			postRequest.data = postVariables;
			var postLoader : URLLoader = new URLLoader();
			postLoader.addEventListener(IOErrorEvent.IO_ERROR,ioErrorHandler);
			try {
				postLoader.load(postRequest);
			}
			catch (e:Error)
			{
				trace('post Error');
			}
		}
		
		private function ioErrorHandler(vet:IOErrorEvent=null):void
		{
			trace('io Error');
			msg('评论文件加载失败,或者发送失败');
		}
		public function listReady():void
		{
			listviewready = true;
		}
		
		public function viewReady():void
		{
			commentviewready = true;
		}
		
		private function xmlHandler(evt:Event):void
		{
			try
			{
				var dat:XML = XML(evt.target.data);
				//trace("evt.target.data : " + dat.descendants('chat').length());
				parseComment(dat);
				parseComment2(dat);
			}
			catch (e:Error)
			{
				trace('xmlHandler : not a xml file.');
				ioErrorHandler();
			}
		}
		
		//parse bili format
		private function parseComment2(xml:XML):void
		{
			var lst:XMLList = xml.descendants('d');
			
			var i:int = 0;
			while (i < lst.length())
			{
				var item:* = lst[i++];
				var attrs:Array = String(item.@p).split(',');
				var tmp:Object ={
				'stime':parseFloat(attrs[0]),
				'mode':uint(attrs[1]),
				'size':uint(attrs[2]),
				'color':uint(attrs[3]),
				'date':Strings.date(new Date(attrs[4] * 1000)),
				'border':false,
				'id':length++};
				
				if (uint(attrs[1]) != 9)
				{
					var str:String = String(item).replace(/(\/n|\\n|\n|\r\n)/g, "\r");
					tmp.text = str;
					dispatchEvent(new CommentDataManagerEvent(tmp.mode, tmp));
					dispatchEvent(new CommentDataManagerEvent(CommentDataManagerEvent.ADDONE, tmp))
				}
				else
				{
					try
					{
					var appendattr:Object = JSON.decode(item);
					str = String(appendattr[0]).replace(/(\/n|\\n|\n|\r\n)/g, "\r");
					tmp.text = str;
					tmp.x = appendattr[1];
					tmp.y = appendattr[2];
					tmp.alpha = appendattr[3];
					tmp.style = appendattr[4];
					tmp.duration = appendattr[5];
					tmp.inStyle = appendattr[6];
					tmp.outStyle = appendattr[7];
					tmp.position = appendattr[8];
					tmp.tStyle = appendattr[9];
					tmp.tEffect = appendattr[10];
					dispatchEvent(new CommentDataManagerEvent(tmp.style + tmp.position, tmp));
					dispatchEvent(new CommentDataManagerEvent(CommentDataManagerEvent.ADDONE, tmp))
					}
					catch (error:Error)
					{
						trace('JSON decode failed!');
						msg('一条弹幕坏掉了');
					}

				}
			}
		}
		
		//acfun format
		private function parseComment(xml:XML):void
		{
			var lst:XMLList = xml.descendants('data');
			
			var i:int = 0;
			while (i < lst.length())
			{
				var item:* = lst[i++];
				var tmp:Object ={
				'color':uint(item.message.attribute("color")),
				'size':uint(item.message.attribute("fontsize")),
				'mode':uint(item.message.attribute("mode")) || uint(item.message.attribute("display")),
				'stime':parseFloat(item.playTime),
				'date':item.times,
				'border':false,
				'author':item.user,
				'id':length++ };
				
				if (tmp.mode != 9)
				{
					var str:String = String(item.message).replace(/(\/n|\\n|\n|\r\n)/g, "\r");
					tmp.text = str;
					dispatchEvent(new CommentDataManagerEvent(tmp.mode, tmp));
					dispatchEvent(new CommentDataManagerEvent(CommentDataManagerEvent.ADDONE, tmp))
				}
				else
				{
					try
					{
						var appendattr:Object = JSON.decode(item.message);
						str = String(appendattr[0]).replace(/(\/n|\\n|\n|\r\n)/g, "\r");
						tmp.text = str;
						tmp.x = appendattr[1];
						tmp.y = appendattr[2];
						tmp.alpha = appendattr[3];
						tmp.style = appendattr[4];
						tmp.duration = appendattr[5];
						tmp.inStyle = appendattr[6];
						tmp.outStyle = appendattr[7];
						tmp.position = appendattr[8];
						tmp.tStyle = appendattr[9];
						tmp.tEffect = appendattr[10];
						dispatchEvent(new CommentDataManagerEvent(tmp.style + tmp.position, tmp));
						dispatchEvent(new CommentDataManagerEvent(CommentDataManagerEvent.ADDONE, tmp))
					}
					catch (error:Error)
					{
						trace('JSON decode failed!');
						msg('一条弹幕坏掉了');
					}
				}//if end
			}//while end
		}

		private function getXmlUrl2(id:String):String
		{
			return 'http://'+ baseURL + '/pcomment/' + id + '/permanent/?r=' + Math.random();
			//return '/pcomment/' + id + '/permanent/?r=' + Math.random();
		}
		public function get serverPath():String
		{
			return 'http://' + baseURL + '/newflvplayer/cnmd.aspx';
			//return '/newflvplayer/cnmd.aspx';
			//return '/' + type + '/' + id + '/post/';
		}
		public function get xmlPath():String
		{
			return 'http://'+ baseURL + '/newflvplayer/xmldata/' + id + '/comment_on.xml?r=' + Math.random();
			//return '/newflvplayer/xmldata/' + id + '/comment_on.xml?r=' + Math.random();
			//return '/' + type + '/' + id + '/get/';
		}
		
		//弹幕列表消息反馈
		public function msg(content:String, tail:String = '内部消息'):void
		{
			var tmp:Object = {
			//'username:', evt.data.username,
			'mode': -1,
			'stime':10086*60,
			'size':25,
			'color': 0,
			'date': tail,
			'text':content,
			'border':false,
			'id':'-1'
			};
			dispatchEvent(new CommentDataManagerEvent(CommentDataManagerEvent.ADDONE, tmp));
		}
		
	}

}