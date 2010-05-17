/**
* Parse a MRSS group into a playlistitem (used in RSS and ATOM).
**/
package com.jeroenwijering.parsers {


import com.jeroenwijering.utils.Strings;


public class MediaParser {


	/** Prefix for the JW Player namespace. **/
	private static const PREFIX:String = 'media';


	/**
	* Parse a feeditem for Yahoo MediaRSS extensions.
	* The 'content' and 'group' elements can nest other MediaRSS elements.
	* 
	* @param obj	The entire MRSS XML object.
	* @param itm	The playlistentry to amend the object to.
	* @return		The playlistentry, amended with the MRSS info.
	* @see			ATOMParser
	* @see			RSSParser
	**/
	public static function parseGroup(obj:XML,itm:Object):Object {
		for each (var i:XML in obj.children()) {
			if(i.namespace().prefix == MediaParser.PREFIX) {
				switch(i.localName().toLowerCase()) {
					case 'content':
						if(!ytp) {
							itm['file'] = i.@url.toString();
						}
						if(i.@duration) {
							itm['duration'] = Strings.seconds(i.@duration.toString());
						}
						if(i.@start) {
							itm['start'] = Strings.seconds(i.@start.toString());
						}
						if(i.children().length() > 0) {
							itm = MediaParser.parseGroup(i,itm);
						}
						if(i.@width && i.@bitrate) {
							if(!itm.levels) {
								itm.levels = new Array();
							}
							itm.levels.push({
								width:i.@width.toString(),
								bitrate:i.@bitrate.toString(),
								url:i.@url.toString()
							});
						}
						break;
					case 'title':
						itm['title'] = i.text().toString();
						break;
					case 'description':
						itm['description'] = i.text().toString();
						break;
					case 'keywords':
						itm['tags'] = i.text().toString();
						break;
					case 'thumbnail':
						itm['image'] = i.@url.toString();
						break;
					case 'credit':
						itm['author'] = i.text().toString();
						break;
					case 'player':
						if(i.@url.indexOf('youtube.com') > 0) {
							var ytp:Boolean = true;
							itm['file'] = i.@url.toString();
						}
						break;
					case 'group':
						itm = MediaParser.parseGroup(i,itm);
						break;
					}
			}
		}
		return itm;
	}


}


}