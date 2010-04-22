MukioPlayer 1.132 Web 源代码(全)

用FlashDevelop打开,配置好了Flex的话可以直接编译

简单说明一下吧:

UI都基本集中在org\lala\plugins\CommentListSender.as
接收和发送弹幕都在org\lala\utils\CommentGetter.as
弹幕算法在org\lala\utils\CommentViewManager.as,不同的模式可以由此继承如NBottomCommentViewManager.as,可以按照例子写一个新的弹幕种类.[逆向弹幕和爬行弹幕没用上,但是源文件还在]
弹幕的展示在org\lala\plugins\CommentView.as
CommentViewManager必须在CommentView中注册,并监听CommentGetter发送出来的弹幕模式消息

org\lala\plugins中都是标准的JWPlayer插件
org\lala\models中是标准的JWPlayer Model,用来播放新浪视频的

JWPlayer总体结构是MVC的
而弹幕插件又是MVC中的MVC,为了遵循该原则,很多事件都是绕着走的,看上去有点怪

FlSWC.swc[flash控件]
MukioLib.swc[Logo和一些UI美化]
buttons.swc [一些UI美化]
five.swf
flash.swc[flash库]
loader.swf
regular.swf

是用到的皮肤和库,regular.swf和five.swf只用到一个

ff.pac[浏览器自动选择脚本,for firefox]
proxyformukioplayer.py[简易的代理服务器,需要python环境]

是替换acfun等网页中的播放器为本播放器,测试用的

详细信息可以到项目主页看:http://code.google.com/p/mukioplayer/
百度空间也有一些信息:http://hi.baidu.com/aristotle9

aristotle9
2010年4月18日