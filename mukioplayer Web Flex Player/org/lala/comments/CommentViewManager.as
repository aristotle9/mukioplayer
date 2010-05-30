package org.lala.comments 
{
	import flash.display.Sprite;
	import flash.events.EventDispatcher;
	import flash.text.AntiAliasType;
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
	public class CommentViewManager extends EventDispatcher
	{
		public static var shadowB:Array = [new GlowFilter(0, 0.7, 3,3)];//[new GlowFilter(0, 0.7, 3,3)];
		public static var shadowW:Array = shadowB;// [new GlowFilter(0xaaaaaa, 0.7, 3, 3)];// shadowB;// [new DropShadowFilter(3, 225, 0xffffff, 0.8)];
		public static var aa:String = AntiAliasType.NORMAL;
		public static var START_POS:int = 30;
		public static var MAX_BORDERED_LINES:int = 20;//最大的描边字幕条目数,只有非负时有效,防卡死措施之一
		public static var MAX_LINES:int = 50;//最大的舞台字幕条目数,只有正数时有效,防卡死措施又一
		public static var MAX_WIDTH_LINE:int = 2048;
		public static var MAX_HEIGHT_LINE:int = 768;
		
		protected var bordered_count:int = 0;
		//protected var line_max_length:int = 0;
		
		protected var displayPools:Array = [];
		protected var freePool:Array = [];
		protected var mainArray:Array = [];
		protected var mainPointer:int = 0;
		protected var oldPos:Number = 0;
		protected var _stage:Sprite;
		protected var getter:CommentGetter;
		protected var cview:CommentView;
		protected var cfilter:CommentFilter;
		
		protected var Width:int=Player.WIDTH;
		protected var Height:int=Player.HEIGHT;
		
		protected var bplay:Boolean = true;
		protected var btrack:Boolean = false;
		
		public function CommentViewManager(cv:CommentView,gtr:CommentGetter,cftr:CommentFilter) :void
		{
			cview = cv;
			cview.addEventListener(CommentViewEvent.TIMER, timmerHandler);
			cview.addEventListener(CommentViewEvent.RESIZE, resizeHandler);
			cview.addEventListener(CommentViewEvent.PLAY, playHandler);
			cview.addEventListener(CommentViewEvent.PAUSE, pauseHandler);
			
			cview.addEventListener(CommentViewEvent.TRACKTOGGLE, trackToggleHandler);
			
			getter = gtr;
			getter.addEventListener(CommentDataManagerEvent.NEW, newCommentDataHandler);
			addGetterListener();
			//layout order by mode or not 
			_stage = cv.clip;
			//_stage = new Sprite();
			//_stage.x = 0;
			//_stage.y = 0;
			//_stage.scaleX = _stage.scaleY = 1;
			//cv.clip.addChild(_stage);
			
			cfilter = cftr;
		}
		
		protected function newCommentDataHandler(evt:CommentDataManagerEvent):void
		{
			mainArray = [];
			mainPointer = 0;
			oldPos = 0;
		}
		protected function addGetterListener():void
		{
			getter.addEventListener(CommentDataManagerEvent.NORMAL_FLOW_RTL, addHandler);
			getter.addEventListener(CommentDataManagerEvent.BIG_BLUE_FLOW_RTL, addHandler);
			getter.addEventListener(CommentDataManagerEvent.NORMAL_ORANGE_FLOW_RTL, addHandler);
		}
		protected function trackToggleHandler(evt:CommentViewEvent):void
		{
			btrack = evt.data;
		}
		protected function playHandler(evt:CommentViewEvent):void
		{
			if (bplay)
			{
				return;
			}
			else
			{
				for (var i:int = 0; i < displayPools.length; i ++)
				{
					for (var j:int = 0; j < displayPools[i].length; j++)
					{
						displayPools[i][j].tween.resume();
					}
				}
				
				for (i = 0; i < freePool.length; i++)
				{
					freePool[i].tween.resume();
				}
				bplay = true;
			}
		}
		protected function pauseHandler(evt:CommentViewEvent):void
		{
			if (!bplay)
			{
				return;
			}
			else
			{
				for (var i:int = 0; i < displayPools.length; i ++)
				{
					for (var j:int = 0; j < displayPools[i].length; j++)
					{
						displayPools[i][j].tween.stop();
					}
				}
				for (i = 0; i < freePool.length; i++)
				{
					freePool[i].tween.stop();
				}
				bplay = false;
			}
		}
		protected function addHandler(evt:CommentDataManagerEvent):void
		{
			//evt.data['on'] = false;
			//evt.data.size = Strings.innerSize(evt.data.size);
			//var p:int = findPos(evt.data.stime,mainArray,'stime');
			var whitespace:RegExp = /(\t|\n|\s)/g;
			//var obj:Object = {
				//'on':false,
				//'text':evt.data['text'],
				//'color':evt.data['color'],
				//'size':evt.data.size,
				//'mode':evt.data['mode'],
				//'stime':evt.data['stime'],
				//'date':evt.data['date'],
				//'border':evt.data['border'],
				//'id':evt.data['id'],
				//'strWidth':Strings.strWidth(evt.data['text'], Strings.innerSize(evt.data.size)),
				//'strHeight':Strings.strHeight(evt.data['text'], Strings.innerSize(evt.data.size)),
				//'trimmed':String(evt.data['text']).replace(whitespace,"")
			//};
			
			//复制对象
			var obj:Object = {on:false};
			for (var key:String in evt.data)
			{
				obj[key] = evt.data[key];
			}
			
			obj.strWidth = Strings.strWidth(evt.data['text'], Strings.innerSize(evt.data.size));
			obj.strHeight = Strings.strHeight(evt.data['text'], Strings.innerSize(evt.data.size));
			obj.trimmed = String(evt.data['text']).replace(whitespace, "");
			
			if (obj.border)
			{
				if (evt.data['prev'])
				{
					obj.border = false;
					addToPool(obj);
					return;
				}
				else
				{
					addToPool(obj);
				}
			}
			
			var p:int = findPos2(obj,mainArray,compareTo);
			mainArray.splice(p, 0, obj);
			if (mainPointer >= p)
			{
				mainPointer ++;
			}
//			trace("Comment View Manager");
		}
		protected function resizeHandler(evt:CommentViewEvent):void
		{
//			Width = evt.data.w;
//			Height = evt.data.h;
			//_stage.scaleY = evt.data.h / Height;
			_stage.scaleY = _stage.scaleX = evt.data.w / Width;
		}
		protected function findPos(s:Number,arr:Array,name:String):int
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
					trace('Error!');
				}
				if (count > 1000)
				{
					//trace('My God!');
					break;
				}
				
			}
			return -1;
		}
		protected function findPos2(a:Object,arr:Array,fn:Function):int
		{
			if (arr.length == 0)
			{
				return 0;
			}
			
			if (fn(a,arr[0])<0)//s < arr[0][name])
			{
				return 0;
			}
			
			if (fn(a,arr[arr.length - 1])>=0)//s >= arr[arr.length - 1][name])
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
				if(fn(a,arr[i-1])>=0/*s >= arr[i - 1][name] */&& 
				fn(a,arr[i])<0/*s < arr[i][name]*/)
				{
					//trace('count: ' + count);
					return i;
				}
				else if (fn(a,arr[i-1])<0/*s < arr[i - 1][name]*/)
				{
					hig = i - 1;
				}
				else if (fn(a,arr[i])>=0/*s >= arr[i][name]*/)
				{
					low = i;
				}
				else
				{
					trace('Error!');
				}
				if (count > 1000)
				{
					//trace('My God!');
					break;
				}
				
			}
			return -1;
		}
		protected function compareTo(a:Object, b:Object):int
		{
			if (a.stime < b.stime)
			{
				return -1;
			}
			else
			if (a.stime > b.stime)
			{
				return 1;
			}
			else
			{
				if (a.date < b.date)
				{
					return -1;
				}
				else
				if (a.date > b.date)
				{
					return 1;
				}
				else
				{
					//if (a.mode < b.mode)
					//{
						//return 1;
					//}
					//else if (a.mode > b.mode)
					//{
						//return -1;
					//}
					//else
					//{
						return 0;
					//}
				}
			}
			
		}
		protected function compareToBottom(a:Object, b:Object):int
		{
			if (a.bottom < b.bottom)
			{
				return -1;
			}
			else
			if (a.bottom > b.bottom)
			{
				return 1;
			}
			else
			{
				return 0;
			}
			
		}
		protected function timmerHandler(evt:CommentViewEvent):void
		{
			var pos:Number = Number(evt.data) - 0.001;
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
					//if(cfilter.validate(mainArray[mainPointer]) && !mainArray[mainPointer]['on']) addToPool(mainArray[mainPointer]);
					if (cfilter.validate(mainArray[mainPointer]) &&
						innerValidate(mainArray[mainPointer]) &&
					    !mainArray[mainPointer]['on']
						)
						addToPool(mainArray[mainPointer]);
				}else
				{
					return;
				}
			}
