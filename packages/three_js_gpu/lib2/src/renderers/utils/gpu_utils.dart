import 'package:web/web.dart';
import 'package:gpux/gpux.dart'; 
import 'package:three_js_core/three_js_core.dart' as core;
import 'package:three_js_math/three_js_math.dart' as math;

// Module-scoped list to mimic JavaScript static performance optimizations
final List<dynamic> _commandList = [null];

/// A WebGPU backend utility module with common helpers.
class WebGPUUtils {
  /// A reference to the WebGPU backend instance context.
  final dynamic backend;

  /// Constructs a new utility object.
  WebGPUUtils(this.backend);

  /// Returns the depth/stencil GPU format for the given render context.
  GpuTextureFormat? getCurrentDepthStencilFormat(dynamic renderContext) {
    GpuTextureFormat? format;
    
    if (renderContext.depth == true) {
      if (renderContext.depthTexture != null) {
        format = this.getTextureFormatGPU(renderContext.depthTexture);
      } else if (renderContext.stencil == true) {
        if (this.backend.renderer.reversedDepthBuffer == true) {
          format = GpuTextureFormat.depth32FloatStencil8;
        } else {
          format = GpuTextureFormat.depth24PlusStencil8;
        }
      } else {
        if (this.backend.renderer.reversedDepthBuffer == true) {
          format = GpuTextureFormat.depth32Float;
        } else {
          format = GpuTextureFormat.depth24Plus;
        }
      }
    }
    
    return format;
  }

  /// Returns the GPU format for the given texture.
  GpuTextureFormat getTextureFormatGPU(core.Texture texture) {
    // Enforcing map directive bracket syntax rules instead of backend.get()
    return this.backend[texture]['format'];
  }

  /// Returns an object that defines the multi-sampling state of the given texture.
  Map<String, dynamic> getTextureSampleData(core.Texture texture) {
    int? samples;

    if (texture is core.FramebufferTexture) {
      samples = 1;
    } else if (texture.isDepthTexture == true && texture.renderTarget == null) {
      final dynamic renderer = this.backend.renderer;
      final dynamic renderTarget = renderer.getRenderTarget();
      samples = renderTarget != null ? renderTarget.samples : renderer.currentSamples;
    } else if (texture.renderTarget != null) {
      samples = texture.renderTarget?.samples;
    }

    // Default assignment evaluation
    final int resolvedSamples = samples ?? 1;
    
    final bool isMSAA = resolvedSamples > 1 && 
        texture.renderTarget != null && 
        (texture.isDepthTexture != true && texture is! core.FramebufferTexture);
        
    final int primarySamples = isMSAA ? 1 : resolvedSamples;

    return {
      'samples': resolvedSamples,
      'primarySamples': primarySamples,
      'isMSAA': isMSAA
    };
  }

  /// Returns the default color attachment's GPU format of the current render context.
  GpuTextureFormat getCurrentColorFormat(dynamic renderContext) {
    if (renderContext.textures != null) {
      return this.getTextureFormatGPU(renderContext.textures[0]);
    }
    return this.getPreferredCanvasFormat();
  }

  /// Returns the GPU formats of all color attachments of the current render context.
  List<GpuTextureFormat> getCurrentColorFormats(dynamic renderContext) {
    if (renderContext.textures != null) {
      final List<dynamic> texturesList = renderContext.textures;
      // Remap JavaScript map loops over array objects cleanly to standard Dart lists
      return texturesList.map((t) => this.getTextureFormatGPU(t as core.Texture)).toList();
    }
    
    return [this.getPreferredCanvasFormat()];
  }

  /// Returns the output color space of the current render context.
  dynamic getCurrentColorSpace(dynamic renderContext) {
    if (renderContext.textures != null) {
      return renderContext.textures[0].colorSpace;
    }
    return this.backend.renderer.outputColorSpace;
  }

  /// Returns GPU primitive topology for the given object and material.
  GpuPrimitiveTopology? getPrimitiveTopology(core.Object3D object, core.Material material) {
    if (object is core.Points) {
      return GpuPrimitiveTopology.pointList;
    } else if (object is core.LineSegments || (object is core.Mesh && material.wireframe == true)) {
      return GpuPrimitiveTopology.lineList;
    } else if (object is core.Line) {
      return GpuPrimitiveTopology.lineStrip;
    } else if (object is core.Mesh) {
      return GpuPrimitiveTopology.triangleList;
    }
    return null;
  }

  /// Returns a modified sample count from the given sample count value.
  /// WebGPU only supports either 1 or 4.
  int getSampleCount(int sampleCount) {
    return sampleCount >= 4 ? 4 : 1;
  }

  /// Returns the sample count of the given render context.
  int getSampleCountRenderContext(dynamic renderContext) {
    if (renderContext.textures != null) {
      return this.getSampleCount(renderContext.sampleCount ?? 1);
    }
    return this.getSampleCount(this.backend.renderer.currentSamples ?? 1);
  }

  /// Returns the preferred canvas texture layout format.
  GpuTextureFormat getPreferredCanvasFormat() {
    final Map<String, dynamic> parameters = this.backend.parameters;
    final dynamic bufferType = parameters['outputType'];

    if (bufferType == null) {
      try {
        // Safe runtime web extraction check path mapping
        return window.navigator.gpu.getPreferredCanvasFormat();
      } catch (_) {
        // Default standard safe color format mapping fallback outside pure web targets
        return GpuTextureFormat.bgra8Unorm;
      }
    } else if (bufferType == math.UnsignedByteType) {
      return GpuTextureFormat.bgra8Unorm;
    } else if (bufferType == math.HalfFloatType) {
      return GpuTextureFormat.rgba16Float;
    } else {
      throw Exception('THREE.WebGPUUtils: Unsupported output buffer type.');
    }
  }
}

/// Submits a single GPU command to the device queue using a shared, module-scoped
/// array to avoid per-call array allocations.
void submit(dynamic device, dynamic command) {
  _commandList[0] = command;
  device.queue.submit(_commandList);
  _commandList[0] = null;
}
