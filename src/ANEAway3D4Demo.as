package  
{
    import arsupport.away3d4.ARAway3D4Container;
    import arsupport.away3d4.Away3D4CameraTexture;
    import arsupport.away3d4.Away3D4Lens;
    import arsupport.demo.away3d4.In2ArLogo;
    
    import away3d.cameras.Camera3D;
    import away3d.containers.Scene3D;
    import away3d.containers.View3D;
    import away3d.debug.AwayStats;
    
    import flash.display.BitmapData;
    import flash.display.Sprite;
    import flash.display.StageAlign;
    import flash.display.StageQuality;
    import flash.display.StageScaleMode;
    import flash.events.Event;
    import flash.geom.Matrix;
    import flash.geom.Vector3D;
    import flash.media.Camera;
    import flash.media.Video;
    import flash.text.TextField;
    import flash.text.TextFormat;
    import flash.ui.Multitouch;
    import flash.ui.MultitouchInputMode;
    import flash.utils.ByteArray;
    
    import ru.inspirit.asfeat.ane.ASFEATInterface;
    import ru.inspirit.asfeat.calibration.IntrinsicParameters;
    import ru.inspirit.asfeat.detect.ASFEATReference;
    import ru.inspirit.asfeat.event.ASFEATDetectionEvent;	
	
	
	/**
	 * @author Eugene Zatepyakin
	 */
	[SWF(frameRate='30',backgroundColor='0xFFFFFF')]
	public final class ANEAway3D4Demo extends Sprite 
	{
		// tracking data file
		[Embed(source="../assets/def_data.ass", mimeType="application/octet-stream")]
		public static const DefinitionaData:Class;
		
		//asfeat variables
        public var asfeat:ASFEATInterface;
        public var intrinsic:IntrinsicParameters;
        public var maxPoints:int = 300; // max points to allow to detect
        public var maxReferences:int = 1; // max objects will be used
        public var maxTrackIterations:int = 5; // track iterations
		
		//engine variables
		private var scene:Scene3D;
		private var camera:Camera3D;
		private var view:View3D;
		private var awayStats:AwayStats;
		
		
		// different visual objects
        public static var text:TextField;
        private var video:Video;
		private var cameraBuffer:BitmapData;
		private var buffer:BitmapData;
		private var cameraMatrix:Matrix;
		
		// 3d stuff
		private var asFeatLens:Away3D4Lens;
		private var model:ARAway3D4Container;
        private var backgroundTexture:Away3D4CameraTexture;
		
	
		// camera size
		public var camWidth:int = 1024;
        public var camHeight:int = 512;
		
        public var srcWidth:int = 640;
        public var srcHeight:int = 480;
        public var deviceCam:Camera;
        
		
		public function ANEAway3D4Demo() 
		{
            if (stage)
            {
                init();
            } else {
                addEventListener(Event.ADDED_TO_STAGE, init);
            }
		}
        private function deactivate(e:Event):void 
		{
			// auto-close
			//NativeApplication.nativeApplication.exit();
		}
		
		private function init(e:Event = null):void
		{
            stage.scaleMode = StageScaleMode.NO_SCALE;
            stage.align = StageAlign.TOP_LEFT;
            stage.quality = StageQuality.LOW;

            //stage.addEventListener(Event.DEACTIVATE, deactivate);
            Multitouch.inputMode = MultitouchInputMode.TOUCH_POINT;
            //NativeApplication.nativeApplication.systemIdleMode = SystemIdleMode.KEEP_AWAKE;

            // save some CPU cicles
            mouseEnabled = false;
            mouseChildren = false;
            
            initCamera();
			initASFEAT();
			initEngine();
			initText();
			initObjects();
			initListeners();
		}
		
		private function initCamera():void
		{
            deviceCam = Camera.getCamera();
            deviceCam.setMode(srcWidth, srcHeight, 15, false);
			
			video = new Video();
			video.attachCamera(deviceCam);
			
            var scx:Number = camWidth / srcWidth;
            var scy:Number = camHeight / srcHeight;
			cameraMatrix = new Matrix(scx, 0, 0, scy);
			
			buffer = new BitmapData(srcWidth, srcHeight, false, 0x00);
			cameraBuffer = new BitmapData(camWidth, camHeight, false, 0x0);
			
			// The depthAndStencil flag in the application descriptor must match the enableDepthAndStencil 
			// Boolean passed to configureBackBuffer on the Context3D object
		}
		
		private function initASFEAT():void
		{
			asfeat = new ASFEATInterface();
            asfeat.allocate(srcWidth, srcHeight, maxPoints, maxReferences);
            asfeat.setupIndexing(12, 10, true);
			// ATTENTION 
			// use it if u want only one model to be detected
			// and available at single frame (better performance)
            asfeat.setMaxReferencesPerFrame(1);
            asfeat.setMaxTrackIterations(maxTrackIterations);

            asfeat.addReference(ByteArray(new DefinitionaData));
		}
		
		private function initEngine():void
		{			
			intrinsic = asfeat.getIntrinsicParameters();
			
			asFeatLens = new Away3D4Lens(intrinsic, srcWidth, srcHeight, 1.0);
			
			view = new View3D();
			view.camera.lens = asFeatLens;
			view.camera.position = new Vector3D();
			
			view.antiAlias = 0;
			backgroundTexture = new Away3D4CameraTexture(cameraBuffer);
			view.background = backgroundTexture;
			
			addChild(view);
            
            view.stage3DProxy.configureBackBuffer(stage.stageWidth, stage.stageHeight, 0, true);
			
			awayStats = new AwayStats(view);
			addChild(awayStats);
		}
		
		private function initText():void
		{
			// DEBUG TEXT FIELD
			text = new TextField();
			text.defaultTextFormat = new TextFormat("Verdana", 11, 0xFFFFFF);
            text.background = true;
            text.backgroundColor = 0x000000;
            text.textColor = 0xFFFFFF;
			text.width = 300;
			text.height = 18;
			text.selectable = false;
			text.mouseEnabled = false;
			addChild(text);
		}
		
		private function initObjects():void
		{
			model = new In2ArLogo();
			view.scene.addChild(model);
		}
		
		private function initListeners():void
		{
			asfeat.addEventListener(ASFEATDetectionEvent.DETECTED, onModelDetected);
			asfeat.addEventListener(ASFEATDetectionEvent.FAILED, onDetectionFailed);
			addEventListener(Event.ENTER_FRAME, onEnterFrame);
			onResize();
		}
		
        private var _frame:int = 0;
		private function onEnterFrame(e:Event = null):void
		{	
            // run only every second frame 
            // because we set camera fps to 15
            if (++_frame & 1)
            {
                //draw video stream to detection buffer & run detection
                deviceCam.drawToBitmapData(buffer);
                
                asfeat.process(buffer);
                
                // draw detection buffer to camera buffer
                cameraBuffer.draw(buffer, cameraMatrix);
                
                //manually invalidate background texture
                backgroundTexture.invalidateContent();
                
                // call it each frame so if lost will accur
                // more then 5 frames with no detected/tracked event
                // it will be erased from the screen
                model.lost();
                
                view.render();
            }
		}
		
		private function onModelDetected(e:ASFEATDetectionEvent):void
		{
			var refList:Vector.<ASFEATReference> = e.detectedReferences;
			var ref:ASFEATReference;
			var n:int = e.detectedReferencesCount;
			var state:String;
			
			for(var i:int = 0; i < n; ++i) {
				ref = refList[i];
				state = ref.detectType;
				
				model.setTransform( ref.rotationMatrix, ref.translationVector, ref.poseError, false );
				text.text = state;
				
				trace(ref.rotationMatrix, ref.translationVector, ref.poseError);
				
				if(state == '_detect')
					text.appendText( '\nmatched: ' + ref.matchedPointsCount );
				
				text.appendText( '\nfound id: ' + ref.id );
			}
		}
        
        private function onDetectionFailed(e:ASFEATDetectionEvent):void 
        {
            text.text = "nothing found";
        }

		
		/**
		 * stage listener for resize events
		 */
		private function onResize(event:Event = null):void
		{
			view.width = stage.stageWidth;
			view.height = stage.stageHeight;
			text.y = stage.stageHeight - text.height;
			awayStats.x = stage.stageWidth - awayStats.width;
		}
		
	}

}