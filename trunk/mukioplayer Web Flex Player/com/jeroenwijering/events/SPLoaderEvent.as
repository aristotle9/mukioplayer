/**
* Definition of the events fired by the SPLoader, which loads the skin and plugins SWF.
* 
* These events are not exposed through the API.
**/
package com.jeroenwijering.events {


import flash.events.Event;


public class SPLoaderEvent extends Event {


	/** Definition for the event that indicates the skin is loaded. **/
	public static var SKIN:String = "SKIN";
	/** Definition for the event that indicates all plugins are loaded. **/
	public static var PLUGINS:String = "PLUGINS";


	/**
	* Constructor; defines which event is fired.
	*
	* @param typ	The definition of the event.
	* @param dat	An object with all associated data.
	**/
	public function SPLoaderEvent(typ:String,bbl:Boolean=false,ccb:Boolean=false):void {
		super(typ, bbl, ccb);
	};


};


}