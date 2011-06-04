package org.lala.utils 
{
	/**
	 * ...
	 * @author aristotle9
	 */
	public class YKParser
	{
		private var key:String;
		private var fileId:String;
		private var type:String;
		public function YKParser(data:Object,typ:String) 
		{
			type = typ;
			key = getKey(data.key1, data.key2);
			fileId = getFileId(data['streamfileids'][type],data['seed']);
		}
		
		public function getUrl(n:int):String
		{
			var hex:String = n.toString(16);
			if(hex.length == 1)
			{
				hex = '0' + hex;
				hex = hex.toUpperCase();
			}
			return 'http://f.youku.com/player/getFlvPath/sid/00_00/st/' + type + '/fileid/' + fileId.substr(0,8) + hex + fileId.substr(10) + '?K=' + key;

		}

		private function getKey(key1:String, key2:String):String
		{
			var appendkey:int = parseInt(key1,16);
			appendkey ^= 0xA55AA5A5;
			return key2 + appendkey.toString(16);
		}
		
		private function getMixString(seedstr:String):String
		{
			var seed:int = parseInt(seedstr);
			var mixed:String = '';
			var source:String = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ/\\:._-1234567890";
			var len:int = source.length;
			for (var i:int = 0;i < len ;i++ )
			{
				seed = (seed * 211 + 30031) % 65536;
				var index:int = Math.floor(seed / 65536 * source.length);
				var c:String = source.charAt(index);
				mixed += c;
				source = source.replace(c,'');
			}
			return mixed;
		}
		
		private function getFileId(fileId:String, seed:String):String
		{
			var mixed:String = getMixString(seed);
			var ids:Array = fileId.split('*');
			var realId:String = '';
			var length:int = ids.length - 1;
			for (var i:int = 0;i < length ;i ++ )
			{
				var id:int = parseInt(ids[i]);
				realId += mixed.charAt(id);
			}
			return realId;
		}
		
		public function get KEY():String
		{
			return key;
		}
		public function get FILEID():String
		{
			return fileId;
		}
		public function get TYPE():String
		{
			return type;
		}
		
	}

}