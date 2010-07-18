package org.lala.models
{
	import flash.display.*;
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.media.Video;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.utils.clearTimeout;
	import flash.utils.setTimeout;
	import flash.utils.Timer;

	import com.jeroenwijering.events.*;
	import com.jeroenwijering.utils.*;
	import com.jeroenwijering.plugins.*;
	import com.jeroenwijering.models.*;
	import com.jeroenwijering.player.*;
	
	import org.lala.events.*;
	import org.lala.plugins.*;
	import org.lala.utils.*;
	
	import com.adobe.serialization.json.*;


	public class YOUKUModel extends SINAModel
	{		
		private var youkuTimer:uint = undefined;
		private var youkuFlag:Object = { '0':true };
		
		private var type:String = 'flv';
		
		protected var infoLoader:URLLoader;

		public function YOUKUModel(mod:Model):void
		{
			super(mod);
		}
		
		override public function load(itm:Object):void 
		{
			item = itm;
			position = 0;
			
			infoLoader = new URLLoader();
			infoLoader.addEventListener(Event.COMPLETE, jsonLoadHandler);
			infoLoader.load(new URLRequest(getJSONUrl(itm['vid'])));
			
			model.sendEvent(ModelEvent.STATE, { newstate:ModelStates.BUFFERING });
		}
		
		protected function getJSONUrl(vid:String):String
		{
			return 'http://v.youku.com/player/getPlayList/VideoIDS/'+ vid + '/';
		}

		protected function jsonLoadHandler(evt:Event):void
		{
			infoLoader.removeEventListener(Event.COMPLETE, jsonLoadHandler);
			
			var jstr :String = infoLoader.data as String;
			
			var data :Object = JSON.decode(jstr);
			if (data)
			{
				//trace(JSON.encode(data));
				data = data.data[0];
				for (var index:String in data.streamtypes)
				{
					if (String(data.streamtypes[index]).toLowerCase() == 'mp4')
					{
						type = 'mp4';
					}
				}
				//hd choose
				
				//create parser
				var psr:YKParser = new YKParser(data, type);
				
				//trace(psr.KEY);
				//trace(psr.FILEID);
				//trace(psr.TYPE);
				totle = parseFloat(data['seconds']) * 1000;
				ifs = [];
				
				for (var i:int = 0; i < data['segs'][type].length; i++)
				{
					ifs.push({ url:psr.getUrl(i),
								length:parseInt(data['segs'][type][i].seconds) * 1000,
								id:i + 1
							  });
				}
				
				if (!totle)
				{
					model.sendEvent(ModelEvent.ERROR, { message: '视频出错了!' } );
					return;
				}
				
				nss = [];
				ofs = [];
				
				var co:uint = 0;
				for(i = 0;i < ifs.length;i++)
				{
					ofs[i] = co += ifs[i].length;
				}
				pi = -1;
				bi = -1;
				
				item['duration'] = totle / 1000;
				model.sendEvent(ModelEvent.STATE, { newstate:ModelStates.PAUSED } );
				state = 'ready';
				
				play();
			}
			else
			{
				model.sendEvent(ModelEvent.ERROR, { message: '播放地址出错了!' } );
			}
		}
		
		override public function seek(pos:Number):void 
		{
			position = pos;
			pos *= 1000;
						
			if (state == 'ready' || state == 'pause')
			{
				play();
				seek(position);
				pause();
				return;
			}
			
			var si:int = getPIByTime(pos);
			
			if (si == pi)
			{
				seekInPart(pos, si);
				return;
			}
			if (si >= nss.length)
			{
				return;
			}
			for (var i:int = 0; i < nss.length; i++)
			{
				getns(i).stopV();
			}
			video.clear();
			pi = si;
			
			getns(pi).playV();
			video.attachNetStream(getns(pi).ns);
			
			if (!youkuFlag[String(pi)])
			{
				youkuFlag[String(pi)] = true;
				if (youkuTimer)
				{
					clearTimeout(youkuTimer);
				}
				youkuTimer = setTimeout(seekInPart, 500, pos, pi);
			}
			else
			{
				seekInPart(pos, pi);
				
			}

		}
		
		override protected function seekInPart(time:Number,si:uint):void
		{
			super.seekInPart(time, si);			
			youkuTimer = undefined;
		}
	}
}