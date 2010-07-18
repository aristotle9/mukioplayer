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
	public class NBottomCommentViewManager extends CommentViewManager
	{
		
		public function NBottomCommentViewManager(cv:CommentView, gtr:CommentGetter, cftr:CommentFilter) 
		{
			super(cv, gtr, cftr);
			
		}
		
		override protected function addGetterListener():void 
		{
			getter.addEventListener( CommentDataManagerEvent.NORMAL_BOTTOM_DISPLAY, addHandler);
			//getter.addEventListener( CommentDataManagerEvent.NORMAL_GREEN_TOP_DISPLAY, addHandler);
		}
		
		override protected function playHandler(evt:CommentViewEvent):void 
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
						displayPools[i][j].tween.start();
					}
				}
				
				for (i = 0; i < freePool.length; i++)
				{
					freePool[i].tween.start();
				}
				bplay = true;
			}
		}
		
		override protected function pauseHandler(evt:CommentViewEvent):void 
		{
			super.pauseHandler(evt);
		}
		
		override protected function addToPool(tmp:Object):void 
		{
			//var tmp:Object = mainArray[n];
			var tfd:TextField = getDeviceTextField();
			tfd.defaultTextFormat = getFormate(Strings.innerSize(tmp.size), '黑体', tmp.color);
			tfd.autoSize = 'left';
			//tfd.selectable = false;
			//tfd.antiAliasType = aa;
			//tfd.filters = tmp.color ? shadowB:shadowW;// [new GlowFilter(0, 0.7, 3, 3)];// [new DropShadowFilter(2, 135, 0, 0.6)];// [new GlowFilter(0x323232, 0.7, 3, 3), new DropShadowFilter(2, 45, 0, 0.6)];// , new DropShadowFilter(2, 135, 0, 0.6)];
			if (MAX_BORDERED_LINES >= 0 && bordered_count > MAX_BORDERED_LINES)
			{
				tfd.filters = [];
			}
			else
			{
				bordered_count ++;
			}
			tfd.text = tmp.text;
			tmp.on = true;
///////////////////////////
//			tfd.x = Width;
///////////////////////////
			//tfd.height = tmp.height;
			//tmp.height = Strings.strHeight(tmp.text, Strings.innerSize(tmp.size));
			tmp.height = tfd.height;
			//trace("add row : " + tmp.height/tmp.size);
			tmp.width = tfd.width;
			//tfd.border = true;
			tfd.border = tmp.border;
			tfd.borderColor = 0x66FFFF;
			//tfd.alpha = 0.9;
///////////////////////////
			tfd.x = (Width - tfd.width) / 2;
///////////////////////////
			tmp.txtItem = tfd;
			
			
///////////////////////////			
//			tmp.speed = getSpeed(tfd.width);
///////////////////////////		
			tmp.speed = 0;
///////////////////////////			
//			var tw:Tween = new Tween(tfd,
//									'x',
//									None.easeOut,
//									Width,
//									- tmp.txtItem.width,
//									(Width + tmp.txtItem.width) / tmp.speed);
//			tmp.tween = tw;
//			tw.addEventListener(TweenEvent.MOTION_FINISH, onEnd(tmp));
///////////////////////////			
			var tw:Timer = new Timer(300, 10);
			tmp.tween = tw;
			if (tfd.height > Height)
			{
				tfd.y = transformY(0, tmp);// Height - tfd.height;
				tmp.poolIndex = -1;
				freePool.push(tmp);
				tmp['on'] = true;
			}
			else
			{
				insertPool(tmp);
			}
			tw.addEventListener(TimerEvent.TIMER_COMPLETE, onEnd(tmp));
///////////////////////////			
			_stage.addChild(tfd);
			tw.start();
			if(btrack) cview.dispatchCommentViewEvent(CommentViewEvent.TRACK, tmp.id);
		}
		
		override protected function transformY(logicY:int, a:Object):int
		{
			//trace("logicY : " + logicY);
			//trace("row : " + a.height/a.size);
			//if (a.mode == 5)
			//{
				//return logicY;
			//}
			//else
			//{
				return Height - logicY - a.height;
			//}
		}
		override protected function validateCheck(top:int, left:int, width:int, height:int, speed:Number, index:int):Boolean 
		{
//			trace('====================\n');
//			trace('t l w h: ' +top+' '+left+' ' + width + ' ' + height);
//			trace('--------------------\n');
			var bottom:int = top + height;
///////////////////////////						
//			var right:int = left + width;
//			var acrossArr:Array = [];
///////////////////////////			
			var displayPool:Array = displayPools[index] as Array;
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
	}

}