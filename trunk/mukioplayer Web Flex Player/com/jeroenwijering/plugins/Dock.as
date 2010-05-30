/**
* Plugin that renders a dock with buttons (much like Apple's dock)
**/
package com.jeroenwijering.plugins {


import com.jeroenwijering.events.*;
import com.jeroenwijering.utils.*;

import flash.display.*;
import flash.events.*;
import flash.geom.*;
import flash.utils.*


public class Dock implements PluginInterface {


	/** Configuration vars for this plugin. **/
	public var config:Object = {
		align:'right'
	};
	/** Reference to the skin MVC. **/
	public var clip:MovieClip;
	/** Reference to the MVC view. **/
	private var view:AbstractView;
	/** Array with all the buttons in the dock. **/
	private var buttons:Array;
	/** Map with color transformation objects. **/
	private var colors:Object;
	/** Timeout for hiding the buttons when the video plays. **/
	private var timeout:Number;


	/** Constructor; add all needed listeners. **/
	public function Dock():void {
		buttons = new Array();
	};


	/** 
	* Add a button to the dock.
	*
	* @param icn	The icon to display in the button.
	* @param txt	The text to display in the button.
	* @param fcn	The function to call when the button is clicked
	* @return 
	**/
	public function addButton(icn:DisplayObject,txt:String,hdl:Function):DockButton { 
		var btn:DockButton = new DockButton(icn,txt,hdl,colors);
		clip.addChild(btn);
		buttons.push(btn);
		resizeHandler();
		return btn;
	};


	/** Initialize the plugin. **/
	public function initializePlugin(vie:AbstractView):void {
		view = vie;
		if(view.config['dock']) {
			view.addControllerListener(ControllerEvent.RESIZE,resizeHandler);
			view.addModelListener(ModelEvent.STATE,stateHandler);
			clip.stage.addEventListener(MouseEvent.MOUSE_MOVE,moveHandler);
		} else {
			clip.visible = false;
		}
		if(view.config['backcolor'] && view.config['frontcolor']) {
			setColorTransforms();
		}
	};


	/** Show the buttons on mousemove. **/
	private function moveHandler(evt:MouseEvent=null):void {
		clearTimeout(timeout);
		if(view.config['state'] == ModelStates.BUFFERING || 
			view.config['state'] == ModelStates.PLAYING) { 
			timeout = setTimeout(moveTimeout,2000);
			if(clip.alpha < 1) {
				Animations.fade(clip,1);
			}
		}
	};


	/** Hide the buttons again when move has timed out. **/
	private function moveTimeout():void {
		Animations.fade(clip,0);
	};


	/** 
	* Remove a button from the dock. 
	* 
	* @param btn	The button to remove.
	**/
	public function removeButton(btn:DockButton):void { 
		for (var i:Number=0; i<buttons.length; i++) { 
			if(buttons[i] == btn) {
				buttons.splice(i,1);
			}
		}
		try {
			clip.removeChild(btn);
		} catch (err:Error) {}
	};


	/** Receive resizing requests **/
	private function resizeHandler(evt:ControllerEvent=null):void {
		clip.y = config['y'];
		if(config['align'] == 'left') {
			clip.x = config['x'];
		} else {
			clip.x = config['x'] + config['width'] - clip.width;
		}
		for (var i:Number=0; i<buttons.length; i++) {
			buttons[i].y = buttons[i].height*i;
		}
	};


	/** Set color tranformation objects so the buttons can be colorized. **/
	private function setColorTransforms():void {
		var bck:ColorTransform = new ColorTransform();
		bck.color = uint('0x'+view.config['backcolor']);
		var frt:ColorTransform = new ColorTransform();
		frt.color = uint('0x'+view.config['frontcolor']);
		var lgt:ColorTransform = new ColorTransform();
		if(view.config['lightcolor']) {
			lgt.color = uint('0x'+view.config['lightcolor']);
		} else { 
			lgt.color = uint('0x'+view.config['backcolor']);
		}
		colors = {back:frt,front:bck,light:lgt};
	};


	/** Process state changes **/
	private function stateHandler(evt:ModelEvent=undefined):void {
		switch(view.config['state']) {
			case ModelStates.PLAYING:
			case ModelStates.BUFFERING:
				moveHandler();
				break;
			default:
				clearTimeout(timeout);
				Animations.fade(clip,1);
				break;
		}
	};


};


}
