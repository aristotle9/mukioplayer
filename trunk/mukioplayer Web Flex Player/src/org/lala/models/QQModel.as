package org.lala.models 
{
	import com.jeroenwijering.models.VideoModel;
	import com.jeroenwijering.player.Model;
	
	/**
	 * qq视频的播放模块
	 * @author aristotle9
	 */
	public class QQModel extends VideoModel
	{
		
		public function QQModel(mod:Model) 
		{
			super(mod);
			
		}
		
		override public function load(itm:Object):void 
		{
			itm.file = QQTool.getDefaultFlvUrl(itm.vid);
			super.load(itm);
		}
		
	}

}