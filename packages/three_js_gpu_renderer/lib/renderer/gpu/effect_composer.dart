import 'package:gpux/gpux.dart' as gpux; // Adjust based on your exact gpux library paths
import '../../effects/full_screen_effect.dart';
import '../../effects/full_screen_effect_pass.dart'; // To interface with FullScreenEffectPass, BlendMode, etc.

/// Manages a chain of Gpu post-processing effects.
class GpuEffectComposer {
  final gpux.GpuDevice device;
  final gpux.GpuTextureFormat formatEnum;

  final List<FullScreenEffectPass> _passes = [];

  int _width;
  int _height;
  bool _isDisposed = false;
  bool _framebuffersInitialized = false;

  // Ping-pong textures and views for multi-pass rendering
  gpux.GpuTexture? _textureA;
  gpux.GpuTexture? _textureB;
  gpux.GpuTextureView? _viewA;
  gpux.GpuTextureView? _viewB;

  gpux.GpuTextureView? get sceneTargetView => _viewA;

  // Cached pipelines and resources per pass
  final Map<FullScreenEffectPass, gpux.GpuRenderPipeline> _pipelineCache = {};
  final Map<FullScreenEffectPass, gpux.GpuBindGroup> _bindGroupCache = {};
  final Map<FullScreenEffectPass, gpux.GpuBuffer> _uniformBufferCache = {};
  final Map<FullScreenEffectPass, gpux.GpuShaderModule> _shaderModuleCache = {};

  // Input texture bind group references
  gpux.GpuBindGroupLayout? _inputBindGroupLayoutA;
  gpux.GpuBindGroupLayout? _inputBindGroupLayoutB;
  gpux.GpuBindGroup? _inputBindGroupA;
  gpux.GpuBindGroup? _inputBindGroupB;
  gpux.GpuSampler? _inputSampler;

