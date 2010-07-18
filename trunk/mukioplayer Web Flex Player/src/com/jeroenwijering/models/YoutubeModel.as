/**
* Wrapper for load and playback of Youtube videos through their API.
**/
package com.jeroenwijering.models {


import com.jeroenwijering.events.*;
import com.jeroenwijering.models.AbstractModel;
import com.jeroenwijering.player.Model;
import com.jeroenwijering.utils.Logger;

import flash.display.Loader;
import flash.events.*;
import flash.net.LocalConnection;
import flash.net.URLRequest;
import flash.system.Security;
import flash.utils.setTimeout;


public class YoutubeModel extends AbstractModel {


	/** Loader for loading the YouTube proxy **/
	private var loader:Loader;
	/** 'Unique' string to use for proxy connection. **/
	private var unique:String;
	/** Connection towards the YT proxy. **/
	private var outgoing:LocalConnection;
	/** connection from the YT proxy. **/
	private var inbound:LocalConnection;
	/** Save that a load call has been sent. **/
	private var loading:Boolean;
	/** Save the connection state. **/
	private var connected:Boolean;


	/** Setup YouTube connections and load proxy. **/
	public function YoutubeModel(mod:Model):void {
		super(mod);
		Security.allowDomain('*');
		outgoing = new LocalConnection();
		outgoing.allowDomain('*');
		outgoing.allowInsecureDomain('*');
		outgoing.addEventListener(StatusEvent.STATUS,onLocalConnectionStatusChange);
		inbound = new LocalConnection();
		inbound.allowDomain('*');
		inbound.allowInsecureDomain('*');
		inbound.addEventListener(StatusEvent.STATUS,onLocalConnectionStatusChange);
		inbound.client = this;
		loader = new Loader();
		loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR,errorHandler);
		addChild(loader);
	};


	/** Catch load errors. **/
	private function errorHandler(evt:ErrorEvent):void {
		stop();
		model.sendEvent(ModelEvent.ERROR,{message:evt.text});
	};


	/** xtract the current ID from a youtube URL **/
	private function getID(url:String):String {
		var arr:Array = url.split('?');
		var str:String = '';
		for (var i:String in arr) {
			if(arr[i].substr(0,2) == 'v=') {
				str = arr[i].substr(2);
			}
		}
		if(str == '') { str = url.substr(url.indexOf('/v/')+3); }
		if(str.indexOf('&') > -1) { 
			str = str.substr(0,str.indexOf('&'));
		}
		return str;
	};


	/** Get the location of yt.swf. **/
	private function getLocation():String {
		var loc:String;
		var url:String = loaderInfo.url;
		if(url.indexOf('http://') == 0) {
			unique = Math.random().toString().substr(2);
			loc = url.substr(0,url.indexOf('.swf'));
			loc = loc.substr(0,loc.lastIndexOf('/')+1)+'yt.swf?unique='+unique;
		} else {
			unique = '1';
			loc = 'yt.swf';
		}
		return loc;
	};

	/** Load the YouTube movie. **/
	override public function load(itm:Object):void {
		item = itm;
		position = 0;
		loading = true;
		if(connected) {
			var gid:String = getID(item['file']);
			outgoing.send('AS3_'+unique,"loadVideoById",gid,item['start']);
			resize();
		} else {
			loader.load(new URLRequest(getLocation()));
			inbound.connect('AS2_'+unique);
		}
		model.sendEvent(ModelEvent.STATE,{newstate:ModelStates.BUFFERING});
	};


	/** Pause the YouTube movie. **/
	override public function pause():void {
		outgoing.send('AS3_'+unique,"pauseVideo");
		model.sendEvent(ModelEvent.STATE,{newstate:ModelStates.PAUSED});
	};



	/** Play or pause the video. **/
	override public function play():void {
		outgoing.send('AS3_'+unique,"playVideo");
		model.sendEvent(ModelEvent.STATE,{newstate:ModelStates.PLAYING});
	};


	/** SWF loaded; add it to the tree **/
	public function onSwfLoadComplete():void {
		model.config['mute'] == true ? volume(0): volume(model.config['volume']);
		connected = true;
		if(loading) { load(item); }
	};


	/** error was thrown without this handler **/
	public function onLocalConnectionStatusChange(evt:StatusEvent):void {};


	/** Catch youtube errors. **/
	public function onError(erc:Number):void {
		stop();
		var msg:String = 'Video not found or deleted: ' + getID(item['file']);
		if(erc == 101 || erc == 150) { 
			msg = 'Embedding this video is disabled by its owner.';
		}
		model.sendEvent(ModelEvent.ERROR,{message:msg});
	};


	/** Catch youtube state changes. **/
	public function onStateChange(stt:Number):void {
		switch(Number(stt)) {
			case 0:
				if(model.config['state'] != ModelStates.BUFFERING && model.config['state'] != ModelStates.IDLE) {
					model.sendEvent(ModelEvent.STATE,{newstate:ModelStates.COMPLETED});
				}
				break;
			case 1:
				model.sendEvent(ModelEvent.STATE,{newstate:ModelStates.PLAYING});
				break;
			case 2:
				model.sendEvent(ModelEvent.STATE,{newstate:ModelStates.PAUSED});
				break;
			case 3:
				model.sendEvent(ModelEvent.STATE,{newstate:ModelStates.BUFFERING});
				break;
		}
	};


	/** Catch Youtube load changes **/
	public function onLoadChange(ldd:Number,ttl:Number,off:Number):void {
		model.sendEvent(ModelEvent.LOADED,{loaded:ldd,total:ttl,offset:off});
	};


	/** Catch Youtube position changes **/
	public function onTimeChange(pos:Number,dur:Number):void {
		model.sendEvent(ModelEvent.TIME,{position:pos,duration:dur});
		if(!item['duration']) { item['duration'] = dur; }
		
	};


	/** Resize the YT player. **/
	override public function resize():void {
		outgoing.send('AS3_'+unique,"setSize",model.config['width'],model.config['height']);
	};


	/** Seek to position. **/
	override public function seek(pos:Number):void {
		outgoing.send('AS3_'+unique,"seekTo",pos);
		play();
	};


	/** Destroy the youtube video. **/
	override public function stop():void {
		if(connected) {
			outgoing.send('AS3_'+unique,"stopVideo");
		} else {
			loading = false;
		}
		position = 0;
		model.sendEvent(ModelEvent.STATE,{newstate:ModelStates.IDLE});
	};



	/** Set the volume level. **/
	override public function volume(pct:Number):void {
		outgoing.send('AS3_'+unique,"setVolume",pct);
	};


}


}