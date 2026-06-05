import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';
import 'package:gpux/gpux.dart';

// gpux backend utility and descriptor imports
import '../../core/render_target_3d.dart';
import '../nodes/core/node.dart';
import 'common/backend.dart';
import './utils/gpu_constants.dart';
import './nodes/wgsl_node_builder.dart';
import './utils/gpu_utils.dart';
import './utils/web_gpu_attribute_utils.dart';
import './utils/web_gpu_binding_utils.dart';
import './utils/gpu_capabilities.dart';
import './utils/web_gpu_pipeline_utils.dart';
import './utils/web_gpu_texture_utils.dart';
import './utils/web_gpu_timestamp_query_pool.dart';
import './descriptors/gpu_buffer_descriptor.dart';
import './descriptors/gpu_command_encoder_descriptor.dart';
import './descriptors/gpu_compute_pass_descriptor.dart';
import './descriptors/gpu_query_set_descriptor.dart';
import './descriptors/gpu_shader_module_descriptor.dart';
import './descriptors/gpu_render_pass_color_attachment.dart';
import './descriptors/gpu_render_pass_depth_stencil_attachment.dart';
import './descriptors/gpu_render_pass_descriptor.dart';
import './descriptors/gpu_render_pass_timestamp_writes.dart';
import './descriptors/gpu_texel_copy_texture_info.dart';
import './descriptors/gpu_texture_view_descriptor.dart';
import './descriptors/gpu_extent_3d.dart';
import 'common/bind_group.dart';
import 'common/buffer.dart';
import 'common/compute_pipeline.dart';
import 'common/indirect_storage_buffer_attribute.dart';
import 'common/info.dart';
import 'common/programmable_stage.dart';
import 'common/render_context.dart';
import 'common/render_object.dart';
import 'common/storage_array_texture.dart';
import 'common/storage_buffer_attribute.dart';
import 'common/storage_instanced_buffer_attribute.dart';
import 'gpu_renderer.dart';

// Package constants definitions or local mapping replacements
class Constants {
  static const int webGPUCoordinateSystem = 2001; // Example constant ID
  static const int timestampQuery = 2002;
  static const String revision = '165';
  static const int halfFloatType = 1016;
  static const String textureCompare = 'textureCompare';
}

// Global File-Scope Shared Descriptors (Emulating JS File Constants)
final Map<String, double> _clearValue = {'r': 0, 'g': 0, 'b': 0, 'a': 1};
final GPUBufferDescriptor _bufferDescriptor = GPUBufferDescriptor();
final GPUCommandEncoderDescriptor _commandEncoderDescriptor = GPUCommandEncoderDescriptor();
final GPUComputePassDescriptor _computePassDescriptor = GPUComputePassDescriptor();
final GPUQuerySetDescriptor _querySetDescriptor = GPUQuerySetDescriptor();
final GPUShaderModuleDescriptor _shaderModuleDescriptor = GPUShaderModuleDescriptor();
final GPURenderPassTimestampWrites _renderPassTimestampWrites = GPURenderPassTimestampWrites();
final GPUTexelCopyTextureInfo _texelCopyTextureInfoSrc = GPUTexelCopyTextureInfo();
final GPUTexelCopyTextureInfo _texelCopyTextureInfoDst = GPUTexelCopyTextureInfo();
final GPUTextureViewDescriptor _viewDescriptor = GPUTextureViewDescriptor();
final GPUExtent3D _extent3D = GPUExtent3D();

/// A backend implementation targeting WebGPU.
class WebGPUBackend extends Backend {
  final bool isWebGPUBackend = true;
  
  bool? compatibilityMode;
  dynamic device; // Maps to native GPUDevice bindings context
  dynamic defaultRenderPassdescriptor;

  late WebGPUUtils utils;
  late WebGPUAttributeUtils attributeUtils;
  late WebGPUBindingUtils bindingUtils;
  late WebGPUCapabilities capabilities;
  late WebGPUPipelineUtils pipelineUtils;
  late WebGpuTextureUtils textureUtils;

  final Map<int, dynamic> occludedResolveCache = {};
  final Map<String, dynamic> _backendStateCache = {};
  late final Map<String, bool> _compatibility;

  /// Constructs a new WebGPU backend framework pipeline.
  WebGPUBackend([Map<String, dynamic>? parameters]) : super(parameters ?? {}) {
    final Map<String, dynamic> params = this.parameters;

    // Apply strict fallback parameters criteria logic
    params['alpha'] = parameters?['alpha'] ?? true;
    params['requiredLimits'] = parameters?['requiredLimits'] ?? <String, dynamic>{};

    // Instantiate exact typed utility engine configurations
    this.utils = WebGPUUtils(this);
    this.attributeUtils = WebGPUAttributeUtils(this);
    this.bindingUtils = WebGPUBindingUtils(this);
    this.capabilities = WebGPUCapabilities(this);
    this.pipelineUtils = WebGPUPipelineUtils(this);
    this.textureUtils = WebGpuTextureUtils(this);

    // Cross-Platform Compatibility validation check parsing
    bool compatibilityTextureCompare = true;
    try {
      // Validates browser environments safely on web compiles
      if (kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        compatibilityTextureCompare = false;
      }
    } catch (_) {
      // Defaults to true when compiled outside an explicit browser sandbox environment (Native Mobile/Desktop)
      compatibilityTextureCompare = true;
    }

    this._compatibility = {
      Constants.textureCompare: compatibilityTextureCompare
    };

    console.info('WebGPUBackend: Structural layout successfully initialized.');
  }

  /// Initializes the backend so it is ready for usage.
  /// 
  /// Throws an [Exception] if the WebGPU context adapter cannot be requested.
  @override
  Future<void> init(Renderer r) async {
    final renderer = r as WebGPURenderer;
    await super.init(renderer);
    final Map<String, dynamic> params = this.parameters;
    dynamic selectedDevice;

    if (params['device'] == null) {
      final Map<String, dynamic> adapterOptions = {
        'powerPreference': params['powerPreference'],
        'featureLevel': 'compatibility',
        'xrCompatible': renderer.xr.enabled
      };

      dynamic adapter;
      try {
        // Querying the platform web context securely via window environment channels
        // In mobile/desktop environments, this bridges directly to your native gpux bindings context
        //adapter = await html.window.navigator.gpu.requestAdapter(adapterOptions);
      } catch (e) {
        adapter = null;
      }

      if (adapter == null) {
        throw Exception('THREE.WebGPUBackend: Unable to create WebGPU adapter.');
      }

      // Feature support analysis checks
      final List<GpuFeatureName> supportedFeatures = [];
      for (final GpuFeatureName name in GpuFeatureName.values) {
        if (adapter.features.has(name)) {
          supportedFeatures.add(name);
        }
      }

      final Map<String, dynamic> deviceDescriptor = {
        'requiredFeatures': supportedFeatures,
        'requiredLimits': params['requiredLimits']
      };

      selectedDevice = await adapter.requestDevice(deviceDescriptor);
    } else {
      selectedDevice = params['device'];
    }

    // Assign and configure compatibility mode flags
    this.compatibilityMode = !selectedDevice.features.has('core-features-and-limits');
    if (this.compatibilityMode == true) {
      renderer.samples = 0; // Fallback sampling adjustment updates
    }

    // Monitor GPU Device Lost callback loops asynchronously
    selectedDevice.lost.then((dynamic info) {
      if (info.reason == 'destroyed') return;
      
      final Map<String, dynamic> deviceLossInfo = {
        'api': 'WebGPU',
        'message': info.message ?? 'Unknown reason',
        'reason': info.reason ?? null,
        'originalEvent': info
      };
      renderer.onDeviceLost(deviceLossInfo);
    });

    // Handle Uncaptured GPU Error dispatchers cleanly
    selectedDevice.onuncapturederror = (dynamic event) {
      final dynamic gpuError = event.error;
      final String type = gpuError?.runtimeType.toString() ?? 'GPUError';
      final String message = gpuError?.message ?? 'Unknown uncaptured GPU error';
      
      renderer.onError({
        'api': 'WebGPU',
        'type': type,
        'message': message,
        'originalEvent': event
      });
    };

    this.device = selectedDevice;
    
    // Evaluate if Timestamp Query metric pools are globally tracked by the device
    this.trackTimestamp = this.trackTimestamp && this.hasFeature(GpuFeatureName.timestampQuery);
    
    this.updateSize();
    console.info('WebGPUBackend: Backend device context successfully attached.');
  }

  /// Registers external GPU textures from `XRGPUBinding` for use in rendering.
  /// 
  /// [renderTarget] - The render target to register the textures for.
  /// [colorTexture] - The shared XR color GPUTexture.
  /// [viewDescriptors] - Optional view descriptors, one per XR view.
  void setXRRenderTargetTextures(BaseRenderTarget renderTarget, GpuTexture colorTexture, [List<dynamic>? viewDescriptors = null]) {
    this.set(renderTarget.texture, {
      'texture': colorTexture,
      'format': colorTexture.format,
      'externalTexture': true,
      'xrViewDescriptors': viewDescriptors,
      'initialized': true
    });
  }

  /// A reference to the context.
  dynamic get context {
    final dynamic canvasTarget = this.renderer?.getCanvasTarget();
    final dynamic canvasData = this.get(canvasTarget);
    dynamic selectedContext = canvasData['context'];

    if (selectedContext == null) {
      final Map<String, dynamic> params = this.parameters;
      
      if (canvasTarget.isDefaultCanvasTarget == true && params['context'] != null) {
        selectedContext = params['context'];
      } else {
        selectedContext = canvasTarget.domElement.getContext('webgpu');
      }

      // Safely perform attribute injection handling across Web and Native platforms
      try {
        final dynamic domElement = canvasTarget.domElement;
        // Check for DOM method existence safely via reflective lookup or try/catch fallback
        domElement.setAttribute('data-engine', 'three.js r${Constants.revision} webgpu');
      } catch (_) {
        // Ignored for OffscreenCanvas or headless native platforms lacking DOM elements
      }

      final String alphaMode = (params['alpha'] == true) ? 'premultiplied' : 'opaque';
      final String toneMappingMode = (params['outputType'] == Constants.halfFloatType) ? 'extended' : 'standard';

      selectedContext.configure({
        'device': this.device,
        'format': this.utils.getPreferredCanvasFormat(),
        // WebGPU constants mask evaluation using standard bitwise OR
        'usage': GpuTextureUsage.renderAttachment | GpuTextureUsage.copySrc,
        'alphaMode': alphaMode,
        'toneMapping': {
          'mode': toneMappingMode
        }
      });

      canvasData['context'] = selectedContext;
    }

    return selectedContext;
  }

  /// The coordinate system of the backend.
  int get coordinateSystem {
    return Constants.webGPUCoordinateSystem;
  }

