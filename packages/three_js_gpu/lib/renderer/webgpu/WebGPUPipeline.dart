import 'package:gpux/gpux.dart';
import 'WebGPUShaderModule.dart';
import 'WebGPUTexture.dart'; // Adjust based on your exact gpux library paths

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
  void create([GpuPipelineLayout? customLayout]) {
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
        final stepMode = layout.stepMode == VertexStepMode.vertex
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
        case PrimitiveTopology.pointList: topology = GpuPrimitiveTopology.pointList; break;
        case PrimitiveTopology.lineList: topology = GpuPrimitiveTopology.lineList; break;
        case PrimitiveTopology.lineStrip: topology = GpuPrimitiveTopology.lineStrip; break;
        case PrimitiveTopology.triangleList: topology = GpuPrimitiveTopology.triangleList; break;
        case PrimitiveTopology.triangleStrip: topology = GpuPrimitiveTopology.triangleStrip; break;
      }

      final GpuCullMode cullMode;
      switch (descriptor.cullMode) {
        case CullMode.none: cullMode = GpuCullMode.none; break;
        case CullMode.front: cullMode = GpuCullMode.front; break;
        case CullMode.back: cullMode = GpuCullMode.back; break;
      }

      final GpuFrontFace frontFace;
      switch (descriptor.frontFace) {
        case FrontFace.ccw: frontFace = GpuFrontFace.ccw; break;
        case FrontFace.cw: frontFace = GpuFrontFace.cw; break;
      }

      // 5. Map Depth Stencil Configurations
      GpuDepthStencilState? depthStencilState;
      final ds = descriptor.depthStencilState;
      if (ds != null) {
        final GpuCompareFunction depthCompare;
        switch (ds.depthCompare) {
          case CompareFunction.never: depthCompare = GpuCompareFunction.never; break;
          case CompareFunction.less: depthCompare = GpuCompareFunction.less; break;
          case CompareFunction.equal: depthCompare = GpuCompareFunction.equal; break;
          case CompareFunction.lessEqual: depthCompare = GpuCompareFunction.lessEqual; break;
          case CompareFunction.greater: depthCompare = GpuCompareFunction.greater; break;
          case CompareFunction.notEqual: depthCompare = GpuCompareFunction.notEqual; break;
          case CompareFunction.greaterEqual: depthCompare = GpuCompareFunction.greaterEqual; break;
          case CompareFunction.always: depthCompare = GpuCompareFunction.always; break;
        }

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
      GpuMultisampleState? multisampleState;
      final ms = descriptor.multisampleState;
      if (ms != null) {
        multisampleState = GpuMultisampleState(
          count: ms.count,
          mask: ms.mask,
          alphaToCoverageEnabled: ms.alphaToCoverageEnabled,
        );
      }

      // 8. Assemble Core Gpux RenderPipeline Descriptor Block
      final pipelineDescriptor = GpuRenderPipelineDescriptor(
        label: descriptor.label,
        layout: customLayout, // If null, gpux automatically infers layout bindings ("auto")
        vertex: GpuVertexState(
          module: _vertexShaderModule!.getModule()!,
          entryPoint: 'vs_main',
          buffers: bufferLayouts,
        ),
        fragment: GpuFragmentState(
          module: _fragmentShaderModule!.getModule()!,
          entryPoint: 'fs_main',
          targets: [colorTarget],
        ),
        primitive: GpuPrimitiveState(
          topology: topology,
          cullMode: cullMode,
          frontFace: frontFace,
        ),
        depthStencil: depthStencilState,
        multisample: multisampleState,
      );

      print("🔨 Creating GPU render pipeline...");
      _pipeline = device.createRenderPipeline(pipelineDescriptor);
      print("🔨 GPU render pipeline created: $_pipeline");
      print("🔨 Pipeline.create() SUCCESS");
    } catch (e) {
      print("🔨 Pipeline.create() EXCEPTION: ${e.toString()}");
      rethrow;
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

  GpuVertexFormat _toWebGpuVertexFormat(VertexFormat format) {
    switch (format) {
      case VertexFormat.float32: return GpuVertexFormat.float32;
      case VertexFormat.float32x2: return GpuVertexFormat.float32x2;
      case VertexFormat.float32x3: return GpuVertexFormat.float32x3;
      case VertexFormat.float32x4: return GpuVertexFormat.float32x4;
      case VertexFormat.uint32: return GpuVertexFormat.uint32;
      case VertexFormat.uint32x2: return GpuVertexFormat.uint32x2;
      case VertexFormat.uint32x3: return GpuVertexFormat.uint32x3;
      case VertexFormat.uint32x4: return GpuVertexFormat.uint32x4;
    }
  }

  GpuTextureFormat _toWebGpuTextureFormat(TextureFormat format) {
    switch (format) {
      case TextureFormat.rgba8Unorm: return GpuTextureFormat.rgba8Unorm;
      case TextureFormat.rgba8Srgb: return GpuTextureFormat.rgba8UnormSrgb;
      case TextureFormat.bgra8Unorm: return GpuTextureFormat.bgra8Unorm;
      case TextureFormat.bgra8Srgb: return GpuTextureFormat.bgra8UnormSrgb;
      case TextureFormat.depth24Plus: return GpuTextureFormat.depth24Plus;
      case TextureFormat.depth32Float: return GpuTextureFormat.depth32Float;
    }
  }

  GpuBlendComponent _createGpuBlendComponent(BlendComponent component) {
    return GpuBlendComponent(
      operation: _toWebGpuBlendOperation(component.operation),
      srcFactor: _toWebGpuBlendFactor(component.srcFactor),
      dstFactor: _toWebGpuBlendFactor(component.dstFactor),
    );
  }

  GpuBlendFactor _toWebGpuBlendFactor(BlendFactor factor) {
    switch (factor) {
      case BlendFactor.zero: return GpuBlendFactor.zero;
      case BlendFactor.one: return GpuBlendFactor.one;
      case BlendFactor.src: return GpuBlendFactor.src;
      case BlendFactor.oneMinusSrc: return GpuBlendFactor.oneMinusSrc;
      case BlendFactor.srcAlpha: return GpuBlendFactor.srcAlpha;
      case BlendFactor.oneMinusSrcAlpha: return GpuBlendFactor.oneMinusSrcAlpha;
      case BlendFactor.dst: return GpuBlendFactor.dst;
      case BlendFactor.oneMinusDst: return GpuBlendFactor.oneMinusDst;
      case BlendFactor.dstAlpha: return GpuBlendFactor.dstAlpha;
      case BlendFactor.oneMinusDstAlpha: return GpuBlendFactor.oneMinusDstAlpha;
    }
  }

  GpuBlendOperation _toWebGpuBlendOperation(BlendOperation operation) {
    switch (operation) {
      case BlendOperation.add: return GpuBlendOperation.add;
      case BlendOperation.subtract: return GpuBlendOperation.subtract;
      case BlendOperation.reverseSubtract: return GpuBlendOperation.reverseSubtract;
      case BlendOperation.min: return GpuBlendOperation.min;
      case BlendOperation.max: return GpuBlendOperation.max;
    }
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
  final List<VertexBufferLayoutDescriptor> vertexLayouts;
  final PrimitiveTopology primitiveTopology;
  final CullMode cullMode;
  final FrontFace frontFace;
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
  final VertexStepMode stepMode;
  final List<VertexAttributeDescriptor> attributes;
  const VertexBufferLayoutDescriptor({required this.arrayStride, required this.stepMode, required this.attributes});
}

class VertexAttributeDescriptor {
  final VertexFormat format;
  final int offset;
  final int shaderLocation;
  const VertexAttributeDescriptor({required this.format, required this.offset, required this.shaderLocation});
}

class ColorTargetDescriptor {
  final TextureFormat format;
  final BlendStateDescriptor? blendState;
  final ColorWriteMask writeMask;
  const ColorTargetDescriptor({required this.format, this.blendState, required this.writeMask});
}

class BlendStateDescriptor {
  final BlendComponent color;
  final BlendComponent alpha;
  const BlendStateDescriptor({required this.color, required this.alpha});
}

class BlendComponent {
  final BlendOperation operation;
  final BlendFactor srcFactor;
  final BlendFactor dstFactor;
  const BlendComponent({required this.operation, required this.srcFactor, required this.dstFactor});
}

class DepthStencilStateDescriptor {
  final TextureFormat format;
  final bool depthWriteEnabled;
  final CompareFunction depthCompare;
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
}

enum VertexStepMode { vertex, instance }
enum VertexFormat { float32, float32x2, float32x3, float32x4, uint32, uint32x2, uint32x3, uint32x4 }
enum PrimitiveTopology { pointList, lineList, lineStrip, triangleList, triangleStrip }
enum CullMode { none, front, back }
enum FrontFace { ccw, cw }
enum CompareFunction { never, less, equal, lessEqual, greater, notEqual, greaterEqual, always }
enum BlendFactor { zero, one, src, oneMinusSrc, srcAlpha, oneMinusSrcAlpha, dst, oneMinusDst, dstAlpha, oneMinusDstAlpha }
enum BlendOperation { add, subtract, reverseSubtract, min, max }
