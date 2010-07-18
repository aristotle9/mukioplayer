package org.lala.utils 
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import org.lala.events.AcfunGraberEvent;
	import com.jeroenwijering.utils.Strings;
	
	import flash.system.System;
	
	/**
	 * ...
	 * grab video vid or video url by html address
	 * @author 
	 */
	public class AcfunGraber extends EventDispatcher
	{
		private var loader:URLLoader;
		private var patten:RegExp = /<embed([^>]+)>/i;
		private var partPatten:RegExp = /<select(.+)<\/select>/smi;
		private var publisherPatten:RegExp = /(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}) (.+) 投稿/i;
		private var descPatten:RegExp = /<meta name="description" content="(.*)">/i;

		private var url:String;
		private var title:String = '';
		private var date:String;
		private var upper:String;
		private var desc:String;
		
		private var baddItem:Boolean = false;
		
		public function AcfunGraber() 
		{
			loader = new URLLoader();
			loader.addEventListener(Event.COMPLETE, completeHandler);
			loader.addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
			
		}
		
		public function load(_url:String,ba:Boolean=false):void
		{
			url = _url;
			baddItem = ba;
			//patten = ptn;
			
			var arr:Array = url.match(/((?:anime|music|game|ent|zj)\/.+\.html)/i);
			if (!arr)
			{
				dispatchEvent(new AcfunGraberEvent(AcfunGraberEvent.COMPLETE, { flag:false } ));
				return;
			}
			url = 'http://acfun.cn/html/' + arr[1];
			System.useCodePage = true;
			loader.load(new URLRequest(url));
		}
		private function completeHandler(evt:Event):void
		{
			var str:String = String(loader.data);
			var arr:Array = str.match(patten);
			if (!arr)
			{
				dispatchEvent(new AcfunGraberEvent(AcfunGraberEvent.COMPLETE, { flag:false } ));
			}
			else
			{
				var brr:Array = str.match(/<title>(.*) - AcFun.cn/i);
				title = '';
				if (brr)
				{
					title = brr[1];
				}
				dispatchEvent(new AcfunGraberEvent(AcfunGraberEvent.COMPLETE, { flag:true, data:parseData(arr[1], title) } ));
				
				if (baddItem)
				{
					dispatchEvent(new AcfunGraberEvent(AcfunGraberEvent.CLEARITEMS,null));
					desc = date = upper = '';
					brr = publisherPatten.exec(str);
					if (brr)
					{
						date = brr[1];
						upper = brr[2];
					}
					brr = descPatten.exec(str)
					if (brr)
					{
						desc = brr[1];
					}
					dispatchEvent(new AcfunGraberEvent(AcfunGraberEvent.HTMLINFO, {title:title,desc:desc,url:url,upper:upper,date:date}));
					
					brr = str.match(partPatten);
					if (brr)
					{
						parseSections(brr[1]);
					}
				}
			}
			System.useCodePage = false;
		}
		private function parseSections(str:String):void
		{
			trace("Match Selected str : " + str);
			var scptn:RegExp =/<option value='([^']+)'>([^<]+)<\/option>/ig;
			var n:int = url.lastIndexOf('/');
			var urlhd:String = url.substring(0, n+1);
			var arr:Object = scptn.exec(str);
			var i:int;
			while(arr)
			{
				var obj:Object =
				{
					htmlref:urlhd + arr[1],
					title:title,
					ptitle:arr[2],
					date:date,
					upper:upper,
					vid:undefined,
					cid:undefined,
					file:undefined,
					cfile:undefined
				}
				//trace("obj.ptitle : " + obj.ptitle);
				//trace("obj.htmlref : " + obj.htmlref);
				dispatchEvent(new AcfunGraberEvent(AcfunGraberEvent.ADDITEM, obj));
				arr = scptn.exec(str);
				i++;
				if (i > 100)
				{
					break;
				}
			}
		}
		public static function parseData(str:String,ti:String=''):Object
		{
			var obj:Object = {
				vid:undefined,
				cid:undefined,
				file:undefined,
				title:ti
				};
			var arr:Array = str.match(/id=\s*(\w+)/i);
			trace("match(/id=(\w+)/) : ");
			if (arr)
			{
			trace("match(/id=(\w+)/) :ed ");
				obj['vid'] = arr[1];
			}
			arr = str.match(/file=\s*([^\?&"]+)/i);
			trace("match(/file=\s*([^\?&\"]+)/) : ");
			if (arr)
			{
				trace("match(/file=\s*([^\?&\"]+)/) :ed ");
				obj['file'] = arr[1];
				obj['cid'] = obj['vid'];
				obj['vid'] = undefined;
			}
			return obj;
			
			
		}
		private function ioErrorHandler(evt:IOErrorEvent):void
		{
			dispatchEvent(new AcfunGraberEvent(AcfunGraberEvent.COMPLETE,{flag:false}));
			System.useCodePage = false;
		}
		
	}

}