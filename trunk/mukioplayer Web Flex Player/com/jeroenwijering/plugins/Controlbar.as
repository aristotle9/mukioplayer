/**
* Display a controlbar with transport buttons and sliders.
**/
package com.jeroenwijering.plugins {


import com.jeroenwijering.events.*;
import com.jeroenwijering.utils.*;

import flash.accessibility.*;
import flash.display.*;
import flash.events.MouseEvent;
import flash.geom.ColorTransform;
import flash.geom.Rectangle;
import flash.net.URLRequest;
import flash.ui.Mouse;
import flash.utils.clearTimeout;
import flash.utils.setTimeout;


public class Controlbar implements PluginInterface {


	/** List with configuration settings. **/
	public var config:Object = {};
	/** Reference to the controlbar clip. **/
	public var clip:MovieClip;
	/** Reference to the view. **/
	private var view:AbstractView;
	/** A list with all controls. **/
	private var stacker:Stacker;
	/** Timeout for hiding the clip. **/
	private var hiding:Number;
	/** When scrubbing, icon shouldn't be set. **/
	private var scrubber:MovieClip;
	/** Color object for frontcolor. **/
	private var front:ColorTransform;
	/** Color object for lightcolor. **/
	private var light:ColorTransform;
	/** The actions for all controlbar buttons. **/
	private var BUTTONS:Object = {
		playButton:'PLAY',
		pauseButton:'PLAY',
//		stopButton:'STOP',
		prevButton:'PREV',
		nextButton:'NEXT',
		linkButton:'LINK',
		fullscreenButton:'FULLSCREEN',
		normalscreenButton:'FULLSCREEN',
		muteButton:'MUTE',
		unmuteButton:'MUTE'
	};
	/** The actions for all sliders **/
	private var SLIDERS:Object = {
		timeSlider:'SEEK',
		volumeSlider:'VOLUME'
	}
	/** The button to clone for all custom buttons. **/
	private var clonee:MovieClip;
	/** Saving the block state of the controlbar. **/
	private var blocking:Boolean;


	/** Constructor. **/
	public function Controlbar():void {};

	/** 
	* Add a new button to the controlclip.
	*
	* @param icn	A graphic to show as icon
	* @param nam	Name of the button
	* @param hdl	The function to call when clicking the button.
	**/
	public function addButton(icn:DisplayObject,nam:String,hdl:Function):void {
		if(clip['linkButton'] && clip['linkButton'].back) {
			var btn:* = Draw.clone(clip['linkButton']);
			btn.name = nam+'Button';
			btn.visible = true;
			btn.tabEnabled = true;
			btn.tabIndex = 6;
			var acs:AccessibilityProperties = new AccessibilityProperties();
			acs.name = nam+'Button';
			btn.accessibilityProperties = acs;
			clip.addChild(btn);
			var off:Number = Math.round((btn.height-icn.height)/2);
			Draw.clear(btn.icon);
			btn.icon.addChild(icn);
			icn.x = icn.y = 0;
			btn.icon.x = btn.icon.y = off;
			btn.back.width = icn.width+2*off;
			btn.buttonMode = true;
			btn.mouseChildren = false;
			btn.addEventListener(MouseEvent.CLICK,hdl);
			if(front) {
				btn.icon.transform.colorTransform = front;
				btn.addEventListener(MouseEvent.MOUSE_OVER,overHandler);
				btn.addEventListener(MouseEvent.MOUSE_OUT,outHandler);
			}
			stacker.insert(btn,clip['linkButton']);
		}
	};


	/** Hide the controlbar **/
	public function block(stt:Boolean):void {
		blocking = stt;
		timeHandler();
	};


	/** Handle clicks from all buttons. **/
	private function clickHandler(evt:MouseEvent):void {
		var act:String = BUTTONS[evt.target.name];
		if (blocking != true || act == "FULLSCREEN" || act == "MUTE") {
			view.sendEvent(act);
		}
	};


	/** Handle mouse presses on sliders. **/
	private function downHandler(evt:MouseEvent):void {
		scrubber = MovieClip(evt.target);
		if(blocking != true || scrubber.name == 'volumeSlider') {
			var rct:Rectangle = new Rectangle(scrubber.rail.x,scrubber.icon.y,scrubber.rail.width-scrubber.icon.width,0);
			scrubber.icon.startDrag(true,rct);
    		clip.stage.addEventListener(MouseEvent.MOUSE_UP,upHandler);
		} else { 
			scrubber = undefined;
		}
	};


	/** Fix the timeline display. **/
	private function fixTime():void {
		try {
			var scp:Number = clip.timeSlider.scaleX;
			clip.timeSlider.scaleX = 1;
			clip.timeSlider.icon.x = scp*clip.timeSlider.icon.x;
			clip.timeSlider.mark.x = scp*clip.timeSlider.mark.x;
			clip.timeSlider.mark.width = scp*clip.timeSlider.mark.width;
			clip.timeSlider.rail.width = scp*clip.timeSlider.rail.width;
			clip.timeSlider.done.x = scp*clip.timeSlider.done.x;
			clip.timeSlider.done.width = scp*clip.timeSlider.done.width;
		} catch (err:Error) {}
	};


	/** Initialize from view. **/
	public function initializePlugin(vie:AbstractView):void {
		view = vie;
		view.addControllerListener(ControllerEvent.RESIZE,resizeHandler);
		view.addModelListener(ModelEvent.LOADED,loadedHandler);
		view.addModelListener(ModelEvent.STATE,stateHandler);
		view.addModelListener(ModelEvent.TIME,timeHandler);
		view.addControllerListener(ControllerEvent.PLAYLIST,itemHandler);
		view.addControllerListener(ControllerEvent.ITEM,itemHandler);
		view.addControllerListener(ControllerEvent.MUTE,muteHandler);
		view.addControllerListener(ControllerEvent.VOLUME,volumeHandler);
		stacker = new Stacker(clip);
		setButtons();
		setColors();
		itemHandler();
		loadedHandler();
		muteHandler();
		stateHandler();
		timeHandler();
		volumeHandler();
	};


	/** Handle a change in the current item **/
	private function itemHandler(evt:ControllerEvent=null):void {
		try {
			if(view.playlist && view.playlist.length > 1) {
				clip.prevButton.visible = clip.nextButton.visible = true;
			} else {
				clip.prevButton.visible = clip.nextButton.visible = false;
			}
		} catch (err:Error) {}
		try {
			if(view.playlist && view.playlist[view.config['item']]['link'] && !view.getPlugin('sharing')) {
				clip.linkButton.visible = true;
			} else { 
				clip.linkButton.visible = false;
			}
		} catch (err:Error) {}
		timeHandler();
		stacker.rearrange();
		fixTime();
		loadedHandler(new ModelEvent(ModelEvent.LOADED,{loaded:0,total:0}))
	};


	/** Process bytesloaded updates given by the model. **/
	private function loadedHandler(evt:ModelEvent=null):void {
		var pc1:Number = 0;
		if(evt && evt.data.total > 0) {
			pc1 = evt.data.loaded/evt.data.total;
		}
		var pc2:Number = 0;
		if(evt && evt.data.offset) {
			pc2 = evt.data.offset/evt.data.total;
		}
		try {
			var wid:Number = clip.timeSlider.rail.width;
			clip.timeSlider.mark.x = pc2*wid;
			clip.timeSlider.mark.width = pc1*wid;
			var icw:Number = clip.timeSlider.icon.x + clip.timeSlider.icon.width;
		} catch (err:Error) {}
	};


	/** Show above controlbar on mousemove. **/
	private function moveHandler(evt:MouseEvent=null):void {
		if(clip.alpha == 0) { Animations.fade(clip,1); }
		clearTimeout(hiding);
		hiding = setTimeout(moveTimeout,2000);
		Mouse.show();
	};


	/** Hide above controlbar again when move has timed out. **/
	private function moveTimeout():void {
		Animations.fade(clip,0);
		Mouse.hide();
	};


	/** Show a mute icon if playing. **/
	private function muteHandler(evt:ControllerEvent=null):void {
			if(view.config['mute'] == true) {
				try {
					clip.muteButton.visible = false;
					clip.unmuteButton.visible = true;
				} catch (err:Error) {}
				try {
					clip.volumeSlider.mark.visible = false;
					clip.volumeSlider.icon.x = clip.volumeSlider.rail.x;
				} catch (err:Error) {}
			} else {
				try {
					clip.muteButton.visible = true;
					clip.unmuteButton.visible = false;
				} catch (err:Error) {}
				try {
					clip.volumeSlider.mark.visible = true;
					volumeHandler();
				} catch (err:Error) {}
			}
	};


	/** Handle mouseouts from all buttons **/
	private function outHandler(evt:MouseEvent):void {
		if(front && evt.target['icon']) {
			evt.target['icon'].transform.colorTransform = front;
		} else {
			evt.target.gotoAndPlay('out');
		}
	};


	/** Handle clicks from all buttons **/
	private function overHandler(evt:MouseEvent):void {
		if(front && evt.target['icon']) {
			evt.target['icon'].transform.colorTransform = light;
		} else {
			evt.target.gotoAndPlay('over');
		}
	};


	/** Process resizing requests **/
	private function resizeHandler(evt:ControllerEvent=null):void {
		var wid:Number = config['width'];
		clip.x = config['x'];
		clip.y = config['y'];
		clip.visible = config['visible'];
		clip.back.alpha = clip.stage['displayState'] == 'fullScreen' ? 0.65 : 1;
		if(config['position'] == 'over' || view.config['fullscreen'] == true) {
			clip.x = config['x'] + config['margin'];
			clip.y = config['y'] + config['height'] - config['margin'] - config['size'];
			wid = config['width'] - 2 * config['margin'];
		}
		try { 
			clip.fullscreenButton.visible = false;
			clip.normalscreenButton.visible = false;
			if(clip.stage['displayState'] && view.config['height'] > 40) {
				trace("view.config['fullscreen'] : " + view.config['fullscreen']);
				if (view.config['fullscreen']) {
					clip.fullscreenButton.visible = false;
					clip.normalscreenButton.visible = true;
				} else {
					clip.fullscreenButton.visible = true;
					clip.normalscreenButton.visible = false;
				}
			}
		} catch (err:Error) {}
		stacker.rearrange(wid);
		stateHandler();
		fixTime();
		Mouse.show();
	};


	/** Clickhandler for all buttons. **/
	private function setButtons():void {
		for(var btn:String in BUTTONS) {
			if(clip[btn]) {
				clip[btn].mouseChildren = false;
				clip[btn].buttonMode = true;
				clip[btn].addEventListener(MouseEvent.CLICK, clickHandler);
				clip[btn].addEventListener(MouseEvent.MOUSE_OVER, overHandler);
				clip[btn].addEventListener(MouseEvent.MOUSE_OUT, outHandler);
			}
		}
		for(var sld:String in SLIDERS) {
			if(clip[sld]) {
				clip[sld].mouseChildren = false;
				clip[sld].buttonMode = true;
				clip[sld].addEventListener(MouseEvent.MOUSE_DOWN, downHandler);
				clip[sld].addEventListener(MouseEvent.MOUSE_OVER, overHandler);
				clip[sld].addEventListener(MouseEvent.MOUSE_OUT, outHandler);
			}
		}
	};


	/** Init the colors. **/
	private function setColors():void {
		if(view.config['backcolor'] && clip['playButton'].icon) {
			var clr:ColorTransform = new ColorTransform();
			clr.color = uint('0x'+view.config['backcolor'].substr(-6));
			clip.back.transform.colorTransform = clr;
		}
		if(view.config['frontcolor']) {
			try {
				front = new ColorTransform();
				front.color = uint('0x'+view.config['frontcolor'].substr(-6));
				for(var btn:String in BUTTONS) {
					if(clip[btn]) {
						clip[btn]['icon'].transform.colorTransform = front;
					}
				}
				for(var sld:String in SLIDERS) {
					if(clip[sld]) {
						clip[sld]['icon'].transform.colorTransform = front;
						clip[sld]['mark'].transform.colorTransform = front;
						clip[sld]['rail'].transform.colorTransform = front;
					}
				}
				clip.elapsedText.textColor = front.color;
				clip.totalText.textColor = front.color;
			} catch (err:Error) {}
		}
		if(view.config['lightcolor']) {
			light = new ColorTransform();
			light.color = uint('0x'+view.config['lightcolor'].substr(-6));
		} else { 
			light = front;
		}
		if(light) {
			try {
				clip['timeSlider']['done'].transform.colorTransform = light;
				clip['volumeSlider']['mark'].transform.colorTransform = light;
			} catch (err:Error) {}
		}
	};


	/** Process state changes **/
	private function stateHandler(evt:ModelEvent=undefined):void {
		clearTimeout(hiding);
		view.skin.removeEventListener(MouseEvent.MOUSE_MOVE,moveHandler);
		try {
			var dps:String = clip.stage['displayState'];
		} catch (err:Error) {}
		switch(view.config['state']) {
			case ModelStates.PLAYING:
			case ModelStates.BUFFERING:
				try {
					clip.playButton.visible = false;
					clip.pauseButton.visible = true;
				} catch (err:Error) {}
				if(config['position'] == 'over' || (dps == 'fullScreen' && config['position'] != 'none')) {
					hiding = setTimeout(moveTimeout,2000);
					view.skin.addEventListener(MouseEvent.MOUSE_MOVE,moveHandler);
				} else {
					Animations.fade(clip,1);
				}
				break;
			default:
				try {
					clip.playButton.visible = true;
					clip.pauseButton.visible = false;
				} catch (err:Error) {}
				if(config['position'] == 'over' || dps == 'fullScreen') {
					Mouse.show();
					Animations.fade(clip,1);
				}
		}
	};


	/** Process time updates given by the model. **/
	private function timeHandler(evt:ModelEvent=null):void {
		var dur:Number = 0;
		var pos:Number = 0;
		if(evt) {
			dur = evt.data.duration;
			pos = evt.data.position;
		} else if(view.playlist) {
			dur = view.playlist[view.config['item']]['duration'];
			pos = 0;
		}
		var pct:Number = pos/dur;
		if(isNaN(pct)) { pct = 1; }
		try {
			clip.elapsedText.text = Strings.digits(pos);
			clip.totalText.text = Strings.digits(dur);
		} catch (err:Error) {}
		try {
			var tsl:MovieClip = clip.timeSlider;
			var xps:Number = Math.round(pct*(tsl.rail.width-tsl.icon.width));
			if (dur > 0) {
				clip.timeSlider.icon.visible = true;
				clip.timeSlider.mark.visible = true;
				if(!scrubber) {
					clip.timeSlider.icon.x = xps;
					clip.timeSlider.done.width = xps;
				}
				clip.timeSlider.done.visible = true;
			} else {
				clip.timeSlider.icon.visible = false;
				clip.timeSlider.mark.visible = false;
				clip.timeSlider.done.visible = false;
			}
		} catch (err:Error) {}
	};


	/** Handle mouse releases on sliders. **/
	private function upHandler(evt:MouseEvent):void {
		var mpl:Number = 0;
    	clip.stage.removeEventListener(MouseEvent.MOUSE_UP,upHandler);
		scrubber.icon.stopDrag();
		if(scrubber.name == 'timeSlider' && view.playlist) {
			mpl = view.playlist[view.config['item']]['duration'];
		} else if(scrubber.name == 'volumeSlider') {
			mpl = 100;
		}
		var pct:Number = (scrubber.icon.x-scrubber.rail.x) / (scrubber.rail.width-scrubber.icon.width) * mpl;
		view.sendEvent(SLIDERS[scrubber.name],Math.round(pct));
		scrubber = undefined;
	};


	/** Reflect the new volume in the controlbar **/
	private function volumeHandler(evt:ControllerEvent=null):void {
		try {
			var vsl:MovieClip = clip.volumeSlider;
			vsl.mark.width = view.config['volume']*(vsl.rail.width-vsl.icon.width/2)/100;
			vsl.icon.x = vsl.mark.x + view.config['volume']*(vsl.rail.width-vsl.icon.width)/100;
		} catch (err:Error) {}
	};


};


}