import 'dart:typed_data';
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';
import 'package:gpux/gpux.dart' as gpux;
import '../shader/shader_library.dart';

/// Base interface for all materials.
abstract class EngineMaterial extends Material {
  /// Material name for debugging
  String get name;

  /// Whether the material needs GPU resources rebuilt
  bool get needsUpdate;
  set needsUpdate(bool value);

  /// Whether the material is visible
  bool get visible;
  set visible(bool value);

  /// Whether the material is transparent
  bool get transparent;

  /// Render order (lower = rendered first)
  int get renderOrder;
  set renderOrder(int value);

  /// Depth testing enabled
  bool get depthTest;
  set depthTest(bool value);

  /// Depth writing enabled
  bool get depthWrite;
  set depthWrite(bool value);

  /// Gets the shader features required by this material.
  Set<ShaderFeature> getRequiredFeatures();

  /// Creates the GPU pipeline for this material.
  gpux.GpuRenderPipeline createPipeline(
    gpux.GpuDevice device,
    gpux.GpuTextureFormat colorFormat,
    gpux.GpuTextureFormat? depthFormat,
  );

  /// Creates bind group with material uniforms.
  gpux.GpuBindGroup createBindGroup(
    gpux.GpuDevice device,
    gpux.GpuBindGroupLayout layout,
  );

  /// Updates uniform buffer data.
  void updateUniforms(gpux.GpuBuffer buffer);
}

/// Which side of faces to render.
enum Side {
  /// Render front faces only (default)
  front,

  /// Render back faces only
  back,

  /// Render both sides
  double,
}

/// Basic unlit material with a solid color.
class BasicMaterial extends EngineMaterial {
  BasicMaterial({
    this.name = 'BasicMaterial',
    Color? color,
    this.opacity = 1.0,
    this.transparent = false,
  }) : color = color ?? Color(1.0, 1.0, 1.0);

  @override
  final String name;
  
  Color color;
  double opacity;
  
  @override
  final bool transparent;

  bool _disposed = false;
  bool get isDisposed => _disposed;

  @override
  bool needsUpdate = true;

  @override
  bool visible = true;

  @override
  int renderOrder = 0;

  @override
  bool depthTest = true;

  @override
  bool depthWrite = true;

  // Cached GPU resources
  gpux.GpuRenderPipeline? _cachedPipeline;

  @override
  Set<ShaderFeature> getRequiredFeatures() => const {};

  @override
  gpux.GpuRenderPipeline createPipeline(
    gpux.GpuDevice device,
    gpux.GpuTextureFormat colorFormat,
    gpux.GpuTextureFormat? depthFormat,
  ) {
    if (_cachedPipeline != null) {
      return _cachedPipeline!;
    }

    final shaderSource = '${ShaderLibrary.unlitVertexShader}\n${ShaderLibrary.unlitFragmentShader}';
    
    final shaderModule = device.createShaderModule(
      shaderSource,
      label: '$name-shader'
    );

    final bindGroupLayout = device.createBindGroupLayout(
       [
        gpux.GpuBindGroupLayoutEntry.buffer(
          binding: 0,
          visibility: gpux.GpuShaderStage.vertex,
          type: gpux.GpuBufferBindingType.uniform,
        ),
      ],
      label: '$name-bind-group-layout',
    );

    final gpux.GpuPipelineLayout pipelineLayout = device.createPipelineLayout(
      [bindGroupLayout],
      label: '$name-pipeline-layout',
    );

    final pipeline = device.createRenderPipeline(
      gpux.GpuRenderPipelineDescriptor(
        label: '$name-pipeline',
        vertexModule: shaderModule,
        fragmentModule: shaderModule,
        colorTargets: [
          gpux.GpuColorTargetState(
            format: colorFormat,
            blend: transparent ? gpux.GpuBlendState(
              color: gpux.GpuBlendComponent(),
              alpha: gpux.GpuBlendComponent()
            ) : null,
          ),
        ],
        vertexBuffers: [
          gpux.GpuVertexBufferLayout(
            arrayStride: 6 * 4, // 6 * FloatBytes (position (3) + color (3))
            attributes: const [
              gpux.GpuVertexAttribute(shaderLocation: 0, format: gpux.GpuVertexFormat.float32x3, offset:0),
              gpux.GpuVertexAttribute(shaderLocation: 1, format: gpux.GpuVertexFormat.float32x3, offset:3 * 4),
            ],
          ),
        ],
        cullMode: 
          FrontSide == side? gpux.GpuCullMode.back:
          BackSide == side? gpux.GpuCullMode.front:
          gpux.GpuCullMode.none
        ,
        depthStencil: (depthFormat != null && depthTest)
          ? gpux.GpuDepthStencilState(
              format: depthFormat,
              depthWriteEnabled: depthWrite,
              depthCompare: gpux.GpuCompareFunction.less,
            )
          : null,
        layout: pipelineLayout,
      ),
    );

    _cachedPipeline = pipeline;
    needsUpdate = false;
    return pipeline;
  }

