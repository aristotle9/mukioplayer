package org.lala.models
{
	/**
	 * 将qqvid转化为flv地址的类
	 * @author ... 
	 */
  public class QQTool extends Object
  {

    public function QQTool()
    {
      return;
    }// end function

    public static function getImgUrl(param1:String, param2:String = ".jpg") : String
    {
      var _loc_3:Number = NaN;
      var _loc_4:Number = NaN;
      var _loc_5:Number = NaN;
      var _loc_6:* = undefined;
      var _loc_7:* = undefined;
      var _loc_8:* = undefined;
      var _loc_9:String = null;
      var _loc_10:Number = NaN;
      _loc_3 = NaN;
      _loc_4 = NaN;
      _loc_5 = NaN;
      _loc_6 = 4294967295 + 1;
      _loc_7 = 10000 * 10000;
      _loc_8 = param1;
      _loc_9 = "";
      _loc_10 = 0;
      _loc_4 = 0;
      while (_loc_4 < _loc_8.length)
      {
        
        _loc_5 = _loc_8.charCodeAt(_loc_4);
        _loc_10 = _loc_10 * 32 + _loc_10 + _loc_5;
        if (_loc_10 >= _loc_6)
        {
          _loc_10 = _loc_10 % _loc_6;
        }
        _loc_4 = _loc_4 + 1;
      }
      _loc_3 = _loc_10 % _loc_7;
      _loc_9 = "http://vpic.video.qq.com/" + _loc_3 + "/" + param1 + param2;
      return _loc_9;
    }// end function

    private static function getTot(param1:String, param2:Number) : Number
    {
      var _loc_3:Number = NaN;
      var _loc_4:Number = NaN;
      var _loc_5:* = undefined;
      var _loc_6:Number = NaN;
      _loc_3 = NaN;
      _loc_4 = NaN;
      _loc_5 = param1;
      _loc_6 = 0;
      _loc_3 = 0;
      while (_loc_3 < _loc_5.length)
      {
        
        _loc_4 = _loc_5.charCodeAt(_loc_3);
        _loc_6 = _loc_6 * 32 + _loc_6 + _loc_4;
        if (_loc_6 >= param2)
        {
          _loc_6 = _loc_6 % param2;
        }
        _loc_3 = _loc_3 + 1;
      }
      return _loc_6;
    }// end function

    public static function getDefaultFlvUrl(param1:String) : String
    {
      var _loc_2:* = undefined;
      var _loc_3:* = undefined;
      var _loc_4:* = undefined;
      _loc_2 = 4294967295 + 1;
      _loc_3 = 10000 * 10000;
      _loc_4 = getTot(param1, _loc_2) % _loc_3;
      return "http://v.video.qq.com/" + _loc_4 + "/" + param1 + ".flv";
    }// end function

    public static function getFlvUrl(param1:String, param2:uint) : String
    {
      var _loc_3:String = null;
      var _loc_4:Number = NaN;
      var _loc_5:Number = NaN;
      var _loc_6:Number = NaN;
      var _loc_7:Number = NaN;
      var _loc_8:String = null;
      var _loc_9:String = null;
      var _loc_10:String = null;
      var _loc_11:Number = NaN;
      var _loc_12:Number = NaN;
      var _loc_13:* = undefined;
      var _loc_14:* = undefined;
      var _loc_15:Number = NaN;
      var _loc_16:* = undefined;
      var _loc_17:* = undefined;
      var _loc_18:* = undefined;
      _loc_3 = null;
      _loc_4 = NaN;
      _loc_5 = NaN;
      _loc_6 = NaN;
      _loc_7 = NaN;
      _loc_8 = null;
      _loc_9 = "";
      _loc_10 = "";
      _loc_11 = 256;
      _loc_12 = 256;
      _loc_13 = _loc_11 * _loc_12;
      _loc_14 = param1;
      _loc_15 = 0;
      _loc_4 = 0;
      while (_loc_4 < _loc_14.length)
      {
        
        _loc_5 = 4294967295 + 1;
        _loc_4 = _loc_4 + 1;
      }
      _loc_16 = getTot(param1, _loc_5) % _loc_13;
      _loc_17 = Math.floor(_loc_16 / _loc_11);
      _loc_18 = Math.floor(_loc_16 % _loc_12);
      if (param2 == 1)
      {
        _loc_10 = "http://vkp.video.qq.com";
      }
      if (param2 == 2)
      {
        _loc_10 = "http://vhot.video.qq.com";
      }
      if (param2 == 4)
      {
        _loc_10 = "http://vhot1.video.qq.com";
      }
      if (param2 == 5)
      {
        _loc_10 = "http://vhot2.video.qq.com";
      }
      if (param2 == 11)
      {
        _loc_10 = "http://vcm1.video.qq.com";
      }
      if (param2 == 12)
      {
        _loc_10 = "http://vcm2.video.qq.com";
      }
      if (param2 == 13)
      {
        _loc_10 = "http://vcm3.video.qq.com";
      }
      if (param2 == 14)
      {
        _loc_10 = "http://vcm3.video.qq.com";
      }
      if (param2 == 15)
      {
        _loc_10 = "http://vcm4.video.qq.com";
      }
      if (param2 == 100)
      {
        _loc_10 = "http://vhotws.video.qq.com";
      }
      if (param2 == 101)
      {
        _loc_10 = "http://vtopws.video.qq.com";
      }
      if (param2 == 105)
      {
        _loc_10 = "http://vkpws.video.qq.com";
      }
      if (param2 == 106)
      {
        _loc_10 = "http://vexws.video.qq.com";
      }
      if (param2 == 110)
      {
        _loc_10 = "http://im.dnion.videocdn.qq.com";
      }
      if (param2 == 111)
      {
        _loc_10 = "http://important.dnion.videocdn.qq.com";
      }
      if (param2 == 17500)
      {
        _loc_10 = "http://im.dnion.videocdn.qq.com";
      }
      if (_loc_10 != "")
      {
        _loc_9 = _loc_10 + "/flv/" + _loc_17 + "/" + _loc_18 + "/" + param1 + ".flv";
      }
      if (param2 == 3 || param2 == 200 || param2 == 201 || param2 == 202 || param2 == 300 || param2 == 203 || param2 == 204 || param2 == 50)
      {
        _loc_7 = 10000 * 10000;
        _loc_14 = param1;
        _loc_6 = getTot(param1, _loc_5) % _loc_7;
        _loc_8 = "";
        switch(param2)
        {
          case 3:
          {
            _loc_8 = "http://vhot.qqvideo.tc.qq.com/";
            break;
          }
          case 200:
          {
            _loc_8 = "http://vhot2.qqvideo.tc.qq.com/";
            break;
          }
          case 201:
          {
            _loc_8 = "http://vtop.qqvideo.tc.qq.com/";
            break;
          }
          case 202:
          {
            _loc_8 = "http://qzone.qqvideo.tc.qq.com/";
            break;
          }
          case 300:
          {
            _loc_8 = "http://ap.video.qq.com/";
            break;
          }
          case 203:
          {
            _loc_8 = "http://vlive.qqvideo.tc.qq.com/";
            break;
          }
          case 204:
          {
            _loc_8 = "http://web.qqvideo.tc.qq.com/";
            break;
          }
          case 50:
          {
            _loc_8 = "http://vtopway.video.qq.com/";
            break;
          }
          default:
          {
            break;
            break;
          }
        }
        _loc_9 = _loc_8 + _loc_6 + "/" + param1 + ".flv";
      }
      return _loc_9;
    }// end function

  }
}