  /// This method performs a readback operation by moving buffer data from
  /// a storage buffer attribute from the GPU to the CPU. ReadbackBuffer can
  /// be used to retain and reuse handles to the intermediate buffers and prevent
  /// new allocation.
  /// 
  /// Returns a [Future] that resolves with the buffer data when the data are ready.
  Future<ByteBuffer> getArrayBufferAsync(
    StorageBufferAttribute attribute, [
    dynamic target = null, 
    int offset = 0, 
    int count = -1
  ]) async {
    return await this.attributeUtils.getArrayBufferAsync(attribute, target, offset, count);
  }

  /// Returns the backend's rendering context.
  /// 
  /// Returns the [GPUCanvasContext] rendering context.
  dynamic getContext() {
    return this.context;
  }

  /// Returns the default render pass descriptor.
  /// 
  /// In WebGPU, the default framebuffer must be configured
  /// like custom framebuffers so the backend needs a render
  /// pass descriptor even when rendering directly to screen.
  dynamic _getDefaultRenderPassDescriptor() {
    final dynamic renderer = this.renderer;
    final dynamic canvasTarget = renderer.getCanvasTarget();
    final dynamic canvasData = this.get(canvasTarget);
    final int samples = renderer.currentSamples;
    
    dynamic descriptor = canvasData['descriptor'];

    if (descriptor == null || canvasData['samples'] != samples) {
      descriptor = GPURenderPassDescriptor();
      descriptor.colorAttachments.add(GPURenderPassColorAttachment());

      if (renderer.depth == true || renderer.stencil == true) {
        final dynamic depthStencilAttachment = GPURenderPassDepthStencilAttachment();
        depthStencilAttachment.view = this.textureUtils.getDepthBuffer(renderer.depth, renderer.stencil).createView();
        descriptor.depthStencilAttachment = depthStencilAttachment;
      }

      final GpuColorAttachment colorAttachment = descriptor.colorAttachments[0];
      if (samples > 0) {
        colorAttachment.view = this.textureUtils.getColorBuffer()?.createView();
      } else {
        colorAttachment.resolveTarget = null; // Replaces undefined with null
      }

      canvasData['descriptor'] = descriptor;
      canvasData['samples'] = samples;
    }

    final GpuColorAttachment colorAttachment = descriptor.colorAttachments[0];
    if (samples > 0) {
      colorAttachment.resolveTarget = this.context.getCurrentTexture().createView();
    } else {
      colorAttachment.view = this.context.getCurrentTexture().createView();
    }

    return descriptor;
  }

  /// Returns whether the render target is a render target array with depth 2D array texture.
  bool _isRenderCameraDepthArray(RenderContext renderContext) {
    final dynamic camera = renderContext.camera;
    return renderContext.depthTexture != null &&
        renderContext.depthTexture is StorageArrayTexture == true &&
        camera != null &&
        camera is ArrayCamera == true;
  }

  /// Returns whether the current render context references external textures.
  /// 
  /// External textures can change every frame, so their descriptors must not be cached.
  bool _hasExternalTexture(RenderContext renderContext) {
    final dynamic textures = renderContext.textures;
    if (textures == null) return false;

    // Optimized sequential iteration for fast external texture lookups
    for (int i = 0; i < textures.length; i++) {
      final dynamic textureData = this.get(textures[i]);
      if (textureData != null && textureData['externalTexture'] == true) {
        return true;
      }
    }

    return false;
  }

  /// Creates attachment views for an external texture render target.
  List<Map<String, dynamic>> _createExternalTextureViews(RenderContext renderContext, dynamic textureData) {
    final List<Map<String, dynamic>> textureViews = [];
    final dynamic camera = renderContext.camera;

    if (textureData['xrViewDescriptors'] != null && camera != null && camera is ArrayCamera == true) {
      final List<dynamic> xrViewDescriptors = textureData['xrViewDescriptors'];
      
      for (int i = 0; i < xrViewDescriptors.length; i++) {
        textureViews.add({
          'view': textureData['texture'].createView(xrViewDescriptors[i]),
          'resolveTarget': null, // Replaces JavaScript undefined
          'depthSlice': null     // Replaces JavaScript undefined
        });
      }
    } else {
      textureViews.add({
        'view': textureData['texture'].createView({
          'dimension': GpuTextureViewDimension.d2, // Uses lowercase enum naming standard
          'baseArrayLayer': renderContext.activeCubeFace,
          'arrayLayerCount': 1
        }),
        'resolveTarget': null,
        'depthSlice': null
      });
    }

    return textureViews;
  }

  /// Returns the render pass descriptor for the given render context.
  Map<String, dynamic> _getRenderPassDescriptor(RenderContext renderContext, [Map<String, dynamic> colorAttachmentsConfig = const {}]) {
    final BaseRenderTarget? renderTarget = renderContext.renderTarget;
    final dynamic renderTargetData = this.get(renderTarget);
    final bool hasExternalTexture = this._hasExternalTexture(renderContext);
    
    dynamic descriptors = renderTargetData['descriptors'];

    if (descriptors == null ||
        renderTargetData['width'] != renderTarget?.width ||
        renderTargetData['height'] != renderTarget?.height ||
        renderTargetData['samples'] != renderTarget?.samples ||
        hasExternalTexture) {
      descriptors = <String, dynamic>{};
      renderTargetData['descriptors'] = descriptors;
    }

    final int? cacheKey = renderContext.getCacheKey();
    dynamic descriptorBase = descriptors[cacheKey];

    if (descriptorBase == null || hasExternalTexture) {
      final List<Texture>? textures = renderContext.textures;
      final List<Map<String, dynamic>> textureViews = [];
      dynamic sliceIndex;
      final bool isRenderCameraDepthArray = this._isRenderCameraDepthArray(renderContext);

      for (int i = 0; i < (textures?.length ?? 0); i++) {
        final dynamic textureData = this.get(textures![i]);
        
        if (textureData['externalTexture'] == true) {
          // Replaces the JavaScript ES6 array spread syntax (...) with addAll
          textureViews.addAll(this._createExternalTextureViews(renderContext, textureData));
          continue;
        }

        _viewDescriptor.label = 'colorAttachment_$i';
        _viewDescriptor.baseMipLevel = renderContext.activeMipmapLevel;
        _viewDescriptor.mipLevelCount = 1;
        _viewDescriptor.baseArrayLayer = renderContext.activeCubeFace;
        _viewDescriptor.arrayLayerCount = 1;
        _viewDescriptor.dimension = GpuTextureViewDimension.d2;

        if (renderTarget is RenderTarget3D) {
          sliceIndex = renderContext.activeCubeFace;
          _viewDescriptor.baseArrayLayer = 0;
          _viewDescriptor.dimension = GpuTextureViewDimension.d3;
        } 
        else if (renderTarget is RenderTarget == true && textures[i].image.depth > 1) {
          if (isRenderCameraDepthArray == true) {
            final List<Camera> cameras = (renderContext.camera  as ArrayCamera).cameras;
            for (int layer = 0; layer < cameras.length; layer++) {
              _viewDescriptor.baseArrayLayer = layer;
              _viewDescriptor.arrayLayerCount = 1;
              _viewDescriptor.dimension = GpuTextureViewDimension.d2;
              
              final dynamic textureView = textureData['texture'].createView(_viewDescriptor);
              textureViews.add({
                'view': textureView,
                'resolveTarget': null,
                'depthSlice': null
              });
            }
          } else {
            _viewDescriptor.dimension = GpuTextureViewDimension.d2Array;
          }
        }

        if (isRenderCameraDepthArray != true) {
          final dynamic textureView = textureData['texture'].createView(_viewDescriptor);
          dynamic view;
          dynamic resolveTarget;

          if (textureData['msaaTexture'] != null) {
            view = textureData['msaaTexture'].createView();
            resolveTarget = textureView;
          } else {
            view = textureView;
            resolveTarget = null;
          }

          textureViews.add({
            'view': view,
            'resolveTarget': resolveTarget,
            'depthSlice': sliceIndex
          });
        }

        _viewDescriptor.reset();
      }

      final List<dynamic> colorAttachments = [];
      for (int i = 0; i < textureViews.length; i++) {
        final Map<String, dynamic> viewInfo = textureViews[i];
        final dynamic attachment = GPURenderPassColorAttachment();
        
        attachment.view = viewInfo['view'];
        attachment.depthSlice = viewInfo['depthSlice'];
        attachment.resolveTarget = viewInfo['resolveTarget'];
        colorAttachments.add(attachment);
      }

      descriptorBase = {
        'textureViews': textureViews,
        'colorAttachments': colorAttachments,
        'descriptor': GPURenderPassDescriptor()
      };

      if (renderContext.depth == true) {
        final dynamic depthTextureData = this.get(renderContext.depthTexture);
        
        if (renderContext.depthTexture is StorageArrayTexture == true || renderContext.depthTexture is CubeTexture == true) {
          _viewDescriptor.dimension = GpuTextureViewDimension.d2;
          _viewDescriptor.arrayLayerCount = 1;
          _viewDescriptor.baseArrayLayer = renderContext.activeCubeFace;
        }

        final dynamic depthStencilAttachment = GPURenderPassDepthStencilAttachment();
        depthStencilAttachment.view = depthTextureData['texture'].createView(_viewDescriptor);
        descriptorBase['depthStencilAttachment'] = depthStencilAttachment;
        
        _viewDescriptor.reset();
      }

      descriptors[cacheKey] = descriptorBase;
      renderTargetData['width'] = renderTarget?.width;
      renderTargetData['height'] = renderTarget?.height;
      renderTargetData['samples'] = renderTarget?.samples;
      renderTargetData['activeMipmapLevel'] = renderContext.activeMipmapLevel;
      renderTargetData['activeCubeFace'] = renderContext.activeCubeFace;
    }

    final dynamic descriptor = descriptorBase['descriptor'];
    descriptor.reset();

    // Apply dynamic properties to cached attachments configurations
    for (int i = 0; i < descriptorBase['colorAttachments'].length; i++) {
      GpuColor clearValue = GpuColor(0, 0, 0, 1);//{'r': 0, 'g': 0, 'b': 0, 'a': 1};

      if (i == 0 && colorAttachmentsConfig['clearValue'] != null) {
        clearValue = colorAttachmentsConfig['clearValue'];
      }

      final attachment = GpuColorAttachment(
        view: descriptorBase['colorAttachments'][i].view,
        depthSlice: descriptorBase['colorAttachments'][i].depthSlice,
        resolveTarget: descriptorBase['colorAttachments'][i].resolveTarget,
        loadOp: colorAttachmentsConfig['loadOp'] ?? GpuLoadOp.load,
        storeOp: colorAttachmentsConfig['storeOp'] ?? GpuStoreOp.store,
        clearValue: clearValue
      );
      descriptorBase['colorAttachments'][i] = attachment;
      descriptor.colorAttachments.add(attachment);
    }

    if (descriptorBase['depthStencilAttachment'] != null) {
      descriptor.depthStencilAttachment = descriptorBase['depthStencilAttachment'];
    }

    return descriptor;
  }

