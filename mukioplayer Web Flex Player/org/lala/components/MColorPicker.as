package org.lala.components
{
    import flash.display.DisplayObject;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.events.KeyboardEvent;
    import flash.events.MouseEvent;
   
    /**
    * 颜色拾取器
    * @author Jaja as-max.cn
    */
    public class MColorPicker extends Sprite
    {
        private var clicker:Clicker = new Clicker;
        private var colorArea:ColorFormArea = new ColorFormArea(colorChangeHandler);
       
        /**
        * 最近的一次颜色值
        */
        private var lastestColor:String = "0x000000";
		
		private var pos:String;
       
        public function MColorPicker(p:String='right') :void
        {
            //add clicker
			pos = p;
			
            super.addChild(clicker);
           
            colorArea.visible = false;
            super.addChild(colorArea);
           
            this.addEventListener(Event.ADDED_TO_STAGE, addThis);
        }
       
        /**
        * 获得颜色值
        */
        public function get color():uint {
            return uint(lastestColor);
        }
		public function set color(clr:uint):void
		{
			var len:int = clr.toString(16).length;
			var str:String = '';
			if (len < 6)
			{
				str = '00000'.substr(0, 6 - len);
			}
			lastestColor = '0x' + str + clr.toString(16);
			clicker.color = lastestColor;
			colorArea.color = lastestColor;
		}
       
        /**
        * 获得颜色字符串
        */
        public function get colorString():String {
            return lastestColor;
        }
       
        private function colorChangeHandler(color:String):void {
            clicker.color = color;
        }
       
        /**
        * 控制是否显示颜色区域
        * @param    event
        */
        private function clickThis(event:MouseEvent = null):void {
            if (colorArea.visible) {
                if (this.mouseY >= colorArea.y + 30) {
                    colorArea.visible = false;
                    sendSelectEvent();
                }
            }else {
                colorArea.visible = true;
               
                //if (this.stage.mouseX > stage.stageWidth - colorArea.width) {
                    //colorArea.x = - colorArea.width - 5;
                //}else {
                    colorArea.x = pos == 'right' ? clicker.x : (clicker.x+clicker.width-colorArea.width+50);// + clicker.width;// + 5;
                //}
                //if (this.stage.mouseY > stage.stageHeight - colorArea.height) {
                    colorArea.y = -colorArea.height -3;// + 30;// 20;
                //}else {
                    //colorArea.y = clicker.y + 5;
                //}
            }
        }
       
        private function keyDown(event:KeyboardEvent):void {
            switch(event.keyCode) {
                case 27://Esc Key
                    showLatestColor();
                    break;
                case 13://Enter Key
                    colorArea.visible = false;
                    sendSelectEvent();
                    break;
            }
        }
       
        private function lostFocus(event:MouseEvent):void {
            if (this.mouseX < colorArea.x ||
                this.mouseX > colorArea.width + colorArea.x ||
                this.mouseY < colorArea.y ||
                this.mouseY > colorArea.height + colorArea.y)
            {
                showLatestColor();
            }
        }
       
        private function lostSystemFocus(event:Event):void {
            showLatestColor();
        }
       
        /**
        * 显示最近的一次颜色
        */
        private function showLatestColor():void {
            colorArea.visible = false;
            clicker.color = lastestColor;
        }
       
        private function addThis(event:Event):void {
            if(!hasEventListener(MouseEvent.CLICK))
                this.addEventListener(MouseEvent.CLICK, clickThis);
            if(!hasEventListener(Event.REMOVED_FROM_STAGE))
                this.addEventListener(Event.REMOVED_FROM_STAGE, removeThis);
            stage.addEventListener(KeyboardEvent.KEY_DOWN, keyDown);
            stage.addEventListener(MouseEvent.MOUSE_DOWN, lostFocus);
            if(!hasEventListener(Event.DEACTIVATE))
                this.addEventListener(Event.DEACTIVATE, lostSystemFocus);
        }
       
        private function removeThis(event:Event):void {
            this.removeEventListener(MouseEvent.CLICK, clickThis);
            this.removeEventListener(Event.REMOVED_FROM_STAGE, removeThis);
            stage.removeEventListener(KeyboardEvent.KEY_DOWN, keyDown);
            stage.removeEventListener(MouseEvent.MOUSE_DOWN, lostFocus);
            this.removeEventListener(Event.DEACTIVATE, lostSystemFocus);
        }
       
        /**
        * @eventType flash.events.Event.SELECT
        */
        [Event(name = "select", type = "flash.events.Event")]
        private function sendSelectEvent():void {
            lastestColor = clicker.color;
            dispatchEvent(new Event(Event.SELECT));
        }
       
        //disable functions
        public override function addChild(child:DisplayObject):DisplayObject
        {
            throw new Error("此方法不可用");
        }
        public override function addChildAt(child:DisplayObject, index:int):DisplayObject
        {
            throw new Error("此方法不可用");
        }
        public override function contains(child:DisplayObject):Boolean
        {
            throw new Error("此方法不可用");
        }
        public override function removeChild(child:DisplayObject):DisplayObject
        {
            throw new Error("此方法不可用");
        }
        public override function removeChildAt(index:int):DisplayObject
        {
            throw new Error("此方法不可用");
        }
        public override function setChildIndex(child:DisplayObject, index:int):void
        {
            throw new Error("此方法不可用");
        }
        public override function swapChildren(child1:DisplayObject, child2:DisplayObject):void
        {
            throw new Error("此方法不可用");
        }
        public override function swapChildrenAt(index1:int, index2:int):void
        {
            throw new Error("此方法不可用");
        }
        public override function set width(value:Number):void
        {
            throw new Error("尝试对只读属性进行赋值");
        }
        public override function set height(value:Number):void
        {
            throw new Error("尝试对只读属性进行赋值");
        }
       
    }
   
}


