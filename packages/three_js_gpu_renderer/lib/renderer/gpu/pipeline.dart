import 'package:gpux/gpux.dart' as gpux;
import 'package:three_js_core/others/console/console_platform.dart';
import 'shader_module.dart';

/// Gpu render pipeline implementation.
/// T032: Pipeline state management with shaders, vertex layout, depth/stencil, culling.
class GpuPipeline {
  final gpux.GpuDevice device;
  final RenderPipelineDescriptor descriptor;

  gpux.GpuRenderPipeline? _pipeline;
  GpuShaderModule? _vertexShaderModule;
  GpuShaderModule? _fragmentShaderModule;

  GpuPipeline(this.device, this.descriptor);

  /// Creates the render pipeline (synchronous fallback architecture matching gpux).
  ///
  /// @param customLayout Optional custom pipeline layout. If provided, uses it instead of layout inferring.
  /// T021: Used for dynamic offset support in uniform buffers.
  int create([gpux.GpuPipelineLayout? customLayout]) {
    try {
      console.info("🔨 Pipeline.create() START");

      // 1. Compile vertex shader module
      console.info("🔨 Creating vertex shader module...");
      _vertexShaderModule = GpuShaderModule(
        device: device,
        descriptor: ShaderModuleDescriptor(
          label: "${descriptor.label ?? "pipeline"}_vertex",
          code: descriptor.vertexShader,
          stage: ShaderStage.vertex,
        ),
      );
      console.info("🔨 Compiling vertex shader...");
      _vertexShaderModule!.compile();

      // 2. Compile fragment shader module
      console.info("🔨 Creating fragment shader module...");
      _fragmentShaderModule = GpuShaderModule(
        device: device,
        descriptor: ShaderModuleDescriptor(
          label: "${descriptor.label ?? "pipeline"}_fragment",
          code: descriptor.fragmentShader,
          stage: ShaderStage.fragment,
        ),
      );
      console.info("🔨 Compiling fragment shader...");
      _fragmentShaderModule!.compile();

      // 3. Map Vertex Buffers Layouts
      final List<gpux.GpuVertexBufferLayout> bufferLayouts = [];
      for (final layout in descriptor.vertexLayouts) {
        final stepMode = layout.stepMode == gpux.GpuVertexStepMode.vertex
            ? gpux.GpuVertexStepMode.vertex
            : gpux.GpuVertexStepMode.instance;

        final List<gpux.GpuVertexAttribute> attributes = [];
        for (final attr in layout.attributes) {
          attributes.add(gpux.GpuVertexAttribute(
            format: attr.format,
            offset: attr.offset,
            shaderLocation: attr.shaderLocation,
          ));
        }

        bufferLayouts.add(gpux.GpuVertexBufferLayout(
          arrayStride: layout.arrayStride,
          stepMode: stepMode,
          attributes: attributes,
        ));
      }

      // 5. Map Depth Stencil Configurations
      gpux.GpuDepthStencilState? depthStencilState;
      final ds = descriptor.depthStencilState;
      if (ds != null) {
        final gpux.GpuCompareFunction depthCompare = ds.depthCompare;
        depthStencilState = gpux.GpuDepthStencilState(
          format: ds.format,
          depthWriteEnabled: ds.depthWriteEnabled,
          depthCompare: depthCompare,
        );
      }

      // 6. Map Color Targets Blending States
      gpux.GpuBlendState? blendState;
      final blend = descriptor.colorTarget.blend;
      if (blend != null) {
        blendState = gpux.GpuBlendState(
          color: _createGpuBlendComponent(blend.color),
          alpha: _createGpuBlendComponent(blend.alpha),
        );
      }

      // 7. Map Multisample Settings
      final ms = descriptor.multisampleState;

      // 8. Assemble Core Gpux RenderPipeline Descriptor Block
      final pipelineDescriptor = gpux.GpuRenderPipelineDescriptor(
        label: descriptor.label ?? '',
        layout: customLayout, // If null, gpux automatically infers layout bindings ("auto")
        vertexModule: _vertexShaderModule!.getModule()!,
        vertexEntryPoint: 'vs_main',
        vertexBuffers: bufferLayouts,
        fragmentModule: _fragmentShaderModule!.getModule()!,
        fragmentEntryPoint: 'fs_main',
        colorTargets: [
          gpux.GpuColorTargetState(
            format: descriptor.colorTarget.format,
            blend: blendState,
            writeMask: descriptor.colorTarget.writeMask,
          )
        ],
        primitiveTopology: descriptor.primitiveTopology,
        cullMode: descriptor.cullMode,
        frontFace: descriptor.frontFace,
        depthStencil: depthStencilState,
        multisampleCount: ms?.count ?? 1,
        multisampleMask: ms?.mask ?? 0xFFFFFFFF,
        alphaToCoverageEnabled: ms?.alphaToCoverageEnabled ?? false,
      );
      
      console.info("🔨 Creating GPU render pipeline...");
      _pipeline = device.createRenderPipeline(pipelineDescriptor);

      console.info("🔨 GPU render pipeline created: $_pipeline");
      console.info("🔨 Pipeline.create() SUCCESS");

      return 0; // Success code
    } catch (e) {
      console.error("🔨 Pipeline.create() EXCEPTION: ${e.toString()}");
      return -1; // Error code
    }
  }

  /// Checks if the pipeline is ready for use.
  /// T006: Added for non-blocking pipeline creation.
  bool get isReady => _pipeline != null;

  /// Gets the underlying GPU render pipeline handle.
  gpux.GpuRenderPipeline? getPipeline() => _pipeline;

  /// Binds this pipeline context layout directly to a render pass encoder execution track.
  void bind(gpux.GpuRenderPassEncoder renderPass) {
    final pipelineInstance = _pipeline;
    if (pipelineInstance != null) {
      renderPass.setPipeline(pipelineInstance);
    }
  }

  gpux.GpuBlendComponent _createGpuBlendComponent(gpux.GpuBlendComponent component) {
    return gpux.GpuBlendComponent(
      operation: _toGpuBlendOperation(component.operation),
      srcFactor: _toGpuBlendFactor(component.srcFactor),
      dstFactor: _toGpuBlendFactor(component.dstFactor),
    );
  }

  gpux.GpuBlendFactor _toGpuBlendFactor(gpux.GpuBlendFactor factor) {
    return factor;
  }

  gpux.GpuBlendOperation _toGpuBlendOperation(gpux.GpuBlendOperation operation) {
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
  final List<gpux.GpuVertexBufferLayout> vertexLayouts;
  final gpux.GpuPrimitiveTopology primitiveTopology;
  final gpux.GpuCullMode cullMode;
  final gpux.GpuFrontFace frontFace;
  final DepthStencilStateDescriptor? depthStencilState;
  final MultisampleStateDescriptor? multisampleState;
  final gpux.GpuColorTargetState colorTarget;

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
  final gpux.GpuVertexStepMode stepMode;
  final List<VertexAttributeDescriptor> attributes;
  const VertexBufferLayoutDescriptor({required this.arrayStride, required this.stepMode, required this.attributes});
}

class VertexAttributeDescriptor {
  final gpux.GpuVertexFormat format;
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
  final gpux.GpuBlendOperation operation;
  final gpux.GpuBlendFactor srcFactor;
  final gpux.GpuBlendFactor dstFactor;
  const BlendComponent({required this.operation, required this.srcFactor, required this.dstFactor});
}

class DepthStencilStateDescriptor {
  final gpux.GpuTextureFormat format;
  final bool depthWriteEnabled;
  final gpux.GpuCompareFunction depthCompare;
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
