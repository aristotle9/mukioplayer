package org.lala.comments 
{
	import flash.display.Sprite;
	import flash.events.EventDispatcher;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.utils.*;
	import flash.events.TimerEvent;
	import fl.transitions.easing.*;
	import fl.transitions.Tween;
	import fl.transitions.TweenEvent;
	import flash.filters.*;
	
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
	public class TopCommentViewManager extends EventDispatcher
	{
		private var displayPool:Array = [];
		private var mainArray:Array = [];
		private var mainPointer:int = 0;
		private var oldPos:Number = 0;
		private var _stage:Sprite;
		private var getter:CommentGetter;
		private var cview:CommentView;
		private var cfilter:CommentFilter;
		
		private var Width:int;
		private var Height:int;
		
		private var bplay:Boolean = true;
		private var btrack:Boolean = false;
		
		public function TopCommentViewManager(cv:CommentView,gtr:CommentGetter,cftr:CommentFilter) :void
		{
			cview = cv;
			cview.addEventListener(CommentViewEvent.TIMER, timmerHandler);
			cview.addEventListener(CommentViewEvent.RESIZE, resizeHandler);
			cview.addEventListener(CommentViewEvent.PLAY, playHandler);
			cview.addEventListener(CommentViewEvent.PAUSE, pauseHandler);
			
			cview.addEventListener(CommentViewEvent.TRACKTOGGLE, trackToggleHandler);
			
			getter = gtr;
///////////////////////////			
//			getter.addEventListener(CommentDataManagerEvent.NORMAL_FLOW_RTL, addHandler);
//			getter.addEventListener(CommentDataManagerEvent.BIG_BLUE_FLOW_RTL, addHandler);
//			getter.addEventListener(CommentDataManagerEvent.NORMAL_ORANGE_FLOW_RTL, addHandler);
///////////////////////////			
			getter.addEventListener( CommentDataManagerEvent.NORMAL_GREEN_TOP_DISPLAY, addHandler);
///////////////////////////			
			_stage = new Sprite();
			_stage.x = 0;
			_stage.y = 0;
			_stage.scaleX = _stage.scaleY = 1;
			cv.clip.addChild(_stage);

			cfilter = cftr;
		}
		private function trackToggleHandler(evt:CommentViewEvent):void
		{
			btrack = evt.data;
		}
		private function playHandler(evt:CommentViewEvent):void
		{
			if (bplay)
			{
				return;
			}
			else
			{
				for (var i:int = 0; i < displayPool.length; i ++)
				{
					displayPool[i].tween.resume();
				}
				bplay = true;
			}
		}
		private function pauseHandler(evt:CommentViewEvent):void
		{
			if (!bplay)
			{
				return;
			}
			else
			{
				for (var i:int = 0; i < displayPool.length; i ++)
				{
					displayPool[i].tween.stop();
				}
				bplay = false;
			}
		}
		private function addHandler(evt:CommentDataManagerEvent):void
		{
			evt.data['on'] = false;
			var p:int = findPos(evt.data.stime,mainArray,'stime');
			mainArray.splice(p, 0, evt.data);
			if (mainPointer >= p)
			{
				mainPointer ++;
			}
			if (evt.data.border)
			{
				addToPool(p);
			}
		}
		private function resizeHandler(evt:CommentViewEvent):void
		{
			Width = evt.data.w;
			Height = evt.data.h;
		}
		private function findPos(s:Number,arr:Array,name:String):int
		{
			if (arr.length == 0)
			{
				return 0;
			}
			
			if (s < arr[0][name])
			{
				return 0;
			}
			
			if (s >= arr[arr.length - 1][name])
			{
				return arr.length;
			}
			var low:int = 0;
			var hig:int = arr.length - 1;
			var i:int;
			var count:int = 0;
			while (low <= hig)
			{
				i = int((low + hig +1) / 2);
				count++;
				if(s >= arr[i - 1][name] && 
				s < arr[i][name])
				{
					//trace('count: ' + count);
					return i;
				}
				else if (s < arr[i - 1][name])
				{
					hig = i - 1;
				}
				else if (s >= arr[i][name])
				{
					low = i;
				}
				else
				{
					//trace('Error!');
				}
				if (count > 1000)
				{
					//trace('My God!');
					break;
				}
				
			}
			return -1;
		}
		private function timmerHandler(evt:CommentViewEvent):void
		{
			var pos:Number = Number(evt.data);
			if (mainPointer >= mainArray.length || Math.abs(pos - oldPos) > 2)
			{
				seekToPoint(pos);
				oldPos = pos;
				if (mainPointer == mainArray.length)
				return;
			}
			else
			{
				oldPos = pos;
			}
//			trace('mainArray[mainPointer][\'stime\'] '+mainArray[mainPointer]['stime']);
//			trace('pos'+pos);
//			trace('mainPointer ' + mainPointer);
			for (; mainPointer < mainArray.length; mainPointer++)
			{
				if (mainArray[mainPointer]['stime'] <= pos)
				{
					if(cfilter.validate(mainArray[mainPointer])  && !mainArray[mainPointer]['on']) addToPool(mainPointer);
				}else
				{
					return;
				}
			}
//			trace('mainPointer '+mainPointer);
		}
		private function seekToPoint(s:Number):void
		{
			mainPointer = findPos(s,mainArray,'stime');
		}
		private function getFormate(size:Number, family:String, color:int):TextFormat
		{
			return new TextFormat(family, size, color);
		}
		private function addToPool(n:int):void
		{
			var tmp:Object = mainArray[n];
			var tfd:TextField = CommentViewManager.getDeviceTextField();
			tmp.on = true;
			tfd.text = tmp.text;
///////////////////////////
//			tfd.x = Width;
///////////////////////////
			tfd.setTextFormat(getFormate(tmp.size, 'simhei', tmp.color));
			tfd.autoSize = 'left';
			tfd.border = tmp.border;
			tfd.borderColor = 0x66FFFF;
			tfd.filters = [new DropShadowFilter(2, 45, 0, 0.6)];// , new DropShadowFilter(2, 135, 0, 0.6)];
			tfd.alpha = 0.9;
///////////////////////////
			tfd.x = (Width - tfd.width) / 2;
///////////////////////////
			tmp.txtItem = tfd;
			
			
///////////////////////////			
//			tmp.speed = getSpeed(tfd.width);
///////////////////////////		
			tmp.speed = 0;
///////////////////////////			
			//var tw:Tween = new Tween(tfd,
									//'x',
									//None.easeOut,
									//Width,
									//- tmp.txtItem.width,
									//(Width + tmp.txtItem.width) / tmp.speed);
			//tmp.tween = tw;
			//tw.addEventListener(TweenEvent.MOTION_FINISH, onEnd(tmp));
///////////////////////////			
			var tw:Tween = new Tween(tfd,
									'alpha',
									None.easeOut,
									tfd.alpha,
									tfd.alpha,
									75);
			tmp.tween = tw;
			tw.addEventListener(TweenEvent.MOTION_FINISH, onEnd(tmp));
///////////////////////////			
			insertPool(tmp);
			_stage.addChild(tfd);
			tw.resume();
			if(btrack) cview.dispatchCommentViewEvent(CommentViewEvent.TRACK, tmp.id);
			
		}
///////////////////////////					
//		private function getSpeed(d:Number):Number
//		{
//			return 4.58 * (1.2 * Width + 2.4 * d) / (1.2*550)  ;
//		}
///////////////////////////					
		private function insertPool(a:Object):void
		{
			try{
			var y:int=0;
			var i:int=0;
			if (displayPool.length == 0)
			{
				a.txtItem.y = y % Height;
				a.y = y;
				a.bottom = y + a.txtItem.height;
				displayPool.push(a);
				//trace('0 got at null:' + i + '/'+displayPool.length);
				return;
			}
			
			if (validateCheck(y, Width, a.txtItem.width, a.txtItem.height,a.speed))
			{
				a.txtItem.y = y % Height;
				a.y = y;
				a.bottom = y + a.txtItem.height;
				displayPool.splice(findPos(a.bottom, displayPool, 'bottom'), 0, a);
				//trace('0 got not null:' + i + '/'+displayPool.length);
				return;
			}
			
			for (i = 0; i < displayPool.length;i++)
			{
				y = displayPool[i].bottom+1;
				if (validateCheck(y, Width, a.txtItem.width, a.txtItem.height,a.speed))
				{
					a.txtItem.y = y % Height;
					a.y = y;
					a.bottom = y + a.txtItem.height;
					displayPool.splice(findPos(a.bottom, displayPool, 'bottom'), 0, a);
					//trace('y got:' + i + '/'+displayPool.length);
					return;
				}
				if (displayPool.length == 0)
				{
					trace('failed at null');
					break;
				}
			}
			//trace('failed!');
			}
			catch (e:Error)
			{
				trace(e.name+': '+e.message);
			}
		}

///////////////////////////					
///////////////////////////					
		private function validateCheck(top:int,left:int,width:int,height:int,speed:Number=0):Boolean
		{
//			trace('====================\n');
//			trace('t l w h: ' +top+' '+left+' ' + width + ' ' + height);
//			trace('--------------------\n');
			var bottom:int = top + height;
///////////////////////////						
//			var right:int = left + width;
//			var acrossArr:Array = [];
///////////////////////////			
			for (var i:int = 0; i < displayPool.length; i++)
			{
				if (displayPool[i].y > bottom || displayPool[i].bottom < top)
				{
//					trace('=>t l w h: ' +displayPool[i].txtItem.y+' '+displayPool[i].txtItem.x+' ' + displayPool[i].txtItem.width + ' ' + displayPool[i].txtItem.height);
					continue;
				}
///////////////////////////							
//				else if (displayPool[i].txtItem.x > right ||
//				displayPool[i].txtItem.x + displayPool[i].txtItem.width < left)
//				{
//					acrossArr.push(displayPool[i]);
//					continue;
//				}
///////////////////////////							
				else
				{
					return false;
				}
				
			}
//			trace('====================\n');
///////////////////////////			
//			for (i = 0; i < acrossArr.length; i ++)
//			{
//				if ((acrossArr[i].txtItem.x + acrossArr[i].txtItem.width ) / acrossArr[i].speed < Width / speed)
//				{
//					continue;
//				}
//				else
//				{
//					return false;
//				}
//			}
///////////////////////////						
			return true;
			
		}
///////////////////////////			
		private function onEnd(a:Object):Function
		{
//			var self:CommentViewManager= this;
			var self:TopCommentViewManager= this;
			return function():void
			{
				self._stage.removeChild(a.txtItem);
				self.del(a);
				a.on = false;
			};
		}
///////////////////////////			
		private function del(a:Object):void
		{
			var n:Number = displayPool.indexOf(a);
			displayPool.splice(n, 1);
		}
	}

}