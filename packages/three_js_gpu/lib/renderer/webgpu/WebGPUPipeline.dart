import 'package:gpux/gpux.dart';
import '../material/MaterialDescriptionRegistry.dart';
import 'WebGPUShaderModule.dart';

/// WebGPU render pipeline implementation.
/// T032: Pipeline state management with shaders, vertex layout, depth/stencil, culling.
class WebGPUPipeline {
  final GpuDevice device;
  final RenderPipelineDescriptor descriptor;

  GpuRenderPipeline? _pipeline;
  WebGPUShaderModule? _vertexShaderModule;
  WebGPUShaderModule? _fragmentShaderModule;

  WebGPUPipeline(this.device, this.descriptor);

  /// Creates the render pipeline (synchronous fallback architecture matching gpux).
  ///
  /// @param customLayout Optional custom pipeline layout. If provided, uses it instead of layout inferring.
  /// T021: Used for dynamic offset support in uniform buffers.
  int create([GpuPipelineLayout? customLayout]) {
    try {
      print("🔨 Pipeline.create() START");

      // 1. Compile vertex shader module
      print("🔨 Creating vertex shader module...");
      _vertexShaderModule = WebGPUShaderModule(
        device: device,
        descriptor: ShaderModuleDescriptor(
          label: "${descriptor.label ?? "pipeline"}_vertex",
          code: descriptor.vertexShader,
          stage: ShaderStage.vertex,
        ),
      );
      print("🔨 Compiling vertex shader...");
      _vertexShaderModule!.compile();

      // 2. Compile fragment shader module
      print("🔨 Creating fragment shader module...");
      _fragmentShaderModule = WebGPUShaderModule(
        device: device,
        descriptor: ShaderModuleDescriptor(
          label: "${descriptor.label ?? "pipeline"}_fragment",
          code: descriptor.fragmentShader,
          stage: ShaderStage.fragment,
        ),
      );
      print("🔨 Compiling fragment shader...");
      _fragmentShaderModule!.compile();

      // 3. Map Vertex Buffers Layouts
      final List<GpuVertexBufferLayout> bufferLayouts = [];
      for (final layout in descriptor.vertexLayouts) {
        final stepMode = layout.stepMode == GpuVertexStepMode.vertex
            ? GpuVertexStepMode.vertex
            : GpuVertexStepMode.instance;

        final List<GpuVertexAttribute> attributes = [];
        for (final attr in layout.attributes) {
          attributes.add(GpuVertexAttribute(
            format: _toWebGpuVertexFormat(attr.format),
            offset: attr.offset,
            shaderLocation: attr.shaderLocation,
          ));
        }

        bufferLayouts.add(GpuVertexBufferLayout(
          arrayStride: layout.arrayStride,
          stepMode: stepMode,
          attributes: attributes,
        ));
      }

      // 4. Map Primitive State Settings
      final GpuPrimitiveTopology topology;
      switch (descriptor.primitiveTopology) {
        case GpuPrimitiveTopology.pointList: topology = GpuPrimitiveTopology.pointList; break;
        case GpuPrimitiveTopology.lineList: topology = GpuPrimitiveTopology.lineList; break;
        case GpuPrimitiveTopology.lineStrip: topology = GpuPrimitiveTopology.lineStrip; break;
        case GpuPrimitiveTopology.triangleList: topology = GpuPrimitiveTopology.triangleList; break;
        case GpuPrimitiveTopology.triangleStrip: topology = GpuPrimitiveTopology.triangleStrip; break;
      }

      final GpuCullMode cullMode;
      switch (descriptor.cullMode) {
        case GpuCullMode.none: cullMode = GpuCullMode.none; break;
        case GpuCullMode.front: cullMode = GpuCullMode.front; break;
        case GpuCullMode.back: cullMode = GpuCullMode.back; break;
      }

      final GpuFrontFace frontFace;
      switch (descriptor.frontFace) {
        case GpuFrontFace.ccw: frontFace = GpuFrontFace.ccw; break;
        case GpuFrontFace.cw: frontFace = GpuFrontFace.cw; break;
      }

      // 5. Map Depth Stencil Configurations
      GpuDepthStencilState? depthStencilState;
      final ds = descriptor.depthStencilState;
      if (ds != null) {
        final GpuCompareFunction depthCompare = ds.depthCompare;

        depthStencilState = GpuDepthStencilState(
          format: _toWebGpuTextureFormat(ds.format),
          depthWriteEnabled: ds.depthWriteEnabled,
          depthCompare: depthCompare,
        );
      }

      // 6. Map Color Targets Blending States
      GpuBlendState? blendState;
      final blend = descriptor.colorTarget.blendState;
      if (blend != null) {
        blendState = GpuBlendState(
          color: _createGpuBlendComponent(blend.color),
          alpha: _createGpuBlendComponent(blend.alpha),
        );
      }

      final colorTarget = GpuColorTargetState(
        format: _toWebGpuTextureFormat(descriptor.colorTarget.format),
        blend: blendState,
        writeMask: descriptor.colorTarget.writeMask.bits,
      );

      // 7. Map Multisample Settings
      final ms = descriptor.multisampleState;

      // 8. Assemble Core Gpux RenderPipeline Descriptor Block
      final pipelineDescriptor = GpuRenderPipelineDescriptor(
        label: descriptor.label ?? '',
        layout: customLayout, // If null, gpux automatically infers layout bindings ("auto")
        vertexModule: _vertexShaderModule!.getModule()!,
        vertexEntryPoint: 'vs_main',
        vertexBuffers: bufferLayouts,
        fragmentModule: _fragmentShaderModule!.getModule()!,
        fragmentEntryPoint: 'fs_main',
        colorTargets: [colorTarget],
        primitiveTopology: topology,
        cullMode: cullMode,
        frontFace: frontFace,
        depthStencil: depthStencilState,
        multisampleCount: ms?.count ?? 0,
        multisampleMask: ms?.mask ?? 0xFFFFFFFF,
        alphaToCoverageEnabled: ms?.alphaToCoverageEnabled ?? false,
      );

      print("🔨 Creating GPU render pipeline...");
      _pipeline = device.createRenderPipeline(pipelineDescriptor);
      print("🔨 GPU render pipeline created: $_pipeline");
      print("🔨 Pipeline.create() SUCCESS");

      return 0; // Success code
    } catch (e) {
      print("🔨 Pipeline.create() EXCEPTION: ${e.toString()}");
      return -1; // Error code
    }
  }

