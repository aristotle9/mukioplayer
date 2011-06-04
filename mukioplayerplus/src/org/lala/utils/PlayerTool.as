package org.lala.utils
{
    import com.adobe.serialization.json.JSON;
    import com.longtailvideo.jwplayer.player.Player;
    
    import flash.events.Event;
    import flash.events.EventDispatcher;
    import flash.events.IEventDispatcher;
    import flash.events.IOErrorEvent;
    import flash.events.SecurityErrorEvent;
    import flash.net.URLLoader;
    import flash.net.URLRequest;
    
    import org.lala.event.EventBus;
    import org.lala.net.CommentServer;
    import org.lala.plugins.CommentView;

    /** 
    * 播放器常用方法集
    * 播放sina视频可以直接调用Player的load方法,因为有SinaMediaProvider
    * 但是播放youku视频要借用SinaMediaProvider,
    * 此外还要对视频信息作解析,这些任务顺序可能较为复杂,因此放在该类中,保证主文件的清洁
    * @author aristotle9
    **/
    public class PlayerTool extends EventDispatcher
    {
        /** 所辅助控制的播放器的引用 **/
        private var _player:Player;
        /** 所辅助控制的弹幕插件的引用,主要用来加载弹幕文件 **/
        private var _commentView:CommentView;
        
        public function PlayerTool(p:Player,target:IEventDispatcher=null)
        {
            _player = p;
            _commentView = CommentView.getInstance();
            super(target);
        }
        //SinaMediaProvider测试
        //player.load({type:'sina',file:'29864957'});
        //player.load({type:'sina',file:'25550133'});
        //player.load({type:'sina',file:'singleFileTest',videoInfo:{length:0,items:[{url:'E:\\acfun\\badapple.flv',length:0}]}});
        //player.load({type:'sina',file:'singleFileTest',videoInfo:{length:347000,items:[{url:'E:\\acfun\\badapple.flv',length:218000},
        //{url:'E:\\acfun\\我哥在光腚.flv',length:129000}]}});
        /**
        * 播放单个文件,借用SinaMediaProvider,因为控制逻辑与原有的MediaProvider有不同
        * @param url 视频文件的地址
        **/
        public function loadSingleFile(url:String):void
        {
            _player.load(
                {   type:'sina',
                    file:'videoInfo',
                    videoInfo:{length:0,
                                items:[
                                       {'url':url,length:0}
                                      ]
                              }
                });
        }
        /** 
        * 播放sina视频
        * @param vid sina视频的vid
        **/
        public function loadSinaVideo(vid:String):void
        {
            _player.load(
                {   type:'sina',
                    file:vid
                });
        }
        /**
        * 播放qq视频
        * @param vid qq视频的vid
        **/
        public function loadQqVideo(vid:String):void
        {
            /** 可以考虑把地址弄进配置文件 **/
            loadSingleFile('http://vsrc.store.qq.com/'+vid+'.flv?channel=vhot2&sdtfrom%3dv2&r%3d931&rfc=v0');
        }
        /**
        * 播放youku视频,同时测试一下log
        * @param vid youku视频id
        **/
        public function loadYoukuVideo(vid:String):void
        {
            var infoLoader:URLLoader = new URLLoader();
            infoLoader.addEventListener(IOErrorEvent.IO_ERROR,errorHandler);
            infoLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR,errorHandler);
            infoLoader.addEventListener(Event.COMPLETE,infoLoaderComplete);
            var infoUrl:String = 'http://v.youku.com/player/getPlayList/VideoIDS/'+ vid + '/';
            infoLoader.load(new URLRequest(infoUrl));
            log("开始加载Youku视频信息...");
        }
        private function errorHandler(event:Event):void
        {
            log(String(event));
        }
        private function infoLoaderComplete(event:Event):void
        {
            var loader:URLLoader = event.target as URLLoader;
            log("youku视频信息加载完成,正在解析...");
            try
            {
                var info:Object = parseYoukuInfo(loader.data as String);
                log("youku视频信息解析完成,可以播放了.");
                _player.load(
                    {   type:'sina',
                        file:'videoInfo',
                        videoInfo:info
                    });
            }
            catch(error:Error)
            {
                log('Youku视频信息解析失败:'+error);
            }
        }
        private function parseYoukuInfo(src:String):Object
        {
            var type:String = 'flv';
            var totle:int = 0;
            var ifs:Array = [];
            var data:Object = JSON.decode(src,false);
            if (data)
            {
                //hd选择
                data = data.data[0];
                for (var index:String in data.streamtypes)
                {
                    if (String(data.streamtypes[index]).toLowerCase() == 'mp4')
                    {
                        type = 'mp4';
                    }
                }
                //create parser
                var psr:YKParser = new YKParser(data, type);
                totle = parseFloat(data['seconds']) * 1000;
                for (var i:int = 0; i < data['segs'][type].length; i++)
                {
                    ifs.push({ url:psr.getUrl(i),
                        length:parseInt(data['segs'][type][i].seconds) * 1000,
                        id:i + 1
                    });
                }
                if (!totle)
                {
                    throw "Youku视频出错.";
                    return null;
                }
                else
                {
                    return {length:totle,
                        items:ifs};
                }
            }
            return null;
        }
        /**
        * 加载一般弹幕文件
        * @params url 弹幕文件地址
        **/
        public function loadCmtFile(url:String):void
        {
            _commentView.loadComment(url);
        }
        /**
        * 加载AMF弹幕文件
        * @params server 弹幕服务器
        **/
        public function loadCmtData(server:CommentServer):void
        {
            _commentView.provider.load('',CommentFormat.AMFCMT,server);
        }
        //以下两个函数在代理测试时使用        
        /**
        * 加载bili弹幕文件
        * @params cid 弹幕id
        **/
        public function loadBiliFile(cid:String):void
        {
            loadCmtFile('http://www.bilibili.us/dm,' + cid + '?r=' + Math.ceil(Math.random() * 1000));
        }
        /**
        * 加载acfun弹幕文件
        * @params cid 弹幕id
        **/
        public function loadAcfunFile(cid:String):void
        {
            loadCmtFile('http://124.228.254.234/newflvplayer/xmldata/' + cid + '/comment_on.xml?r=' + Math.random());
        }
        private function log(message:String):void
        {
            EventBus.getInstance().log(message);
        }
    }
}