import flash.display.CapsStyle;
import flash.display.JointStyle;
import flash.display.Shape;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.filters.BevelFilter;
import flash.filters.BitmapFilterQuality;
import flash.filters.BitmapFilterType;
import flash.text.TextField;
import flash.text.TextFieldType;
class Clicker extends Sprite {
   
    /**
    * 拾色器的头
    */
    private var myColorArea:ClickColorArea = new ClickColorArea;
   
    /**
    * 包含的颜色的字符串表示形式
    */
    private var theColor:String = "0x000000";
    public function Clicker():void {
        with(graphics){
            lineStyle(1, 0xFFFFFF, 1, true, "normal", CapsStyle.SQUARE, JointStyle.MITER);
            moveTo(0, 25);
            lineTo(0, 0);
            lineTo(25, 0);
            lineStyle(1, 0xAAAAAA, 1, true, "normal", CapsStyle.SQUARE, JointStyle.MITER);
            lineTo(25, 25);
            lineTo(0, 25);
            lineStyle(1, 0xEEEEEE, 1, true, "normal", CapsStyle.SQUARE, JointStyle.MITER);
            moveTo(1, 24);
            lineTo(1, 1);
            lineTo(24, 1);
            lineTo(24, 24);
            lineTo(1, 24);
            lineStyle(1, 0xCCCCCC, 1, true, "normal", CapsStyle.SQUARE, JointStyle.MITER);
            moveTo(2, 23);
            lineTo(2, 2);
            lineTo(23, 2);
            lineStyle(1, 0xFFFFFF, 1, true, "normal", CapsStyle.SQUARE, JointStyle.MITER);
            lineTo(23, 23);
            lineTo(2, 23);
        }
       
        myColorArea.x = 2.5;
        myColorArea.y = 2.5;
        addChild(myColorArea);
       
        var blackArr:Shape = new Shape;
        blackArr.graphics.beginFill(0xEEEEEE);
        blackArr.graphics.drawRect(0, 0, 8, 6);
        blackArr.graphics.endFill();
        blackArr.graphics.beginFill(0);
        blackArr.graphics.lineStyle(.01, 0xCCCCCC, 1, true, "normal", CapsStyle.SQUARE, JointStyle.MITER);
        blackArr.graphics.moveTo(1, 1);
        blackArr.graphics.lineTo(7, 1);
        blackArr.graphics.lineTo(4, 5);
        blackArr.graphics.lineTo(1, 1);
        blackArr.graphics.endFill();
        blackArr.x = this.width - blackArr.width - 2;
        blackArr.y = this.height - blackArr.height - 2;
        addChild(blackArr);
    }
   
