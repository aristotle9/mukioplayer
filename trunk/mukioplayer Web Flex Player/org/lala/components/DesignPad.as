package  org.lala.components
{
	//import flash.display.MovieClip;
	import adobe.utils.ProductManager;
	import com.jeroenwijering.events.AbstractView;
	import com.jeroenwijering.player.Player;
	import com.jeroenwijering.utils.Strings;
	import fl.controls.Button;
	import fl.controls.CheckBox;
	import fl.controls.DataGrid;
	import fl.controls.ComboBox;
	import fl.controls.dataGridClasses.DataGridColumn;
	import fl.controls.listClasses.CellRenderer;
	import fl.events.ListEvent;
	import flash.display.SpreadMethod;
	import flash.display.Sprite;
	import flash.events.*;
	import flash.text.TextField;
	import flash.text.TextFieldType;
	import flash.text.TextFormat;
	import flash.ui.ContextMenu;
	import flash.ui.ContextMenuItem;
	
	import org.lala.plugins.*;
	import org.lala.events.*;
	
	/**
	 * ...
	 * @author 
	 */
	public class DesignPad extends EventDispatcher
	{
		public static var modeArr:Array = [ { modename:'从左往右', mode:1 },
											{ modename:'底部居中', mode:4 },
											{ modename:'顶部居中', mode:5 }
											];
		public static var rmode:Object = { '1':0,
										   '4':1,
										   '5':2
		};
		public static var sizeArr:Array = [ { sizename:'smaller', size:10},
											{ sizename:'small', size:15 },
											{ sizename:'middle', size:25 },
											{ sizename:'big', size:37 }
											];
		public static var rsize:Object = { '10':0,
										   '15':1,
										   '25':2,
										   '37':3
		};
		private var clip:Sprite;
		private var lstSender:CommentListSender;
		private var previewPad:Sprite;
		//private var previewBox:TextField;
		
		private var tabs:TabButtons;
		private var edt:TextField;
		private var dg:DataGrid;
		private var modCb:ComboBox;
		private var modCbLabel:TextField;
		private var szCb:ComboBox;
		private var szCbLabel:TextField;
		private var cpk:MColorPicker;
		
		private var stLabel:TextField;
		private var stBox:TextField;
		//buttons
		private var sendBt:Button;
		private var viviBt:Button;
		private var newBt:Button;
		private var prevBox:CheckBox;
		
		private var curItem:Object=null;

		public function DesignPad(clp:Sprite,snd:CommentListSender,prv:Sprite) 
		{
			clip = clp;
			lstSender = snd;
			previewPad = prv;
			createUI();
			
		}
		
		private function createUI():void
		{
			tabs = new TabButtons(clip, 0, 0, CommentListSender.WIDTH - CommentListSender.X0, CommentListSender.HEIGHT - 54 - 30);
			tabs.addTab('编辑');
			tabs.addTab('管理');
			
			edt = CommentViewManager.getDeviceTextField();
			//edt.defaultTextFormat = tf;
			//edt.setTextFormat(tf);
			edt.text = '';
			edt.type = TextFieldType.INPUT;
			edt.x = 1;
			edt.y = 0;
			edt.width = CommentListSender.WIDTH - CommentListSender.X0-4;
			edt.height = CommentListSender.HEIGHT -54-2-100;
			edt.border = true;
			edt.borderColor = 0x70767a;
			edt.multiline = true;
			edt.wordWrap = false;
			edt.selectable = true;
			edt.alwaysShowSelection = true;
			edt.maxChars = 1024;
			//edt.addEventListener(FocusEvent.FOCUS_IN, edtFocusHandler);
			//edt.addEventListener(FocusEvent.FOCUS_OUT, edtFocusHandler);
			edt.addEventListener(Event.CHANGE, edtChangeHandler);
			
			//clip.addChild(edt);
			tabs.addItem(0, edt);
			
			dg = new DataGrid();
			dg.x = 1;// edt.x + edt.width + 1;
			dg.y = 0;// edt.y;
			dg.setSize(CommentListSender.WIDTH - CommentListSender.X0 - 4, edt.height);
			dg.sortableColumns = false;
			//dg.editable = true;
			dg.columns = ['name','mode','size','color','enable'];
			dg.columns[0].headerText = '名称';
			dg.columns[1].headerText = '模式';
			(dg.columns[1] as DataGridColumn).labelFunction = function(item:Object):String
			{
				return modeArr[rmode[item.mode]].modename;
			}
			dg.columns[2].headerText = '大小';
			(dg.columns[2] as DataGridColumn).labelFunction = function(item:Object):String
			{
				return sizeArr[rsize[item.size]].sizename;
			}
			dg.columns[3].headerText = '颜色';
			dg.columns[3].cellRenderer = ColorCell;
			(dg.columns[3] as DataGridColumn).labelFunction = function(item:Object):String
			{
				return Strings.color(item.color);
			}
			dg.columns[4].headerText = '预览';
			dg.columns[4].cellRenderer = CheckCellRenderer;
			
			dg.setStyle("cellRenderer", AlternatingRowColors);
			dg.addEventListener(Event.CHANGE, loadItemHandler);
			dg.addEventListener(ListEvent.ITEM_DOUBLE_CLICK, changeToEdtHandler);
			dg.addEventListener(ListEvent.ITEM_CLICK, visibleToggleHandler);
			var delMItm:ContextMenuItem = new ContextMenuItem('删除',true);
			delMItm.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, delMItmHandler);
			var preMItm:ContextMenuItem = new ContextMenuItem('前移');
			preMItm.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, preMItmHandler);
			var nxtMItm:ContextMenuItem = new ContextMenuItem('后移');
			nxtMItm.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, nxtMItmHandler);
			var ctmn:ContextMenu = new ContextMenu();
			ctmn.hideBuiltInItems();
			ctmn.customItems.push(preMItm);
			ctmn.customItems.push(nxtMItm);
			ctmn.customItems.push(delMItm);
			dg.contextMenu = ctmn;
			
			//clip.addChild(dg);
			tabs.addItem(1, dg);
			//
			modCbLabel = new TextField();
			modCbLabel.x = 1;
			modCbLabel.y = edt.y + edt.height + 2+5;
			modCbLabel.height = 25;
			modCbLabel.width = 30;
			modCbLabel.text = '模式';			
			modCbLabel.selectable = false;
			modCbLabel.setTextFormat(CommentListSender.tf);
			
			//clip.addChild(modCbLabel);
			tabs.addItem(0, modCbLabel);
			//
			modCb = new ComboBox();
			modCb.move(modCbLabel.x + modCbLabel.width,edt.y + edt.height + 2);
			modCb.setSize(85, 25.4);
			modCb.dataProvider.addItems(modeArr);
			modCb.labelField = 'modename';
			//modCb.selectedIndex = 0;
			modCb.addEventListener(Event.CHANGE, modeChangeHandler);
			
			//clip.addChild(modCb);
			tabs.addItem(0, modCb);
			
			//
			szCbLabel = new TextField();
			szCbLabel.x = modCb.x+modCb.width+1;
			szCbLabel.y = edt.y + edt.height + 2+5;
			szCbLabel.height = 25;
			szCbLabel.width = 30;
			szCbLabel.text = '字号';			
			szCbLabel.selectable = false;
			szCbLabel.setTextFormat(CommentListSender.tf);
			
			//clip.addChild(szCbLabel);
			tabs.addItem(0, szCbLabel);
			//
			szCb = new ComboBox();
			szCb.move(szCbLabel.x + szCbLabel.width,edt.y + edt.height + 2);
			szCb.setSize(85, 25.4);
			szCb.dataProvider.addItems(sizeArr);
			szCb.labelField = 'sizename';
			//szCb.selectedIndex = 2;
			szCb.addEventListener(Event.CHANGE, sizeChangeHandler);
			
			//clip.addChild(szCb);
			tabs.addItem(0, szCb);
			//
			cpk = new MColorPicker('left');
			cpk.x = szCb.x + szCb.width + 2;
			cpk.y = edt.y + edt.height + 2;
			//cpk.color = 0xffffff;
			cpk.addEventListener(Event.SELECT, cpkSelectHandler);
			
			//clip.addChild(cpk);
			tabs.addItem(0, cpk);
			
			//
			stLabel = new TextField();
			stLabel.x = cpk.x+25+1;
			stLabel.y = edt.y + edt.height + 2+5;
			stLabel.height = 25;
			stLabel.width = 45;
			stLabel.text = '时点/秒:';			
			stLabel.selectable = false;
			stLabel.setTextFormat(CommentListSender.tf);
			
			//clip.addChild(stLabel);
			tabs.addItem(0, stLabel);
			//
			stBox = new TextField();
			stBox.x = stLabel.x + stLabel.width + 1;
			stBox.y = edt.y + edt.height + 2+5;
			stBox.width = 55;
			stBox.height = 15.4;
			stBox.setTextFormat(CommentListSender.tf);
			stBox.defaultTextFormat = CommentListSender.tf;
			stBox.type = TextFieldType.INPUT;
			stBox.border = true;
			stBox.borderColor = 0x70767a;
			stBox.restrict = '0-9.';
			stBox.maxChars = 16;
			
			//clip.addChild(stBox);
			tabs.addItem(0, stBox);
			
			//previewPad Toggle visible
			prevBox = new CheckBox();
			prevBox.move(1, edt.y + edt.height + 2);
			prevBox.setSize(85, 25.4);
			prevBox.label = '预览开关';
			prevBox.selected = true;
			prevBox.addEventListener(Event.CHANGE, prevBoxHandler);
			
			tabs.addItem(1, prevBox);
			
			newBt = new Button();
			newBt.label = '新建弹幕';
			newBt.move(1,CommentListSender.HEIGHT-27-27-25.4-27);
			newBt.setSize(71,25.4);
			newBt.addEventListener(MouseEvent.CLICK, newBtHandler);
			
			//clip.addChild(newBt);
			tabs.addItem(1, newBt);
			
			viviBt = new Button();
			viviBt.label = '动态预览';
			viviBt.move(newBt.x+newBt.width+2,CommentListSender.HEIGHT-27-27-25.4-27);
			viviBt.setSize(71,25.4);
			viviBt.addEventListener(MouseEvent.CLICK, viviBtHandler);
			
			//clip.addChild(viviBt);
			tabs.addItem(1, viviBt);
			
			sendBt = new Button();
			sendBt.label = '发射弹幕';
			sendBt.move(viviBt.x+viviBt.width+2,CommentListSender.HEIGHT-27-27-25.4-27);
			sendBt.setSize(71,25.4);
			sendBt.addEventListener(MouseEvent.CLICK, sendBtHandler);
			
			//clip.addChild(sendBt);
			tabs.addItem(1, sendBt);
			
			//previewBox = CommentViewManager.getDeviceTextField();
			//previewBox.text = '';
			//previewBox.x = 0;
			//previewBox.y = 0;
			//previewBox.border = true;
			//previewBox.borderColor = 0xff0000;// 0x70767a;
			//previewBox.selectable = false;
			//previewBox.autoSize = 'left';
			//
			//previewPad.visible = false;
			//
			//previewPad.addChild(previewBox);
			//sizeChangeHandler();
			newBtHandler();
			
		}
		private function preMItmHandler(evt:ContextMenuEvent):void
		{
			if (dg.selectedIndex == 0)
			{
				return;
			}

			previewPad.setChildIndex(previewBox, dg.length - dg.selectedIndex);
			var itm:Object = dg.replaceItemAt(dg.getItemAt(dg.selectedIndex), dg.selectedIndex - 1);
			dg.replaceItemAt(itm, dg.selectedIndex);
			dg.selectedIndex -= 1;
		}
		private function nxtMItmHandler(evt:ContextMenuEvent):void
		{
			if (dg.selectedIndex == dg.length -1)
			{
				return;
			}

			previewPad.setChildIndex(previewBox, dg.length - dg.selectedIndex - 2);
			var itm:Object = dg.replaceItemAt(dg.getItemAt(dg.selectedIndex), dg.selectedIndex +1);
			dg.replaceItemAt(itm, dg.selectedIndex);
			dg.selectedIndex += 1;
			
		}
		private function delMItmHandler(evt:ContextMenuEvent):void
		{
			var i:int = dg.selectedIndex;
			if (dg.length > 0)
			{
				previewPad.removeChild(previewBox);
				dg.removeItem(curItem);
			}
			if (dg.length == 0)
			{
				newItem();
			}
			else
			{
				if (i < dg.length)
				{
					dg.selectedIndex = i;
				}
				else
				if (i - 1 >= 0)
				{
					dg.selectedIndex = i -1;
				}
				else
				{
					dg.selectedIndex = 0;
				}
				loadItemHandler();
			}
		}
		private function prevBoxHandler(evt:Event):void
		{
			previewPad.visible = prevBox.selected;
		}
		private function prevBoxFactory():TextField
		{
			var tf:TextField = CommentViewManager.getDeviceTextField();
			tf.text = '';
			tf.x = 0;
			tf.y = 0;
			tf.border = true;
			tf.borderColor = 0x70767a;// 0xff0000;// 0x70767a;
			tf.selectable = false;
			tf.autoSize = 'left';
			tf.visible = false;
			previewPad.addChildAt(tf, dg.selectedIndex == -1 ? 0 : (dg.length - dg.selectedIndex));
			return tf;
		}
		private function visibleToggleHandler(evt:ListEvent = null):void
		{
			if (evt.columnIndex == 4)
			{
				if (evt.item.mode != 1)
				{
					evt.item.prvbox.visible = evt.item.enable;
				}
			}
		}
		private function changeToEdtHandler(evt:ListEvent = null):void
		{
			if (evt.columnIndex == 4)
			{
				return;
			}
			tabs.selectedIndex = 0;
		}
		private function newBtHandler(evt:MouseEvent=null):void
		{
			newItem();
			tabs.selectedIndex = 0;
		}
		private function newItem():void
		{
			var itm:Object = {
				color:0xffffff,
				mode:1,
				size:25,
				text:'',
				stime:lstSender.stime,
				prvbox:prevBoxFactory(),
				name:'item ' + dg.length,
				enable:true
			};
//			curItem = itm;
			dg.addItemAt(itm,dg.selectedIndex == -1 ? 0 : dg.selectedIndex);
			dg.selectedItem = itm;
			loadItemHandler();
		}
		private function viviBtHandler(evt:MouseEvent):void
		{
			var i:int;
			for (i = dg.length - 1; i >= 0 ; i--)
			{
				var itm:Object = dg.getItemAt(i);
				if (itm.enable && itm.text != '')
				{
					lstSender.dispatchCommentListViewEvent(CommentListViewEvent.PREVIEWCOMMENT, { 'mode':itm.mode, 'size':itm.size, 'color':itm.color, 'stime': lstSender.stime, 'text':itm.text} );
				}
			}
			
			prevBox.selected = false;
			previewPad.visible = false;
		}
		private function sendBtHandler(evt:MouseEvent):void
		{
			if (text == '')
			return;
			lstSender.dispatchCommentListViewEvent(CommentListViewEvent.SENDCOMMENT, { 'mode':mode,'size':size,'color':color,'stime': lstSender.stime, 'text':text,'am':true } );
		}
		private function sizeChangeHandler(evt:Event=null):void
		{
			saveItem();
			setPreviewFormat();
			setPreviewPosition();
			(dg.getCellRendererAt(dg.selectedIndex, 2) as CellRenderer).label = sizeArr[rsize[size]].sizename;
		}
		private function modeChangeHandler(evt:Event):void
		{
			saveItem();
			previewBox.visible = curItem.enable;
			(dg.getCellRendererAt(dg.selectedIndex, 1) as CellRenderer).label = modeArr[rmode[mode]].modename;
			if (modCb.selectedIndex == 0)
			{
				previewBox.visible = false;
				return;
			}
			setPreviewPosition();
		}
		private function edtChangeHandler(evt:Event):void
		{
			saveItem();
			previewBox.text = text;
			if (modCb.selectedIndex == 0)
			{
				return;
			}
			setPreviewPosition();
		}
		private function setPreviewFormat():void
		{
			if (previewBox)
			{
				previewBox.defaultTextFormat = (new TextFormat('黑体', Strings.innerSize(size), color));
				previewBox.setTextFormat(previewBox.defaultTextFormat);
				previewBox.filters = color ? CommentViewManager.shadowB : CommentViewManager.shadowW;
			}
		}
		private function setPreviewPosition():void
		{
			if (previewBox)
			{
				previewBox.x = (Player.WIDTH - previewBox.width) / 2;
				if (modCb.selectedIndex == 2)
				{
					previewBox.y = 0;
				}
				else
				{
					previewBox.y = Player.HEIGHT - Strings.strHeight(text, Strings.innerSize(size));// previewBox.height;//要修改
				}
			}
		}
		private function cpkSelectHandler(evt:Event):void
		{
			saveItem();
			setPreviewFormat();
			(dg.getCellRendererAt(dg.selectedIndex, 3) as ColorCell).setStyle('icon', getIcon(color));
			(dg.getCellRendererAt(dg.selectedIndex, 3) as ColorCell).label = Strings.color(color);
		}
		//private function edtFocusHandler(evt:FocusEvent):void
		//{
			//if (evt.type == FocusEvent.FOCUS_IN)
			//{
				//if (modCb.selectedIndex != 0)
				//{
					//previewPad.visible = true;
				//}
			//}
			//else
			//{
				//previewPad.visible = false;
			//}
		//}
		private function saveItem():void
		{
			curItem.mode = mode;
			curItem.size = size;
			curItem.color = color;
			curItem.text = text;
		}
		private function loadItemHandler(evt:Event = null):void
		{
			if (curItem)
			{
				previewBox.borderColor = 0x70767a;
				previewBox.alpha = 0.9;
			}
			
			curItem = dg.selectedItem;
			
			previewBox.borderColor = 0xff0000;
			previewBox.alpha = 1;
			mode = curItem.mode;
			size = curItem.size;
			color = curItem.color;
			text = curItem.text;
			setPreviewFormat();
			setPreviewPosition();
		}
		public function get mode():int
		{
			return modCb.selectedItem.mode;
		}
		public function get size():int
		{
			return szCb.selectedItem.size;
		}
		public function get text():String
		{
			return edt.text;
		}
		public function get color():int
		{
			return cpk.color;
		}
		public function set mode(md:int):void
		{
			if(rmode[md] != null)
				modCb.selectedIndex = rmode[md];
		}
		public function set size(sz:int):void
		{
			if(rsize[sz] != null)
				szCb.selectedIndex = rsize[sz];
		}
		public function set text(txt:String):void
		{
			edt.text = txt;
			previewBox.text = txt;
		}
		public function set color(clr:int):void
		{
			cpk.color = clr;
		}
		public function get previewBox():TextField
		{
			return curItem.prvbox;
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
		//public function get curItem():Object
		//{
			//if (dg.selectedIndex == -1)
			//{
				//return null;
			//}
			//return dg.selectedItem;
		//}
	}

}