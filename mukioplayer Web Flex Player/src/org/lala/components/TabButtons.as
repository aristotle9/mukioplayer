package org.lala.components 
{
	import fl.controls.Button;
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.text.TextFormat;
	
	import org.lala.events.*;
	/**
	 * ...
	 * @author 
	 */
	public class TabButtons extends EventDispatcher
	{
		public var clip:Sprite;
		private var tabsArr:Array = [];
		private var curTab:Object;
		private var X0:int = 0;
		private var Y0:int = 0;
		private var TWidth:int = 100;
		private var THeight:int = 27;
		private var SWidth:int = 400;
		private var SHeight:int = 400;
		private var tf:TextFormat;
		private var tf2:TextFormat;
		
		public function TabButtons(_stage:Sprite,x:int,y:int,w:int,h:int):void 
		{
			clip = _stage;
			X0 = x;
			Y0 = y;
			SWidth = w
			SHeight = h;
			tf = new TextFormat('simsum', '12', 0x323232);
			tf2 = new TextFormat('simsum', '12', 0x626262);
		}
		public function addTab(_title:String,clr:int=0xddddff/*white 0xededed*//*purple 0xddddff*//*0xb4d7ed*/):void
		{
			var bt:Button = new Button();
			var shape:Sprite = new Sprite();
			//var selDisUp:Object = bt.getStyle('upSkin');
			//var selUp:Object = bt.getStyle('selectedDownSkin');
			bt.setStyle('selectedUpSkin',Button_selectedDownSkin);
			bt.setStyle('selectedDisabledSkin',Button_upSkin);
			bt.label = _title;
			bt.move(X0 + (TWidth+2) * tabsArr.length +1, Y0+3);
			bt.setSize(TWidth, THeight);
			bt.setStyle('textFormat',tf2);
			bt.setStyle('disabledTextFormat',tf);
			bt.toggle = true;
			bt.selected = true;
			bt.addEventListener(Event.CHANGE, changeHandler);
			clip.addChildAt(bt, 0);
			
			shape.scaleX = shape.scaleY = 1;
			shape.graphics.beginFill(clr);
			shape.graphics.drawRect(0, -2, SWidth, SHeight);
			shape.graphics.endFill();
			shape.graphics.lineStyle(1, 0x70767a)
			shape.graphics.moveTo(0, -2);
			shape.graphics.lineTo(1+tabsArr.length*(TWidth+2), -2);
			shape.graphics.moveTo(1+tabsArr.length*(TWidth+2)+TWidth, -2);
			shape.graphics.lineTo(SWidth, -2);
			
			shape.x = X0;
			shape.y = Y0 + THeight;
			shape.visible = false;
			clip.addChild(shape);
			tabsArr.push(
			{
				bt:bt,
				fd:shape
			});
			if (tabsArr.length == 1)
			{
				curTab = tabsArr[0];
				curTab.bt.enabled = false;
				curTab.bt.selected = true;
				curTab.fd.visible = true;
			}
		}
		private function changeHandler(evt:Event):void
		{
			var bt:Button = evt.target as Button;
			for (var i:int = 0; i < tabsArr.length; i++)
			{
				if (tabsArr[i].bt == bt)
				{
					curTab.bt.enabled = true;
					curTab.bt.selected = true;
					curTab.fd.visible = false;
					curTab = tabsArr[i];
					curTab.bt.enabled = false;
					curTab.bt.selected = true;
					curTab.fd.visible = true;
					dispatchEvent(new CommentListViewEvent(CommentListViewEvent.TBBUTTONCHANGE, i));
					break;
				}
			}
		}
		public function addItem(index:int, dsp:DisplayObject):void
		{
			if (index >= tabsArr.length)
			{
				return;
			}
			tabsArr[index].fd.addChild(dsp);
		}
		public function tab(index:int):Sprite
		{
			if (index >= tabsArr.length)
			{
				return null;
			}
			return tabsArr[index].fd;
		}
		public function bt(index:int):Button
		{
			if (index >= tabsArr.length)
			{
				return null;
			}
			return tabsArr[index].bt;
		}
		public function set selectedIndex(index:int):void
		{
			if (index >= tabsArr.length)
			{
				return;
			}
			
			curTab.bt.enabled = true;
			curTab.bt.selected = true;
			curTab.fd.visible = false;
			curTab = tabsArr[index];
			curTab.bt.enabled = false;
			curTab.bt.selected = true;
			curTab.fd.visible = true;
			dispatchEvent(new CommentListViewEvent(CommentListViewEvent.TBBUTTONCHANGE, index));
		}
	}

}