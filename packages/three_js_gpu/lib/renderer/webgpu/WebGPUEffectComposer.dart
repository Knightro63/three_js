import 'package:gpux/gpux.dart'; // Adjust based on your exact gpux library paths
import '../../effects/FullScreenEffect.dart';
import '../../effects/FullScreenEffectPass.dart'; // To interface with FullScreenEffectPass, BlendMode, etc.

/// Manages a chain of WebGPU post-processing effects.
class WebGPUEffectComposer {
  final GpuDevice device;
  final GpuTextureFormat formatEnum;

  final List<FullScreenEffectPass> _passes = [];

  int _width;
  int _height;
  bool _isDisposed = false;
  bool _framebuffersInitialized = false;

  // Ping-pong textures and views for multi-pass rendering
  GpuTexture? _textureA;
  GpuTexture? _textureB;
  GpuTextureView? _viewA;
  GpuTextureView? _viewB;

  // Cached pipelines and resources per pass
  final Map<FullScreenEffectPass, GpuRenderPipeline> _pipelineCache = {};
  final Map<FullScreenEffectPass, GpuBindGroup> _bindGroupCache = {};
  final Map<FullScreenEffectPass, GpuBuffer> _uniformBufferCache = {};
  final Map<FullScreenEffectPass, GpuShaderModule> _shaderModuleCache = {};

  // Input texture bind group references
  GpuBindGroupLayout? _inputBindGroupLayoutA;
  GpuBindGroupLayout? _inputBindGroupLayoutB;
  GpuBindGroup? _inputBindGroupA;
  GpuBindGroup? _inputBindGroupB;
  GpuSampler? _inputSampler;

  WebGPUEffectComposer({
    required this.device,
    int width = 0,
    int height = 0,
    GpuTextureFormat format = GpuTextureFormat.bgra8Unorm,
  })  : _width = width,
        _height = height,
        formatEnum = format;

  /// Read-only list of all passes in the chain
  List<FullScreenEffectPass> get passes => List.unmodifiable(_passes);

  /// Number of passes in the chain
  int get passCount => _passes.length;

  /// Current width in pixels
  int get width => _width;

  /// Current height in pixels
  int get height => _height;

  /// Whether this composer has been disposed
  bool get isDisposed => _isDisposed;

  /// Initialize or resize the ping-pong textures.
  void initializeFramebuffers() {
    _disposeFramebuffers();
    if (_width <= 0 || _height <= 0) return;

    // Create texture A & B views
    _textureA = _createRenderTexture("WebGPUEffectComposer-TextureA");
    _viewA = _textureA!.createView();

    _textureB = _createRenderTexture("WebGPUEffectComposer-TextureB");
    _viewB = _textureB!.createView();

    // Create edge-clamped sampler for input textures
    _inputSampler = device.createSampler(
      magFilter: GpuFilterMode.linear,
      minFilter: GpuFilterMode.linear,
      addressModeU: GpuAddressMode.clampToEdge,
      addressModeV: GpuAddressMode.clampToEdge,
    );

    // Create bind group layout for input texture mapping
    final bindGroupLayoutDescriptor = [
      const GpuBindGroupLayoutEntry.texture(
        binding: 0,
        visibility: GpuShaderStage.fragment,
        sampleType: GpuTextureSampleType.float,
        viewDimension: GpuTextureViewDimension.d2,
      ),
      const GpuSamplerBindingLayout(
        binding: 1,
        visibility: GpuShaderStage.fragment,
        type: GpuSamplerBindingType.filtering,
      )
    ];

    _inputBindGroupLayoutA = device.createBindGroupLayout(bindGroupLayoutDescriptor,label: "WebGPUEffectComposer-InputBindGroupLayout",);
    _inputBindGroupLayoutB = device.createBindGroupLayout(bindGroupLayoutDescriptor,label: "WebGPUEffectComposer-InputBindGroupLayout",);

    _inputBindGroupA = _createInputBindGroup(_viewA!, _inputBindGroupLayoutA!, "InputBindGroup-A");
    _inputBindGroupB = _createInputBindGroup(_viewB!, _inputBindGroupLayoutB!, "InputBindGroup-B");
    _framebuffersInitialized = true;
  }

  GpuTexture _createRenderTexture(String label) {
    return device.createTexture(
      label: label,
      width: _width, height: _height, depthOrArrayLayers: 1,
      format: formatEnum,
      usage: GpuTextureUsage.textureBinding | GpuTextureUsage.renderAttachment | GpuTextureUsage.copySrc | GpuTextureUsage.copyDst,
    );
  }

