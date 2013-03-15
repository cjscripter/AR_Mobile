package arsupport.away3d4 
{
	import away3d.textures.Texture2DBase;
    import away3d.tools.utils.TextureUtils;
    import flash.display.BitmapData;
    import flash.display3D.textures.Texture;
    import flash.display3D.textures.TextureBase;
    import flash.utils.ByteArray;
	
	/**
     * Simplified version of BitmapTexture class
     * @author Eugene Zatepyakin
     */
    public final class Away3D4CameraTexture extends Texture2DBase 
    {
        private var _bitmapData:BitmapData = null;
        private var _bytes:ByteArray = null;
        
        public function Away3D4CameraTexture(bitmapData:BitmapData, bytes:ByteArray = null) 
        {
            super();
			
            this.bitmapData = bitmapData;
            _bytes = bytes;
        }
        
        public function get bitmapData():BitmapData
		{
			return _bitmapData;
		}
        
        public function set bitmapData(value : BitmapData) : void
		{
			if (value == _bitmapData) return;

			if (!TextureUtils.isBitmapDataValid(value))
				throw new Error("Invalid bitmapData: Width and height must be power of 2 and cannot exceed 2048");

			invalidateContent();
			setSize(value.width, value.height);

			_bitmapData = value;
		}
        
        public function setupTextureSize(width:int, height:int):void
        {
            invalidateContent();
			setSize(width, height);
        }

		override protected function uploadContent(texture:TextureBase):void
		{
            if (_bytes)
            {
                Texture(texture).uploadFromByteArray(_bytes, 0, 0);
            }
            else {
                Texture(texture).uploadFromBitmapData(_bitmapData);
            }
		}
        
        override public function invalidateContent():void 
        {
            _dirty[0] = true;
        }
        
    }

}