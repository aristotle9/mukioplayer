package org.lala.utils 
{
	import com.jeroenwijering.utils.Strings;
	/**
	 * ...
	 * @author 
	 */
	public class NicoParser
	{
		
		public function NicoParser() 
		{
			
		}
		public static function parse(xml:XML):Array
		{
			var i:int=0;
			var resArr:Array=[];
			var xmllist:XMLList = xml.descendants('chat');
			//trace("inner xmllist : " + xmllist.length());
			for (i = 0; i < xmllist.length(); i++)
			{
				//trace("itm i : " + i);
				var itm:*= xmllist[i];
				
				if (itm.@deleted != 1)
				{
					var obj:Object =
					{
	//					anonymity:itm.@anonymity,
						'date':itm.@date,
						'mail':itm.@mail,
						'id':itm.@no,
	//					thread:itm.@thread,
	//					'user_id':itm.@user_id,
						'stime':int(itm.@vpos)/1000,
						'text':itm.toString().replace(/(\/n|\\n)/g, "\n"),
						'border':false
					};
					obj['mode'] = getMode(obj.mail);
					obj['color'] = getColor(obj.mail);
					obj['size'] = getSize(obj.mail);
					obj['width'] = Strings.strWidth(obj['text'], obj['size']);
					obj['height'] = Strings.strHeight(obj['text'], obj['size']);
					
					//trace("obj['mode'] : " + obj['mode']);
					//trace("obj['color'] : " + obj['color']);
					//trace("obj['size'] : " + obj['size']);
					//trace("obj.mail : " + obj.mail);
					//trace("obj['text'] : " + obj['text']);
					
					resArr.push(obj);
				}
			}
			trace("resArr : " + resArr.length);
			return resArr;
		}
		public static function getMode(mail:String):int
		{
			var mode:int = 1;
			
			var modestr:String = '';
			var arr:Array = mail.match(/(shita|ue|naka)/);
			
			if (arr)
			{
				modestr = arr[1];
			}
			
			switch(modestr)
			{
				case 'shita':
					mode = 4;
					break;
				case 'ue':
					mode = 5;
					break;
			}
			
			return mode;
		}
		public static function getSize(mail:String):int
		{
			var size:int = 16;
			
			var sizestr:String = '';
			var arr:Array = mail.match(/(big|medium|small)/);
			
			if (arr)
			{
				sizestr = arr[1];
			}

			switch(sizestr)
			{
                case "small":
                {
                    size = 13;
                    break;
                }
                case "big":
                {
                    size = 19;
                    break;
                }
			}
				
			return size;
		}
		public static function getColor(mail:String):int
		{
			var clr:int = 0xffffff;
			
			var clrstr:String = '';
			var arr:Array =	mail.match(/(white|red|pink|orange|yellow|green|cyan|blue|purple|niconicowhite|white2|truered|red2|passionorange|orange2|madyellow|yellow2|elementalgreen|green2|marineblue|blue2|nobleviolet|purple2|black|\#[0-9a-f]{6})/);
			
			if (arr)
			{
				clrstr = arr[1];
			}

			switch(clrstr)
			{
                case "red":
                {
                    clr = 16711680;
                    break;
                }
                case "pink":
                {
                    clr = 16744576;
                    break;
                }
                case "orange":
                {
                    clr = 16763904;
                    break;
                }
                case "yellow":
                {
                    clr = 16776960;
                    break;
                }
                case "green":
                {
                    clr = 65280;
                    break;
                }
                case "cyan":
                {
                    clr = 65535;
                    break;
                }
                case "blue":
                {
                    clr = 255;
                    break;
                }
                case "purple":
                {
                    clr = 12583167;
                    break;
                }
                case "niconicowhite":
                {
                    clr = 13421721;
                    break;
                }
                case "white2":
                {
                    clr = 13421721;
                    break;
                }
                case "truered":
                {
                    clr = 13369395;
                    break;
                }
                case "red2":
                {
                    clr = 13369395;
                    break;
                }
                case "passionorange":
                {
                    clr = 16737792;
                    break;
                }
                case "orange2":
                {
                    clr = 16737792;
                    break;
                }
                case "madyellow":
                {
                    clr = 10066176;
                    break;
                }
                case "yellow2":
                {
                    clr = 10066176;
                    break;
                }
                case "elementalgreen":
                {
                    clr = 52326;
                    break;
                }
                case "green2":
                {
                    clr = 52326;
                    break;
                }
                case "marineblue":
                {
                    clr = 3407868;
                    break;
                }
                case "blue2":
                {
                    clr = 3407868;
                    break;
                }
                case "nobleviolet":
                {
                    clr = 6697932;
                    break;
                }
                case "purple2":
                {
                    clr = 6697932;
                    break;
                }
                case "black":
                {
                    clr = 0;
                    break;
                }
                default:
                {
					if (clrstr.match(/^\#[0-9a-f]{6}/))
					{
						clr=Number(clrstr.replace(/^\#/, "0x"));
					}
                    break;
                }
			}
			
			return clr;
		}
		
	}

}