  GpuBindGroup _createInputBindGroup(GpuTextureView view, GpuBindGroupLayout layout, String label) {
    return device.createBindGroup(
      label: label,
      layout: layout,
      entries: [
        GpuBindGroupEntry.textureView(binding: 0, view: view),
        GpuBindGroupEntry.sampler(binding: 1, sampler: _inputSampler!),
      ],
    );
  }

  void _disposeFramebuffers() {
    _textureA?.destroy();
    _textureB?.destroy();
    _textureA = null;
    _textureB = null;
    _viewA = null;
    _viewB = null;
    _inputBindGroupA = null;
    _inputBindGroupB = null;
    _inputBindGroupLayoutA = null;
    _inputBindGroupLayoutB = null;
    _inputSampler = null;
    _framebuffersInitialized = false;
  }

  /// Adds a pass to the end of the chain.
  void addPass(FullScreenEffectPass pass) {
    _checkNotDisposed();
    _passes.add(pass);
    pass.setSize(_width, _height);
  }

  /// Inserts a pass at the specified index.
  void insertPass(FullScreenEffectPass pass, int index) {
    _checkNotDisposed();
    _passes.insert(index, pass);
    pass.setSize(_width, _height);
  }

  /// Removes a pass from the chain.
  bool removePass(FullScreenEffectPass pass) {
    final removed = _passes.remove(pass);
    if (removed) {
      _pipelineCache.remove(pass);
      _bindGroupCache.remove(pass);
      _uniformBufferCache[pass]?.destroy();
      _uniformBufferCache.remove(pass);
      _shaderModuleCache.remove(pass);
    }
    return removed;
  }

  /// Removes the pass at the specified index.
  FullScreenEffectPass removePassAt(int index) {
    final pass = _passes.removeAt(index);
    _pipelineCache.remove(pass);
    _bindGroupCache.remove(pass);
    _uniformBufferCache[pass]?.destroy();
    _uniformBufferCache.remove(pass);
    _shaderModuleCache.remove(pass);
    return pass;
  }

  /// Removes all passes from the chain.
  void clearPasses() {
    for (final pass in _passes) {
      _pipelineCache.remove(pass);
      _bindGroupCache.remove(pass);
      _uniformBufferCache[pass]?.destroy();
      _uniformBufferCache.remove(pass);
      _shaderModuleCache.remove(pass);
    }
    _passes.clear();
  }

  /// Updates the size and propagates to all passes.
  void setSize(int width, int height) {
    if (_width == width && _height == height) return;
    _width = width;
    _height = height;
    
    for (final pass in _passes) {
      pass.setSize(width, height);
    }

    if (_framebuffersInitialized) {
      initializeFramebuffers();
    }
    _bindGroupCache.clear();
  }

  /// Swaps the positions of two passes.
  void swapPasses(int index1, int index2) {
    final temp = _passes[index1];
    _passes[index1] = _passes[index2];
    _passes[index2] = temp;
  }

  /// Gets only enabled passes.
  List<FullScreenEffectPass> getEnabledPasses() {
    return _passes.where((pass) => pass.enabled && !pass.isDisposed).toList();
  }

  /// Render all enabled passes in the chain using ping-pong textures.
  void render(GpuTextureView outputView) {
    if (_isDisposed) return;
    final enabledPasses = getEnabledPasses();
    if (enabledPasses.isEmpty) return;

    if (!_framebuffersInitialized && enabledPasses.length > 1) {
      initializeFramebuffers();
    }

    bool readFromA = false;

    for (int index = 0; index < enabledPasses.length; index++) {
      final pass = enabledPasses[index];
      final isFirstPass = index == 0;
      final isLastPass = index == enabledPasses.length - 1;

      final targetView = (isLastPass || pass.renderToScreen)
          ? outputView
          : (index % 2 == 0 ? _viewA! : _viewB!);

      final pipeline = _getOrCreatePipeline(pass);
      final uniformBindGroup = _getOrCreateUniformBindGroup(pass);

      if (pass.isUniformBufferDirty) {
        _updateUniformBuffer(pass);
        pass.clearDirtyFlag();
      }

      final inputBindGroup = (pass.requiresInputTexture && !isFirstPass)
          ? (readFromA ? _inputBindGroupA : _inputBindGroupB)
          : null;

      final commandEncoder = device.createCommandEncoder();
      
      final colorAttachment = GpuColorAttachment(
        view: targetView,
        loadOp: GpuLoadOp.clear,
        storeOp: GpuStoreOp.store,
        clearValue: GpuColor(
          pass.clearColor.r,
          pass.clearColor.g,
          pass.clearColor.b,
          pass.clearColor.a,
        ),
      );

      final renderPass = commandEncoder.beginRenderPass(
        colorAttachments: [colorAttachment],
      );

      renderPass.setPipeline(pipeline);

      if (uniformBindGroup != null) {
        renderPass.setBindGroup(0, uniformBindGroup);
      }

      if (inputBindGroup != null) {
        renderPass.setBindGroup(1, inputBindGroup);
      }

      renderPass.draw(vertexCount: 3); // Draw fullscreen triangle
      renderPass.end();

      device.queue.submit([commandEncoder.finish()]);

      if (!isLastPass) {
        readFromA = (index % 2 == 0);
      }
    }
  }

