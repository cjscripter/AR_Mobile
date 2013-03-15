package  
{
    import aerys.minko.render.Viewport;
    import aerys.minko.scene.node.Camera;
    import aerys.minko.scene.node.Group;
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
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import flash.geom.Vector3D;
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
    import ru.inspirit.asfeat.light.LightMap;
    
	
	/**
     * ...
     * @author Eugene Zatepyakin
     */
    [SWF(frameRate='30', backgroundColor='0xFFFFFF')]
    public final class ANEMinkoLightMapDemo extends Sprite 
    {
        // tracking data file
		[Embed(source="../assets/def_data.ass", mimeType="application/octet-stream")]
		public static const DefinitionaData:Class;
        
        [Embed(source = '../assets/def_marker.jpg')]
		private static const ref_ass:Class;
        
        public var refImg:BitmapData = Bitmap(new ref_ass).bitmapData;
        
        //asfeat variables
        public var asfeat:ASFEATInterface;
        public var intrinsic:IntrinsicParameters;
        public var lightMap:LightMap;
        public var maxPoints:int = 300; // max points to allow to detect
        public var maxReferences:int = 1; // max objects will be used
        public var maxTrackIterations:int = 3; // track iterations
		
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
        private var model:In2ArLogo;
        private var controller:MinkoIN2ARController;
		
        // Capture stuff
        public var streamW:int = 640;
        public var streamH:int = 480;
        public var streamFPS:int = 15;
        public var clipRect:Rectangle = new Rectangle(0, 0, 512, 512);
        public var deviceCam:flash.media.Camera;
        
        public function ANEMinkoLightMapDemo() 
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

        private function onContextCreated(event:Event):void
        {
            var stage3D:Stage3D = stage.stage3Ds[0];
            stage3D.removeEventListener(Event.CONTEXT3D_CREATE, onContextCreated);
            stage3D.context3D.dispose();

            initNativeCamera();
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
        
        private function deactivate(e:Event):void 
		{
            removeEventListener(Event.ENTER_FRAME, onEnterFrame);
            if(asfeat) asfeat.dispose();
			// auto-close
			//NativeApplication.nativeApplication.exit();
		}
        
        private function initASFEAT():void
		{            
            asfeat = new ASFEATInterface();
            asfeat.allocate(streamW, streamH, maxPoints, maxReferences);
            asfeat.setupIndexing(12, 10, true);
			// ATTENTION 
			// use it if u want only limited amount of objects to be detected
			// and available at single frame (better performance)
            asfeat.setMaxReferencesPerFrame(1);
            asfeat.setMaxTrackIterations(maxTrackIterations);

            asfeat.addReference(ByteArray(new DefinitionaData));
            
            // init light map
            lightMap = new LightMap();
			// we downscale reference image because 
			// in real life we will never detect it
			// at original size on the screen
			var sampWidth:int = refImg.width / 3;
			var sampHeight:int = refImg.height / 3;
            // init LightMap
			lightMap.setup(128);
			lightMap.init(refImg, sampWidth, sampHeight, 8, 6);
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
		
		private function initObjects():void
		{
            model = new In2ArLogo();
            // light map
            model.setupLightMap(lightMap.mapBitmapData);
            
            // controller
            controller = new MinkoIN2ARController(maxReferences);
            controller.addReference(0, model);
            
            scene.addChild(model);
		}
		
		private function initListeners():void
		{
            asfeat.addEventListener(ASFEATDetectionEvent.DETECTED, onModelDetected);
			asfeat.addEventListener(ASFEATDetectionEvent.FAILED, onDetectionFailed);
			addEventListener(Event.ENTER_FRAME, onEnterFrame);
		}
		
        private var _frame:int = 0;
        private const lightmap_pt:Point = new Point(50, 80);
		private function onEnterFrame(e:Event = null):void
		{
            // since movie fps is 30 and cam is 15
            // we render every second frame
            if (++_frame & 1)
            {
                deviceCam.drawToBitmapData(buffer);
                asfeat.process(buffer);
                
                //buffer.copyPixels(lightMap.mapBitmapData, lightMap.mapRect, lightmap_pt);
                
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
				
                controller.setTransform( ref.id, ref.rotationMatrix, ref.translationVector, ref.poseError, false );
				text.text = state;
                text.appendText( ' @ ' + ref.id );
				
				if(state == '_detect')
					text.appendText( ' :: matched: ' + ref.matchedPointsCount );
                    
                // update light map
                // care about precision
                // update only when fully visible and trackable
                var tl_x:Number = ref.TLx;
                var tl_y:Number = ref.TLy;
                var tr_x:Number = ref.TRx;
                var tr_y:Number = ref.TRy;
                var bl_x:Number = ref.BLx;
                var bl_y:Number = ref.BLy;
                var br_x:Number = ref.BRx;
                var br_y:Number = ref.BRy;
                if (state == "_track" 
                    && tl_x > 0 && tl_x < streamW && tr_x > 0 && tr_x < streamW
                    && bl_x > 0 && bl_x < streamW && br_x > 0 && br_x < streamW
                    && tl_y > 0 && tl_y < streamH && tr_y > 0 && tr_y < streamH
                    && bl_y > 0 && bl_y < streamH && br_y > 0 && br_y < streamH)
                {
                    var normal:Vector3D = model.getSurfaceNormal();
                    lightMap.addNormal(buffer, normal,
                                        tl_x, tl_y, tr_x, tr_y, 
                                        br_x, br_y, bl_x, bl_y);
                    
                    lightMap.invalidate();
                    model.updateLightMap();
                }
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
			
			video = new Video(deviceCam.width, deviceCam.height);
			video.attachCamera(deviceCam);
			
			buffer = new BitmapData(streamW, streamH, false, 0x00);
		}
    }

}