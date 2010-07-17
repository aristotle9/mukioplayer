package com.jeroenwijering.utils {


/**
* This class groups a couple of commonly used string operations.
**/
public class Strings {


	/** 
	* Unescape a string and filter "asfunction" occurences ( can be used for XSS exploits).
	* 
	* @param str	The string to decode.
	* @return 		The decoded string.
	**/
	public static function decode(str:String):String {
		if(str.indexOf('asfunction') == -1) {
			return unescape(str);
		} else {
			return '';
		}
	};


	/** 
	* Convert a number to a digital-clock like string. 
	*
	* @param nbr	The number of seconds.
	* @return		A MN:SS string.
	**/
	public static function digits(nbr:Number):String {
		var min:Number = Math.floor(nbr/60);
		var sec:Number = Math.floor(nbr%60);
		var str:String = Strings.zero(min)+':'+Strings.zero(sec);
		return str;
	};


	/**
	* Convert a time-representing string to a number.
	* 
	* @param str	The input string. Supported are 00:03:00.1 / 03:00.1 / 180.1s / 3.2m / 3.2h
	* @return		The number of seconds.
	**/
	public static function seconds(str:String):Number {
		str = str.replace(',','.');
		var arr:Array = str.split(':');
		var sec:Number = 0;
		if (str.substr(-1) == 's') {
			sec = Number(str.substr(0,str.length-1));
		} else if (str.substr(-1) == 'm') {
			sec = Number(str.substr(0,str.length-1)) * 60;
		} else if(str.substr(-1) == 'h') {
			sec = Number(str.substr(0,str.length-1)) *3600;
		} else if(arr.length > 1) {
			sec = Number(arr[arr.length-1]);
			sec += Number(arr[arr.length-2]) * 60;
			if(arr.length == 3) {
				sec += Number(arr[arr.length-3]) *3600;
			}
		} else {
			sec = Number(str);
		}
		return sec;
	};


	/**
	* Basic serialization: string representations of booleans and numbers are returned typed;
	* strings are returned urldecoded.
	*
	* @param val	String value to serialize.
	* @return		The original value in the correct primitive type.
	**/
	public static function serialize(val:String):Object {
		if(val == null) {
			return null;
		} else if (val == 'true') {
			return true;
		} else if (val == 'false') {
			return false;
		} else if (isNaN(Number(val)) || val.length > 5) {
			return val;
		} else {
			return Number(val);
		}
	};


	/**
	* Strip HTML tags and linebreaks off a string.
	*
	* @param str	The string to clean up.
	* @return		The clean string.
	**/
	public static function strip(str:String):String {
		var tmp:Array = str.split("\n");
		str = tmp.join("");
		tmp = str.split("\r");
		str = tmp.join("");
		var idx:Number = str.indexOf("<");
		while(idx != -1) {
			var end:Number = str.indexOf(">",idx+1);
			end == -1 ? end = str.length-1: null;
			str = str.substr(0,idx)+" "+str.substr(end+1,str.length);
			idx = str.indexOf("<",idx);
		}
		return str;
	};


	/** 
	* Add a leading zero to a number.
	* 
	* @param nbr	The number to convert. Can be 0 to 99.
	* @ return		A string representation with possible leading 0.
	**/
	public static function zero(nbr:Number):String {
		if(nbr < 10) {
			return '0'+nbr;
		} else {
			return ''+nbr;
		}
	};
	
	/**
	 * cut a string
	 * @param str	The Source String
	 * @param n		The maxlength of result
	 * @return		a cutted string
	 **/
	public static function cut(str:String, n:Number = 17):String
	{
		var tmp:Array = str.split("\n");
		str = tmp.join("");
		tmp = str.split("\r");
		str = tmp.join("");
		if (str.length <= n)
		{
			return str;
		}
		else
		{
			//if (str.charCodeAt(n) > 0xa0)
			//{
				//n++;
			//}
			return str.substr(0, n)+'...';
		}
	}
	public static function strWidth(str:String,size:Number):Number
	{
		var arr:Array=str.split(/(\r|\n)/g);
		var brr:Array=arr.map(function(item:*, index:int, array:Array):Object
												  {
													  return { 'len':String(item).length };// Strings.naturalstrLength(item) };
												  });
		brr.sortOn('len', Array.NUMERIC);

		return brr[brr.length - 1].len * (size);
	}
	public static function strHeight(str:String,size:Number):Number
	{
		//var Height:int = 386;
		var rows:int = str.split('\r').length;
		return rows * size;

		//switch(size)
		//{
			//case 15:
				//return rows * Height / 19;
			 //break;
			//case 25:
				//return rows * Height / 14;
			 //break;
			//case 37:
				//return rows * Height / 10;
			 //break;
			//default:
				//trace("Size default : ");
				//return rows * size * 1.224;
			 //break;
		//}
	}
	public static function innerSize2(size:Number):Number
	{
		var Width:int = 538;

		switch(size)
		{
			case 10:
				return Width / 36;
				break;
			case 15:
				return Width / 28;
			 break;
			case 25:
				return Width / 20;
			 break;
			case 37:
				return Width / 14;
			 break;
			default:
				trace("Size default : ");
				
				return 0.8763 * size + 5.6904;//线性回归拟合
			 break;
		}
	}
	public static function innerSize(size:Number):Number
	{
		return size;
		var Width:int = 538;

		switch(size)
		{
			case 15:
				return Width / 33;
			 break;
			case 25:
				return Width / 21.5;
			 break;
			case 37:
				return Width / 14;
			 break;
			default:
				trace("Size default : ");
				
				return 1.0094 * size + 0.6776;//线性回归拟合
				//return 0.8763 * size + 5.6904;//线性回归拟合
			 break;
		}
	}
	public static function date(now:Date = null) : String
	{
		if(now == null)
			now = new Date();
			
		return now.getFullYear() + "-" + Strings.zero(now.getMonth() + 1) + "-" + Strings.zero(now.getDate()) + " " + Strings.zero(now.getHours()) + ":" + Strings.zero(now.getMinutes()) + ":" + Strings.zero(now.getSeconds());
	}// end function
	
	public static function parseFlashvars(str:String):Object
	{
		var arr :Array = str.split("&");
		if (arr.length == 1)
		{
			arr = str.split(" ");
		}
		var data:Object = { };
		for (var i:int = 0; i < arr.length; i++)
		{
			trace("arr[i] : " + arr[i]);
			var brr:Array = String(arr[i]).split('=');
			if (brr.length == 2)
			{
				data[brr[0]] = brr[1];
				trace("brr[0] : " + brr[0]);
				trace("brr[1] : " + brr[1]);
			}
		}
		return data;
	}

	//public static function naturalstrLength(str:String):Number
	//{
		//str = str.split(/(\r|\n)/g)[0];
		//var res:Number = 0;
		//for (var i:int = 0; i < str.length; i++)
		//{
			//var cd:int = str.charCodeAt(i);
			//if (0x2e80 <= cd && cd <= 0x9ffff)
			//{
				//res++;
			//}else if (0x41 <= cd && cd <= 0x5a)
			//{
				//res += 0.7;
			//}else
			//{
				//res += 0.6;
			//}
		//}
		//return res;
	//}
	public static function color(clr:int):String
	{
		var len:int = clr.toString(16).length;
		var str:String = '';
		if (len < 6)
		{
			str = '00000'.substr(0, 6 - len);
		}
		return  '#' + str + clr.toString(16);
	}


}


}