package  
{
    import aerys.minko.render.Viewport;
    import aerys.minko.scene.node.Camera;
    import aerys.minko.scene.node.Group;
    import aerys.minko.scene.node.mesh.geometry.primitive.QuadGeometry;
    import aerys.minko.scene.node.mesh.Mesh;
    import aerys.minko.scene.node.Scene;
    import aerys.minko.type.math.Vector4;
    import arsupport.demo.minko.In2ArLogo;
    import arsupport.minko.MinkoCameraController;
    import arsupport.minko.MinkoCaptureGeometry;
    import arsupport.minko.MinkoCaptureMesh;
    import arsupport.minko.MinkoIN2ARController;
    import flash.desktop.NativeApplication;
    import flash.desktop.SystemIdleMode;
    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.display.Sprite;
    import flash.display.Stage3D;
    import flash.display.StageAlign;
    import flash.display.StageQuality;
    import flash.display.StageScaleMode;
    import flash.display3D.Context3DRenderMode;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.geom.Rectangle;
    import flash.text.TextField;
    import flash.text.TextFormat;
    import flash.ui.Multitouch;
    import flash.ui.MultitouchInputMode;
    import flash.utils.ByteArray;
    import flash.utils.setTimeout;

    import ru.inspirit.asfeat.ane.ASFEATInterface;
    import ru.inspirit.asfeat.calibration.IntrinsicParameters;
    import ru.inspirit.asfeat.detect.ASFEATReference;
    import ru.inspirit.asfeat.event.ASFEATDetectionEvent;
    import ru.inspirit.capture.CaptureDevice;
    import ru.inspirit.capture.CaptureDeviceInfo;
    
	
	/**
     * ...
     * @author Eugene Zatepyakin
     */
    [SWF(frameRate='30',backgroundColor='0xFFFFFF')]
    public final class ANEMinkoCaptureDemo extends Sprite 
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
        private var stageW:int = 640;
        private var stageH:int = 480;
		private var scene:Scene;
		private var camera:Camera;
		private var view:Viewport;
		
		// different visual objects
        public static var text:TextField;
		
		// 3d stuff
        private var cameraController:MinkoCameraController;
        private var cameraMesh:MinkoCaptureMesh;
        private var plane:Mesh;
        private var model:In2ArLogo;
        private var controller:MinkoIN2ARController;
		
        // Capture stuff
        public var clipRect:Rectangle = new Rectangle(0, 0, 512, 512);
        public var capture:CaptureDevice;
        public var devices:Vector.<CaptureDeviceInfo>;
        public var streamW:int = 640;
        public var streamH:int = 480;
        public var streamFPS:int = 15;
        
        public function ANEMinkoCaptureDemo() 
        {
            stage.scaleMode = StageScaleMode.NO_SCALE;
            stage.align = StageAlign.TOP_LEFT;
            stage.quality = StageQuality.LOW;

            // seems to be buggy
            //stage.addEventListener(Event.DEACTIVATE, deactivate);
            Multitouch.inputMode = MultitouchInputMode.TOUCH_POINT;
            NativeApplication.nativeApplication.systemIdleMode = SystemIdleMode.KEEP_AWAKE;

            // save some CPU cicles
            mouseEnabled = false;
            mouseChildren = false;

            // so yes its a hack to get real stage dimension
            getContext();
            /*
            initCamera();
            initASFEAT();
            initEngine();
            initText();
            initObjects();
            initListeners();
            */
        }
        
        private function deactivate(e:Event=null):void
		{
            removeListeners();
            //if(CaptureDevice.available) CaptureDevice.unInitialize();
            if(capture) capture.dispose();
            if(asfeat) asfeat.dispose();

            capture = null;
            asfeat = null;
			// auto-close
			//NativeApplication.nativeApplication.exit();
		}

        private function onContextCreated(event:Event):void
        {
            var stage3D:Stage3D = stage.stage3Ds[0];
            stage3D.removeEventListener(Event.CONTEXT3D_CREATE, onContextCreated);
            stage3D.context3D.dispose();

            initCamera();
            initASFEAT();
            initEngine();
            initText();
            initObjects();
            initListeners();
        }

        protected function getContext(): void
        {
            var stage3D:Stage3D = stage.stage3Ds[0];
            stage3D.addEventListener(Event.CONTEXT3D_CREATE, onContextCreated);
            stage3D.requestContext3D(Context3DRenderMode.AUTO);
        }
        
		private function initCamera():void
		{            
            // static initializer
            // just loads native library/code to memory
            CaptureDevice.initialize();

            // lets see if we are on desktop or mobile
            if(!CaptureDevice.supportsSaveToCameraRoll())
            {
                // run at full resolution/power
                streamFPS = 30;
                clipRect = null;
            }
            
            devices = CaptureDevice.getDevices(true);
            
            capture = null;
            
            var dev:CaptureDeviceInfo = devices[0]; // Back Camera on mobiles
            //
            try
            {
                capture = new CaptureDevice(dev.name, streamW, streamH, streamFPS);
                
                // result camera dimension may be different from requested
                streamW = capture.width;
                streamH = capture.height;
            }
            catch (err:Error)
            {
                // "CAN'T CONNECT TO CAMERA :("
            }
            
            if (capture)
            {
                // we will use bytearrays only
                // raw bytes for asfeat & power of 2 for stage3D
                // use clip rectangle to force 512x512 capture texture
                capture.setupForDataType(CaptureDevice.GET_FRAME_RAW_BYTES
                                            | CaptureDevice.GET_POWER_OF_2_FRAME_BGRA_BYTES, clipRect);
            }
		}

        protected var refOccl:BitmapData;
        protected var occl_bmp:Bitmap;
		private function initASFEAT():void
		{
            asfeat = new ASFEATInterface();
            asfeat.allocate(streamW, streamH, maxPoints, maxReferences);
            asfeat.setupIndexing(12, 10, true);
			// ATTENTION 
			// use it if u want only one model to be detected
			// and available at single frame (better performance)
            asfeat.setMaxReferencesPerFrame(1);
            asfeat.setMaxTrackIterations(maxTrackIterations);

            var vob_id:int = asfeat.addReference(ByteArray(new DefinitionaData));
		}
		
		private function initEngine():void
		{			
			intrinsic = asfeat.getIntrinsicParameters();
            
            stageW = stage.stageWidth;
            stageH = stage.stageHeight;
			
            view = new Viewport(0, stageW, stageH);
            scene = new Scene();
            camera = new Camera();
            
            cameraMesh = new MinkoCaptureMesh(view.width, view.height, 
                                                streamW, streamH, 
                                                MinkoCaptureGeometry.FILL_MODE_PRESERVE_ASPECT_RATIO_AND_FILL, clipRect);
            cameraMesh.setupForByteArray(capture.bgraP2Bytes);
            
            // calculate scale for camera
            var camScale:Number = clipRect ? view.width / clipRect.width : Math.max(stageW / streamW, stageH / streamH);
            cameraController = new MinkoCameraController(intrinsic, camScale);
            camera.removeAllControllers();
            camera.addController(cameraController);
            
            scene.addChild(camera);
            scene.addChild(cameraMesh);
			
			addChild(view);
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
		
        private var group:Group;
		private function initObjects():void
		{
            model = new In2ArLogo();
            plane = new Mesh(QuadGeometry.quadGeometry, { diffuseColor : 0x333333 });
            plane.transform.prependRotation(Math.PI, Vector4.X_AXIS)
							.prependScale(550, 440, 1);
            
            group = new Group(/*plane, */model);

            // setup controller
            controller = new MinkoIN2ARController(maxReferences);
            controller.addReference(0, group);
            
            scene.addChild(group);
		}
		
		private function initListeners():void
		{
			asfeat.addEventListener(ASFEATDetectionEvent.DETECTED, onModelDetected);
			asfeat.addEventListener(ASFEATDetectionEvent.FAILED, onDetectionFailed);
			addEventListener(Event.ENTER_FRAME, onEnterFrame);
            stage.doubleClickEnabled = true;
            stage.addEventListener(MouseEvent.DOUBLE_CLICK, onDoubleClick);
		}

        private function removeListeners():void
        {
            asfeat.removeEventListener(ASFEATDetectionEvent.DETECTED, onModelDetected);
            asfeat.removeEventListener(ASFEATDetectionEvent.FAILED, onDetectionFailed);
            removeEventListener(Event.ENTER_FRAME, onEnterFrame);
            stage.removeEventListener(MouseEvent.DOUBLE_CLICK, onDoubleClick);
        }
		
		private function onEnterFrame(e:Event = null):void
		{
            var isNewFrame:Boolean;
            
            isNewFrame = capture.requestFrame(CaptureDevice.GET_FRAME_RAW_BYTES
                                                | CaptureDevice.GET_POWER_OF_2_FRAME_BGRA_BYTES);
            
            if(isNewFrame)
            {
                asfeat.processCaptureRawData(capture.rawBytes, streamW, streamH);
                
                //manually invalidate texture
                cameraMesh.invalidate();
                
                // call it each frame so if lost will accur
                // more then 5 frames with no detected/tracked event
                // it will be erased from the screen
                controller.lost();
                
                scene.render(view);
            }
		}
		
		private function onModelDetected(e:ASFEATDetectionEvent):void
		{
			var refList:Vector.<ASFEATReference> = e.detectedReferences;
			var ref:ASFEATReference;
			var n:int = e.detectedReferencesCount;
			var state:String;
			
			loop: for(var i:int = 0; i < n; ++i) {
				ref = refList[i];
				state = ref.detectType;
				//
                controller.setTransform( ref.id, ref.rotationMatrix, ref.translationVector, ref.poseError, false );
				text.text = state;
                text.appendText( ' @ ' + ref.id );
				
				if(state == '_detect')
					text.appendText( ' :: matched: ' + ref.matchedPointsCount );
			}
		}
        
        private function onDetectionFailed(e:ASFEATDetectionEvent):void 
        {
            text.text = "nothing found";
        }

        private function onDoubleClick(e:MouseEvent):void
        {
            if(capture)
            {
                //capture.focusAtPoint();
            }
        }
    }

}