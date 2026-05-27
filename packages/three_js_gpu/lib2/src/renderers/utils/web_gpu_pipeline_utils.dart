import 'dart:typed_data';

import 'package:gpux/gpux.dart';
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';

import '../descriptors/gpu_compute_pipeline_descriptor.dart';
import '../descriptors/gpu_pipeline_layout_descriptor.dart';
import '../descriptors/gpu_render_bundle_encoder_descriptor.dart';
import '../descriptors/gpu_render_pipeline_descriptor.dart';

// Shared file descriptors initialized from your recently converted files
final GPUComputePipelineDescriptor _computePipelineDescriptor = GPUComputePipelineDescriptor();
final GPUPipelineLayoutDescriptor _pipelineLayoutDescriptor = GPUPipelineLayoutDescriptor();
final GPURenderBundleEncoderDescriptor _renderBundleEncoderDescriptor = GPURenderBundleEncoderDescriptor();
final GPURenderPipelineDescriptor _renderPipelineDescriptor = GPURenderPipelineDescriptor();

/// A WebGPU backend utility module for managing pipelines.
class WebGPUPipelineUtils {
  /// A reference to the WebGPU backend instance context.
  final dynamic backend;

  /// A Map that tracks the active pipeline for render or compute passes.
  /// Replaces JavaScript WeakMap with safe Dart garbage-collection ready map caching.
  final Map<dynamic, dynamic> _activePipelines = {};

  /// Constructs a new utility object context.
  WebGPUPipelineUtils(this.backend);

  /// Sets the given pipeline for the given pass. The method makes sure to only set the
  /// pipeline when necessary.
  /// 
  /// [pass] - The active pass encoder (GPURenderPassEncoder or GPUComputePassEncoder).
  /// [pipeline] - The targeting pipeline (GPURenderPipeline or GPUComputePipeline).
  void setPipeline(dynamic pass, dynamic pipeline) {
    // Utilizing direct map bracket directives for the internal state cache tracking
    final dynamic currentPipeline = this._activePipelines[pass];
    
    if (currentPipeline != pipeline) {
      pass.setPipeline(pipeline);
      this._activePipelines[pass] = pipeline;
    }
  }

  /// Returns the sample count derived from the given render context.
  int _getSampleCount(dynamic renderContext) {
    return this.backend.utils.getSampleCountRenderContext(renderContext).toInt();
  }