  /// Render a single pass directly (no pass chain processing).
  void renderSingle(FullScreenEffectPass pass, GpuTextureView outputView) {
    if (_isDisposed) return;
    
    final pipeline = _getOrCreatePipeline(pass);
    final uniformBindGroup = _getOrCreateUniformBindGroup(pass);

    if (pass.isUniformBufferDirty) {
      _updateUniformBuffer(pass);
      pass.clearDirtyFlag();
    }

    final commandEncoder = device.createCommandEncoder();
    final colorAttachment = GpuColorAttachment(
      view: outputView,
      loadOp: GpuLoadOp.clear,
      storeOp: GpuStoreOp.store,
      clearValue: GpuColor(
        pass.clearColor.r,
        pass.clearColor.g,
        pass.clearColor.b,
        pass.clearColor.a,
      ),
    );

    final renderPass = commandEncoder.beginRenderPass(
      colorAttachments: [colorAttachment],
    );

    renderPass.setPipeline(pipeline);

    if (uniformBindGroup != null) {
      renderPass.setBindGroup(0, uniformBindGroup);
    }

    renderPass.draw(vertexCount: 3);
    renderPass.end();

    device.queue.submit([commandEncoder.finish()]);
  }

  GpuRenderPipeline _getOrCreatePipeline(FullScreenEffectPass pass) {
    if (_pipelineCache.containsKey(pass)) {
      return _pipelineCache[pass]!;
    }

    final shaderCode = pass.getShaderCode();
    final shaderModule = device.createShaderModule(
      shaderCode,
      label: "WebGPUEffectComposer-ShaderModule",
    );
    _shaderModuleCache[pass] = shaderModule;

    final List<GpuBindGroupLayout> bindGroupLayouts = [];
    if (pass.effect.uniforms.isNotEmpty) {
      bindGroupLayouts.add(_createUniformBindGroupLayout());
    }

    if (pass.requiresInputTexture) {
      final layoutA = _inputBindGroupLayoutA;
      if (layoutA != null) bindGroupLayouts.add(layoutA);
    }

    final pipelineLayout = device.createPipelineLayout(
      bindGroupLayouts,
      label: "WebGPUEffectComposer-PipelineLayout",
    );

    final pipeline = device.createRenderPipeline(GpuRenderPipelineDescriptor(
      label: "WebGPUEffectComposer-RenderPipeline",
      layout: pipelineLayout,
        vertexModule: shaderModule,
        vertexEntryPoint: "vs_main",
        fragmentModule: shaderModule,
        fragmentEntryPoint: "main",
        colorTargets: [
          GpuColorTargetState(
            format: formatEnum,
            blend: _createBlendState(pass.blendMode),
          ),
        ],
        primitiveTopology: GpuPrimitiveTopology.triangleList,
        cullMode: GpuCullMode.none,
    ));

    _pipelineCache[pass] = pipeline;
    return pipeline;
  }

  GpuBindGroupLayout _createUniformBindGroupLayout() {
    return device.createBindGroupLayout(
      [
        GpuBindGroupLayoutEntry.buffer(
          binding: 0,
          visibility: GpuShaderStage.vertex | GpuShaderStage.fragment,
          type: GpuBufferBindingType.uniform
        ),
      ],
      label: "WebGPUEffectComposer-UniformBindGroupLayout",
    );
  }