  /// This method is executed at the beginning of a render call and prepares
  /// the WebGPU state for upcoming render calls.
  void beginRender(RenderContext renderContext) {
    // Utilizing direct map bracket directives instead of this.get()
    final Map<dynamic,dynamic> renderContextData = this.get(renderContext)!; 
    final int occlusionQueryCount = renderContext.occlusionQueryCount;
    dynamic occlusionQuerySet;

    if (occlusionQueryCount > 0) {
      if (renderContextData['currentOcclusionQuerySet'] != null) {
        renderContextData['currentOcclusionQuerySet'].destroy();
      }
      if (renderContextData['currentOcclusionQueryBuffer'] != null) {
        renderContextData['currentOcclusionQueryBuffer'].destroy();
      }

      // Retain context reference sets safely before asynchronous readback cycles
      renderContextData['currentOcclusionQuerySet'] = renderContextData['occlusionQuerySet'];
      renderContextData['currentOcclusionQueryBuffer'] = renderContextData['occlusionQueryBuffer'];
      renderContextData['currentOcclusionQueryObjects'] = renderContextData['occlusionQueryObjects'];

      _querySetDescriptor.type = GpuQueryType.occlusion;//'occlusion';
      _querySetDescriptor.count = occlusionQueryCount;
      
      occlusionQuerySet = device.createQuerySet(_querySetDescriptor);
      _querySetDescriptor.reset();

      renderContextData['occlusionQuerySet'] = occlusionQuerySet;
      renderContextData['occlusionQueryIndex'] = 0;
      
      // Instantiates a typed non-growable fixed list layout matching original array size allocation
      renderContextData['occlusionQueryObjects'] = List<dynamic>.filled(occlusionQueryCount, null, growable: false);
      renderContextData['lastOcclusionObject'] = null;
    }

    dynamic descriptor;
    if (renderContext.textures == null) {
      descriptor = this._getDefaultRenderPassDescriptor();
    } else {
      descriptor = this._getRenderPassDescriptor(renderContext, {
        'loadOp': GpuLoadOp.load
      });
    }

    this.initTimestampQuery(Constants.timestampQuery, this.getTimestampUID(renderContext), descriptor);
    descriptor.occlusionQuerySet = occlusionQuerySet;
    final dynamic depthStencilAttachment = descriptor.depthStencilAttachment;

    if (renderContext.textures != null) {
      final List<dynamic> colorAttachments = descriptor.colorAttachments;
      for (int i = 0; i < colorAttachments.length; i++) {
        final dynamic colorAttachment = colorAttachments[i];
        if (renderContext.clearColor == true) {
          if (i == 0) {
            colorAttachment.clearValue = renderContext.clearColorValue;
          } else {
            _clearValue['r'] = 0;
            _clearValue['g'] = 0;
            _clearValue['b'] = 0;
            _clearValue['a'] = 1;
            colorAttachment.clearValue = _clearValue;
          }
          colorAttachment.loadOp = GpuLoadOp.clear;
        } else {
          colorAttachment.loadOp = GpuLoadOp.load;
        }
        colorAttachment.storeOp = GpuStoreOp.store;
      }
    } else {
      final dynamic colorAttachment = descriptor.colorAttachments[0];
      if (renderContext.clearColor == true) {
        colorAttachment.clearValue = renderContext.clearColorValue;
        colorAttachment.loadOp = GpuLoadOp.clear;
      } else {
        colorAttachment.loadOp = GpuLoadOp.load;
      }
      colorAttachment.storeOp = GpuStoreOp.store;
    }

    if (renderContext.depth == true && depthStencilAttachment != null) {
      if (renderContext.clearDepth == true) {
        depthStencilAttachment.depthClearValue = renderContext.clearDepthValue;
        depthStencilAttachment.depthLoadOp = GpuLoadOp.clear;
      } else {
        depthStencilAttachment.depthLoadOp = GpuLoadOp.load;
      }
      depthStencilAttachment.depthStoreOp = GpuStoreOp.store;
    }

    if (renderContext.stencil == true && depthStencilAttachment != null) {
      if (renderContext.clearStencil == true) {
        depthStencilAttachment.stencilClearValue = renderContext.clearStencilValue;
        depthStencilAttachment.stencilLoadOp = GpuLoadOp.clear;
      } else {
        depthStencilAttachment.stencilLoadOp = GpuLoadOp.load;
      }
      depthStencilAttachment.stencilStoreOp = GpuStoreOp.store;
    }

    final dynamic encoder = device.createCommandEncoder(_commandEncoderDescriptor);
    _commandEncoderDescriptor.reset();

    // Layered render targets: prepare bundle encoders for each camera in the array camera structure
    if (this._isRenderCameraDepthArray(renderContext) == true) {
      final List<dynamic> cameras = (renderContext.camera as ArrayCamera).cameras;
      
      if (renderContextData['layerDescriptors'] == null || renderContextData['layerDescriptors'].length != cameras.length) {
        this._createArrayCameraLayerDescriptors(renderContext, renderContextData, descriptor, cameras);
      } else {
        this._updateArrayCameraLayerDescriptors(renderContext, renderContextData, cameras);
      }

      renderContextData['bundleEncoders'] = <dynamic>[];
      renderContextData['bundleSets'] = <Map<String, dynamic>>[];

      for (int i = 0; i < cameras.length; i++) {
        final dynamic bundleEncoder = this.pipelineUtils.createBundleEncoder(renderContext, 'renderBundleArrayCamera_$i');
        
        final Map<String, dynamic> bundleSets = {
          'attributes': <String, dynamic>{},
          'bindingGroups': <dynamic>[],
          'pipeline': null,
          'index': null
        };
        
        renderContextData['bundleEncoders'].add(bundleEncoder);
        renderContextData['bundleSets'].add(bundleSets);
      }

      renderContextData['currentPass'] = null;
    } else {
      final dynamic currentPass = encoder.beginRenderPass(descriptor);
      renderContextData['currentPass'] = currentPass;

      if (renderContext.viewport != null) {
        this.updateViewport(renderContext);
      }
      if (renderContext.scissor != null) {
        this.updateScissor(renderContext);
      }
    }

    renderContextData['encoder'] = encoder;
    renderContextData['currentSets'] = {
      'attributes': <String, dynamic>{},
      'bindingGroups': <dynamic>[],
      'pipeline': null,
      'index': null
    };
    renderContextData['renderBundles'] = <dynamic>[];
  }

  /// Creates render pass descriptors for each camera in an array camera.
  void _createArrayCameraLayerDescriptors(
    RenderContext renderContext, 
    Map<dynamic,dynamic> renderContextData, 
    dynamic descriptor, 
    List<dynamic> cameras
  ) {
    final dynamic depthStencilAttachment = descriptor.depthStencilAttachment;
    renderContextData['layerDescriptors'] = <dynamic>[];
    
    // Utilizing direct map bracket lookup directive instead of this.get()
    final Map<dynamic,dynamic> depthTextureData = this.get(renderContext.depthTexture)!; 
    
    if (depthTextureData['viewCache'] == null) {
      depthTextureData['viewCache'] = <int, dynamic>{};
    }

    final dynamic viewCache = depthTextureData['viewCache'];

    for (int i = 0; i < cameras.length; i++) {
      final dynamic sourceAttachment = descriptor.colorAttachments[0];
      final GPURenderPassColorAttachment layerColorAttachment = GPURenderPassColorAttachment();
      
      layerColorAttachment.view = descriptor.colorAttachments[i].view;
      layerColorAttachment.depthSlice = sourceAttachment.depthSlice;
      layerColorAttachment.resolveTarget = sourceAttachment.resolveTarget;
      layerColorAttachment.loadOp = sourceAttachment.loadOp;
      layerColorAttachment.storeOp = sourceAttachment.storeOp;
      layerColorAttachment.clearValue = sourceAttachment.clearValue;

      final GPURenderPassDescriptor layerDescriptor = GPURenderPassDescriptor();
      layerDescriptor.label = descriptor.label;
      layerDescriptor.occlusionQuerySet = descriptor.occlusionQuerySet;
      layerDescriptor.timestampWrites = descriptor.timestampWrites;
      layerDescriptor.colorAttachments.add(layerColorAttachment);

      if (descriptor.depthStencilAttachment != null) {
        final int layerIndex = i;
        
        if (viewCache[layerIndex] == null) {
          _viewDescriptor.dimension = GpuTextureViewDimension.d2;
          _viewDescriptor.baseArrayLayer = i;
          _viewDescriptor.arrayLayerCount = 1;
          
          viewCache[layerIndex] = depthTextureData['texture'].createView(_viewDescriptor);
          _viewDescriptor.reset();
        }

        final dynamic layerDepthStencilAttachment = GPURenderPassDepthStencilAttachment();
        layerDepthStencilAttachment.view = viewCache[layerIndex];
        layerDepthStencilAttachment.depthLoadOp = depthStencilAttachment.depthLoadOp ?? GpuLoadOp.clear;
        layerDepthStencilAttachment.depthStoreOp = depthStencilAttachment.depthStoreOp ?? GpuStoreOp.store;
        layerDepthStencilAttachment.depthClearValue = depthStencilAttachment.depthClearValue ?? 1.0;

        if (renderContext.stencil == true) {
          layerDepthStencilAttachment.stencilLoadOp = depthStencilAttachment.stencilLoadOp;
          layerDepthStencilAttachment.stencilStoreOp = depthStencilAttachment.stencilStoreOp;
          layerDepthStencilAttachment.stencilClearValue = depthStencilAttachment.stencilClearValue;
        }
        
        layerDescriptor.depthStencilAttachment = layerDepthStencilAttachment;
      } else {
        final dynamic layerDepthStencilAttachment = GPURenderPassDepthStencilAttachment();
        
        layerDepthStencilAttachment.view = depthStencilAttachment.view;
        layerDepthStencilAttachment.depthLoadOp = depthStencilAttachment.depthLoadOp;
        layerDepthStencilAttachment.depthStoreOp = depthStencilAttachment.depthStoreOp;
        layerDepthStencilAttachment.depthClearValue = depthStencilAttachment.depthClearValue;
        layerDepthStencilAttachment.depthReadOnly = depthStencilAttachment.depthReadOnly;
        layerDepthStencilAttachment.stencilLoadOp = depthStencilAttachment.stencilLoadOp;
        layerDepthStencilAttachment.stencilStoreOp = depthStencilAttachment.stencilStoreOp;
        layerDepthStencilAttachment.stencilClearValue = depthStencilAttachment.stencilClearValue;
        layerDepthStencilAttachment.stencilReadOnly = depthStencilAttachment.stencilReadOnly;
        
        layerDescriptor.depthStencilAttachment = layerDepthStencilAttachment;
      }

      renderContextData['layerDescriptors'].add(layerDescriptor);
    }
  }

