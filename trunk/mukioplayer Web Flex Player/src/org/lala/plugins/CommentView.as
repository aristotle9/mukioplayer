package org.lala.plugins 
{
	import flash.display.*;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.events.*;
	import flash.ui.ContextMenu;
	
	import com.jeroenwijering.events.*;
	import com.jeroenwijering.utils.*;
	import com.jeroenwijering.plugins.*;
	import com.jeroenwijering.models.*;
	import com.jeroenwijering.player.*;
	
	import org.lala.events.*;
	import org.lala.models.*;
	import org.lala.utils.*;
	import org.lala.comments.*;
	/**
	 * ...
	 * @author 
	 */
	public class CommentView extends EventDispatcher implements PluginInterface
	{
		public var config:Object={};
		public var clip:Sprite;
		public var view:AbstractView;
		
		private var cvm:CommentViewManager;
		private var tcvm:NTopCommentViewManager;
		private var bcvm:NBottomCommentViewManager;
		private var popocvm:PopoCommentViewManager;
		private var popobcvm:PopoBottomCommentViewManager;
		private var popotcvm:PopoTopCommentViewManager;
		//private var rcvm:LTRCommentViewManager;
		//private var rlbcvm:RTLBCommentViewManager;
		private var getter:CommentGetter;
		private var commentUI:CommentListSender;
		private var cfilter:CommentFilter;

		public function CommentView(gtr:CommentGetter,cls:CommentListSender):void
		{
			clip = new Sprite();
			clip.mouseChildren = false;
			clip.mouseEnabled = false;

			getter = gtr;
			commentUI = cls;
			commentUI.cview = this;
			cfilter = new CommentFilter(this);
			
		}
		public function initializePlugin(vw:AbstractView):void
		{
			view = vw;
			view.addControllerListener(ControllerEvent.RESIZE, resizeHandler);
			view.addModelListener(ModelEvent.TIME, timeHandler);
			view.addModelListener(ModelEvent.STATE, stateHandler);
			
			commentUI.addEventListener(CommentListViewEvent.DISPLAYTOGGLE, toggleDisplayHandler);
			commentUI.addEventListener(CommentListViewEvent.TRACKTOGGLE, trackToggleHandler);
			commentUI.addEventListener(CommentListViewEvent.FILTERADD, filterAddHandler);
			commentUI.addEventListener(CommentListViewEvent.FILTERLISTENABLETOGGLE, filterEnableToggleHandler);
			commentUI.addEventListener(CommentListViewEvent.FILTERCHECKBOXTOGGLE, filterCheckBoxToggleHandler);
			commentUI.addEventListener(CommentListViewEvent.FILTERDELETE, filterDeleteHandler);
			//note to the layout order of creations of these view managers,lateest is topest
			tcvm = new NTopCommentViewManager(this, getter,cfilter);
			bcvm = new NBottomCommentViewManager(this, getter,cfilter);
			cvm = new CommentViewManager(this, getter,cfilter);
			popocvm = new PopoCommentViewManager(this, getter,cfilter);
			popobcvm = new PopoBottomCommentViewManager(this, getter,cfilter);
			popotcvm = new PopoTopCommentViewManager(this, getter,cfilter);
			//rcvm = new LTRCommentViewManager(this, getter,cfilter);
			//rlbcvm = new RTLBCommentViewManager(this, getter,cfilter);
			getter.viewReady();
			
			cfilter.loadFromSharedObject();
		}
		private function filterDeleteHandler(evt:CommentListViewEvent):void
		{
			cfilter.deleteItem(evt.data as int);
			cfilter.savetoSharedObject();
		}
		private function filterAddHandler(evt:CommentListViewEvent):void
		{
			cfilter.addItem(evt.data as String);
			cfilter.savetoSharedObject();
		}
		private function stateHandler(evt:ModelEvent = undefined):void
		{
			switch(view.config['state'])
			{
				case ModelStates.PLAYING:
				case ModelStates.BUFFERING:
				dispatchEvent(new CommentViewEvent(CommentViewEvent.PLAY, null));
				break;
				case ModelStates.PAUSED:
				dispatchEvent(new CommentViewEvent(CommentViewEvent.PAUSE, null));
				break;
				
			}
		}
		private function resizeHandler(evt:ControllerEvent):void
		{
			clip.x = config['x'];
			clip.y = config['y'];
			clip.height = config['height'];
			clip.width = config['width'];
			//clip.visible = config['visible'];
			clip.scaleX = 1;
			clip.scaleY = 1;
			dispatchEvent(new CommentViewEvent(CommentViewEvent.RESIZE, { 'w':config['width'], 'h':config['height']} ));
		}
		private function timeHandler(evt:ModelEvent):void
		{
//			trace(clip.visible +' x:' + clip.x + ' y:' + clip.y + ' w:' + clip.width + ' h:' + clip.height + ' ' + clip.parent.getChildIndex(clip) + '/' + clip.parent.numChildren + ' ' + clip.numChildren);			
			clip.visible && dispatchEvent(new CommentViewEvent(CommentViewEvent.TIMER, evt.data.position));
		}
		
		private function toggleDisplayHandler(evt:CommentListViewEvent):void
		{
			if (clip.visible == evt.data)
			{
				return;
			}
			clip.visible = evt.data;
		}
		
		private function trackToggleHandler(evt:CommentListViewEvent):void
		{
			//trace('selected :' + evt.data);
			dispatchEvent(new CommentViewEvent(CommentViewEvent.TRACKTOGGLE, evt.data));
		}
		public function dispatchCommentViewEvent(type:String, data:Object):void
		{
			dispatchEvent(new CommentViewEvent(type,data));
		}
		
		public function filterCheckBoxToggleHandler(evt:CommentListViewEvent):void
		{
			cfilter.savetoSharedObject();
		}
		public function filterEnableToggleHandler(evt:CommentListViewEvent):void
		{
			cfilter.setEnable(evt.data.id, evt.data.enable);
			cfilter.savetoSharedObject();
		}
		public function log(a:*):void
		{
			commentUI.log(a);
		}
		
	}

}