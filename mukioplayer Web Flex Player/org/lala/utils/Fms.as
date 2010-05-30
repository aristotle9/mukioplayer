package org.lala.utils
{
    import flash.events.*;
    import flash.net.*;
	import org.lala.events.FmsEvent;

    public class Fms extends EventDispatcher
    {
        private var username:String = "";
        private var path:String = "rtmp::1935/flvplayer2";
        //private var path:String = "rtmp://acfun.cn/flvplayer2";
        private var myShared:SharedObject;
        private var nc:NetConnection;
        private var roomID:String = "";

        public function Fms(param1:Object)
        {
            //path = "rtmp:/flvplayer2";
            username = "";
            roomID = "";
            roomID = param1.movieID;
            username = param1.username;
            nc = new NetConnection();
            nc.objectEncoding = ObjectEncoding.AMF0;
            nc.connect(path + "/" + param1.movieID, param1);
            nc.addEventListener(NetStatusEvent.NET_STATUS, statusHandler);
            nc.client = this;
            return;
        }// end function

        public function init(param1:Object):void
        {
            dispatchEvent(new FmsEvent(FmsEvent.ACCEPT_ADDRESS, param1));
            return;
        }// end function

        public function sendMsg(param1:Object):void
        {
            nc.call("publicChat", null, param1);
            return;
        }// end function

        private function statusHandler(event:NetStatusEvent) : void
        {
            if (event.info.code == "NetConnection.Connect.Success")
            {
                myShared = SharedObject.getRemote("chat", nc.uri, false);
                myShared.connect(nc);
                myShared.client = this;
                dispatchEvent(new FmsEvent(FmsEvent.COMPLETE));
            }
            return;
        }// end function

        public function showChat(param1:Object):void
        {
            dispatchEvent(new FmsEvent(FmsEvent.ACCEPTMSG, param1));
            return;
        }// end function

    }
}