  GpuBlendState? _createBlendState(BlendMode blendMode) {
    switch (blendMode) {
      case BlendMode.opaque:
        return null;
      case BlendMode.alphaBlend:
        return const GpuBlendState(
          color: GpuBlendComponent(srcFactor: GpuBlendFactor.srcAlpha, dstFactor: GpuBlendFactor.oneMinusSrcAlpha, operation: GpuBlendOperation.add),
          alpha: GpuBlendComponent(srcFactor: GpuBlendFactor.one, dstFactor: GpuBlendFactor.oneMinusSrcAlpha, operation: GpuBlendOperation.add),
        );
      case BlendMode.additive:
        return const GpuBlendState(
          color: GpuBlendComponent(srcFactor: GpuBlendFactor.one, dstFactor: GpuBlendFactor.one, operation: GpuBlendOperation.add),
          alpha: GpuBlendComponent(srcFactor: GpuBlendFactor.one, dstFactor: GpuBlendFactor.one, operation: GpuBlendOperation.add),
        );
      case BlendMode.multiply:
        return const GpuBlendState(
          color: GpuBlendComponent(srcFactor: GpuBlendFactor.dst, dstFactor: GpuBlendFactor.zero, operation: GpuBlendOperation.add),
          alpha: GpuBlendComponent(srcFactor: GpuBlendFactor.dstAlpha, dstFactor: GpuBlendFactor.zero, operation: GpuBlendOperation.add),
        );
      case BlendMode.screen:
        return const GpuBlendState(
          color: GpuBlendComponent(srcFactor: GpuBlendFactor.one, dstFactor: GpuBlendFactor.oneMinusSrc, operation: GpuBlendOperation.add),
          alpha: GpuBlendComponent(srcFactor: GpuBlendFactor.one, dstFactor: GpuBlendFactor.oneMinusSrcAlpha, operation: GpuBlendOperation.add),
        );
      case BlendMode.overlay:
        return const GpuBlendState(
          color: GpuBlendComponent(srcFactor: GpuBlendFactor.dst, dstFactor: GpuBlendFactor.zero, operation: GpuBlendOperation.add),
          alpha: GpuBlendComponent(srcFactor: GpuBlendFactor.dstAlpha, dstFactor: GpuBlendFactor.zero, operation: GpuBlendOperation.add),
        );
      case BlendMode.premultipliedAlpha:
        return const GpuBlendState(
          color: GpuBlendComponent(srcFactor: GpuBlendFactor.one, dstFactor: GpuBlendFactor.oneMinusSrcAlpha, operation: GpuBlendOperation.add),
          alpha: GpuBlendComponent(srcFactor: GpuBlendFactor.one, dstFactor: GpuBlendFactor.oneMinusSrcAlpha, operation: GpuBlendOperation.add),
        );
    }
  }

  GpuBindGroup? _getOrCreateUniformBindGroup(FullScreenEffectPass pass) {
    if (pass.effect.uniforms.isEmpty) return null;
    if (_bindGroupCache.containsKey(pass)) {
      return _bindGroupCache[pass];
    }

    final uniformBuffer = _getOrCreateUniformBuffer(pass);
    final bindGroupLayout = _createUniformBindGroupLayout();

    final bindGroup = device.createBindGroup(
      label: "WebGPUEffectComposer-UniformBindGroup",
      layout: bindGroupLayout,
      entries: [
        GpuBindGroupEntry.buffer(binding: 0, buffer: uniformBuffer),
      ],
    );

    _bindGroupCache[pass] = bindGroup;
    return bindGroup;
  }

  GpuBuffer _getOrCreateUniformBuffer(FullScreenEffectPass pass) {
    if (_uniformBufferCache.containsKey(pass)) {
      return _uniformBufferCache[pass]!;
    }

    final bufferSize = pass.effect.uniformBuffer.length * 4; // Float elements to bytes
    final alignedSize = ((bufferSize + 15) ~/ 16) * 16;      // 16-byte buffer packing alignment

    final buffer = device.createBuffer(
      size: alignedSize,
      usage: GpuBufferUsage.uniform | GpuBufferUsage.copyDst,
      label: "WebGPUEffectComposer-UniformBuffer",
    );

    _uniformBufferCache[pass] = buffer;
    _uploadUniformBuffer(pass, buffer);
    return buffer;
  }

  void _updateUniformBuffer(FullScreenEffectPass pass) {
    final buffer = _uniformBufferCache[pass];
    if (buffer != null) {
      _uploadUniformBuffer(pass, buffer);
    }
  }

  void _uploadUniformBuffer(FullScreenEffectPass pass, GpuBuffer buffer) {
    final data = pass.effect.uniformBuffer;
    device.queue.writeBuffer(
      buffer,
      data.buffer.asByteData(data.offsetInBytes, data.lengthInBytes).buffer.asUint8List(),
      bufferOffset: 0, 
    );
  }

  /// Releases all associated GPU resources and passes.
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;

    for (final pass in _passes) {
      pass.dispose();
    }
    _passes.clear();

    for (final buffer in _uniformBufferCache.values) {
      buffer.destroy();
    }
    _uniformBufferCache.clear();
    _pipelineCache.clear();
    _bindGroupCache.clear();
    _shaderModuleCache.clear();

    _disposeFramebuffers();
  }

  void _checkNotDisposed() {
    if (_isDisposed) {
      throw StateError("WebGPUEffectComposer has been disposed");
    }
  }
}
