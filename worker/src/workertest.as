package
{
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.system.MessageChannel;
	import flash.system.Worker;
	import flash.system.WorkerDomain;
	import flash.system.WorkerState;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	
	[SWF(width="600", height="440", frameRate="60", backgroundColor="#CCCCCC")]
	public class workertest extends Sprite
	{
		//*********************************************************
		// VARIABLES
		//*********************************************************
		private var worker:Worker;
		private var mainTo:MessageChannel;
		private var workerTo:MessageChannel;
		
		private var log:TextField;
		private var balls:Array;
		private var seed:Number = 1;
		private var container:Sprite;
		private var fps:TextField;
		
		
		//*********************************************************
		// CONSTANTS
		//*********************************************************
		private const CENTER_X:int = 300;
		private const CENTER_Y:int = 220;
		private const MAX_BALL:int = 400;
		private const HARDCOST_LOOP:int = 100000000;
		
		
		//*********************************************************
		// PUBLIC METHODS
		//*********************************************************
		/**
		 * constructor 
		 */		
		public function workertest()
		{
			init();
		}
		
		
		//*********************************************************
		// PRIVATE METHODS
		//*********************************************************
		
		/**
		 * init 
		 */		
		private function init():void
		{
			balls = [];
			
			container = new Sprite();
			container.x = CENTER_X;
			container.y = CENTER_Y;
			container.mouseChildren = false;
			container.mouseEnabled = false;
			addChild(container);
			
			log = createTextField();
			log.text = "Worker Test";
			addChild(log);
			
			fps = createTextField();
			fps.text = 'fps : ' + String(stage.frameRate);
			fps.x = stage.stageWidth - fps.width;
			fps.y = stage.stageHeight - fps.height;
			addChild(fps);
			
			var time:Number = new Date().time;
			
			// single thread
//			singleThreadTest();
			
			// multi thread
			multiThreadTest();
			
			// 経過時間
			log.appendText('\n');
			log.appendText('left time : ' + String(new Date().time - time));
			trace(new Date().time - time);
		}
		
		/**
		 * single thread test method
		 */		
		private function singleThreadTest():void
		{
			// メイン処理
			mainMethod();
			
			// 負荷の高い処理
			hardCostMethod();
		}
		
		/**
		 * multi thread test method
		 */		
		private function multiThreadTest():void
		{
			// main worker
			if (Worker.current.isPrimordial)
			{
				// メイン処理
				mainMethod();
				
				// sub worker
				worker = WorkerDomain.current.createWorker(loaderInfo.bytes);
				
				// worker 間通信用チャンネル
				mainTo = Worker.current.createMessageChannel(worker);
				workerTo = worker.createMessageChannel(Worker.current);
				
				// worker 間共有プロパティ登録
				worker.setSharedProperty("mainTo", mainTo);
				worker.setSharedProperty("workerTo", workerTo);
				
				// message 受信イベントハンドラ (sub worker -> main worker)
				workerTo.addEventListener(Event.CHANNEL_MESSAGE, workerToHandler);
				
				// state event handler
				worker.addEventListener(Event.WORKER_STATE, workerStateHandler);
				
				// worker 処理開始
				worker.start();
			}
			// sub worker
			else
			{
				// worker 間共有プロパティ取得
				mainTo = Worker.current.getSharedProperty("mainTo");
				workerTo = Worker.current.getSharedProperty("workerTo");
				
				// message 受信イベントハンドラ (main worker -> sub worker)
				mainTo.addEventListener(Event.CHANNEL_MESSAGE, mainToHandler);
				
				// 重い処理
				hardCostMethod();
			}
		}
		
		/**
		 * message 受信イベントハンドラ (sub worker -> main worker)
		 * @param e
		 */		
		private function workerToHandler(e:Event):void
		{
			if (e.target.messageAvailable == false) return;
			
			var message:* = workerTo.receive();
			
			trace('[worker to receive]' + message);
			log.appendText('\n');
			log.appendText('worker to receive : ' + message);
			
			if (message == 'worker ready')
			{
				var inc:int = workerTo.receive() + workerTo.receive() + workerTo.receive();
				
				trace('[worker to receive]' + inc);
				log.appendText('\n');
				log.appendText('worker to receive : ' + inc);
			}
		}
		
		/**
		 * message 受信イベントハンドラ (main worker -> sub worker)
		 * @param e
		 */		
		private function mainToHandler(e:Event):void
		{
			if (e.target.messageAvailable == false) return;
			
			var message:* = mainTo.receive();
			
			workerTo.send(message);
			
			if (message == 'worker ready')
			{
				workerTo.send(1);
				workerTo.send(2);
				workerTo.send(3);
			}
		}
		
		/**
		 * state event handler
		 * @param e
		 */		
		private function workerStateHandler(e:Event):void
		{
			if (e.target.state == WorkerState.RUNNING)
			{
				mainTo.send('worker ready');
			}
		}
		
		/**
		 * 描画処理 
		 */		
		private function mainMethod():void
		{
			var i:int;
			var ball:Sprite;
			var fibonacci:Number;
			for (i = 0; i < MAX_BALL; i++)
			{
				ball = createBall();
				fibonacci = i * 1 * Math.PI * ((1 + Math.sqrt(5)) * .5);
				ball.x = (Math.cos(fibonacci) * i);
				ball.y = (Math.sin(fibonacci) * i);
				container.addChild(ball);
				balls[i] = ball;
			}
			
			addEventListener(Event.ENTER_FRAME, enterFrameHandler); 
		}
		
		/**
		 * enter frame handler
		 * @param e
		 */		
		private function enterFrameHandler(e:Event):void
		{
			var i:int;
			var ball:Sprite;
			var fibonacci:Number;
			seed += 0.00001;
			
			for (i = 0; i < MAX_BALL; i++)
			{
				ball = balls[i];
				fibonacci = i * seed * Math.PI * ((1 + Math.sqrt(5)) * .5);
				ball.x += ((Math.cos(fibonacci) * i) - ball.x) * .5;
				ball.y += ((Math.sin(fibonacci) * i) - ball.y) * .5;
			}
			
			fps.text = 'fps : ' + String(stage.frameRate);
			fps.x = stage.stageWidth - fps.width;
		}
		
		/**
		 * 重い処理 
		 */		
		private function hardCostMethod():void
		{
			trace('start hard cost method');
			if (workerTo) workerTo.send('start hard cost method');
			
			var time:Number = new Date().time;
			
			var n:int = 0;
			var i:int
			for (i = 0; i < HARDCOST_LOOP; i++)
			{
				n = i;
			}
			
			// 経過時間
			if (workerTo) workerTo.send('left time : ' + String(new Date().time - time));
			trace('end hard cost method');
			if (workerTo) workerTo.send('end hard cost method');
		}
		
		/**
		 * text field 生成 
		 */		
		private function createTextField():TextField
		{
			var textField:TextField = new TextField();
			textField.selectable = false;
			textField.mouseEnabled = false;
			textField.autoSize = TextFieldAutoSize.LEFT;
			textField.background = true;
			
			return textField;
		}
		
		/**
		 * ball 生成 
		 */		
		private function createBall():Sprite
		{
			var ball:Sprite = new Sprite();
			ball.graphics.beginFill(0, .5);
			ball.graphics.drawCircle(0, 0, 20);
			ball.graphics.endFill();
			
			return ball;
		}
	}
}