  /// Creates a render pipeline for the given render object.
  /// 
  /// [renderObject] - The render object.
  /// [promises] - An array of compilation futures which are used in `compileAsync()`.
  void createRenderPipeline(dynamic renderObject, List<Future<void>>? promises) {
    // Replacing JavaScript object destructuring with standard property extraction
    final dynamic object = renderObject.object;
    final dynamic material = renderObject.material;
    final dynamic geometry = renderObject.geometry;
    final dynamic pipeline = renderObject.pipeline;

    final dynamic vertexProgram = pipeline.vertexProgram;
    final dynamic fragmentProgram = pipeline.fragmentProgram;

    final dynamic backend = this.backend;
    final dynamic device = backend.device;
    final dynamic utils = backend.utils;
    
    // Enforcing map directive bracket syntax rules instead of backend.get()
    final dynamic pipelineData = backend[pipeline];

    // Bind group layouts resolution
    final List<dynamic> bindGroupLayouts = [];
    final List<dynamic> renderObjectBindings = renderObject.getBindings() ?? [];
    
    for (final dynamic bindGroup in renderObjectBindings) {
      final dynamic bindingsData = backend[bindGroup];
      final dynamic layoutGPU = bindingsData?['layout']?['layoutGPU'];
      if (layoutGPU != null) {
        bindGroupLayouts.add(layoutGPU);
      }
    }

    // Vertex buffers generation
    final List<Map<String, dynamic>> vertexBuffers = backend.attributeUtils.createShaderVertexBuffers(renderObject);

    // Material blending configuration mapping
    Map<String, dynamic>? materialBlending;
    if (material.blending != NoBlending && 
        (material.blending != NormalBlending || material.transparent != false)) {
      materialBlending = this._getBlending(material);
    }

    // Stencil pipeline tracking logic evaluation
    Map<String, dynamic> stencilFront = {};
    if (material.stencilWrite == true) {
      stencilFront = {
        'compare': this._getStencilCompare(material),
        'failOp': this._getStencilOperation(material.stencilFail),
        'depthFailOp': this._getStencilOperation(material.stencilZFail),
        'passOp': this._getStencilOperation(material.stencilZPass)
      };
    }

    final int colorWriteMask = this._getColorWriteMask(material);
    final List<Map<String, dynamic>> targets = [];

    if (renderObject.context.textures != null) {
      final List<dynamic> textures = renderObject.context.textures;
      final dynamic mrt = renderObject.context.mrt;
      
      for (int i = 0; i < textures.length; i++) {
        final dynamic texture = textures[i];
        final String colorFormat = utils.getTextureFormatGPU(texture);

        // MRT blending allocation routing
        dynamic blending;
        if (mrt != null) {
          if (this.backend.compatibilityMode != true) {
            final dynamic blendMode = mrt.getBlendMode(texture.name);
            if (blendMode.blending == MaterialBlending) {
              blending = materialBlending;
            } else if (blendMode.blending != NoBlending) {
              blending = this._getBlending(blendMode);
            }
          } else {
            console.warning('WebGPURenderer: Multiple Render Targets (MRT) blending configuration is not fully supported in compatibility mode. The material blending will be used for all render targets.');
            blending = materialBlending;
          }
        } else {
          blending = materialBlending;
        }

        targets.add({
          'format': colorFormat, 
          'blend': blending, 
          'writeMask': colorWriteMask
        });
      }
    } else {
      final String colorFormat = utils.getCurrentColorFormat(renderObject.context);
      targets.add({
        'format': colorFormat, 
        'blend': materialBlending, 
        'writeMask': colorWriteMask
      });
    }

    final dynamic vertexModule = backend[vertexProgram]?['module'];
    final dynamic fragmentModule = backend[fragmentProgram]?['module'];
    
    final GpuPrimitiveTopology primitiveState = this._getPrimitiveState(object, geometry, material);
    final GpuCompareFunction depthCompare = this._getDepthCompare(material);
    final String depthStencilFormat = utils.getCurrentDepthStencilFormat(renderObject.context);
    final int sampleCount = this._getSampleCount(renderObject.context);

    _pipelineLayoutDescriptor.bindGroupLayouts = bindGroupLayouts;
    final dynamic pipelineLayout = device.createPipelineLayout(_pipelineLayoutDescriptor);
    _pipelineLayoutDescriptor.reset();

    final String materialIdentifier = material.name != null && material.name != '' ? material.name : material.type;
    _renderPipelineDescriptor.label = 'renderPipeline_${materialIdentifier}_${material.id}';
    
    // Mimics JavaScript Object.assign via explicit Map cloning spread expansions
    _renderPipelineDescriptor.vertex = <String, dynamic>{
      ...?vertexModule,
      'buffers': vertexBuffers
    };
    
    _renderPipelineDescriptor.fragment = <String, dynamic>{
      ...?fragmentModule,
      'targets': targets
    };
    
    _renderPipelineDescriptor.primitive = primitiveState;
    _renderPipelineDescriptor.multisample.count = sampleCount;
    _renderPipelineDescriptor.multisample.alphaToCoverageEnabled = material.alphaToCoverage == true && sampleCount > 1;
    _renderPipelineDescriptor.layout = pipelineLayout;

    final Map<String, dynamic> depthStencil = {};
    final bool renderDepth = renderObject.context.depth == true;
    final bool renderStencil = renderObject.context.stencil == true;

    if (renderDepth || renderStencil) {
      if (renderDepth) {
        depthStencil['format'] = depthStencilFormat;
        depthStencil['depthWriteEnabled'] = material.depthWrite;
        depthStencil['depthCompare'] = depthCompare;
      }
      if (renderStencil) {
        depthStencil['stencilFront'] = stencilFront;
        depthStencil['stencilBack'] = stencilFront; // Mirror matching non-separated GL behavior
        depthStencil['stencilReadMask'] = material.stencilFuncMask;
        depthStencil['stencilWriteMask'] = material.stencilWriteMask;
      }
      
      if (material.polygonOffset == true && (primitiveState == GpuPrimitiveTopology.triangleList)) {
        depthStencil['depthBias'] = material.polygonOffsetUnits;
        depthStencil['depthBiasSlopeScale'] = material.polygonOffsetFactor;
        depthStencil['depthBiasClamp'] = 0;
      }
      
      _renderPipelineDescriptor.depthStencil = depthStencil;
    }

    // Set error scopes on the graphics device to isolate pipeline compilation faults
    device.pushErrorScope('validation');
    
    final List<Map<String, dynamic>> stages = [
      {'program': vertexProgram, 'module': vertexModule?['module']},
      {'program': fragmentProgram, 'module': fragmentModule?['module']}
    ];
    
    final String pipelineLabel = _renderPipelineDescriptor.label;

    if (promises == null) {
      // Synchronous creation tracking path
      pipelineData['pipeline'] = device.createRenderPipeline(_renderPipelineDescriptor);
      _renderPipelineDescriptor.reset();
      
      device.popErrorScope().then((dynamic err) {
        if (err != null) {
          pipelineData['error'] = true;
          console.error('WebGPURenderer: Render pipeline creation failed ($pipelineLabel): ${err.message}');
          this._reportShaderDiagnostics(stages, pipelineLabel);
        }
      });
    } else {
      // Asynchronous non-blocking multi-threaded compilation target path
      final Future<void> asyncCompilationTask = () async {
        try {
          dynamic asyncError;
          try {
            pipelineData['pipeline'] = await device.createRenderPipelineAsync(_renderPipelineDescriptor);
          } catch (err) {
            asyncError = err;
          }

          final dynamic errorScope = await device.popErrorScope();
          if (errorScope != null || asyncError != null) {
            pipelineData['error'] = true;
            final String reason = errorScope != null ? errorScope.message : (asyncError != null ? asyncError.message : 'unknown');
            console.error('WebGPURenderer: Async render pipeline creation failed ($pipelineLabel): $reason');
            await this._reportShaderDiagnostics(stages, pipelineLabel);
          }
        } finally {
          _renderPipelineDescriptor.reset();
        }
      }();
      
      promises.add(asyncCompilationTask);
    }
  }

