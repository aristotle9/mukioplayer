/**
* Pick random array indexes without having the same picked twice times.
**/
package com.jeroenwijering.utils {


public class Randomizer {


	/** A reference of the original array. **/
	private var original:Array;
	/** An array with the items to play. **/
	private var todo:Array;
	/** An array with the items already done. **/
	private var done:Array;


	/**
	* Constructor.
	*
	* @param len	Length of the list to randomize.
	**/
	public function Randomizer(len:Number):void {
		original = new Array();
		todo = new Array();
		done = new Array();
		for(var i:Number=0; i<len; i++) {
			original.push(i);
		}
	};


	/** Returns a random number below the length given. **/
	public function pick():Number {
		if(todo.length == 0) {
			for(var k:Number=0; k<original.length; k++) {
				todo.push(k);
			}
		}
		var ran:Number = Math.floor(Math.random()*todo.length);
		var idx:Number = todo[ran];
		done.push(todo.splice(ran,1)[0]);
		return idx;
	};


	/** Return the number of items still in the buffer. **/
	public function get length():Number {
		return todo.length;
	}


	/** Go one item back in the buffer. **/
	public function back():Number {
		if(done.length < 2) {
			return pick();
		} else { 
			todo.push(done.pop());
			return done[done.length-1];
		}
	};


}


}