package
{
    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.display.Graphics;
    import flash.display.Shape;
    import flash.display.Sprite;
    import flash.display.StageAlign;
    import flash.display.StageQuality;
    import flash.display.StageScaleMode;
    import flash.events.Event;
    import flash.geom.Matrix;
    import flash.geom.Rectangle;
    import flash.media.Camera;
    import flash.media.Video;
    import flash.text.TextField;
    import flash.text.TextFormat;
    import flash.utils.ByteArray;

    import ru.inspirit.asfeat.ane.ASFEATInterface;
    import ru.inspirit.asfeat.detect.ASFEATDetectType;
    import ru.inspirit.asfeat.detect.ASFEATReference;
    import ru.inspirit.asfeat.event.ASFEATDetectionEvent;

    /**
     * ...
     * @author Eugene Zatepyakin
     */
    [SWF(frameRate='30',backgroundColor='0xFFFFFF')]
    public final class ANEConfidenceDemo extends Sprite
    {
        // tracking data file
        [Embed(source="../assets/def_data.ass", mimeType="application/octet-stream")]
        public static const DefinitionaData:Class;

        [Embed(source = '../assets/def_marker.jpg')]
        private static const ref_ass:Class;

        public var refImg:BitmapData = Bitmap(new ref_ass).bitmapData;

        //asfeat variables
        public var asfeat:ASFEATInterface;
        public var maxPoints:int = 300; // max points to allow to detect
        public var maxReferences:int = 1; // max objects will be used
        public var maxTrackIterations:int = 5; // track iterations

        // different visual objects
        public static var text:TextField;
        public var camBmp:Bitmap;
        public var shape:Shape;
        public var gfx:Graphics;

        // Capture stuff
        public var streamW:int = 640;
        public var streamH:int = 480;
        public var streamFPS:int = 30;
        public var deviceCam:flash.media.Camera;

        public function ANEConfidenceDemo()
        {
            stage.scaleMode = StageScaleMode.NO_SCALE;
            stage.align = StageAlign.TOP_LEFT;
            stage.quality = StageQuality.LOW;

            // save some CPU cicles
            mouseEnabled = false;
            mouseChildren = false;

            initASFEAT();
            initNativeCamera();
            initListeners();

            camBmp = new Bitmap(buffer);
            shape = new Shape();
            gfx = shape.graphics;

            addChild(camBmp);
            addChild(shape);

            initText();
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
            asfeat.setMaxReferencesPerFrame(1);
            asfeat.setMaxTrackIterations(maxTrackIterations);

            var ref_id:int = asfeat.addReference(ByteArray(new DefinitionaData));

            // add marker image to test regions/buttons overlay
            var samp:BitmapData = new BitmapData(refImg.width/3,refImg.height/3,false,0x0);
            samp.draw(refImg,new Matrix(1/3,0,0,1/3),null,null,null,true);
            asfeat.initReferenceSample(ref_id, samp);
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
                //asfeat.renderPoints(buffer, 0);
            }
        }

        private function onModelDetected(e:ASFEATDetectionEvent):void
        {
            var refList:Vector.<ASFEATReference> = e.detectedReferences;
            var ref:ASFEATReference;
            var n:int = e.detectedReferencesCount;
            var state:String;

            gfx.clear();
            gfx.lineStyle(2,0x00FF00);

            loop: for (var i:int = 0; i < n; ++i)
            {
                ref = refList[i];
                state = ref.detectType;

                text.text = state;
                text.appendText( ' @ ' + ref.id );

                //
                gfx.moveTo(ref.TLx,ref.TLy);
                gfx.lineTo(ref.TRx,ref.TRy);
                gfx.lineTo(ref.BRx,ref.BRy);
                gfx.lineTo(ref.BLx,ref.BLy);
                gfx.lineTo(ref.TLx,ref.TLy);
                //
                // here update internal occlusion data
                // dont forget we downscaled sample by 3!
                if(state == ASFEATDetectType.TRACKED)
                {
                    asfeat.updateReferenceSample(ref.id);
                    var rect:Rectangle = new Rectangle(150/3,30/3,200/3,100/3);
                    // result is sqared to avoid using sqrt
                    // the possible range from 0 to 1
                    // the higher value means less occlusion
                    var conf_sq:Number = asfeat.getReferenceRectConfidence(ref.id,rect);
                    if(conf_sq < 0.7*0.7) // remember the result is squared
                    {
                        text.appendText( ' (button pressed) ' );
                    } else {
                        text.appendText( ' (button not pressed) ' );
                    }
                }
                //

                if(state == '_detect')
                    text.appendText( ' :: matched: ' + ref.matchedPointsCount );
            }
        }

        private function onDetectionFailed(e:ASFEATDetectionEvent):void
        {
            text.text = "nothing found";
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