//			trace('mainPointer '+mainPointer);
		}
		protected function seekToPoint(s:Number):void
		{
			mainPointer = findPos(s,mainArray,'stime');
		}
		protected function getFormate(size:Number, family:String, color:int):TextFormat
		{
			return new TextFormat(family, size, color);
		}
		protected function addToPool(tmp:Object):void
		{
//			var tmp:Object = mainArray[n];
			var tfd:TextField = getDeviceTextField();
			//tfd.selectable = false;
			tfd.defaultTextFormat = getFormate(Strings.innerSize(tmp.size), '黑体', tmp.color);
			tfd.autoSize = 'left';
			//tfd.antiAliasType = aa;
			//tfd.filters = tmp.color ? shadowB:shadowW;// [new GlowFilter(0, 0.7, 3, 3)];// [new DropShadowFilter(2, 135, 0, 0.6)];// tmp.color ? [new GlowFilter(0x323232, 0.7, 3, 3), new DropShadowFilter(2, 45, 0, 0.6)] : [new GlowFilter(0xeeeeee, 0.7, 3, 3)];// , new DropShadowFilter(2, 135, 0, 0.6)];
			if (MAX_BORDERED_LINES >= 0 && bordered_count >= MAX_BORDERED_LINES)
			{
				tfd.filters = [];
			}
			else
			{
				bordered_count ++;
			}
			tmp.on = true;
			tfd.text = tmp.text;
			tfd.x = Width - START_POS;
			//tfd.height = tmp.height;
			//tmp.height = Strings.strHeight(tmp.text, Strings.innerSize(tmp.size));
			tmp.height = tfd.height;
			tmp.width = tfd.width;
			//if (tmp.width > line_max_length)
			//{
				//line_max_length = tmp.width;
				//cview.log(line_max_length);
			//}
			//tfd.border = true;
			tfd.border = tmp.border;
			tfd.borderColor = 0x66FFFF;
			//tfd.alpha = 0.9;
			tmp.txtItem = tfd;
			tmp.speed = getSpeed(tmp);
			
			var tw:Tween = new Tween(tfd,
									'x',
									None.easeOut,
									Width - START_POS,
									- tmp.txtItem.width,
									(Width + tmp.txtItem.width - START_POS) / tmp.speed);
			tmp.tween = tw;
			if (tfd.height > Height)
			{
				tmp.poolIndex = -1;
				freePool.push(tmp);
				tmp['on'] = true;
			}
			else
			{
				insertPool(tmp);
			}
			tw.addEventListener(TweenEvent.MOTION_FINISH, onEnd(tmp));
			
			_stage.addChild(tfd);
			tw.resume();
			if(btrack) cview.dispatchCommentViewEvent(CommentViewEvent.TRACK, tmp.id);
			
		}
		protected function getSpeed(data:Object):Number
		{
//			return 4.58 * (1.2 * Width + 2.4 * d) / (1.2*550)  ;
			//return (2 * data.width + 1.6 * Width)*4.58 / (1.2*550);
			return 5 * (Width + data.width) / (Width + Strings.innerSize(data.size));
			//return 7.5 * (Width + data.width) / (Width + Strings.innerSize(data.size));
		}
		protected function insertPool(a:Object,index:int=0):void
		{
			try{
			var y:int=0;
			var i:int = 0;
			if (!displayPools[index])
			{
				displayPools[index] = [];
			}
			var displayPool:Array = displayPools[index] as Array;
			if (displayPool.length == 0)
			{
				a.txtItem.y = transformY(y, a);
				a.y = y;
				a.bottom = y + a.height;
				displayPool.push(a);
				//trace('0 got at null:' + i + '/'+displayPool.length);
				a['poolIndex'] = index;
				return;
			}
			
			if (validateCheck(y, Width - START_POS, a.txtItem.width, a.height,a.speed,index))
			{
				a.txtItem.y = transformY(y, a);
				a.y = y;
				a.bottom = y + a.height;
				displayPool.splice(findPos2(a, displayPool, compareToBottom), 0, a);
				a['poolIndex'] = index;
				//trace('0 got not null:' + i + '/'+displayPool.length);
				return;
			}
			
			for (i = 0; i < displayPool.length;i++)
			{
				y = displayPool[i].bottom+1;
				if (validateCheck(y, Width - START_POS, a.txtItem.width, a.height,a.speed,index))
				{
					if (y + a.height > Height)
					{
						break;
					}
					else
					{
						a.txtItem.y = transformY(y, a);;
						a.y = y;
						a.bottom = y + a.height;
						displayPool.splice(findPos2(a, displayPool, compareToBottom), 0, a);
						//trace('y got:' + i + '/'+displayPool.length);
						a['poolIndex'] = index;
						return;
					}
				}
				if (displayPool.length == 0)
				{
					//trace('failed at null');
					break;
				}
			}
			trace('Next Poll!');
			insertPool(a, index + 1);
			}
			catch (e:Error)
			{
				trace(e.name+': '+e.message);
			}
		}
		protected function transformY(logicY:int, a:Object):int
		{
			return logicY;
		}
		protected function validateCheck(top:int,left:int,width:int,height:int,speed:Number,index:int):Boolean
		{
//			trace('====================\n');
//			trace('t l w h: ' +top+' '+left+' ' + width + ' ' + height);
//			trace('--------------------\n');
			var bottom:int = top + height;
			var right:int = left + width;
			var acrossArr:Array = [];
			var displayPool:Array = displayPools[index] as Array;
			for (var i:int = 0; i < displayPool.length; i++)
			{
				if (displayPool[i].y > bottom || displayPool[i].bottom < top)
				{
//					trace('=>t l w h: ' +displayPool[i].txtItem.y+' '+displayPool[i].txtItem.x+' ' + displayPool[i].txtItem.width + ' ' + displayPool[i].txtItem.height);
					continue;
				} else if (displayPool[i].txtItem.x > right ||
				displayPool[i].txtItem.x + displayPool[i].txtItem.width < left)
				{
					acrossArr.push(displayPool[i]);
					continue;
				}
				else
				{
					return false;
				}
				
			}
//			trace('====================\n');
			for (i = 0; i < acrossArr.length; i ++)
			{
				if ((acrossArr[i].txtItem.x + acrossArr[i].txtItem.width ) / acrossArr[i].speed < (Width - START_POS) / speed)
				{
					continue;
				}
				else
				{
					return false;
				}
			}
			return true;
			
		}
		protected function onEnd(a:Object):Function
		{
			var self:CommentViewManager= this;
			return function():void
			{
				self._stage.removeChild(a.txtItem);
				if (a.txtItem.filters.length)
				{
					bordered_count --;
				}
				delete a.tween;
				delete a.txtItem;
				self.del(a);
				a.on = false;
			};
		}
		protected function del(a:Object):void
		{
			if (a.poolIndex == -1)
			{
				var n:int = freePool.indexOf(a);
				freePool.splice(n, 1);
				return;
			}
			n = displayPools[a.poolIndex].indexOf(a);
			displayPools[a.poolIndex].splice(n, 1);
		}
		public static function getDeviceTextField():TextField
		{
			//var tfd:TextField = (new DeviceTextFieldFactory()).holdTextField;
			//tfd.autoSize = 'left';
			//tfd.wordWrap = false;
			//return tfd;
			return (new DeviceTextFieldFactory()).holdTextField;
		}
		public function get commentLines():int
		{
			return _stage.numChildren;
		}
		public function innerValidate(a:Object):Boolean
		{
			if (MAX_LINES > 0 && commentLines > MAX_LINES)
			{
				return false;
			}
			if (a.trimmed == '')
			{
				return false;
			}
			if (a.strWidth > MAX_WIDTH_LINE)
			{
				return false;
			}
			if (a.strHeight > MAX_HEIGHT_LINE)
			{
				return false;
			}
			return true;
		}

	}

}