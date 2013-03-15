package arsupport.demo.minko 
{
    import aerys.minko.render.effect.Effect;
    import aerys.minko.render.resource.texture.TextureResource;
    import aerys.minko.scene.node.Group;
    import aerys.minko.scene.node.mesh.geometry.Geometry;
    import aerys.minko.scene.node.mesh.Mesh;
    import aerys.minko.type.loader.TextureLoader;
    import aerys.minko.type.math.Vector4;
    import aerys.minko.type.stream.format.VertexFormat;
    import aerys.minko.type.stream.IndexStream;
    import aerys.minko.type.stream.IVertexStream;
    import aerys.minko.type.stream.VertexStream;
    import arsupport.demo.OBJParser;
    import arsupport.minko.MinkoCaptureTexture;
    import flash.display.BitmapData;
    import flash.geom.Vector3D;
    import flash.utils.ByteArray;
	
	/**
     * ...
     * @author Eugene Zatepyakin
     */
    public final class In2ArLogo extends Group 
    {
        [Embed(source="../../../../assets/in2ar_logo/paint_noise.png")] private static var Charmap:Class;
		[Embed(source = "../../../../assets/in2ar_logo/logo_bouquet.obj", mimeType = "application/octet-stream")] private static var Charmesh:Class;
        
        protected var _lightTexture:MinkoCaptureTexture;
        protected var _model:Mesh;
        
        public function In2ArLogo() 
        {
            var geometry:Geometry = createGeometry();
            var texture:TextureResource = TextureLoader.loadClass(Charmap);
            
            geometry.computeNormals(0, true);
            
            _model = new Mesh( geometry, { 
                                diffuseMap:texture
                             } );
            
            _model.transform.prependScale( -1, 1, 1 );
            _model.transform.prependRotation( 90 * (Math.PI / 180), Vector4.X_AXIS );
            
            addChild(_model);
        }
        
        public function setupLightMap(bmp:BitmapData):void
        {
            _lightTexture = new MinkoCaptureTexture(bmp.width);
            _lightTexture.setContentFromBitmapData(bmp, false);
            
            _model.properties.setProperty("lightMap", _lightTexture);
            
            _model.effect = new Effect(new LightMapShader);
        }
        public function updateLightMap():void
        {
            _lightTexture.update = true;
        }
        
        public var surfNormal:Vector3D = new Vector3D();
        protected var _surfNormal4:Vector4 = new Vector4();
        public function getSurfaceNormal():Vector3D
        {
            //var dt:Vector.<Number> = this.transform.matrix3D.rawData;

            //surfNormal.x = dt[2];
            //surfNormal.y = dt[6];
            //surfNormal.z = dt[10];
			
            _surfNormal4.x = 0;
            _surfNormal4.y = 0;
            _surfNormal4.z = -1;
            _surfNormal4 = this.transform.deltaTransformVector(_surfNormal4);

            _surfNormal4.normalize();
            
            surfNormal.x = _surfNormal4.x;
            surfNormal.y = _surfNormal4.y;
            surfNormal.z = _surfNormal4.z;

            return surfNormal;
        }
        
        protected function createGeometry():Geometry
        {
            var parser:OBJParser = new OBJParser(13);
            var obj_ba:ByteArray = ByteArray(new Charmesh);
			var str:String = obj_ba.toString();
            parser.parse(str);
			obj_ba.clear();
            
            // construct format
            var verts:Vector.<Number> = parser.vertices;
            var uvs:Vector.<Number> = parser.uvs;
            var numV:int = verts.length / 3;
            var xyz_uv:Vector.<Number> = new Vector.<Number>();
            
            var j:int = 0;
            for (var i:int = 0; i < numV; ++i)
            {
                xyz_uv.push(verts[j], verts[(j + 1) | 0], verts[(j + 2) | 0], uvs[i << 1], uvs[((i << 1) + 1) | 0]);
                j += 3;
            }
            
            var vstream:VertexStream = new VertexStream(
				0,
				VertexFormat.XYZ_UV,
				xyz_uv
			);
			
			return new Geometry(
				new <IVertexStream>[vstream],
				new IndexStream(0, parser.indices)
			);
        }
        
    }

}