package org.lala.utils
{
    import flash.display.DisplayObject;

    /** 应用程序配置,从外部xml文件加载 **/
    public class CommentXMLConfig
    {
        private var _xml:XML;
        /** 加载地址 **/
        private var _load:String;
        private var _send:String;
        private var _onHost:String;
        private var _root:DisplayObject;
        private var _gateway:String;
        private var _rtmp:String;
		
        public function CommentXMLConfig(_r:DisplayObject)
        {
            _root = _r;
        }
        
        public function init(xml:XML):void
        {
            _xml = xml;
            _load = _xml.server.load;
            _send = _xml.server.send;
            _gateway = _xml.server.gateway;
            _onHost = _xml.server.onhost;
			_rtmp = String(_xml.server.rtmp);
            // ...
        }
        public function get initialized():Boolean
        {
            if(_xml)
            {
                return true;
            }
            return false;
        }
        public function getCommentFileURL(id:String):String
        {
            var result:String = _load.replace(/\{\$id\}/ig,id);
            var random:String = 'r=' + Math.ceil(Math.random() * 1000);
            if(result.lastIndexOf('?') == -1)
            {
                result += '?' + random;
            }
            else
            {
                result += '&' + random;
            }
            return result;
        }
        public function getCommentPostURL(id:String):String
        {
            return _send.replace(/\{\$id\}/ig,id);
        }
        public function get playerURL():String
        {
            return _root.loaderInfo.url;
        }
        public function getConfURL(fileName:String='conf.xml'):String
        {
            return playerURL.replace(/[^\/]+.swf.*/igm,'') + fileName;
        }

        /** amf网关 **/
        public function get gateway():String
        {
            return _gateway;
        }
        /** 使用mukioplayer规定的参数来路由 **/
        public function get isOnHost():Boolean
        {
            return _onHost.length != 0;
        }
		/** 消息服务器 **/
		public function get rtmp():String
		{
			return _rtmp;
		}


    }
}