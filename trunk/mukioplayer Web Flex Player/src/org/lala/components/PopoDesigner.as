package org.lala.components 
{
	import com.jeroenwijering.player.Player;
	import fl.controls.Button;
	import fl.controls.CheckBox;
	import fl.controls.ComboBox;
	import fl.controls.Label;
	import fl.controls.Slider;
	import fl.controls.TextArea;
	import fl.controls.TextInput;
	import fl.events.SliderEvent;
	import flash.display.Bitmap;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import fl.controls.RadioButton;
	import fl.controls.RadioButtonGroup;
	import org.lala.events.CommentListViewEvent;
	
	import com.yahoo.astra.fl.containers.Form;
	import com.yahoo.astra.containers.formClasses.*;
	
	/**
	 * popo comment designer
	 * @author aristotle9
	 */
	public class PopoDesigner extends Sprite
	{
		
		[Embed(source="asset/target.png")]
		private const TargetIcon:Class;
		
		private var targetSpot:Bitmap;
		private var spotter:Sprite;
		private var p:Point;
		private var posLb:Label;
	
		private var formlyt:Form;
		
		private var styleArr:Array = [
		{label:'普通',data:'normal'},
		{label:'大喊',data:'loud'},
		{label:'思考',data:'think'},
		{label:'底端字幕',data:'subtitle'}
		];
		private var styleCb:ComboBox;
		
		private var commentIpt:TextArea;
		
		private var commandIpt:TextInput;
		
		private var sendBt:Button;
		
		private var colorCpk:fl.controls.ColorPicker;
		
		private var sizeArr:Array = [
		{label:'正常',data:25},
		{label:'大',data:37},
		{label:'小',data:15}
		];
		
		//font style
		private var boldBt:Button;
		private var italicBt:Button;
		private var underlineBt:Button;
		
		private var sizeCb:ComboBox;
		
		//opacity
		private var opacitySld:Slider;
		private var opacityLb:Label;
		
		//duration
		private var durationSld:Slider;
		private var durationLb:Label;
		
		//in and out effect
		private var inEffectArr:Array = [
		{label:'无',data:'normal'},
		{label:'随机',data:'random'},
		{label:'渐显',data:'fade'},
		{label:'飞行',data:'fly'},
		];
		private var inEffectCb:ComboBox;
		private var inEffectSld:Slider;
		private var inEffectLb:Label;//标签
		
		private var outEffectArr:Array = [
		{label:'无',data:'normal'},
		{label:'随机',data:'random'},
		{label:'渐隐',data:'fade'},
		{label:'飞行',data:'fly'},
		];
		private var outEffectCb:ComboBox;
		private var outEffectSld:Slider;
		private var outEffectLb:Label;//标签
		
		private var cps:Compass;
		
		private var lupinCkb:CheckBox;
		
		public function PopoDesigner() 
		{
			init();
		}
		
		private function init():void
		{
			formlyt = new Form();
			formlyt.formHeading = 'ZOOME弹幕设计面板';
			formlyt.horizontalGap = 30;
			formlyt.autoSize = true;
			formlyt.labelAlign = FormLayoutStyle.RIGHT;
			addChild(formlyt);
			
			
			//style options
			styleCb = new ComboBox();
			styleCb.dataProvider.addItems(styleArr);
			styleCb.labelField = 'label';
			
			//comment input
			commentIpt = new TextArea();
			commentIpt.setSize(240, 40);
			commentIpt.maxChars = 255;
			
			//command input
			commandIpt = new TextInput();
			commandIpt.setSize(190, 20);
			commandIpt.text = '不可用';
			commandIpt.enabled = false;
			
			//color picker
			colorCpk = new fl.controls.ColorPicker();
			//colorCpk.selectedColor = 0xFFFFFF;
			colorCpk.selectedColor = 0;
			
			//size options
			sizeCb = new ComboBox();
			sizeCb.labelField = 'label';
			sizeCb.dataProvider.addItems(sizeArr);
			
			//font styles
			boldBt = new Button();
			boldBt.setSize(24,20);
			boldBt.toggle = true;
			boldBt.label = 'B';
			boldBt.setStyle('textFormat', new TextFormat('sans', null, 0, true));
			
			italicBt = new Button();
			italicBt.setSize(24,20);
			italicBt.toggle = true;
			italicBt.label = 'I';
			italicBt.setStyle('textFormat', new TextFormat('sans', null, 0, false, true));
			
			underlineBt = new Button();
			underlineBt.setSize(24,20);
			underlineBt.toggle = true;
			underlineBt.label = 'U';
			underlineBt.setStyle('textFormat', new TextFormat('sans', null, 0, false, false, true));
			
			//opacity
			opacitySld = new Slider();
			//opacitySld.setSize(100,20);
			opacitySld.maximum = 100;
			opacitySld.minimum = 0;
			opacitySld.snapInterval = 10;
			opacitySld.liveDragging = true;
			opacitySld.value = 40;
			opacitySld.addEventListener(SliderEvent.CHANGE, opacitySldUpdateHandler);
			
			opacityLb = new Label();
			opacityLb.text = opacitySld.value.toString();
			
			//duration
			durationSld = new Slider();
			//durationSld.setSize(100,20);
			durationSld.maximum = 8000;
			durationSld.minimum = 0;
			durationSld.snapInterval = 500;
			durationSld.value = 1000;
			durationSld.liveDragging = true;
			durationSld.addEventListener(SliderEvent.CHANGE, durationSldUpdateHandler);
			
			durationLb = new Label();
			durationLb.text = durationSld.value.toString();
			
			//in effect
			inEffectCb = new ComboBox();
			inEffectCb.dataProvider.addItems(inEffectArr);
			inEffectCb.labelField = 'label';
			inEffectCb.addEventListener(Event.CHANGE, inEffectCbUpdateHandler);
			
			inEffectSld = new Slider();
			inEffectSld.setSize(100,10);
			inEffectSld.maximum = 360;
			inEffectSld.minimum = 0;
			inEffectSld.snapInterval = 15;
			inEffectSld.value = 0;
			inEffectSld.liveDragging = true;
			inEffectSld.addEventListener(SliderEvent.CHANGE, inEffectSldUpdateHandler);
			
			inEffectLb = new Label();
			inEffectLb.text = '';
			
			//out effect
			outEffectCb = new ComboBox();
			outEffectCb.dataProvider.addItems(outEffectArr);
			outEffectCb.labelField = 'label';
			outEffectCb.addEventListener(Event.CHANGE, outEffectCbUpdateHandler);
			
			outEffectSld = new Slider();
			outEffectSld.setSize(100,10);
			outEffectSld.maximum = 360;
			outEffectSld.minimum = 0;
			outEffectSld.snapInterval = 15;
			outEffectSld.value = 0;
			outEffectSld.liveDragging = true;
			outEffectSld.addEventListener(SliderEvent.CHANGE, outEffectSldUpdateHandler);
			
			outEffectLb = new Label()
			outEffectLb.text = '';
			
			//effect show
			cps = new Compass(50);
			cps.x = 200;
			cps.y = 140;
			addChild(cps);
			
			//type animation
			lupinCkb = new CheckBox();
			lupinCkb.label = '';
			
			//submit button
			sendBt = new Button();
			sendBt.label = '发送';
			sendBt.setSize(40, 20);
			sendBt.addEventListener(MouseEvent.CLICK, sendPopoCommentHandler);
			
			//sight
			targetSpot = (new TargetIcon()) as Bitmap;
			spotter = new Sprite();
			spotter.addChild(targetSpot);
			spotter.addEventListener(MouseEvent.MOUSE_DOWN, spotterDragStartHandler);
			spotter.addEventListener(MouseEvent.MOUSE_UP, spotterDragStopHandler);
			spotter.addEventListener(MouseEvent.MOUSE_MOVE, spotterDragUpdateHandler);
			addChild(spotter);
			
			//
			posLb = new Label();
			posLb.text = 'position';
			
			var formData:Array = [
			{label:'气泡风格',items:[styleCb,posLb]},
			{label:'内容',items:commentIpt},
			{label:'命令',items:[commandIpt,sendBt]},
			{label:'颜色',items:colorCpk},
			{label:'字号',items:sizeCb},
			{label:'文字格式',items:[boldBt,italicBt,underlineBt]},
			{label:'背景透明度',items:[opacitySld,opacityLb]},
			{label:'停留时间',items:[durationSld,durationLb]},
			//{label:'Effects',items:cps},
			{label:'进入效果',items:[inEffectCb,inEffectSld,inEffectLb]},
			{label:'退出效果',items:[outEffectCb,outEffectSld,outEffectLb]},
			{label:'打字效果', items:lupinCkb },
			];
			
			formlyt.dataSource = formData;
		}
		//api
		public function get text():String
		{
			return commentIpt.text;
		}
		
		public function get size():int
		{
			return sizeCb.selectedItem.data;
		}
		
		public function get color():int
		{
			return colorCpk.selectedColor;
		}
		
		public function get opacity():Number
		{
			return opacitySld.value;
		}
		
		public function get duration():int
		{
			return durationSld.value;
		}
		
		public function get style():String
		{
			return styleCb.selectedItem.data;
		}
		
		public function get tEffect():String
		{
			if (lupinCkb.selected)
				return 'lupin';
			
			return '';
		}
		
		public function get tStyle():String
		{
			var res:Array = [];
			
			if (boldBt.selected)
				res.push('bold');
				
			if (italicBt.selected)
				res.push('italic');
				
			if (underlineBt.selected)
				res.push('underline');
				
			return res.join(' ');
		}
		
		public function get inStyle():String
		{
			if (inEffectCb.selectedItem.data != 'fly')
				return inEffectCb.selectedItem.data;
				
			if (inEffectSld.value % 90 == 0)
			{
				var posArr:Array = ['left','drop','right','rise'];
				return posArr[Math.floor(inEffectSld.value / 90) % 4];
			}
			
			return inEffectSld.value.toString();
		}
		
		public function get outStyle():String
		{
			if (outEffectCb.selectedItem.data != 'fly')
				return  outEffectCb.selectedItem.data;
				
			if (outEffectSld.value % 90 == 0)
			{
				var posArr:Array = ['right','rise','left','drop'];
				return posArr[Math.floor(outEffectSld.value / 90) % 4];
			}
			
			return outEffectSld.value.toString();
		}
		
		//校正一下位置,正中心对准文字0点
		public function get px():int
		{
			return p.x - 17;
		}
		
		public function get py():int
		{
			return p.y + 34;
		}
		
		public function get position():String
		{
			if (style == 'subtitle')
				return 'bottom';
			
			return '';
		}
		
		private function opacitySldUpdateHandler(event:SliderEvent):void
		{
			opacityLb.text = opacitySld.value.toString();
		}
		
		private function durationSldUpdateHandler(event:SliderEvent):void
		{
			durationLb.text = durationSld.value.toString();
		}
		
		private function spotterDragUpdateHandler(event:MouseEvent=null):void
		{
			if (event == null)
			{
				p.x = p.y = 0;
				posLb.text = p.toString();
			}
			else if(event.buttonDown)
			{
				var point:Point = new Point(spotter.x + 32, spotter.y + 32);
				p = localToGlobal(point);
				posLb.text = p.toString();
			}
		}
		
		private function spotterDragStartHandler(event:MouseEvent):void
		{
			spotter.startDrag();
		}
		
		private function spotterDragStopHandler(event:MouseEvent):void
		{
			spotter.stopDrag();
			var point:Point = new Point(spotter.x + 32, spotter.y + 32);
			p = localToGlobal(point);
			if (p.x< 0 || p.x >= Player.WIDTH || p.y >= Player.HEIGHT || p.y < 0)
			{
				resetTarget();
			}
		}
		
		private function resetTarget():void
		{
			spotter.x = spotter.y = 0;
			spotterDragUpdateHandler();
		}
		
		private function sendPopoCommentHandler(event:MouseEvent):void
		{
			if (spotter.x == 0 || spotter.y == 0 || text == '')
			{
				commandIpt.text = '拖动定位器到屏幕位置,填写内容发送';
				return;
			}
			commandIpt.text = '不可用';
				
			dispatchEvent(new CommentListViewEvent(CommentListViewEvent.POPOCOMMENTSEND,null));
			commentIpt.text = '';
			resetTarget();
		}
		
		private function inEffectSldUpdateHandler(event:SliderEvent):void
		{
			cps.inIdt = inEffectSld.value;
			inEffectCbUpdateHandler();
		}
		
		private function inEffectCbUpdateHandler(event:Event=null):void
		{
			inEffectLb.text = inStyle;
		}
				
		private function outEffectSldUpdateHandler(event:SliderEvent):void
		{
			cps.outIdt = outEffectSld.value;
			outEffectCbUpdateHandler();
		}
		
		private function outEffectCbUpdateHandler(event:Event=null):void
		{
			outEffectLb.text = outStyle;
		}
	}

}