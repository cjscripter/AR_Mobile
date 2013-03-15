package arsupport.away3d4 
{	
	import away3d.containers.ObjectContainer3D;
	import flash.events.Event;
	import flash.geom.Matrix3D;
	/**
	 * ...
	 * @author Eugene Zatepyakin
	 */
	public class ARAway3D4Container extends ObjectContainer3D
	{
		public var maxLostCount:int = 5;
		public var lostCount:int = 0;
		public var detected:Boolean = false;
		
		protected const transformData:Vector.<Number> = new Vector.<Number>(16, true);
		public var newMatrix:Matrix3D = new Matrix3D();
		public var nextMatrix:Matrix3D = new Matrix3D();
		
		public function ARAway3D4Container() 
		{
			super();
			
			visible = false;
		}
		
		public function setTransform(R:Vector.<Number>, t:Vector.<Number>, matrixError:Number, mirror:Boolean = false):void
		{
            if (++lostCount < 0) return;
            
			get3DMatrixLH( transformData, R, t, mirror );
			newMatrix.rawData = transformData;
			nextMatrix.interpolateTo(newMatrix, 0.85);
			
			this.transform = nextMatrix;
			
			
			visible = true;
			detected = true;
			lostCount = 0;
		}
		
		public function lost():void
		{
			if(visible && ++lostCount == maxLostCount)
			{
				hideObject();
			}
		}
		
		public function hideObject(e:Event = null):void
		{
			visible = false;
			detected = false;
            lostCount = -maxLostCount;
			nextMatrix.identity();
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