  /// Updates render pass descriptors for each camera in an array camera.
  void _updateArrayCameraLayerDescriptors(
    dynamic renderContext, 
    dynamic renderContextData, 
    List<dynamic> cameras
  ) {
    for (int i = 0; i < cameras.length; i++) {
      // Using map bracket directives to pull the layer descriptor from the data store
      final dynamic layerDescriptor = renderContextData['layerDescriptors'][i];

      if (layerDescriptor.depthStencilAttachment != null) {
        final dynamic depthAttachment = layerDescriptor.depthStencilAttachment;

        if (renderContext.depth == true) {
          if (renderContext.clearDepth == true) {
            depthAttachment.depthClearValue = renderContext.clearDepthValue;
            depthAttachment.depthLoadOp = GpuLoadOp.clear;
          } else {
            depthAttachment.depthLoadOp = GpuLoadOp.load;
          }
        }

        if (renderContext.stencil == true) {
          if (renderContext.clearStencil == true) {
            depthAttachment.stencilClearValue = renderContext.clearStencilValue;
            depthAttachment.stencilLoadOp = GpuLoadOp.clear;
          } else {
            depthAttachment.stencilLoadOp = GpuLoadOp.load;
          }
        }
      }
    }
  }

  /// This method is executed at the end of a render call and finalizes work
  /// after draw calls.
  void finishRender(RenderContext renderContext) {
    // Direct map bracket assignment following map directive strategy
    final Map<dynamic,dynamic> renderContextData = this.get(renderContext)!; 
    final int occlusionQueryCount = renderContext.occlusionQueryCount ?? 0;

    if (renderContextData['renderBundles'].length > 0) {
      renderContextData['currentPass'].executeBundles(renderContextData['renderBundles']);
    }

    if (occlusionQueryCount > (renderContextData['occlusionQueryIndex'] ?? 0)) {
      renderContextData['currentPass'].endOcclusionQuery();
    }

    final dynamic encoder = renderContextData['encoder'];

    // Layered render targets: execute the bundle array sequence for each camera layer configuration
    if (this._isRenderCameraDepthArray(renderContext) == true) {
      final List<dynamic> bundles = [];
      final List<dynamic> bundleEncoders = renderContextData['bundleEncoders'] ?? [];

      for (int i = 0; i < bundleEncoders.length; i++) {
        final dynamic bundleEncoder = bundleEncoders[i];
        bundles.add(bundleEncoder.finish());
      }

      final List<dynamic> layerDescriptors = renderContextData['layerDescriptors'] ?? [];
      for (int i = 0; i < layerDescriptors.length; i++) {
        if (i < bundles.length) {
          final dynamic layerDescriptor = layerDescriptors[i];
          final dynamic renderPass = encoder.beginRenderPass(layerDescriptor);

          if (renderContext.viewport == true) {
            // Replaces JavaScript object destructuring with direct property extraction
            final dynamic vp = renderContext.viewportValue;
            renderPass.setViewport(vp.x, vp.y, vp.width, vp.height, vp.minDepth, vp.maxDepth);
          }

          if (renderContext.scissor == true) {
            final dynamic sc = renderContext.scissorValue;
            renderPass.setScissorRect(sc.x, sc.y, sc.width, sc.height);
          }

          renderPass.executeBundles([bundles[i]]);
          renderPass.end();
        }
      }
    } else if (renderContextData['currentPass'] != null) {
      renderContextData['currentPass'].end();
    }

    if (occlusionQueryCount > 0) {
      final int bufferSize = occlusionQueryCount * 8; // 8 byte entries for query results
      
      // Access the internal cache via bracket map syntax
      dynamic queryResolveBuffer = this.occludedResolveCache[bufferSize];

      if (queryResolveBuffer == null) {
        _bufferDescriptor.size = bufferSize;
        _bufferDescriptor.usage = GpuBufferUsage.queryResolve | GpuBufferUsage.copySrc;
        
        queryResolveBuffer = this.device.createBuffer(_bufferDescriptor);
        _bufferDescriptor.reset();
        
        this.occludedResolveCache[bufferSize] = queryResolveBuffer;
      }

      _bufferDescriptor.size = bufferSize;
      _bufferDescriptor.usage = GpuBufferUsage.copyDst | GpuBufferUsage.mapRead;
      
      final dynamic readBuffer = this.device.createBuffer(_bufferDescriptor);
      _bufferDescriptor.reset();

      // Run buffer resolutions through WebGPU command encoder pipes
      renderContextData['encoder'].resolveQuerySet(renderContextData['occlusionQuerySet'], 0, occlusionQueryCount, queryResolveBuffer, 0);
      renderContextData['encoder'].copyBufferToBuffer(queryResolveBuffer, 0, readBuffer, 0, bufferSize);
      renderContextData['occlusionQueryBuffer'] = readBuffer;
    }

    // Submit command sequences straight to the hardware driver wrapper
    submit(this.device, renderContextData['encoder'].finish());

    if (renderContext.textures != null) {
      final List<Texture>? textures = renderContext.textures;
      for (int i = 0; i < (textures?.length ?? 0); i++) {
        final Texture texture = textures![i];
        if (texture.generateMipmaps == true) {
          this.textureUtils.generateMipmaps(texture);
        }
      }
    }
  }

  /// Returns `true` if the given 3D object is fully occluded by other
  /// 3D objects in the scene.
  bool isOccluded(RenderContext renderContext, Object3D object) {
    // Utilizing direct map bracket directives instead of this.get()
    final Map<dynamic,dynamic> renderContextData = this.get(renderContext)!; 
    final Set<dynamic>? occluded = renderContextData['occluded'];
    
    return occluded != null && occluded.contains(object);
  }

  /// This method processes the result of occlusion queries and writes it
  /// into render context data.
  /// 
  /// Returns a [Future] that resolves when the occlusion query results have been processed.
  Future<void> resolveOccludedAsync(dynamic renderContext) async {
    final Map<dynamic,dynamic> renderContextData = this.get(renderContext)!; 
    
    // Destructuring unpack replacement via direct bracket properties extraction
    final dynamic currentOcclusionQueryBuffer = renderContextData?['currentOcclusionQueryBuffer'];
    final List<dynamic>? currentOcclusionQueryObjects = renderContextData?['currentOcclusionQueryObjects'];

    if (currentOcclusionQueryBuffer != null && currentOcclusionQueryObjects != null) {
      // Replaces WeakSet with a standard Dart Set collection structure
      final Set<dynamic> occluded = <dynamic>{};
      
      renderContextData['currentOcclusionQueryObjects'] = null;
      renderContextData['currentOcclusionQueryBuffer'] = null;

      // Map dynamic GPU memory buffers asynchronously to CPU space
      await currentOcclusionQueryBuffer.mapAsync(GpuMapMode.read);
      
      // Extract the raw binary payload array view from the mapped region
      final dynamic buffer = currentOcclusionQueryBuffer.getMappedRange();
      
      // Native Dart representation of a 64-bit unsigned binary integer view layer
      final ByteData results = ByteData.view(buffer);

      for (int i = 0; i < currentOcclusionQueryObjects.length; i++) {
        // Reads 8-byte (64-bit) unsigned increments sequentially from the payload stream
        final int byteOffset = i * 8;
        final int queryValue = results.getUint64(byteOffset, Endian.little);

        if (queryValue == 0) {
          occluded.add(currentOcclusionQueryObjects[i]);
        }
      }

      currentOcclusionQueryBuffer.destroy();
      renderContextData['occluded'] = occluded;
    }
  }

  /// Updates the viewport with the values from the given render context.
  void updateViewport(RenderContext renderContext) {
    final Map<dynamic,dynamic> renderContextData = this.get(renderContext)!;
    final dynamic currentPass = renderContextData['currentPass'];
    
    if (currentPass != null) {
      final dynamic vp = renderContext.viewportValue;
      currentPass.setViewport(vp.x, vp.y, vp.width, vp.height, vp.minDepth, vp.maxDepth);
    }
  }

  /// Updates the scissor with the values from the given render context.
  void updateScissor(RenderContext renderContext) {
    final Map<dynamic,dynamic> renderContextData = this.get(renderContext)!;
    final dynamic currentPass = renderContextData['currentPass'];
    
    if (currentPass != null) {
      final dynamic sc = renderContext.scissorValue;
      currentPass.setScissorRect(sc.x, sc.y, sc.width, sc.height);
    }
  }

  /// Returns the clear color and alpha into a single color object.
  @override
  Color? getClearColor() {
    final Color? clearColor = super.getClearColor();

    // Only premultiply alpha when alphaMode is configured as "premultiplied"
    if (clearColor != null && this.renderer?.alpha == true) {
      clearColor.red *= clearColor.alpha;
      clearColor.green *= clearColor.alpha;
      clearColor.blue *= clearColor.alpha;
    }
    
    return clearColor;
  }

