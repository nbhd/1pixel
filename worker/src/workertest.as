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
		private var worker:Worker;
		private var mainTo:MessageChannel;
		private var workerTo:MessageChannel;
		
		private var ball:Sprite;
		private var log:TextField;
		
		public function workertest()
		{
			init();
		}
		
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
			log.appendText('\nleft time : ' + String(new Date().time - time));
			trace(new Date().time - time);
		}
		
		private function singleThreadTest():void
		{
			// メイン処理
			mainMethod();
			
			// 負荷の高い処理
			hardCostMethod();
		}
		
		private function multiThreadTest():void
		{
			if (Worker.current.isPrimordial)
			{
				worker = WorkerDomain.current.createWorker(loaderInfo.bytes);
				
				mainMethod();
				
				mainTo = Worker.current.createMessageChannel(worker);
				workerTo = worker.createMessageChannel(Worker.current);
				
				worker.setSharedProperty("mainTo", mainTo);
				worker.setSharedProperty("workerTo", workerTo);
				
				workerTo.addEventListener(Event.CHANNEL_MESSAGE, workerToHandler);
				
				worker.addEventListener(Event.WORKER_STATE, workerStateHandler);
				worker.start();
			}
			else
			{
				mainTo = Worker.current.getSharedProperty("mainTo");
				workerTo = Worker.current.getSharedProperty("workerTo");
				
				mainTo.addEventListener(Event.CHANNEL_MESSAGE, mainToHandler);
				hardCostMethod();
			}
		}
		
		private function workerToHandler(e:Event):void
		{
			if (e.target.messageAvailable == false) return;
			var message:* = workerTo.receive();
			trace('[worker to receive]' + message);
			log.appendText('\nworker to receive : ' + message);
		}
		
		private function mainToHandler(e:Event):void
		{
			if (e.target.messageAvailable == false) return;
			var message:* = mainTo.receive();
			
			workerTo.send(message);
		}
		
		private function workerStateHandler(e:Event):void
		{
			if (e.target.state == WorkerState.RUNNING)
			{
				mainTo.send('worker ready');
			}
		}
		
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
		
		private function enterFrameHandler(e:Event):void
		{
			ball.x += 1;
		}
		
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