  /// Creates GPU render bundle encoder for the given render context.
  /// 
  /// [renderContext] - The render context.
  /// [label] - The label for the bundle encoder.
  /// Returns the hardware GPURenderBundleEncoder.
  dynamic createBundleEncoder(dynamic renderContext, [String label = 'renderBundleEncoder']) {
    final dynamic backend = this.backend;
    final dynamic utils = backend.utils;
    final dynamic device = backend.device;

    final String? depthStencilFormat = utils.getCurrentDepthStencilFormat(renderContext);
    final List<GpuTextureFormat> colorFormats = utils.getCurrentColorFormats(renderContext);
    final int sampleCount = this._getSampleCount(renderContext);

    _renderBundleEncoderDescriptor.label = label;
    _renderBundleEncoderDescriptor.colorFormats = colorFormats;
    _renderBundleEncoderDescriptor.depthStencilFormat = depthStencilFormat != null ? GpuTextureFormat.values.byName(depthStencilFormat) : null;
    _renderBundleEncoderDescriptor.sampleCount = sampleCount;

    final dynamic bundleEncoder = device.createRenderBundleEncoder(_renderBundleEncoderDescriptor);
    _renderBundleEncoderDescriptor.reset();

    return bundleEncoder;
  }

  /// Creates a compute pipeline for the given compute node.
  /// 
  /// [pipeline] - The compute pipeline.
  /// [bindings] - The bindings array list.
  void createComputePipeline(dynamic pipeline, List<dynamic> bindings) {
    final dynamic backend = this.backend;
    final dynamic device = backend.device;
    
    // Enforcing map directive bracket syntax rules instead of backend.get()
    final dynamic computeProgram = backend[pipeline.computeProgram]?['module'];
    final dynamic pipelineGPU = backend[pipeline];

    // Bind group layouts resolution
    final List<dynamic> bindGroupLayouts = [];
    for (final dynamic bindingsGroup in bindings) {
      final dynamic bindingsData = backend[bindingsGroup];
      final dynamic layoutGPU = bindingsData?['layout']?['layoutGPU'];
      if (layoutGPU != null) {
        bindGroupLayouts.add(layoutGPU);
      }
    }

    final dynamic computeStage = pipeline.computeProgram;
    final String nameSuffix = (computeStage.name != null && computeStage.name != '') ? '_${computeStage.name}' : '';
    final String pipelineLabel = 'computePipeline_${computeStage.stage}$nameSuffix';

    // Set dynamic error validation scopes on the core computing device context
    device.pushErrorScope('validation');

    _pipelineLayoutDescriptor.bindGroupLayouts = bindGroupLayouts;
    final dynamic pipelineLayout = device.createPipelineLayout(_pipelineLayoutDescriptor);
    _pipelineLayoutDescriptor.reset();

    _computePipelineDescriptor.label = pipelineLabel;
    _computePipelineDescriptor.compute = computeProgram;
    _computePipelineDescriptor.layout = pipelineLayout;

    pipelineGPU['pipeline'] = device.createComputePipeline(_computePipelineDescriptor);
    _computePipelineDescriptor.reset();

    device.popErrorScope().then((dynamic err) {
      if (err != null) {
        pipelineGPU['error'] = true;
        console.error('WebGPURenderer: Compute pipeline creation failed ($pipelineLabel): ${err.message}');
        this._reportShaderDiagnostics([
          {
            'program': computeStage, 
            'module': computeProgram?['module']
          }
        ], pipelineLabel);
      }
    });
  }