  /// Performs a clear operation.
  /// 
  /// [color] - Whether the color buffer should be cleared or not.
  /// [depth] - Whether the depth buffer should be cleared or not.
  /// [stencil] - Whether the stencil buffer should be cleared or not.
  /// [renderTargetContext] - The render context of the current set render target.
  void clear(bool color, bool depth, bool stencil, [dynamic renderTargetContext = null]) {
    final dynamic renderer = this.renderer;
    List<dynamic> colorAttachments = [];
    dynamic depthStencilAttachment;
    bool supportsDepth = false;
    bool supportsStencil = false;

    if (color == true) {
      final dynamic clearColor = this.getClearColor();
      _clearValue['r'] = clearColor.r;
      _clearValue['g'] = clearColor.g;
      _clearValue['b'] = clearColor.b;
      _clearValue['a'] = clearColor.a;
    }

    if (renderTargetContext == null) {
      supportsDepth = renderer.depth == true;
      supportsStencil = renderer.stencil == true;
      final dynamic descriptor = this._getDefaultRenderPassDescriptor();

      if (color == true) {
        colorAttachments = descriptor.colorAttachments;
        final dynamic colorAttachment = colorAttachments[0];
        colorAttachment.clearValue = _clearValue;
        colorAttachment.loadOp = GpuLoadOp.clear;
        colorAttachment.storeOp = GpuStoreOp.store;
      }

      if (supportsDepth || supportsStencil) {
        depthStencilAttachment = descriptor.depthStencilAttachment;
      }
    } else {
      supportsDepth = renderTargetContext.depth == true;
      supportsStencil = renderTargetContext.stencil == true;

      final Map<String, dynamic> clearConfig = {
        'loadOp': color ? GpuLoadOp.clear : GpuLoadOp.load,
        'clearValue': color ? _clearValue : null
      };

      if (supportsDepth) {
        clearConfig['depthLoadOp'] = depth ? GpuLoadOp.clear : GpuLoadOp.load;
        clearConfig['depthClearValue'] = depth ? renderer.getClearDepth() : null;
        clearConfig['depthStoreOp'] = GpuStoreOp.store;
      }

      if (supportsStencil) {
        clearConfig['stencilLoadOp'] = stencil ? GpuLoadOp.clear : GpuLoadOp.load;
        clearConfig['stencilClearValue'] = stencil ? renderer.getClearStencil() : null;
        clearConfig['stencilStoreOp'] = GpuStoreOp.store;
      }

      final dynamic descriptor = this._getRenderPassDescriptor(renderTargetContext, clearConfig);
      colorAttachments = descriptor.colorAttachments;
      depthStencilAttachment = descriptor.depthStencilAttachment;
    }

    if (supportsDepth && depthStencilAttachment != null) {
      if (depth == true) {
        depthStencilAttachment.depthLoadOp = GpuLoadOp.clear;
        depthStencilAttachment.depthClearValue = renderer.getClearDepth();
        depthStencilAttachment.depthStoreOp = GpuStoreOp.store;
      } else {
        depthStencilAttachment.depthLoadOp = GpuLoadOp.load;
        depthStencilAttachment.depthStoreOp = GpuStoreOp.store;
      }
    }

    if (supportsStencil && depthStencilAttachment != null) {
      if (stencil == true) {
        depthStencilAttachment.stencilLoadOp = GpuLoadOp.clear;
        depthStencilAttachment.stencilClearValue = renderer.getClearStencil();
        depthStencilAttachment.stencilStoreOp = GpuStoreOp.store;
      } else {
        depthStencilAttachment.stencilLoadOp = GpuLoadOp.load;
        depthStencilAttachment.stencilStoreOp = GpuStoreOp.store;
      }
    }

    final dynamic encoder = device.createCommandEncoder(_commandEncoderDescriptor);
    _commandEncoderDescriptor.reset();

    final dynamic currentPass = encoder.beginRenderPass({
      'colorAttachments': colorAttachments,
      'depthStencilAttachment': depthStencilAttachment
    });
    currentPass.end();

    submit(device, encoder.finish());
  }

  /// This method is executed at the beginning of a compute call and
  /// prepares the state for upcoming compute tasks.
  /// 
  /// [computeGroup] - The compute node(s).
  void beginCompute(List<Node> computeGroup) {
    // Utilizing direct map bracket directives instead of this.get()
    final Map<dynamic,dynamic> groupGPU = this.get(computeGroup)!; 
    final String label = 'computeGroup_${computeGroup.id}';
    
    _computePassDescriptor.label = label;
    _commandEncoderDescriptor.label = label;
    
    this.initTimestampQuery(Constants.timestampQuery, this.getTimestampUID(computeGroup), _computePassDescriptor);
    
    groupGPU['cmdEncoderGPU'] = this.device.createCommandEncoder(_commandEncoderDescriptor);
    groupGPU['passEncoderGPU'] = groupGPU['cmdEncoderGPU'].beginComputePass(_computePassDescriptor);
    
    _commandEncoderDescriptor.reset();
    _computePassDescriptor.reset();
  }

  /// Executes a compute command for the given compute node.
  void compute(
    List<Node> computeGroup, 
    Node computeNode, 
    List<BindGroup> bindings, 
    ComputePipeline pipeline, 
    [dynamic dispatchSize]
  ) {
    // Utilizing direct map bracket directives instead of this.get()
    final Map<dynamic,dynamic> computeNodeData = this.get(computeNode)!;
    final Map<dynamic,dynamic> computeGroupData = this.get(computeGroup)!;
    final dynamic passEncoderGPU = computeGroupData['passEncoderGPU'];

    // Pipeline allocation resolution
    final dynamic pipelineGPU = this.get(pipeline)?['pipeline'];
    this.pipelineUtils.setPipeline(passEncoderGPU, pipelineGPU);

    // Bind groups mapping loop
    for (int i = 0, l = bindings.length; i < l; i++) {
      final dynamic bindGroup = bindings[i];
      final dynamic bindingsData = this.get(bindGroup);
      passEncoderGPU.setBindGroup(i, bindingsData?['group']);
    }

    if (dispatchSize == null) {
      dispatchSize = computeNode.dispatchSize ?? computeNode.count;
    }

    // When the dispatchSize is loaded with a StorageBuffer directly from GPU memory context
    if (dispatchSize != null && dispatchSize is IndirectStorageBufferAttribute == true) {
      final Map<dynamic,dynamic> dispatchBuffer = this.get(dispatchSize)?['buffer'];
      passEncoderGPU.dispatchWorkgroupsIndirect(dispatchBuffer, 0);
      return;
    }

    if (dispatchSize is num) {
      // If a single number is given, calculate the dispatch size based on the workgroup dimensions
      final int count = dispatchSize.toInt();
      
      if (computeNodeData['dispatchSize'] == null || computeNodeData['count'] != count) {
        // Cache dispatch size allocations to avoid recalculating bounds every tick
        computeNodeData['dispatchSize'] = <int>[0, 1, 1];
        computeNodeData['count'] = count;
        
        final List<num> workgroupSize = computeNode.workgroupSize;
        int size = workgroupSize[0].toInt();
        
        for (int i = 1; i < workgroupSize.length; i++) {
          size *= workgroupSize[i].toInt();
        }
        
        // Native ceiling alignment math calculation
        final int dispatchCount = (count / size).ceil();
        final int maxComputeWorkgroupsPerDimension = this.device.limits.maxComputeWorkgroupsPerDimension;
        
        List<int> calculationSize = [dispatchCount, 1, 1];
        
        if (dispatchCount > maxComputeWorkgroupsPerDimension) {
          calculationSize[0] = dispatchCount < maxComputeWorkgroupsPerDimension ? dispatchCount : maxComputeWorkgroupsPerDimension;
          calculationSize[1] = (dispatchCount / maxComputeWorkgroupsPerDimension).ceil();
        }
        
        computeNodeData['dispatchSize'] = calculationSize;
      }
      
      dispatchSize = computeNodeData['dispatchSize'];
    }

    // Run compute pass dispatch routines on hardware pipelines
    passEncoderGPU.dispatchWorkgroups(
      dispatchSize[0].toInt(), 
      dispatchSize.length > 1 ? dispatchSize[1].toInt() : 1, 
      dispatchSize.length > 2 ? dispatchSize[2].toInt() : 1
    );
  }

  /// This method is executed at the end of a compute call and
  /// finalizes work after compute tasks.
  void finishCompute(List<Node> computeGroup) {
    // Utilizing direct map bracket directives instead of this.get()
    final dynamic groupData = this.get(computeGroup)!;
    
    groupData['passEncoderGPU'].end();
    submit(this.device, groupData['cmdEncoderGPU'].finish());
  }

  /// Internal draw function that performs the draw with the given pass encoder.
  void _draw(
    dynamic renderObject, 
    dynamic info, 
    dynamic renderContextData, 
    dynamic pipelineGPU, 
    List<dynamic> bindings, 
    List<dynamic> vertexBuffers, 
    Map<String, dynamic> drawParams, 
    dynamic passEncoderGPU, 
    dynamic currentSets
  ) {
    // Replaces JavaScript object destructuring with standard variable assignments
    final dynamic object = renderObject.object;
    final dynamic material = renderObject.material;
    final dynamic context = renderObject.context;

    final dynamic index = renderObject.getIndex();
    final bool hasIndex = (index != null);

    // Pipeline binding allocations
    this.pipelineUtils.setPipeline(passEncoderGPU, pipelineGPU);
    currentSets['pipeline'] = pipelineGPU;

    // Bind groups mapping loop
    final List<dynamic> currentBindingGroups = currentSets['bindingGroups'];
    for (int i = 0, l = bindings.length; i < l; i++) {
      final dynamic bindGroup = bindings[i];
      // Utilizing direct map bracket directive instead of this.get()
      final dynamic bindingsData = this.get(bindGroup); 
      
      if (currentBindingGroups[i] != bindGroup.id) {
        passEncoderGPU.setBindGroup(i, bindingsData['group']);
        currentBindingGroups[i] = bindGroup.id;
      }
    }

    // Index buffer configurations
    if (hasIndex == true) {
      if (currentSets['index'] != index) {
        final dynamic buffer = this.get(index)?['buffer'];
        
        // Check backing element type natively using Dart typed data array signatures
        final GpuIndexFormat indexFormat = (index.array is Uint16List) 
            ? GpuIndexFormat.uint16 
            : GpuIndexFormat.uint32;
            
        passEncoderGPU.setIndexBuffer(buffer, indexFormat);
        currentSets['index'] = index;
      }
    }

    // Vertex attributes compilation binding pipeline loop
    for (int i = 0, l = vertexBuffers.length; i < l; i++) {
      final dynamic vertexBuffer = vertexBuffers[i];
      if (currentSets['attributes'][i] != vertexBuffer) {
        final dynamic buffer = this.get(vertexBuffer)?['buffer'];
        passEncoderGPU.setVertexBuffer(i, buffer);
        currentSets['attributes'][i] = vertexBuffer;
      }
    }

    // Stencil pipeline tracking logic evaluation
    if (context.stencil == true && 
        material.stencilWrite == true && 
        renderContextData['currentStencilRef'] != material.stencilRef) {
      passEncoderGPU.setStencilReference(material.stencilRef);
      renderContextData['currentStencilRef'] = material.stencilRef;
    }

    // Batched mesh execution pipeline paths handling
    if (object.isBatchedMesh == true) {
      final List<int> starts = object._multiDrawStarts;
      final List<int> counts = object._multiDrawCounts;
      final int drawCount = object._multiDrawCount;
      
      // Determine bytes per element size configuration
      int bytesPerElement = (hasIndex == true) ? index.array.elementSizeInBytes : 1;
      
      if (material.wireframe == true) {
        bytesPerElement = (object.geometry.attributes.position.count > 65535) ? 4 : 2;
      }

      for (int i = 0; i < drawCount; i++) {
        if (hasIndex == true) {
          passEncoderGPU.drawIndexed(counts[i], 1, (starts[i] / bytesPerElement).floor(), 0, i);
        } else {
          passEncoderGPU.draw(counts[i], 1, starts[i], i);
        }
        info.update(object, counts[i], 1);
      }
    } 
    // Standard Indexed Geometry extraction drawing execution paths
    else if (hasIndex == true) {
      final int indexCount = drawParams['vertexCount'] ?? 0;
      final int instanceCount = drawParams['instanceCount'] ?? 1;
      final int firstIndex = drawParams['firstVertex'] ?? 0;
      
      final dynamic indirect = renderObject.getIndirect();
      
      if (indirect != null) {
        final dynamic buffer = this.get(indirect)?['buffer'];
        final dynamic indirectOffset = renderObject.getIndirectOffset();
        final List<dynamic> indirectOffsets = (indirectOffset is List) ? indirectOffset : [indirectOffset];
        
        for (int i = 0; i < indirectOffsets.length; i++) {
          passEncoderGPU.drawIndexedIndirect(buffer, indirectOffsets[i]);
        }
      } else {
        passEncoderGPU.drawIndexed(indexCount, instanceCount, firstIndex, 0, 0);
      }
      info.update(object, indexCount, instanceCount);
    } 
    // Non-Indexed base draw coordinate geometry extraction paths
    else {
      final int vertexCount = drawParams['vertexCount'] ?? 0;
      final int instanceCount = drawParams['instanceCount'] ?? 1;
      final int firstVertex = drawParams['firstVertex'] ?? 0;
      
      final dynamic indirect = renderObject.getIndirect();
      
      if (indirect != null) {
        final dynamic buffer = this.get(indirect)?['buffer'];
        final dynamic indirectOffset = renderObject.getIndirectOffset();
        final List<dynamic> indirectOffsets = (indirectOffset is List) ? indirectOffset : [indirectOffset];
        
        for (int i = 0; i < indirectOffsets.length; i++) {
          passEncoderGPU.drawIndirect(buffer, indirectOffsets[i]);
        }
      } else {
        passEncoderGPU.draw(vertexCount, instanceCount, firstVertex, 0);
      }
      info.update(object, vertexCount, instanceCount);
    }
  }

