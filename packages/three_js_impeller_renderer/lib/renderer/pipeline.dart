import 'package:flutter_gpu/gpu.dart' as gpux;
import 'package:three_js_core/others/console/console_platform.dart';
import 'package:three_js_impeller_renderer/renderer/material/material_description_registry.dart';

/// Gpu render pipeline implementation.
/// T032: Pipeline state management with shaders, vertex layout, depth/stencil, culling.
class GpuPipeline {
  final gpux.GpuContext context;
  final RenderPipelineDescriptor descriptor;

  GpuPipeline(this.context, this.descriptor);

  /// Creates the render pipeline (synchronous fallback architecture matching gpux).
  ///
  /// @param customLayout Optional custom pipeline layout. If provided, uses it instead of layout inferring.
  /// T021: Used for dynamic offset support in uniform buffers.
  int bind(gpux.RenderPass pass) {
    try {
      console.info("🔨 Creating GPU render pipeline...");
      final vertex = descriptor.vertexShader;
      final fragment = descriptor.fragmentShader;
      final renderState = descriptor.renderState;

      final pipeline = context.createRenderPipeline(vertex,fragment);
      pass.bindPipeline(pipeline);
      pass.setCullMode(renderState.cullMode);
      pass.setDepthWriteEnable(renderState.depthWrite);
      pass.setDepthCompareOperation(renderState.depthCompare);
      pass.setPrimitiveType(renderState.topology);
      pass.setWindingOrder(renderState.winding);
      pass.setStencilConfig(
        gpux.StencilConfig(
          stencilFailureOperation: gpux.StencilOperation.keep,
          depthStencilPassOperation: gpux.StencilOperation.keep,
          depthFailureOperation: gpux.StencilOperation.keep,
          compareFunction: gpux.CompareFunction.always,
          writeMask: descriptor.writeMask ?? 0xffffffff
        ),
        targetFace: renderState.frontFace
      );

      pass.setColorBlendEnable(true, colorAttachmentIndex: descriptor.colorAttachmentIndex);
      pass.setColorBlendEquation(renderState.blendState,colorAttachmentIndex: descriptor.colorAttachmentIndex);


      console.info("🔨 GPU render pipeline created: $pipeline");
      console.info("🔨 Pipeline.create() SUCCESS");

      return 0; // Success code
    } catch (e) {
      console.error("🔨 Pipeline.create() EXCEPTION: ${e.toString()}");
      return -1; // Error code
    }
  }
}

// ==========================================
// CORE DATA INTERFACE TYPE DECLARATIONS
// ==========================================

class RenderPipelineDescriptor {
  final String? label;
  final gpux.Shader vertexShader;
  final gpux.Shader fragmentShader;
  //final MaterialDescriptor vertexLayouts;
  final MaterialRenderState renderState;
  final DepthStencilStateDescriptor? depthStencilState;
  final MultisampleStateDescriptor? multisampleState;
  final int? writeMask;
  final int colorAttachmentIndex;

  const RenderPipelineDescriptor({
    this.label,
    required this.vertexShader,
    required this.fragmentShader,
    ///required this.vertexLayouts,
    required this.renderState,
    this.depthStencilState,
    this.multisampleState,
    this.writeMask,
    this.colorAttachmentIndex = 0
  });
}

class VertexBufferLayoutDescriptor {
  final int arrayStride;
  final List<VertexAttributeDescriptor> attributes;
  const VertexBufferLayoutDescriptor({required this.arrayStride, required this.attributes});
}

class VertexAttributeDescriptor {
  final gpux.PolygonMode format;
  final int offset;
  final int shaderLocation;
  const VertexAttributeDescriptor({required this.format, required this.offset, required this.shaderLocation});
}

class BlendStateDescriptor {
  final BlendComponent color;
  final BlendComponent alpha;
  const BlendStateDescriptor({required this.color, required this.alpha});
}

class BlendComponent {
  final gpux.BlendOperation operation;
  final gpux.BlendFactor srcFactor;
  final gpux.BlendFactor dstFactor;
  const BlendComponent({required this.operation, required this.srcFactor, required this.dstFactor});
}

class DepthStencilStateDescriptor {
  final gpux.PixelFormat format;
  final bool depthWriteEnabled;
  final depthCompare;
  const DepthStencilStateDescriptor({required this.format, required this.depthWriteEnabled, required this.depthCompare});
}

class MultisampleStateDescriptor {
  final int count;
  final int mask;
  final bool alphaToCoverageEnabled;
  const MultisampleStateDescriptor({required this.count, required this.mask, required this.alphaToCoverageEnabled});
}

class ColorWriteMask {
  final int bits;
  const ColorWriteMask(this.bits);
  static const ColorWriteMask all = ColorWriteMask(0xF);
  static const ColorWriteMask none = ColorWriteMask(0x0);
}