  GpuEffectComposer({
    required this.device,
    int width = 0,
    int height = 0,
    gpux.GpuTextureFormat format = gpux.GpuTextureFormat.bgra8Unorm,
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
    _textureA = _createRenderTexture("GpuEffectComposer-TextureA");
    _viewA = _textureA!.createView();

    _textureB = _createRenderTexture("GpuEffectComposer-TextureB");
    _viewB = _textureB!.createView();

    // Create edge-clamped sampler for input textures
    _inputSampler = device.createSampler(
      magFilter: gpux.GpuFilterMode.linear,
      minFilter: gpux.GpuFilterMode.linear,
      addressModeU: gpux.GpuAddressMode.clampToEdge,
      addressModeV: gpux.GpuAddressMode.clampToEdge,
    );

    // Create bind group layout for input texture mapping
    final bindGroupLayoutDescriptor = [
      const gpux.GpuBindGroupLayoutEntry.texture(
        binding: 0,
        visibility: gpux.GpuShaderStage.fragment,
        sampleType: gpux.GpuTextureSampleType.float,
        viewDimension: gpux.GpuTextureViewDimension.d2,
      ),
      const gpux.GpuSamplerBindingLayout(
        binding: 1,
        visibility: gpux.GpuShaderStage.fragment,
        type: gpux.GpuSamplerBindingType.filtering,
      )
    ];

    _inputBindGroupLayoutA = device.createBindGroupLayout(bindGroupLayoutDescriptor,label: "GpuEffectComposer-InputBindGroupLayout",);
    _inputBindGroupLayoutB = device.createBindGroupLayout(bindGroupLayoutDescriptor,label: "GpuEffectComposer-InputBindGroupLayout",);

    _inputBindGroupA = _createInputBindGroup(_viewA!, _inputBindGroupLayoutA!, "InputBindGroup-A");
    _inputBindGroupB = _createInputBindGroup(_viewB!, _inputBindGroupLayoutB!, "InputBindGroup-B");
    _framebuffersInitialized = true;
  }

  gpux.GpuTexture _createRenderTexture(String label) {
    return device.createTexture(
      label: label,
      width: _width, 
      height: _height, 
      depthOrArrayLayers: 1,
      format: formatEnum,
      usage: gpux.GpuTextureUsage.textureBinding | gpux.GpuTextureUsage.renderAttachment | gpux.GpuTextureUsage.copySrc | gpux.GpuTextureUsage.copyDst,
    );
  }

  gpux.GpuBindGroup _createInputBindGroup(gpux.GpuTextureView view, gpux.GpuBindGroupLayout layout, String label) {
    return device.createBindGroup(
      label: label,
      layout: layout,
      entries: [
        gpux.GpuBindGroupEntry.textureView(binding: 0, view: view),
        gpux.GpuBindGroupEntry.sampler(binding: 1, sampler: _inputSampler!),
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
  void render(gpux.GpuTextureView outputView) {
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
      
      final colorAttachment = gpux.GpuColorAttachment(
        view: targetView,
        loadOp: gpux.GpuLoadOp.clear,
        storeOp: gpux.GpuStoreOp.store,
        clearValue: gpux.GpuColor(
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
  void renderSingle(FullScreenEffectPass pass, gpux.GpuTextureView outputView) {
    if (_isDisposed) return;
    
    final pipeline = _getOrCreatePipeline(pass);
    final uniformBindGroup = _getOrCreateUniformBindGroup(pass);

    if (pass.isUniformBufferDirty) {
      _updateUniformBuffer(pass);
      pass.clearDirtyFlag();
    }

    final commandEncoder = device.createCommandEncoder();
    final colorAttachment = gpux.GpuColorAttachment(
      view: outputView,
      loadOp: gpux.GpuLoadOp.clear,
      storeOp: gpux.GpuStoreOp.store,
      clearValue: gpux.GpuColor(
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

  gpux.GpuRenderPipeline _getOrCreatePipeline(FullScreenEffectPass pass) {
    if (_pipelineCache.containsKey(pass)) {
      return _pipelineCache[pass]!;
    }

    final shaderCode = pass.getShaderCode();
    final shaderModule = device.createShaderModule(
      shaderCode,
      label: "GpuEffectComposer-ShaderModule",
    );
    _shaderModuleCache[pass] = shaderModule;

    final List<gpux.GpuBindGroupLayout> bindGroupLayouts = [];
    if (pass.effect.uniforms.isNotEmpty) {
      bindGroupLayouts.add(_createUniformBindGroupLayout());
    }

    if (pass.requiresInputTexture) {
      final layoutA = _inputBindGroupLayoutA;
      if (layoutA != null) bindGroupLayouts.add(layoutA);
    }

    final pipelineLayout = device.createPipelineLayout(
      bindGroupLayouts,
      label: "GpuEffectComposer-PipelineLayout",
    );

    final pipeline = device.createRenderPipeline(gpux.GpuRenderPipelineDescriptor(
      label: "GpuEffectComposer-RenderPipeline",
      layout: pipelineLayout,
        vertexModule: shaderModule,
        vertexEntryPoint: "vs_main",
        fragmentModule: shaderModule,
        fragmentEntryPoint: "main",
        colorTargets: [
          gpux.GpuColorTargetState(
            format: formatEnum,
            blend: _createBlendState(pass.blendMode),
          ),
        ],
        primitiveTopology: gpux.GpuPrimitiveTopology.triangleList,
        cullMode: gpux.GpuCullMode.none,
    ));

    _pipelineCache[pass] = pipeline;
    return pipeline;
  }

  gpux.GpuBindGroupLayout _createUniformBindGroupLayout() {
    return device.createBindGroupLayout(
      [
        gpux.GpuBindGroupLayoutEntry.buffer(
          binding: 0,
          visibility: gpux.GpuShaderStage.vertex | gpux.GpuShaderStage.fragment,
          type: gpux.GpuBufferBindingType.uniform
        ),
      ],
      label: "GpuEffectComposer-UniformBindGroupLayout",
    );
  }

  gpux.GpuBlendState? _createBlendState(BlendMode blendMode) {
    switch (blendMode) {
      case BlendMode.opaque:
        return null;
        
      case BlendMode.alphaBlend:
        return const gpux.GpuBlendState(
          color: gpux.GpuBlendComponent(
            srcFactor: gpux.GpuBlendFactor.srcAlpha, 
            dstFactor: gpux.GpuBlendFactor.oneMinusSrcAlpha, 
            operation: gpux.GpuBlendOperation.add
          ),
          alpha: gpux.GpuBlendComponent(
            srcFactor: gpux.GpuBlendFactor.one, 
            dstFactor: gpux.GpuBlendFactor.oneMinusSrcAlpha, 
            operation: gpux.GpuBlendOperation.add
          ),
        );
        
      case BlendMode.additive:
        return const gpux.GpuBlendState(
          color: gpux.GpuBlendComponent(
            srcFactor: gpux.GpuBlendFactor.one, 
            dstFactor: gpux.GpuBlendFactor.one, 
            operation: gpux.GpuBlendOperation.add
          ),
          alpha: gpux.GpuBlendComponent(
            srcFactor: gpux.GpuBlendFactor.one, 
            dstFactor: gpux.GpuBlendFactor.one, 
            operation: gpux.GpuBlendOperation.add
          ),
        );
        
      case BlendMode.multiply:
        return const gpux.GpuBlendState(
          color: gpux.GpuBlendComponent(
            srcFactor: gpux.GpuBlendFactor.dst, // Multiplies incoming color against background canvas color
            dstFactor: gpux.GpuBlendFactor.zero, 
            operation: gpux.GpuBlendOperation.add
          ),
          alpha: gpux.GpuBlendComponent(
            srcFactor: gpux.GpuBlendFactor.dstAlpha, 
            dstFactor: gpux.GpuBlendFactor.zero, 
            operation: gpux.GpuBlendOperation.add
          ),
        );
        
      case BlendMode.screen:
        return const gpux.GpuBlendState(
          color: gpux.GpuBlendComponent(
            srcFactor: gpux.GpuBlendFactor.one, 
            dstFactor: gpux.GpuBlendFactor.oneMinusSrc, 
            operation: gpux.GpuBlendOperation.add
          ),
          alpha: gpux.GpuBlendComponent(
            srcFactor: gpux.GpuBlendFactor.one, 
            dstFactor: gpux.GpuBlendFactor.oneMinusSrcAlpha, 
            operation: gpux.GpuBlendOperation.add
          ),
        );
        
      case BlendMode.overlay:
        // FIX: Standard hardware simulation approximation for 2x Multiplicative Overlay layering
        return const gpux.GpuBlendState(
          color: gpux.GpuBlendComponent(
            srcFactor: gpux.GpuBlendFactor.dst, 
            dstFactor: gpux.GpuBlendFactor.src, 
            operation: gpux.GpuBlendOperation.add
          ),
          alpha: gpux.GpuBlendComponent(
            srcFactor: gpux.GpuBlendFactor.one, 
            dstFactor: gpux.GpuBlendFactor.oneMinusSrcAlpha, 
            operation: gpux.GpuBlendOperation.add
          ),
        );
        
      case BlendMode.premultipliedAlpha:
        return const gpux.GpuBlendState(
          color: gpux.GpuBlendComponent(
            srcFactor: gpux.GpuBlendFactor.one, 
            dstFactor: gpux.GpuBlendFactor.oneMinusSrcAlpha, 
            operation: gpux.GpuBlendOperation.add
          ),
          alpha: gpux.GpuBlendComponent(
            srcFactor: gpux.GpuBlendFactor.one, 
            dstFactor: gpux.GpuBlendFactor.oneMinusSrcAlpha, 
            operation: gpux.GpuBlendOperation.add
          ),
        );
    }
  }

  gpux.GpuBindGroup? _getOrCreateUniformBindGroup(FullScreenEffectPass pass) {
    if (pass.effect.uniforms.isEmpty) return null;
    if (_bindGroupCache.containsKey(pass)) {
      return _bindGroupCache[pass];
    }

    final uniformBuffer = _getOrCreateUniformBuffer(pass);
    final bindGroupLayout = _createUniformBindGroupLayout();

    final bindGroup = device.createBindGroup(
      label: "GpuEffectComposer-UniformBindGroup",
      layout: bindGroupLayout,
      entries: [
        gpux.GpuBindGroupEntry.buffer(binding: 0, buffer: uniformBuffer),
      ],
    );

    _bindGroupCache[pass] = bindGroup;
    return bindGroup;
  }

  gpux.GpuBuffer _getOrCreateUniformBuffer(FullScreenEffectPass pass) {
    if (_uniformBufferCache.containsKey(pass)) {
      return _uniformBufferCache[pass]!;
    }

    final bufferSize = pass.effect.uniformBuffer.length * 4; // Float elements to bytes
    final alignedSize = ((bufferSize + 15) ~/ 16) * 16;      // 16-byte buffer packing alignment

    final buffer = device.createBuffer(
      size: alignedSize,
      usage: gpux.GpuBufferUsage.uniform | gpux.GpuBufferUsage.copyDst,
      label: "GpuEffectComposer-UniformBuffer",
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

  void _uploadUniformBuffer(FullScreenEffectPass pass, gpux.GpuBuffer buffer) {
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
      throw StateError("GpuEffectComposer has been disposed");
    }
  }
}
