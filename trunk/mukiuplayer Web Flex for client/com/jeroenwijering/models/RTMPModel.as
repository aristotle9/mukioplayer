package com.jeroenwijering.models {


import com.jeroenwijering.events.*;
import com.jeroenwijering.models.AbstractModel;
import com.jeroenwijering.player.Model;
import com.jeroenwijering.utils.*;

import flash.events.*;
import flash.media.*;
import flash.net.*;
import flash.utils.*;


/**
* Wrapper for playback of video streamed over RTMP. Can playback MP4, FLV, MP3, AAC and live streams.
* Server-specific features are:
* - The SecureToken functionality of Wowza (with the 'token' flahvar).
* - Load balancing with SMIL files (with the 'rtmp.loadbalance=true' flashvar).
**/
public class RTMPModel extends AbstractModel {


	/** Save if the bandwidth checkin already occurs. **/
	private var bwcheck:Boolean;
	/** Switch if the bandwidth is not enough. **/
	private var bwswitch:Boolean = true;
	/** Interval for bw checking - with dynamic streaming. **/
	private var bwinterval:Number;
	/** NetConnection object for setup of the video stream. **/
	private var connection:NetConnection;
	/** Is dynamic streaming possible. **/
	private var dynamics:Boolean;
	/** ID for the position interval. **/
	private var interval:Number;
	/** Loader instance that loads the XML file. **/
	private var loader:URLLoader;
	/** NetStream instance that handles the stream IO. **/
	private var stream:NetStream;
	/** Interval ID for subscription pings. **/
	private var subscribe:Number;
	/** Offset in seconds of the last seek. **/
	private var timeoffset:Number = 0;
	/** Sound control object. **/
	private var transformer:SoundTransform;
	/** Save the location of the XML redirect. **/
	private var smil:String;
	/** Save that a stream is streaming. **/
	private var streaming:Boolean;
	/** Save that we're transitioning. **/
	private var transitioning:Boolean;
	/** Video object to be instantiated. **/
	private var video:Video;

	/** Constructor; sets up the connection and display. **/
	public function RTMPModel(mod:Model):void {
		super(mod);
		connection = new NetConnection();
		connection.addEventListener(NetStatusEvent.NET_STATUS,statusHandler);
		connection.addEventListener(SecurityErrorEvent.SECURITY_ERROR,errorHandler);
		connection.addEventListener(IOErrorEvent.IO_ERROR,errorHandler);
		connection.addEventListener(AsyncErrorEvent.ASYNC_ERROR,errorHandler);
		connection.objectEncoding = ObjectEncoding.AMF0;
		connection.client = new NetClient(this);
		loader = new URLLoader();
		loader.addEventListener(Event.COMPLETE, loaderHandler);
		loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR,errorHandler);
		loader.addEventListener(IOErrorEvent.IO_ERROR,errorHandler);
		transformer = new SoundTransform();
		video = new Video(320,240);
		video.smoothing = model.config['smoothing'];
		addChild(video);
	};


	/** Check if the player can use dynamic streaming. **/
	private function checkDynamic(str:String):void {
		var clt:Number = Number(model.config['client'].split(' ')[2].split(',')[0]);
		var mjr:Number = Number(str.split(',')[0]);
		var mnr:Number = Number(str.split(',')[1]);
		if(clt > 9 && (mjr > 3 || (mjr == 3 && mnr > 4))) { 
			dynamics = true;
		}
	};


	/** Try subscribing to livestream **/
	private function doSubscribe(id:String):void {
		connection.call("FCSubscribe",null,id);
	};


	/** Catch security errors. **/
	private function errorHandler(evt:ErrorEvent):void {
		stop();
		model.sendEvent(ModelEvent.ERROR,{message:evt.text});
	};


	/** Bandwidth checking for dynamic streaming. **/
	private function getBandwidth():void {
		try { 
			model.config['bandwidth'] = Math.round(stream.info.maxBytesPerSecond*8/1024);
		} catch(err:Error) { 
			clearInterval(bwinterval);
		}
		if(item['levels'] && getLevel() != model.config['level']) {
			swap();
		}
	};


	/** Bandwidth checking for non-dynamic streaming. **/
	private function getBW():void {
		if(streaming) {
			connection.call("checkBandwidth",null);
		}
	};


	/** Extract the correct rtmp syntax from the file string. **/
	private function getID(url:String):String {
		var ext:String = url.substr(-4);
		if(model.config['rtmp.prepend'] == false) {
			return url;
		} else if(ext == '.mp3') {
			return 'mp3:'+url.substr(0,url.length-4);
		} else if (ext=='.mp4' || ext=='.mov' || ext=='.m4v' || ext=='.aac' || ext=='.m4a' || ext=='.f4v') {
			return 'mp4:'+url;
		} else if (ext == '.flv') {
			return url.substr(0,url.length-4);
		} else {
			return url;
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
		timeoffset = item['start'];
		model.sendEvent(ModelEvent.STATE,{newstate:ModelStates.BUFFERING});
		if(model.config['rtmp.loadbalance']) {
			smil = item['file'];
			loader.load(new URLRequest(smil));
		} else {
			connection.connect(item['streamer']);
		}
	};


	/** Get the streamer / file from the loadbalancing XML. **/
	private function loaderHandler(evt:Event):void {
		var xml:XML = XML(evt.currentTarget.data);
		item['streamer'] = xml.children()[0].children()[0].@base.toString();
		item['file'] = xml.children()[1].children()[0].@src.toString();
		connection.connect(item['streamer']);
	};


	/** Get metadata information from netstream class. **/
	public function onClientData(dat:Object):void {
		if(dat.type == 'fcsubscribe') {
			if(dat.code == "NetStream.Play.StreamNotFound" ) {
				model.sendEvent(ModelEvent.ERROR,{message:"Subscription failed: "+item['file']});
			} else if(dat.code == "NetStream.Play.Start") {
				setStream();
			}
			clearInterval(subscribe);
		}
		if(dat.width) {
			video.width = dat.width;
			video.height = dat.height;
			super.resize();
		}
		if(dat.duration && !item['duration']) {
			item['duration'] = dat.duration;
		}
		if(dat.type == 'complete') {
			clearInterval(interval);
			model.sendEvent(ModelEvent.STATE,{newstate:ModelStates.COMPLETED});
		}
		if(dat.type == 'close') {
			stop();
		}
		if(dat.type == 'bandwidth' && dat.bandwidth > 50) {
			model.config['bandwidth'] = dat.bandwidth;
		}
		if(dat.code == 'NetStream.Play.TransitionComplete') {
			transitioning = false;
		}
		model.sendEvent(ModelEvent.META,dat);
	};


	/** Pause playback. **/
	override public function pause():void {
		stream.pause();
		clearInterval(interval);
		model.sendEvent(ModelEvent.STATE,{newstate:ModelStates.PAUSED});
		if(stream && item['duration'] == 0 && !dynamics) { stop(); }
	};


	/** Resume playing. **/
	override public function play():void {
		stream.resume();
		interval = setInterval(positionInterval,100);
		model.sendEvent(ModelEvent.STATE,{newstate:ModelStates.PLAYING});
	};


	/** Interval for the position progress. **/
	private function positionInterval():void {
		var pos:Number = Math.round((stream.time)*10)/10;
		var bfr:Number = stream.bufferLength/stream.bufferTime;
		if(bfr < 0.5 && pos < item['duration']-5 && model.config['state'] != ModelStates.BUFFERING) {
			model.sendEvent(ModelEvent.STATE,{newstate:ModelStates.BUFFERING});
			stream.bufferTime = model.config['bufferlength'];
		} else if (bfr > 1 && model.config['state'] != ModelStates.PLAYING) {
			model.sendEvent(ModelEvent.STATE,{newstate:ModelStates.PLAYING});
			stream.bufferTime = model.config['bufferlength']*4;
		}
		if(pos < item['duration']) {
			if(pos != position) {
				model.sendEvent(ModelEvent.TIME,{position:pos,duration:item['duration']});
				position = pos;
			}
		} else if (!isNaN(position) && item['duration'] > 0) {
			stream.pause();
			clearInterval(interval);
			if(stream && item['duration'] == 0) { stop(); }
			model.sendEvent(ModelEvent.STATE,{newstate:ModelStates.COMPLETED});
		}
	};


	/** Check if the level must be switched on resize. **/
	override public function resize():void {
		super.resize();
		if(item['levels'] && getLevel() != model.config['level']) {
			if(dynamics) {
				swap();
			} else { 
				seek(position);
			}
		}
	};


	/** Seek to a new position. **/
	override public function seek(pos:Number):void {
		position = 0;
		timeoffset = pos;
		transitioning = false;
		clearInterval(interval);
		clearInterval(bwinterval);
		interval = setInterval(positionInterval,100);
		if(item['levels'] && getLevel() != model.config['level']) {
			model.config['level'] = getLevel();
			item['file'] = item['levels'][model.config['level']].url;
		}
		if(model.config['state'] == ModelStates.PAUSED) {
			stream.resume();
		}
		if(model.config['rtmp.subscribe']) {
			stream.play(getID(item['file']));
		} else {
			stream.play(getID(item['file']));
			if(timeoffset) { stream.seek(timeoffset); }
			if(dynamics) {
				bwinterval = setInterval(getBandwidth,2000);
			} else {
				bwinterval = setInterval(getBW,20000);
			}
		}
		streaming = true;
	};


	/** Start the netstream object. **/
	private function setStream():void {
		stream = new NetStream(connection);
		stream.checkPolicyFile = true;
		stream.addEventListener(NetStatusEvent.NET_STATUS,statusHandler);
		stream.addEventListener(IOErrorEvent.IO_ERROR,errorHandler);
		stream.addEventListener(AsyncErrorEvent.ASYNC_ERROR,errorHandler);
		stream.bufferTime = model.config['bufferlength'];
		stream.client = new NetClient(this);
		video.attachNetStream(stream);
		model.config['mute'] == true ? volume(0): volume(model.config['volume']);
		seek(timeoffset);
		resize();
	};


	/** Receive NetStream status updates. **/
	private function statusHandler(evt:NetStatusEvent):void {
		switch(evt.info.code) {
			case 'NetConnection.Connect.Success':
				if(evt.info.secureToken != undefined) {
					connection.call("secureTokenResponse",null,
						TEA.decrypt(evt.info.secureToken,model.config['token']));
				}
				if(evt.info.data) { checkDynamic(evt.info.data.version); }
				if(model.config['rtmp.subscribe']) {
					subscribe = setInterval(doSubscribe,1000,getID(item['file']));
					return;
				} else {
					setStream();
					if(!item['levels']) {
						connection.call("getStreamLength",new Responder(streamlengthHandler),getID(item['file']));
					}
				}
				break;
			case  'NetStream.Seek.Notify':
				clearInterval(interval);
				interval = setInterval(positionInterval,100);
				break;
			case 'NetConnection.Connect.Rejected':
				try { 
					if(evt.info.ex.code == 302) {
						item['streamer'] = evt.info.ex.redirect;
						setTimeout(load,100,item);
						return;
					}
				} catch (err:Error) {
					stop();
					var msg:String = evt.info.code;
					if(evt.info['description']) { msg = evt.info['description']; }
					stop();
					model.sendEvent(ModelEvent.ERROR,{message:msg});
				}
				break;
			case 'NetStream.Failed':
			case 'NetStream.Play.StreamNotFound':
				if(!streaming) {
					onClientData({type:'complete'});
				} else { 
					stop();
					model.sendEvent(ModelEvent.ERROR,{message:"Stream not found: "+item['file']});
				}
				break;
			case 'NetConnection.Connect.Failed':
				stop();
				model.sendEvent(ModelEvent.ERROR,{message:"Server not found: "+item['streamer']});
				break;
			case 'NetStream.Play.UnpublishNotify':
				stop();
				break;
		}
		model.sendEvent('META',evt.info);
	};


	/** Destroy the stream. **/
	override public function stop():void {
		if(stream && stream.time) { stream.close(); }
		streaming = false;
		connection.close();
		clearInterval(interval);
		clearInterval(bwinterval);
		position = 0;
		timeoffset = item['start'];
		model.sendEvent(ModelEvent.STATE,{newstate:ModelStates.IDLE});
		if(smil) { 
			item['file'] = smil;
		}
	};


	/** Get the streamlength returned from the connection. **/
	private function streamlengthHandler(len:Number):void {
		if(len && !item['duration']) { item['duration'] = len; }
	};


	/** Dynamically switch streams **/
	private function swap():void {
		if(transitioning == true) {
			Logger.log('transition to level '+getLevel()+' cancelled');
		} else { 
			transitioning = true;
			model.config['level'] = getLevel();
			Logger.log('transition to level '+getLevel()+' initiated');
			item['file'] = item['levels'][model.config['level']].url;
			var nso:NetStreamPlayOptions = new NetStreamPlayOptions();
			nso.streamName = getID(item['file']);
			nso.transition = NetStreamPlayTransitions.SWITCH;
			stream.play2(nso);
		}
	};


	/** Set the volume level. **/
	override public function volume(vol:Number):void {
		transformer.volume = vol/100;
		if(stream) {
			stream.soundTransform = transformer;
		}
	};


};


}