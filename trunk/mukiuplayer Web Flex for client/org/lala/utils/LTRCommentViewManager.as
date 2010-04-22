package org.lala.utils 
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
	 * 反向字幕
	 * ...
	 * @author 
	 */
	
	public class LTRCommentViewManager extends CommentViewManager
	{
		
		public function LTRCommentViewManager(cv:CommentView, gtr:CommentGetter, cftr:CommentFilter) 
		{
			super(cv, gtr, cftr);
			
		}
		
		override protected function addGetterListener():void 
		{
			getter.addEventListener(CommentDataManagerEvent.BIG_BLUE_FLOW_RTL, addHandler);
			getter.addEventListener( CommentDataManagerEvent.NORMAL_FLOW_LTR, addHandler);

		}
		override protected function addToPool(n:int):void 
		{
			var tmp:Object = mainArray[n];
			var tfd:TextField = getDeviceTextField();
			tfd.selectable = false;
			tfd.defaultTextFormat = getFormate(tmp.size, '黑体', tmp.color);
			tfd.autoSize = 'left';
			tfd.filters = [new GlowFilter(0, 0.7, 3, 3)];// [new DropShadowFilter(2, 135, 0, 0.6)];// tmp.color ? [new GlowFilter(0x323232, 0.7, 3, 3), new DropShadowFilter(2, 45, 0, 0.6)] : [new GlowFilter(0xeeeeee, 0.7, 3, 3)];// , new DropShadowFilter(2, 135, 0, 0.6)];
			tmp.on = true;
			tfd.text = tmp.text;
			tfd.x = Width;
			//tfd.height = tmp.height;
			tmp.height = Strings.strHeight(tmp.text, tmp.size);
			tmp.width = tfd.width;
			tfd.border = tmp.border;
			tfd.borderColor = 0x66FFFF;
			//tfd.alpha = 0.9;
			tmp.txtItem = tfd;
			tmp.speed = getSpeed(tmp);
			
			var tw:Tween = new Tween(tfd,
									'x',
									None.easeOut,
									- tmp.txtItem.width,
									Width,
									(Width + tmp.txtItem.width) / tmp.speed);//reverse 
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
		
	}

}