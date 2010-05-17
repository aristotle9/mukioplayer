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
		//public static var serverPath:String = 'http://acfun.cn/newflvplayer/cnmd.aspx';
		//public static var serverPath:String = '/newflvplayer/cnmd.aspx';
		//public static var serverPath:String = 'http://127.0.0.1:86/flv/mukioplayer/post.php';
		public static var commentLoadInterval:int = 28000;//30秒载入一次评论
		//private var loadTimer:Timer;
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
		
		private var fms:Fms;
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
		//private function loadTimerHandler(evt:TimerEvent):void
		//{
			//if(_loadable) load(id,bfile,bnico);
		//}
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
			
			//loadTimer.stop();
			if (fms)
			{
				fms.removeEventListener(FmsEvent.ACCEPTMSG, recieveMsgHandler);
				fms = null;
			}
			
			if (!bfile && _loadable)
			{
				var obj:Object = {
				username:userName,
				playType:'video',
				sortSina:'new',
				movieID:id
				};
				
				fms = new Fms(obj);
				fms.addEventListener(FmsEvent.ACCEPTMSG, recieveMsgHandler);

			}
			
			if (_loadable)
			{
				xmlLoader.load(new URLRequest(bfile ? id : xmlPath));
				xmlLoader2.load(new URLRequest(bfile ? id : getXmlUrl2(id)));
			}
			
			//trace("bfile ? id : getXmlUrl(id) : " + bfile ? id : getXmlUrl(id));
		}
		
		private function recieveMsgHandler(evt:FmsEvent):void
		{
			if (evt.data.username == userName)
			{
				return;
			}
			var tmp:Object = {
			//'username:', evt.data.username,
			'mode': uint(evt.data.mode),
			'stime':parseFloat(evt.data.playTime),
			'size':uint(evt.data.fontsize),
			'color': uint(evt.data.color),
			'date': evt.data.times,
			'text':String(evt.data.message).replace(/(\/n|\\n|\n|\r\n)/g, "\r"),
			'border':false,
			'id':length ++
			};
//			trace("tmp Text : " + tmp.text);
			dispatchEvent(new CommentDataManagerEvent(tmp.mode, tmp));
			dispatchEvent(new CommentDataManagerEvent(CommentDataManagerEvent.ADDONE, tmp));
		}
		
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
			//data['width'] = Strings.strWidth(data.text,data.size);
			//data['height'] = Strings.strHeight(data.text, data.size);
			data['id'] = length ++;
			dispatchEvent(new CommentDataManagerEvent(data.mode, data));
			dispatchEvent(new CommentDataManagerEvent(CommentDataManagerEvent.ADDONE, data));
			
			if (bfile || !_loadable)
			{
				return;
			}
			var postVariables:URLVariables = new URLVariables();
			postVariables.playerID = id;
			postVariables.message = data.text;
			postVariables.color = data.color;
			postVariables.fontsize = data.size;
			//trace("postVariables.fontsize : " + postVariables.fontsize);
			postVariables.mode = data.mode;
			postVariables.playTime = data.stime;
			postVariables.date = data.date;
			trace(postVariables.toString());
			
			//var postRequest:URLRequest = new URLRequest('http://' + baseURL + CommentGetter.serverPath);
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
			
			if (fms)
			{
				var obj:Object = {
					'username':userName,
					'mode':data.mode,
					'color':data.color,
					'fontsize':data.size,
					'message':data.text,
					'playTime':data.stime,
					'times':data.date
				};
				fms.sendMsg(obj);
			}
		}
		private function ioErrorHandler(vet:IOErrorEvent):void
		{
			trace('io Error');
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
				trace("evt.target.data : " + dat.descendants('chat').length());
				parseComment(dat);
			}
			catch (e:Error)
			{
				trace('xmlHandler : not a xml file.');
			}
		}
		private function parseComment(xml:XML):void
		{
			//var res:Array = [];
			//if (bnico)
			//{
				//trace("Parse bnico : " + bnico);
				//
				//var res:Array = NicoParser.parse(xml);
				//while (length < res.length)
				//{
					//dispatchEvent(new CommentDataManagerEvent(res[length].mode, res[length]));
					//dispatchEvent(new CommentDataManagerEvent(CommentDataManagerEvent.ADDONE, res[length]));
					//length ++;
				//}
			//}
			//else
			//{
				var lst:XMLList = xml.descendants('data');

				while (length < lst.length())
				{
					var item:* = lst[length];
					var str:String = String(item.message).replace(/(\/n|\\n|\n|\r\n)/g, "\r");
					//var str:String = String(item.message);
					var tmp:Object ={
					'text':str,
					'color':uint(item.message.attribute("color")),
					//'width':Strings.strWidth(str,uint(item.message.attribute("fontsize"))),
					//'height':Strings.strHeight(str, uint(item.message.attribute("fontsize"))),
					'size':uint(item.message.attribute("fontsize")),
					'mode':uint(item.message.attribute("mode")) || uint(item.message.attribute("display")),
					'stime':parseFloat(item.playTime),
					'date':item.times,
					'border':false,
					'author':item.user,
					'id':length++};
					dispatchEvent(new CommentDataManagerEvent(tmp.mode, tmp));
					dispatchEvent(new CommentDataManagerEvent(CommentDataManagerEvent.ADDONE, tmp))
				}
			//}
			//loadTimer.start();
			//for each(var item in xml.descendants('data'))
			//{
				//res.push(tmp);
			//}
			//dispatchEvent(new CommentDataManagerEvent(CommentDataManagerEvent.SETDATA, res));
		}
		//private function getXmlUrl(id:String):String
		//{
			//return 'http://acfun.cn/newflvplayer/xmldata/' + id + '/comment_on.xml?r=' + Math.random();
			//return 'http://'+ baseURL + '/newflvplayer/xmldata/' + id + '/comment_on.xml?r=' + Math.random();
			//return '/newflvplayer/xmldata/' + id + '/comment_on.xml?r=' + Math.random();
			//return "http://localhost:86/flv/mukioplayer/get.php?id="+id+'&r='+Math.random();
			//return "http://localhost:86/flv/getxml.php?id="+id+'&r='+Math.random();
//			return 'pad.xml';
		//}
		private function getXmlUrl2(id:String):String
		{
			//return 'http://'+ baseURL + '/pcomment/' + id + '/permanent/?r=' + Math.random();
			return '/pcomment/' + id + '/permanent/?r=' + Math.random();
		}
		public function get serverPath():String
		{
			//return 'http://' + baseURL + '/newflvplayer/cnmd.aspx';
			return '/newflvplayer/cnmd.aspx';
			//return '/' + type + '/' + id + '/post/';
		}
		public function get xmlPath():String
		{
			//return 'http://'+ baseURL + '/newflvplayer/xmldata/' + id + '/comment_on.xml?r=' + Math.random();
			return '/newflvplayer/xmldata/' + id + '/comment_on.xml?r=' + Math.random();
			//return '/' + type + '/' + id + '/get/';
		}
		
	}

}