  /// Executes a draw command for the given render object.
  /// 
  /// [renderObject] - The render object to draw.
  /// [info] - Holds a series of statistical information about the GPU memory and the rendering process.
  void draw(RenderObject renderObject, Info info) {
    // Replacing JavaScript object destructuring with standard property extraction
    final dynamic object = renderObject.object;
    final dynamic context = renderObject.context;
    final dynamic pipeline = renderObject.pipeline;

    // Utilizing direct map bracket directives instead of this.get()
    final dynamic renderContextData = this.get(context); 
    final dynamic pipelineData = this.get(pipeline);
    final dynamic pipelineGPU = pipelineData?['pipeline'];

    // Skip if pipeline has compilation or device verification faults
    if (pipelineData?['error'] == true) return;

    final dynamic drawParams = renderObject.getDrawParameters();
    if (drawParams == null) return;

    final List<dynamic> bindings = renderObject.getBindings() ?? [];
    final List<dynamic> vertexBuffers = renderObject.getVertexBuffers() ?? [];

    // Multi-Camera array execution branch pipeline path
    if (renderObject.camera is ArrayCamera == true && (renderObject.camera as ArrayCamera).cameras.length > 0) {
      final dynamic cameraData = this.get(renderObject.camera);
      final List<Camera> cameras = (renderObject.camera as ArrayCamera).cameras;
      final dynamic cameraIndex = renderObject.getBindingGroup('cameraIndex');

      if (cameraData?['indexesGPU'] == null || cameraData['indexesGPU'].length != cameras.length) {
        final dynamic bindingsData = this.get(cameraIndex);
        final List<dynamic> indexesGPU = [];
        
        // Map Uint32Array to native Uint32List structure
        final Uint32List data = Uint32List.fromList([0, 0, 0, 0]);

        for (int i = 0, len = cameras.length; i < len; i++) {
          data[0] = i;
          final dynamic layoutGPU = bindingsData?['layout']?['layoutGPU'];
          final dynamic bindGroupIndex = this.bindingUtils.createBindGroupIndex(data, layoutGPU);
          indexesGPU.add(bindGroupIndex);
        }
        cameraData['indexesGPU'] = indexesGPU;
      }

      final double pixelRatio = this.renderer!.getPixelRatio().toDouble();

      for (int i = 0, len = cameras.length; i < len; i++) {
        final Camera subCamera = cameras[i];
        
        if (object.layers.test(subCamera.layers) == true) {
          final Vector4 vp = subCamera.viewport!;
          dynamic pass = renderContextData['currentPass'];
          dynamic sets = renderContextData['currentSets'];
          
          final bool isBundleEncoder = renderContextData['bundleEncoders'] != null;
          if (isBundleEncoder) {
            pass = renderContextData['bundleEncoders'][i];
            sets = renderContextData['bundleSets'][i];
          }

          // GPURenderBundleEncoder does not support setViewport, only GPURenderPassEncoder does
          if (vp != null && !isBundleEncoder) {
            pass.setViewport(
              (vp.x * pixelRatio).floor(),
              (vp.y * pixelRatio).floor(),
              (vp.width * pixelRatio).floor(),
              (vp.height * pixelRatio).floor(),
              context.viewportValue.minDepth,
              context.viewportValue.maxDepth
            );
          }

          // Set camera index binding for this multi-layer sub-camera pass
          if (cameraIndex != null && cameraData['indexesGPU'] != null) {
            final int indexPos = bindings.indexOf(cameraIndex);
            if (indexPos != -1) {
              pass.setBindGroup(indexPos, cameraData['indexesGPU'][i]);
              sets['bindingGroups'][indexPos] = cameraIndex.id;
            }
          }

          this._draw(renderObject, info, renderContextData, pipelineGPU, bindings, vertexBuffers, drawParams, pass, sets);
        }
      }
    } 
    // Regular single camera rendering deployment path
    else {
      if (renderContextData['currentPass'] != null) {
        
        // Handle Occlusion Query metrics tracking layers
        if (renderContextData['occlusionQuerySet'] != null) {
          final dynamic lastObject = renderContextData['lastOcclusionObject'];
          
          if (lastObject != object) {
            if (lastObject != null && lastObject.occlusionTest == true) {
              renderContextData['currentPass'].endOcclusionQuery();
              renderContextData['occlusionQueryIndex'] = (renderContextData['occlusionQueryIndex'] ?? 0) + 1;
            }
            
            if (object.occlusionTest == true) {
              final int currentIndex = renderContextData['occlusionQueryIndex'] ?? 0;
              renderContextData['currentPass'].beginOcclusionQuery(currentIndex);
              renderContextData['occlusionQueryObjects'][currentIndex] = object;
            }
            
            renderContextData['lastOcclusionObject'] = object;
          }
        }

        this._draw(renderObject, info, renderContextData, pipelineGPU, bindings, vertexBuffers, drawParams, renderContextData['currentPass'], renderContextData['currentSets']);
      }
    }
  }

  /// Returns `true` if the render pipeline requires an update.
  bool needsRenderUpdate(RenderObject renderObject) {
    // Utilizing direct map bracket directive instead of this.get()
    final Map data = this.get(renderObject)!; 
    final Object3D object = renderObject.object;
    final Material material = renderObject.material;
    final dynamic utils = this.utils;

    final int sampleCount = utils.getSampleCountRenderContext(renderObject.context);
    final dynamic colorSpace = utils.getCurrentColorSpace(renderObject.context);
    final dynamic colorFormat = utils.getCurrentColorFormat(renderObject.context);
    final dynamic depthStencilFormat = utils.getCurrentDepthStencilFormat(renderObject.context);
    final dynamic primitiveTopology = utils.getPrimitiveTopology(object, material);
    
    bool needsUpdate = false;

    // Evaluates backend memory track footprints directly via bracket key index structures
    if (data['material'] != material ||
        data['materialVersion'] != material.version ||
        data['transparent'] != material.transparent ||
        data['blending'] != material.blending ||
        data['premultipliedAlpha'] != material.premultipliedAlpha ||
        data['blendSrc'] != material.blendSrc ||
        data['blendDst'] != material.blendDst ||
        data['blendEquation'] != material.blendEquation ||
        data['blendSrcAlpha'] != material.blendSrcAlpha ||
        data['blendDstAlpha'] != material.blendDstAlpha ||
        data['blendEquationAlpha'] != material.blendEquationAlpha ||
        data['colorWrite'] != material.colorWrite ||
        data['depthWrite'] != material.depthWrite ||
        data['depthTest'] != material.depthTest ||
        data['depthFunc'] != material.depthFunc ||
        data['stencilWrite'] != material.stencilWrite ||
        data['stencilFunc'] != material.stencilFunc ||
        data['stencilFail'] != material.stencilFail ||
        data['stencilZFail'] != material.stencilZFail ||
        data['stencilZPass'] != material.stencilZPass ||
        data['stencilFuncMask'] != material.stencilFuncMask ||
        data['stencilWriteMask'] != material.stencilWriteMask ||
        data['side'] != material.side ||
        data['alphaToCoverage'] != material.alphaToCoverage ||
        data['sampleCount'] != sampleCount ||
        data['colorSpace'] != colorSpace ||
        data['colorFormat'] != colorFormat ||
        data['depthStencilFormat'] != depthStencilFormat ||
        data['primitiveTopology'] != primitiveTopology ||
        data['clippingContextCacheKey'] != renderObject.clippingContextCacheKey) {
        
      data['material'] = material;
      data['materialVersion'] = material.version;
      data['transparent'] = material.transparent;
      data['blending'] = material.blending;
      data['premultipliedAlpha'] = material.premultipliedAlpha;
      data['blendSrc'] = material.blendSrc;
      data['blendDst'] = material.blendDst;
      data['blendEquation'] = material.blendEquation;
      data['blendSrcAlpha'] = material.blendSrcAlpha;
      data['blendDstAlpha'] = material.blendDstAlpha;
      data['blendEquationAlpha'] = material.blendEquationAlpha;
      data['colorWrite'] = material.colorWrite;
      data['depthWrite'] = material.depthWrite;
      data['depthTest'] = material.depthTest;
      data['depthFunc'] = material.depthFunc;
      data['stencilWrite'] = material.stencilWrite;
      data['stencilFunc'] = material.stencilFunc;
      data['stencilFail'] = material.stencilFail;
      data['stencilZFail'] = material.stencilZFail;
      data['stencilZPass'] = material.stencilZPass;
      data['stencilFuncMask'] = material.stencilFuncMask;
      data['stencilWriteMask'] = material.stencilWriteMask;
      data['side'] = material.side;
      data['alphaToCoverage'] = material.alphaToCoverage;
      data['sampleCount'] = sampleCount;
      data['colorSpace'] = colorSpace;
      data['colorFormat'] = colorFormat;
      data['depthStencilFormat'] = depthStencilFormat;
      data['primitiveTopology'] = primitiveTopology;
      data['clippingContextCacheKey'] = renderObject.clippingContextCacheKey;
      
      needsUpdate = true;
    }

    return needsUpdate;
  }

