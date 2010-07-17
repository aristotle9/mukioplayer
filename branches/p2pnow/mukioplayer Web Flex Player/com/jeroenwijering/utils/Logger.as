package com.jeroenwijering.utils {


import flash.events.StatusEvent;
import flash.external.ExternalInterface;
import flash.net.LocalConnection;
import flash.net.SharedObject;
import flash.system.System;


/**
* <p>Utility class for logging debug messages. It supports the following logging systems:</p>
* <ul>
* <li>The standalone Arthropod AIR application.</li>
* <li>The Console.log function built into Firefox/Firebug.</li>
* <li>The tracing sstem built into the debugging players.</li>
* </ul>
*
* @todo implement log levels.
**/
public class Logger {


	/** Constant defining the Arthropod output type. **/
	public static const ARTHROPOD:String = "arthropod";
	/** LocalConnection instance arthropod use. **/
	private static const CONNECTION:LocalConnection = new LocalConnection();
	/** Arthropod connection name. **/
	private static const CONNECTION_NAME:String = 
		'app#com.carlcalderon.Arthropod.161E714B6C1A76DE7B9865F88B32FCCE8FABA7B5.1:arthropod';
	/** Constant defining the Firefox/Firebug console output type. **/
	public static const CONSOLE:String = "console";
	/** Constant defining there's no output. **/
	public static const NONE:String = "none";
	/** Constant defining the Flash tracing output type. **/
	public static const TRACE:String = "trace";


	/** Latest output position. **/
	private static var _output:String = Logger.NONE;


	/**
	* Log a message to the output system.
	*
	* @param message	The message to send forward. Arrays and objects are automatically chopped up.
	* @param type		The type of message; is capitalized and encapsulates the message.
	**/
	public static function log(message:*,type:String="log"):void {
		if(message == undefined) {
			send(type.toUpperCase());
		} else if (message is String) {
			send(type.toUpperCase()+' ('+message+')');
		} else if (message is Boolean || message is Number || message is Array) {
			send(type.toUpperCase()+' ('+message.toString()+')');
		} else {
			Logger.object(message,type);
		}
	};


	/** Explode an object for logging. **/
	private static function object(message:Object,type:String):void {
		var txt:String = type.toUpperCase()+' ({';
		for(var i:String in message) {
			if(message[i] is Object) { 
				txt += i+':'+message[i].toString()+', ';
			}
		}
		txt = txt.substr(0,txt.length-2);
		if(i) { txt += '})'; }
		Logger.send(txt);
	};


	/** 
	* Set output system to use for logging. The output is also saved in a cookie.
	*
	* @param put	System to use (ARTHROPOD, CONSOLE, TRACE or NONE).StatusEvent
	**/
	public static function set output(put:String):void {
		if(put == ARTHROPOD) {
			CONNECTION.allowInsecureDomain('*');
			CONNECTION.addEventListener(StatusEvent.STATUS,Logger.status);
		}
		SharedObject.getLocal('com.jeroenwijering','/').data['debug'] = put;
		Logger._output = put;
	};


	/** 
	* Get output system to use for logging.
	*
	* @return	System to use (ARTHROPOD, CONSOLE, TRACE or NONE).
	**/
	public static function get output():String {
		return Logger._output;
	};


	/** Send the messages to the output system. **/
	private static function send(text:String):void {
		switch(Logger._output) {
			case ARTHROPOD:
				CONNECTION.send(CONNECTION_NAME,'debug','CDC309AF',text,0xCCCCCC);
				break;
			case CONSOLE:
				ExternalInterface.call('console.log',text);
				break;
			case TRACE:
				trace(text);
				break;
			case NONE:
				break;
			default:
				ExternalInterface.call(Logger._output,text);
				break;
		}
	};


	/** Manage the status call of localconnection. **/
	private static function status(evt:StatusEvent):void {};


}


}