  /// Reads line-accurate diagnostics from shader modules and logs them.
  /// Called from pipeline creation error paths to turn opaque validation
  /// failures into actionable WGSL feedback.
  Future<void> _reportShaderDiagnostics(List<Map<String, dynamic>> stages, String pipelineLabel) async {
    for (final Map<String, dynamic> stage in stages) {
      final dynamic program = stage['program'];
      final dynamic module = stage['module'];
      
      if (module == null) continue;
      
      final dynamic info = await module.getCompilationInfo();
      final List<dynamic> messages = info.messages ?? [];
      if (messages.isEmpty) continue;

      final String code = program.code ?? '';
      final List<String> sourceLines = code.split('\n');

      for (final dynamic msg in messages) {
        final int lineNum = msg.lineNum?.toInt() ?? 0;
        final int linePos = msg.linePos?.toInt() ?? 0;
        
        final String location = lineNum > 0 
            ? ' at line $lineNum${linePos > 0 ? ':$linePos' : ''}' 
            : '';
            
        final String header = 'WebGPURenderer [$pipelineLabel / ${program.stage} ${msg.type}]$location: ${msg.message}';
        String excerpt = '';

        if (lineNum > 0 && lineNum <= sourceLines.length) {
          excerpt = '\n  ${sourceLines[lineNum - 1]}';
          if (linePos > 0) {
            excerpt += '\n  ${' ' * (linePos - 1)}^';
          }
        }

        if (msg.type == 'error') {
          console.error(header + excerpt);
        } else {
          console.warning(header + excerpt);
        }
      }
    }
  }

