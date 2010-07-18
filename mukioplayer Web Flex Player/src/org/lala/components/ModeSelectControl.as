package org.lala.components
{
	import flash.display.SimpleButton;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.filters.DropShadowFilter;
	import flash.display.CapsStyle;
	import flash.display.JointStyle;
	import flash.display.InteractiveObject;
	
	import org.lala.events.CommentListViewEvent;
	/**
	 * ...
	 * @author aristotle9
	 */
	public class ModeSelectControl extends ModeSelect
	{
		protected var _mode:int = 1;
		protected var _size:int = 25;
		protected var _color:int = 0xFFFFFF;
		
		protected var moderect:Sprite;
		protected var sizerect:Sprite;
		protected var colorrect:Sprite;
		protected var clrArray:Array = [ 0xFFFFFF,
										 0xFF0000,
										 0xFF8080,
										 0xFFC000,
										 0xFFFF00,
										 0x00FF00,
										 0x00FFFF,
										 0x0000FF,
										 0xC000FF,
										 0x000000,
										 0xCCCC99,
										 0xCC0033,
										 0xFF33CC,
										 0xFF6600,
										 0x999900,
										 0x00CC66,
										 0x00CCCC,
										 0x3399FF,
										 0x9900FF,
										 0x666666 ];
		protected var clrbtArray:Array = [];
		protected var _ref:InteractiveObject;
		public function ModeSelectControl() 
		{
			super();
			
			addColorButtons();
			
			moderect = new Sprite();
			moderect.graphics.lineStyle(2, 0x333333,1,false,'normal',CapsStyle.NONE,JointStyle.MITER);
			moderect.graphics.drawRect(0, 0, 57, 41);
			addChild(moderect);
			
			sizerect = new Sprite();
			sizerect.graphics.lineStyle(2, 0x333333,1,false,'normal',CapsStyle.NONE,JointStyle.MITER);
			sizerect.graphics.drawRect(0, 0, 57, 41);
			addChild(sizerect);
			
			colorrect = new Sprite();
			colorrect.graphics.lineStyle(2, 0x333333,1,false,'normal',CapsStyle.NONE,JointStyle.MITER);
			colorrect.graphics.drawRect(0, 0, 15.5, 15.5);
			addChild(colorrect);
			
			addModeButton(leftflowbt, 1);
			addModeButton(bottommodebt, 4);
			addModeButton(topmodebt, 5);
			
			addSizeButton(normalsizebt, 25);
			addSizeButton(smallsizebt, 15);
			addSizeButton(bigsizebt, 37);
			
			
			resetbt.addEventListener(MouseEvent.CLICK, resetAll);
			
			resetAll();
			
			closebt.addEventListener(MouseEvent.CLICK, function(evt:MouseEvent):void
			{
				visible = false;
				removeEventListener(MouseEvent.CLICK, stageClickHandler);
			});

			init();
		}
		protected function resetAll(evt:MouseEvent=null):void
		{
			setMode(leftflowbt, 1);
			setSize(normalsizebt, 25);
			setColor(clrbtArray[0], clrArray[0]);
		}
		protected function setMode(bt:SimpleButton,mod:int):void
		{
				_mode = mod;
				moderect.x = bt.x - .5;
				moderect.y = bt.y - .5;
				changed('mode', mod);
		}
		protected function setSize(bt:SimpleButton,sz:int):void
		{
				_size = sz;
				sizerect.x = bt.x - .5;
				sizerect.y = bt.y - .5;
				changed('size', sz);
		}
		
		protected function setColor(bt:SimpleButton,clr:int):void
		{
				_color = clr;
				colorrect.x = bt.x + .5;
				colorrect.y = bt.y + .5;
				changed('color', clr);
		}
		
		protected function addModeButton(bt:SimpleButton,mod:int):void
		{
			bt.addEventListener(MouseEvent.CLICK, function(evt:MouseEvent):void
			{
				setMode(bt, mod);
			});
		}
		protected function addSizeButton(bt:SimpleButton,sz:int):void
		{
			bt.addEventListener(MouseEvent.CLICK, function(evt:MouseEvent):void
			{
				setSize(bt, sz);
			});
		}
		protected function addColorButton(bt:SimpleButton,clr:int):void
		{
			bt.addEventListener(MouseEvent.CLICK, function(evt:MouseEvent):void
			{
				setColor(bt, clr);
			});
		}
		protected function addColorButtons():void
		{
			var i:int = 0;
			var length:int = 10;
			var x0:int = 60;
			var y0:int = 23;
			for (i = 0; i < clrArray.length; i ++ )
			{
				var cbt:ColorCellButton = new ColorCellButton(clrArray[i]);
				cbt.x = x0 + 18 * (i % length);
				cbt.y = y0 + 18 * Math.floor(i / length);
				addColorButton(cbt, clrArray[i]);
				addChild(cbt);
				clrbtArray.push(cbt);
			}
		}
		protected function init():void
		{
			visible = false;
			filters = [new DropShadowFilter(2, 45, 0, 0.6)];
		}
		public function get mode():int
		{
			return _mode;
		}
		public function get size():int
		{
			return _size;
		}
		public function get color():int
		{
			return _color;
		}
		
		public function set ref(r:InteractiveObject):void
		{
			_ref = r;
			r.addEventListener(MouseEvent.CLICK, refClickHandler);
		}
		private function refClickHandler(evt:MouseEvent):void
		{
			show();
		}
		public function show():void {
			if (visible)
			{
				visible = false;
				return;
			}
			visible = true;
			stage.addEventListener(MouseEvent.CLICK, stageClickHandler);
		}
		private function stageClickHandler(evt:MouseEvent):void
		{
			if (!hitTestPoint(evt.stageX, evt.stageY) && !_ref.hitTestPoint(evt.stageX, evt.stageY) )
			{
				visible = false;
				removeEventListener(MouseEvent.CLICK, stageClickHandler);
			}
		}
		protected function changed(type:String,val:int):void
		{
			dispatchEvent(new CommentListViewEvent(CommentListViewEvent.MODESTYLESIZECHANGE, {type:type,value:val}));
		}
		
	}

}