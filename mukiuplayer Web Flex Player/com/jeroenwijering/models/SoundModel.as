/**
* Wrapper for playback of mp3 sounds.
**/
package com.jeroenwijering.models {


import com.jeroenwijering.events.*;
import com.jeroenwijering.models.AbstractModel;
import com.jeroenwijering.player.Model;

import flash.events.*;
import flash.media.*;
import flash.net.URLRequest;
import flash.utils.*;


public class SoundModel extends AbstractModel {


	/** sound object to be instantiated. **/
	private var sound:Sound;
	/** Sound control object. **/
	private var transformer:SoundTransform;
	/** Sound channel object. **/
	private var channel:SoundChannel;
	/** Sound context object. **/
	private var context:SoundLoaderContext;
	/** ID for the position interval. **/
	protected var interval:Number;
	/** Interval for loading progress. **/
	private var loadinterval:Number;


	/** Constructor; sets up the connection and display. **/
	public function SoundModel(mod:Model):void {
		super(mod);
		transformer = new SoundTransform();
		context = new SoundLoaderContext(model.config['bufferlength']*1000,true);
	};


	/** Sound completed; send event. **/
	private function completeHandler(evt:Event):void {
		clearInterval(interval);
		model.sendEvent(ModelEvent.STATE,{newstate:ModelStates.COMPLETED});
	};


	/** Catch errors. **/
	private function errorHandler(evt:ErrorEvent):void {
		stop();
		model.sendEvent(ModelEvent.ERROR,{message:evt.text});
	};


	/** Forward ID3 data from the sound. **/
	private function id3Handler(evt:Event):void {
		try {
			var id3:ID3Info = sound.id3;
			var obj:Object = {
				type:'id3',
				album:id3.album,
				artist:id3.artist,
				comment:id3.comment,
				genre:id3.genre,
				name:id3.songName,
				track:id3.track,
				year:id3.year
			}
			model.sendEvent(ModelEvent.META,obj);
		} catch (err:Error) {}
	};


	/** Load the sound. **/
	override public function load(itm:Object):void {
		item = itm;
		position = 0;
		sound = new Sound();
		sound.addEventListener(IOErrorEvent.IO_ERROR,errorHandler);
		sound.addEventListener(Event.ID3,id3Handler);
		sound.load(new URLRequest(item['file']),context);
		play();
		if(item['start'] > 0) {
			seek(item['start']);
		}
		loadinterval = setInterval(loadHandler,200);
		model.config['mute'] == true ? volume(0): volume(model.config['volume']);
		model.sendEvent(ModelEvent.STATE,{newstate:ModelStates.BUFFERING});
	};


	/** Interval for the loading progress **/
	private function loadHandler():void {
		var ldd:Number = sound.bytesLoaded;
		var ttl:Number = sound.bytesTotal;
		model.sendEvent(ModelEvent.LOADED,{loaded:ldd,total:ttl});
		if(ldd/ttl > 0.1 && item['duration'] == 0) {
			item['duration'] =  sound.length/1000/ldd*ttl;
		}
		if(ldd == ttl && ldd > 0) {
			clearInterval(loadinterval);
		}
	};


	/** Pause the sound. **/
	override public function pause():void {
		channel.stop();
		clearInterval(interval);
		model.sendEvent(ModelEvent.STATE,{newstate:ModelStates.PAUSED});
	};


	/** Play the sound. **/
	override public function play():void {
		channel = sound.play(position*1000,0,transformer);
		channel.addEventListener(Event.SOUND_COMPLETE,completeHandler);
		interval = setInterval(positionInterval,100);
	};


	/** Interval for the position progress **/
	protected function positionInterval():void {
		position = Math.round(channel.position/100)/10;
		if (model.config['state'] != ModelStates.PLAYING && channel.position > 0) {
			model.sendEvent(ModelEvent.STATE,{newstate:ModelStates.PLAYING});
		}
		if(position < item['duration']) {
			model.sendEvent(ModelEvent.TIME,{position:position,duration:item['duration']});
		} else if (item['duration'] > 0) {
			pause();
			model.sendEvent(ModelEvent.STATE,{newstate:ModelStates.COMPLETED});
		}
	};


	/** Seek in the sound. **/
	override public function seek(pos:Number):void {
		position = pos;
		clearInterval(interval);
		channel.stop();
		play();
	};


	/** Destroy the sound. **/
	override public function stop():void {
		clearInterval(loadinterval);
		clearInterval(interval);
		if(channel) { channel.stop(); }
		try { sound.close(); } catch (err:Error) {}
		position = 0;
		model.sendEvent(ModelEvent.STATE,{newstate:ModelStates.IDLE});
	};


	/** Set the volume level. **/
	override public function volume(vol:Number):void {
		transformer.volume = vol/100;
		if(channel) {
			channel.soundTransform = transformer;
		}
	};


};


}