    /**
    * 改变选中的颜色
    * @param    color
    */
    public function changeColor(color:uint):void {
        myColorArea.changeColor(color);
    }
   
    /**
    * 设置颜色
    */
    public function set color(color:String):void {
        theColor = color;
        myColorArea.changeColor(uint(color));
    }
    /**
    * 获得颜色
    */
    public function get color():String {
        return theColor;
    }
}

class ClickColorArea extends Sprite {
   
    /**
    * 拾色器头显示当前颜色的部分
    * @param    color 默认为黑色
    */
    public function ClickColorArea(color:uint = 0x000000):void {
        changeColor(color);
    }
   
    /**
    * 改变此显示区域的颜色
    * @param    color
    */
    public function changeColor(color:uint):void {
        graphics.clear();
        graphics.beginFill(color);
        graphics.drawRect(0, 0, 20, 20);
        graphics.endFill();
    }
}

class ColorForm extends Sprite {
   
    private var theHandler:Function;
   
    /**
    * 颜色块的颜色
    */
    private var theColor:String = "";
   
    private var sharp:Shape = new Shape;
   
    /**
    * 颜色块
    * @param    color
    * @param    mouseOverHandler
    */
    public function ColorForm(color:String, mouseOverHandler:Function = null):void {
        theColor = color;
        theHandler = mouseOverHandler;
       
        //绘制中部
        graphics.beginFill(uint(color));
        graphics.drawRect(0, 0, 15, 15);
        graphics.endFill();
        //绘制外圈
        sharp.graphics.lineStyle(1, 0xFFFFFF);
        sharp.graphics.drawRect(0, 0, 15, 15);
        addChild(sharp);
        sharp.visible = false;
       
        this.addEventListener(Event.REMOVED_FROM_STAGE, removeThis);
        this.addEventListener(MouseEvent.MOUSE_OVER, mouseOverThis);
    }
   
    private function mouseOverThis(event:MouseEvent):void {
        if (Boolean(theHandler)) {
            theHandler(theColor);
        }
    }
   
    private function mouseOutThis(event:MouseEvent):void {
        select = false;
    }
   
    private function removeThis(event:Event):void {
        this.removeEventListener(Event.REMOVED_FROM_STAGE, removeThis);
        this.removeEventListener(MouseEvent.MOUSE_OVER, mouseOverThis);
    }
   
    /**
    * 获得或设置选中状态
    */
    public function set select(value:Boolean):void {
        sharp.visible = value;
    }
    public function get select():Boolean {
        return sharp.visible;
    }
   
    /**
    * 获得本色块的颜色
    */
    public function get color():String {
        return theColor;
    }
}

class ColorFormArea extends Sprite {
   
    private var colorArr:Array = ["00", "33", "66", "99", "CC", "FF"];
   
    //color text
    private var txt:TextField = new TextField;
    /**
    * 颜色块数组
    */
    private const RECTS_ARR:Array = new Array;
   
    /**
    * 颜色改变时的处理函数
    */
    private var theHandler:Function;
   
    /**
    * 颜色块区域
    */
    private var colorRects:Sprite = new Sprite;
   
