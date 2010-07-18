/**
* Player that crunches through all media formats Flash can read.
**/
package com.jeroenwijering.player {


import com.jeroenwijering.events.*;
import com.jeroenwijering.models.*;
import com.jeroenwijering.plugins.*;
import com.jeroenwijering.utils.*;

import mx.core.MovieClipLoaderAsset;

import flash.display.*;
import flash.events.*;

import org.lala.models.*;
import org.lala.plugins.*;
import org.lala.utils.*;

[SWF(backgroundColor="0xffffff", width="950", height="432", frameRate="30")]
public class Player extends MovieClip {


	//[Embed(source="../../../regular.swf")]
	[Embed(source="asset/five.swf")]
	private const EmbeddedSkin:Class;
	
	[Embed(source="asset/loader.swf")]
	protected var LoadingScreen:Class;
	/** All configuration values. Change them to hard-code your preferences. **/
	public static var WIDTH:int = 540;
	public static var HEIGHT:int = 384;
	
	public var config:Object = {
		author:undefined,
		date:undefined,
		description:undefined,
		duration:0,
		file:undefined,
		//cfile:undefined,
		cfile:undefined,//'http://bilibili.us/newflvplayer/xmldata/19927138.xml',
		//vid:'-1',
		vid:'-1',
		cid:undefined,
		//isyouku:false,
		//nico:undefined,
		nico:undefined,
		image:undefined,
		link:undefined,
		start:0,
		streamer:undefined,
		tags:undefined,
		title:undefined,
		type:undefined,

		backcolor:undefined,
		frontcolor:undefined,
		lightcolor:undefined,
		screencolor:undefined,

		controlbar:'bottom',
		dock:false,
		height:300,
		icons:true,
		playlist:'none',
		playlistsize:180,
		//skin:'modieus.swf',
		skin:undefined,
		width:400,

		autostart:false,
		bandwidth:5000,
		bufferlength:1,
		displayclick:'play',
		fullscreen:true,
		item:0,
		level:0,
		linktarget:'_blank',
		logo:undefined,
		mute:false,
		repeat:'none',
		shuffle:false,
		smoothing:true,
		state:'IDLE',
		stretching:'uniform',
		volume:90,

		//abouttext:"JW Player",
		abouttext:"MukioPlayer1.142 Web",
		//aboutlink:"http://www.longtailvideo.com/players/jw-flv-player/",
		aboutlink:"http://code.google.com/p/mukioplayer/",
		client:undefined,
		debug:'none',
		id:undefined,
		plugins:undefined,
		//version:'4.6.525'
		version:'1.142'
	};
	/** Reference to all stage graphics. **/
	public var skin:MovieClip;
	/** Reference to the View of the MVC cycle, defining all API calls. **/
	public var view:View;
	/** Object that loads all configuration variables. **/
	protected var configger:Configger;
	/** Object that load the skin and plugins. **/
	protected var sploader:SPLoader;
	/** Reference to the Controller of the MVC cycle. **/
	protected var controller:Controller;
	/** Reference to the model of the MVC cycle. **/
	protected var model:Model;
	
	/** a getter share by to plugins **/
	protected var getter:CommentGetter;
	protected var commentUI:CommentListSender;
	protected var commentView:CommentView;

	protected var loaderScreen:Sprite;
	protected var loaderAnim:MovieClipLoaderAsset;
	protected var mcl:MovieClipLoaderAsset;
	/** Constructor; hides player and waits until it is added to the stage. **/
	public function Player():void {
		
		loaderScreen = new Sprite();
		loaderScreen.name = 'loaderScreen';

		loaderAnim = new LoadingScreen() as MovieClipLoaderAsset;
		var ld:Loader = Loader(loaderAnim.getChildAt(0));
		ld.contentLoaderInfo.addEventListener(Event.INIT, resizeStage);

		loaderScreen.graphics.clear();
		loaderScreen.graphics.beginFill(0, 1);
		loaderScreen.graphics.drawRect(0, 0, stage.stageWidth, stage.stageHeight);
		loaderScreen.graphics.endFill();
		addChild(loaderScreen);
		//resizeStage();
		
		//visible = false;
		//visible = false;
		//skin = this['player'];
		//loadConfig();
	};
	

	protected function resizeStage(evt:Event = null):void {
		
		loaderScreen.addChild(loaderAnim);
		

		loaderAnim.x = (stage.stageWidth - loaderAnim.width) / 2;
		loaderAnim.y = (stage.stageHeight - loaderAnim.height) / 2;
		
		mcl = new EmbeddedSkin() as MovieClipLoaderAsset;
		var ldr:Loader = Loader(mcl.getChildAt(0));
		ldr.contentLoaderInfo.addEventListener(Event.INIT, loadConfig);
	}

	/** When the skinis loaded, the config is loaded. **/
	protected function loadConfig(evt:Event=null):void {
		skin = MovieClip(LoaderInfo(evt.target).content).player;
		skin.visible = false;
		addChild(skin);
		//
		configger = new Configger(this);
		configger.addEventListener(Event.COMPLETE,loadSkin);
		configger.load(config);
	};

	/** When config is loaded, the player laods the skin. **/
	protected function loadSkin(evt:Event):void {
		if(config['tracecall']) {
			Logger.output = config['tracecall'];
		} else { 
			Logger.output = config['debug'];
		}
		sploader = new SPLoader(this);
		sploader.addEventListener(SPLoaderEvent.SKIN,loadMVC);
		sploader.loadSkin();
	};


	/** When the skin is loaded, the model/view/controller are inited. **/
	protected function loadMVC(evt:SPLoaderEvent):void {
		controller = new Controller(config,skin,sploader);
		model = new Model(config,skin,sploader,controller);
		view = new View(config,skin,sploader,controller,model);
		controller.closeMVC(model,view);
		addModels();
		addPlugins();
		sploader.addEventListener(SPLoaderEvent.PLUGINS,startPlayer);
		sploader.loadPlugins();
	};


	/** Initialize all playback models. **/
	protected function addModels():void {
		model.addModel(new HTTPModel(model),'http');
		model.addModel(new ImageModel(model),'image');
		model.addModel(new LivestreamModel(model),'livestream');
		// model.addModel(new RTMPModel(model),'rtmp');
		model.addModel(new SoundModel(model),'sound');
		model.addModel(new VideoModel(model),'video');
		model.addModel(new YoutubeModel(model), 'youtube');
		model.addModel(new SINAModel(model),'sina');//add
		model.addModel(new BOKECCModel(model),'bokecc');//add
		model.addModel(new YOUKUModel(model),'youku');//add
		model.addModel(new SIXROOMModel(model),'6room');//add
	};


	/** Init built-in plugins and load external ones. **/
	protected function addPlugins():void {
		sploader.addPlugin(new Display(),'display');
		sploader.addPlugin(new Rightclick(),'rightclick');
		sploader.addPlugin(new Controlbar(),'controlbar');
		sploader.addPlugin(new Playlist(),'playlist');
		sploader.addPlugin(new Dock(),'dock');
		sploader.addPlugin(new Watermark(false), 'watermark');
		//sploader.addPlugin(new Dragdrop(), 'dragdrop',true);
		
		{//hack for config
			//config['type'] = undefined;
			
			//if (config['file'])
			//{
				//var arr:Array = String(config['file']).match(/(?:http:\/\/v\.youku\.com\/v_show\/id_([^\.]+)\.html|\/sid\/([^\/]+)\/v\.swf)/i);
				//if (arr)
				//{
					//config['isyouku'] = true;
					//config['vid'] = arr.slice(1).join('');
					//config['file'] = undefined;
				//}
			//}
			
			//avfun001
			if (config['pid'])
			{
				config['cfile'] = 'http://www.avfun001.org/subtitle/' + config['pid'];
			}
			
			//bili
			if (config['avid'])
			{
				var arr:Array = String(config['avid']).split('levelup');
				config['file'] = 'http://pl.bilibili.us/uploads/' + arr[0] + '/' + arr[1] + '.flv';
				config['cid'] = config['avid'];
				config['vid'] = undefined;
			}
			
			//if only pass id or vid,then vid = id ,type = sina
			if ((config['id'] || config['vid']) && !config['file'] && config['type'] == 'video')
			{
				config['type'] = 'sina';
			}//adapt acfun
			
			if ((config['id'] || config['vid']) && config['file'])
			{
				if(!String(config['file']).match('.mp3'))
					config['type'] = 'video';
			}//adapt mp3
			
			//cover id to vid ,if file is undefined
			if (config['id'] && !config['file'])
			{
				config['vid'] = config['id'];
			}
			else if(config['id'])//if id and file,then load video from file,load comment xml from id(cid)
			{
				config['cid'] = config['id'];
				config['vid'] = '-1';
			}
			config['id'] = undefined;//set id to null,because id is not the standard argument 
			
			//if vid is -1 and has file,(so there will be cid and file couple), set the vid to null,so 
			//type will turn to video but not sina
			if (config['vid'] == '-1' && config['file'] != undefined)
			{
				config['vid'] = undefined;
			}
			
			
			//trace("config['vid'] : " + config['vid']);
			//trace("config['file'] : " + config['file']);
			
		}
		
		//trace("config['cfile'] : " + config['cfile']);
		//Strings.parseFlashvars('vid=30144957&cfile=c:/pad.xml');
		//return;
		//trace("config['cfile'] : " + config['cfile']);
		//trace("config['nico'] : " + config['nico']);
		
		getter = new CommentGetter();
		commentUI = new CommentListSender(getter);
		commentView = new CommentView(getter, commentUI);
		sploader.addPlugin(commentUI, 'commentlistsender');
		sploader.addPlugin(commentView, 'commentview');
	};


	/**
	* Everything is now ready. The Player is redrawn, shown and the file is loaded.
	*
	* The Player broadcasts a READY event here to actionscript.
	* The View will send an asynchroneous PlayerReady event to javascript.
	**/
	protected function startPlayer(evt:SPLoaderEvent):void {
		view.sendEvent(ViewEvent.REDRAW);
		//visible = true;
		skin.visible = true;
		removeChild(loaderScreen);
		
		dispatchEvent(new PlayerEvent(PlayerEvent.READY));
		
		config['file'] = config['vid'] ? 'sina' : config['file'];//add
		
		view.playerReady();
		if(config['file']) {
			view.sendEvent(ViewEvent.LOAD,config);
		}
	};


}


}