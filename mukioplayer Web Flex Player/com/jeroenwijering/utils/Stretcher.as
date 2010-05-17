/**
* Simple class that handles stretching of displayelements. 
**/
package com.jeroenwijering.utils {


import flash.display.DisplayObject;


public class Stretcher {


	/** Stretches the clip nonuniform to fit the container. **/
	public static var EXACTFIT:String = "exactfit";
	/** Stretches the clip uniform to fill the container, with parts being cut off. **/
	public static var FILL:String = "fill";
	/** No stretching, but the clip is placed in the center of the container. **/
	public static var NONE:String = "none";
	/** Stretches the clip uniform to fit the container, with bars added. **/
	public static var UNIFORM:String = "uniform";


	/** 
	* Resize a displayobject to the display, depending on the stretching.
	*
	* @param clp	The display element to resize.
	* @param wid	The target width.
	* @param hei	The target height.
	* @param typ	The stretching type.
	**/
	public static function stretch(clp:DisplayObject,wid:Number,hei:Number,typ:String='uniform'):void {
		var xsc:Number = wid/clp.width;
		var ysc:Number = hei/clp.height;
		switch(typ.toLowerCase()) {
			case 'exactfit':
				clp.width = wid;
				clp.height = hei;
				break;
			case 'fill':
				if(xsc > ysc) { 
					clp.width *= xsc;
					clp.height *= xsc;
				} else { 
					clp.width *= ysc;
					clp.height *= ysc;
				}
				break;
			case 'none':
				clp.scaleX = 1;
				clp.scaleY = 1;
				break;
			case 'uniform':
			default:
				if(xsc > ysc) {
					clp.width *= ysc;
					clp.height *= ysc;
				} else { 
					clp.width *= xsc;
					clp.height *= xsc;
				}
				break;
		}
		clp.x = Math.round(wid/2 - clp.width/2);
		clp.y = Math.round(hei/2 - clp.height/2);
		clp.width = Math.ceil(clp.width);
		clp.height = Math.ceil(clp.height);
	};

}


}