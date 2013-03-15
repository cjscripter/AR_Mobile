package arsupport.minko 
{
    import aerys.minko.render.Viewport;
	import aerys.minko.scene.controller.AbstractController;
    import aerys.minko.scene.data.CameraDataProvider;
    import aerys.minko.scene.node.Camera;
    import aerys.minko.scene.node.ISceneNode;
    import aerys.minko.scene.node.Scene;
    import aerys.minko.type.data.DataBindings;
    import aerys.minko.type.data.IDataProvider;
    import aerys.minko.type.math.Matrix4x4;
    import aerys.minko.type.math.Vector4;
    import ru.inspirit.asfeat.calibration.IntrinsicParameters;
	
	/**
     * ...
     * @author Eugene Zatepyakin
     */
    public final class MinkoCameraController extends AbstractController 
    {
        private var _camera:Camera = null;
        
        private var _intrinsic:IntrinsicParameters = null;        
        private var _arScale:Number;
        
        public function MinkoCameraController(ip:IntrinsicParameters, arScale:Number = 1.0) 
        {
            super(Camera);
            
            _intrinsic = ip;
            _arScale = arScale;
			
			targetAdded.add(targetAddedHandler);
			targetRemoved.add(targetRemovedHandler);
        }
        
        private function targetAddedHandler(controller	: MinkoCameraController,
											target		: Camera) : void
		{
			if (_camera != null)
				throw new Error();

			_camera = target;
			_camera.addedToScene.add(addedToSceneHandler);
			_camera.removedFromScene.add(removedFromSceneHandler);
			_camera.worldToLocal.changed.add(worldToLocalChangedHandler);
		}

		private function targetRemovedHandler(controller	: MinkoCameraController,
											  target		: Camera) : void
		{
			_camera.addedToScene.remove(addedToSceneHandler);
			_camera.removedFromScene.remove(removedFromSceneHandler);
			_camera.worldToLocal.changed.remove(worldToLocalChangedHandler);
			_camera = null;
		}

		private function addedToSceneHandler(camera : Camera, scene : Scene) : void
		{
			var sceneBindings : DataBindings = scene.bindings;

			sceneBindings.addProvider(camera.cameraData);
			sceneBindings.addCallback('viewportWidth', viewportSizeChanged);
			sceneBindings.addCallback('viewportHeight', viewportSizeChanged);
			camera.cameraData.changed.add(cameraPropertyChangedHandler);

			updateProjection();
		}

		private function removedFromSceneHandler(camera : Camera, scene : Scene) : void
		{
			var sceneBindings : DataBindings = scene.bindings;

			sceneBindings.removeProvider(camera.cameraData);
			sceneBindings.removeCallback('viewportWidth', viewportSizeChanged);
			sceneBindings.removeCallback('viewportHeight', viewportSizeChanged);
			camera.cameraData.changed.remove(cameraPropertyChangedHandler);
		}

		private function worldToLocalChangedHandler(worldToLocal : Matrix4x4, propertyName : String) : void
		{
			var cameraData	: CameraDataProvider	= _camera.cameraData;

			cameraData.worldToScreen.lock()
				.copyFrom(_camera.worldToLocal)
				.append(cameraData.projection)
				.unlock();

			cameraData.screenToWorld.lock()
				.copyFrom(cameraData.screenToView)
				.append(_camera.localToWorld)
				.unlock();
		}

		private function viewportSizeChanged(bindings : DataBindings, key : String, newValue : Object) : void
		{
			updateProjection();
		}

		private function cameraPropertyChangedHandler(provider : IDataProvider, property : String) : void
		{
            // we dont move camera and updateProjection is public
            // if user decide to change intrinsic parameters
			//updateProjection();
		}
		
        public const projection_raw:Vector.<Number> = new Vector.<Number>(16, true);
		public function updateProjection() : void
		{
			var cameraData		: CameraDataProvider	= _camera.cameraData;
			var screenToView	: Matrix4x4				= cameraData.screenToView;
			var sceneBindings	: DataBindings			= Scene(_camera.root).bindings;
			var viewportWidth	: Number				= sceneBindings.getProperty('viewportWidth');
			var viewportHeight	: Number				= sceneBindings.getProperty('viewportHeight');
            
            var cx		: Number 	= _intrinsic.cx;
			var cy		: Number 	= _intrinsic.cy;
			var w		: Number 	= viewportWidth;
			var h		: Number 	= viewportHeight;
			var fx		: Number 	= _intrinsic.fx;
			var fy		: Number 	= _intrinsic.fy;
			var aspect	: Number 	= w / h;
			
			var _zNear:Number = fx / 32;
			var _zFar:Number = fx * 32;
			var _fov:Number = 2.0 * Math.atan((h - 1) / (2 * fy));
			
			var pSizeY	: Number	= _zNear * Math.tan(_fov * .5);
			var pSizeX	: Number 	= pSizeY * aspect;
            
            cameraData.fieldOfView = _fov;
            cameraData.zFar = _zFar;
            cameraData.zNear = _zNear;
            
            var raw:Vector.<Number> = projection_raw;
            
            raw[uint(0)] = _zNear/pSizeX * _arScale;
			raw[uint(5)] = _zNear/pSizeY * _arScale;
			raw[uint(10)] = _zFar/(_zFar-_zNear);
			raw[uint(11)] = 1.;
			raw[uint(14)] = -_zNear*raw[uint(10)];
            
            cameraData.projection.setRawData(raw);
            
            screenToView.lock()
				.copyFrom(cameraData.projection)
				.invert()
				.unlock();

			cameraData.screenToWorld.lock()
				.copyFrom(cameraData.screenToView)
				.append(_camera.localToWorld)
				.unlock();

			cameraData.worldToScreen.lock()
				.copyFrom(_camera.worldToLocal)
				.append(cameraData.projection)
				.unlock();
		}
        
    }

}