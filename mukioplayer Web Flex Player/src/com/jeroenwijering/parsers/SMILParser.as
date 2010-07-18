/**
* Parse an SMIL feed and translate it to a feedarray.
**/
package com.jeroenwijering.parsers {


import com.jeroenwijering.parsers.JWParser;
import com.jeroenwijering.utils.Strings;


public class SMILParser {


	/** Parse an SMIL playlist for feeditems. **/
	public static function parse(dat:XML):Array {
		var arr:Array = new Array();
		var elm:XML = dat.children()[1].children()[0];
		if(elm.localName().toLowerCase() == 'seq') {
			for each (var i:XML in elm.children()) {
				arr.push(SMILParser.parseSeq(i));
			}
		} else {
			arr.push(SMILParser.parsePar(elm));
		}
		return arr;
	};


	/** Translate SMIL sequence item to playlistitem. **/
	public static function parseSeq(obj:XML):Object {
		var itm:Object =  new Object();
		switch (obj.localName().toLowerCase()) {
			case 'par':
				itm = SMILParser.parsePar(obj);
				break;
			case 'img':
			case 'video':
			case 'audio':
				itm = SMILParser.parseAttributes(obj,itm);
				break;
			default:
				break;
		}
		return itm;
	};


	/** Translate a SMIL par group to playlistitem **/
	public static function parsePar(obj:XML):Object {
		var itm:Object =  new Object();
		for each (var i:XML in obj.children()) {
			switch (i.localName().toLowerCase()) {
				case 'anchor':
					itm['link'] = i.@href.toString();
					break;
				case 'img':
					if(itm['file']) {
						itm['image'] = i.@src.toString();
						break;
					} else {
						itm = SMILParser.parseAttributes(i,itm);
					}
					break;
				case 'video':
				case 'audio':
					itm = SMILParser.parseAttributes(i,itm);
					break;
				default:
					break;
			}
		}
		itm = JWParser.parseEntry(obj,itm);
		return itm;
	};


	/** Get attributes from a SMIL element. **/
	public static function parseAttributes(obj:Object,itm:Object):Object {
		for(var i:Number=0; i<obj.attributes().length(); i++) {
			var att:String = obj.attributes()[i].name().toString();
			switch(att) {
				case 'begin':
					itm['start'] = Strings.seconds(obj.@begin.toString());
					break;
				case 'src':
					itm['file'] = obj.@src.toString();
					break;
				case 'dur':
					itm['duration'] = Strings.seconds(obj.@dur.toString());
					break;
				case 'alt':
					itm['description'] = obj.@alt.toString();
					break;
				default:
					itm[att] = obj.attributes()[i].toString();
					break;
			}
		}
		return itm;
	}

}


}