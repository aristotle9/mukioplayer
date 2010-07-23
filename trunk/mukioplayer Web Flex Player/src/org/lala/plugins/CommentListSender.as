package org.lala.plugins
{
	/**
	 * ...
	 * @author 
	 */
	import fl.controls.ColorPicker;
	import fl.controls.DataGrid;
	import fl.controls.dataGridClasses.DataGridColumn;
	import fl.events.ColorPickerEvent;
	import fl.controls.Button;
	import fl.controls.CheckBox;
	import fl.controls.ScrollPolicy;
	import fl.data.DataProvider;
	import fl.events.ComponentEvent;
	import fl.events.DataGridEvent;
	import fl.events.ListEvent;
	import flash.display.*;
	import flash.events.*;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.text.TextFieldType;
	import flash.ui.Keyboard;
	import fl.managers.StyleManager;
	import flash.ui.ContextMenuItem;
	import flash.ui.ContextMenu;
	import flash.utils.Timer;
	

	
	import com.jeroenwijering.events.*;
	import com.jeroenwijering.utils.*;
	import com.jeroenwijering.plugins.*;
	import com.jeroenwijering.models.*;
	import com.jeroenwijering.player.*;
	
	import org.lala.events.*;
	import org.lala.models.*;
	import org.lala.utils.*;
	import org.lala.components.*;
	
	public class CommentListSender extends EventDispatcher implements PluginInterface
	{
		//public static var BG_COLOR:int = 0x9ad8ff;
		public static var BG_COLOR:int = 0xdedeff;
		public static var FNT_COLOR:int = 0x323232;
		public static var FNT_COLOR2:int = 0x626262;
		public static var X0:int = Player.WIDTH;
		public static var Y0:int = Player.HEIGHT  + 21;//34;
		public static var WIDTH:int = 950;
		public static var HEIGHT:int = Y0 + 27;
		public static var tf:TextFormat;
		public static var tf2:TextFormat;
		
		public var config:Object={};
		public var clip:Sprite;
		public var view:AbstractView;
		public var cview:CommentView;
		private var dg:DataGrid;
		private var getter:CommentGetter;
		private var tooltip:TextField;
		
		//ui
		private var tabs:TabButtons;
		private var commentInput:TextField;
		private var sendButton:Button;
		private var selectedModeButton:Button;
		private var modeStyleControl:ModeSelectControl;
		private var colorPicker:ColorPicker;
		[Embed(source="asset/cIcon.png")]
		private var CommentIcon:Class;
		private var commentIco:Bitmap;
		
		private var trackCommentButton:CheckBox;
		
		[Embed(source="asset/cycleIcon.png")]
		private var CycleIcon:Class;
		private var cycleIco:Bitmap;
		
		private var commentCountLabel:TextField;
		
		private var windowWidth:int;
		//send mode data manager
		private var sender:CommentSender;
		//filter
		private var filterAddButton:Button;
		private var filterDatagrid:DataGrid;
		private var filterLable:TextField;
		private var filterInput:TextField;
		private var filterEnableCB:CheckBox;
		private var filterRegEnableCB:CheckBox;
		private var filterWhitelistCB:CheckBox;
		
		//order pair of the specific list index of id
		private var idIndex:Array = [];
		private var trackTimer:Timer;//ease time to make every 500 ms track a comment list
		private var oldTrackIndex:int = 0;
		private var trackIndex:int = 0;
		
		//播放时间,数据精度0.001,实际精度与帧率有关
		private var _stime:Number = 0;//current player time ahead
		
		//zoome 设计面板
		private var popodsg:PopoDesigner;

		
		public function CommentListSender(gtr:CommentGetter) :void
		{
			clip = new Sprite();
			var ctmn:ContextMenu = new ContextMenu();
			ctmn.hideBuiltInItems();
			clip.contextMenu = ctmn;//hidemenu


			clip.graphics.beginFill(BG_COLOR);
            clip.graphics.moveTo(X0, 0);
            clip.graphics.lineTo(X0, Y0);
            clip.graphics.lineTo(0, Y0);
            clip.graphics.lineTo(0,HEIGHT);
            clip.graphics.lineTo(WIDTH, HEIGHT);
            clip.graphics.lineTo(WIDTH, 0);
            clip.graphics.endFill();
			//trace('draw symbol');	

			getter = gtr;
			getter.addEventListener(CommentDataManagerEvent.SETDATA, setData);
			getter.addEventListener(CommentDataManagerEvent.ADDONE, addItem);
			getter.addEventListener(CommentDataManagerEvent.NEW, newCommentDataHandler);
			getter.listReady();
			
			trackTimer = new Timer(500);
			trackTimer.addEventListener(TimerEvent.TIMER, trackTimerHandler);
			
			sender = new CommentSender(this, getter);
			addEventListener(CommentListViewEvent.COLDTRICKER, coldTrickerHandler);
			
			createUI();
			setStyle();
		}
		//换皮肤
		private function setStyle():void
		{
			filterAddButton.setStyle('upSkin',YellowUpSkin);
			filterAddButton.setStyle('overSkin',YellowOverSkin);
			filterAddButton.setStyle('downSkin',YellowDownSkin);
			selectedModeButton.setStyle('upSkin',YellowUpSkin);
			selectedModeButton.setStyle('overSkin',YellowOverSkin);
			selectedModeButton.setStyle('downSkin',YellowDownSkin);
			selectedModeButton.setStyle('icon',ModelIcon);
			sendButton.setStyle('upSkin',YellowUpSkin);
			sendButton.setStyle('overSkin',YellowOverSkin);
			sendButton.setStyle('downSkin', YellowDownSkin);
			sendButton.setStyle('icon', SendIcon);
			tabs.bt(0).setStyle('icon',ListIcon);
			tabs.bt(1).setStyle('icon',ConfigIcon);
			
		}
		private function createUI():void
		{
			//set gloable font style
			tf = new TextFormat('simsum', '12', FNT_COLOR);
			tf2 = new TextFormat('simsum', '12', FNT_COLOR2);
			StyleManager.setStyle('textFormat', tf);
			
			//tabs
			tabs = new TabButtons(clip, X0, 0, WIDTH - X0, HEIGHT -27 - 27);
			tabs.addTab('评论列表');
			tabs.addTab('过滤设置');
			tabs.addTab('实验室');
			tabs.addEventListener(CommentListViewEvent.TBBUTTONCHANGE, tabChangeHandler);
			
			//popo designer
			popodsg = new PopoDesigner();
			popodsg.x = popodsg.y = 0;
			popodsg.addEventListener(CommentListViewEvent.POPOCOMMENTSEND, sendPopoCommentHandler);
			tabs.addItem(2, popodsg);


			//add DataGrid
			dg = new DataGrid();
			dg.x = 1;// X0 + 1 ;
			dg.y = 0;//27;
			dg.width = WIDTH - X0;
			dg.height = HEIGHT - 27 - 27;
			dg.columns = ['时间标签', '评论', '发布日期','author'];
			dg.columns[0].width = 60;
			dg.columns[0].sortOptions = Array.NUMERIC;
			dg.columns[0].labelFunction = function(item:Object):String {
				return Strings.digits(item['时间标签']);
			}
			dg.columns[1].labelFunction = function(item:Object):String {
				return Strings.cut(item['评论']);
			}
			dg.columns[1].width = 220;
			dg.columns[2].width = 128;
			dg.columns[3].width = 128;
			(dg.columns[3] as DataGridColumn).headerText = '发送者';
			
			dg.horizontalScrollPolicy = ScrollPolicy.ON;
			dg.rowHeight = 20;
			dg.addEventListener(ListEvent.ITEM_ROLL_OUT, showTooltip);
			dg.addEventListener(ListEvent.ITEM_ROLL_OVER, showTooltip);
			dg.addEventListener(ListEvent.ITEM_DOUBLE_CLICK, seekHandler);
			dg.addEventListener(DataGridEvent.HEADER_RELEASE, dgSortedHandler);
			dg.setStyle("cellRenderer", AlternatingRowColors);

			tabs.addItem(0, dg);
			dg.cacheAsBitmap = true;//提高滚动性能
			dg.opaqueBackground = 0xf1f1ff;
			
			var dgCopyItm:ContextMenuItem = new ContextMenuItem('复制选中评论');
			dgCopyItm.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, function(evt:ContextMenuEvent):void
			{
				if(dg.selectedIndex == -1)
				{
					return;
				}
			//	Clipboard.generalClipboard.clear();
			//	Clipboard.generalClipboard.setData(ClipboardFormats.TEXT_FORMAT, dg.selectedItem['评论']);
			});
			var dgCopyMn:ContextMenu = new ContextMenu();
			dgCopyMn.hideBuiltInItems();
			dgCopyMn.customItems.push(dgCopyItm);
			dg.contextMenu = dgCopyMn;
			
			//track Button
			trackCommentButton = new CheckBox();
			trackCommentButton.move(625.5, Y0+1);
			trackCommentButton.setSize( 83, 25.4);
			trackCommentButton.selected = false;
			trackCommentButton.label = '追踪弹幕';
			trackCommentButton.addEventListener(Event.CHANGE, trackCommentHandler);
			clip.addChild(trackCommentButton);
			
			//three check box
			filterEnableCB = new CheckBox();
			filterEnableCB.move(2, 7);
			filterEnableCB.setSize(100, 22);
			filterEnableCB.label = '启用过滤器';
			filterEnableCB.selected = true;
			tabs.addItem(1, filterEnableCB);
			
			filterRegEnableCB = new CheckBox();
			filterRegEnableCB.move(109, 7);
			filterRegEnableCB.setSize(140, 22);
			filterRegEnableCB.label = '启用正则表达式';
			filterRegEnableCB.selected = false;
			tabs.addItem(1, filterRegEnableCB);
			
			filterWhitelistCB = new CheckBox();
			filterWhitelistCB.move(238, 7);
			filterWhitelistCB.setSize(100, 22);
			filterWhitelistCB.label = '白名单模式';
			filterWhitelistCB.selected = false;
			tabs.addItem(1, filterWhitelistCB);
			
			filterEnableCB.addEventListener(Event.CHANGE, filterCheckHandler);
			filterRegEnableCB.addEventListener(Event.CHANGE, filterCheckHandler);
			filterWhitelistCB.addEventListener(Event.CHANGE, filterCheckHandler);
			
			//filter lable
			filterLable = new TextField();
			filterLable.text = '屏蔽关键词或表达式:';
			filterLable.autoSize = 'left';
			filterLable.setTextFormat(tf);
			filterLable.x = 0;
			filterLable.y = 41;
			filterLable.selectable = false;
			tabs.addItem(1, filterLable);
			
			//filter input
			filterInput = new TextField();
			filterInput.type = TextFieldType.INPUT;
			filterInput.border = true;
			filterInput.borderColor = 0xeeeeee;
			filterInput.background = true;
			filterInput.backgroundColor = 0xffffff;
			filterInput.x = 120;
			filterInput.y = 41;
			filterInput.width = 214;
			filterInput.height = 22;
			tabs.addItem(1, filterInput);

			//filter Button
			filterAddButton = new Button();
			filterAddButton.x = 339;
			filterAddButton.y = 39;
			filterAddButton.width = 70;
			filterAddButton.height = 25.4;
			filterAddButton.label = '添加';
			tabs.addItem(1, filterAddButton);
			
			filterAddButton.addEventListener(MouseEvent.CLICK, filterAddHandler);
			
			//filter list
			filterDatagrid = new DataGrid();
			filterDatagrid.x = 1;// X0 + 1;
			filterDatagrid.y = 95 - 27;
			filterDatagrid.width = WIDTH - X0;
			filterDatagrid.height = HEIGHT - 61 - 34 - 27;
			filterDatagrid.columns = ['过滤类别', '关键词','源'];
			filterDatagrid.columns[0].width = 70;
			filterDatagrid.columns[0].labelFunction = function(item:Object):String {
				var a:Array = ['模式', '颜色', '内容'];
				return a[item['过滤类别']];
			}
			filterDatagrid.columns[1].labelFunction = function(item:Object):String {
				if (item['过滤类别'] == 0)
				{
					//var a:Array = [null,'从右往左', '从右往左-大字蓝', '从右往左-橙','底部','顶部-大字绿'];
					var a:Array = [null,'从右往左', '从左往右', '从右往左-底部','底部','顶部','从左往右'];
					return a[item['关键词']] ? a[item['关键词']] : '不合理的模式值';
				}
				else
				{
					return item['关键词'];
				}
			}
			filterDatagrid.setStyle("cellRenderer", AlternatingRowColors);
			
			var checkCol:DataGridColumn = new DataGridColumn('enable');
			checkCol.cellRenderer = CheckCellRenderer;
			checkCol.headerText = '使用状态';
			filterDatagrid.addColumn(checkCol);
			
			filterDatagrid.addEventListener(ListEvent.ITEM_CLICK, filerListEnableHandler);
			
			tabs.addItem(1, filterDatagrid);
			
			filterDatagrid.allowMultipleSelection = true;
			
			var mnItem:ContextMenuItem = new ContextMenuItem('删除选中关键字');
			mnItem.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, function(evt:ContextMenuEvent):void
			{
				if (filterDatagrid.selectedIndices.length < 1)
				{
					return;
				}

				for each(var itm:Object in filterDatagrid.selectedItems)
				{
					dispatchCommentListViewEvent(CommentListViewEvent.FILTERDELETE, itm['id']);
					filterDatagrid.removeItem(itm);
				}
				filterDatagrid.clearSelection();
			});
			var ctxMenu:ContextMenu = new ContextMenu();
			ctxMenu.hideBuiltInItems();
			ctxMenu.customItems.push(mnItem);
			filterDatagrid.contextMenu = ctxMenu;
			
			//tooltip textbox
			tooltip = new TextField();
			tooltip.x = X0+60;
			tooltip.background = true;
			tooltip.backgroundColor = BG_COLOR;
			tooltip.border = true;
			tooltip.borderColor = FNT_COLOR;
			tooltip.autoSize = 'left';
			tooltip.defaultTextFormat = tf;
			tooltip.visible = false;
			tooltip.y = 0
			tooltip.text = '';

			//sel mode
			selectedModeButton = new Button();
			selectedModeButton.move(2, Y0+1);
			selectedModeButton.setSize(71, 25.4);
			selectedModeButton.label = '样式';
			clip.addChild(selectedModeButton);
			
			//sel box
			modeStyleControl = new ModeSelectControl();
			modeStyleControl.x = 0;
			modeStyleControl.y = Y0 + 1 - 187 - 2;
			modeStyleControl.ref = selectedModeButton;
			clip.addChild(modeStyleControl);
			modeStyleControl.addEventListener(CommentListViewEvent.MODESTYLESIZECHANGE, modeStyleHandler);
			
			//color picker
			colorPicker = new ColorPicker();
			colorPicker.x = selectedModeButton.x + selectedModeButton.width + 3;
			colorPicker.y = selectedModeButton.y + 1;
			colorPicker.selectedColor = 0xffffff;
			colorPicker.addEventListener(ColorPickerEvent.CHANGE, function(evt:ColorPickerEvent):void {
				sender.color = colorPicker.selectedColor;
				} );
			clip.addChild(colorPicker);
			//input 
			commentInput = new TextField();
			commentInput.type = TextFieldType.INPUT;
			commentInput.x = 76 + 28;
			commentInput.y = Y0 + 2.5 - 2;
			commentInput.width = 332.6 + 28;
			commentInput.height = 22 + 2;
			commentInput.border = true;
			commentInput.borderColor = 0xFFCB1E;
			commentInput.background = true;
			commentInput.backgroundColor = 0xf1f1ff;
			commentInput.defaultTextFormat = new TextFormat('simhei', '20', 0);
			commentInput.setTextFormat(commentInput.defaultTextFormat);
			clip.addChild(commentInput);
			
			commentInput.addEventListener(FocusEvent.FOCUS_IN, inputFocusHandler);
			commentInput.addEventListener(FocusEvent.FOCUS_OUT, inputFocusHandler);
			commentInput.addEventListener(KeyboardEvent.KEY_DOWN, inputEnterHandler);
			
			//send button
			sendButton = new Button();
			sendButton.x = 413.4 + 56;
			sendButton.y = Y0 + 1;
			sendButton.width = 71;
			sendButton.height = 25.4;
			sendButton.label = '发表';
			clip.addChild(sendButton);
			sendButton.addEventListener(MouseEvent.CLICK, sendButtonHandler);
			
			commentCountLabel = new TextField();
			commentCountLabel.x = 714;
			commentCountLabel.y = Y0+4;
			commentCountLabel.autoSize = 'left';
			commentCountLabel.multiline = false;
			commentCountLabel.text = '';
			commentCountLabel.selectable = false;
			commentCountLabel.defaultTextFormat = tf;
			
			clip.addChild(commentCountLabel);
			
			clip.addChild(tooltip);

		}
		
		private function modeStyleHandler(evt:CommentListViewEvent):void
		{
			sender.mode = modeStyleControl.mode;
			sender.size = modeStyleControl.size;
			sender.color = modeStyleControl.color;
			colorPicker.selectedColor = modeStyleControl.color;
		}
		
		private function parseCmd(str:String):Boolean
		{
			return false;
			
		}
		
		//send popo comment
		private function sendPopoCommentHandler(event:CommentListViewEvent):void
		{
			var data:Object = {
				text:popodsg.text,
				stime:stime,
				mode:9,
				border:true,
				size:popodsg.size,
				tStyle:popodsg.tStyle,
				color:popodsg.color,
				date:Strings.date(),
				x:popodsg.px,
				y:popodsg.py,
				alpha:popodsg.opacity,
				style:popodsg.style,
				duration:popodsg.duration,
				inStyle:popodsg.inStyle,
				outStyle:popodsg.outStyle,
				position:popodsg.position,
				tEffect:popodsg.tEffect
				};
			dispatchCommentListViewEvent(CommentListViewEvent.SENDPOPOCOMMENT, data);
			
		}
		private function sendButtonHandler(evt:MouseEvent=null):void
		{
			if (parseCmd(commentInput.text))
			{
				return;
			}

			if (commentInput.text.length > 0)
			{
				dispatchCommentListViewEvent(CommentListViewEvent.SENDCOMMENT, { 'stime': _stime, 'text':commentInput.text,'am':false } );
				commentInput.text = '';
			}
		}
		private function filterCheckHandler(evt:Event):void
		{
			CommentFilter.bEnable = filterEnableCB.selected;
			CommentFilter.bRegEnable = filterRegEnableCB.selected;
			CommentFilter.bWhiteList = filterWhitelistCB.selected;
			dispatchCommentListViewEvent(CommentListViewEvent.FILTERCHECKBOXTOGGLE, null);
		}
		private function filterAddHandler(evt:MouseEvent):void
		{
			if (filterInput.text != '')
			{
				dispatchCommentListViewEvent(CommentListViewEvent.FILTERADD, filterInput.text);
				filterInput.text = '';
			}
		}
		private function dgSortedHandler(evt:DataGridEvent):void
		{
			trackCommentButton.selected = false;
			dispatchCommentListViewEvent(CommentListViewEvent.TRACKTOGGLE, false);

		}
		private function tabChangeHandler(evt:CommentListViewEvent):void
		{
			trackCommentButton.selected = false;
			dispatchCommentListViewEvent(CommentListViewEvent.TRACKTOGGLE, false);
		}
		
		private function inputEnterHandler(evt:KeyboardEvent=null):void
		{
			//parseCmd(commentInput.text);
			if (!evt || evt.keyCode == Keyboard.ENTER)
			{
				sendButtonHandler();
				//commentInput.y = Y0+1.5;
				//commentInput.height = 22;
				//sendButton.setFocus();
			}
		}
		private function inputFocusHandler(evt:FocusEvent):void
		{
			//if (commentInput.enabled)
			//{
				if (evt.type == FocusEvent.FOCUS_IN)
				{
					//commentInput.y = Y0-5.9;
					//commentInput.height = 30.4;
					view.skin.stage.addEventListener(MouseEvent.CLICK, stageClickHandler);
				}
				else
				{
					//commentInput.y = Y0+1.5;
					//commentInput.height = 22;
				}
			//}
		}
		private function stageClickHandler(evt:MouseEvent):void
		{
			if (!commentInput.hitTestPoint(evt.stageX,evt.stageY))
			{
				sendButton.setFocus();
				view.skin.stage.removeEventListener(MouseEvent.CLICK, stageClickHandler);
			}
		}
		public function initializePlugin(vw:AbstractView):void
		{
			view = vw;
			view.addControllerListener(ControllerEvent.RESIZE, resizeHandler);
			view.addControllerListener(ControllerEvent.ITEM,itemHandler);
			view.addModelListener(ModelEvent.TIME, timeHandler);
			//trace('hello');
			
			cview.addEventListener(CommentViewEvent.TRACK, trackHandler);
			cview.addEventListener(CommentViewEvent.FILTERADD, filterListAdd);
			cview.addEventListener(CommentViewEvent.FILTEINITIAL, filterCheckBoxInitial);

			//循环
			cycleIco = new CycleIcon() as Bitmap;
			cycleIco.alpha = .5;
			view.getPlugin('controlbar').addButton(cycleIco, 'repeat', function(event:MouseEvent):void
			{
				if (view.config['repeat'] != 'single')
				{
					view.config['repeat']  = 'single';
					cycleIco.alpha = 1;
				}
				else
				{
					view.config['repeat']  = 'none';
					cycleIco.alpha = .5;
				}
			});
			//显隐弹幕
			commentIco = new CommentIcon() as Bitmap;
			view.getPlugin('controlbar').addButton(commentIco, 'comment', function(event:MouseEvent):void
			{
				if (view.config['comment'] != false)
				{
					view.config['comment']  = false;
					commentIco.alpha = .5;
				}
				else
				{
					view.config['comment']  = true;
					commentIco.alpha = 1;
				}
				dispatchCommentListViewEvent(CommentListViewEvent.DISPLAYTOGGLE, view.config['comment']);
			});

		}
		private function filterCheckBoxInitial(evt:CommentViewEvent):void
		{
			filterEnableCB.selected = CommentFilter.bEnable;
			filterRegEnableCB.selected = CommentFilter.bRegEnable;
			filterWhitelistCB.selected = CommentFilter.bWhiteList;
		}
		private function filterListAdd(evt:CommentViewEvent):void
		{
			var dp:DataProvider = filterDatagrid.dataProvider;
			dp.addItem( { '过滤类别':evt.data.mode,
			'关键词':evt.data.exp,
			'源':evt.data.data,
			'id':evt.data.id,
			'enable':evt.data.enable } );
			filterDatagrid.selectedIndex = dp.length - 1;
			filterDatagrid.scrollToSelected();
		}
		private function trackTimerHandler(evt:TimerEvent):void
		{
			if (trackCommentButton.selected && oldTrackIndex != trackIndex)
			{
				dg.selectedItem = idIndex[trackIndex];
				dg.scrollToSelected();
				oldTrackIndex = trackIndex;
			}
		}
		private function trackHandler(evt:CommentViewEvent):void
		{
			trackIndex = evt.data as int;
		}
		private function timeHandler(evt:ModelEvent):void
		{
			_stime = evt.data.position;
		}
		private function itemHandler(evt:ControllerEvent):void
		{
			var idx:Number = view.config['item'];
			var itm:Object = view.playlist[idx];

			if (itm['cid'] == undefined && itm['vid'] != '-1')
			{
				itm['cid'] = itm['vid'];
			}
			if (itm['nico'] != undefined)
			{
				itm['nico'] = true;
			}
			else
			{
				itm['nico'] = false;
			}
			
			if(itm['cfile'])
			{
				getter.load(itm['cfile'],itm['type'], true, itm['nico'],true);
			}
			else if(itm['cid'])
			{
				getter.load(itm['cid'],itm['type'],false,false,true);
			}
			else
			{
				getter.load('',itm['type'], true, false, true, false);//clear the comments
			}
		}
		private function resizeHandler(evt:ControllerEvent=null):void
		{

			clip.x = config['x'];
			clip.y = config['y'];
			clip.height = config['height'];
			clip.width = config['width'];
			clip.visible = config['visible'];
			clip.scaleX = clip.scaleY = 1;
			
			trackCommentButton.selected = false;
			dispatchCommentListViewEvent(CommentListViewEvent.TRACKTOGGLE, false);
		}
		private function setData(evt:CommentDataManagerEvent):void
		{
			var dp:DataProvider = new DataProvider();
			var arr:Object = evt.data;
			idIndex.length = arr.length;
			for (var i:int=0; i < arr.length; i++)
			{
				dp.addItem( { '时间标签':arr[i]['stime'], '评论':arr[i]['text'], '发布日期':arr[i]['date'],'id':arr[i]['id']} );
				idIndex[arr[i].id] = dp.getItemAt(dp.length-1);
			}
			dg.dataProvider = dp;
		}
		private function newCommentDataHandler(evt:CommentDataManagerEvent):void
		{
			dg.removeAll();
			commentCountLabel.text = '当前评论条目 0';
		}
		private function addItem(evt:CommentDataManagerEvent):void
		{
			var dp:DataProvider = dg.dataProvider;
			dp.addItem( { '时间标签':evt.data['stime'], '评论':evt.data['text'], '发布日期':evt.data['date'],'id':evt.data['id'],'author':evt.data['author']} );
			idIndex.length++;
			idIndex[evt.data.id] = dp.getItemAt(dp.length - 1);
			commentCountLabel.text = '当前评论条目 ' + dp.length;
		}
		private function showTooltip(evt:ListEvent):void
		{
			if (evt.type == ListEvent.ITEM_ROLL_OUT)
			{
				tooltip.visible = false;
			}
			else if(evt.columnIndex == 1)
			{
				tooltip.text = evt.item['评论'];
				tooltip.y = clip.mouseY + 2;
				tooltip.visible = true;
			}
		}
		
		private function trackCommentHandler(evt:Event):void
		{
			var cbx:CheckBox = evt.target as CheckBox;
			dispatchCommentListViewEvent(CommentListViewEvent.TRACKTOGGLE, cbx.selected);
			if (cbx.selected)
			{
				dg.dataProvider.sortOn('时间标签', Array.NUMERIC);
				trackTimer.start();
			}
			else
			{
				trackTimer.stop();
			}
		}
		
		public function dispatchCommentListViewEvent(type:String, data:Object):void
		{
			dispatchEvent(new CommentListViewEvent(type, data));
		}
		private function filerListEnableHandler(evt:ListEvent):void
		{
			if (evt.columnIndex == 3)
			{
				dispatchCommentListViewEvent(CommentListViewEvent.FILTERLISTENABLETOGGLE,{'id':evt.item.id,'enable':evt.item.enable});
			}
		}
		private function coldTrickerHandler(evt:CommentListViewEvent):void
		{
			sendButton.enabled = evt.data.enable;
			sendButton.label = evt.data.label;
			commentInput.type = evt.data.enable ? TextFieldType.INPUT : TextFieldType.DYNAMIC;
		}
		
		private function seekHandler(evt:ListEvent):void
		{
			view.sendEvent('SEEK', evt.item['时间标签']);
			trace('seek to ' + evt.item['时间标签']);
		}
		
		public function get stime():Number
		{
			return _stime;
		}
		
		public function log(a:*):void
		{
			commentInput.text = Strings.cut(String(a));
		}
	}

}