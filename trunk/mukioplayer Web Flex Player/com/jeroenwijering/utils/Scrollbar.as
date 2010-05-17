/**
* This draws a simple scrollbar next to a textfield/mask combination.
**/
package com.jeroenwijering.utils {


import flash.display.Sprite;
import flash.events.MouseEvent;
import flash.text.TextField;
import flash.utils.clearInterval;
import flash.utils.setInterval;


public class Scrollbar {


	/** Textfield that has to be scrolled. **/
	private var field:TextField;
	/** Mask for the scrolleable field. **/
	private var mask:Sprite;
	/** Clip in which the scrollbar is drawn. **/
	private var scrollbar:Sprite;
	/** Icon of the scrollbar. **/
	private var icon:Sprite;
	/** Color of the scrollbar. **/
	private var color:uint;
	/** Proportion between the field and mask. **/
	private var proportion:Number;
	/** Interval ID for smooth scrolling. **/
	private var interval:Number;


	/**
	* Constructor; initializes the scrollbar parameters.
	*
	* @param fld	The field that has to be scrolled.
	* @param clr	The color of the scrollbar (the part that moves).
	**/
	public function Scrollbar(fld:TextField,clr:uint=0xFFFFFF):void {
		field = fld;
		color = clr;
		mask = new Sprite();
		mask.graphics.beginFill(color);
		mask.graphics.drawRect(0,0,field.width,field.height);
		mask.x = field.x;
		mask.y = field.y;
		field.parent.addChild(mask);
		field.mask = mask;
		scrollbar = new Sprite();
		scrollbar.mouseChildren = false;
		scrollbar.buttonMode = true;
		field.parent.addChild(scrollbar);
		icon = new Sprite();
		scrollbar.addChild(icon);
	};


	/**
	* Invoke a (re)draw of the scrollbar.
	**/
	public function draw(hei:Number):void {
		if(hei) { mask.height = hei; }
		mask.width = field.width;
		field.y = mask.y;
		scrollbar.x = field.x + field.width;
		scrollbar.y = field.y;
		proportion = mask.height/field.height;
		if(proportion < 1) {
			scrollbar.visible = true;
			scrollbar.graphics.clear();
			scrollbar.graphics.drawRect(0,0,10,mask.height);
			scrollbar.graphics.beginFill(color,0.5);
			scrollbar.graphics.drawRect(4,0,1,mask.height);
			icon.graphics.clear();
			icon.graphics.beginFill(color);
			icon.graphics.drawRect(3,0,3,mask.height*proportion);
			scrollbar.addEventListener(MouseEvent.MOUSE_DOWN,downHandler);
		} else {
			scrollbar.visible = false;
			scrollbar.removeEventListener(MouseEvent.MOUSE_DOWN,downHandler);
		}
	};


	/** The mouse is pressed over the scrollbar. **/
	private function downHandler(evt:MouseEvent):void {
		interval = setInterval(scroll,25);
		mask.stage.addEventListener(MouseEvent.MOUSE_UP,upHandler);
	};


	/** The mouse has been released after a scrollbarpress. **/
	private function upHandler(evt:MouseEvent):void {
		clearInterval(interval);
		mask.stage.removeEventListener(MouseEvent.MOUSE_UP,upHandler);
	};


	/** Calculate and scroll to the new y position. **/
	private function scroll():void {
		var mps:Number = scrollbar.mouseY;
		if(mps < icon.height/2) {
			icon.y = 0;
			field.y = mask.y;
		} else if (mps > scrollbar.height - icon.height/2) {
			icon.y = scrollbar.height-icon.height;
			field.y = mask.y + mask.height - field.height;
		} else {
			icon.y = mps - icon.height/2;
			field.y = mask.y + mask.height/2 - mps/proportion;
		}
	};


};


}