  /// Returns the blending state as a descriptor object required
  /// for the pipeline creation.
  Map<String, dynamic>? _getBlending(dynamic object) {
    Map<String, dynamic>? color;
    Map<String, dynamic>? alpha;

    final int blending = object.blending;
    final int blendSrc = object.blendSrc;
    final int blendDst = object.blendDst;
    final int blendEquation = object.blendEquation;

    if (blending == CustomBlending) {
      final int blendSrcAlpha = object.blendSrcAlpha ?? blendSrc;
      final int blendDstAlpha = object.blendDstAlpha ?? blendDst;
      final int blendEquationAlpha = object.blendEquationAlpha ?? blendEquation;

      color = {
        'srcFactor': this._getBlendFactor(blendSrc),
        'dstFactor': this._getBlendFactor(blendDst),
        'operation': this._getBlendOperation(blendEquation)
      };
      
      alpha = {
        'srcFactor': this._getBlendFactor(blendSrcAlpha),
        'dstFactor': this._getBlendFactor(blendDstAlpha),
        'operation': this._getBlendOperation(blendEquationAlpha)
      };
    } else {
      final bool premultipliedAlpha = object.premultipliedAlpha == true;
      
      void setBlend(GpuBlendFactor srcRGB, GpuBlendFactor dstRGB, GpuBlendFactor srcAlpha, GpuBlendFactor dstAlpha) {
        color = {
          'srcFactor': srcRGB,
          'dstFactor': dstRGB,
          'operation': GpuBlendOperation.add
        };
        alpha = {
          'srcFactor': srcAlpha,
          'dstFactor': dstAlpha,
          'operation': GpuBlendOperation.add
        };
      }

      if (premultipliedAlpha) {
        if (blending == NormalBlending) {
          setBlend(GpuBlendFactor.one, GpuBlendFactor.oneMinusSrcAlpha, GpuBlendFactor.one, GpuBlendFactor.oneMinusSrcAlpha);
        } else if (blending == AdditiveBlending) {
          setBlend(GpuBlendFactor.one, GpuBlendFactor.one, GpuBlendFactor.one, GpuBlendFactor.one);
        } else if (blending == SubtractiveBlending) {
          setBlend(GpuBlendFactor.zero, GpuBlendFactor.oneMinusSrc, GpuBlendFactor.zero, GpuBlendFactor.one);
        } else if (blending == MultiplyBlending) {
          setBlend(GpuBlendFactor.dst, GpuBlendFactor.oneMinusSrcAlpha, GpuBlendFactor.zero, GpuBlendFactor.one);
        }
      } else {
        if (blending == NormalBlending) {
          setBlend(GpuBlendFactor.srcAlpha, GpuBlendFactor.oneMinusSrcAlpha, GpuBlendFactor.one, GpuBlendFactor.oneMinusSrcAlpha);
        } else if (blending == AdditiveBlending) {
          setBlend(GpuBlendFactor.srcAlpha, GpuBlendFactor.one, GpuBlendFactor.one, GpuBlendFactor.one);
        } else if (blending == SubtractiveBlending) {
          final String prefix = object.isMaterial == true ? 'material' : 'blendMode';
          console.error('WebGPURenderer: "SubtractiveBlending" requires "$prefix.premultipliedAlpha = true".');
        } else if (blending == MultiplyBlending) {
          final String prefix = object.isMaterial == true ? 'material' : 'blendMode';
          console.error('WebGPURenderer: "MultiplyBlending" requires "$prefix.premultipliedAlpha = true".');
        }
      }
    }

    if (color != null && alpha != null) {
      return {
        'color': color,
        'alpha': alpha
      };
    } else {
      console.error('WebGPURenderer: Invalid blending: $blending');
      return null;
    }
  }

