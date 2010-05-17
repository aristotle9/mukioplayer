package  org.lala.utils
{
	import fl.controls.Button;
	import flash.display.*;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.filters.DropShadowFilter;
	import flash.geom.ColorTransform;
	import flash.text.TextField;
	
	import org.lala.events.*;
	/**
	 * ...
	 * @author 
	 */
	public class GroupButtons extends Sprite
	{
		private var btArr:Array=[];
		private var curBt:Object;
		public var _ref:InteractiveObject;
		
		public function GroupButtons() 
		{
			scaleX = scaleY = 1;
			var gp:Graphics = graphics;
			{
				gp.lineStyle(1,0,0.4)
				gp.beginFill(0xffffff, 0.5);
				gp.drawRoundRect(0, 0, 242, 160, 8);
				gp.endFill();
				gp.moveTo(0, 25);
				gp.lineTo(242, 25);
			}
			var title:TextField = new TextField();
			title.text = '弹幕发送样式';
			title.x = title.y = 5;
			title.textColor = 0x323232;
			title.autoSize = 'left';
			title.selectable = false;
			addChild(title);
			var cbt:Button = new Button();
			cbt.label = 'X';
			cbt.move(214, 3);
			cbt.setSize(23, 20);
			addChild(cbt);
			cbt.addEventListener(MouseEvent.CLICK, function(evt:MouseEvent):void
			{
				visible = false;
				removeEventListener(MouseEvent.CLICK, stageClickHandler);
			});
			filters = [new DropShadowFilter(2, 45, 0, 0.6)];
			visible = false;
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
		public function add(data:Object):void
		{
			btArr.push( { bt:createButton(data), data:data, id:btArr.length } );
			if (btArr.length == 1)
			{
				curBt = btArr[0];
				curBt.bt.selected = true;
				curBt.bt.enabled = false;
			}
		}
		private function createButton(data:Object):Button
		{
			var bt:Button = new Button();
			bt.move(data.x + 5,data.y + 34);
			bt.setSize(data.w, data.h);
			bt.label = '';
			bt.setStyle('icon', createIcon(data.color, data.size, data.arrow, data.position));
			bt.setStyle('selectedDisabledIcon', createIcon(data.color, data.size, data.arrow, data.position,true));
			bt.toggle = true;
			bt.selected = false;
			bt.addEventListener(Event.CHANGE, buttonsChangeHandler);
			addChild(bt);
			return bt;
		}
		private function buttonsChangeHandler(evt:Event):void
		{
			var tmp : Button = evt.target as Button;
			for (var i:int = 0; i < btArr.length; i++)
			{
				if (tmp == btArr[i].bt)
				{
					curBt.bt.enabled = true;
					curBt.bt.selected = false;
					curBt = btArr[i];
					curBt.bt.enabled = false;
					curBt.bt.selected = true;
					dispatchEvent(new CommentListViewEvent(CommentListViewEvent.GPBUTTONCHANGE, curBt.data));
					break;
				}
			}
		}

		private function createIcon(color:int=0xffffff,size:String='normal',arrow:String='none',position:String='top',sel:Boolean=false):Object
		{
			var sp:Sprite = new Sprite();

			var sizes:Object = { small:0.8, normal:1.0, big:1.5 };
			
			var arrows:Object = { toLeft:[45, 16, 17, 16, 21, 12],
									toRight:[4, 16, 32, 16, 29, 12],
									toLeftBottom:[45, 36, 17, 36, 21, 40],
								none:null};
			sp.scaleX = sp.scaleY = 1;
			var gp:Graphics = sp.graphics;
			{
				gp.lineStyle(2, 0x262c2b);
				gp.beginFill(sel ? 0x008fe9 : 0xffffff,0.8);
				gp.drawRoundRect(0, 0, 50, 50, 6);
				gp.endFill();
				gp.beginFill(0x262c2b);
				gp.drawRect(4, 9, 42, 32);
				gp.endFill();
				if (arrows[arrow])
				{
					gp.lineStyle(2, 0xffffff);
					gp.moveTo(arrows[arrow][0], arrows[arrow][1]);
					gp.lineTo(arrows[arrow][2], arrows[arrow][3]);
					gp.lineTo(arrows[arrow][4], arrows[arrow][5]);
				}
			}
			if (arrows[arrow])
			{
				position = 'middle';
			}
			var zm:Zimu = getColorZimu(color);

			sp.addChild(zm);
			zm.width *= sizes[size];
			zm.height *= sizes[size];
			zm.x = (50 - zm.width) / 2;
			switch(position)
			{
				case 'top':
					zm.y = 9;
					break;
				case 'bottom':
					zm.y = 50-zm.height - 9;
					break;
				case 'middle':
					zm.y = (50-zm.height)/2;
					break;
				default:
				    zm.y = 0;
					zm.x = 0;
			}
			return sp;


		}
		private function getColorZimu(color:int=0xffffff):Zimu
		{
			var zimu:Zimu = new Zimu();
			var ct :ColorTransform = new ColorTransform(1, 1, 1, 1, (color >> 16) & 0xff, (color >> 8) & 0xff, color & 0xff, 0);
			zimu.transform.colorTransform = ct;
			return zimu;
		}
		
	}

}