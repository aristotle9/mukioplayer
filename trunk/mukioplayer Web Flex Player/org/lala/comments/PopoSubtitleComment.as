package org.lala.comments 
{
	import flash.display.Sprite;
	import flash.text.TextField;
	import flash.text.TextFormat;
	
	/**
	 * subtitle entity for zoome,both top and bottom,more simple then other zoome style
	 * @author aristotle9
	 */
	public class PopoSubtitleComment extends Sprite
	{
		private var item:Object;//config data
		
		private var ttf:TextField;
		private var tf:TextFormat;//but
		
		public function PopoSubtitleComment(itm:Object) 
		{
			//copy config data
			item = {};
			for(var key :String in itm)
			{
				item[key] = itm[key];
			}
			
			init();
		}
		private function init():void
		{
			tf = getTextFormat();
			ttf = new TextField();
			ttf.autoSize = 'left';
			ttf.defaultTextFormat = tf;
			ttf.x = ttf.y = 0;
			ttf.text = item.text;
						
			addChild(ttf);
		}
		
		override public function get width():Number { return ttf.width; }
		override public function get height():Number { return ttf.height; }
		
		override public function set width(value:Number):void 
		{
			super.width = value;
		}
		
		private function getTextFormat():TextFormat
		{
			var tmp:TextFormat = new TextFormat();
			
			tmp.size = item.size;
			tmp.color = item.color;
			
			var tStyle:String = item.tStyle;
			
			if (tStyle.match('italic'))
				tmp.italic = true;
				
			if (tStyle.match('bold'))
				tmp.bold = true;
				
			if (tStyle.match('underline'))
				tmp.underline = true;

			return tmp;
		}
		
	}

}