/**
* Parse an XSPF feed and translate it to a feedarray.
**/
package com.jeroenwijering.parsers {


import com.jeroenwijering.parsers.JWParser;
import com.jeroenwijering.parsers.MediaParser;
import com.jeroenwijering.utils.Strings;


public class XSPFParser {


	/** Parse an XSPF playlist for feeditems. **/
	public static function parse(dat:XML):Array {
		var arr:Array = new Array();
		for each (var i:XML in dat.children()) {
			if (i.localName().toLowerCase() == 'tracklist') {
				for each (var j:XML in i.children()) {
					arr.push(XSPFParser.parseItem(j));
				}
			}
		}
		return arr;
	};


	/** Translate XSPF item to playlist item. **/
	public static function parseItem(obj:XML):Object {
		var itm:Object =  new Object();
		for each (var i:XML in obj.children()) {
			if(!i.localName()) { break; }
			switch(i.localName().toLowerCase()) {
				case 'location':
					itm['file'] = i.text().toString();
					break;
				case 'title':
					itm['title'] = i.text().toString();
					break;
				case 'annotation':
					itm['description'] = i.text().toString();
					break;
				case 'info':
					itm['link'] = i.text().toString();
					break;
				case 'image':
					itm['image'] = i.text().toString();
					break;
				case 'creator':
					itm['author'] = i.text().toString();
					break;
				case 'duration':
					itm['duration'] = Strings.seconds(i.text());
					break;
				case 'meta':
					itm[i.@rel] = i.text().toString();
					break;
			}
		}
		itm = MediaParser.parseGroup(obj,itm);
		itm = JWParser.parseEntry(obj,itm);
		return itm;
	};


}


}