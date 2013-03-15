package arsupport.minko 
{
    import aerys.minko.render.effect.Effect;
    import aerys.minko.scene.node.mesh.geometry.Geometry;
    import aerys.minko.scene.node.mesh.Mesh;
    import flash.display.BitmapData;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import flash.utils.ByteArray;
	
	/**
     * ...
     * @author Eugene Zatepyakin
     */
    public final class MinkoCaptureMesh extends Mesh 
    {        
        protected var _viewWidth:int;
        protected var _viewHeight:int;
        protected var _imageWidth:int;
        protected var _imageHeight:int;
        protected var _textureWidth:int;
        protected var _textureHeight:int;
        protected var _imageRect:Rectangle;
        
        protected var _texture:MinkoCaptureTexture;
        protected var _textureBmp:BitmapData;
        
        public function MinkoCaptureMesh(
                                        viewWidth:int, viewHeight:int, 
                                        streamWidth:int, streamHeight:int, 
                                        fillMode:uint = MinkoCaptureGeometry.FILL_MODE_PRESERVE_ASPECT_RATIO_AND_FILL,
                                        powerOfTwoRect:Rectangle = null) 
        {           
            _viewWidth = viewWidth;
            _viewHeight = viewHeight;
            _imageWidth = streamWidth;
            _imageHeight = streamHeight;
            
            _textureWidth = nextPowerOfTwo(streamWidth);
            _textureHeight = nextPowerOfTwo(streamHeight);
            
            _imageRect = new Rectangle(0, 0, _imageWidth, _imageHeight);
            
            if (null != powerOfTwoRect)
            {
                _textureWidth = Math.min(powerOfTwoRect.width, _textureWidth);
                _textureHeight = Math.min(powerOfTwoRect.height, _textureHeight);
                if (_imageWidth > _textureWidth)
                {
                    _imageRect.x = (_imageWidth - _textureWidth) * 0.5;
                    _imageWidth = _textureWidth;
                }
                if (_imageHeight > _textureHeight)
                {
                    _imageRect.y = (_imageHeight - _textureHeight) * 0.5;
                    _imageHeight = _textureHeight;
                }
                _imageRect.width = _imageWidth;
                _imageRect.height = _imageHeight;
            }
            
            _textureCopyPoint = new Point((_textureWidth - _imageWidth) * 0.5, (_textureHeight - _imageHeight) * 0.5);
            
            var geometry:Geometry = new MinkoCaptureGeometry(viewWidth, viewHeight, _textureWidth, _textureHeight, _imageWidth, _imageHeight, fillMode);
            
            _texture = new MinkoCaptureTexture(_textureWidth, _textureHeight);
            
            var properties:Object = {diffuseMap:_texture};
            var effect:Effect = new Effect(new MinkoCaptureShader);
            
            super(geometry, properties, effect);
        }
        
        protected var _buffer:BitmapData = null;
        protected var _textureCopyPoint:Point;
        public function setupForBitmapData(bmp:BitmapData):void
        {
            _buffer = bmp;
            _textureBmp = new BitmapData(_textureWidth, _textureHeight, true, 0x0);
            _texture.setContentFromBitmapData(_textureBmp, false);
        }
        public function setupForByteArray(ba:ByteArray):void
        {
            _texture.setContentFromBytes(ba);
        }
        
        public function invalidate():void
        {
            if (_buffer)
            {
                _textureBmp.copyPixels(_buffer, _imageRect, _textureCopyPoint);
            }
            _texture.update = true;
        }
        
        public function get textureWidth():Number
        {
            return _textureWidth;
        }
        public function get textureHeight():Number
        {
            return _textureHeight;
        }
        
        public function dispose():void
        {
            geometry.dispose();
            _texture.dispose();
            if (_buffer) _buffer.dispose();
        }
        
        public static function nextPowerOfTwo(v:uint):uint
        {
            v--;
            v |= v >> 1;
            v |= v >> 2;
            v |= v >> 4;
            v |= v >> 8;
            v |= v >> 16;
            v++;
            return v;
        }
        
    }

}