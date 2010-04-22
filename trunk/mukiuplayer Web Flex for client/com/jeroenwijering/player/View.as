/**
* Wrap all views and plugins and provides them with MVC access pointers.
**/
package com.jeroenwijering.player {


import com.jeroenwijering.events.*;
import com.jeroenwijering.utils.*;

import flash.display.*;
import flash.events.*;
import flash.external.ExternalInterface;
import flash.system.*;
import flash.ui.ContextMenu;
import flash.utils.setTimeout;


public class View extends AbstractView {


	/** Object with all configuration parameters **/
	private var _config:Object;
	/** Reference to all stage graphics. **/
	private var _skin:MovieClip;
	/** Object that load the skin and plugins. **/
	private var sploader:SPLoader;
	/** Controller of the MVC cycle. **/
	private var controller:Controller;
	/** Model of the MVC cycle. **/
	private var model:Model;
	/** Reference to the contextmenu. **/
	private var context:ContextMenu;
	/** A list with all javascript listeners. **/
	private var listeners:Array;
	/** Player is ready **/
	private var ready:Boolean;


	/** Constructor, save references and subscribe to events. **/
	public function View(cfg:Object,skn:MovieClip,ldr:SPLoader,ctr:Controller,mdl:Model):void {
		Security.allowDomain("*");
		_config = cfg;
		_config['client'] = 'FLASH '+Capabilities.version;
		_skin = skn;
		_skin.stage.scaleMode = "noScale";
		_skin.stage.align = "TL";
		//_skin.stage.addEventListener(Event.RESIZE,resizeHandler);
		_skin.stage.addEventListener(FullScreenEvent.FULL_SCREEN,resizeHandler);
		sploader = ldr;
		controller = ctr;
		model = mdl;
		setListening();
		listeners = new Array();
	};


	/**  Getters for the config parameters, skinning parameters and playlist. **/
	override public function get config():Object { return _config; };
	override public function get playlist():Array { return controller.playlist; };
	override public function get skin():MovieClip { return _skin; };


	/**  Subscribers to the controller, model and view. **/
	override public function addControllerListener(typ:String,fcn:Function):void {
		controller.addEventListener(typ.toUpperCase(),fcn);
	};
	private function addJSControllerListener(typ:String,fcn:String):Boolean {
		listeners.push({target:'CONTROLLER',type:typ.toUpperCase(),callee:fcn});
		return true;
	};
	override public function addModelListener(typ:String,fcn:Function):void {
		model.addEventListener(typ.toUpperCase(),fcn);
	};
	private function addJSModelListener(typ:String,fcn:String):Boolean {
		listeners.push({target:'MODEL',type:typ.toUpperCase(),callee:fcn});
		return true;
	};
	override public function addViewListener(typ:String,fcn:Function):void {
		this.addEventListener(typ.toUpperCase(),fcn);
	};
	private function addJSViewListener(typ:String,fcn:String):Boolean {
		listeners.push({target:'VIEW',type:typ.toUpperCase(),callee:fcn});
		return true;
	};


	/** Send event to listeners and tracers. **/
	private function forward(tgt:String,typ:String,dat:Object):void {
		var prm:String = '';
		for (var i:String in dat) { prm += i+':'+dat[i]+','; }
		if(prm.length > 0) {
			prm = '('+prm.substr(0,prm.length-1)+')';
		}
		if(!dat) { dat = new Object(); }
	 	dat.id = config['id'];
		dat.client = config['client'];
		dat.version = config['version'];
		for (var itm:String in listeners) {
			if(listeners[itm]['target'] == tgt && listeners[itm]['type'] == typ) {
				ExternalInterface.call(listeners[itm]['callee'],dat);
			}
		}
	};


	/** Javascript getters for the config, pluginconfig and playlist. **/
	private function getConfig():Object {
		var cfg:Object = new Object();
		for(var s:String in _config) {
			if(s.indexOf('.') == -1 && _config[s] != undefined) {
				cfg[s] = _config[s];
			}
		}
		return cfg;
	};


	/** Return the current playlist. **/
	private function getPlaylist():Array {
		var arr:Array = new Array();
		var cfg:Object = new Object();
		if(controller.playlist) {
			for(var i:Number=0; i<controller.playlist.length; i++) {
				cfg = new Object();
				for(var s:String in controller.playlist[i]) {
					if(s.indexOf('.') == -1) {
						cfg[s] = controller.playlist[i][s];
					}
				}
				arr.push(cfg);
			}
		}
		return arr;
	};


	/** Return the config object of a specific plugin. **/
	override public function getPluginConfig(nam:Object):Object {
		return sploader.getPluginConfig(nam);
	};


	/** Return the config object of a specific plugin. **/
	public function getJSPluginConfig(nam:String):Object {
		try {
			var plg:Object = getPlugin(nam);
			var cfg:Object = getPluginConfig(plg);
		} catch (err:Error) {
			return {error:'plugin not loaded'}
		}
		var obj:Object = new Object();
		for(var s:String in cfg) {
			if(cfg[s] is String || cfg[s] is Boolean || cfg[s] is Number) {
				obj[s] = cfg[s];
			}
		}
		return obj;
	};




	/** Get a reference to a specific plugin. **/
	override public function getPlugin(nam:String):Object {
		return sploader.getPlugin(nam);
	};


	/** Load a plugin into the player at runtime. **/
	override public function loadPlugin(url:String,vrs:String=null):Boolean {
		sploader.loadPlugin(url,vrs);
		return true;
	};


	/** Send a ready ping to javascript. **/
	public function playerReady():void {
		if(ExternalInterface.available && _skin.loaderInfo.url.indexOf('http') == 0 && ready != true) {
			ready = true;
			setTimeout(playerReadyPing,50);
		}
	};


	/** The timeout on this ping is needed for IE - it'll not get the playerReady call. **/
	private function playerReadyPing():void {
		try {
			if(ExternalInterface.objectID && !_config['id']) {
				_config['id'] = ExternalInterface.objectID;
			}
			if(_config['id']) {
				ExternalInterface.addCallback("addControllerListener",addJSControllerListener);
				ExternalInterface.addCallback("addModelListener",addJSModelListener);
				ExternalInterface.addCallback("addViewListener",addJSViewListener);
				ExternalInterface.addCallback("removeControllerListener",removeJSControllerListener);
				ExternalInterface.addCallback("removeModelListener",removeJSModelListener);
				ExternalInterface.addCallback("removeViewListener",removeJSViewListener);
				ExternalInterface.addCallback("getConfig",getConfig);
				ExternalInterface.addCallback("getPlaylist",getPlaylist);
				ExternalInterface.addCallback("getPluginConfig",getJSPluginConfig);
				ExternalInterface.addCallback("loadPlugin",loadPlugin);
				ExternalInterface.addCallback("sendEvent",sendEvent);
				ExternalInterface.call("playerReady",{
					id:config['id'],
					client:config['client'],
					version:config['version']
				});
			}
		} catch (err:Error) {}
	}


	/**  Unsubscribers to the controller, model and view. **/
	override public function removeControllerListener(typ:String,fcn:Function):void {
		controller.removeEventListener(typ.toUpperCase(),fcn);
	};
	private function removeJSControllerListener(typ:String,fcn:String):Boolean {
		removeJSListener('CONTROLLER',typ.toUpperCase(),fcn);
		return true;
	};
	override public function removeModelListener(typ:String,fcn:Function):void {
		model.removeEventListener(typ.toUpperCase(),fcn);
	};
	private function removeJSModelListener(typ:String,fcn:String):Boolean {
		removeJSListener('MODEL',typ.toUpperCase(),fcn);
		return true;
	};
	override public function removeViewListener(typ:String,fcn:Function):void {
		this.removeEventListener(typ.toUpperCase(),fcn);
	};
	private function removeJSViewListener(typ:String,fcn:String):Boolean {
		removeJSListener('VIEW',typ.toUpperCase(),fcn);
		return true;
	};
	private function removeJSListener(tgt:String,typ:String,fcn:String):void { 
		for(var i:Number=0; i<listeners.length; i++) {
			if(listeners[i]['target'] == tgt && listeners[i]['type'] == typ && listeners[i]['callee'] == fcn) {
				listeners.splice(i,1);
				return;
			}
		}
	};


	/** Send a redraw request when the stage is resized. **/
	private function resizeHandler(evt:Event = undefined):void {
		//trace("resizeHandler : ");
		dispatchEvent(new ViewEvent(ViewEvent.REDRAW));
	};


	/**  Dispatch events. **/
	override public function sendEvent(typ:String,prm:Object=undefined):void {
		typ = typ.toUpperCase();
		var dat:Object = new Object();
		switch(typ) {
			case 'ITEM':
				dat['index'] = prm;
				break;
			case 'LINK':
				dat['index'] = prm;
				break;
			case 'LOAD':
				dat['object'] = prm;
				break;
			case 'SEEK':
				dat['position'] = prm;
				trace("Seek dat['position'] : " + dat['position']);
				break;
			case 'VOLUME':
				dat['percentage'] = prm;
				break;
			default:
				if(prm == true || prm == 'true') {
					dat['state'] = true;
				} else if(prm === false || prm == 'false') {
					dat['state'] = false;
				}
				break;
		}
		Logger.log(prm,typ);
		dispatchEvent(new ViewEvent(typ,dat));
	};


	/** Forward events to tracer and subscribers. **/
	private function setController(evt:ControllerEvent):void { forward('CONTROLLER',evt.type,evt.data); };
	private function setModel(evt:ModelEvent):void { forward('MODEL',evt.type,evt.data); };
	private function setView(evt:ViewEvent):void { forward('VIEW',evt.type,evt.data); };


	/** Setup listeners to all events for tracing / javascript. **/
	private function setListening():void {
		addControllerListener(ControllerEvent.ERROR,setController);
		addControllerListener(ControllerEvent.ITEM,setController);
		addControllerListener(ControllerEvent.MUTE,setController);
		addControllerListener(ControllerEvent.PLAY,setController);
		addControllerListener(ControllerEvent.PLAYLIST,setController);
		addControllerListener(ControllerEvent.RESIZE,setController);
		addControllerListener(ControllerEvent.SEEK,setController);
		addControllerListener(ControllerEvent.STOP,setController);
		addControllerListener(ControllerEvent.VOLUME,setController);
		addModelListener(ModelEvent.BUFFER,setModel);
		addModelListener(ModelEvent.ERROR,setModel);
		addModelListener(ModelEvent.LOADED,setModel);
		addModelListener(ModelEvent.META,setModel);
		addModelListener(ModelEvent.STATE,setModel);
		addModelListener(ModelEvent.TIME,setModel);
		addViewListener(ViewEvent.FULLSCREEN,setView);
		addViewListener(ViewEvent.ITEM,setView);
		addViewListener(ViewEvent.LINK,setView);
		addViewListener(ViewEvent.LOAD,setView);
		addViewListener(ViewEvent.MUTE,setView);
		addViewListener(ViewEvent.NEXT,setView);
		addViewListener(ViewEvent.PLAY,setView);
		addViewListener(ViewEvent.PREV,setView);
		addViewListener(ViewEvent.REDRAW,setView);
		addViewListener(ViewEvent.SEEK,setView);
		addViewListener(ViewEvent.STOP,setView);
		addViewListener(ViewEvent.TRACE,setView);
		addViewListener(ViewEvent.VOLUME,setView);
	};


}


}