package arsupport.minko 
{
    import aerys.minko.render.RenderTarget;
    import aerys.minko.render.shader.SFloat;
	import aerys.minko.render.shader.Shader;
    import aerys.minko.render.shader.ShaderSettings;
    import aerys.minko.type.enum.Blending;
    import aerys.minko.type.enum.DepthTest;
    import aerys.minko.type.enum.SamplerFiltering;
    import aerys.minko.type.enum.SamplerMipMapping;
    import aerys.minko.type.enum.SamplerWrapping;
	
	/**
     * @author Eugene Zatepyakin
     */
    public final class MinkoCaptureShader extends Shader 
    { 
        public function MinkoCaptureShader(target		: RenderTarget	= null,
									priority	: Number		= 0.)
		{
			super(target, priority);
		}
        
        override protected function initializeSettings(settings:ShaderSettings):void
		{
            super.initializeSettings(settings);
            
			settings.depthWriteEnabled = false;
            settings.depthTest = DepthTest.ALWAYS;
            settings.enabled = true;
		}
        
        override protected function getVertexPosition():SFloat
		{
			return vertexXYZ;
		}

		override protected function getPixelColor():SFloat
		{
			var diffuseMap:SFloat = meshBindings.getTextureParameter(
					'diffuseMap',
					meshBindings.getConstant('diffuseFiltering', SamplerFiltering.LINEAR),
					meshBindings.getConstant('diffuseMipMapping', SamplerMipMapping.DISABLE),
					meshBindings.getConstant('diffuseWrapping', SamplerWrapping.CLAMP)
				);
				
			return sampleTexture(diffuseMap, interpolate(vertexUV.xy));
		}
        
    }

}