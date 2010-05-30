package com.jeroenwijering.utils {


import com.jeroenwijering.utils.Strings;
import org.lala.utils.CommentGetter;

import flash.events.Event;
import flash.events.EventDispatcher;
import flash.display.Sprite;
import flash.net.SharedObject;
import flash.net.URLRequest;
import flash.net.URLLoader;

//import flash.events.InvokeEvent;//for air 
//import flash.desktop.NativeApplication;//

/**
* <p>This class loads application configuration data from respectively:</p>
* <ul>
* <li>An XML file (which can be set with the "config" flashvar).</li>
* <li>Shared objects (Actionscripts' cookies).</li>
* <li>Flashvars.</li>
* </ul>
* <p>This configuration data is pushed as key:value pairs in an opject handed over by the application class.</p>
* <p>Values are converted to strings/numbers/booleans and asfunction injection attempts are filtered.</p>
**/
public class Configger extends EventDispatcher {


	/** Reference to a display object to get flashvars from. **/
	private var reference:Sprite;
	/** Reference to the config object. **/
	private var config:Object;
	/** XML loading object reference **/
	private var loader:URLLoader;


	/**
	* Constructor.
	* 
	* @param ref	A reference Sprite that is placed on the stage; needed to access the flashvars.
	**/
	public function Configger(ref:Sprite):void {
		reference = ref;
	};


	/**
	* Start the variables loading process.
	* 
	* @param cfg	An object with key:value defaults; existing values are overwritten and new ones are added.
	**/
	public function load(cfg:Object):void {
		config = cfg;
		loadCookies();
	};


	/** Load configuration data from flashcookie. **/
	private function loadCookies():void {
		try{
			var cookie:SharedObject = SharedObject.getLocal('com.jeroenwijering','/');
			compareWrite(cookie.data);
		}
		catch(e:Error){}
		var xml:String = reference.root.loaderInfo.parameters['config'];
		if(xml) {
			loadXML(Strings.decode(xml));
		} else {
			loadFlashvars();
		}
	};


	/** Load configuration data from external XML file. **/
	private function loadXML(url:String):void {
		loader = new URLLoader();
		loader.addEventListener(Event.COMPLETE,xmlHandler);
		try {
			loader.load(new URLRequest(url));
		} catch (err:Error) {
			loadFlashvars();
		}
	};


	/** Parse the XML from external configuration file. **/
	private function xmlHandler(evt:Event):void {
		var dat:XML = XML(evt.currentTarget.data);
		var obj:Object = new Object();
		for each (var prp:XML in dat.children()) {
			obj[prp.name()] = prp.text();
		}
		compareWrite(obj);
			loadFlashvars();
	};


	/** Set config variables or load them from flashvars. **/
	private function loadFlashvars():void {
		compareWrite(reference.root.loaderInfo.parameters);
		try
		{
			CommentGetter.baseURL = reference.root.loaderInfo.url.split(/([\/]+)/)[2];
			//CONFIG::debugging
			//{
				trace(CommentGetter.baseURL);
			//}
		}
		catch (e:Error)
		{
			
		}
		//NativeApplication.nativeApplication.addEventListener(InvokeEvent.INVOKE,loadNativeApplicationArguments);
		dispatchEvent(new Event(Event.COMPLETE));
	};
	
	//private function loadNativeApplicationArguments(evt:InvokeEvent):void
	//{
		//var vrs:Array = evt.arguments as Array;
		//for (var i:int = 0; i < vrs.length; i++)
		//{
			//compareWrite(Strings.parseFlashvars(vrs[i]));
		//}
		//NativeApplication.nativeApplication.removeEventListener(InvokeEvent.INVOKE,loadNativeApplicationArguments);
		//dispatchEvent(new Event(Event.COMPLETE));
	//}


	/** Compare and save new items in config. **/
	private function compareWrite(obj:Object):void {
		for (var cfv:String in obj) {
			config[cfv.toLowerCase()] = Strings.serialize(obj[cfv.toLowerCase()]);
		}
	};


	/**
	* Save config parameter to cookie.
	*
	* @param prm	The parameter name.
	* @param val	The parameter value.
	**/
	public static function saveCookie(prm:String,val:Object):void {
		try {
			var cookie:SharedObject = SharedObject.getLocal('com.jeroenwijering','/');
			cookie.data[prm] = val;
			cookie.flush();
		} catch (err:Error) {}
	};


}


}