/**
* This is the base model class all models must extent.
**/
package com.jeroenwijering.models {


import com.jeroenwijering.events.*;
import com.jeroenwijering.player.Model;
import com.jeroenwijering.utils.Stretcher;

import flash.display.Sprite;


public class AbstractModel extends Sprite {


	/** Reference to the player Model. **/
	protected var model:Model
	/** Reference to the currently active playlistitem. **/
	protected var item:Object;
	/** The current position inside the file. **/
	protected var position:Number;


	/**
	* Constructor; sets up reference to the MVC model.
	*
	* @param mod	The model of the player MVC triad.
	* @see Model
	**/
	public function AbstractModel(mod:Model):void {
		model = mod;
		mouseEnabled = false;
	};


	/**
	* Load an item into the model.
	*
	* @param itm	The currently active playlistitem.
	**/
	public function load(itm:Object):void {
		item = itm;
		position = 0;
	};


	/** Pause playback of the item. **/
	public function pause():void {};


	/** Resume playback of the item. **/
	public function play():void {};


	/** Handle a resize of the display. **/
	public function resize():void {
		Stretcher.stretch(this,
			model.config['width'],
			model.config['height'],
			model.config['stretching']
		);
	};


	/**
	* Seek to a certain position in the item.
	*
	* @param pos	The position in seconds.
	**/
	public function seek(pos:Number):void {
		position = pos;
	};


	/** Stop playing and loading the item. **/
	public function stop():void {};


	/** 
	* Change the playback volume of the item.
	*
	* @param vol	The new volume (0 to 100).
	**/
	public function volume(vol:Number):void {};


};


}