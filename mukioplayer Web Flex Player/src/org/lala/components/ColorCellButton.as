package org.lala.components
{
	import flash.display.DisplayObject;
	import flash.display.SimpleButton;
	
	/**
	 * ...
	 * @author aristotle9
	 */
	public class ColorCellButton extends SimpleButton
	{
		
		public function ColorCellButton(color:int) 
		{
			var ico:DisplayObject = getColorIcon(color);
			super(ico, ico, ico, ico);
			width = height = ico.width;
		}
		protected function getColorIcon(clr:int):DisplayObject
		{
			var icon:BClrCell = new BClrCell();
			icon.graphics.beginFill(clr);
			icon.graphics.drawRect(4, 4, 10, 10);
			icon.graphics.endFill();
			return icon;
		}
		
	}

}