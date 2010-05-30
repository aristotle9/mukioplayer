package org.lala.comments 
{
	import flash.utils.Timer;
	import flash.events.TimerEvent;
	
	import org.lala.plugins.*;
	import org.lala.utils.*;
	import org.lala.events.*;
	/**
	 * ...
	 * @author aristotle9
	 */
	public class PopoBottomCommentViewManager extends NBottomCommentViewManager
	{
		
		public function PopoBottomCommentViewManager(cv:CommentView, gtr:CommentGetter, cftr:CommentFilter) 
		{
			super(cv, gtr, cftr);
		}
		
		override protected function addGetterListener():void 
		{
			getter.addEventListener( CommentDataManagerEvent.POPO_BOTTOM_SUBTITLE, addHandler);
		}
		
		override protected function addToPool(item:Object):void 
		{
			//var item:Object = mainArray[n];
			
			var popo:PopoSubtitleComment = new PopoSubtitleComment(item);
			popo.x = (Width - popo.width) / 2;
			
			item.on = true;
			item.width = popo.width;
			item.height = popo.height;
			item.txtItem = popo;
			item.speed = 0;
			
			
			if (popo.height > Height)
			{
				popo.y = transformY(0, item);
				item.poolIndex = -1;
				freePool.push(item);
			}
			else
			{
				insertPool(item);//set y position
			}

			_stage.addChild(popo);

			var tw:Timer = new Timer(item.duration, 1);
			tw.addEventListener(TimerEvent.TIMER_COMPLETE, onEnd(item));
			item.tween = tw;
			tw.start();
		}
	}

}