package org.lala.comments 
{
	import flash.display.MovieClip;
	import flash.utils.getDefinitionByName;

	/**
	 * ...
	 * @author aristotle9
	 */
	public class FukidashiFactory
	{
		public function FukidashiFactory()
		{
		}
		
		static public function getFukidashi(typ:String):MovieClip
		{
			var clip:MovieClip;
			switch(typ)
			{
				case 'loud':
					clip = new telopLoud();
					break;
				case 'think':
					clip = new telopThink();
					break;
				default:
					clip = new telopNormal();
					break;
			}
			
			clip.gotoAndStop('RB');
			return clip;
		}
		
	}

}