package org.lala.components 
{
	import fl.controls.CheckBox;
	import fl.controls.listClasses.CellRenderer;
	import fl.controls.listClasses.ListData;
	import fl.core.InvalidationType;
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.utils.getDefinitionByName;
	
	/**
	 * ...
	 * @author 
	 */
	//先前的从一开始就错了
	public class CheckCellRenderer extends CellRenderer
	{
		private var _sel:Boolean;
		
		private var SelSkins:Array = [];
		private var unSelSkins:Array = [];
		
		public function CheckCellRenderer() 
		{
			super();
			
			loadSkins();
			addEventListener(MouseEvent.CLICK, clHandler);
		}
		
		private function getAClassObject(classname:String):Object
		{
			var classRef:Class=getDefinitionByName(classname) as Class;
			return new classRef();
		}
		
		private function loadSkins():void
		{
			var or:Array = ['up', 'down', 'over', 'disabled'];
			var or2:Array = ['Up', 'Down', 'Over', 'Disabled'];
			for (var i :int = 0; i < 4; i++)
			{
				SelSkins.push( {'name':or[i] + 'Icon',
				'data':getAClassObject('CheckBox_selected'+or2[i]+'Icon')});

				unSelSkins.push( { 'name':or[i] + 'Icon',
				'data':getAClassObject('CheckBox_' + or[i] + 'Icon') } );
				
			}
			SelSkins.push({'name':'icon','data':SelSkins[0].data});
			unSelSkins.push({'name':'icon','data':unSelSkins[0].data});
		}
		
		private function updateSkins():void
		{
			super.label = _sel ? '启用':' 未启用';
			for (var i:int = 0; i < 5; i++)
			{
				if (_sel)
				{
					super.setStyle(SelSkins[i].name, SelSkins[i].data);
				}
				else
				{
					super.setStyle(unSelSkins[i].name, unSelSkins[i].data);
				}
			}

		}

		override public function set data(value:Object):void
		{
			super.data = value;
			_sel = value.enable;
		}
		override public function set listData(value:ListData):void
		{
			super.listData = value;
			updateSkins();
		}
		private function clHandler(evt:MouseEvent):void
		{
			_sel = !_sel;
			super.data.enable = _sel;
			
			updateSkins();
			//invalidate(InvalidationType.DATA);
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