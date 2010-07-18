package org.lala.components 
{
	import flash.display.Sprite;
	import fl.controls.listClasses.ListData;
	import org.lala.utils.AlternatingRowColors;
	
	/**
	 * ...
	 * @author 
	 */
	public class ColorCell extends AlternatingRowColors
	{
		
		public function ColorCell() 
		{
			super();
		}		
		override public function set listData(value:ListData):void 
		{
			super.listData = value;
//			super.label = '';
			super.setStyle('icon', getIcon(data.color));
		}
		
		private function getIcon(clr:int):Sprite
		{
			var ico:Sprite = new Sprite();
			
			ico.scaleX = ico.scaleY = 1;
			
			ico.graphics.lineStyle(1);
			ico.graphics.beginFill(clr);
			ico.graphics.drawRect(0, 0, 14, 14);
			ico.graphics.endFill();
			
			return ico;
		}
		
	}

}
