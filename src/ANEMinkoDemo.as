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
    import flash.media.Video;
    import flash.text.TextField;
    import flash.text.TextFormat;
    import flash.ui.Multitouch;
    import flash.ui.MultitouchInputMode;
    import flash.utils.ByteArray;

    import net.hires.debug.Stats;

    import ru.inspirit.asfeat.ane.ASFEATInterface;
    import ru.inspirit.asfeat.calibration.IntrinsicParameters;
    import ru.inspirit.asfeat.detect.ASFEATReference;
    import ru.inspirit.asfeat.event.ASFEATDetectionEvent;
    
	
	/**
     * ...
     * @author Eugene Zatepyakin
     */
    [SWF(frameRate='30',backgroundColor='0xFFFFFF')]
    public final class ANEMinkoDemo extends Sprite 
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
        public var streamW:int = 640;
        public var streamH:int = 480;
        public var streamFPS:int = 30;
        // for mobiles to prevent 1024x512 texture upload
        public var clipRect:Rectangle = new Rectangle(0, 0, 512, 512);
        public var deviceCam:flash.media.Camera;

        public var _stat:Stats;
        
        public function ANEMinkoDemo() 
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

            // so yes its a hack to get real stage dimension
            getContext();
            /*
            initNativeCamera();
            initASFEAT();
            initEngine();
            initText();
            initObjects();
            initListeners();
            */
        }
        
        private function deactivate(e:Event = null):void 
		{
            removeEventListener(Event.ENTER_FRAME, onEnterFrame);
            video.attachCamera(null);
            deviceCam = null;
            video = null;
            if (asfeat) asfeat.dispose();
            asfeat = null;
			// auto-close
			//NativeApplication.nativeApplication.exit();
		}

        private function onContextCreated(event:Event):void
        {
            var stage3D:Stage3D = stage.stage3Ds[0];
            stage3D.removeEventListener(Event.CONTEXT3D_CREATE, onContextCreated);
            stage3D.context3D.dispose();

            initNativeCamera();
            initASFEAT();
            initEngine();
            initText();
            iniStats();
            initObjects();
            initListeners();
        }

        protected function getContext(): void
        {
            var stage3D:Stage3D = stage.stage3Ds[0];
            stage3D.addEventListener(Event.CONTEXT3D_CREATE, onContextCreated);
            stage3D.requestContext3D(Context3DRenderMode.AUTO);
        }
        
        private function initASFEAT():void
		{            
            asfeat = new ASFEATInterface();
            asfeat.allocate(streamW, streamH, maxPoints, maxReferences);
            asfeat.setupIndexing(12, 10, true);
            asfeat.setUseLSHDictionary(true);
            
			// ATTENTION 
			// use it if u want only limited amount of objects to be detected
			// and available at single frame (better performance)
            asfeat.setMaxReferencesPerFrame(0);
            asfeat.setMaxTrackIterations(maxTrackIterations);

            asfeat.addReference(ByteArray(new DefinitionaData));
		}
        
        private function initEngine():void
		{
			intrinsic = asfeat.getIntrinsicParameters();
            
            stageW = stage.stageWidth;
            stageH = stage.stageHeight;
			
            view = new Viewport(2, stageW, stageH);
            scene = new Scene();
            camera = new Camera();
            
            cameraMesh = new MinkoCaptureMesh(view.width, view.height, 
                                                streamW, streamH, 
                                                MinkoCaptureGeometry.FILL_MODE_PRESERVE_ASPECT_RATIO_AND_FILL, clipRect);
            cameraMesh.setupForBitmapData(buffer);
            
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

        private function iniStats():void
        {
            _stat = new Stats();
            _stat.x = streamW - 70;
            _stat.y = streamH - 100;
            addChild(_stat);
        }
		
        private var group:Group;
		private function initObjects():void
		{
            model = new In2ArLogo();
            //plane = new Mesh(QuadGeometry.quadGeometry, { diffuseColor : 0x333333 });
            //plane.transform.prependRotation(Math.PI, Vector4.X_AXIS)
							//.prependScale(550, 440, 1);
            
            group = new Group(/*plane, */model);
            
            // controller
            controller = new MinkoIN2ARController(maxReferences);
            controller.addReference(0, group);
            
            scene.addChild(group);
		}
		
		private function initListeners():void
		{
            asfeat.addEventListener(ASFEATDetectionEvent.DETECTED, onModelDetected);
			asfeat.addEventListener(ASFEATDetectionEvent.FAILED, onDetectionFailed);
			addEventListener(Event.ENTER_FRAME, onEnterFrame);
		}
		
        private var _frame:int = 0;
		private function onEnterFrame(e:Event = null):void
		{
            // since movie fps is 30 and cam is 15
            // we render every second frame
            //if (++_frame & 1)
            {
                deviceCam.drawToBitmapData(buffer);
                asfeat.process(buffer);
                asfeat.renderPoints(buffer, 0);
                cameraMesh.invalidate();
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
			
			loop: for (var i:int = 0; i < n; ++i) 
            {
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
        
        private var video:Video;
        private var buffer:BitmapData;
        private function initNativeCamera():void
		{
			deviceCam = flash.media.Camera.getCamera();
            deviceCam.setMode(streamW, streamH, streamFPS, false);
			
			video = new Video();
			video.attachCamera(deviceCam);
			
			buffer = new BitmapData(streamW, streamH, false, 0x00);
		}
        
    }

}