  /// Checks if the pipeline is ready for use.
  /// T006: Added for non-blocking pipeline creation.
  bool get isReady => _pipeline != null;

  /// Gets the underlying GPU render pipeline handle.
  GpuRenderPipeline? getPipeline() => _pipeline;

  /// Binds this pipeline context layout directly to a render pass encoder execution track.
  void bind(GpuRenderPassEncoder renderPass) {
    final pipelineInstance = _pipeline;
    if (pipelineInstance != null) {
      renderPass.setPipeline(pipelineInstance);
    }
  }

  GpuVertexFormat _toWebGpuVertexFormat(GpuVertexFormat format) {
    return format;
  }

  GpuTextureFormat _toWebGpuTextureFormat(GpuTextureFormat format) {
    return format;
  }

  GpuBlendComponent _createGpuBlendComponent(GpuBlendComponent component) {
    return GpuBlendComponent(
      operation: _toWebGpuBlendOperation(component.operation),
      srcFactor: _toWebGpuBlendFactor(component.srcFactor),
      dstFactor: _toWebGpuBlendFactor(component.dstFactor),
    );
  }

  GpuBlendFactor _toWebGpuBlendFactor(GpuBlendFactor factor) {
    return factor;
  }

  GpuBlendOperation _toWebGpuBlendOperation(GpuBlendOperation operation) {
    return operation;
  }

  /// Disposes the pipeline resources and clears vertex/fragment shader contexts from graphics stack.
  void dispose() {
    _vertexShaderModule?.dispose();
    _fragmentShaderModule?.dispose();
    _pipeline = null;
  }
}

// ==========================================
// CORE DATA INTERFACE TYPE DECLARATIONS
// ==========================================

class RenderPipelineDescriptor {
  final String? label;
  final String vertexShader;
  final String fragmentShader;
  final List<GpuVertexBufferLayout> vertexLayouts;
  final GpuPrimitiveTopology primitiveTopology;
  final GpuCullMode cullMode;
  final GpuFrontFace frontFace;
  final DepthStencilStateDescriptor? depthStencilState;
  final MultisampleStateDescriptor? multisampleState;
  final ColorTargetDescriptor colorTarget;

  const RenderPipelineDescriptor({
    this.label,
    required this.vertexShader,
    required this.fragmentShader,
    required this.vertexLayouts,
    required this.primitiveTopology,
    required this.cullMode,
    required this.frontFace,
    this.depthStencilState,
    this.multisampleState,
    required this.colorTarget,
  });
}

class VertexBufferLayoutDescriptor {
  final int arrayStride;
  final GpuVertexStepMode stepMode;
  final List<VertexAttributeDescriptor> attributes;
  const VertexBufferLayoutDescriptor({required this.arrayStride, required this.stepMode, required this.attributes});
}

class VertexAttributeDescriptor {
  final GpuVertexFormat format;
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
  final GpuBlendOperation operation;
  final GpuBlendFactor srcFactor;
  final GpuBlendFactor dstFactor;
  const BlendComponent({required this.operation, required this.srcFactor, required this.dstFactor});
}

class DepthStencilStateDescriptor {
  final GpuTextureFormat format;
  final bool depthWriteEnabled;
  final GpuCompareFunction depthCompare;
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

// enum VertexStepMode { vertex, instance }
// enum VertexFormat { float32, float32x2, float32x3, float32x4, uint32, uint32x2, uint32x3, uint32x4 }
// enum PrimitiveTopology { pointList, lineList, lineStrip, triangleList, triangleStrip }
// enum CullMode { none, front, back }
// enum FrontFace { ccw, cw }
// enum CompareFunction { never, less, equal, lessEqual, greater, notEqual, greaterEqual, always }
// enum BlendFactor { zero, one, src, oneMinusSrc, srcAlpha, oneMinusSrcAlpha, dst, oneMinusDst, dstAlpha, oneMinusDstAlpha }
// enum BlendOperation { add, subtract, reverseSubtract, min, max }
