/**
* Functions for drawing commonly used elements.
**/
package com.jeroenwijering.utils {


import flash.display.*;
import flash.geom.Rectangle;
import flash.text.TextField;
import flash.text.TextFormat;
import flash.utils.getQualifiedClassName;


public class Draw {


	/**
	* Completely clear the contents of a displayobject.
	*
	* @param tgt	Displayobject to clear.
	**/
	public static function clear(tgt:DisplayObjectContainer):void {
		var len:Number = tgt.numChildren;
		for(var i:Number=0; i<len; i++) {
			tgt.removeChildAt(0);
		}
		tgt.scaleX = tgt.scaleY = 1;
	};


	/** 
	* Clone a sprite / movieclip.
	*
	* @param tgt	Sprite to clone.
	* @param adc	Add as child to the parent displayobject.
	*
	* @return		The clone; not yet added to the displaystack.
	**/
	public static function clone(tgt:Sprite,adc:Boolean=false):MovieClip {
		var nam:String = getQualifiedClassName(tgt);
		var cls:Class;
		try {
			cls = tgt.loaderInfo.applicationDomain.getDefinition(nam) as Class;
		} catch(e:Error) {
			cls = Object(tgt).constructor;
		}
		var dup:* = new cls();
		dup.transform = tgt.transform;
		dup.filters = tgt.filters;
		dup.cacheAsBitmap = tgt.cacheAsBitmap;
		dup.opaqueBackground = tgt.opaqueBackground;
		if(adc == true) {
			var idx:Number = tgt.parent.getChildIndex(tgt);
			tgt.parent.addChildAt(dup,idx+1);
		}
	    return dup;
	};

	/** 
	* Try positioning a certain displayobject.
	*
	* @param obj	The displayobject to position.
	* @param xps	New x position of the object.
	* @param yps	New y position of the object.
	**/
	public static function pos(obj:DisplayObject,xps:Number,yps:Number):void {
		try {
			obj.x = Math.round(xps);
			obj.y = Math.round(yps);
		} catch (err:Error) {}
	};


	/**
	* Draw a rectangle on stage.
	*
	* @param tgt	Displayobject to add the rectangle to.
	* @param col	Color of the rectangle.
	* @param wid	Width of the rectangle.
	* @param hei	Height of the rectangle.
	* @param xps	X offset of the rectangle, defaults to 0.
	* @param yps	Y offset of the rectangle, defaults to 0.
	* @param alp	Alpha value of the rectangle, defaults to 0.
	* @return		A reference to the newly drawn rectangle.
	**/
	public static function rect(tgt:Sprite,col:String,wid:Number,hei:Number,xps:Number=0,yps:Number=0,alp:Number=1):Sprite {
		var rct:Sprite = new Sprite();
		rct.x = xps;
		rct.y = yps;
		rct.graphics.beginFill(uint('0x'+col),alp);
		rct.graphics.drawRect(0,0,wid,hei);
		tgt.addChild(rct);
		return rct;
	};


	/** 
	* Try setting a certain property of a displayobject. 
	*
	* @param obj	The displayobject to update.
	* @param prp	The property to update.
	* @param val	The new value of the property.
	**/
	public static function set(obj:DisplayObject,prp:String,val:Object):void {
		try {
			obj[prp] = val;
		} catch (err:Error) {}
	};


	/**
	* Try resizing a certain displayobject.
	*
	* @param obj	The displayobject to resize.
	* @param wid	New width of the object.
	* @param hei	New height of the object.
	**/
	public static function size(obj:DisplayObject,wid:Number,hei:Number):void {
		try {
			obj.width = Math.round(wid);
			obj.height = Math.round(hei);
		} catch (err:Error) {}
	};


	/** 
	* Draw a textfield on stage.
	*
	* @param tgt	Displayobject to add the textfield to.
	* @param txt	Text string to print.
	* @param col	Color of the text.
	* @param siz	Font size, defaults to 12.
	* @param fnt	Font family, defaults to 'Arial'.
	* @param mtl	Is the textfeld multilined, defaults to false.
	* @param wid	If a textfield is multilined, this is the width.
	* @param xps	X offset of the textfield,defaults to 0.
	* @param yps	Y offset of the textfield, defaults to 0.
	* @param ats	Autosize text alignment.
	*
	* @return		A reference to the textfield.
	**/
	public static function text(tgt:Sprite,txt:String,col:String,siz:Number=12,fnt:String='Arial',
		mtl:Boolean=false,wid:Number=100,xps:Number=0,yps:Number=0,ats:String="left"):TextField {
		var tfd:TextField = new TextField();
		var fmt:TextFormat = new TextFormat();
		tfd.autoSize = 'left';
		tfd.selectable = false;
		if(mtl) { 
			tfd.width = wid;
			tfd.multiline = true;
			tfd.wordWrap = true;
		} else { 
			tfd.autoSize = ats;
		}
		tfd.x = xps;
		tfd.y = yps;
		fmt.font = fnt;
		fmt.color = uint('0x'+col);
		fmt.size = siz;
		fmt.underline = false;
		tfd.defaultTextFormat = fmt;
		tfd.text = txt;
		tgt.addChild(tfd);
		return tfd;
	};


}


}