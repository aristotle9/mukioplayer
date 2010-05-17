/**
* A couple of commonly used animation functions.
**/
package com.jeroenwijering.utils {


import flash.display.MovieClip;
import flash.events.Event;


public class Animations {


	/**
	* Fade function for MovieClip.
	*
	* @param tgt	The Movieclip to fade out.
	* @param end	The final alpha value.
	* @param spd	The amount of alpha change per frame.
	**/
	public static function fade(tgt:MovieClip,end:Number=1,spd:Number=0.25):void {
		if(tgt.alpha > end) {
			tgt.spd = -Math.abs(spd);
		} else {
			tgt.spd = Math.abs(spd);
		}
		tgt.end = end;
		tgt.addEventListener(Event.ENTER_FRAME,fadeHandler);
	};


	/** The fade enterframe function. **/
	private static function fadeHandler(evt:Event):void {
		var tgt:MovieClip = MovieClip(evt.target);
		if((tgt.alpha >= tgt.end-tgt.spd && tgt.spd > 0) ||
			(tgt.alpha <= tgt.end+tgt.spd && tgt.spd < 0)) {
			tgt.removeEventListener(Event.ENTER_FRAME,fadeHandler);
			tgt.alpha = tgt.end;
			if(tgt.end == 0) {tgt.visible = false;}
		} else {
			tgt.visible = true;
			tgt.alpha += tgt.spd;
		}
	};


	/**
	* Smoothly move a Movielip to a certain position.
	*
	* @param tgt	The Movielip to move.
	* @param xps	The x destination.
	* @param yps	The y destination.
	* @param spd	The movement speed (1 - 2).
	**/
	public static function ease(tgt:MovieClip,xps:Number,yps:Number,spd:Number=2):void {
		if(!xps) { tgt.xps = tgt.x; } else { tgt.xps = xps; }
		if(!yps) { tgt.yps = tgt.y; } else { tgt.yps = yps; }
		tgt.spd = spd;
		tgt.addEventListener(Event.ENTER_FRAME,easeHandler);
	};


	/** The ease enterframe function. **/
	private static function easeHandler(evt:Event):void {
		var tgt:MovieClip = MovieClip(evt.target);
		if(Math.abs(tgt.x - tgt.xps) < 1 && Math.abs(tgt.y - tgt.yps) < 1) {
			tgt.removeEventListener(Event.ENTER_FRAME,easeHandler);
			tgt.x = tgt.xps;
			tgt.y = tgt.yps;
		} else {
			tgt.x = tgt.xps - (tgt.xps-tgt.x)/tgt.spd;
			tgt.y = tgt.yps - (tgt.yps-tgt.y)/tgt.spd;
		}
	};


	/**
	* Typewrite text into a textfield.
	*
	* @param tgt	Movieclip that has a 'field' TextField.
	* @param txt	The textstring to write.
	* @param spd	The speed of typing (1 - 2).
	**/
	public static function write(tgt:MovieClip,str:String,spd:Number=1.5):void {
		tgt.str = str;
		tgt.spd = spd;
		tgt.tf.text = '';
		tgt.addEventListener(Event.ENTER_FRAME,writeHandler);
	};


	/** The write enterframe function. **/
	private static function writeHandler(evt:Event):void {
		var tgt:MovieClip = MovieClip(evt.target);
		var dif:Number = Math.floor((tgt.str.length-tgt.tf.text.length)/tgt.spd);
		tgt.tf.text = tgt.str.substr(0,tgt.str.length-dif);
		if(tgt.tf.text == tgt.str) {
			tgt.tf.htmlText = tgt.str;
			tgt.removeEventListener(Event.ENTER_FRAME,easeHandler);
		}
	};


}


}