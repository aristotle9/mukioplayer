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
	public class NTopCommentViewManager extends NBottomCommentViewManager
	{
		
		public function NTopCommentViewManager(cv:CommentView, gtr:CommentGetter, cftr:CommentFilter) 
		{
			super(cv, gtr, cftr);
			
		}
		override protected function addGetterListener():void 
		{
			getter.addEventListener( CommentDataManagerEvent.NORMAL_GREEN_TOP_DISPLAY, addHandler);
		}
		override protected function transformY(logicY:int, a:Object):int 
		{
			return logicY;
		}
		
	}

}