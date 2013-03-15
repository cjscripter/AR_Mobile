package arsupport.demo.away3d4 
{
	import arsupport.away3d4.ARAway3D4Container;
	import away3d.entities.Mesh;
	import away3d.events.AssetEvent;
	import away3d.library.AssetLibrary;
	import away3d.library.assets.AssetType;
	import away3d.loaders.misc.AssetLoaderContext;
	import away3d.loaders.parsers.OBJParser;
    import away3d.materials.TextureMaterial;
    import away3d.textures.BitmapTexture;
	import flash.geom.Vector3D;
	import flash.utils.ByteArray;
	
	/**
	 * ...
	 * @author Eugene Zatepyakin
	 */
	public final class In2ArLogo extends ARAway3D4Container 
	{
		[Embed(source="../../../../assets/in2ar_logo/paint_noise.png")] private static var Charmap:Class;
		[Embed(source="../../../../assets/in2ar_logo/logo_bouquet.obj", mimeType="application/octet-stream")] private static var Charmesh:Class;
		
		private var _mesh:Mesh;
        private var _texture:BitmapTexture;
		private var _material:TextureMaterial;
		
		public function In2ArLogo() 
		{
			super();			
			initObjects();
		}
		
		private function initObjects():void
		{			
            _texture = new BitmapTexture(new Charmap().bitmapData);
			_material = new TextureMaterial(_texture);
			
			var _parserobj:OBJParser = new OBJParser(15);
			AssetLibrary.enableParser(OBJParser);			
			
			AssetLibrary.addEventListener(AssetEvent.ASSET_COMPLETE, onAssetRetrieved);
			AssetLibrary.loadData(ByteArray(new Charmesh), new AssetLoaderContext(false), null, _parserobj);
		}
		
		private function onAssetRetrieved(event : AssetEvent) : void
		{
			if (event.asset.assetType == AssetType.MESH) 
			{
				_mesh = Mesh(event.asset);
				_mesh.transform.appendScale( -1, -1, 1 );
				_mesh.transform.appendRotation( -90, Vector3D.X_AXIS );
                _mesh.transform.appendRotation( 180, Vector3D.Z_AXIS );

				addChild(_mesh);

				_mesh.material = _material;
			}
		}
	}

}