  /// Returns a cache key that is used to identify render pipelines.
  String getRenderCacheKey(RenderObject renderObject) {
    final dynamic object = renderObject.object;
    final dynamic material = renderObject.material;
    final dynamic utils = this.utils;
    final dynamic renderContext = renderObject.context;

    // Meshes with negative scale have a different frontFace render pipeline
    // descriptor value so the following must be honored in the cache key.
    final bool frontFaceCW = (object.isMesh == true && object.matrixWorld.determinant() < 0);

    // Flattens parameter tracks straight into a concatenated unique matching string signature profile
    return [
      material.transparent,
      material.blending,
      material.premultipliedAlpha,
      material.blendSrc,
      material.blendDst,
      material.blendEquation,
      material.blendSrcAlpha,
      material.blendDstAlpha,
      material.blendEquationAlpha,
      material.colorWrite,
      material.depthWrite,
      material.depthTest,
      material.depthFunc,
      material.stencilWrite,
      material.stencilFunc,
      material.stencilFail,
      material.stencilZFail,
      material.stencilZPass,
      material.stencilFuncMask,
      material.stencilWriteMask,
      material.side,
      frontFaceCW,
      utils.getSampleCountRenderContext(renderContext),
      utils.getCurrentColorSpace(renderContext),
      utils.getCurrentColorFormat(renderContext),
      utils.getCurrentDepthStencilFormat(renderContext),
      utils.getPrimitiveTopology(object, material),
      renderObject.getGeometryCacheKey(),
      renderObject.clippingContextCacheKey
    ].join(','); // Join explicitly with a comma separator string criteria matching original JS output
  }

  /// Updates a GPU sampler for the given texture.
  /// 
  /// Returns the current sampler key [String].
  String updateSampler(dynamic texture, dynamic textureNode) {
    return this.textureUtils.updateSampler(texture, textureNode);
  }

  /// Creates a default texture for the given texture that can be used
  /// as a placeholder until the actual texture is ready for usage.
  /// 
  /// Returns `true` if the sampler has been updated successfully.
  void createDefaultTexture(Texture texture) {
    return this.textureUtils.createDefaultTexture(texture);
  }

  /// Defines a texture on the GPU for the given texture object.
  /// 
  /// [options] - Optional configuration parameters map layer.
  void createTexture(dynamic texture, [Map<String, dynamic>? options]) {
    this.textureUtils.createTexture(texture, options ?? {});
  }

  /// Uploads the updated texture data to the GPU.
  /// 
  /// [options] - Optional configuration parameters map layer.
  void updateTexture(dynamic texture, [Map<String, dynamic>? options]) {
    this.textureUtils.updateTexture(texture, options ?? {});
  }

  /// Generates mipmaps for the given texture.
  void generateMipmaps(dynamic texture) {
    this.textureUtils.generateMipmaps(texture);
  }

  /// Destroys the GPU data for the given texture object.
  /// 
  /// [isDefaultTexture] - Whether the texture uses a default GPU texture or not.
  void destroyTexture(Texture texture, [bool isDefaultTexture = false]) {
    this.textureUtils.destroyTexture(texture, isDefaultTexture);
  }

  /// Returns texture data as a typed array view.
  /// 
  /// Returns a [Future] that resolves with the backing buffer data when the copy operation has finished.
  Future<TypedData> copyTextureToBuffer(
    Texture texture, 
    double x, 
    double y, 
    double width, 
    double height, 
    int faceIndex
  ) async {
    return await this.textureUtils.copyTextureToBuffer(texture, x, y, width, height, faceIndex);
  }

  /// Inits a time stamp query for the given render context.
  /// 
  /// [type] - The type of the timestamp query (e.g. 'render', 'compute').
  /// [uid] - Unique id for the context (e.g. render context id).
  /// [descriptor] - The query descriptor.
  void initTimestampQuery(String type, int uid, dynamic descriptor) {
    if (this.trackTimestamp != true) return;
    
    // Check if the query pool maps contain the specified type key
    if (this.timestampQueryPool[type] == null) {
      this.timestampQueryPool[type] = WebGPUTimestampQueryPool(this.device, type, 2048);
    }

    final dynamic timestampQueryPool = this.timestampQueryPool[type];
    final int baseOffset = timestampQueryPool.allocateQueriesForContext(uid);

    _renderPassTimestampWrites.querySet = timestampQueryPool.querySet;
    _renderPassTimestampWrites.beginningOfPassWriteIndex = baseOffset;
    _renderPassTimestampWrites.endOfPassWriteIndex = baseOffset + 1;

    descriptor.timestampWrites = _renderPassTimestampWrites;
  }

  // Node Builder

  /// Returns a node builder for the given render object.
  /// 
  /// Returns a new [WGSLNodeBuilder] instance context.
  WGSLNodeBuilder createNodeBuilder(Object3D object, Renderer renderer) {
    return WGSLNodeBuilder(object, renderer);
  }

  // Program

  /// Creates a shader program module from the given programmable stage block.
  void createProgram(ProgrammableStage program) {
    // Utilizing direct map bracket directive instead of this.get()
    final Map programGPU = this.get(program)!; 
    
    final String labelSuffix = (program.name != '') ? '_${program.name}' : '';
    _shaderModuleDescriptor.label = '${program.stage}$labelSuffix';
    _shaderModuleDescriptor.code = program.code;

    programGPU['module'] = {
      'module': this.device.createShaderModule(_shaderModuleDescriptor),
      'entryPoint': 'main'
    };

    _shaderModuleDescriptor.reset();
  }

  /// Destroys the shader program of the given programmable stage.
  void destroyProgram(ProgrammableStage program) {
    // Replaces this.delete(program) with native Dart Map element extraction removal
    this._backendStateCache.remove(program);
  }

  // Pipelines

  /// Creates a render pipeline for the given render object.
  /// 
  /// [promises] - An array of compilation futures which are evaluated in `compileAsync()`.
  void createRenderPipeline(RenderObject renderObject, [List<Future<dynamic>>? promises]) {
    this.pipelineUtils.createRenderPipeline(renderObject, promises);
  }

  /// Creates a compute pipeline for the given compute node.
  /// 
  /// [bindings] - The configuration target bind groups.
  void createComputePipeline(dynamic computePipeline, List<dynamic> bindings) {
    this.pipelineUtils.createComputePipeline(computePipeline, bindings);
  }

  /// Prepares the state for encoding render bundles.
  void beginBundle(dynamic renderContext) {
    // Utilizing direct map bracket directive instead of this.get()
    final Map renderContextData = this.get(renderContext)!; 
    
    renderContextData['_currentPass'] = renderContextData['currentPass'];
    renderContextData['_currentSets'] = renderContextData['currentSets'];
    
    // Clear and instantiate fresh structural set tracks inside state caches
    renderContextData['currentSets'] = {
      'attributes': <String, dynamic>{},
      'bindingGroups': <dynamic>[],
      'pipeline': null,
      'index': null
    };
    
    renderContextData['currentPass'] = this.pipelineUtils.createBundleEncoder(renderContext);
  }

  /// After processing render bundles this method finalizes related work.
  /// 
  /// [bundle] - The render bundle output container.
  void finishBundle(RenderContext renderContext, dynamic bundle) {
    final dynamic renderContextData = this.get(renderContext); 
    final dynamic bundleEncoder = renderContextData['currentPass'];
    final dynamic bundleGPU = bundleEncoder.finish();
    
    // Cache the completed hardware layout bundle via map bracket assignments
    this.get(bundle)?['bundleGPU'] = bundleGPU; 
    
    // Restore the underlying active parent render pass pipeline configurations state
    renderContextData['currentSets'] = renderContextData['_currentSets'];
    renderContextData['currentPass'] = renderContextData['_currentPass'];
  }

  /// Adds a render bundle to the render context data.
  void addBundle(RenderContext renderContext, dynamic bundle) {
    // Utilizing direct map bracket directive instead of this.get()
    final dynamic renderContextData = this.get(renderContext);
    
    // Extract hardware bundle reference using bracket mapping notation
    final dynamic bundleGPU = this.get(bundle)?['bundleGPU'];
    
    if (renderContextData?['renderBundles'] != null && bundleGPU != null) {
      renderContextData['renderBundles'].add(bundleGPU);
    }
  }

  // Bindings

  /// Creates a uniform buffer.
  /// 
  /// [uniformBuffer] - The uniform buffer payload structure.
  void createUniformBuffer(dynamic uniformBuffer) {
    final dynamic uniformBufferData = this.get(uniformBuffer);

    if (uniformBufferData?['buffer'] == null) {
      final int byteLength = uniformBuffer.byteLength;
      
      // WebGPU binding parameters format mask matching gpux specifications
      final int usage = GpuBufferUsage.uniform | GpuBufferUsage.copyDst;
      final List<String> visibilities = [];

      // Perform standard bitwise AND comparisons against stage flags
      final int visibility = uniformBuffer.visibility ?? 0;
      
      if ((visibility & GPUShaderStage.vertex) != 0) {
        visibilities.add('vertex');
      }
      if ((visibility & GPUShaderStage.fragment) != 0) {
        visibilities.add('fragment');
      }
      if ((visibility & GPUShaderStage.compute) != 0) {
        visibilities.add('compute');
      }

      final String bufferVisibility = '(${visibilities.join(',')})';
      _bufferDescriptor.label = 'bindingBuffer${uniformBuffer.id}_${uniformBuffer.name}_$bufferVisibility';
      _bufferDescriptor.size = byteLength;
      _bufferDescriptor.usage = usage;

      final dynamic bufferGPU = this.device.createBuffer(_bufferDescriptor);
      _bufferDescriptor.reset();

      uniformBufferData['buffer'] = bufferGPU;
    }
  }

  /// Destroys the GPU data for the given uniform buffer.
  void destroyUniformBuffer(dynamic uniformBuffer) {
    final dynamic uniformBufferData = this.get(uniformBuffer);
    
    if (uniformBufferData?['buffer'] != null) {
      uniformBufferData['buffer'].destroy();
    }
    
    // Utilize native Dart cache removal following map instructions strategy
    this._backendStateCache.remove(uniformBuffer);
  }

  // Bindings

  /// Creates bindings from the given bind group definition.
  void createBindings(BindGroup bindGroup, List<BindGroup> bindings, int cacheIndex,[int? version ]) {
    this.bindingUtils.createBindings(bindGroup, bindings, cacheIndex, version ?? 0);
  }

  /// Updates the given bind group definition.
  void updateBindings(BindGroup bindGroup, List<BindGroup> bindings, int cacheIndex, int version) {
    this.bindingUtils.createBindings(bindGroup, bindings, cacheIndex, version);
  }

  /// Updates a buffer binding.
  void updateBinding(Buffer binding) {
    this.bindingUtils.updateBinding(binding);
  }

  /// Delete data associated with the current bind group.
  void deleteBindGroupData(BindGroup bindGroup) {
    this.bindingUtils.deleteBindGroupData(bindGroup);
  }

  // Attributes

  /// Creates the buffer of an indexed shader attribute.
  void createIndexAttribute(dynamic attribute) {
    int usage = GpuBufferUsage.index | GpuBufferUsage.copySrc | GpuBufferUsage.copyDst;
    
    if (attribute is StorageBufferAttribute == true || attribute is StorageInstancedBufferAttribute == true) {
      // Standard bitwise OR operation assignment masks mapping
      usage |= GpuBufferUsage.storage;
    }
    
    this.attributeUtils.createAttribute(attribute, usage);
  }

