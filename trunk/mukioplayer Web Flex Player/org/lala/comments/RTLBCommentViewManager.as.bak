package org.lala.utils 
{
	import org.lala.plugins.CommentView;
	import org.lala.utils.CommentFilter;
	import org.lala.utils.CommentGetter;
	import org.lala.utils.CommentViewManager;
	import org.lala.events.*;
	
	/**
	 * ...
	 * @author 
	 */
	public class RTLBCommentViewManager extends CommentViewManager
	{
		
		public function RTLBCommentViewManager(cv:CommentView, gtr:CommentGetter, cftr:CommentFilter) 
		{
			super(cv, gtr, cftr);
			
		}
		override protected function addGetterListener():void 
		{
			getter.addEventListener(CommentDataManagerEvent.NORMAL_ORANGE_FLOW_RTL, addHandler);
		}
		override protected function transformY(logicY:int, a:Object):int 
		{
			return Height - logicY - a.height;
		}
	}

}