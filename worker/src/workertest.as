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
	
	[SWF(width="800", height="600", frameRate="60", backgroundColor="#CCCCCC")]
	public class workertest extends Sprite
	{
		//*********************************************************
		// VARIABLES
		//*********************************************************
		private var worker:Worker;
		private var mainTo:MessageChannel;
		private var workerTo:MessageChannel;
		
		private var ball:Sprite;
		private var log:TextField;
		
		
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
			log = createTextField();
			addChild(log);
			log.text = "Worker Test";
			
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
				// sub worker
				worker = WorkerDomain.current.createWorker(loaderInfo.bytes);
				
				// 描画処理
				mainMethod();
				
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
			ball = new Sprite();
			ball.graphics.beginFill(0);
			ball.graphics.drawCircle(0, 0, 20);
			ball.graphics.endFill();
			ball.y = int(stage.stageHeight * .5);
			addChild(ball);
			
			addEventListener(Event.ENTER_FRAME, enterFrameHandler); 
		}
		
		/**
		 * enter frame handler
		 * @param e
		 */		
		private function enterFrameHandler(e:Event):void
		{
			ball.x += 1;
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
			for (i = 0; i < 100000000; i++)
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
			
			return textField;
		}
	}
}