/**
* Wrapper for load and playback of Livestream channels through their API.
**/
package com.jeroenwijering.models {


import com.jeroenwijering.events.*;
import com.jeroenwijering.models.AbstractModel;
import com.jeroenwijering.player.Model;
import com.jeroenwijering.utils.Stretcher;

import flash.display.*;
import flash.events.*;
import flash.net.URLRequest;
import flash.system.*;


public class LivestreamModel extends AbstractModel {


	/** URL of the livestream SWF. **/
	private const LOCATION:String = "http://cdn.livestream.com/chromelessPlayer/wrappers/SimpleWrapper.swf";


	/** Loader for loading the Livestream API. **/
	private var loader:Loader;
	/** Reference to the chromeless player. **/
	private var player:Object;
	/** Wrapper of the chromeless player. **/
	private var wrapper:Object;
	/** Save if we're actually playing. **/
	private var playing:Boolean;


	/** Setup Livestream application loader. **/
	public function LivestreamModel(mod:Model):void {
		super(mod);
		mouseEnabled = true;
		Security.allowDomain('*');
		loader = new Loader();
		loader.contentLoaderInfo.addEventListener(Event.COMPLETE,loaderHandler);
		loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR,errorHandler);
		addChild(loader);
	};

	/** Livestream application loaded. **/
	private function applicationHandler(evt:Event):void {
		wrapper = Object(loader.content).application;
		wrapper.addEventListener("ready", playerReadyHandler);
	};


	/** Catch load errors. **/
	private function errorHandler(evt:ErrorEvent):void {
		stop();
		model.sendEvent(ModelEvent.ERROR,{message:evt.text});
	};


	/** Load the Livestream channel. **/
	override public function load(itm:Object):void {
		item = itm;
		position = item['start'];
		model.sendEvent(ModelEvent.STATE,{newstate:ModelStates.BUFFERING});
		if(player) {
			play();
		} else {
			Security.loadPolicyFile("http://cdn.livestream.com/crossdomain.xml");
			try {
				loader.load(new URLRequest(LOCATION),new LoaderContext(true,
					ApplicationDomain.currentDomain,SecurityDomain.currentDomain));
			} catch (e:SecurityError) {
				loader.load(new URLRequest(LOCATION));
			}
		}
	};


	/** Livestream player SWF loaded. **/
	private function loaderHandler(evt:Event):void {
		loader.content.addEventListener('applicationComplete',applicationHandler);
	};


	/** Pause the livestream. **/
	override public function pause():void {
		stop();
	};


	/** Play the livestream. **/
	override public function play():void {
		player.channel = item['file'];
		player.play();
		playing = true;
		model.sendEvent(ModelEvent.STATE,{newstate:ModelStates.PLAYING});
	};


	/** Chromeless player has succesfully loaded. **/
	private function playerReadyHandler(evt:Event):void {
		player = wrapper.getPlayer();
		player.addEventListener("errorEvent", playerErrorHandler);
		player.devKey = model.config['livestream.devkey'];
		player.showMuteButton = false;
		player.showPauseButton = false;
		player.showPlayButton = false;
		player.showSpinner = false;
		player.volumeOverlayEnabled = true;
		model.config['mute'] == true ? volume(0): volume(model.config['volume']);
		resize();
		play();
	};


	/** Chromeless player failed loading. **/
	private function playerErrorHandler(evt:Event):void {
		stop();
		model.sendEvent(ModelEvent.ERROR,{message:Object(evt).message});
	};


	/** Handle a resize of the livestream. **/
	override public function resize():void {
		if(wrapper) {
			Stretcher.stretch(DisplayObject(wrapper),model.config['width'],model.config['height'],Stretcher.EXACTFIT);
		}
	};


	/** Destroy the youtube video. **/
	override public function stop():void {
		if(playing) {
			player.stop();
			playing = false;
		}
		position = item['start'];
		model.sendEvent(ModelEvent.STATE,{newstate:ModelStates.IDLE});
	};


	/** Set the volume level. **/
	override public function volume(pct:Number):void {
		if(player) {
			player.volume = pct/100;
		}
	};


}


}