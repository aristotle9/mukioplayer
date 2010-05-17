/**
* Parse a SmoothStreamingMedia manifest for metadata, quality levels and chunks.
**/
package com.jeroenwijering.parsers {


import com.jeroenwijering.utils.Logger;
import com.jeroenwijering.utils.Strings;


public class SmoothParser {


	/** Push c elements in an array. **/
	public static function parseChunks(dat:XML):Array {
		var arr:Array = new Array();
		var stt:Number = 0;
		for each (var i:XML in dat.children()[0].children()) {
			if (i.localName().toLowerCase() == 'c') {
				var end:Number = Math.round((stt+Number(i.@d)/10000000)*100)/100;
				var obj:Object = {start:stt,end:end};
				arr.push(obj);
				stt = end;
			}
		}
		return arr;
	};


	/** Push StreamIndex attributes into an object. **/
	public static function parseIndex(dat:XML):Object {
		var obj:Object = new Object();
		obj['duration'] = Math.round(Number(dat.@Duration)/100000)/100;
		var att:XMLList = dat.children()[0].@*;
		for(var i:Number=0; i<att.length(); i++) {
			obj[att[i].name().toString().toLowerCase()] = att[i].toString();
		}
		return obj;
	};


	/** Push QualityLevel elements in an array. **/
	public static function parseLevels(dat:XML):Array {
		var arr:Array = new Array();
		for each (var i:XML in dat.children()[0].children()) {
			if (i.localName().toLowerCase() == 'qualitylevel') {
				var obj:Object = {
					bitrate:Number(i.@Bitrate.toString())/1000,
					width:Number(i.@Width.toString())/1,
					height:Number(i.@Height.toString())/1
				};
				Logger.log(obj);
				arr.push(obj);
			}
		}
		return arr;
	};


}


}