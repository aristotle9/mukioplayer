package org.lala.comments 
{
	import flash.display.Sprite;
	
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
	 * zoome style comment manager
	 * @author aristotle9
	 */
	public class PopoCommentViewManager extends CommentViewManager
	{
		
		public function PopoCommentViewManager(cv:CommentView, gtr:CommentGetter, cftr:CommentFilter) 
		{
			super(cv, gtr, cftr);
			
		}
		
		override protected function addGetterListener():void 
		{
			getter.addEventListener(CommentDataManagerEvent.POPO_NORMAL, addHandler);
			getter.addEventListener(CommentDataManagerEvent.POPO_THINK, addHandler);
			getter.addEventListener(CommentDataManagerEvent.POPO_LOUD, addHandler);
		}
		
		override protected function pauseHandler(evt:CommentViewEvent):void 
		{
			//set empty
		}
		
		override protected function playHandler(evt:CommentViewEvent):void 
		{
			//set empty
		}
		
		override protected function addToPool(item:Object):void 
		{
			//var item:Object = mainArray[n];
			item.on = true;
			var popo:PopoComment = new PopoComment(item);
			popo.completeHandler = getCompleteHandler(item,popo);//add a complete handler
			
			_stage.addChild(popo);
			popo.start();//play actions
		}
		
		protected function getCompleteHandler(a:Object,popo:Sprite):Function 
		{
			var self:PopoCommentViewManager = this;
			return function():void
			{
				self._stage.removeChild(popo);
				a.on = false;
			};
		}
	}

}