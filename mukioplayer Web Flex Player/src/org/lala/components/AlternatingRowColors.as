package org.lala.components 
{
	import fl.controls.listClasses.CellRenderer;
	import fl.controls.listClasses.ICellRenderer;
	
	/**
	 * ...
	 * @author 
	 */
	public class AlternatingRowColors extends CellRenderer implements ICellRenderer
	{
		
		public function AlternatingRowColors() 
		{
			super();
			
		}
		
		public static function getStyleDefinition():Object {
            return CellRenderer.getStyleDefinition();
        }
		
		override protected function drawBackground():void {
            if (_listData.index % 2 == 0) {
                setStyle("upSkin", CellRenderer_upSkin);
            } else {
                setStyle("upSkin", CellRenderer_upSkinBlue);
            }
            super.drawBackground();
        }


	}

}