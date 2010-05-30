package org.lala.models
{
	import flash.display.*;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.media.Video;
	import flash.net.URLLoader;
	import flash.net.URLRequest;

	import com.jeroenwijering.events.*;
	import com.jeroenwijering.utils.*;
	import com.jeroenwijering.plugins.*;
	import com.jeroenwijering.models.*;
	import com.jeroenwijering.player.*;
	
	import org.lala.events.*;
	import org.lala.plugins.*;
	import org.lala.utils.*;
	
	import flash.net.URLRequestMethod;

	//import org.lala.utils.*;
	//import org.lala.events.*;

	public class SIXROOMModel extends BOKECCModel
	{
		//private var ns:NS;
		
		public function SIXROOMModel(mod:Model):void
		{
			super(mod);
		}
		
		override public function load(itm:Object):void 
		{
			item = itm;
			position = 0;

			infoLoader = new URLLoader();
			
			infoLoader.addEventListener(Event.COMPLETE, xml1LoadHandler);
			infoLoader.addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
			
			var req:URLRequest = new URLRequest(getXML1Url(itm['vid']));
			req.method = URLRequestMethod.POST;
			req.data = 'echo=hello';//Be polite
			infoLoader.load(req);

			model.sendEvent(ModelEvent.STATE, { newstate:ModelStates.BUFFERING });
		}
		
		protected function ioErrorHandler(evt:IOErrorEvent):void
		{
			model.sendEvent(ModelEvent.ERROR, { message: '播放地址出错了!' } );
		}
		
		protected function xml1LoadHandler(evt:Event):void
		{
			infoLoader.removeEventListener(Event.COMPLETE, xml1LoadHandler);
			var data:String = infoLoader.data as String;
			//var arr:Array = data.match(/<file_xml>(.+)<\/file_xml>/i);
			//if (arr)
			if (data)
			{
				var flvXMLPath:String = data;
				infoLoader.load(new URLRequest(flvXMLPath));
				infoLoader.addEventListener(Event.COMPLETE, flvXMLLoaderHandler);
				infoLoader.addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
			}
		}
		protected function flvXMLLoaderHandler(evt:Event):void
		{
			infoLoader.removeEventListener(Event.COMPLETE, flvXMLLoaderHandler);
			try
			{
				var data:XML = XML(infoLoader.data);
			}
			catch (e:Error)
			{
				model.sendEvent(ModelEvent.ERROR, { message: '播放地址出错了!' } );
				return;
			}
			
			if (data)
			{
				var flist:XMLList = data.descendants('file');
				for each(var itm:XML in flist)
				{
					item['file'] = itm.toString();
					break;
				}
				
				item['file'] += '?' + getKeys();
				//trace("item['file'] : " + item['file']);
				//return;
				
				totle = 0;
				ifs = [{ url:item['file'], length:0 } ];
				ofs = [0];
				nss = [];
				pi = -1;
				bi = -1;
				
				item['duration'] = totle / 1000;
				model.sendEvent(ModelEvent.STATE, { newstate:ModelStates.PAUSED } );
				state = 'ready';
				
				play();
			}
			else
			{
				model.sendEvent(ModelEvent.ERROR, { message: '6cn视频载入失败-_-!' });
			}
		}
		
		protected function getXML1Url(vid:String):String
		{
			//return 'http://6.cn/v72.php?vid=' + vid;
			//return 'http://localhost:8088/' + vid + '/sixroom/';
			//return 'http://mukiolib.appspot.com/' + vid + '/sixroom/';
			return '/' + vid + '/sixroom/';
		}
		
		protected function getKeys():String
		{
			  var dt:Date = new Date();
			  var ms:Number = dt.getTime() / 1000;
			  ms += 123456;
			  var key3:int = 1000000000 + Math.floor(Math.random() * 1000000000);
			  var key4:int = 1000000000 + Math.floor(Math.random() * 1000000000);
			  
			  var flag:Number = Math.random() * 100;
			  if (flag > 50)
			  {
				var key1:int = Math.abs(Math.floor(ms / 3) ^ key3);
				var key2:int = Math.abs(Math.floor(ms * 2 / 3) ^ key4);
			  }
			  else
			  {
				key1 = Math.abs(Math.floor(ms * 2 / 3) ^ key3);
				key2 = Math.abs(Math.floor(ms / 3) ^ key4);
			  }
			  return 'key1=' + key1.toString() + '&key2=' + key2.toString()
					+ '&key3=' + key3.toString() + '&key4=' + key4.toString();
		}
	}
}