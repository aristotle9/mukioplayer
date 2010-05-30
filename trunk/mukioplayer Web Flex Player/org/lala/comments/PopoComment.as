package org.lala.comments 
{
	//import fl.motion.MotionEvent;
	//import fl.transitions.Tween;
	//import fl.transitions.easing.None;
	//import fl.transitions.TweenEvent;
	
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.filters.DropShadowFilter;
	import flash.utils.Timer;
	import flash.events.TimerEvent;
	
	//import mx.effects.Move;
	import org.libspark.betweenas3.BetweenAS3;
	import org.libspark.betweenas3.tweens.ITween;
	import org.libspark.betweenas3.easing.Expo;
	import org.libspark.betweenas3.events.TweenEvent;
	import org.libspark.betweenas3.easing.Physical;
	import org.libspark.betweenas3.easing.Quad;
	import org.libspark.betweenas3.easing.Linear;
	
	import com.jeroenwijering.player.Player;
	
	/**
	 * zoome style comments
	 * @author aristotle9
	 */
	public class PopoComment extends Sprite
	{
		
		static public var TIMER_INTERVAL:Number = 8;//补间更新毫秒
		static public var TIMER_TICK:Number = 1;//退场增量速度
		static public var RADIUS:Number = Player.WIDTH / 2;//全方向半径
		static public var screenW:int = Player.WIDTH;
		static public var screenH:int = Player.HEIGHT;
		
		private var item:Object;//config data
		
		//visual objects
		private var bg:MovieClip;
		private var ttf:TextField;
		private var tf:TextFormat;//but
		
		//size control
		private var W:int;//bg size
		private var H:int;
		private var w:int;//inner size
		private var h:int;
		
		//complete handle,[in]
		public var completeHandler:Function;
		
		//three type of actions
		//private var tmi:Timer;//in
		private var tmd:Timer;//duration
		//private var tmo:Timer;//out
		private var tmte:Timer//lupin effect
		
		private var twi:ITween;
		private var two:ITween;
		
		public function PopoComment(itm:Object) 
		{
			//copy config data
			item = {};
			for(var key :String in itm)
			{
				item[key] = itm[key];
			}
			
			visible = false;
			init();
		}
		
		private function init():void
		{
			//x = item.x;
			y = item.y;
			
			tf = getTextFormat();
			ttf = new TextField();
			ttf.autoSize = 'left';
			ttf.defaultTextFormat = tf;
			ttf.x = ttf.y = 15;
			ttf.text = item.text;
			
			w = ttf.width;//global size bases on text size
			h = ttf.height;
			W = w + 30;
			H = h + 30;
			
			//if (item.alpha)
			//{
				bg = FukidashiFactory.getFukidashi(item.style);
				bg.alpha = item.alpha / 100;
				bg.x = bg.y = 0;
				bg.width = W;
				bg.height = H;
				bg.filters = [new DropShadowFilter(10, 45, 0, 0.5)];
				addChild(bg);
			//}
			
			addChild(ttf);
			
			//position 校正
			setPosition();
			
			var inStyle:String = item.inStyle == 'random' ? getRndStyle() : item.inStyle;
			var outStyle:String = item.outStyle == 'random' ? getRndStyle() : item.outStyle;
			
			//inStyle = outStyle = 'fade';

			//get start,end position
			getPosition(inStyle,outStyle);
			
			//set action chains
			var self:PopoComment = this;
			//tmi = new Timer(TIMER_INTERVAL);
			//var inTween:Function = getInTween(item.inStyle);
			//tmi .addEventListener(TimerEvent.TIMER, function(event:TimerEvent):void
			//{
				//inTween();
			//});
			//twi = new Tween(this, 'x', None.easeIn, item.stx, item.x, 1, true);
			//twi.addEventListener(TweenEvent.MOTION_FINISH, function(event:TweenEvent):void
			//{
				//tmd.start();
			//});
			if (inStyle == 'fade')
			{
				x = item.x;
				y = item.y;
				alpha = 0;
				twi = BetweenAS3.tween(this, { alpha:1}, {alpha:0},0.5,Linear.easeOut);
				twi.addEventListener(TweenEvent.COMPLETE, function(event:TweenEvent):void
				{
					twi = null;
					self.tmd.start();
				});
			}
			else if (inStyle == 'normal')
			{
				x = item.x;
				y = item.y;
			}
			else
			{
				x = item.stx;
				y = item.sty;
				//if (x == 0 && y == 0)
				//{
					//trace("inStyle : >" + inStyle + '<');
					//trace("item.x : " + item.x);
					//trace("item.y : " + item.y);
					//trace("item.stx : " + item.stx);
					//trace("item.sty : " + item.sty);
				//}
				twi = BetweenAS3.tween(this, { x:item.x, y:item.y }, { x:item.stx, y:item.sty },1,Expo.easeOut);
				twi.addEventListener(TweenEvent.COMPLETE, function(event:TweenEvent):void
				{
					twi = null;
					self.tmd.start();
				});
			}
			
			if (item.tEffect == 'lupin')
			{
				ttf.text = '';
				tmte = new Timer(50, 0);
				var num:int = 0;
				var tEffectHandler:Function = function(event:TimerEvent):void
				{
					if (num < self.item.text.length)
					{
						num ++;
						self.ttf.text = String(self.item.text).substr(0, num);
					}
					else
					{
						self.tmte.stop();
						self.tmte.removeEventListener(TimerEvent.TIMER, tEffectHandler);
						self.tmte = null;
					}
				};
				tmte.addEventListener(TimerEvent.TIMER, tEffectHandler);
			}
			
			//tmo = new Timer(TIMER_INTERVAL);
			//var outTween:Function = getOutTween(item.outStyle);
			//tmo .addEventListener(TimerEvent.TIMER, function(event:TimerEvent):void
			//{
				//outTween();
			//});
			
			if (outStyle == 'fade')
			{
				two = BetweenAS3.tween(this, { alpha:0 } , {alpha:1},0.5,Linear.easeIn);
				two.addEventListener(TweenEvent.COMPLETE, function(event:TweenEvent):void
				{
					two = null;
					self.completeHandler();
				});
			}
			else if(outStyle != 'normal')
			{
				//trace("outStyle : " + outStyle);
				two = BetweenAS3.tween(this, { x:item.edx, y:item.edy } , { x:item.x, y:item.y },1,Quad.easeIn);
				two.addEventListener(TweenEvent.COMPLETE, function(event:TweenEvent):void
				{
					two = null;
					self.completeHandler();
				});
			}
			
			tmd = new Timer(item.duration, 1);
			tmd.addEventListener(TimerEvent.TIMER_COMPLETE, function(event:TimerEvent):void
			{
				//self.tmo.start();
				if (outStyle == 'normal')
					self.completeHandler();
				else
					self.two.play();
			});
		}
		
		private function getTextFormat():TextFormat
		{
			var tmp:TextFormat = new TextFormat();
			
			tmp.size = item.size;
			tmp.color = item.color;
			
			var tStyle:String = item.tStyle;
			
			if (tStyle.match('italic'))
				tmp.italic = true;
				
			if (tStyle.match('bold'))
				tmp.bold = true;
				
			if (tStyle.match('underline'))
				tmp.underline = true;

			return tmp;
		}
		
		//start action chains
		public function start():void
		{
			visible = true;
			//tmi.start();
			if (item.inStyle == 'normal')
				tmd.start();
			else
				twi.play();
				
			if (item.tEffect == 'lupin')
				tmte.start();
		}
		
		//private function getInTween(inStyle:String='fade'):Function
		//{
			//var self:PopoComment = this;
			//inStyle = inStyle == 'random' ? getRndStyle() : inStyle;
			//
			//switch(inStyle)
			//{
				//case 'right':
					//initial pos
					//x = -W;
					//y = item.y;
					//return function():void
					//{
						//if (Math.abs(self.item.x - self.x) <= 3)
						//{
							//self.x = self.item.x;
							//self.tmi.stop();
							//self.tmi = null;
							//self.tmd.start();
						//}
						//var delta:int = (self.item.x - self.x) / 5;
						//self.x += delta;
					//};
					//break;
					//
				//case 'left':
					//x = screenW + W;
					//y = item.y;
					//return function():void
					//{
						//if (Math.abs(self.item.x - self.x) <= 3)
						//{
							//self.x = self.item.x;
							//self.tmi.stop();
							//self.tmi = null;
							//self.tmd.start();
						//}
						//var delta:int = (self.item.x - self.x) / 5;
						//self.x += delta;
					//};
					//break;
					//
				//case 'drop':
					//x = item.x;
					//y = -H;
					//return function():void
					//{
						//if (Math.abs(self.item.y - self.y) <= 3)
						//{
							//self.y = self.item.y;
							//self.tmi.stop();
							//self.tmi = null;
							//self.tmd.start();
						//}
						//var delta:int = (self.item.y - self.y) / 5;
						//self.y += delta;
					//};
					//break;
					//
				//case 'rise':
					//x = item.x;
					//y = screenH + H;
					//return function():void
					//{
						//if (Math.abs(self.item.y - self.y) <= 3)
						//{
							//self.y = self.item.y;
							//self.tmi.stop();
							//self.tmi = null;
							//self.tmd.start();
						//}
						//var delta:int = (self.item.y - self.y) / 5;
						//self.y += delta;
					//};
					//break;
					//
				//case 'fade':
					//x = item.x;
					//y = item.y;
					//alpha = 0;
					//return function():void
					//{
						//if (self.alpha >= 1)
						//{
							//self.tmi.stop();
							//self.tmi = null;
							//self.tmd.start();
						//}
						//self.alpha += 0.05;
					//};
					//break;
					//
				//default:
					//x = item.x;
					//y = item.y;
					//return function():void
					//{
						//self.tmi.stop();
						//self.tmi = null;
						//self.tmd.start();
					//};
					//break;
			//}
		//}
		
		//private function getOutTween(outStyle:String='fade'):Function
		//{
			//var self:PopoComment = this;
			//var sec:Number = 0;
			//outStyle = outStyle == 'random' ? getRndStyle() : outStyle;
			//
			//switch(outStyle)
			//{
				//case 'right':
				//{
					//return function():void
					//{
						//var delta:int = 4.9 * sec * sec / 100;//二次缓动,退场
						//self.x += delta;
						//sec += TIMER_TICK;
						//if (self.x >= PopoComment.screenW)
						//{
							//self.x = PopoComment.screenW;
							//self.tmo.stop();
							//self.tmo = null;
							//self.completeHandler();
						//}
					//};
					//break;
				//}
				//case 'left':
				//{
					//return function():void
					//{
						//var delta:int = 4.9 * sec * sec / 100;//二次缓动,退场
						//self.x -= delta;
						//sec += TIMER_TICK;
						//if (self.x <= -self.W)
						//{
							//self.x = -self.W;
							//self.tmo.stop();
							//self.tmo = null;
							//self.completeHandler();
						//}
					//};
					//break;
				//}
				//case 'rise':
				//{
					//return function():void
					//{
						//var delta:int = 4.9 * sec * sec / 100;//二次缓动,退场
						//self.y -= delta;
						//sec += TIMER_TICK;
						//if (self.y <= -self.H)
						//{
							//self.y = -self.H;
							//self.tmo.stop();
							//self.tmo = null;
							//self.completeHandler();
						//}
					//};
					//break;
				//}
				//case 'drop':
				//{
					//return function():void
					//{
						//var delta:int = 4.9 * sec * sec / 100;//二次缓动,退场
						//self.y += delta;
						//sec += TIMER_TICK;
						//if (self.y >= PopoComment.screenH)
						//{
							//self.y = PopoComment.screenH;
							//self.tmo.stop();
							//self.tmo = null;
							//self.completeHandler();
						//}
					//};
					//break;
				//}
				//case 'fade':
				//{
					//return function():void
					//{
						//self.alpha -= 0.05;
						//if (self.alpha <= 0)
						//{
							//self.tmo.stop();
							//self.tmo = null;
							//self.completeHandler();
						//}
					//};
					//break;
				//}
				//default:
				//{
					//return function():void
					//{
						//self.tmo.stop();
						//self.tmo = null;
						//self.completeHandler();
					//};
					//break;
				//}
			//}
		//}
		
		private function getRndStyle():String
		{
			var arr:Array = ['right',
						 	 'left',
							 'rise',
							 'drop',
							 'fade',
							 'fade'
							];
			return arr[Math.floor(Math.random()*5)];
		}
		
		//change item.x and item.y
		//set popo arrow
		private function setPosition():void
		{
			if (!item.x)
				item.x = 0;
			
			if (!item.y)
				item.y = 0;
				
			if (!item.style)
				item.style = 'normal';
				
			if (W > PopoComment.screenW)
			{
				w -= (W - PopoComment.screenW);
				W = w;
				h = tf.size as Number;
				H = h + 30;
			}
			
			var newX :int = item.x;
			var newY :int = item.y - H;
			
			if (newX + W <= screenW)
			{
				if (newY > 0)
				{
					bg.gotoAndStop('LB');
				}
				else
				{
					newY = newY + H;
					bg.gotoAndStop('LT');
				}
			}
			else if (newY >= 0)
			{
				newX -= W;
				bg.gotoAndStop('RB');
			}
			else
			{
				newX -= W;
				newY += H;
				bg.gotoAndStop('RT');
			}
			
			if (newX < 0)
				newX = 0;
				
			if (newY < 0)
				newY = 0;
				
			item.x = newX;
			item.y = newY;
		}
		
		//caculate the start position
		private function getPosition(inStyle:String,outStyle:String):void
		{
			item.stx = getXPosition(inStyle);
			item.sty = getYPosition(inStyle);
			
			item.edx = getXPosition(outStyle,false);
			item.edy = getYPosition(outStyle,false);
		}
		
		//return the x pos
		private function getXPosition(style:String,bIn:Boolean=true):Number
		{
			var n:Number = parseInt(style);
			
			if (n > 0 && n <= 360)//全方向的计算方法有所不同,是按半径算的,以成为圆形
				return item.x + PopoComment.RADIUS * Math.cos(-n / 180 * Math.PI);
				
			if(!bIn)
				switch(style)
				{
					case 'left':
						return -W;
					case 'right':
						return screenW;
					case 'drop':
					case 'rise':
						return item.x;
					default:
						return 0;
				}
			else
				switch(style)
				{
					case 'left':
						return screenW;
					case 'right':
						return -W;
					case 'drop':
					case 'rise':
						return item.x;
					default:
						return 0;
				}
			return 0;
			
		}
		
		//return the y pos
		private function getYPosition(style:String,bIn:Boolean=true):Number
		{
			//trace("style : " + style);
			var n:Number = parseInt(style);
			
			if (n > 0 && n <= 360)//全方向的计算方法有所不同,是按半径算的,以成为圆形
				return item.y + PopoComment.RADIUS * Math.sin(-n / 180 * Math.PI);

			if(bIn)
				switch(style)
				{
					case 'drop':
						return -H;
					case 'rise':
						return screenH;
					case 'left':
					case 'right':
						return item.y;
					default:
						return 0;
				}
			else
				switch(style)
				{
					case 'drop':
						return screenH;
					case 'rise':
						return -H;
					case 'left':
					case 'right':
						return item.y;
					default:
						return 0;
				}
				
			return 0;
			
		}
	}

}