  /// Creates the GPU buffer of a shader attribute.
  void createAttribute(dynamic attribute) {
    this.attributeUtils.createAttribute(
      attribute, 
      GpuBufferUsage.vertex | GpuBufferUsage.copySrc | GpuBufferUsage.copyDst
    );
  }

  /// Creates the GPU buffer of a storage attribute.
  void createStorageAttribute(dynamic attribute) {
    this.attributeUtils.createAttribute(
      attribute, 
      GpuBufferUsage.storage | GpuBufferUsage.vertex | GpuBufferUsage.copySrc | GpuBufferUsage.copyDst
    );
  }

  /// Creates the GPU buffer of an indirect storage attribute.
  void createIndirectStorageAttribute(dynamic attribute) {
    this.attributeUtils.createAttribute(
      attribute, 
      GpuBufferUsage.storage | GpuBufferUsage.indirect | GpuBufferUsage.copySrc | GpuBufferUsage.copyDst
    );
  }

  /// Updates the GPU buffer of a shader attribute.
  void updateAttribute(dynamic attribute) {
    this.attributeUtils.updateAttribute(attribute);
  }

  /// Destroys the GPU buffer of a shader attribute.
  void destroyAttribute(dynamic attribute) {
    this.attributeUtils.destroyAttribute(attribute);
  }

  // Canvas

  /// Triggers an update of the default render pass descriptor.
  void updateSize() {
    // Replaces this.delete() with direct internal state dictionary map removal
    this._backendStateCache.remove(this.renderer?.getCanvasTarget());
  }

  // Utils

  /// Checks if the given feature is supported by the backend.
  /// 
  /// Returns `true` if the hardware feature is fully supported.
  bool hasFeature(GpuFeatureName name) {
    GpuFeatureName featureName = name;
    
    // Check global constant property map trackers natively using bracket access
    if (GpuFeatureMap[name] != null) {
      featureName = GpuFeatureMap[name]!;
    }
    
    return this.device.features.has(featureName);
  }

  /// Copies data of the given source texture to the given destination texture.
  /// 
  /// [srcTexture] - The source texture.
  /// [dstTexture] - The destination texture.
  /// [srcRegion] - The region of the source texture to copy (Box3 or Box2).
  /// [dstPosition] - The destination position of the copy (Vector3 or Vector2).
  /// [srcLevel] - The mipmap level to copy.
  /// [dstLevel] - The destination mip level to copy to.
  void copyTextureToTexture(
    Texture srcTexture, 
    Texture dstTexture, [
    BoundingBox? srcRegion, 
    Vector? dstPosition, 
    int srcLevel = 0, 
    int dstLevel = 0 
  ]) {
    double dstX = 0;
    double dstY = 0;
    double dstZ = 0;
    double srcX = 0;
    double srcY = 0;
    double srcZ = 0;
    
    int srcWidth = srcTexture.image.width.toInt();
    int srcHeight = srcTexture.image.height.toInt();
    int srcDepth = 1;

    if (srcRegion != null) {
      srcX = srcRegion.min.x;
      srcY = srcRegion.min.y;
      srcZ = srcRegion.min.z;
      srcWidth = (srcRegion.max.x - srcRegion.min.x).toInt();
      srcHeight = (srcRegion.max.y - srcRegion.min.y).toInt();
      srcDepth = (srcRegion.max.z - srcRegion.min.z).toInt();
    }

    if (dstPosition != null) {
      dstX = dstPosition.x;
      dstY = dstPosition.y;
      // Handle the fallback lookup calculation if z parameter does not exist on Vector2
      try {
        if(Vector is Vector3) dstZ = (dstPosition as Vector3).z;
      } catch (_) {
        dstZ = 0;
      }
    }

    _commandEncoderDescriptor.label = 'copyTextureToTexture_${srcTexture.id}_${dstTexture.id}';
    final dynamic encoder = this.device.createCommandEncoder(_commandEncoderDescriptor);
    _commandEncoderDescriptor.reset();

    // Utilizing direct map bracket directives instead of this.get()
    final dynamic sourceGPU = this.get(srcTexture)?['texture'];
    final dynamic destinationGPU = this.get(dstTexture)?['texture'];

    _texelCopyTextureInfoSrc.texture = sourceGPU;
    _texelCopyTextureInfoSrc.mipLevel = srcLevel;
    _texelCopyTextureInfoSrc.origin.x = srcX;
    _texelCopyTextureInfoSrc.origin.y = srcY;
    _texelCopyTextureInfoSrc.origin.z = srcZ;

    _texelCopyTextureInfoDst.texture = destinationGPU;
    _texelCopyTextureInfoDst.mipLevel = dstLevel;
    _texelCopyTextureInfoDst.origin.x = dstX;
    _texelCopyTextureInfoDst.origin.y = dstY;
    _texelCopyTextureInfoDst.origin.z = dstZ;

    _extent3D.width = srcWidth;
    _extent3D.height = srcHeight;
    _extent3D.depthOrArrayLayers = srcDepth;

    // Dispatches copy directives to WebGPU command recording encoder buffers
    encoder.copyTextureToTexture(_texelCopyTextureInfoSrc, _texelCopyTextureInfoDst, _extent3D);

    _texelCopyTextureInfoSrc.reset();
    _texelCopyTextureInfoDst.reset();
    _extent3D.reset();

    submit(this.device, encoder.finish());

    if (dstLevel == 0 && dstTexture.generateMipmaps == true) {
      this.textureUtils.generateMipmaps(dstTexture);
    }
  }

  /// Copies the current bound framebuffer to the given texture.
  /// 
  /// [texture] - The destination texture.
  /// [renderContext] - The render context.
  /// [rectangle] - A four dimensional vector defining the origin and dimension of the copy.
  void copyFramebufferToTexture(Texture texture, RenderContext renderContext, dynamic rectangle) {
    // Utilizing direct map bracket directives instead of this.get()
    final Map renderContextData = this.get(renderContext)!; 
    dynamic sourceGPU;

    if (renderContext.renderTarget == true) {
      if (texture is DepthTexture == true) {
        sourceGPU = this.get(renderContext.depthTexture)!['texture'];
      } else {
        sourceGPU = this.get(renderContext.textures![0])!['texture'];
      }
    } else {
      if (texture is DepthTexture == true) {
        sourceGPU = this.textureUtils.getDepthBuffer(renderContext.depth, renderContext.stencil);
      } else {
        sourceGPU = this.context.getCurrentTexture();
      }
    }

    final dynamic destinationGPU = this.get(texture)!['texture'];

    if (sourceGPU.format != destinationGPU.format) {
      // Replaces JavaScript error handler with three_js_core console logger
      console.error(
        'WebGPUBackend: copyFramebufferToTexture: Source and destination formats do not match. '
        'Source: ${sourceGPU.format}, Destination: ${destinationGPU.format}'
      );
      return;
    }

    dynamic encoder;
    if (renderContextData['currentPass'] != null) {
      renderContextData['currentPass'].end();
      encoder = renderContextData['encoder'];
    } else {
      _commandEncoderDescriptor.label = 'copyFramebufferToTexture_${texture.id}';
      encoder = this.device.createCommandEncoder(_commandEncoderDescriptor);
      _commandEncoderDescriptor.reset();
    }

    _texelCopyTextureInfoSrc.texture = sourceGPU;
    _texelCopyTextureInfoSrc.origin.x = rectangle.x.toInt();
    _texelCopyTextureInfoSrc.origin.y = rectangle.y.toInt();

    _texelCopyTextureInfoDst.texture = destinationGPU;

    _extent3D.width = rectangle.z.toInt();
    _extent3D.height = rectangle.w.toInt();

    encoder.copyTextureToTexture(_texelCopyTextureInfoSrc, _texelCopyTextureInfoDst, _extent3D);

    _texelCopyTextureInfoSrc.reset();
    _texelCopyTextureInfoDst.reset();
    _extent3D.reset();

    // Mipmaps must be generated with the same encoder otherwise the copied texture data
    // might be out-of-sync, see #31768
    if (texture.generateMipmaps == true) {
      this.textureUtils.generateMipmaps(texture, encoder);
    }

    if (renderContextData['currentPass'] != null) {
      final dynamic descriptor = renderContextData['descriptor'];
      final List<dynamic> colorAttachments = descriptor.colorAttachments;
      
      for (int i = 0; i < colorAttachments.length; i++) {
        colorAttachments[i].loadOp = GpuLoadOp.load;
      }

      if (renderContext.depth == true && descriptor.depthStencilAttachment != null) {
        descriptor.depthStencilAttachment.depthLoadOp = GpuLoadOp.load;
      }
      if (renderContext.stencil == true && descriptor.depthStencilAttachment != null) {
        descriptor.depthStencilAttachment.stencilLoadOp = GpuLoadOp.load;
      }

      renderContextData['currentPass'] = encoder.beginRenderPass(descriptor);
      
      renderContextData['currentSets'] = {
        'attributes': <String, dynamic>{},
        'bindingGroups': <dynamic>[],
        'pipeline': null,
        'index': null
      };

      if (renderContext.viewport == true) {
        this.updateViewport(renderContext);
      }
      if (renderContext.scissor == true) {
        this.updateScissor(renderContext);
      }
    } else {
      submit(this.device, encoder.finish());
    }
  }

  /// Checks if the given compatibility is supported by the backend.
  /// 
  /// Returns `true` if the compatibility aspect matches target hardware flags.
  @override
  bool hasCompatibility(String name) {
    if (this._compatibility[name] != null) {
      return this._compatibility[name]!;
    }
    return super.hasCompatibility(name);
  }

  /// Cleans up and releases all GPU resources, maps, query pools, 
  /// and device context memory structures held by the backend.
  @override
  void dispose() {
    this.bindingUtils.dispose();
    this.textureUtils.dispose();

    // Iterate and release all occlusion query resolution buffers cached in memory
    if (this.occludedResolveCache.isNotEmpty) {
      for (final dynamic buffer in this.occludedResolveCache.values) {
        if (buffer != null) {
          buffer.destroy();
        }
      }
      this.occludedResolveCache.clear();
    }

    // Clean up allocated timeline performance diagnostic query metric pools
    if (this.timestampQueryPool.isNotEmpty) {
      for (final dynamic queryPool in this.timestampQueryPool.values) {
        if (queryPool != null) {
          queryPool.dispose();
        }
      }
      this.timestampQueryPool.clear();
    }

    // Safely discard the core GPUDevice instance if it was created internally 
    // rather than provided as an external application parameter.
    if (this.parameters['device'] == null && this.device != null) {
      this.device.destroy();
      this.device = null;
    }

    // Reset the internal state backup cache map entirely
    this._backendStateCache.clear();
    
    console.info('WebGPUBackend: Framework pipeline context successfully disposed.');
    super.dispose();
  }
}
