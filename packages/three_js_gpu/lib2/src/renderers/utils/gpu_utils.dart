import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_gpu/common/render_context.dart';
import '../gpu_backend.dart';
import 'package:three_js_math/three_js_math.dart';

class WebGPUUtils {
  WebGPUBackend backend;

	WebGPUUtils(this.backend );

	/// Returns the depth/stencil GPU format for the given render context.
	String getCurrentDepthStencilFormat(RenderContext renderContext ) {
		String? format;

		if ( renderContext.depth ) {
			if ( renderContext.depthTexture != null ) {
				format = this.getTextureFormatGPU( renderContext.depthTexture );
			} 
      else if ( renderContext.stencil ) {
				if ( this.backend.renderer.reversedDepthBuffer == true ) {
					format = GPUTextureFormat.Depth32FloatStencil8;
				} 
        else {
					format = GPUTextureFormat.Depth24PlusStencil8;
				}
			} 
      else {
				if ( this.backend.renderer.reversedDepthBuffer == true ) {
					format = GPUTextureFormat.Depth32Float;
				} 
        else {
					format = GPUTextureFormat.Depth24Plus;
				}
			}
		}

		return format!;
	}

	String getTextureFormatGPU(Texture texture ) {
		return backend.get( texture ).format;
	}

	/// Returns an object that defines the multi-sampling state of the given texture.
	Map<String,dynamic> getTextureSampleData(Texture texture ) {
		int? samples;

		if ( texture is FramebufferTexture ) {
			samples = 1;
		} else if ( texture.isDepthTexture && texture.renderTarget == null) {
			final renderer = backend.renderer;
			final renderTarget = renderer?.getRenderTarget();

			samples = renderTarget != null? renderTarget.samples : renderer?.samples;
		} 
    else if ( texture.renderTarget != null) {
			samples = texture.renderTarget?.samples;
		}

		samples = samples ?? 1;

		final isMSAA = samples > 1 && texture.renderTarget != null && ( texture is DepthTexture != true && texture is FramebufferTexture != true );
		final primarySamples = isMSAA ? 1 : samples;

		return { 'samples': samples, 'primarySamples': primarySamples, 'isMSAA': isMSAA };
	}

	/// Returns the default color attachment's GPU format of the current render context.
	String? getCurrentColorFormat(RenderContext renderContext ) {
		String? format;

		if ( renderContext.textures != null ) {
			format = getTextureFormatGPU( renderContext.textures[ 0 ] );
		} else {
			format = getPreferredCanvasFormat(); // default context format
		}

		return format;
	}

	/// Returns the output color space of the current render context.
	String getCurrentColorSpace(RenderContext renderContext ) {
		if ( renderContext.textures != null ) {
			return renderContext.textures?[ 0 ].colorSpace ?? '';
		}

		return backend.renderer?.outputColorSpace ?? '';
	}

	/// Returns GPU primitive topology for the given object and material.
	String? getPrimitiveTopology( Object3D object, Material material ) {
		if ( object is Points ) return GPUPrimitiveTopology.PointList;
		else if ( object is LineSegments || ( object is Mesh && material.wireframe == true ) ) return GPUPrimitiveTopology.LineList;
		else if ( object is Line ) return GPUPrimitiveTopology.LineStrip;
		else if ( object is Mesh ) return GPUPrimitiveTopology.TriangleList;

    return null;
	}

	/// Returns a modified sample count from the given sample count value.
	///
	/// That is required since WebGPU only supports either 1 or 4.
	int getSampleCount(int sampleCount ) {
		return sampleCount >= 4 ? 4 : 1;
	}

	/// Returns the sample count of the given render context.
	int getSampleCountRenderContext(RenderContext renderContext ) {
		if ( renderContext.textures != null ) {
			return getSampleCount( renderContext.sampleCount );
		}

		return getSampleCount( backend.renderer.samples );
	}

	/// Returns the preferred canvas format.
	///
	/// There is a separate method for this so it's possible to
	/// honor edge cases for specific devices.
	String getPreferredCanvasFormat() {
		final outputType = backend.parameters['outputType'];

		if ( outputType == null ) {
			return navigator.gpu.getPreferredCanvasFormat();
		} else if ( outputType == UnsignedByteType ) {
			return GPUTextureFormat.BGRA8Unorm;
		} else if ( outputType == HalfFloatType ) {
			return GPUTextureFormat.RGBA16Float;
		} else {
			throw( 'Unsupported outputType' );
		}
	}
}
