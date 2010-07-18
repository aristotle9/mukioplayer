/**
* Plugin that skins the actual mediafiles, overlay icons and the logo.
**/
package com.jeroenwijering.plugins {


import com.jeroenwijering.events.*;
import com.jeroenwijering.utils.*;

import flash.display.*;
import flash.events.*;
import flash.geom.ColorTransform;
import flash.net.*;
import flash.utils.*;


public class Display implements PluginInterface {


	/** Configuration vars for this plugin. **/
	public var config:Object = {};
	/** Reference to the skin MC. **/
	public var clip:MovieClip;
	/** Reference to the MVC view. **/
	private var view:AbstractView;
	/** Loader object for loading a logo. **/
	private var loader:Loader;
	/** The margins of the logo. **/
	private var margins:Array;
	/** The latest playback state **/
	private var state:String;
	/** Map with color transformation objects. **/
	private var colors:Object;
	/** A list of all the icons. **/
	private var ICONS:Array = new Array(
		'playIcon',
		'errorIcon',
		'bufferIcon',
		'linkIcon',
		'muteIcon',
		'fullscreenIcon',
		'nextIcon',
		'titleIcon'
	);
	/** Timeout for hiding the buffericon. **/
	private var timeout:Number;


	/** Constructor; add all needed listeners. **/
	public function Display():void {};


	/** Initialize the plugin. **/
	public function initializePlugin(vie:AbstractView):void {
		view = vie;
		view.addControllerListener(ControllerEvent.ERROR,errorHandler);
		view.addControllerListener(ControllerEvent.MUTE,stateHandler);
		view.addControllerListener(ControllerEvent.PLAYLIST,stateHandler);
		view.addControllerListener(ControllerEvent.RESIZE,resizeHandler);
		view.addModelListener(ModelEvent.BUFFER,bufferHandler);
		view.addModelListener(ModelEvent.ERROR,errorHandler);
		view.addModelListener(ModelEvent.STATE,stateHandler);
		if(view.config['screencolor']) {
			var scr:ColorTransform = new ColorTransform();
			scr.color = uint('0x'+view.config['screencolor']);
			clip.back.transform.colorTransform = scr;
		}
		if(view.config['displayclick'] != 'none') {
			clip.addEventListener(MouseEvent.CLICK,clickHandler);
			clip.buttonMode = true;
		}
		if(clip.logo) {
			logoSetter();
		}
		stateHandler();
	};


	/** Receive buffer updates. **/
	private function bufferHandler(evt:ModelEvent):void {
		if(evt.data.percentage > 0) {
			Draw.set(clip.bufferIcon.txt,'text',Strings.zero(evt.data.percentage));
		} else {
			Draw.set(clip.bufferIcon.txt,'text','');
		}
	};


	/** Process a click on the clip. **/
	private function clickHandler(evt:MouseEvent):void {
		if(view.config['state'] == ModelStates.IDLE) {
			view.sendEvent('PLAY');
		} else if (view.config['state'] == ModelStates.PLAYING && view.config['mute'] == true) {
			view.sendEvent('MUTE');
		} else {
			view.sendEvent(view.config['displayclick']);
		}
	};


	/** Receive and print errors. **/
	private function errorHandler(evt:Object):void {
		if(view.config['icons'] == true) {
			setIcon('errorIcon');
			Draw.set(clip.errorIcon.txt,'text',evt.data.message);
		}
	};


	/** Logo loaded; now position it. **/
	private function loaderHandler(evt:Event=null):void {
		if(margins[0] > margins[2]) {
			clip.logo.x = clip.back.width- margins[2]-clip.logo.width;
		} else {
			clip.logo.x = margins[0];
		}
		if(margins[1] > margins[3]) {
			clip.logo.y = clip.back.height- margins[3]-clip.logo.height;
		} else {
			clip.logo.y = margins[1];
		}
	};


	/** Setup the logo loading. **/
	private function logoSetter():void {
		margins = new Array(
			clip.logo.x,
			clip.logo.y,
			clip.back.width-clip.logo.x-clip.logo.width,
			clip.back.height-clip.logo.y-clip.logo.height
		);
		if(clip.logo.width == 10) {
			Draw.clear(clip.logo);
		}
		if(view.config['logo']) {
			Draw.clear(clip.logo);
			loader = new Loader();
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE,loaderHandler);
			loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR,loaderHandler);
			clip.logo.addChild(loader);
			loader.load(new URLRequest(view.config['logo']));
		}
	};



	/** Receive resizing requests **/
	private function resizeHandler(evt:ControllerEvent):void {
		if(config['height'] > 11) {
			clip.visible = true;
		} else {
			clip.visible = false;
		}
		Draw.pos(clip,config['x'],config['y']);
		Draw.size(clip.back,config['width'],config['height']);
		Draw.size(clip.masker,config['width'],config['height']);
		for(var i:String in ICONS) {
			Draw.pos(clip[ICONS[i]],config['width']/2,config['height']/2);
		}
		if(clip.logo) {
			loaderHandler();
		}
	};


	/** Set a specific icon in the clip. **/
	private function setIcon(icn:String=undefined):void {
		clearTimeout(timeout);
		for(var i:String in ICONS) {
			if(clip[ICONS[i]]) {
				if(icn == ICONS[i] && view.config['icons'] == true) {
					clip[ICONS[i]].visible = true;
				} else {
					clip[ICONS[i]].visible = false;
				}
			}
		}
	};


	/** Place the title in the titleIcon. **/
	private function setTitle():void {
		var icn:MovieClip = clip.titleIcon;
		icn.txt.autoSize = 'left';
		icn.txt.text = view.playlist[view.config['item']]['title'];
		if(icn.txt.width+icn.icn.width + 60 > config['width']) {
			icn.bck.width = config['width'] - 60;
			icn.txt.autoSize = 'none';
			icn.txt.width = icn.bck.width - icn.icn.width - 20;
		} else { 
			icn.bck.width = icn.txt.width + icn.icn.width + 20;
		}
		icn.bck.x = -icn.bck.width/2;
		icn.icn.x = icn.bck.x;
		icn.txt.x = icn.icn.x + icn.icn.width;
	};


	/** Handle a change in playback state. **/
	private function stateHandler(evt:Event=null):void {
		switch (view.config['state']) {
			case ModelStates.PLAYING:
				if(view.config['mute'] == true) {
					setIcon('muteIcon');
				} else {
					setIcon();
				}
				break;
			case ModelStates.BUFFERING:
				if(evt && evt['data'].oldstate == ModelStates.PLAYING) {
					timeout = setTimeout(setIcon,1500,'bufferIcon');
				} else {
					setIcon('bufferIcon');
				}
				break;
			case ModelStates.IDLE:
			case ModelStates.COMPLETED:
				if(view.config.displayclick == 'none' || !view.playlist) {
					setIcon();
				} else if (clip.titleIcon && view.config['displaytitle']) {
					setTitle();
					setIcon('titleIcon');
				} else {
					setIcon('playIcon');
				}
				break;
			default:
				setIcon(view.config.displayclick+'Icon');
				break;
		}
	};


};


}
