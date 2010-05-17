/**
* Parse JWPlayer specific feed content into playlists.
**/
package com.jeroenwijering.parsers {


import com.jeroenwijering.utils.Strings;


public class JWParser {


	/** Prefix for the JW Player namespace. **/
	private static const PREFIX:String = 'jwplayer';


	/**
	* Parse a feedentry for JWPlayer content.
	* 
	* @param obj	The XML object to parse.
	* @param itm	The playlistentry to amend the object to.
	* @return		The playlistentry, amended with the JWPlayer info.
	* @see			ASXParser
	* @see			ATOMParser
	* @see			RSSParser
	* @see			SMILParser
	* @see			XSPFParser
	**/
	public static function parseEntry(obj:XML,itm:Object):Object {
		for each (var i:XML in obj.children()) {
			if(i.namespace().prefix == JWParser.PREFIX) {
				itm[i.localName()] = Strings.serialize(i.text().toString());
			}
		}
		return itm;
	}


}


}