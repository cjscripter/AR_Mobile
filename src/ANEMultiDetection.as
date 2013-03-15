package
{
    import aerys.minko.render.Viewport;
    import aerys.minko.scene.node.Camera;
    import aerys.minko.scene.node.ISceneNode;
    import aerys.minko.scene.node.mesh.Mesh;
    import aerys.minko.scene.node.Scene;
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
    import flash.geom.Rectangle;
    import flash.media.Video;
    import flash.system.Capabilities;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.utils.ByteArray;
    import flash.utils.setTimeout;
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
	public final class ANEMultiDetection extends Sprite
	{
		// data files
		[Embed(source="../assets/chewgum/chewgum1.jpg.mobile.ass",mimeType="application/octet-stream")]
		public static const chew_1:Class;
		[Embed(source="../assets/chewgum/chewgum2.jpg.mobile.ass",mimeType="application/octet-stream")]
		public static const chew_2:Class;
		[Embed(source="../assets/chewgum/chewgum3.jpg.mobile.ass",mimeType="application/octet-stream")]
		public static const chew_3:Class;
		[Embed(source="../assets/chewgum/chewgum4.jpg.mobile.ass",mimeType="application/octet-stream")]
		public static const chew_4:Class;
		[Embed(source="../assets/chewgum/chewgum5.jpg.mobile.ass",mimeType="application/octet-stream")]
		public static const chew_5:Class;
		[Embed(source="../assets/chewgum/chewgum6.jpg.mobile.ass",mimeType="application/octet-stream")]
		public static const chew_6:Class;
		[Embed(source="../assets/chewgum/chewgum7.jpg.mobile.ass",mimeType="application/octet-stream")]
		public static const chew_7:Class;
		[Embed(source="../assets/chewgum/chewgum8.jpg.mobile.ass",mimeType="application/octet-stream")]
		public static const chew_8:Class;
		[Embed(source="../assets/chewgum/chewgum9.jpg.mobile.ass",mimeType="application/octet-stream")]
		public static const chew_9:Class;
		[Embed(source="../assets/chewgum/chewgum10.jpg.mobile.ass",mimeType="application/octet-stream")]
		public static const chew_10:Class;
		[Embed(source="../assets/chewgum/chewgum11.jpg.mobile.ass",mimeType="application/octet-stream")]
		public static const chew_11:Class;
		[Embed(source="../assets/chewgum/chewgum12.jpg.mobile.ass",mimeType="application/octet-stream")]
		public static const chew_12:Class;
		[Embed(source="../assets/chewgum/chewgum13.jpg.mobile.ass",mimeType="application/octet-stream")]
		public static const chew_13:Class;
		[Embed(source="../assets/chewgum/chewgum14.jpg.mobile.ass",mimeType="application/octet-stream")]
		public static const chew_14:Class;
		[Embed(source="../assets/chewgum/chewgum15.jpg.mobile.ass",mimeType="application/octet-stream")]
		public static const chew_15:Class;
		[Embed(source="../assets/chewgum/chewgum16.jpg.mobile.ass",mimeType="application/octet-stream")]
		public static const chew_16:Class;
		[Embed(source="../assets/chewgum/chewgum17.jpg.mobile.ass",mimeType="application/octet-stream")]
		public static const chew_17:Class;

        [Embed(source="../assets/def_data.ass",mimeType="application/octet-stream")]
        public static const data_def:Class;
		
		public const data_files:Vector.<ByteArray> = new <ByteArray>[ByteArray(new data_def),
            ByteArray(new chew_1), ByteArray(new chew_2), ByteArray(new chew_3), ByteArray(new chew_4), ByteArray(new chew_5), ByteArray(new chew_6), ByteArray(new chew_7), ByteArray(new chew_8), ByteArray(new chew_9), ByteArray(new chew_10), ByteArray(new chew_11), ByteArray(new chew_12), ByteArray(new chew_13), ByteArray(new chew_14), ByteArray(new chew_15), ByteArray(new chew_16), ByteArray(new chew_17)];
		
		//asfeat variables
		public var asfeat:ASFEATInterface;
        public var intrinsic:IntrinsicParameters;
		public var maxPoints:int = 300; // max points to allow to detect
		public var maxReferences:int = 18; // max objects will be used
		public var maxTrackIterations:int = 5; // track iterations
        public var maxRefsPerFrame:int = 2;
		
		public static var text:TextField;
		private var video:Video = null;
		private var buffer:BitmapData;
		private var camScreen:Bitmap;
        
        // 3d stuff
        private var stageW:int = 640;
        private var stageH:int = 480;
		private var scene:Scene;
		private var camera:Camera;
		private var view:Viewport;
        
        private var cameraController:MinkoCameraController;
        private var cameraMesh:MinkoCaptureMesh;
        private var controller:MinkoIN2ARController;
		
		// camera size
        public var deviceCamera:flash.media.Camera;
		public var srcWidth:int = 640;
		public var srcHeight:int = 480;
        // uncomment to limit camera texture size to 512x512
        public var clipRect:Rectangle;// = new Rectangle(0, 0, 512, 512);
        
        public var _stat:Stats;
		
		public function ANEMultiDetection()
		{
            stage.scaleMode = StageScaleMode.NO_SCALE;
            stage.align = StageAlign.TOP_LEFT;
            stage.quality = StageQuality.LOW;
            
            //NativeApplication.nativeApplication.systemIdleMode = SystemIdleMode.KEEP_AWAKE;
            
            // save some CPU cicles
            mouseEnabled = false;
            mouseChildren = false;
            
            // its a hack to get stage dimensions
            // probably i used wrong way to detect it :)
			getContext();
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
            iniStats();
            initListeners();
        }
        
        private function getContext(): void
        {
            var stage3D:Stage3D = stage.stage3Ds[0];
            stage3D.addEventListener(Event.CONTEXT3D_CREATE, onContextCreated);
            stage3D.requestContext3D(Context3DRenderMode.AUTO);
        }
        
        private function iniStats():void
        {
            _stat = new Stats();
            _stat.x = srcWidth - 70;
            _stat.y = srcHeight - 100;
            addChild(_stat);
        }
		
		private function initCamera():void
		{
			deviceCamera = flash.media.Camera.getCamera();
			deviceCamera.setMode(srcWidth, srcHeight, 30, false);
            
            buffer = new BitmapData(srcWidth, srcHeight, false, 0x00);
            
            video = new Video(deviceCamera.width, deviceCamera.height);
			video.attachCamera(deviceCamera);
            
            // on android first camera open result in very low camera fps (HTC Sensation)
            // so i close it open again here
            if (Capabilities.manufacturer.toLowerCase().indexOf('android') != -1)
            {
                setTimeout(reopenCamera, 2500);
            }
		}
        
        private function reopenCamera():void 
        {
            removeEventListener(Event.ENTER_FRAME, onEnterFrame);
            
            video.attachCamera(null);
            deviceCamera = null;
            video = null;
            setTimeout(newCam, 1500);
        }
        private function newCam():void
        {
            deviceCamera = flash.media.Camera.getCamera();
			deviceCamera.setMode(srcWidth, srcHeight, 30, false);
            
            video = new Video(deviceCamera.width, deviceCamera.height);
			video.attachCamera(deviceCamera);
            
            if (!hasEventListener(Event.ENTER_FRAME))
            {
                addEventListener(Event.ENTER_FRAME, onEnterFrame);
            }
        }
		
		private function initASFEAT():void
		{
			asfeat = new ASFEATInterface();
			asfeat.allocate(srcWidth, srcHeight, maxPoints, maxReferences);
			asfeat.setupIndexing(14, 8, true);
			asfeat.setMatchThreshold(31);
            
            // here i limit amount of reference to allow per frame.
            // we search for 18 reference, so i tell engine so stop searching
            // as soon as it finds 2 references and switch to tracking it
            // it helps to improve performance
            asfeat.setMaxReferencesPerFrame(maxRefsPerFrame);
			
			// add all our markers
			var n:int = data_files.length;
			for (var i:int = 0; i < n; ++i)
			{
				asfeat.addReference(data_files[i]);
			}
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
                                                srcWidth, srcHeight, 
                                                MinkoCaptureGeometry.FILL_MODE_PRESERVE_ASPECT_RATIO_AND_FILL, clipRect);
            cameraMesh.setupForBitmapData(buffer);
            
            // calculate scale for camera
            var camScale:Number = clipRect ? view.width / clipRect.width : Math.max(stageW / srcWidth, stageH / srcHeight);
            cameraController = new MinkoCameraController(intrinsic, camScale);
            camera.removeAllControllers();
            camera.addController(cameraController);
            
            scene.addChild(camera);
            scene.addChild(cameraMesh);
			
			addChild(view);
		}
        
        private function initObjects():void
		{
            var n:int = data_files.length;
            // controller
            controller = new MinkoIN2ARController(n);
            // just duplicates of logo model
            for (var i:int = 0; i < n; ++i)
            {
                var mod3d:ISceneNode = new In2ArLogo();
                controller.addReference(i, mod3d);
                scene.addChild(mod3d);
            }
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
			text.multiline = true;
			text.autoSize = "left";
			text.selectable = false;
			text.mouseEnabled = false;
            text.text = "camera initialization...";
			addChild(text);
		}
		
		private function initListeners():void
		{
			asfeat.addEventListener(ASFEATDetectionEvent.DETECTED, onModelDetected);
			asfeat.addEventListener(ASFEATDetectionEvent.FAILED, onDetectionFailed);
            if (!hasEventListener(Event.ENTER_FRAME) && null!=deviceCamera)
            {
                addEventListener(Event.ENTER_FRAME, onEnterFrame);
            }
		}
		
		private function onEnterFrame(e:Event = null):void
		{
            //draw video stream to detection buffer & run detection
            deviceCamera.drawToBitmapData(buffer);
            
            asfeat.process(buffer);
            //asfeat.renderPoints(buffer, 0);
            cameraMesh.invalidate();
            controller.lost();
            scene.render(view);
		}
		
		private function onModelDetected(e:ASFEATDetectionEvent):void
		{
			var refList:Vector.<ASFEATReference> = e.detectedReferences;
			var ref:ASFEATReference;
			var n:int = e.detectedReferencesCount;
			var state:String;
			var str:String = "";
			
			for (var i:int = 0; i < n; ++i)
			{
				ref = refList[i];
				state = ref.detectType;
                var objid:int = ref.id;
                
                controller.setTransform( objid, ref.rotationMatrix, ref.translationVector, ref.poseError, false );
				
                if (state == "_track")
                {
				    str += 'found id(' + ref.id + ') \tstate(' + state + ')\n';
                } else 
                {
                    str += 'found id(' + ref.id + ') \tstate(' + state + ') \tmatched(' + ref.matchedPointsCount + ')\n';
                }
			}
			
			text.text = str;
		}
		
		private function onDetectionFailed(e:ASFEATDetectionEvent):void
		{
			text.text = "nothing found";
		}
	
	}

}