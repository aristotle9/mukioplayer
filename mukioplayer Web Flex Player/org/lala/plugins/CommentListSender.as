package org.lala.plugins
{
	/**
	 * ...
	 * @author 
	 */
	//import fl.controls.ColorPicker;
	import fl.controls.DataGrid;
	import fl.controls.dataGridClasses.DataGridColumn;
	//import fl.controls.TextInput;
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
	
	//import flash.desktop.NativeApplication;//
	//import flash.display.NativeWindow;
	
	import flash.desktop.Clipboard;
	import flash.desktop.ClipboardFormats;
	//import flash.events.NativeDragEvent;
	//import flash.desktop.NativeDragManager;
	//import flash.filesystem.File;
	
	import com.jeroenwijering.events.*;
	import com.jeroenwijering.utils.*;
	import com.jeroenwijering.plugins.*;
	import com.jeroenwijering.models.*;
	import com.jeroenwijering.player.*;
	
	import org.lala.events.*;
	import org.lala.models.*;
	import org.lala.utils.*;
	
	public class CommentListSender extends EventDispatcher implements PluginInterface
	{
		//public static var BG_COLOR:int = 0x9ad8ff;
		public static var BG_COLOR:int = 0xddddff;
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
		//private var graber:AcfunGraber;
		//private var mklist:MukioPlaylist;
		
		//ui
		private var tabs:TabButtons;
		private var commentInput:TextField;
		//private var commentInput:TextInput;
		//private var transtoItm:NativeMenuItem;
		private var sendButton:Button;
		private var selectedModeButton:Button;
		//private var selectWindow:GroupButtons;
		private var modeStyleControl:ModeSelectControl;
		private var colorPicker:MColorPicker;
		private var toggleViewButton:CheckBox;
		//private var commentListTabButton:Button;
		//private var filterTabButton:Button;
		//private var listShape:Sprite;
		private var trackCommentButton:CheckBox;
		private var toggleRepeatButton:CheckBox;
		private var commentCountLabel:TextField;
		
		private var windowWidth:int;
		//send mode data manager
		private var sender:CommentSender;
		//filter
		private var filterAddButton:Button;
		private var filterDatagrid:DataGrid;
		private var filterLable:TextField;
		private var filterInput:TextField;
		//private var filterInput:TextInput;
		//private var filterShape:Sprite;
		private var filterEnableCB:CheckBox;
		private var filterRegEnableCB:CheckBox;
		private var filterWhitelistCB:CheckBox;
		//playlist
		//private var playlistDataGrid:DataGrid;
		
		//private var infoTf:TextField;
		//order pair of the specific list index of id
		private var idIndex:Array = [];
		private var trackTimer:Timer;//ease time to make every 500 ms track a comment list
		private var oldTrackIndex:int = 0;
		private var trackIndex:int = 0;
		
		private var _stime:Number = 0;//current player time ahead
		//rich editor
		//private var richInput:TextField;
		//private var sendRichButton:Button;
		//private var dsgPad:DesignPad;
		//private var previewPad:Sprite;
		
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
			trace('draw symbol');	

			getter = gtr;
			getter.addEventListener(CommentDataManagerEvent.SETDATA, setData);
			getter.addEventListener(CommentDataManagerEvent.ADDONE, addItem);
			getter.addEventListener(CommentDataManagerEvent.NEW, newCommentDataHandler);
			getter.listReady();
			
			trackTimer = new Timer(500);
			trackTimer.addEventListener(TimerEvent.TIMER, trackTimerHandler);
			
			sender = new CommentSender(this, getter);
			addEventListener(CommentListViewEvent.COLDTRICKER, coldTrickerHandler);
			
			//clip.addEventListener(NativeDragEvent.NATIVE_DRAG_ENTER, dragHandler);
			//trace("dragHandler : ");
			//clip.addEventListener(NativeDragEvent.NATIVE_DRAG_DROP, dropHandler);
			
			//graber = new AcfunGraber();
			//graber.addEventListener(AcfunGraberEvent.COMPLETE, graberHandler);
			//graber.addEventListener(AcfunGraberEvent.ADDITEM, addItemGraberHandler);
			//graber.addEventListener(AcfunGraberEvent.CLEARITEMS, clearItemsGraberHandler);
			//graber.addEventListener(AcfunGraberEvent.HTMLINFO, setInfoGraberHandler);
			
			//mklist = new MukioPlaylist();
			//mklist.addEventListener(MukioPlaylistEvent.ADDITEM,addMkPlaylistHandler);
			createUI();
			setStyle();
		}
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
			
			//tab button
			//commentListTabButton = new Button();
			//commentListTabButton.x = X0 + 2;
			//commentListTabButton.y = 4;
			//commentListTabButton.width = 114;
			//commentListTabButton.height = 27;
			//commentListTabButton.label = '评论列表';
			//clip.addChild(commentListTabButton);
			//
			//commentListTabButton.setStyle('textFormat',tf2);
			//commentListTabButton.setStyle('disabledTextFormat',tf);
			//commentListTabButton.toggle = true;
			//commentListTabButton.addEventListener(Event.CHANGE, tabChangeHandler);
			//commentListTabButton.selected = true;
			//commentListTabButton.enabled = false;
			
			//tab button of filter
			//filterTabButton = new Button();
			//filterTabButton.x = X0 + 2 + 114 + 2;
			//filterTabButton.y = 4;
			//filterTabButton.width = 114;
			//filterTabButton.height = 27;
			//filterTabButton.label = '过滤设置';
			//clip.addChild(filterTabButton);
			//
			//filterTabButton.setStyle('textFormat',tf2);
			//filterTabButton.setStyle('disabledTextFormat',tf);
			//filterTabButton.toggle = true;
			//filterTabButton.addEventListener(Event.CHANGE, tabChangeHandler);
			//filterTabButton.selected = true;
			//
			//list shape
			//listShape = new Sprite();
			//listShape.x = X0;
			//listShape.y = 27;
			//listShape.scaleX = listShape.scaleY = 1;
			//
			//listShape.graphics.beginFill(0xb4d7ed);
			//listShape.graphics.drawRect(0, 0, HEIGHT, 34);
			//listShape.graphics.endFill();
			//
			//clip.addChild(listShape);
			//tabs
			tabs = new TabButtons(clip, X0, 0, WIDTH - X0, HEIGHT -27 - 27);
			tabs.addTab('评论列表');
			tabs.addTab('过滤设置');
			//tabs.addTab('弹幕设计');
			//tabs.addTab('章节列表');
			//tabs.addTab('网页信息');
			tabs.addEventListener(CommentListViewEvent.TBBUTTONCHANGE, tabChangeHandler);

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

			//clip.addChild(dg);
			tabs.addItem(0, dg);
			dg.cacheAsBitmap = true;//提高滚动性能
			
			//playlist
			//playlistDataGrid = new DataGrid();
			//playlistDataGrid.move(1, 0);
			//playlistDataGrid.setSize(WIDTH - X0, HEIGHT - 54);
			//var ttcol:DataGridColumn = new DataGridColumn('title');
			//ttcol.headerText = '标题';
			//playlistDataGrid.addColumn(ttcol);
			//var pttcol:DataGridColumn = new DataGridColumn('ptitle');
			//pttcol.headerText = '分标题';
			//pttcol.sortCompareFunction = function(a:Object, b:Object):int
			//{
				//var ai:int = parseInt(a.ptitle);
				//var bi:int = parseInt(b.ptitle);
				//if (ai > bi)
				//{
					//return -1;
				//}
				//else if ( ai < bi)
				//{
					//return 1;
				//}
				//else
				//{
					//return (a.ptitle > b.ptitle) ? -1 : ((a.ptitle < b.ptitle) ? 1 :0);
				//}
			//}
			//playlistDataGrid.addColumn(pttcol);
			//var uppercol:DataGridColumn = new DataGridColumn('upper');
			//uppercol.headerText = 'UP主';
			//playlistDataGrid.addColumn(uppercol);
			//var dtcol:DataGridColumn = new DataGridColumn('date');
			//dtcol.headerText = '上传时间';
			//dtcol.width = 128;
			//playlistDataGrid.addColumn(dtcol);
			//playlistDataGrid.setStyle("cellRenderer", AlternatingRowColors);
			//
			//playlistDataGrid.addEventListener(ListEvent.ITEM_DOUBLE_CLICK, playItemHandler);
			//
			//tabs.addItem(2, playlistDataGrid);
			
			//infoTf = new TextField();
			//infoTf.defaultTextFormat = tf;
			//infoTf.autoSize = 'left';
			//infoTf.x = 1;
			//infoTf.y = 2;
			//infoTf.width = WIDTH - X0;
			//infoTf.multiline = true;
			//infoTf.wordWrap = true;
			//infoTf.selectable = false;
			//tabs.addItem(3, infoTf);
			
			var dgCopyItm:ContextMenuItem = new ContextMenuItem('复制选中评论');
			dgCopyItm.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, function(evt:ContextMenuEvent):void
			{
				if(dg.selectedIndex == -1)
				{
					return;
				}
				Clipboard.generalClipboard.clear();
				Clipboard.generalClipboard.setData(ClipboardFormats.TEXT_FORMAT, dg.selectedItem['评论']);
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
			
			//filter shape
			//filterShape = new Sprite();
			//filterShape.x = X0;
			//filterShape.y = 27;
			//filterShape.scaleX = filterShape.scaleY = 1;
			//
			//filterShape.graphics.beginFill(0xb4d7ed);
			//filterShape.graphics.drawRect(0, 0, WIDTH - X0, 68);
			//filterShape.graphics.endFill();
			//filterShape.graphics.lineStyle(1, 0x70767a);
			//filterShape.graphics.moveTo(0, 0);
			//filterShape.graphics.lineTo(118, 0);
			//filterShape.graphics.moveTo(118 + 114, 0);
			//filterShape.graphics.lineTo(WIDTH - X0, 0);
			//
			//clip.addChild(filterShape);
			
			//filterShape.visible = false;
			//three check box
			filterEnableCB = new CheckBox();
			filterEnableCB.move(2, 7);
			filterEnableCB.setSize(100, 22);
			filterEnableCB.label = '启用过滤器';
			filterEnableCB.selected = true;
			//filterShape.addChild(filterEnableCB);
			tabs.addItem(1, filterEnableCB);
			
			filterRegEnableCB = new CheckBox();
			filterRegEnableCB.move(109, 7);
			filterRegEnableCB.setSize(140, 22);
			filterRegEnableCB.label = '启用正则表达式';
			filterRegEnableCB.selected = false;
			//filterShape.addChild(filterRegEnableCB);
			tabs.addItem(1, filterRegEnableCB);
			
			filterWhitelistCB = new CheckBox();
			filterWhitelistCB.move(238, 7);
			filterWhitelistCB.setSize(100, 22);
			filterWhitelistCB.label = '白名单模式';
			filterWhitelistCB.selected = false;
			//filterShape.addChild(filterWhitelistCB);
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
			//filterShape.addChild(filterLable);
			tabs.addItem(1, filterLable);
			
			//filter input
			filterInput = new TextField();
			//filterInput = new TextInput();
			filterInput.type = TextFieldType.INPUT;
			filterInput.border = true;
			filterInput.borderColor = 0xeeeeee;
			filterInput.background = true;
			filterInput.backgroundColor = 0xffffff;
			filterInput.x = 120;
			filterInput.y = 41;
			filterInput.width = 214;
			filterInput.height = 22;
			//filterShape.addChild(filterInput);
			tabs.addItem(1, filterInput);

			//filter Button
			filterAddButton = new Button();
			filterAddButton.x = 339;
			filterAddButton.y = 39;
			filterAddButton.width = 70;
			filterAddButton.height = 25.4;
			filterAddButton.label = '添加';
			//filterShape.addChild(filterAddButton);
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
			
			//clip.addChild(filterDatagrid);
			tabs.addItem(1, filterDatagrid);
			
			//filterDatagrid.visible = false;
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
			//clip.addChild(tooltip);
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
			//selectWindow = new GroupButtons();
			//selectWindow.x = 3;
			//selectWindow.y = Y0 + 1 - 160;
			//selectWindow.ref = selectedModeButton;
			//clip.addChild(selectWindow);
			//selectWindow.add( { x:0,
						 //y:0,
						 //w:55,
						 //h:55,
						 //color:0xffffff,
						 //size:'normal',
						 //position:'top',
						 //arrow:'toLeft'} );
			//selectWindow.add( { x:59,
						 //y:0,
						 //w:55,
						 //h:55,
						 //color:0xcdff,
						 //size:'big',
						 //position:'top',
						 //arrow:'toLeft'} );
			//selectWindow.add( { x:118,
						 //y:0,
						 //w:55,
						 //h:55,
						 //color:0xE17004,
						 //color:0xffffff,
						 //size:'normal',
						 //position:'top',
						 //arrow:'toLeftBottom'} );
						 //arrow:'none'} );
			//selectWindow.add( { x:177,
						 //y:0,
						 //w:55,
						 //h:55,
						 //color:0xcccc98,
						 //color:0xffffff,
						 //size:'small',
						 //position:'top',
						 //arrow:'toRight'} );
						 //arrow:'none'} );
			//selectWindow.add( { x:0,
						 //y:65,
						 //w:55,
						 //h:55,
						 //color:0xffffff,
						 //size:'normal',
						 //position:'bottom',
						 //arrow:'none'} );
			//selectWindow.add( { x:59,
						 //y:65,
						 //w:55,
						 //h:55,
						 //color:0x3cac01,
						 //size:'big',
						 //position:'bottom',
						 //arrow:'none'} );
			//selectWindow.add( { x:118,
						 //y:65,
						 //w:55,
						 //h:55,
						 //color:0x800030,
						 //size:'small',
						 //position:'bottom',
						 //arrow:'none'} );
			//selectWindow.add( { x:177,
						 //y:65,
						 //w:55,
						 //h:55,
						 //color:0x3CAC01,
						 //size:'big',
						 //position:'top',
						 //arrow:'none'} );
			//selectWindow.addEventListener(CommentListViewEvent.GPBUTTONCHANGE, selectWindowHandler);
			//color picker
			colorPicker = new MColorPicker();
			colorPicker.x = selectedModeButton.x + selectedModeButton.width + 3;
			colorPicker.y = selectedModeButton.y;
			colorPicker.color = 0xffffff;
			colorPicker.addEventListener(Event.SELECT, function(evt:Event):void {
				sender.color = colorPicker.color;
				} );
			clip.addChild(colorPicker);
			//input 
			commentInput = new TextField();
			//commentInput = new TextInput();
			commentInput.type = TextFieldType.INPUT;
			commentInput.x = 76 + 28;
			commentInput.y = Y0 + 2.5;
			commentInput.width = 332.6 - 28;
			commentInput.height = 22;
			commentInput.border = true;
			commentInput.borderColor = BG_COLOR;
			commentInput.background = true;
			commentInput.backgroundColor = 0xffffff;
			//commentInput.move(76+28, Y0 + 2.5);
			//commentInput.setSize(332.6-28, 22);//20
			//commentInput.setStyle('textFormat',new TextFormat('simsum', '20', 0));
			commentInput.defaultTextFormat = new TextFormat('simsum', '20', 0);
			commentInput.setTextFormat(commentInput.defaultTextFormat);
			clip.addChild(commentInput);
			
			commentInput.addEventListener(FocusEvent.FOCUS_IN, inputFocusHandler);
			commentInput.addEventListener(FocusEvent.FOCUS_OUT, inputFocusHandler);
			//commentInput.addEventListener(ComponentEvent.ENTER, inputEnterHandler);
			commentInput.addEventListener(KeyboardEvent.KEY_DOWN, inputEnterHandler);
			
			//transtoItm = new NativeMenuItem('粘贴并转到');
			//transtoItm.addEventListener(Event.SELECT, function(evt:Event):void
			//{
				//if (Clipboard.generalClipboard.hasFormat(ClipboardFormats.TEXT_FORMAT))
				//{
					//commentInput.text = String(Clipboard.generalClipboard.getData(ClipboardFormats.TEXT_FORMAT));
					//inputEnterHandler();
					//Clipboard.generalClipboard.clear();
				//}
			//});
			//var transtoMn:NativeMenu = commentInput.textField.contextMenu;
			//transtoMn.clipboardMenu = true;
			//transtoMn.addItemAt(transtoItm,3);
			//commentInput.textField.contextMenu = transtoMn;
			//commentInput.textField.addEventListener(MouseEvent.MOUSE_DOWN, function(evt:MouseEvent):void
			//{
				//if (Clipboard.generalClipboard.hasFormat(ClipboardFormats.TEXT_FORMAT))
				//{
					//transtoItm.enabled = true;
				//}
				//else
				//{
					//transtoItm.enabled = false;
				//}
				//if (!evt.buttonDown)//right button 
				//{
				//}
			//});
			
			
			//send button
			sendButton = new Button();
			sendButton.x = 413.4;
			sendButton.y = Y0 + 1;
			sendButton.width = 71;
			sendButton.height = 25.4;
			sendButton.label = '发表';
			clip.addChild(sendButton);
			sendButton.addEventListener(MouseEvent.CLICK, sendButtonHandler);
			
			//侧栏显隐
			toggleRepeatButton = new CheckBox();
			toggleRepeatButton.label = '循环';
			toggleRepeatButton.move(482.5, Y0+1);
			toggleRepeatButton.setSize(83, 25.4);
			toggleRepeatButton.selected = false;
			clip.addChild(toggleRepeatButton);
			//windowWidth = NativeApplication.nativeApplication.activeWindow.width;
			toggleRepeatButton.addEventListener(Event.CHANGE, function(evt:Event):void
			{
				view.config['repeat'] = toggleRepeatButton.selected ? 'single' : 'none';
				//if (toggleSidePanelButton.selected)
				//{
					//NativeApplication.nativeApplication.activeWindow.width = windowWidth;
				//}
				//else
				//{
					//NativeApplication.nativeApplication.activeWindow.width = windowWidth -(WIDTH - X0);
					//
					//trackCommentButton.selected = false;
					//dispatchCommentListViewEvent(CommentListViewEvent.TRACKTOGGLE, false);
				//}
			});
			//toggle button
			toggleViewButton = new CheckBox();
			toggleViewButton.move(540,Y0+1);
			toggleViewButton.setSize(82, 25.4);// 27.4;
			toggleViewButton.selected = true;
			toggleViewButton.label = '显示弹幕';
			toggleViewButton.addEventListener(Event.CHANGE,toggleViewHandler);
			clip.addChild(toggleViewButton);
			
			commentCountLabel = new TextField();
			commentCountLabel.x = 714;
			commentCountLabel.y = Y0+4;
			commentCountLabel.autoSize = 'left';
			commentCountLabel.multiline = false;
			commentCountLabel.text = '';
			commentCountLabel.selectable = false;
			commentCountLabel.defaultTextFormat = tf;
			
			clip.addChild(commentCountLabel);
						
			//previewPad = new Sprite();
			//previewPad.x = 0;
			//previewPad.y = 0;
			//previewPad.scaleX = previewPad.scaleY = 1;
			//
			//dsgPad = new DesignPad(tabs.tab(2),this,previewPad);
			
			clip.addChild(tooltip);

		}
		//private function addMkPlaylistHandler(evt:MukioPlaylistEvent):void
		//{
			//var dp:DataProvider = playlistDataGrid.dataProvider;
			//dp.addItem(evt.data);
		//}
		//private function dragHandler(evt:NativeDragEvent):void
		//{
			//NativeDragManager.acceptDragDrop(clip);
			//trace("drag clip : " );
		//}
		//private function dropHandler(evt:NativeDragEvent):void
		//{
			//var itm:Object = {
				//vid : undefined,
				//cid : undefined,
				//file : undefined,
				//bnico : undefined,
				//cfile : undefined,
				//title:null
			//};
//
			//var files:Array = evt.clipboard.getData(ClipboardFormats.FILE_LIST_FORMAT) as Array;
			//
			//if (!files)
			//{
				//return;
			//}
			//
			//var f:File = File(files[0]);
			//trace("files[0] : " + files[0]);
			//
			//itm.file = f.nativePath;
			//trace("f.nativePath : " + f.nativePath);
			//
			//var i:int = String(itm.file).lastIndexOf('.');
			//if (i != -1)
			//{
				//var xmlpath:String = String(itm.file).substring(0, i) + '.xml';
				//trace("xmlfile : " + xmlpath);
				//try
				//{
					//var xmlfile:File = new File(xmlpath);
					//trace('ising xml file?');
					//if (xmlfile.exists)
					//{
						//trace('cfile xml');
						//itm.cfile = xmlpath;
					//}
				//}
				//catch (e:Error)
				//{
					//trace('no xml file!!!');
				//}
			//}
			//var arr :Array = String(itm.file).split(File.separator);
			//itm.title = String(arr.pop());
			//
			//view.config['autostart'] = true;
			//view.sendEvent(ViewEvent.LOAD, itm);
		//}
		//private function setInfoGraberHandler(evt:AcfunGraberEvent):void
		//{
			//var arr:Array = ['<font size="16" color="#0000ff"><b><a href="' + evt.data['url'] + '">' + evt.data['title'] + '</a></b></font>',
							//'    <b>'+ evt.data['upper']+'</b> <i>' + evt.data['date']+'</i>',
							//'    '+evt.data['desc']];
			//infoTf.htmlText = arr.join('\n');
		//}
		//private function clearItemsGraberHandler(evt:AcfunGraberEvent):void
		//{
			//playlistDataGrid.removeAll();
			//mklist.clear();
			//infoTf.htmlText = '';
		//}
		
		//private function addItemGraberHandler(evt:AcfunGraberEvent):void
		//{
			//trace("addItemGraberHandler : ");
			//mklist.add(evt.data);
		//}
		//private function graberHandler(evt:AcfunGraberEvent):void
		//{
			//if (!evt.data.flag)
			//{
				//return;
			//}
			//
			//var itm:Object = {
				//vid : undefined,
				//cid : undefined,
				//file : undefined,
				//bnico : undefined,
				//cfile : undefined
			//};
			//
			//var obj:Object = evt.data.data;
			//for (var cfv:String in obj) {
				//itm[cfv.toLowerCase()] = Strings.serialize(obj[cfv.toLowerCase()]);
			//}
						//
			//itm['file'] = itm['vid'] ? 'sina' : itm['file'];//add	
			//
			//view.config['autostart'] = true;
			//
			//view.sendEvent(ViewEvent.LOAD, itm);
			//
		//}
		private function modeStyleHandler(evt:CommentListViewEvent):void
		{
			sender.mode = modeStyleControl.mode;
			sender.size = modeStyleControl.size;
			sender.color = modeStyleControl.color;
			colorPicker.color = modeStyleControl.color;
		}
		//private function selectWindowHandler(evt:CommentListViewEvent):void
		//{
			//sender.color = evt.data.color;
			//colorPicker.color = sender.color;
			//if (evt.data.arrow == 'toLeft')
			//{
				//sender.mode = 1;
			//}
			//else if (evt.data.arrow == 'toRight')
			//{
				//sender.mode = 2;
			//}
			//else if (evt.data.arrow == 'toLeftBottom')
			//{
				//sender.mode = 3;
			//}
			//else
			//{
				//if (evt.data.position == 'top')
				//{
					//sender.mode = 5;
				//}
				//else
				//{
					//sender.mode = 4;
				//}
			//}
			//var tmp:Object = { small:15,
			//normal:25,
			//big:37 };
			//sender.size = tmp[evt.data.size];
			//commentInput.text = evt.data['mode'] + ' ' + evt.data.color + ' ' + evt.data.size;
			//commentInput.text = sender.mode + ' ' + sender.color + ' ' + sender.size;
		//}
		private function parseCmd(str:String):Boolean
		{
			return false;
			//var itm:Object = {
				//vid : '-1',
				//cid : undefined,
				//file : undefined,
				//bnico : undefined,
				//cfile : undefined
			//};
			//
			//var arr:Array = commentInput.text.match(/^args\((.*)\)$/);
			//if (arr)
			//{
				//var obj:Object = Strings.parseFlashvars(arr[1]);
				//for (var cfv:String in obj) {
					//itm[cfv.toLowerCase()] = Strings.serialize(obj[cfv.toLowerCase()]);
				//}
				//
				//if (itm['vid'] == '-1' && itm['file'] != undefined)
				//{
					//itm['vid'] = undefined;
				//}
				//
				//itm['file'] = itm['vid'] ? 'sina' : itm['file'];//add	
				//
				//view.config['autostart'] = true;
				//
				//view.sendEvent(ViewEvent.LOAD, itm);
				//
				//commentInput.text = '';
				//return true;
			//}
			//
			//arr = commentInput.text.match(/file=/i);
			//if (arr)
			//{
				//trace("里区 detected: ");
				//
				//obj = AcfunGraber.parseData(commentInput.text);
				//for (cfv in obj) {
					//itm[cfv.toLowerCase()] = Strings.serialize(obj[cfv.toLowerCase()]);
				//}
							//
				//itm['file'] = itm['vid'] ? 'sina' : itm['file'];//add	
				//
				//view.config['autostart'] = true;
				//view.sendEvent(ViewEvent.LOAD, itm);
				//commentInput.text = '';
				//return true;
			//}
			//
			//arr = commentInput.text.match(/(?:[^ut]id=|b\/|t=\d#)(\d+)/i);
			//if (arr)
			//{
				//trace("sina detected: ");
				//
				//itm.vid = arr[1];
				//
				//itm['file'] = itm['vid'] ? 'sina' : itm['file'];//add	
				//
				//view.config['autostart'] = true;
				//view.sendEvent(ViewEvent.LOAD, itm);
				//commentInput.text = '';
				//return true;
			//}
			//
			//arr = commentInput.text.match(/((?:anime|music|game|ent|zj)\/.+\.html)/i);
			//if (arr)
			//{
				//trace("graber.load : ");
				//graber.load(commentInput.text,true);
				//commentInput.text = '';
				//return true;
			//}
			//return false;
			
		}
		//private function playItemHandler(evt:ListEvent):void
		//{
			//trace("click graber.load : ");
			//graber.load(evt.item['htmlref']);
		//}
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
		//private function tabChangeHandler(evt:Event):void
		//{
			//var curBtn:Button = evt.currentTarget as Button;
			//curBtn.enabled = false;
			//curBtn.selected = true;
			//
			//if (curBtn == commentListTabButton)
			//{
				//filterTabButton.selected = true;
				//filterTabButton.enabled = true;
				//
				//dg.visible = true;
				//listShape.visible = true;
				//trackCommentButton.visible = true;
				//filterShape.visible = false;
				//filterDatagrid.visible = false;
			//}
			//else
			//{
				//commentListTabButton.selected = true;
				//commentListTabButton.enabled = true;
				//
				//dg.visible = false;
				//listShape.visible = false;
				//trackCommentButton.visible = false;
				//
				//trackCommentButton.selected = false;
				//dispatchCommentListViewEvent(CommentListViewEvent.TRACKTOGGLE, false);
//
			//
				//filterShape.visible = true;
				//filterDatagrid.visible = true;
			//}
		//}
		private function inputEnterHandler(evt:KeyboardEvent=null):void
		//private function inputEnterHandler(evt:ComponentEvent=null):void
		{
			//parseCmd(commentInput.text);
			if (!evt || evt.keyCode == Keyboard.ENTER)
			{
				sendButtonHandler();
				commentInput.y = Y0+1.5;
				commentInput.height = 22;
				sendButton.setFocus();
			}
		}
		private function inputFocusHandler(evt:FocusEvent):void
		{
			//if (commentInput.enabled)
			//{
				if (evt.type == FocusEvent.FOCUS_IN)
				{
					commentInput.y = Y0-5.9;
					commentInput.height = 30.4;
					view.skin.stage.addEventListener(MouseEvent.CLICK, stageClickHandler);
				}
				else
				{
					commentInput.y = Y0+1.5;
					commentInput.height = 22;
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
			//view.sendEvent(ViewEvent.TRACE, "hello");
			view.addControllerListener(ControllerEvent.RESIZE, resizeHandler);
			view.addControllerListener(ControllerEvent.ITEM,itemHandler);
			view.addModelListener(ModelEvent.TIME, timeHandler);
			//trace('hello');
			
			cview.addEventListener(CommentViewEvent.TRACK, trackHandler);
			cview.addEventListener(CommentViewEvent.FILTERADD, filterListAdd);
			cview.addEventListener(CommentViewEvent.FILTEINITIAL, filterCheckBoxInitial);

			//cview.clip.addChild(previewPad);

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
			//trace(evt.data);
			//var dp:DataProvider = dg.dataProvider;
			//dg.scrollToIndex(dp.getItemIndex(idIndex[evt.data]));
			//commentInput.text="evt.data : " + evt.data + "idIndex[evt.data] : " + idIndex[evt.data]
		}
		private function timeHandler(evt:ModelEvent):void
		{
			_stime = evt.data.position;
			//trace(clip.visible +' x:'+clip.x+' y:'+clip.y+' w:'+clip.width+' h:'+clip.height+' '+clip.parent.getChildIndex(clip)+'/'+clip.parent.numChildren);
		}
		private function itemHandler(evt:ControllerEvent):void
		{
			var idx:Number = view.config['item'];
			var itm:Object = view.playlist[idx];
			
			//NativeApplication.nativeApplication.activeWindow.title = 'MukioPlayer';
			//if (itm.title && itm.title != '')
			//{
				//NativeApplication.nativeApplication.activeWindow.title = Strings.cut(itm.title) + ' - MukioPlayer';
			//}

			
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
		private function toggleViewHandler(evt:Event):void
		{
			dispatchCommentListViewEvent(CommentListViewEvent.DISPLAYTOGGLE, toggleViewButton.selected);
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
			//commentInput.enabled = evt.data.enable;
			//commentInput.focusEnabled = evt.data.enable;
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