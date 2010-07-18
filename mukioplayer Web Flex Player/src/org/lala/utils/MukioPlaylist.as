package org.lala.utils 
{
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	
	import org.lala.events.MukioPlaylistEvent;
	/**
	 * ...
	 * @author 
	 */
	public class MukioPlaylist extends EventDispatcher
	{
		private var lstArr:Array = [];
		public function MukioPlaylist(target:IEventDispatcher = null) 
		{
		}
		public function add(itm:Object):void
		{
			var obj:Object = {
				'file':itm['file'],
				'cfile':itm['cfile'],
				'vid':itm['vid'],
				'cid':itm['cid'],
				'title':itm['title'],
				'ptitle':itm['ptitle'],
				'upper':itm['upper'],
				'date':itm['date'],
				'htmlref':itm['htmlref']
			}
			lstArr.push(obj);
			dispatchEvent(new MukioPlaylistEvent(MukioPlaylistEvent.ADDITEM,obj));
		}
		
		public function clear():void
		{
			lstArr = [];
		}
	}

}