  @override
  gpux.GpuBindGroup createBindGroup(gpux.GpuDevice device, gpux.GpuBindGroupLayout layout) {
    final uniformBuffer = device.createBuffer(
      label: '$name-uniforms',
      size: 64, // mat4x4
      usage: gpux.GpuBufferUsage.uniform | gpux.GpuBufferUsage.copyDst,
    );

    return device.createBindGroup(
      label: '$name-bind-group',
      layout: layout,
      entries: [
        gpux.GpuBindGroupEntry.buffer(
          binding: 0,
          buffer: uniformBuffer,
        ),
      ],
    );
  }

  @override
  void updateUniforms(gpux.GpuBuffer buffer) {
    // For BasicMaterial, uniforms are just the MVP matrix
    // which is handled externally by the renderer
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
  }
}

/// Standard PBR material with metallic-roughness workflow.
class StandardMaterial extends EngineMaterial {
  StandardMaterial({
    this.name = 'StandardMaterial',
    Color? baseColor,
    this.metallic = 0.0,
    this.roughness = 0.5,
    Color? emissive,
    this.emissiveIntensity = 1.0,
    double normalScale = 1.0,
    this.aoIntensity = 1.0,
    this.opacity = 1.0,
    this.alphaCutoff = 0.0,
    this.transparent = false,
    required this.device,
  }){
    this.normalScale = Vector2(normalScale, normalScale);
    baseColor = baseColor ?? Color(1.0, 1.0, 1.0);
    this.emissive = emissive ?? Color(0.0, 0.0, 0.0);
  }

  @override
  final String name;

  final gpux.GpuDevice device;

  late final Color baseColor;
  double metallic;
  double roughness;
  double emissiveIntensity;
  double aoIntensity;
  double opacity;
  double alphaCutoff;

  @override
  final bool transparent;

  bool _disposed = false;
  bool get isDisposed => _disposed;

  @override
  bool needsUpdate = true;

  @override
  bool visible = true;

  @override
  int renderOrder = 0;

  @override
  bool depthTest = true;

  @override
  bool depthWrite = true;

  // Texture references (managed externally)
  dynamic baseColorMap;
  dynamic metallicRoughnessMap;

  // Cached resources
  gpux.GpuRenderPipeline? _cachedPipeline;

  @override
  Set<ShaderFeature> getRequiredFeatures() {
    final features = <ShaderFeature>{ShaderFeature.useDirectionalLight};
    if (baseColorMap != null) features.add(ShaderFeature.useTexture);
    if (normalMap != null) features.add(ShaderFeature.useNormalMap);
    if (metallicRoughnessMap != null) features.add(ShaderFeature.useMetallicRoughnessMap);
    if (aoMap != null) features.add(ShaderFeature.useAoMap);
    if (emissiveMap != null) features.add(ShaderFeature.useEmissiveMap);
    if (alphaCutoff > 0.0) features.add(ShaderFeature.useAlphaCutoff);
    return features;
  }

