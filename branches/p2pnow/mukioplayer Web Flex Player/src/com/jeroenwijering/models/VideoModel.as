/**
* Wrapper for playback of progressively downloaded video.
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


public class VideoModel extends AbstractModel {


	/** Save if the bandwidth checkin already occurs. **/
	private var bwcheck:Boolean;
	/** Switch if the bandwidth is not enough. **/
	private var bwswitch:Boolean = true;
	/** NetConnection object for setup of the video stream. **/
	private var connection:NetConnection;
	/** ID for the position interval. **/
	private var interval:Number;
	/** Interval ID for the loading. **/
	private var loading:Number;
	/** NetStream instance that handles the stream IO. **/
	private var stream:NetStream;
	/** Sound control object. **/
	private var transformer:SoundTransform;
	/** Video object to be instantiated. **/
	private var video:Video;


	/** Constructor; sets up the connection and display. **/
	public function VideoModel(mod:Model):void {
		super(mod);
		connection = new NetConnection();
		connection.connect(null);
		stream = new NetStream(connection);
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
					model.config['level'] = getLevel();
					item['file'] = item['levels'][model.config['level']].url;
					load(item);
					return;
				}
			}
			setTimeout(getBandwidth,2000,ldd);
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


	/** Load content. **/
	override public function load(itm:Object):void {
		item = itm;
		position = 0;
		bwcheck = false;
		if(item['levels']) {
			model.config['level'] = getLevel();
			item['file'] = item['levels'][model.config['level']].url;
		}
		stream.checkPolicyFile = true;
		stream.play(item['file']);
		clearInterval(interval);
		interval = setInterval(positionInterval,100);
		clearInterval(loading);
		loading = setInterval(loadHandler,200);
		model.config['mute'] == true ? volume(0): volume(model.config['volume']);
		model.sendEvent(ModelEvent.STATE,{newstate:ModelStates.BUFFERING});
		resize();
	};


	/** Interval for the loading progress **/
	private function loadHandler():void {
		var ldd:Number = stream.bytesLoaded;
		var ttl:Number = stream.bytesTotal;
		model.sendEvent(ModelEvent.LOADED,{loaded:ldd,total:ttl});
		if(ldd && ldd == ttl) {
			clearInterval(loading);
		}
		if(ldd > 0 && !bwcheck) {
			bwcheck = true;
			setTimeout(getBandwidth,2000,ldd);
		}
	};


	/** Get metadata information from netstream class. **/
	public function onClientData(dat:Object):void {
		if(dat.width) {
			video.width = dat.width;
			video.height = dat.height;
			resize();
		}
		if(dat.duration && !item['duration']) {
			item['duration'] = dat.duration;
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
		var bfr:Number = stream.bufferLength/stream.bufferTime;
		if(bfr < 0.5 && position < item['duration']-5 && model.config['state'] != ModelStates.BUFFERING) {
			model.sendEvent(ModelEvent.STATE,{newstate:ModelStates.BUFFERING});
		} else if (bfr > 1 && model.config['state'] != ModelStates.PLAYING) {
			model.sendEvent(ModelEvent.STATE,{newstate:ModelStates.PLAYING});
		}
		if(pos < item['duration'] + 10) {
			if(pos != position) {
				position = pos;
				model.sendEvent(ModelEvent.TIME,{position:pos,duration:item['duration']});
			}
		} else if (item['duration']) {
			stream.pause();
			clearInterval(interval);
			model.sendEvent(ModelEvent.STATE,{newstate:ModelStates.COMPLETED});
		}
	};


	/** Seek to a new position. **/
	override public function seek(pos:Number):void {
		if(stream && pos < stream.bytesLoaded/stream.bytesTotal*item['duration']) {
			position = pos;
			clearInterval(interval);
			stream.seek(position);
			play();
		}
	};


	/** Receive NetStream status updates. **/
	private function statusHandler(evt:NetStatusEvent):void {
		switch (evt.info.code) {
			case "NetStream.Play.Stop":
				if(position > 1) {
					clearInterval(interval);
					model.sendEvent(ModelEvent.STATE,{newstate:ModelStates.COMPLETED});
				}
				break;
			case "NetStream.Play.StreamNotFound":
				stop();
				model.sendEvent(ModelEvent.ERROR,{message:'Video not found or access denied: '+item['file']});
				break;
		}
		model.sendEvent(ModelEvent.META,{status:evt.info.code});
	};


	/** Destroy the video. **/
	override public function stop():void {
		if(stream.bytesLoaded < stream.bytesTotal) {
			stream.close();
		} else {
			stream.pause();
		}
		clearInterval(loading);
		clearInterval(interval);
		position = 0;
		model.sendEvent(ModelEvent.STATE,{newstate:ModelStates.IDLE});
	};


	/** Set the volume. **/
	override public function volume(vol:Number):void {
		transformer.volume = vol/100;
		stream.soundTransform = transformer;
	};


};


}