  /// Returns the GPU blend factor which is required for the pipeline creation.
  GpuBlendFactor? _getBlendFactor(int blend) {
    GpuBlendFactor? blendFactor;
    
    if (blend == ZeroFactor) {
      blendFactor = GpuBlendFactor.zero;
    } else if (blend == OneFactor) {
      blendFactor = GpuBlendFactor.one;
    } else if (blend == SrcColorFactor) {
      blendFactor = GpuBlendFactor.src;
    } else if (blend == OneMinusSrcColorFactor) {
      blendFactor = GpuBlendFactor.oneMinusSrc;
    } else if (blend == SrcAlphaFactor) {
      blendFactor = GpuBlendFactor.srcAlpha;
    } else if (blend == OneMinusSrcAlphaFactor) {
      blendFactor = GpuBlendFactor.oneMinusSrcAlpha;
    } else if (blend == DstColorFactor) {
      blendFactor = GpuBlendFactor.dst;
    } else if (blend == OneMinusDstColorFactor) {
      blendFactor = GpuBlendFactor.oneMinusDst;
    } else if (blend == DstAlphaFactor) {
      blendFactor = GpuBlendFactor.dstAlpha;
    } else if (blend == OneMinusDstAlphaFactor) {
      blendFactor = GpuBlendFactor.oneMinusDstAlpha;
    } else if (blend == SrcAlphaSaturateFactor) {
      blendFactor = GpuBlendFactor.srcAlphaSaturated;
    } else if (blend == BlendColorFactor) {
      blendFactor = GpuBlendFactor.constant;
    } else if (blend == OneMinusBlendColorFactor) {
      blendFactor = GpuBlendFactor.oneMinusConstant;
    } else {
      console.error('WebGPURenderer: Blend factor not supported: $blend');
    }
    
    return blendFactor;
  }

  /// Returns the GPU stencil compare function which is required for the pipeline creation.
  GpuCompareFunction? _getStencilCompare(dynamic material) {
    GpuCompareFunction? stencilCompare;
    final int stencilFunc = material.stencilFunc ?? AlwaysStencilFunc;
    
    if (stencilFunc == NeverStencilFunc) {
      stencilCompare = GpuCompareFunction.never;
    } else if (stencilFunc == AlwaysStencilFunc) {
      stencilCompare = GpuCompareFunction.always;
    } else if (stencilFunc == LessStencilFunc) {
      stencilCompare = GpuCompareFunction.less;
    } else if (stencilFunc == LessEqualStencilFunc) {
      stencilCompare = GpuCompareFunction.lessEqual;
    } else if (stencilFunc == EqualStencilFunc) {
      stencilCompare = GpuCompareFunction.equal;
    } else if (stencilFunc == GreaterEqualStencilFunc) {
      stencilCompare = GpuCompareFunction.greaterEqual;
    } else if (stencilFunc == GreaterStencilFunc) {
      stencilCompare = GpuCompareFunction.greater;
    } else if (stencilFunc == NotEqualStencilFunc) {
      stencilCompare = GpuCompareFunction.notEqual;
    } else {
      console.error('WebGPURenderer: Invalid stencil function: $stencilFunc');
    }
    
    return stencilCompare;
  }
  /// Returns the GPU stencil operation which is required for the pipeline creation.
  GpuStencilOperation? _getStencilOperation(int op) {
    GpuStencilOperation? stencilOperation;
    
    if (op == KeepStencilOp) {
      stencilOperation = GpuStencilOperation.keep;
    } else if (op == ZeroStencilOp) {
      stencilOperation = GpuStencilOperation.zero;
    } else if (op == ReplaceStencilOp) {
      stencilOperation = GpuStencilOperation.replace;
    } else if (op == InvertStencilOp) {
      stencilOperation = GpuStencilOperation.invert;
    } else if (op == IncrementStencilOp) {
      stencilOperation = GpuStencilOperation.incrementClamp;
    } else if (op == DecrementStencilOp) {
      stencilOperation = GpuStencilOperation.decrementClamp;
    } else if (op == IncrementWrapStencilOp) {
      stencilOperation = GpuStencilOperation.incrementWrap;
    } else if (op == DecrementWrapStencilOp) {
      stencilOperation = GpuStencilOperation.decrementWrap;
    } else {
      console.error('WebGPURenderer: Invalid stencil operation: $op');
    }
    
    return stencilOperation;
  }

