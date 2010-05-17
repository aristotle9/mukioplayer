/**
* Print a graphical playlist, plus a scrollbar if the items don't fit.
**/
package com.jeroenwijering.plugins {


import com.jeroenwijering.events.*;
import com.jeroenwijering.utils.*;

import flash.display.*;
import flash.events.*;
import flash.geom.ColorTransform;
import flash.geom.Rectangle;
import flash.net.URLRequest;
import flash.utils.setInterval;
import flash.utils.clearInterval;


public class Playlist implements PluginInterface {


	/** List with configuration settings. **/
	public var config:Object = {};
	/** Reference to the playlist MC. **/
	public var clip:MovieClip;
	/** Reference to the view. **/
	private var view:AbstractView;
	/** Array with all button instances **/
	private var buttons:Array;
	/** Height of a button (to calculate scrolling) **/
	private var buttonheight:Number;
	/** Currently active button. **/
	private var active:Number;
	/** Proportion between clip and mask. **/
	private var proportion:Number;
	/** Interval ID for scrolling **/
	private var scrollInterval:Number;
	/** Image dimensions. **/
	private var image:Array;
	/** Color object for backcolor. **/
	private var back:ColorTransform;
	/** Color object for frontcolor. **/
	private var front:ColorTransform;
	/** Color object for lightcolor. **/
	private var light:ColorTransform;


	public function Playlist():void {};


	/** Initialize the communication with the player. **/
	public function initializePlugin(vie:AbstractView):void {
		view = vie;
		view.addControllerListener(ControllerEvent.ITEM,itemHandler);
		view.addControllerListener(ControllerEvent.PLAYLIST,playlistHandler);
		view.addControllerListener(ControllerEvent.RESIZE,resizeHandler);
		view.addModelListener(ModelEvent.STATE,stateHandler);
		buttonheight = clip.list.button.height;
		clip.list.button.visible = false;
		clip.list.mask = clip.masker;
		clip.list.addEventListener(MouseEvent.CLICK,clickHandler);
		clip.list.addEventListener(MouseEvent.MOUSE_OVER,overHandler);
		clip.list.addEventListener(MouseEvent.MOUSE_OUT,outHandler);
		clip.slider.buttonMode = true;
		clip.slider.mouseChildren = false;
		clip.slider.addEventListener(MouseEvent.MOUSE_DOWN,sdownHandler);
		clip.slider.addEventListener(MouseEvent.MOUSE_OVER,soverHandler);
		clip.slider.addEventListener(MouseEvent.MOUSE_OUT,soutHandler);
		clip.slider.visible = false;
		buttons = new Array();
		try {
			image = new Array(clip.list.button.image.width,clip.list.button.image.height);
		} catch (err:Error) {}
		if(clip.list.button['back']) { setColors(); }
	};


	/** Setup all buttons in the playlist **/
	private function buildList(clr:Boolean):void {
		if(!view.playlist) { return; }
		var wid:Number = clip.back.width;
		var hei:Number = clip.back.height;
		clip.masker.height = hei;
		clip.masker.width = wid;
		proportion = view.playlist.length*buttonheight/hei;
		if (proportion > 1.01) {
			wid -=clip.slider.width;
			buildSlider();
		} else {
			clip.slider.visible = false;
		}
		if(clr) {
			clip.list.y = clip.masker.y;
			for(var j:Number=0; j<buttons.length; j++) {
				clip.list.removeChild(buttons[j].c);
			}
			buttons = new Array();
		} else { 
			if(proportion > 1) { scrollEase(); }
		}
		for(var i:Number=0; i<view.playlist.length; i++) {
			if(clr) {
				var btn:MovieClip = Draw.clone(clip.list.button,true);
				var stc:Stacker = new Stacker(btn);
				btn.y = i*buttonheight;
				btn.buttonMode = true;
				btn.mouseChildren =false;
				btn.name = i.toString();
				buttons.push({c:btn,s:stc});
				setContents(i);
			}
			buttons[i].s.rearrange(wid);
		}
	};


	/** Setup the scrollbar component **/
	private function buildSlider():void {
		var scr:MovieClip = clip.slider;
		scr.visible = true;
		scr.x = clip.back.width-scr.width;
		var dif:Number = clip.back.height-scr.height-scr.y;
		scr.back.height += dif;
		scr.rail.height += dif;
		scr.icon.height = Math.round(scr.rail.height/proportion);
	};


	/** Handle a click on a button. **/
	private function clickHandler(evt:MouseEvent):void {
		view.sendEvent('item',Number(evt.target.name));
	};


	/** Switch the currently active item */
	private function itemHandler(evt:ControllerEvent):void {
		var idx:Number = view.config['item'];
		clearInterval(scrollInterval);
		if (proportion > 1.01) {
			scrollInterval = setInterval(scrollEase,50,idx*buttonheight/proportion,-idx*buttonheight+clip.masker.y);
		}
		if(light) {
			for (var itm:String in view.playlist[idx]) {
				if(buttons[idx].c[itm]) {
					try { 
						buttons[idx].c[itm].textColor = light.color;
					} catch (err:Error) {}
				}
			}
		}
		if(back) {
			buttons[idx].c['back'].transform.colorTransform = back;
		}
		buttons[idx].c.gotoAndStop('active');
		if(!isNaN(active)) {
			if(front) {
				for (var act:String in view.playlist[active]) {
					if(buttons[active].c[act]) {
						try { 
							buttons[active].c[act].textColor = front.color;
						} catch (err:Error) {}
					}
				}
			}
			buttons[active].c.gotoAndStop('out');
		}
		active = idx;
	};


	/** Loading of image completed; resume loading **/
	private function loaderHandler(evt:Event):void {
		var ldr:Loader = Loader(evt.target.loader);
		Stretcher.stretch(ldr,image[0],image[1],Stretcher.FILL);
	};


	/** Handle a button rollover. **/
	private function overHandler(evt:MouseEvent):void {
		var idx:Number = Number(evt.target.name);
		if(front && back) {
			for (var itm:String in view.playlist[idx]) {
				if(buttons[idx].c[itm] && typeof(buttons[idx].c[itm]) == "object") {
					buttons[idx].c[itm].textColor = back.color;
				}
			}
			buttons[idx].c['back'].transform.colorTransform = light;
		}
		buttons[idx].c.gotoAndStop('over');
	};


	/** Handle a button rollover. **/
	private function outHandler(evt:MouseEvent):void {
		var idx:Number = Number(evt.target.name);
		if(front && back) {
			for (var itm:String in view.playlist[idx]) {
				if(buttons[idx].c[itm] && typeof(buttons[idx].c[itm]) == "object") {
					if(idx == active) {
						buttons[idx].c[itm].textColor = light.color;
					} else { 
						buttons[idx].c[itm].textColor = front.color;
					}
				}
			}
			buttons[idx].c['back'].transform.colorTransform = back;
		}
		if(idx == active) {
			buttons[idx].c.gotoAndStop('active');
		} else { 
			buttons[idx].c.gotoAndStop('out');
		}
	};


	/** New playlist loaded: rebuild the playclip. **/
	private function playlistHandler(evt:ControllerEvent=null):void {
		clearInterval(scrollInterval);
		active = undefined;
		buildList(true);
		resizeHandler();
	};


	/** Process resizing requests **/
	private function resizeHandler(evt:ControllerEvent=null):void {
		clip.x = config['x'];
		clip.y = config['y'];
		clip.back.width = config['width'];
		clip.back.height = config['height'];
		buildList(false);
		if(config['position'] == 'over') {
			stateHandler();
		} else {
			clip.visible = config['visible'];
		}
	};


	/** Make sure the playlist is not out of range. **/
	private function scrollEase(ips:Number=-1,cps:Number=-1):void {
		var scr:MovieClip = clip.slider;
		if(ips != -1) {
			scr.icon.y = Math.round(ips-(ips-scr.icon.y)/1.5);
			clip.list.y = Math.round((cps - (cps-clip.list.y)/1.5));
		}
		if(clip.list.y > 0 || scr.icon.y < scr.rail.y) {
			clip.list.y = clip.masker.y;
			scr.icon.y = scr.rail.y;
		} else if (clip.list.y < clip.masker.height-clip.list.height ||
			scr.icon.y > scr.rail.y+scr.rail.height-scr.icon.height) {
			scr.icon.y = scr.rail.y+scr.rail.height-scr.icon.height;
			clip.list.y = clip.masker.y+clip.masker.height-clip.list.height;
		}
	};


	/** Scrolling handler. **/
	private function scrollHandler():void {
		var scr:MovieClip = clip.slider;
		var yps:Number = scr.mouseY-scr.rail.y;
		var ips:Number = yps - scr.icon.height/2;
		var cps:Number = clip.masker.y+clip.masker.height/2-proportion*yps;
		scrollEase(ips,cps);
	};


	/** Init the colors. **/
	private function setColors():void {
		if(view.config['backcolor']) { 
			back = new ColorTransform();
			back.color = uint('0x'+view.config['backcolor'].substr(-6));
			clip.back.transform.colorTransform = back;
			clip.slider.back.transform.colorTransform = back;
		}
		if(view.config['frontcolor']) {
			front = new ColorTransform();
			front.color = uint('0x'+view.config['frontcolor'].substr(-6));
			try { 
				clip.slider.icon.transform.colorTransform = front;
				clip.slider.rail.transform.colorTransform = front;
			} catch (err:Error) {}
			if(view.config['lightcolor']) {
				light = new ColorTransform();
				light.color = uint('0x'+view.config['lightcolor'].substr(-6));
			} else { 
				light = front;
			}
		}
	};


	/** Setup button elements **/
	private function setContents(idx:Number):void {
		for (var itm:String in view.playlist[idx]) {
			buttons[idx].c.gotoAndStop(0);
			if(!buttons[idx].c[itm] || !view.playlist[idx][itm]) {
				continue;
			} else if(itm == 'image') {
				if(config['thumbs'] != false && view.config['playlist'] != 'none' &&
					(view.playlist[idx]['image'] || view.playlist[idx]['playlist.image'])) {
					var img:MovieClip = buttons[idx].c.image;
					var msk:Sprite = Draw.rect(buttons[idx].c,'0xFF0000',img.width,img.height,img.x,img.y);
					var ldr:Loader = new Loader();
					img.mask = msk;
					img.addChild(ldr);
					ldr.contentLoaderInfo.addEventListener(Event.COMPLETE,loaderHandler);
					if(view.playlist[idx]['playlist.image']) {
						ldr.load(new URLRequest(view.playlist[idx]['playlist.image']));
					} else {
						ldr.load(new URLRequest(view.playlist[idx]['image']));
					}
				}
			} else if(itm == 'duration') {
				if(view.playlist[idx][itm] > 0) {
					buttons[idx].c[itm].htmlText = '<b>'+Strings.digits(view.playlist[idx][itm])+'</b>';
					if(front) { 
						buttons[idx].c[itm].textColor = front.color;
					}
				}
			} else {
				try { 
					if(itm == 'description') {
						buttons[idx].c[itm].htmlText = view.playlist[idx][itm];
					} else if(itm == 'title') {
						buttons[idx].c[itm].htmlText = '<b>'+view.playlist[idx][itm]+'</b>';
					} else {
						buttons[idx].c[itm].text = view.playlist[idx][itm];
					}
					if(front) {
						buttons[idx].c[itm].textColor = front.color;
					}
				} catch (e:Error) {}
			}
		}
		if(buttons[idx].c['image'] && (!view.playlist[idx]['image'] || config['thumbs'] == false)) {
			buttons[idx].c['image'].visible = false;
		}
		if(back) {
			buttons[idx].c['back'].transform.colorTransform = back;
		}
	};


	/** Start scrolling the playlist on mousedown. **/
	private function sdownHandler(evt:MouseEvent):void {
		clearInterval(scrollInterval);
    	clip.stage.addEventListener(MouseEvent.MOUSE_UP,supHandler);
		scrollHandler();
		scrollInterval = setInterval(scrollHandler,50);
	};


	/** Revert the highlight on mouseout. **/
	private function soutHandler(evt:MouseEvent):void {
		if(front) {
			clip.slider.icon.transform.colorTransform = front;
		} else { 
			clip.slider.icon.gotoAndStop('out');
		}
	};


	/** Highlight the icon on rollover. **/
	private function soverHandler(evt:MouseEvent):void {
		if(front) {
			clip.slider.icon.transform.colorTransform = light;
		} else { 
			clip.slider.icon.gotoAndStop('over');
		}
	};


	/** Stop scrolling the playlist on mouseout. **/
	private function supHandler(evt:MouseEvent):void {
		clearInterval(scrollInterval);
    	clip.stage.removeEventListener(MouseEvent.MOUSE_UP,supHandler);
	};


	/** Process state changes **/
	private function stateHandler(evt:ModelEvent=null):void {
		if(config['position'] == 'over') {
			if(view.config['state'] == ModelStates.PLAYING ||
				view.config['state'] == ModelStates.PAUSED ||
				view.config['state'] == ModelStates.BUFFERING) {
				clip.visible = false;
			} else {
				clip.visible = true;
			}
		}
	};


};


}