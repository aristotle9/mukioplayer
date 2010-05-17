/**
* Manages playback of http streaming flv.
**/
package com.jeroenwijering.models {


import com.jeroenwijering.events.*;
import com.jeroenwijering.models.AbstractModel;
import com.jeroenwijering.player.Model;
import com.jeroenwijering.utils.*;

import flash.events.*;
import flash.media.*;
import flash.net.*;
import flash.utils.*;


public class HTTPModel extends AbstractModel {


	/** Offset in bytes of the last seek. **/
	private var byteoffset:Number = 0;
	/** Save if the bandwidth checkin already occurs. **/
	private var bwcheck:Boolean;
	/** Bandwidth interval checking ID. **/
	private var bwtimeout:Number;
	/** Switch on startup if the bandwidth is not enough. **/
	private var bwswitch:Boolean = true;
	/** NetConnection object for setup of the video stream. **/
	private var connection:NetConnection;
	/** ID for the position interval. **/
	private var interval:Number;
	/** Object with keyframe times and positions. **/
	private var keyframes:Object;
	/** Interval ID for the loading. **/
	private var loadinterval:Number;
	/** Save whether metadata has already been sent. **/
	private var meta:Boolean;
	/** Boolean for mp4 / flv streaming. **/
	private var mp4:Boolean;
	/** Start parameter. **/
	private var startparam:String = 'start';
	/** NetStream instance that handles the stream IO. **/
	private var stream:NetStream;
	/** Offset in seconds of the last seek. **/
	private var timeoffset:Number = 0;
	/** Sound control object. **/
	private var transformer:SoundTransform;
	/** Video object to be instantiated. **/
	private var video:Video;


	/** Constructor; sets up the connection and display. **/
	public function HTTPModel(mod:Model):void {
		super(mod);
		connection = new NetConnection();
		connection.connect(null);
		stream = new NetStream(connection);
		stream.checkPolicyFile = true;
		stream.addEventListener(NetStatusEvent.NET_STATUS,statusHandler);
		stream.addEventListener(IOErrorEvent.IO_ERROR,errorHandler);
		stream.addEventListener(AsyncErrorEvent.ASYNC_ERROR,errorHandler);
		stream.bufferTime = model.config['bufferlength'];
		stream.client = new NetClient(this);
		transformer = new SoundTransform();
		video = new Video(320,240);
		video.smoothing = model.config['smoothing'];
		video.attachNetStream(stream);
		addChild(video);
	};


	/** Convert seekpoints to keyframes. **/
	private function convertSeekpoints(dat:Object):Object {
		var kfr:Object = new Object();
		kfr.times = new Array();
		kfr.filepositions = new Array();
		for (var j:String in dat) {
			kfr.times[j] = Number(dat[j]['time']);
			kfr.filepositions[j] = Number(dat[j]['offset']);
		}
		return kfr;
	};


	/** Catch security errors. **/
	private function errorHandler(evt:ErrorEvent):void {
		stop();
		model.sendEvent(ModelEvent.ERROR,{message:evt.text});
	};


	/** Bandwidth is checked every four seconds as long as there's loading. **/
	private function getBandwidth(old:Number):void {
		var ldd:Number = stream.bytesLoaded;
		var bdw:Number = Math.round((ldd-old)*4/1000);
		if(ldd < stream.bytesTotal) {
			if(bdw > 0) { model.config['bandwidth'] = bdw; }
			if(bwswitch) {
				bwswitch = false;
				if(item['levels'] && getLevel() != model.config['level']) {
					byteoffset = -1;
					seek(position);
					return;
				}
			}
			bwtimeout = setTimeout(getBandwidth,2000,ldd);
		}
	};


	/** Return which level best fits the display width and connection bandwidth. **/
	private function getLevel():Number {
		var lvl:Number = item['levels'].length-1;
		for (var i:Number=0; i<item['levels'].length; i++) {
			if(model.config['width'] >= item['levels'][i].width && 
				model.config['bandwidth'] >= item['levels'][i].bitrate) {
				lvl = i;
				break;
			}
		}
		return lvl;
	};


	/** Return a keyframe byteoffset or timeoffset. **/
	private function getOffset(pos:Number,tme:Boolean=false):Number {
		if(!keyframes) {
			return 0;
		}
		for (var i:Number=0; i < keyframes.times.length - 1; i++) {
			if(keyframes.times[i] <= pos && keyframes.times[i+1] >= pos) {
				break;
			}
		}
		if(tme == true) {
			return keyframes.times[i];
		} else { 
			return keyframes.filepositions[i];
		}
	};


	/** Create the video request URL. **/
	private function getURL():String {
		var url:String = item['file'];
		var off:Number  = byteoffset;
		if(model.config['http.startparam']) {
			startparam = model.config['http.startparam'];
		}
		if(item['streamer']) {
			if(item['streamer'].indexOf('/') > -1) {
				url = getURLConcat(item['streamer'],'file',item['file']);
			} else { 
				startparam = item['streamer'];
			}
		}
		if(mp4) {
			off = timeoffset;
		} else if (startparam == 'starttime') {
			startparam = 'start';
		}
		if(!mp4 || off > 0) {
			url = getURLConcat(url,startparam,off);
		}
		if(model.config['token']) {
			url = getURLConcat(url,'token',model.config['token']);
		}
		return url;
	};


	/** Concatenate a parameter to the url. **/
	private function getURLConcat(url:String,prm:String,val:*):String {
		if(url.indexOf('?') > -1) {
			return url+'&'+prm+'='+val;
		} else {
			return url + '?'+prm+'='+val;
		}
	};


	/** Load content. **/
	override public function load(itm:Object):void {
		item = itm;
		position = timeoffset;
		bwcheck = false;
		if(item['levels']) {
			model.config['level'] = getLevel();
			item['file'] = item['levels'][model.config['level']].url;
		}
		stream.play(getURL());
		clearInterval(interval);
		interval = setInterval(positionInterval,100);
		clearInterval(loadinterval);
		loadinterval = setInterval(loadHandler,200);
		clearTimeout(bwtimeout);
		model.config['mute'] == true ? volume(0): volume(model.config['volume']);
		model.sendEvent(ModelEvent.STATE,{newstate:ModelStates.BUFFERING});
	};


	/** Interval for the loading progress **/
	private function loadHandler():void {
		var ldd:Number = stream.bytesLoaded;
		var ttl:Number = stream.bytesTotal;
		var pct:Number = timeoffset/(item['duration']+0.001);
		var off:Number = Math.round(ttl*pct/(1-pct));
		ttl += off;
		model.sendEvent(ModelEvent.LOADED,{loaded:ldd,total:ttl,offset:off});
		if(ldd+off >= ttl && ldd > 0) {
			clearInterval(loadinterval);
		}
		if(ldd > 0 && !bwcheck) {
			bwcheck = true;
			bwtimeout = setTimeout(getBandwidth,2000,ldd);
		}
	};


	/** Get metadata information from netstream class. **/
	public function onClientData(dat:Object):void {
		if(dat.width) {
			video.width = dat.width;
			video.height = dat.height;
			super.resize();
		}
		if(!item['duration'] && dat.duration) {
			item['duration'] = dat.duration;
		}
		if(dat['type'] == 'metadata' && !meta) {
			meta = true;
			if(dat.seekpoints) {
				mp4 = true;
				keyframes = convertSeekpoints(dat.seekpoints);
			} else {
				mp4 = false;
				keyframes = dat.keyframes;
			}
			if(item['start'] > 0) {
				seek(item['start']);
			}
		}
		model.sendEvent(ModelEvent.META,dat);
	};


	/** Pause playback. **/
	override public function pause():void {
		stream.pause();
		clearInterval(interval);
		model.sendEvent(ModelEvent.STATE,{newstate:ModelStates.PAUSED});
	};


	/** Resume playing. **/
	override public function play():void {
		stream.resume();
		interval = setInterval(positionInterval,100);
		model.sendEvent(ModelEvent.STATE,{newstate:ModelStates.PLAYING});
	};


	/** Interval for the position progress **/
	private function positionInterval():void {
		var pos:Number = Math.round(stream.time*10)/10;
		if (mp4) {
			pos += timeoffset;
		}
		var bfr:Number = stream.bufferLength/stream.bufferTime;
		if(bfr < 0.5 && pos < item['duration']-5 && model.config['state'] != ModelStates.BUFFERING) {
			model.sendEvent(ModelEvent.STATE,{newstate:ModelStates.BUFFERING});
		} else if (bfr > 1 && model.config['state'] != ModelStates.PLAYING) {
			model.sendEvent(ModelEvent.STATE,{newstate:ModelStates.PLAYING});
		}
		if(pos < item['duration'] + 10) {
			if(pos != position) {
				model.sendEvent(ModelEvent.TIME,{position:pos,duration:item['duration']});
				position = pos;
			}
		} else if (item['duration'] > 0) {
			stream.pause();
			clearInterval(interval);
			model.sendEvent(ModelEvent.STATE,{newstate:ModelStates.COMPLETED});
		}
	};


	/** The stage has been resize. **/
	override public function resize():void {
		super.resize();
		if(item['levels'] && getLevel() != model.config['level']) {
			byteoffset = getOffset(position);
			timeoffset = position = getOffset(position,true);
			load(item);
		}
	};


	/** Seek to a specific second. **/
	override public function seek(pos:Number):void {
		var off:Number = getOffset(pos);
		clearInterval(interval);
		if(off < byteoffset || off >= byteoffset+stream.bytesLoaded) {
			timeoffset = position = getOffset(pos,true);
			byteoffset = off;
			load(item);
		} else {
			if(model.config['state'] == ModelStates.PAUSED) {
				stream.resume();
			}
			position = pos;
			if(mp4) {
				stream.seek(getOffset(position-timeoffset,true));
			} else {
				stream.seek(getOffset(position,true));
			}
			play();
		}
	};


	/** Receive NetStream status updates. **/
	private function statusHandler(evt:NetStatusEvent):void {
		switch (evt.info.code) {
			case "NetStream.Play.Stop":
				if(model.config['state'] != ModelStates.COMPLETED && 
					model.config['state'] != ModelStates.BUFFERING) {
					clearInterval(interval);
					model.sendEvent(ModelEvent.STATE,{newstate:ModelStates.COMPLETED});
				}
				break;
			case "NetStream.Play.StreamNotFound":
				stop();
				model.sendEvent(ModelEvent.ERROR,{message:'Video not found: '+item['file']});
				break;
		}
		model.sendEvent(ModelEvent.META,{info:evt.info.code});
	};


	/** Destroy the HTTP stream. **/
	override public function stop():void {
		if(stream.bytesLoaded < stream.bytesTotal) {
			stream.close();
		} else {
			stream.pause();
		}
		clearInterval(interval);
		clearInterval(loadinterval);
		byteoffset = timeoffset = position = 0;
		keyframes = undefined;
		meta = false;
		model.sendEvent(ModelEvent.STATE,{newstate:ModelStates.IDLE});
	};


	/** Set the volume. **/
	override public function volume(vol:Number):void {
		transformer.volume = vol/100;
		stream.soundTransform = transformer;
	};


};


}