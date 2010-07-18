/**
* Process all input from the views and modifies the model.
**/
package com.jeroenwijering.player {


import com.jeroenwijering.events.*;
import com.jeroenwijering.parsers.*;
import com.jeroenwijering.utils.*;

import flash.display.MovieClip;
import flash.events.*;
import flash.geom.*;
import flash.net.*;
import flash.system.Capabilities;


public class Controller extends EventDispatcher {


	/** Configuration object **/
	private var config:Object;
	/** Reference to the skin (for stage access). **/
	private var skin:MovieClip;
	/** Reference to the SPLoader (for layouting plugins). **/
	private var sploader:SPLoader;
	/** Playlist of the player. **/
	public var playlist:Array;
	/** Reference to the player's model. **/
	private var model:Model;
	/** Reference to the player's view. **/
	private var view:View;
	/** Object that manages loading of XML playlists. **/
	private var loader:URLLoader;
	/** object that provides randomization. **/
	private var randomizer:Randomizer;
	/** File extensions of all supported mediatypes. **/
	
	//private var bfullscr:Boolean = false;
	private var EXTENSIONS:Object = {
		'3g2':'video',
		'3gp':'video',
		'aac':'video',
		'f4b':'video',
		'f4p':'video',
		'f4v':'video',
		'flv':'video',
		'gif':'image',
		'jpg':'image',
		'm4a':'video',
		'm4v':'video',
		'mov':'video',
		'mp3':'sound',
		'mp4':'video',
		'png':'image',
		'rbs':'sound',
		'sdp':'video',
		'swf':'image',
		'vp6':'video'
	};
	/** Elements of config that are part of the playlist. **/
	private var ELEMENTS:Object = {
		author:undefined,
		date:undefined,
		description:undefined,
		duration:0,
		file:undefined,
		image:undefined,
		link:undefined,
		start:0,
		streamer:undefined,
		tags:undefined,
		title:undefined,
		type:undefined,
		vid:undefined,//add,
		cid:undefined,
		cfile:undefined,
		bnico:undefined
		//isyouku:undefined
	};
	/** A list with legacy CDN classes that are now redirected to buit-in ones. **/
	private var REDIRECTS:Object = {
		bitgravity:{flashvar:'startparam',model:'http',value:'starttime'},
		edgecast:{flashvar:'startparam',model:'http',value:'ec_seek'},
		fcsubscribe:{flashvar:'subscribe',model:'rtmp',value:true},
		flvseek:{flashvar:'startparam',model:'http',value:'fs'},
		highwinds:{flashvar:'loadbalance',model:'rtmp',value:true},
		lighttpd:{flashvar:'startparam',model:'http',value:'start'},
		vdox:{flashvar:'loadbalance',model:'rtmp',value:true}
	};


	/** Constructor, set up stage and playlist listeners. **/
	public function Controller(cfg:Object,skn:MovieClip,ldr:SPLoader):void {
		config = cfg;
		skin = skn;
		sploader = ldr;
		loader = new URLLoader();
		loader.addEventListener(Event.COMPLETE,loaderHandler);
		loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR,errorHandler);
		loader.addEventListener(IOErrorEvent.IO_ERROR,errorHandler);
	};


	/** Register view and model with controller, start loading playlist. **/
	public function closeMVC(mdl:Model,vie:View):void {
		model= mdl;
		model.addEventListener(ModelEvent.STATE,stateHandler);
		view = vie;
		view.addEventListener(ViewEvent.FULLSCREEN,fullscreenHandler);
		view.addEventListener(ViewEvent.ITEM,itemHandler);
		view.addEventListener(ViewEvent.LINK,linkHandler);
		view.addEventListener(ViewEvent.LOAD,loadHandler);
		view.addEventListener(ViewEvent.MUTE,muteHandler);
		view.addEventListener(ViewEvent.NEXT,nextHandler);
		view.addEventListener(ViewEvent.PLAY,playHandler);
		view.addEventListener(ViewEvent.PREV,prevHandler);
		view.addEventListener(ViewEvent.REDRAW,redrawHandler);
		view.addEventListener(ViewEvent.SEEK,seekHandler);
		view.addEventListener(ViewEvent.STOP,stopHandler);
		view.addEventListener(ViewEvent.VOLUME,volumeHandler);
	};


	/** Catch errors dispatched by the playlister. **/
	private function errorHandler(evt:ErrorEvent):void {
		sendEvent(ControllerEvent.ERROR,{message:evt.text});
	};


	/** Switch fullscreen state. **/
	private function fullscreenHandler(evt:ViewEvent):void {
		if (skin.stage['displayState'] == 'fullScreen') {
			//bfullscr = false;
			skin.stage['displayState'] = 'normal';
		} else {
			try { fullscreenrect(); } catch (err:Error) { }
			//bfullscr = true;	
			skin.stage['displayState'] = 'fullScreen';
		}
	};


	/** Set the fullscreen rectangle **/
	private function fullscreenrect():void {
		var pnt:Point = skin.parent.localToGlobal(new Point(skin.x,skin.y));
		skin.stage["fullScreenSourceRect"] = new Rectangle(
			pnt.x,
			pnt.y,
			Capabilities.screenResolutionX,
			Capabilities.screenResolutionY
		);
	};


	/** Return the type of specific playlistitem (the Model to play it with) **/
	private function getModelType(itm:Object,sub:Boolean):String {
		if(!itm['file']) {
			return null;
		} else if(REDIRECTS[itm['type']]) {
			var typ:Object = REDIRECTS[itm['type']];
			config[typ['model']+'.'+typ['flashvar']] = typ['value'];
			return typ['model'];
		} else if(itm['type']) {
			return itm['type'];
		} else if (itm['streamer'] && sub) {
			if(itm['streamer'].substr(0,4) == 'rtmp') {
				return 'rtmp';
			} else if(itm['streamer'].indexOf('/') != -1) {
				return 'http';
			} else {
				return itm['streamer'];
			}
		// this is a small hack to enable youtube links to work by default.
		} else if(itm['vid']) {//hack for SINAModel
//			trace('sina');
			return 'sina';
		} else if(itm['file'].indexOf('youtube.com/w') > -1 || itm['file'].indexOf('youtube.com/v') > -1) {
			return 'youtube';
		} else if(itm['file'].indexOf('livestream.com/') > -1 ) {
			return 'livestream';
		} else { 
			 return EXTENSIONS[itm['file'].substr(-3).toLowerCase()];
		}
	};


	/** Jump to a userdefined item in the playlist. **/
	private function itemHandler(evt:ViewEvent):void {
		var itm:Number = evt.data.index;
		if(playlist && playlist[itm]) {
			if (itm < 0) {
				playItem(0);
			} else if (itm > playlist.length-1) {
				playItem(playlist.length-1);
			} else if (!isNaN(itm)) {
				playItem(itm);
			}
		}
	};


	/** Jump to the link of a playlistitem. **/
	private function linkHandler(evt:ViewEvent=null):void {
		var itm:Number = config['item'];
		if(evt && evt.data.index) { itm = evt.data.index; }
		var lnk:String = playlist[itm]['link'];
		if(lnk != null) {
			navigateToURL(new URLRequest(lnk),config['linktarget']);
		}
		playHandler(new ViewEvent(ViewEvent.PLAY,{state:false}));
	};


	/** Load a new playlist. **/
	private function loadHandler(evt:ViewEvent):void {
		if(config['state'] != 'IDLE') {
			stopHandler();
		}
		var obj:Object = new Object();
		if(typeof(evt.data.object) == 'array') {
			playlistHandler(evt.data.object);
		} else if(typeof(evt.data.object) == 'string') {
			obj['file'] = evt.data.object;
		} else if (evt.data.object['file']) {
			for(var itm:String in ELEMENTS) {
				if(evt.data.object[itm]) {
					obj[itm] = Strings.serialize(evt.data.object[itm]);
				}
			}
		}
		if(obj['file']) {
			if(getModelType(obj,false) == null) {
				loader.load(new URLRequest(obj['file']));
				return;
			} else {
				playlistHandler(new Array(obj));
			}
		} else {
			var arr:Array = new Array();
			for each (var ent:Object in evt.data.object) {
				arr.push(ent);
			}
			playlistHandler(arr);
		}
	};


	/** Translate the XML object to the feed array. **/
	private function loaderHandler(evt:Event):void {
		try {
			var dat:XML = XML(evt.target.data);
			var fmt:String = dat.localName().toLowerCase();
		} catch (err:Error) {
			sendEvent(ControllerEvent.ERROR,{message:'This playlist is not a valid XML file.'});
			return;
		}
		switch (fmt) {
			case 'rss':
				playlistHandler(RSSParser.parse(dat));
				break;
			case 'playlist':
				playlistHandler(XSPFParser.parse(dat));
				break;
			case 'asx':
				playlistHandler(ASXParser.parse(dat));
				break;
			case 'smil':
				playlistHandler(SMILParser.parse(dat));
				break;
			case 'feed':
				playlistHandler(ATOMParser.parse(dat));
				break;
			default:
				sendEvent(ControllerEvent.ERROR,{message:'Unknown playlist format: '+fmt});
				return;
		}
	};


	/** Save new state of the mute switch and send volume. **/
	private function muteHandler(evt:ViewEvent):void {
		if(evt.data.state == true || evt.data.state == false) {
			if(evt.data.state == config['mute']) {
				return;
			} else {
				config['mute'] = evt.data.state;
			}
		} else {
			config['mute'] = !config['mute'];
		}
		Configger.saveCookie('mute',config['mute']);
		sendEvent(ControllerEvent.MUTE,{state:config['mute']});
	};


	/** Jump to the next item in the playlist. **/
	private function nextHandler(evt:ViewEvent=null):void {
		if(playlist && config['shuffle'] == true) {
			playItem(randomizer.pick());
		} else if (playlist && config['item'] == playlist.length-1) {
			playItem(0);
		} else if (playlist) { 
			playItem(config['item']+1);
		}
	};


	/** Change the playback state. **/
	private function playHandler(evt:ViewEvent):void {
		if(playlist) {
			if(evt.data.state != false && config['state'] == ModelStates.PAUSED) {
				sendEvent(ControllerEvent.PLAY,{state:true});
			} else if (evt.data.state != false && config['state'] == ModelStates.COMPLETED) {
				sendEvent(ControllerEvent.SEEK,{position:playlist[config['item']]['start']});
			} else if(evt.data.state != false && config['state'] == ModelStates.IDLE) {
				playItem();
			} else if (evt.data.state != true &&
				(config['state'] == ModelStates.PLAYING || config['state'] == ModelStates.BUFFERING)) {
				sendEvent(ControllerEvent.PLAY,{state:false});
			}
		}
	};


	/** Direct the model to play a new item. **/
	private function playItem(nbr:Number=undefined):void {
		if(!isNaN(nbr)) {
			config['item'] = nbr;
		}
		sendEvent(ControllerEvent.ITEM,{index:config['item']});
	};


	/** Check new playlist for playeable files and setup randomizing/autostart. **/
	private function playlistHandler(ply:Array):void {
		for(var i:Number = ply.length-1; i > -1; i--) {
			if(!ply[i]['duration'] || isNaN(ply[i]['duration'])) { ply[i]['duration'] = 0; }
			if(!ply[i]['start'] || isNaN(ply[i]['start'])) { ply[i]['start'] = 0; }
			if(!ply[i]['streamer'] && config['streamer']) {
				ply[i]['streamer'] = config['streamer'];
			}
			ply[i]['type'] = getModelType(ply[i],true);
			if(!ply[i]['type']) { ply.splice(i,1); }
		}
		if(ply.length > 0) {
			playlist = ply;
		} else {
			sendEvent(ControllerEvent.ERROR,{message:"No valid media file(s) found."});
			return;
		}
		if(config['shuffle'] == true) {
			randomizer = new Randomizer(playlist.length);
			config['item'] = randomizer.pick();
		} else if (config['item'] >= playlist.length) {
			config['item'] = playlist.length-1;
		}
		sendEvent(ControllerEvent.PLAYLIST,{playlist:playlist});
		if(config['autostart'] == true) {
			playItem();
		}
	};


	/** Jump to the previous item in the playlist. **/
	private function prevHandler(evt:ViewEvent):void {
		if (config['item'] == 0) {
			playItem(playlist.length-1);
		} else {
			playItem(config['item']-1);
		}
	};


	/** Manage a resizing of the stage. **/
	private function redrawHandler(evt:ViewEvent = null):void {
		//trace("redrawHandler : ");
		//trace("skin.stage['displayState'] : " + skin.stage['displayState']);
		try { 
			var dps:String = skin.stage['displayState'];
		} catch (err:Error) {}
		if(dps == 'fullScreen') {
			config['fullscreen'] = true;
			sploader.layoutFullscreen();
		} else {
			config['width'] = Player.WIDTH;// skin.stage.stageWidth - 412;
			config['height'] = Player.HEIGHT + 21;// 34;//31 is the height of controlbar //skin.stage.stageHeight - 27;
			config['fullscreen'] = false;
			sploader.layoutNormal();
		}
		sendEvent(ControllerEvent.RESIZE,{
			fullscreen:config['fullscreen'],width:config['width'],height:config['height']});
	};


	/** Seek to a specific part in a mediafile. **/
	private function seekHandler(evt:ViewEvent):void {
		if(config['state'] != ModelStates.IDLE && playlist[config['item']]['duration'] > 0) {
			var pos:Number = evt.data.position;
			if(pos < 1) { 
				pos = 0;
			} else if (pos > playlist[config['item']]['duration']-1) {
				pos = playlist[config['item']]['duration']-1;
			}
			sendEvent(ControllerEvent.SEEK,{position:pos});
		}
	};


	/** Log and dispatch events. **/
	private function sendEvent(typ:String,dat:Object=undefined):void {
		Logger.log(dat,typ);
		dispatchEvent(new ControllerEvent(typ,dat));
	};


	/** Stop all playback and buffering. **/
	private function stopHandler(evt:ViewEvent=undefined):void {
		sendEvent(ControllerEvent.STOP);
	};


	/** Manage playback state changes. **/
	private function stateHandler(evt:ModelEvent):void {
		if(evt.data.newstate == ModelStates.COMPLETED) {
			switch (config['repeat']) {
				case 'single':
					playHandler(new ViewEvent(ViewEvent.PLAY,{state:true}));
					break;
				case 'always':
					if(playlist.length == 1) {
						playHandler(new ViewEvent(ViewEvent.PLAY,{state:true}));
					} else { 
						nextHandler();
					}
					break;
				case 'list':
					if((config['shuffle'] == true && randomizer.length > 0) ||
						(config['shuffle'] == false && config['item'] < playlist.length-1)) {
						nextHandler();
					}
					break;
			}
		}
	};


	/** Save new state of the mute switch and send volume. **/
	private function volumeHandler(evt:ViewEvent):void {
		var vol:Number = evt.data.percentage;
		if (vol < 1) {
			muteHandler(new ViewEvent(ViewEvent.MUTE,{state:true}));
		} else if (!isNaN(vol) && vol < 101) {
			if(config['mute'] == true) { 
				muteHandler(new ViewEvent(ViewEvent.MUTE,{state:false}));
			}
			config['volume'] = vol;
			Configger.saveCookie('volume',config['volume']);
			sendEvent(ControllerEvent.VOLUME,{percentage:vol});
		}
	};


}


}