    /**
    * 构造一个新的ColorFormArea实例
    */
    public function ColorFormArea(colorChangeHandler:Function = null):void {
        theHandler = colorChangeHandler;
       
        var bg:Sprite = new Sprite;
        with (bg) {
			graphics.lineStyle(1, 0x323232);
            graphics.beginFill(0xFFFFFF,0.4);
            //graphics.drawRect(0, 0, 308, 230);
            graphics.drawRoundRect(0, 0, 308, 230,5);
            graphics.endFill();
            graphics.lineStyle(1, 0xCCCCCC, 1, true, "normal", CapsStyle.SQUARE, JointStyle.MITER);
            graphics.moveTo(1, 1);
            graphics.lineTo(1, 229);
            graphics.moveTo(308, 1);
            graphics.lineTo(308, 229);
        }
        //添加滤镜
        var bevel:BevelFilter = new BevelFilter(1.5, 90, 0xFFFFFF, 1, 0x666666, 1, 0, 4, 1, BitmapFilterQuality.LOW, BitmapFilterType.INNER, false);
        bg.filters = [bevel];
        addChild(bg);
       
        //add text
        txt.width = 60;
        txt.height = 20;
        txt.border = true;
        txt.type = TextFieldType.INPUT;
        txt.x = 10;
        txt.y = 5;
        txt.maxChars = 7;
        txt.restrict = "0-9a-f#";
        txt.text = "0x000000";
        txt.addEventListener(Event.CHANGE, txtChange);
        addChild(txt);
       
        //add color rects bg
        var colorBG:Sprite = new Sprite;
        colorBG.graphics.lineStyle(1);
        colorBG.graphics.beginFill(0);
        colorBG.graphics.drawRect(0, 0, 300, 300);
        colorBG.graphics.endFill();
        addChild(colorBG);
       
        //add color rects
        colorRects.x = txt.x + 1;
        colorRects.y = txt.y + txt.height + 5;
        addChild(colorRects);
        for (var i:int = 0; i < 18; i++) {
            for (var j:int = 0; j < 12; j++) {
                var color:String = "";
                color = "0x" + colorArr[Math.floor(i / 6) + Math.floor(j / 6) * 3] + colorArr[i % 6] + colorArr[j % 6];
                var colorForm:ColorForm = new ColorForm(color, selectColorHandler);
                colorForm.x = i * (colorForm.width);
                colorForm.y = j * (colorForm.height);
                colorRects.addChild(colorForm);
                RECTS_ARR.push(colorForm);
            }
        }
        colorBG.width = colorRects.width + 1;
        colorBG.height = colorRects.height + 1;
        colorBG.x = colorRects.x - 1;
        colorBG.y = colorRects.y - 1;
       
        this.addEventListener(Event.REMOVED_FROM_STAGE, removeThis);
    }
   
    /**
    * 移除侦听器
    * @param    event
    */
    private function removeThis(event:Event):void {
        txt.removeEventListener(Event.CHANGE, txtChange);
        this.removeEventListener(Event.REMOVED_FROM_STAGE, removeThis);
    }
   
    private function selectColorHandler(color:String):void {
        txt.text = "#" + color.slice(2, 8);
        txtChange();
       
        callHandler(color);
    }
   
    /**
    * 最近一次选中的方块
    */
    private var latestIndex:int = 0;
   
    private function txtChange(event:Event = null):void {
        var txtValue:String = txt.text;
        var txtColor:String = "";
       
        if (txtValue.slice(0, 1) == "#") {
            txt.maxChars = 7;
            txtColor = "0x" + txtValue.slice(1, 7);
        }else {
            txt.maxChars = 6;
            txtColor = "0x" + txtValue.slice(0, 6);
        }
        callHandler(txtColor);
       
        RECTS_ARR[latestIndex].select = false;
        for (var i:int = 0; i < RECTS_ARR.length; i++) {
            var colorForm:ColorForm = RECTS_ARR[i] as ColorForm;
            if (uint(colorForm.color) == uint(txtColor)) {
                colorForm.select = true;
                latestIndex = i;
                break;
            }
        }
    }
   
    /**
    * 颜色改变时调用此函数
    * @param    color
    */
    private function callHandler(color:String):void {
        if (Boolean(theHandler)) {
            theHandler(color);
        }
    }
	public function set color(color:String):void
	{
        txt.text = "#" + color.slice(2, 8);
        txtChange();
	}
}