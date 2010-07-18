package org.lala.components 
{
	import fl.core.UIComponent;
	import flash.display.Graphics;
	import flash.display.CapsStyle;
	import flash.display.JointStyle;
	import flash.display.LineScaleMode;
	import flash.display.Sprite;
	
	/**
	 * ...
	 * @author aristotle9
	 */
	public class Compass extends UIComponent
	{
		private var r:Number;
		
		private var inIndicator:Sprite;
		private var outIndicator:Sprite;
		
		public function Compass(_r:Number=32) 
		{
			//super();
			r = _r;
			width = height = r*2;
			
			init();
		}
		
		private function init():void
		{
			drawCompass();
			createIndicators();
		}
		
		private function drawCompass():void
		{
			var g:Graphics = graphics;
			g.lineStyle(0.1, 0, 1, false, LineScaleMode.NONE, CapsStyle.NONE, JointStyle.MITER);
			g.drawCircle(r, r, r);
		}
		
		private function createIndicators():void
		{
			inIndicator = new Sprite();
			var g:Graphics = inIndicator.graphics;
			g.lineStyle(0.1, 0xff0000, .5, false, LineScaleMode.NONE, CapsStyle.NONE, JointStyle.MITER);
			g.moveTo(0, 0);
			g.lineTo(r, 0);
			g.moveTo(1 / 4 * r * Math.cos(Math.PI / 6), 1 / 4 * r * Math.sin(Math.PI / 6));
			g.lineTo(0, 0);
			g.moveTo(1 / 4 * r * Math.cos(-Math.PI / 6), 1 / 4 * r * Math.sin(-Math.PI / 6));
			g.lineTo(0, 0);
			inIndicator.x = inIndicator.y = r;
			addChild(inIndicator);
			
			outIndicator = new Sprite();
			g = outIndicator.graphics;
			g.lineStyle(0.1, 0x00ff00, .5, false, LineScaleMode.NONE, CapsStyle.NONE, JointStyle.MITER);
			g.moveTo(0, 0);
			g.lineTo(r, 0);
			g.moveTo(r - 1 / 4 * r * Math.cos(Math.PI / 6), 1 / 4 * r * Math.sin(Math.PI / 6));
			g.lineTo(r, 0);
			g.moveTo(r - 1 / 4 * r * Math.cos(-Math.PI / 6), 1 / 4 * r * Math.sin(-Math.PI / 6));
			g.lineTo(r, 0);
			outIndicator.x = outIndicator.y = r;
			addChild(outIndicator);
		}
		
		public function set inIdt(dgr:int):void
		{
			inIndicator.rotation = -dgr;
		}
		
		public function set outIdt(dgr:int):void
		{
			outIndicator.rotation = -dgr;
		}
		
	}

}