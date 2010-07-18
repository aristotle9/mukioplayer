package org.lala.comments 
{
	import org.lala.plugins.CommentView;
	import org.lala.utils.CommentFilter;
	import org.lala.utils.CommentGetter;
	import org.lala.events.CommentDataManagerEvent;
	
	/**
	 * ...
	 * @author aristotle9
	 */
	public class PopoTopCommentViewManager extends PopoBottomCommentViewManager
	{
		
		public function PopoTopCommentViewManager(cv:CommentView, gtr:CommentGetter, cftr:CommentFilter) 
		{
			super(cv, gtr, cftr);
			
		}
		override protected function addGetterListener():void 
		{
			getter.addEventListener( CommentDataManagerEvent.POPO_TOP_SUBTITLE, addHandler);
		}
		override protected function transformY(logicY:int, a:Object):int 
		{
			return logicY;
		}
		
	}

}