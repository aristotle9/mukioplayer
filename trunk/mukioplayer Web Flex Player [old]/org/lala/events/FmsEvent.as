package org.lala.events
{
    import flash.events.*;

    public class FmsEvent extends Event
    {
        private var _data:Object;
        public static const ACCEPTMSG:String = "acceptMsg";
        public static const COMPLETE:String = "complete";
        public static const ACCEPT_ADDRESS:String = "accept_address";

        public function FmsEvent(param1:String, param2:Object = null , param3:Boolean = false, param4:Boolean = false)
        {
            super(param1, param3, param4);
            _data = param2;
            return;
        }// end function

        public function get data() : Object
        {
            return _data;
        }// end function

    }
}
