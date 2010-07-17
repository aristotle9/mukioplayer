package org.lala.utils 
{
	import flash.events.EventDispatcher;
	import flash.net.SharedObject;
	
	//import flash.events.InvokeEvent;//for air 
	//import flash.desktop.NativeApplication;//
	import flash.events.Event;
	
	import com.jeroenwijering.events.*;
	import com.jeroenwijering.utils.*;
	import com.jeroenwijering.plugins.*;
	import com.jeroenwijering.models.*;
	import com.jeroenwijering.player.*;
	
	import org.lala.events.*;
	import org.lala.models.*;
	import org.lala.plugins.*;
	import org.lala.utils.*;
	/**
	 * ...
	 * @author 
	 */
	public class CommentFilter extends EventDispatcher
	{
		
		private var fArr:Array = [];
		private var cview:CommentView;
		private var ids:int = 0;
		
		private static var Mode:Array = ['mode', 'color', 'text'];
		
		public static var bEnable:Boolean = true;
		public static var bRegEnable:Boolean = false;
		public static var bWhiteList:Boolean = false;
		
		public function CommentFilter(cvr:CommentView) 
		{
			cview = cvr;
			//loadFromSharedObject();
			
			//NativeApplication.nativeApplication.addEventListener(InvokeEvent.INVOKE,loadFromSharedObject);
			//NativeApplication.nativeApplication.addEventListener(Event.EXITING,savetoSharedObject);
		}
		public function setEnable(id:int, enable:Boolean):void
		{//because delete operate makes some fArr[id] to null,so has to search over
			for (var i:int = 0; i < fArr.length; i++)
			{
				if (fArr[i].id == id)
				{
					fArr[i].enable = enable;
					return;
				}
			}
		}
		public function deleteItem(id:int):void
		{//because delete operate makes some fArr[id] to null, so has to search over
			trace('delete filter ' + id);
			for (var i:int = 0; i < fArr.length; i++)
			{
				if (fArr[i].id == id)
				{
					fArr.splice(i, 1);
					return;
				}
			}
		}
		public function savetoSharedObject(evt:Event=null):void
		{
			var arr:Array = [];
			for (var i:int = 0; i < fArr.length; i++)
			{
				arr.push({'keyword':fArr[i]['data'],'enable':fArr[i]['enable']});
			}
			try
			{
				var cookie:SharedObject = SharedObject.getLocal("MukioPlayer", '/');
				cookie.data['keywords'] = arr;
				cookie.data['bEnable'] = bEnable;
				cookie.data['bRegEnable'] = bRegEnable;
				cookie.data['bWhiteList'] = bWhiteList;
				cookie.flush();
			}
			catch (e:Error) { };
			trace('saving filter ' + i);
		}
		//private function loadFromSharedObject(evt:InvokeEvent):void
		public function loadFromSharedObject(evt:Event = null):void
		{
			try
			{
				var cookie:SharedObject = SharedObject.getLocal("MukioPlayer", '/');
				var arr:Array = cookie.data['keywords'] as Array;
				for (var i:int = 0; i < arr.length; i++)
				{
					addItem(arr[i]['keyword'], arr[i]['enable']);
				}
				bEnable = cookie.data['bEnable'];
				bRegEnable = cookie.data['bRegEnable'];
				bWhiteList = cookie.data['bWhiteList'];
				cview.dispatchCommentViewEvent(CommentViewEvent.FILTEINITIAL, null);
			}catch (e:Error) { };
			trace('loading filter ' +i);
			//NativeApplication.nativeApplication.removeEventListener(InvokeEvent.INVOKE,loadFromSharedObject);
		}
		public function addItem(keyword:String,enable:Boolean=true):void
		{
			var mod:int;
			var exp:String;
			
			if (keyword.length < 3)
			{
				mod = 2;
				exp = keyword;
			}
			else
			{
				var head:String = keyword.substr(0, 2);
				exp = keyword.substr(2);
				switch(head)
				{
					case 'm=':
						mod = 0;
						break;
					case 'c=':
						mod = 1;
						break;
					case 't=':
						mod = 2;
						break;
					default:
						mod = 2;
						exp = keyword;
						break;
				}
			}
			add(mod, exp, keyword,enable);
			cview.dispatchCommentViewEvent(CommentViewEvent.FILTERADD, fArr[fArr.length-1]);
			fArr.sortOn('mode');
		}
		private function add(mode:int, exp:String, data:String,enable:Boolean=true):void
		{
			fArr.push( { 'mode':mode,
						'data':data,
						'exp':exp,
						'normalExp':String(exp).replace(/(\^|\$|\\|\.|\*|\+|\?|\(|\)|\[|\]|\{|\}|\||\/)/g,'\\$1'),
						'id':ids++,
						'enable':enable} );
		}
		public function validate(item:Object):Boolean
		{
			if (!bEnable)
			{
				return true;
			}
			var res:Boolean = !bWhiteList;
			for (var i:int = 0; i < fArr.length; i++)
			{
				var tmp:Object = fArr[i];
				if (!tmp.enable)
				{
					continue;
				}
				//trace("\n\ntmp.mode : " + tmp.mode);
				if (tmp.mode == 0)
				{
					if (tmp.exp == String(item.mode))
					{
						//trace("String(item.mode) : " + String(item.mode));
						res = bWhiteList;
						break;
					}
				}
				else if (tmp.mode == 1)
				{
					if (parseInt(tmp.exp, 16) == item.color)
					{
						//trace("parseInt(tmp.exp, 16) : " + parseInt(tmp.exp, 16));
						//trace("item.color : " + item.color);
						res = bWhiteList;
						break;
					}
				}
				else
				{
					if (CommentFilter.bRegEnable)
					{
						//trace("String(item.text).search(tmp.exp) : " + String(item.text).search(tmp.exp));
						if (String(item.text).search(tmp.exp) != -1)
						{
							res = bWhiteList;
							break;
						}
					}
					else
					{
						//trace("String(item.text).search(tmp.normalExp) : " + String(item.text).search(tmp.normalExp));
						if (String(item.text).search(tmp.normalExp) != -1)
						{
							
							res = bWhiteList;
							break;
						}
					}
				}
			}
			//trace("res : " + res);
			return res;
		}
	}

}