  @override
  gpux.GpuRenderPipeline createPipeline(
    gpux.GpuDevice device,
    gpux.GpuTextureFormat colorFormat,
    gpux.GpuTextureFormat? depthFormat,
  ) {
    if (_cachedPipeline != null && !needsUpdate) {
      return _cachedPipeline!;
    }

    final features = getRequiredFeatures();
    final vertexSource = ShaderLibrary.compileShader(ShaderLibrary.standardVertexShader, features);
    final fragmentSource = ShaderLibrary.compileShader(ShaderLibrary.standardFragmentShader, features);

    final vertexModule = device.createShaderModule(vertexSource, label: '$name-vertex');
    final fragmentModule = device.createShaderModule(fragmentSource, label: '$name-fragment');

    // Build vertex buffer layout based on features
    final attributes = [
      gpux.GpuVertexAttribute(shaderLocation: 0, format: gpux.GpuVertexFormat.float32x3, offset: 0),  // position
      gpux.GpuVertexAttribute(shaderLocation:1, format: gpux.GpuVertexFormat.float32x3, offset: 12), // normal
      gpux.GpuVertexAttribute(shaderLocation:2, format: gpux.GpuVertexFormat.float32x2, offset: 4), // uv
    ];
    const stride = 32; // position + normal + uv

    // Create bind group layouts
    final bindGroupLayouts = <gpux.GpuBindGroupLayout>[
      // Group 0: Camera uniforms
      device.createBindGroupLayout(
        [
          gpux.GpuBindGroupLayoutEntry.buffer(binding: 0, visibility: gpux.GpuShaderStage.vertex | gpux.GpuShaderStage.fragment, type: gpux.GpuBufferBindingType.uniform),
          gpux.GpuBindGroupLayoutEntry.buffer(binding: 1, visibility: gpux.GpuShaderStage.fragment, type: gpux.GpuBufferBindingType.uniform),
        ],
        label: '$name-camera-layout',
      ),
      // Group 1: Model uniforms
      device.createBindGroupLayout(
        [
          gpux.GpuBindGroupLayoutEntry.buffer(binding: 0, visibility: gpux.GpuShaderStage.vertex, type: gpux.GpuBufferBindingType.uniform),
        ],
        label: '$name-model-layout',
      ),
    ];

    // Group 2: Material uniforms and textures
    final materialEntries = [
      const gpux.GpuBindGroupLayoutEntry.buffer(binding: 0, visibility: gpux.GpuShaderStage.fragment, type: gpux.GpuBufferBindingType.uniform),
    ];

    if (features.contains(ShaderFeature.useTexture)) {
      materialEntries.add(gpux.GpuBindGroupLayoutEntry.texture(binding: 1, visibility: gpux.GpuShaderStage.fragment));
      materialEntries.add(gpux.GpuBindGroupLayoutEntry.sampler(binding: 2, visibility: gpux.GpuShaderStage.fragment));
    }

    bindGroupLayouts.add(
      device.createBindGroupLayout(
        materialEntries,
        label: '$name-material-layout',
      ),
    );
    final gpux.GpuPipelineLayout pipelineLayout = device.createPipelineLayout(
      bindGroupLayouts,
      label: '$name-pipeline-layout',
    );

    final pipeline = device.createRenderPipeline(
      gpux.GpuRenderPipelineDescriptor(
        label: '$name-pipeline',
        vertexModule: vertexModule,
        fragmentModule: fragmentModule,
        colorTargets: [
          gpux.GpuColorTargetState(
            format: colorFormat,
            blend: transparent ? gpux.GpuBlendState(
              color: gpux.GpuBlendComponent(),
              alpha: gpux.GpuBlendComponent()
            ) : null,
          ),
        ],
        vertexBuffers: [
          gpux.GpuVertexBufferLayout(arrayStride: stride, attributes: attributes),
        ],
        cullMode: 
          FrontSide == side? gpux.GpuCullMode.back:
          BackSide == side? gpux.GpuCullMode.front:
          gpux.GpuCullMode.none
        ,
        depthStencil: (depthFormat != null && depthTest)
          ? gpux.GpuDepthStencilState(
              format: depthFormat,
              depthWriteEnabled: depthWrite,
              depthCompare: gpux.GpuCompareFunction.less,
            )
          : null,
        layout: pipelineLayout,
      ),
    );

    _cachedPipeline = pipeline;
    needsUpdate = false;
    return pipeline;
  }

  @override
  gpux.GpuBindGroup createBindGroup(gpux.GpuDevice device, gpux.GpuBindGroupLayout layout) {
    final uniformBuffer = device.createBuffer(
      label: '$name-material-uniforms',
      size: 64, // Enough for MaterialUniforms struct
      usage: gpux.GpuBufferUsage.uniform | gpux.GpuBufferUsage.copyDst,
    );

    updateUniforms(uniformBuffer);

    return device.createBindGroup(
      label: '$name-material-bind-group',
      layout: layout,
      entries: [
        gpux.GpuBindGroupEntry.buffer(binding: 0, buffer: uniformBuffer),
      ],
    );
  }

  @override
  void updateUniforms(gpux.GpuBuffer buffer) {
    // MaterialUniforms layout matching WGSL std140 structure perfectly
    final data = Float32List(16);
    
    // baseColor (vec4)
    data[0] = baseColor.red;
    data[1] = baseColor.green;
    data[2] = baseColor.blue;
    data[3] = opacity;

    // emissive (vec3) + metallic (f32)
    data[4] = emissive!.red * emissiveIntensity;
    data[5] = emissive!.green * emissiveIntensity;
    data[6] = emissive!.blue * emissiveIntensity;
    data[7] = metallic;

    // roughness, alphaCutoff, normalScale, aoStrength
    data[8] = roughness;
    data[9] = alphaCutoff;
    data[10] = normalScale?.x ?? 0;
    data[11] = aoIntensity;

    // explicit alignment padding
    data[12] = 0.0;
    data[13] = 0.0;
    data[14] = 0.0;
    data[15] = 0.0;
    device.queue.writeBuffer(
      buffer,         // Target GPU destination buffer
      data.buffer.asUint8List(),    // Source CPU memory buffer array view element
    );
    //buffer.writeFloats(data);
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
  }
}
