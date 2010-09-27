/**
* Loads external SWF skins and plugins.
**/


package com.jeroenwijering.player {


import com.jeroenwijering.events.SPLoaderEvent;
import com.jeroenwijering.player.Player;
import com.jeroenwijering.utils.Strings;

import flash.display.*;
import flash.events.*;
import flash.net.URLRequest;
import flash.system.*;


public class SPLoader extends EventDispatcher {


	/** Reference to the player config. **/
	private var config:Object;
	/** Reference to the skin. **/
	private var skin:MovieClip;
	/** Reference to the view. **/
	private var player:Player;
	/** SWF loader reference **/
	private var loader:Loader;
	/** Number of plugns that are done loading. **/
	private var done:Number = 0;
	/** List with all the plugins. **/
	private var plugins:Array;
	/** Base directory from which plugins are loaded. **/
	private var basedir:String = 'http://plugins.longtailvideo.com/';


	/** Constructor, references  **/
	public function SPLoader(ply:Player):void {
		config = ply.config;
		skin = ply.skin;
		player = ply;
		plugins = new Array();
	};


	/** Add a plugin to the list. **/
	public function addPlugin(pgi:Object,nam:String,ext:Boolean=false):void {
		var obj:Object = { reference:pgi,name:nam,x:0,y:0,width:400,height:300};
		// hack for the playlist/controlbar flashvars
		var cbr:DisplayObject = skin.getChildByName('controlbar');
		var dck:DisplayObject = skin.getChildByName('dock');
		if(nam == 'controlbar') {
			config['controlbar.position'] = config['controlbar'];
			config['controlbar.size'] = cbr.height;
			config['controlbar.margin'] = cbr.x;
		} else if (nam == 'playlist') {
			config['playlist.position'] = config['playlist'];
			config['playlist.size'] = config['playlistsize'];
		}
		else if (nam == 'commentlistsender')
		{
			config['commentlistsender.position'] = 'special';
		}
		else if (nam == 'commentview')
		{
			config['commentview.position'] = 'morespecial';
		}
		
		// load config for plugin
		try {
			for(var org:String in pgi.config) {
				obj[org] = pgi.config[org];
			}
		} catch (err:Error) {}
		for(var str:String in config) {
			if (str.indexOf(nam + ".") == 0) {
				obj[str.substring(nam.length + 1)] = config[str];
			}
		}
		//load skin for plugin
		var clp:DisplayObject;
		if(ext == true) { 
			clp = DisplayObject(pgi);
			skin.addChild(clp);
		} else if(skin.getChildByName(nam)) {
			clp = skin.getChildByName(nam);
		} else {
			clp = new MovieClip();
			clp.name = nam;
			if (nam == 'commentlistsender')
			{
				clp = pgi.clip;
				skin.stage.addChild(clp);
				//trace('commentlistsender added.');
			}
			else if (nam == 'commentview')
			{
				clp = pgi.clip;
				skin.addChild(clp);
				//trace('comment view added');
			}
			else
			{
				skin.addChildAt(clp, 1);
			}
		}
		// add plugin and initialize
		plugins.push(obj);
		try { 
			pgi.config = obj;
			pgi.clip = clp; 
			//trace(nam + ' ' + pgi.clip);
		} catch (err:Error) {}
		if(cbr) { skin.setChildIndex(cbr,skin.numChildren-1); }
		if(dck) { skin.setChildIndex(dck,skin.numChildren-1); }
		pgi.initializePlugin(player.view);
	};


	/** Get a reference to a specific plugin. **/
	public function getPlugin(nam:String):Object {
		for(var i:Number=0; i<plugins.length; i++) { 
			if(plugins[i]['name'] == nam) {
				return plugins[i]['reference'];
			}
		}
		return null;
	};


	/** Return the configuration data of a specific plugin. **/
	public function getPluginConfig(plg:Object):Object {
		for(var i:Number=0; i<plugins.length; i++) {
			if(plugins[i]['reference'] == plg) {
				return plugins[i];
			}
		}
		return null;
	};


	/** Load a single plugin into the stack (after initialization). **/
	public function loadPlugin(url:String,str:String=null):void {
		if(str != null && str != '') {
			var ar1:Array = str.split('&');
			for(var i:String in ar1) {
				var ar2:Array = ar1[i].split('=');
				config[ar2[0]] = Strings.serialize(ar2[1]); 
			}
		}
		loadSWF(url,false);
	};


	/** Start loading the SWF plugins, or broadcast if there's none. **/
	public function loadPlugins():void {
		if(config['plugins']) {
			var arr:Array = config['plugins'].split(',');
			done = arr.length;
			for(var i:Number=0; i<arr.length; i++) {
				loadSWF(arr[i],false);
			}
		} else {
			dispatchEvent(new SPLoaderEvent(SPLoaderEvent.PLUGINS));
		}
	};


	/** Start loading the skin, or broadcast if there's none. **/
	public function loadSkin():void {
		if(config['skin']) {
			loadSWF(config['skin'],true);
		} else {
			dispatchEvent(new SPLoaderEvent(SPLoaderEvent.SKIN));
		}
	};


	/** Load a particular SWF file. **/
	private function loadSWF(str:String,skn:Boolean):void {
		if(str.substr(-4) == '.swf') { str = str.substr(0, str.length-4); }
		var ldr:Loader = new Loader();
		if(skn) {
			ldr.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR,skinError);
			ldr.contentLoaderInfo.addEventListener(Event.COMPLETE,skinHandler);
		} else {
			ldr.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR,pluginError);
			ldr.contentLoaderInfo.addEventListener(SecurityErrorEvent.SECURITY_ERROR,pluginError);
			ldr.contentLoaderInfo.addEventListener(Event.COMPLETE,pluginHandler);
		}
		str += '.swf';
		if(skin.loaderInfo.url.indexOf('http') == 0) {
			var ctx:LoaderContext = new LoaderContext(true,ApplicationDomain.currentDomain,SecurityDomain.currentDomain);
			if(skn || str.indexOf('/') > -1) {
				ldr.load(new URLRequest(str),ctx);
			} else {
				ldr.load(new URLRequest(basedir+str),ctx);
			}
		} else {
			ldr.load(new URLRequest(str));
		}
	};


	/** Plugin loading failed. **/
	private function pluginError(evt:ErrorEvent):void {
		done--;
		if(done == 0) {
			dispatchEvent(new SPLoaderEvent(SPLoaderEvent.PLUGINS));
		}
	};


	/** Plugin loading completed; add to stage and populate. **/
	private function pluginHandler(evt:Event):void {
		try {
			var idx:Number = evt.target.url.lastIndexOf('/');
			var end:Number = evt.target.url.length-4;
			if(evt.target.url.indexOf('-',end-5) > -1) { 
				end = evt.target.url.indexOf('-',end-5);
			}
			var nam:String = evt.target.url.substring(idx+1,end).toLowerCase();
			addPlugin(evt.target.content,nam,true);
			evt.target.loader.visible = true;
		} catch(err:Error) {}
		done--;
		if(done == 0) {
			dispatchEvent(new SPLoaderEvent(SPLoaderEvent.PLUGINS));
		} else if (done <0) {
			player.view.sendEvent('REDRAW');
		}
	};


	/** Layout all plugins for a normal resize. **/
	public function layoutNormal():void {
		var bounds:Object = {x:0,y:0,width:config['width'],height:config['height']};
		var overs:Array = new Array();
		for(var i:Number = plugins.length-1; i>=0; i--) {
			switch(plugins[i]['position']) {
				case "left":
					plugins[i]['x'] = bounds.x;
					plugins[i]['y'] = bounds.y;
					plugins[i]['width'] = plugins[i]['size'];
					plugins[i]['height'] = bounds.height;
					plugins[i]['visible'] = true;
					bounds.x += plugins[i]['size'];
					bounds.width -= plugins[i]['size'];
					break;
				case "top":
					plugins[i]['x'] = bounds.x;
					plugins[i]['y'] = bounds.y;
					plugins[i]['width'] = bounds.width;
					plugins[i]['height'] = plugins[i]['size'];
					plugins[i]['visible'] = true;
					bounds.y += plugins[i]['size'];
					bounds.height -= plugins[i]['size'];
					break;
				case "right":
					plugins[i]['x'] = bounds.x + bounds.width - plugins[i]['size'];
					plugins[i]['y'] = bounds.y;
					plugins[i]['width'] = plugins[i]['size'];
					plugins[i]['height'] = bounds.height;
					plugins[i]['visible'] = true;
					bounds.width -= plugins[i]['size'];
					break;
				case "bottom":
					plugins[i]['x'] = bounds.x;
					plugins[i]['y'] = bounds.y+bounds.height-plugins[i]['size'];
					plugins[i]['width'] = bounds.width;
					plugins[i]['height'] = plugins[i]['size'];
					plugins[i]['visible'] = true;
					bounds.height -= plugins[i]['size'];
					break;
				case 'special':
					plugins[i]['x'] = 0;
					plugins[i]['y'] = 0;
					plugins[i]['width'] = skin.stage.stageWidth;
					plugins[i]['height'] = skin.stage.stageHeight;
					plugins[i]['visible'] = true;
					//trace('commentlistsender set layout');
					break;
				case 'morespecial':
					plugins[i]['x'] = 0;
					plugins[i]['y'] = 0;
					plugins[i]['width'] = Player.WIDTH;
					plugins[i]['height'] = Player.HEIGHT;
					plugins[i]['visible'] = true;
					//trace('commentview set layout');
					break;
				case "none":
					plugins[i]['visible'] = false;
					break;
				default:
					overs.push(i);
					break;
			}
		}
		for(var j:Number=0; j<overs.length; j++) {
			plugins[overs[j]]['x'] = bounds.x;
			plugins[overs[j]]['y'] = bounds.y;
			plugins[overs[j]]['width'] = bounds.width;
			plugins[overs[j]]['height'] = bounds.height;
			plugins[overs[j]]['visible'] = true;
		}
		config['width'] = bounds.width;
		config['height'] = bounds.height;
	};


	/** Layout all plugins in case of a fullscreen resize. **/
	public function layoutFullscreen():void {
		for(var i:Number=0; i<plugins.length; i++) {
			if (plugins[i]['position'] == 'over' || plugins[i]['position'] == undefined || 
				plugins[i]['position'] == 'morespecial' ||
				plugins[i]['name'] == 'controlbar' && plugins[i]['position'] != 'none') {
				plugins[i]['x'] = 0;
				plugins[i]['y'] = 0;
				plugins[i]['width'] = skin.stage.stageWidth;
				plugins[i]['height'] = skin.stage.stageHeight;
				plugins[i]['visible'] = true;
				if (plugins[i]['position'] == 'morespecial') {
					var rw:Number = skin.stage.stageWidth / Player.WIDTH;
					var rh:Number = skin.stage.stageHeight / Player.HEIGHT;
					var r:Number;
					if(rw < rh)
						r = rw;
					else 
						r = rh;
					plugins[i]['x'] = (skin.stage.stageWidth - Player.WIDTH * r) / 2;
				}
			} 
			else if (plugins[i]['position'] == 'special'){
				plugins[i]['visible'] = false;
				//trace('full screen hidden');
			}
			else {
				plugins[i]['visible'] = false;
			}
		}
		config['width'] = skin.stage.stageWidth;
		config['height'] = skin.stage.stageHeight;
	};


	/** Skin loading failed; use default skin. **/
	private function skinError(evt:IOErrorEvent=null):void {
		dispatchEvent(new SPLoaderEvent(SPLoaderEvent.SKIN));
	};


	/** Skin loading completed; add to stage and populate. **/
	private function skinHandler(evt:Event):void {
		try {
			var skn:MovieClip = evt.target.content['player'];
			while(skn.numChildren > 0) {
				var newchd:DisplayObject = skn.getChildAt(0);
				var chd:DisplayObject = skin.getChildByName(newchd.name);
				if(chd) {
					var idx:Number = skin.getChildIndex(chd);
					skin.removeChild(chd);
					delete skin[chd.name];
					skin.addChildAt(newchd,idx);
					skin[newchd.name] = newchd;
					skin.getChildByName(newchd.name).visible = false;
				} else { 
					skin.addChild(newchd);
					skin[newchd.name] = newchd;
				}
			}
			dispatchEvent(new SPLoaderEvent(SPLoaderEvent.SKIN));
		} catch (err:Error) {}
	};


}


}