  /// Returns the GPU blend operation which is required for the pipeline creation.
  GpuBlendOperation? _getBlendOperation(int blendEquation) {
    GpuBlendOperation? blendOperation;
    
    if (blendEquation == AddEquation) {
      blendOperation = GpuBlendOperation.add;
    } else if (blendEquation == SubtractEquation) {
      blendOperation = GpuBlendOperation.subtract;
    } else if (blendEquation == ReverseSubtractEquation) {
      blendOperation = GpuBlendOperation.reverseSubtract;
    } else if (blendEquation == MinEquation) {
      blendOperation = GpuBlendOperation.min;
    } else if (blendEquation == MaxEquation) {
      blendOperation = GpuBlendOperation.max;
    } else {
      console.error('WebGPUPipelineUtils: Blend equation not supported: $blendEquation');
    }
    
    return blendOperation;
  }

  /// Returns the primitive state as a descriptor object required
  /// for the pipeline creation.
  Map<String, dynamic> _getPrimitiveState(dynamic object, dynamic geometry, dynamic material) {
    final Map<String, dynamic> descriptor = {};
    final dynamic utils = this.backend.utils;

    descriptor['topology'] = utils.getPrimitiveTopology(object, material);

    if (geometry.index != null && object.isLine == true && object.isLineSegments != true) {
      descriptor['stripIndexFormat'] = (geometry.index.array is Uint16List)
          ? GpuIndexFormat.uint16
          : GpuIndexFormat.uint32;
    }

    bool flipSided = (material.side == BackSide);
    if (object.isMesh == true && object.matrixWorld.determinant() < 0) {
      flipSided = !flipSided;
    }

    descriptor['frontFace'] = (flipSided == true) ? GpuFrontFace.cw : GpuFrontFace.ccw;
    descriptor['cullMode'] = (material.side == DoubleSide) ? GpuCullMode.none : GpuCullMode.back;

    return descriptor;
  }

  /// Returns the GPU color write mask which is required for the pipeline creation.
  int _getColorWriteMask(dynamic material) {
    return (material.colorWrite == true) ? GpuColorWrite.all : 0;
  }

  /// Returns the GPU depth compare function which is required for the pipeline creation.
  GpuCompareFunction? _getDepthCompare(dynamic material) {
    GpuCompareFunction? depthCompare;

    if (material.depthTest == false) {
      depthCompare = GpuCompareFunction.always;
    } else {
      // Look up depth evaluation function and switch if reversed depth mapping is active
      dynamic depthFunc = material.depthFunc;
      if (this.backend.parameters['reversedDepthBuffer'] == true) {
        // Enforcing direct bracket map lookup syntax to resolve the reversed utility map functions
        depthFunc = ReversedDepthFuncs[material.depthFunc];
      }

      if (depthFunc == NeverDepth) {
        depthCompare = GpuCompareFunction.never;
      } else if (depthFunc == AlwaysDepth) {
        depthCompare = GpuCompareFunction.always;
      } else if (depthFunc == LessDepth) {
        depthCompare = GpuCompareFunction.less;
      } else if (depthFunc == LessEqualDepth) {
        depthCompare = GpuCompareFunction.lessEqual;
      } else if (depthFunc == EqualDepth) {
        depthCompare = GpuCompareFunction.equal;
      } else if (depthFunc == GreaterEqualDepth) {
        depthCompare = GpuCompareFunction.greaterEqual;
      } else if (depthFunc == GreaterDepth) {
        depthCompare = GpuCompareFunction.greater;
      } else if (depthFunc == NotEqualDepth) {
        depthCompare = GpuCompareFunction.notEqual;
      } else {
        console.error('WebGPUPipelineUtils: Invalid depth function: $depthFunc');
      }
    }

    return depthCompare;
  }
}