/**
* Wraps all media APIs (all models) and manages thumbnail display.
**/
package com.jeroenwijering.player {


import com.jeroenwijering.events.*;
import com.jeroenwijering.models.AbstractModel;
import com.jeroenwijering.player.*;
import com.jeroenwijering.utils.*;

import flash.display.*;
import flash.events.*;
import flash.net.URLRequest;
import flash.system.LoaderContext;

import org.lala.models.*;


public class Model extends EventDispatcher {


	/** Object with all configuration variables. **/
	public var config:Object;
	/** Reference to the media element. **/
	public var media:Sprite;
	/** Reference to the player's controller. **/
	private var controller:Controller;
	/** The list with all active models. **/
	private var models:Object;
	/** Loader for the preview image. **/
	private var thumb:Loader;
	/** Save the currently playing playlist item. **/
	private var item:Object;
	/** Save the current image url to prevent duplicate loading. **/
	private var image:String;


	/** Constructor, save references, setup listeners and  init thumbloader. **/
	public function Model(cfg:Object,skn:MovieClip,ldr:SPLoader,ctr:Controller):void {
		config = cfg;
		controller = ctr;
		controller.addEventListener(ControllerEvent.ITEM,itemHandler);
		controller.addEventListener(ControllerEvent.MUTE,muteHandler);
		controller.addEventListener(ControllerEvent.PLAY,playHandler);
		controller.addEventListener(ControllerEvent.PLAYLIST,playlistHandler);
		controller.addEventListener(ControllerEvent.RESIZE,resizeHandler);
		controller.addEventListener(ControllerEvent.SEEK,seekHandler);
		controller.addEventListener(ControllerEvent.STOP,stopHandler);
		controller.addEventListener(ControllerEvent.VOLUME,volumeHandler);
		models = new Object();
		thumb = new Loader();
		thumb.contentLoaderInfo.addEventListener(Event.COMPLETE,thumbHandler);
		thumb.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR,thumbHandler);
		var dpl:MovieClip = skn.getChildByName('display') as MovieClip;
		media = dpl.media as Sprite;
		media.visible = false;
		Draw.clear(media);
		dpl.addChildAt(thumb,dpl.getChildIndex(media));
	};


	/** Load a new playback model. **/
	public function addModel(mdl:AbstractModel,typ:String):void {
		models[typ] = mdl;
	};

	/** Check if the currently playing item is audio only. **/
	private function audioOnly():Boolean {
		var ext:String = item['file'].substr(-3);
		if(ext == 'm4a' || ext == 'mp3' || ext == 'aac') {
			return true;
		} else {
			return false;
		}
	};


	/** Item change: stop the old model and start the new one. **/
	private function itemHandler(evt:ControllerEvent):void {
		if(item) {
			models[item['type']].stop();
			media.removeChild(models[item['type']]);
		}
		item = controller.playlist[config['item']];
		if(models[item['type']]) {
			media.addChild(models[item['type']]);
			models[item['type']].load(item);
		} else {
			sendEvent(ModelEvent.ERROR,{message:'No suiteable model found for playback of this file.'});
		}
		if(item['image']) {
			if(item['image'] != image) {
				image = item['image'];
				thumb.load(new URLRequest(item['image']),new LoaderContext(true));
			}
		} else if(image) {
			image = undefined;
			thumb.unload();
		}
	};


	/** Make the current model toggle its mute state. **/
	private function muteHandler(evt:ControllerEvent):void {
		if(item) {
			if(evt.data.state == true) {
				models[item['type']].volume(0);
			} else {
				models[item['type']].volume(config['volume']);
			}
		}
	};


	/** Make the current model play or pause. **/
	private function playHandler(evt:ControllerEvent):void {
		if(item) {
			if(evt.data.state == true) {
				models[item['type']].play();
			} else {
				models[item['type']].pause();
			}
		}
	};


	/** Load a thumb; either from the playlist or (if there) player-wide.  **/
	private function playlistHandler(evt:ControllerEvent):void {
		var img:String = controller.playlist[config['item']]['image'];
		if(img && img != image) {
			image = img;
			thumb.load(new URLRequest(img),new LoaderContext(true));
		}
	};


	/** Resize the media and thumb. **/
	private function resizeHandler(evt:ControllerEvent):void {
		if(thumb.width) { thumbResize(); };
		if(item) { models[item['type']].resize(); }
	};


	/** Make the current model seek. **/
	private function seekHandler(evt:ControllerEvent):void {
		if(item) {
			models[item['type']].seek(evt.data.position);
		}
	};


	/** Make the current model stop and show the thumb. **/
	private function stopHandler(evt:ControllerEvent=undefined):void {
		if(item) {
			models[item['type']].stop();
		}
	};


	/**
	* Dispatch events to the View/ Controller.
	* When switching states, the thumbnail is shown/hidden.
	* 
	* @param typ	The eventtype to dispatch.
	* @param dat	An object with data to send along.
	* @see 			ModelEvent
	**/
	public function sendEvent(typ:String,dat:Object):void {
		if(typ == ModelEvent.STATE) {
			if(dat.newstate == config['state']) { return; }
			dat['oldstate'] = config['state'];
			config['state'] = dat.newstate;
			switch(dat['newstate']) {
				case ModelStates.IDLE:
					sendEvent(ModelEvent.LOADED,{loaded:0,offset:0,total:0});
				case ModelStates.COMPLETED:
					thumb.visible = true;
					media.visible = false;
					sendEvent(ModelEvent.TIME,{position:item['start'],duration:item['duration']});
					break;
				case ModelStates.BUFFERING:
				case ModelStates.PLAYING:
					thumb.visible = audioOnly();
					media.visible = !audioOnly();
					break;
			}
		}
		Logger.log(dat,typ);
		dispatchEvent(new ModelEvent(typ,dat));
	};


	/** Thumb loaded, try to antialias it before resizing. **/
	private function thumbHandler(evt:Event):void {
		try {
			Bitmap(thumb.content).smoothing = true;
		} catch (err:Error) {}
		thumbResize();
	};


	/** Resize the thumbnail. **/
	private function thumbResize():void {
		Stretcher.stretch(thumb,config['width'],config['height'],config['stretching']);
	};


	/** Make the current model change volume. **/
	private function volumeHandler(evt:ControllerEvent):void {
		if(item) {
			models[item['type']].volume(evt.data.percentage);
		}
	};


}


}