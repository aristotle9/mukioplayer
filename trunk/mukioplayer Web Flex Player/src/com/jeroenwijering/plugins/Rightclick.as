/**
* Implement a rightclick menu with "fullscreen", "stretching" and "about" options.
**/
package com.jeroenwijering.plugins {


import com.jeroenwijering.events.*;
import com.jeroenwijering.utils.Logger;
import com.jeroenwijering.utils.Stretcher;

import flash.events.ContextMenuEvent;
import flash.net.URLRequest;
import flash.net.navigateToURL;
import flash.system.Capabilities;
import flash.ui.ContextMenu;
import flash.ui.ContextMenuItem;


public class Rightclick implements PluginInterface {


	/** Plugin configuration object. **/
	public var config:Object = {};
	/** Reference to the contextmenu. **/
	private var context:ContextMenu;
	/** Reference to the 'about' menuitem. **/
	private var about:ContextMenuItem;
	/** Reference to the fullscreen menuitem. **/
	private var fullscreen:ContextMenuItem;
	/** Reference to the stretchmode menuitem. **/
	private var stretching:ContextMenuItem;
	/** Reference to the debugging menuitem. **/
	private var debug:ContextMenuItem;
	/** Reference to the MVC view. **/
	private var view:AbstractView;


	/** Constructor. **/
	public function Rightclick():void {
		context = new ContextMenu();
		context.hideBuiltInItems();
	};


	/** Add an item to the contextmenu. **/
	private function addItem(itm:ContextMenuItem,fcn:Function):void {
		itm.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT,fcn);
		itm.separatorBefore = true;
		context.customItems.push(itm);
	};


	/** Initialize the communication with the player. **/
	public function initializePlugin(vie:AbstractView):void {
		view = vie;
		view.skin.contextMenu = context;
		try {
			fullscreen = new ContextMenuItem('全屏切换...');
			addItem(fullscreen,fullscreenHandler);
		} catch (err:Error) {}
		stretching = new ContextMenuItem('缩放选项 '+view.config['stretching']+'...');
		addItem(stretching,stretchHandler);
		if(view.config['abouttext'] == 'JW Player' || view.config['abouttext'] == undefined) {
			about = new ContextMenuItem('About JW Player '+view.config['version']+'...');
		} else {
			about = new ContextMenuItem('About '+view.config['abouttext']+'...');
		}
		addItem(about,aboutHandler);
		if(Capabilities.isDebugger == true || view.config['debug'] != 'none') {
			debug = new ContextMenuItem('Logging to '+Logger.output+'...');
			addItem(debug,debugHandler);
		}
	};


	/** jump to the about page. **/
	private function aboutHandler(evt:ContextMenuEvent):void {
		navigateToURL(new URLRequest(view.config['aboutlink']),'_blank');
	};


	/** change the debug system. **/
	private function debugHandler(evt:ContextMenuEvent):void {
		var arr:Array = new Array(Logger.NONE,Logger.ARTHROPOD,Logger.CONSOLE,Logger.TRACE);
		var idx:Number = arr.indexOf(Logger.output);
		idx == arr.length-1 ? idx = 0: idx++;
		debug.caption = 'Logging to '+arr[idx]+'...';
		Logger.output = arr[idx];
	};


	/** Toggle the fullscreen mode. **/
	private function fullscreenHandler(evt:ContextMenuEvent):void {
		view.sendEvent(ViewEvent.FULLSCREEN);
	};


	/** Change the stretchmode. **/
	private function stretchHandler(evt:ContextMenuEvent):void {
		var arr:Array = new Array(Stretcher.UNIFORM,Stretcher.FILL,Stretcher.EXACTFIT,Stretcher.NONE);
		var idx:Number = arr.indexOf(view.config['stretching']);
		idx == arr.length-1 ? idx = 0: idx++;
		view.config['stretching'] = arr[idx];
		stretching.caption = '缩放选项 '+arr[idx]+'...';
		view.sendEvent(ViewEvent.REDRAW);
	};


}


}