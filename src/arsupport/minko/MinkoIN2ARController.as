package arsupport.minko 
{
    import aerys.minko.scene.node.Group;
    import aerys.minko.scene.node.ISceneNode;
    import aerys.minko.scene.node.mesh.Mesh;
    import aerys.minko.type.math.Matrix4x4;
	
	/**
     * ...
     * @author Eugene Zatepyakin
     */
    public final class MinkoIN2ARController
    {
        public static var MAX_LOST_COUNT:int = 5;
        
        protected var _objects:Vector.<ReferenceData>;
        protected var _count:int;
		
		protected const _transformData:Vector.<Number> = new Vector.<Number>(16, true);
		protected const _nextMatrix:Matrix4x4 = new Matrix4x4();
        
        public function MinkoIN2ARController(numReferences:uint) 
        {
            _objects = new Vector.<ReferenceData>(numReferences, true);
            for (var i:int = 0; i < numReferences; ++i)
            {
                _objects[i] = new ReferenceData();
                _objects[i].id = -1;
                _objects[i].detected = false;
            }
            
            _count = 0;
        }
        
        public function addReference(id:int, object:ISceneNode):void
        {
            var info:ReferenceData = _objects[id];
            info.id = id;
            info.lostCount = -MAX_LOST_COUNT;
            info.detected = false;
            info.object = object;
            
            toggleVisibility(object, false);
            ++_count;
        }
        
        public function removeReference(id:int):ISceneNode
        {
            var info:ReferenceData = _objects[id];
            var obj:ISceneNode = null;
            if (info.id > -1)
            {
                info.id = -1;
                info.detected = false;
                obj = info.object;
                info.object = null;
                --_count;
            }
            return obj;
        }
        
        public function setTransform(id:int, R:Vector.<Number>, t:Vector.<Number>, matrixError:Number, mirror:Boolean = false):void
		{
            var info:ReferenceData = _objects[id];
            
            if (++info.lostCount < 0) return;
            
			get3DMatrixLH( _transformData, R, t, mirror );
            _nextMatrix.setRawData(_transformData);
            
            var trg:ISceneNode = info.object;
            if (!info.detected)
            {
                trg.transform.setTranslation(_nextMatrix.translationX, _nextMatrix.translationY, _nextMatrix.translationZ);
                toggleVisibility(trg, true);
            }
            
            trg.transform.interpolateTo(_nextMatrix, 0.85);
			
			info.detected = true;
			info.lostCount = 0;
		}
		
		public function lost():void
		{
            var n:int = _objects.length;
            for (var i:int = 0; i < n; ++i)
            {
                var info:ReferenceData = _objects[i];
                if(info.detected && ++info.lostCount == MAX_LOST_COUNT)
                {
                    info.detected = false;
                    info.lostCount = -MAX_LOST_COUNT;
                    toggleVisibility(info.object, false);
                }
            }
		}
        
        public function toggleVisibility(node:ISceneNode, value:Boolean):void
        {
            var meshes:Vector.<ISceneNode> = node is Group ? Group(node).getDescendantsByType(Mesh) : new <ISceneNode>[node];
            for each (var mesh:ISceneNode in meshes)
            {   
                Mesh(mesh).visible = value;
            }
        }
		
		public function get3DMatrixLH(data:Vector.<Number>, R:Vector.<Number>, t:Vector.<Number>, mirror:Boolean = false):void
		{
			if (mirror == false) 
			{
				data[0] = R[0];
				data[1] = -R[3];
				data[2] = R[6];
				data[3] = 0.0;
				data[4] = R[1];
				data[5] = -R[4];
				data[6] = R[7];
				data[7] = 0.0;
				data[8] = -R[2];
				data[9] = R[5];
				data[10] = -R[8];
				data[11] = 0.0;
				data[12] = t[0];
				data[13] = -t[1];
				data[14] = t[2];
				data[15] = 1.0;
			} else {
				data[0] = -R[0];
				data[1] = -R[3];
				data[2] = R[6];
				data[3] = 0.0;
				data[4] = R[1];
				data[5] = R[4];
				data[6] = -R[7];
				data[7] = 0.0;
				data[8] = R[2];
				data[9] = R[5];
				data[10] = -R[8];
				data[11] = 0.0;
				data[12] = -t[0];
				data[13] = -t[1];
				data[14] = t[2];
				data[15] = 1.0;
			}
		}
        
    }
}
import aerys.minko.scene.node.ISceneNode;

internal final class ReferenceData
{
    public var id:int;
    public var lostCount:int;
    public var detected:Boolean;
    public var object:ISceneNode;
}