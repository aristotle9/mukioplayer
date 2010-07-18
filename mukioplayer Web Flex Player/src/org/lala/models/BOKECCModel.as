package org.lala.models
{
	import flash.display.*;
	import flash.events.Event;
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


	//import org.lala.utils.*;
	//import org.lala.events.*;

	public class BOKECCModel extends AbstractModel
	{
		protected var video:Video;
		protected var vol:Number;
		
		protected var nss:Array=[];
		protected var ofs:Array=[];
		protected var ifs:Array=[];
		protected var bi:int=-1;
		protected var pi:int=-1;
		
		protected var totle:int;
		protected var state:String;
		
		
		protected var infoLoader:URLLoader;
		//private var ns:NS;
		
		public function BOKECCModel(mod:Model):void
		{
			super(mod);
			
			video = new Video();
			video.smoothing = model.config['smoothing'];
			vol = model.config['mute'] == true ? 0 : model.config['volume'] / 100;

			addChild(video);
		}
		
		override public function load(itm:Object):void 
		{
			super.load(itm);
			
			//item['vid'] = item['file'];
			
			infoLoader = new URLLoader();
			infoLoader.addEventListener(Event.COMPLETE, uidLoadHandler);
			infoLoader.load(new URLRequest(getUidUrl(itm['vid'])));

			model.sendEvent(ModelEvent.STATE, { newstate:ModelStates.BUFFERING });
		}
		
		protected function uidLoadHandler(evt:Event):void
		{
			infoLoader.removeEventListener(Event.COMPLETE, uidLoadHandler);
			var data:String = infoLoader.data as String;
			var arr:Array = data.match(/_([^_]{4,})_/i);
			if (arr)
			{
				item['uid'] = arr[1];
				infoLoader.load(new URLRequest(getFlvUrl(item['vid'],item['uid'])));
				infoLoader.addEventListener(Event.COMPLETE, flvLoaderHandler);
			}
		}
		protected function flvLoaderHandler(evt:Event):void
		{
			infoLoader.removeEventListener(Event.COMPLETE, flvLoaderHandler);
			var data:String = infoLoader.data as String;
			var arr:Array = data.match(/flvPath="([^"]+)"/i);
			if (arr)
			{
				item['file'] = arr[1];
				totle = 0;
				ifs = [ { url:item['file'], length:0 } ];
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
				model.sendEvent(ModelEvent.ERROR, { message: 'bokecc视频载入失败-_-!' });
			}
		}
		
		protected function getUidUrl(vid:String):String
		{
			return 'http://union.bokecc.com/servlet/getPlayerSkin?videoID=' + vid + '&userID=0';
		}
		protected function getFlvUrl(vid:String,uid:String):String
		{
			return 'http://union.bokecc.com/servlet/GetVideoStatus?videoID=' + vid + '&userID=' + uid;
		}
		
		/*
		protected function xmlLoadHandler(evt:Event):void
		{
			trace("item['vid'] :>" + item['vid'] +'<');
			if (item['vid'] == '-1')
			{
				model.sendEvent(ModelEvent.ERROR, { message: '使用方法: 见程序目录readme.txt' } );
				return;
			}
			try {
				var data:XML = XML(evt.target.data);
			}
			catch (e:Error)
			{
				trace('load vid xml error,not a xml file' + evt.target.data);
				model.sendEvent(ModelEvent.ERROR, { message: '播放地址出错了!' } );
				return;
			}
			
			totle = data.timelength;
			trace("data.timelength : " + data.timelength);
			ifs = [];
			
			for each(var itm:XML in data.descendants('durl'))
			{
				ifs.push({url:itm.url, length:parseInt(itm.length),id:itm.order});
			}
			
			if (!totle)
			{
				model.sendEvent(ModelEvent.ERROR, { message: '视频出错了!' } );
				return;
			}
			
			nss = [];
			ofs = [];
			
			var co:uint = 0;
			for(var i:uint = 0;i < ifs.length;i++)
			{
				ofs[i] = co += ifs[i].length;
			}
			pi = -1;
			bi = -1;
			
			item['duration'] = totle / 1000;
			model.sendEvent(ModelEvent.STATE, { newstate:ModelStates.PAUSED } );
			state = 'ready';
			
			play();

		}*/
		
		protected function createBuffer():void
		{
			if(ifs[++bi])
			{
				trace("create buffer : " + bi);
				var ns:NS = new NS()


				ns.addEventListener(NSEvent.PLAYING, playingHandler);
				ns.addEventListener(NSEvent.BUFFERING, bufferingHandler);
				ns.addEventListener(NSEvent.CHECK_FULL, checkfullHandler);
				ns.addEventListener(NSEvent.STOP, stopHandler);
				if (bi == 0) ns.addEventListener(NSEvent.META_DATA,  metadataHandler);
				
				ns.id = ifs[bi].id 
				ns.volume = vol;
				
				ns.loadV(ifs[bi].url)
				nss.push(ns)
				return;
            }
			trace('buffer all full');
		}
		
		protected function changeNS():void
		{  
			if(pi >= 0)
			{
				if(!nss[pi])
					return
				getns(pi).stopV();
			} 

			if(nss[pi+1])
		    {
				trace("change ns : " + (pi+1));
				getns(++pi).playV();
				
				video.clear();
				video.attachNetStream(getns(pi).ns);
				
				getns(pi).stopV();
				getns(pi).playV();
				
		    }
		     
		}
		override public function play():void 
		{
			if (state == 'play')
			{
				return;
			}
			if (state == 'ready')
			{
				createBuffer();
				
				changeNS();
				//getns(pi).playV();
				
				state = 'play';
				model.sendEvent(ModelEvent.STATE, { newstate:ModelStates.PLAYING } );
			}
			if (state == 'pause')
			{
				getns(pi).playV();
				state = 'play';
				model.sendEvent(ModelEvent.STATE,{newstate:ModelStates.PLAYING});
			}
		}
		override public function pause():void 
		{
			if (state == 'pause')
			{
				return;
			}
			if (state == 'play')
			{
				getns(pi).pauseV();
				
				state = 'pause';
				model.sendEvent(ModelEvent.STATE,{newstate:ModelStates.PAUSED});
			}
		}
		override public function stop():void 
		{
			if (state == 'pause' || state=='ready')
			{
				return;
			}
			if (state == 'play')
			{
				for (var i:int = 0; i < nss.length; i++)
				{
					getns(i).stopV();
					//trace("getns(i).stopV() : ");
				}
				video.clear();
				
				pi = -1;
				changeNS();
				pause();
				//model.sendEvent(ModelEvent.STATE,{newstate:ModelStates.IDLE});
				trace("STOP pause() : ");
				return;
				
			}
			trace("STOP out ");
		}
		override public function seek(pos:Number):void 
		{
//			super.seek(pos);
			position = pos;
//			pos = Math.floor(pos);
			pos *= 1000;
			//trace("pos *= 1000 : " + pos);
						
			if (state == 'ready' || state == 'pause')
			{
				play();
				seek(position);
				pause();
				return;
			}
			//trace("seek pos : " + pos);
			seekInPart(pos, 0);
			return;/*
			var si:int = getPIByTime(pos);
			
			if (si == pi)
			{
				seekInPart(pos, si);
				return;
			}
			if (si >= nss.length)
			{
				trace("si >= nss.length : ");
				return;
			}
			for (var i:int = 0; i < nss.length; i++)
			{
				getns(i).stopV();
				//trace("getns(i).stopV() : ");
			}
			video.clear();
			//trace("video.clear() : ");
			pi = si;
			
			video.attachNetStream(getns(pi).ns);
			//trace("video.attachNetStream(getns(pi).ns) : ");
			seekInPart(pos, pi);
			//trace("seekInPart(pos, pi) : ");*/

		}
		
		protected function metadataHandler(evt:NSEvent):void
		{
			if (evt.info['width'])
			{
				video.width = evt.info['width'];
				video.height = evt.info['height'];
			}
			if(evt.info.duration) {
				item['duration'] = parseFloat(evt.info.duration);
				totle = item['duration'] * 1000;
				ifs[0].length = totle;
				ofs[0] = totle;
				trace("evt.info.duration : " + item['duration']);
				
			}
			super.resize();
			//trace("resize : ");
			model.sendEvent(ModelEvent.META, evt.info);
			getns(0).removeEventListener(NSEvent.META_DATA,  metadataHandler);
		}
		protected function bufferingHandler(evt:NSEvent):void
		{
			var next:Number;
			var current:Number;
			var pre:Number;
			if(bi == 0)
			{
				 next = int(ofs[bi]) / totle;
				 current = Number(evt.info) * next;
				 //trace("current : " + current);
				model.sendEvent(ModelEvent.LOADED, {loaded:current,total:1} );
			}
            else
            {
				pre = int(ofs[bi - 1]) / totle;
				next = int(ofs[bi]) / totle;
				current = pre + Number(evt.info) * (next - pre);
				//trace("current : " + current);
				model.sendEvent(ModelEvent.LOADED, {loaded:current,total:1} );
            }
		}
		protected function stopHandler(evt:NSEvent):void
		{
			if (pi != ifs.length -1)
			{
				changeNS();
				return;
			}
			
			//stop();
			for (var i:int = 0; i < nss.length; i++)
			{
				getns(i).stopV();
			}
			video.clear();
			
			pi = -1;
			changeNS();
			getns(pi).pauseV();
			model.sendEvent(ModelEvent.STATE, { newstate:ModelStates.COMPLETED});

			//trace("stop : pause ");
		}
		protected function checkfullHandler(evt:NSEvent):void
		{
			getns(bi).removeEventListener(NSEvent.BUFFERING, bufferingHandler);
			getns(bi).removeEventListener(NSEvent.CHECK_FULL, checkfullHandler);
			createBuffer();
		}
		protected function playingHandler(evt:NSEvent):void
		{
			var pos:Number = Math.round(getns(pi).ns.time*10)/10;
			var bfr:Number = getns(pi).ns.bufferLength / getns(pi).ns.bufferTime;
			//
			if(bfr < 0.5 && pos < ifs[pi].length - 10 && model.config['state'] != ModelStates.BUFFERING) {
				model.sendEvent(ModelEvent.STATE,{newstate:ModelStates.BUFFERING});
			} else if (bfr > 1 && model.config['state'] != ModelStates.PLAYING) {
				model.sendEvent(ModelEvent.STATE,{newstate:ModelStates.PLAYING});
			}
			//
//
			if (pi == 0)
			{
				position = uint(evt.info) / 1000;
				model.sendEvent(ModelEvent.TIME, { position:uint(evt.info) / 1000, duration:totle/1000 } );
			}
			else
			{
				position = uint(parseInt(ofs[pi-1])+uint(evt.info)) / 1000;
				model.sendEvent(ModelEvent.TIME, { position:uint(parseInt(ofs[pi - 1]) + uint(evt.info)) / 1000, duration:totle / 1000 } );
			}
		}
		override public function volume(vl:Number):void 
		{
			vol = vl / 100;//wo chao ,现在才发现这个BUG
			for(var i:uint=0;i<nss.length;i++)
		  	{
				getns(i).volume = vol;
				//trace("=====>>vol : " + vol);
		  	}
			
		}
		
		protected function getns(i:int):NS
		{
			return NS(nss[i]);
		}
		
		protected function getPIByTime(time:Number):uint
		{   
			return 0;/*
		    var i:uint = 0;
		    var pre:Number = -1;
		 	for(;i<nss.length;)
		 	{
				//trace("nss.length : " + nss.length);
              if( time > pre && time <=  ofs[i])
				break;
              pre =  ofs[i++];
             }
			 //trace("i : " + i);
		 	 return i;*/
		}
		protected function seekInPart(time:Number,si:uint):void
		{
			//trace("seekInPart time : " + time);
			 var ptime:Number;
			 if (si == 0)
			   ptime = time;
			 else
			   ptime = time - ofs[si - 1];
			   
			//trace("seekInPart ptime : " + ptime);
			   
			pause();
			getns(pi).seekV(ptime);
			play();
		}
	}
}