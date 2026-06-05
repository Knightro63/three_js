import 'dart:typed_data';
import 'package:gpux/gpux.dart';
import '../common/data_map.dart';
import '../descriptors/gpu_bind_group_descriptor.dart';
import '../descriptors/gpu_buffer_descriptor.dart';
import '../descriptors/gpu_command_encoder_descriptor.dart';
import '../descriptors/gpu_render_bundle_encoder_descriptor.dart';
import '../descriptors/gpu_render_pass_color_attachment.dart';
import '../descriptors/gpu_render_pass_descriptor.dart';
import '../descriptors/gpu_render_pipeline_descriptor.dart';
import '../descriptors/gpu_shader_module_descriptor.dart';
import '../descriptors/gpu_texture_descriptor.dart';
import '../descriptors/gpu_texture_view_descriptor.dart';
import 'gpu_utils.dart';

// Shared file descriptors initialized from your recently converted files
final GPUBindGroupDescriptor _bindGroupDescriptor = GPUBindGroupDescriptor();
final GPUBufferDescriptor _bufferDescriptor = GPUBufferDescriptor();
final GPUCommandEncoderDescriptor _commandEncoderDescriptor = GPUCommandEncoderDescriptor();
final GPURenderBundleEncoderDescriptor _renderBundleEncoderDescriptor = GPURenderBundleEncoderDescriptor();
final GPURenderPassDescriptor _renderPassDescriptor = GPURenderPassDescriptor();
final GPURenderPipelineDescriptor _renderPipelineDescriptor = GPURenderPipelineDescriptor();
final GPURenderPassColorAttachment _colorAttachment = GPURenderPassColorAttachment();
final GPUShaderModuleDescriptor _shaderModuleDescriptor = GPUShaderModuleDescriptor();
final GPUTextureDescriptor _textureDescriptor = GPUTextureDescriptor();
final GPUTextureViewDescriptor _viewDescriptor = GPUTextureViewDescriptor();

/// A WebGPU backend utility module used by WebGPUTextureUtils.
class WebGPUTexturePassUtils extends DataMap {
  /// The WebGPU device context reference.
  final dynamic device;

  /// The mipmap GPU sampler.
  late final dynamic mipmapSampler;

  /// The flipY GPU sampler.
  late final dynamic flipYSampler;

  /// Flip uniform buffer.
  late final dynamic flipUniformBuffer;

  /// No flip uniform buffer.
  late final dynamic noFlipUniformBuffer;

  /// A cache for GPU render pipelines used for copy/transfer passes.
  /// Every texture format and textureBindingViewDimension combo requires a unique pipeline.
  final Map<String, dynamic> transferPipelines = {};

  /// The mipmap shader module.
  late final dynamic mipmapShaderModule;

  /// Local state backing cache following map instructions strategy
  // final Map<String, dynamic> _passUtilsStateCache = {};
  // dynamic operator [](String key) => _passUtilsStateCache[key];
  // void operator []=(String key, dynamic value) => _passUtilsStateCache[key] = value;

  /// Constructs a new texture pass utility object.
  WebGPUTexturePassUtils(this.device) : super() {
    const String mipmapSource = '''
 struct VarysStruct {
 @builtin( position ) Position: vec4f,
 @location( 0 ) vTex : vec2f,
 @location( 1 ) @interpolate(flat, either) vBaseArrayLayer: u32,
 };
 @group( 0 ) @binding ( 2 ) var<uniform> flipY: u32;
 @vertex fn mainVS( @builtin( vertex_index ) vertexIndex : u32, @builtin( instance_index ) instanceIndex : u32 ) -> VarysStruct {
 var Varys : VarysStruct;
 var pos = array( vec2f( -1, -1 ), vec2f( -1, 3 ), vec2f( 3, -1 ), );
 let p = pos[ vertexIndex ];
 let mult = select( vec2f( 0.5, -0.5 ), vec2f( 0.5, 0.5 ), flipY != 0 );
 Varys.vTex = p * mult + vec2f( 0.5 );
 Varys.Position = vec4f( p, 0, 1 );
 Varys.vBaseArrayLayer = instanceIndex;
 return Varys;
 }
 @group( 0 ) @binding( 0 ) var imgSampler : sampler;
 @group( 0 ) @binding( 1 ) var img2d : texture_2d<f32>;
 @fragment fn main_2d( Varys: VarysStruct ) -> @location( 0 ) vec4<f32> {
 return textureSample( img2d, imgSampler, Varys.vTex );
 }
 @group( 0 ) @binding( 1 ) var img2dArray : texture_2d_array<f32>;
 @fragment fn main_2d_array( Varys: VarysStruct ) -> @location( 0 ) vec4<f32> {
 return textureSample( img2dArray, imgSampler, Varys.vTex, Varys.vBaseArrayLayer );
 }
 const faceMat = array(
 mat3x3f( 0, 0, -2, 0, -2, 0, 1, 1, 1 ), // pos-x
 mat3x3f( 0, 0, 2, 0, -2, 0, -1, 1, -1 ), // neg-x
 mat3x3f( 2, 0, 0, 0, 0, 2, -1, 1, -1 ), // pos-y
 mat3x3f( 2, 0, 0, 0, 0, -2, -1, -1, 1 ), // neg-y
 mat3x3f( 2, 0, 0, 0, -2, 0, -1, 1, 1 ), // pos-z
 mat3x3f( -2, 0, 0, 0, -2, 0, 1, 1, -1 ), // neg-z
 );
 @group( 0 ) @binding( 1 ) var imgCube : texture_cube<f32>;
 @fragment fn main_cube( Varys: VarysStruct ) -> @location( 0 ) vec4<f32> {
 return textureSample( imgCube, imgSampler, faceMat[ Varys.vBaseArrayLayer ] * vec3f( fract( Varys.vTex ), 1 ) );
 }
 ''';

    // Sampler setup using safe lowercase enum configurations
    this.mipmapSampler = device.createSampler({
      'minFilter': GpuFilterMode.linear
    });

    this.flipYSampler = device.createSampler({
      'minFilter': GpuFilterMode.nearest
    });

    // Flip uniform buffer initialization
    _bufferDescriptor.size = 4;
    _bufferDescriptor.usage = GpuBufferUsage.uniform | GpuBufferUsage.copyDst;
    this.flipUniformBuffer = device.createBuffer(_bufferDescriptor);
    _bufferDescriptor.reset();

    // Map hardware list array using native Uint32List view allocations
    final Uint32List flipValue = Uint32List.fromList([1]);
    device.queue.writeBuffer(this.flipUniformBuffer, 0, flipValue, 0, flipValue.length);

    // No-flip uniform buffer initialization
    _bufferDescriptor.size = 4;
    _bufferDescriptor.usage = GpuBufferUsage.uniform;
    this.noFlipUniformBuffer = device.createBuffer(_bufferDescriptor);
    _bufferDescriptor.reset();

    // Compile mipmap processing shader entry module
    _shaderModuleDescriptor.label = 'mipmap';
    _shaderModuleDescriptor.code = mipmapSource;
    this.mipmapShaderModule = device.createShaderModule(_shaderModuleDescriptor);
    _shaderModuleDescriptor.reset();
  }

  /// Returns a render pipeline for the internal copy render pass. The pass
  /// requires a unique render pipeline for each texture format.
  /// 
  /// [format] - The GPU texture format.
  /// [textureBindingViewDimension] - The GPU texture binding view dimension.
  /// Returns the hardware GPURenderPipeline.
  dynamic getTransferPipeline(GpuTextureFormat format, [String? textureBindingViewDimension]) {
    final String viewDimension = textureBindingViewDimension ?? '2d-array';
    final String key = '${format.name}-$viewDimension';
    
    // Utilizing direct map bracket directives for internal transfer caches lookup
    dynamic pipeline = this.transferPipelines[key];

    if (pipeline == null) {
      _renderPipelineDescriptor.label = 'mipmap-${format.name}-$viewDimension';
      _renderPipelineDescriptor.vertex = <String, dynamic>{
        'module': this.mipmapShaderModule
      };
      
      _renderPipelineDescriptor.fragment = <String, dynamic>{
        'module': this.mipmapShaderModule,
        'entryPoint': 'main_${viewDimension.replaceAll('-', '_')}',
        'targets': [
          <String, dynamic>{'format': format}
        ]
      };
      
      _renderPipelineDescriptor.layout = 'auto';
      
      pipeline = this.device.createRenderPipeline(_renderPipelineDescriptor);
      _renderPipelineDescriptor.reset();
      
      this.transferPipelines[key] = pipeline;
    }

    return pipeline;
  }

  /// Flip the contents of the given GPU texture along its vertical axis.
  /// 
  /// [textureGPU] - The GPU texture object.
  /// [textureGPUDescriptor] - The texture descriptor layout model.
  /// [baseArrayLayer] - The index of the first array layer accessible to the texture view.
  void flipY(dynamic textureGPU, dynamic textureGPUDescriptor, [int baseArrayLayer = 0]) {
    final GpuTextureFormat format = textureGPUDescriptor.format;
    final Map<String, int> size = textureGPUDescriptor.size;
    
    final int width = size['width'] ?? 0;
    final int height = size['height'] ?? 0;

    _textureDescriptor.size['width'] = width;
    _textureDescriptor.size['height'] = height;
    _textureDescriptor.format = format;
    _textureDescriptor.usage = GpuTextureUsage.renderAttachment | GpuTextureUsage.textureBinding;

    final dynamic tempTexture = this.device.createTexture(_textureDescriptor);
    _textureDescriptor.reset();

    final dynamic copyTransferPipeline = this.getTransferPipeline(format, textureGPU.textureBindingViewDimension);
    final dynamic flipTransferPipeline = this.getTransferPipeline(format, tempTexture.textureBindingViewDimension);

    final dynamic commandEncoder = this.device.createCommandEncoder(_commandEncoderDescriptor);

    // Inner localized procedural drawing function block
    void pass(
      dynamic pipeline, 
      dynamic sourceTexture, 
      int sourceArrayLayer, 
      dynamic destinationTexture, 
      int destinationArrayLayer, 
      bool doFlip
    ) {
      final dynamic bindGroupLayout = pipeline.getBindGroupLayout(0);
      final String sourceDim = sourceTexture.textureBindingViewDimension ?? '2d-array';

      _viewDescriptor.dimension = GpuTextureViewDimension.values.byName(
        sourceDim == '2d-array' ? 'twoDArray' : (sourceDim == '3d' ? 'threeD' : (sourceDim == 'cube' ? 'cube' : 'twoD'))
      );
      _viewDescriptor.mipLevelCount = 1;
      
      final dynamic sourceView = sourceTexture.createView(_viewDescriptor);
      _viewDescriptor.reset();

      _bindGroupDescriptor.layout = bindGroupLayout;
      _bindGroupDescriptor.entries.addAll([
        {'binding': 0, 'resource': this.flipYSampler},
        {'binding': 1, 'resource': sourceView},
        {
          'binding': 2, 
          'resource': {
            'buffer': doFlip ? this.flipUniformBuffer : this.noFlipUniformBuffer
          }
        }
      ]);

      final dynamic bindGroup = this.device.createBindGroup(_bindGroupDescriptor);
      _bindGroupDescriptor.reset();

      _viewDescriptor.dimension = GpuTextureViewDimension.d2;
      _viewDescriptor.mipLevelCount = 1;
      _viewDescriptor.baseArrayLayer = destinationArrayLayer;
      _viewDescriptor.arrayLayerCount = 1;

      final dynamic destinationView = destinationTexture.createView(_viewDescriptor);
      _viewDescriptor.reset();

      _colorAttachment.view = destinationView;
      _colorAttachment.loadOp = GpuLoadOp.clear;
      _colorAttachment.storeOp = GpuStoreOp.store;
      
      _renderPassDescriptor.colorAttachments.add(_colorAttachment);

      final dynamic passEncoder = commandEncoder.beginRenderPass(_renderPassDescriptor);
      _renderPassDescriptor.reset();
      _colorAttachment.reset();

      passEncoder.setPipeline(pipeline);
      passEncoder.setBindGroup(0, bindGroup);
      passEncoder.draw(3, 1, 0, sourceArrayLayer);
      passEncoder.end();
    }

    // Dispatch the vertical texture inversion copy commands
    pass(copyTransferPipeline, textureGPU, baseArrayLayer, tempTexture, 0, false);
    pass(flipTransferPipeline, tempTexture, 0, textureGPU, baseArrayLayer, true);

    submit(this.device, commandEncoder.finish());
    tempTexture.destroy();
  }

  /// Generates mipmaps for the given GPU texture.
  /// 
  /// [textureGPU] - The GPU texture object.
  /// [encoder] - An optional command encoder used to generate mipmaps.
  void generateMipmaps(dynamic textureGPU, [dynamic encoder = null]) {
    // Enforcing your map directive bracket syntax rules instead of this.get()
    final dynamic textureData = this[textureGPU];
    final List<dynamic> passes = textureData?['layers'] ?? this._mipmapCreateBundles(textureGPU);
    
    dynamic commandEncoder = encoder;

    if (commandEncoder == null) {
      _commandEncoderDescriptor.label = 'mipmapEncoder';
      commandEncoder = this.device.createCommandEncoder(_commandEncoderDescriptor);
      _commandEncoderDescriptor.reset();
    }

    this._mipmapRunBundles(commandEncoder, passes);

    if (encoder == null) {
      submit(this.device, commandEncoder.finish());
    }

    textureData?['layers'] = passes;
  }

  /// Since multiple copy render passes are required to generate mipmaps, the passes
  /// are managed as render bundles to improve performance.
  /// 
  /// [textureGPU] - The GPU texture object.
  /// Returns an array list of generated render bundles.
  List<dynamic> _mipmapCreateBundles(dynamic textureGPU) {
    final String textureBindingViewDimension = textureGPU.textureBindingViewDimension ?? '2d-array';
    
    // Explicitly parse enum structures out of your backend format tags
    final GpuTextureFormat format = textureGPU.format;
    final dynamic pipeline = this.getTransferPipeline(format, textureBindingViewDimension);
    final dynamic bindGroupLayout = pipeline.getBindGroupLayout(0);
    
    final List<dynamic> passes = [];

    for (int baseMipLevel = 1; baseMipLevel < textureGPU.mipLevelCount; baseMipLevel++) {
      for (int baseArrayLayer = 0; baseArrayLayer < textureGPU.depthOrArrayLayers; baseArrayLayer++) {
        
        // Assemble source mip view dimensions configuration parameters
        _viewDescriptor.dimension = GpuTextureViewDimension.values.byName(
          textureBindingViewDimension == '2d-array' ? 'twoDArray' : (textureBindingViewDimension == '3d' ? 'threeD' : (textureBindingViewDimension == 'cube' ? 'cube' : 'twoD'))
        );
        _viewDescriptor.baseMipLevel = baseMipLevel - 1;
        _viewDescriptor.mipLevelCount = 1;
        
        final dynamic sourceView = textureGPU.createView(_viewDescriptor);
        _viewDescriptor.reset();

        _bindGroupDescriptor.layout = bindGroupLayout;
        _bindGroupDescriptor.entries.addAll([
          {'binding': 0, 'resource': this.mipmapSampler},
          {'binding': 1, 'resource': sourceView},
          {
            'binding': 2, 
            'resource': {
              'buffer': this.noFlipUniformBuffer
            }
          }
        ]);

        final dynamic bindGroup = this.device.createBindGroup(_bindGroupDescriptor);
        _bindGroupDescriptor.reset();

        // Assemble targeting downsampled destination texture properties
        _viewDescriptor.dimension = GpuTextureViewDimension.d2;
        _viewDescriptor.baseMipLevel = baseMipLevel;
        _viewDescriptor.mipLevelCount = 1;
        _viewDescriptor.baseArrayLayer = baseArrayLayer;
        _viewDescriptor.arrayLayerCount = 1;

        final dynamic destinationView = textureGPU.createView(_viewDescriptor);
        _viewDescriptor.reset();

        final GpuColorAttachment passColorAttachment = GpuColorAttachment(
          view: destinationView,
          loadOp: GpuLoadOp.clear,
          storeOp: GpuStoreOp.store
        );


        final GPURenderPassDescriptor passDescriptor = GPURenderPassDescriptor();
        passDescriptor.colorAttachments.add(passColorAttachment);

        _renderBundleEncoderDescriptor.colorFormats = [format];
        
        final dynamic passEncoder = this.device.createRenderBundleEncoder(_renderBundleEncoderDescriptor);
        _renderBundleEncoderDescriptor.reset();

        passEncoder.setPipeline(pipeline);
        passEncoder.setBindGroup(0, bindGroup);
        passEncoder.draw(3, 1, 0, baseArrayLayer);

        passes.add({
          'renderBundles': [passEncoder.finish()],
          'passDescriptor': passDescriptor
        });
      }
    }

    return passes;
  }

  /// Executes the pre-recorded downsampling render bundles.
  /// 
  /// [commandEncoder] - The GPU command encoder.
  /// [passes] - An array holding the configured pass descriptors and bundle sequences.
  void _mipmapRunBundles(dynamic commandEncoder, List<dynamic> passes) {
    final int levels = passes.length;
    
    for (int i = 0; i < levels; i++) {
      final dynamic pass = passes[i];
      
      // Enforcing direct map bracket parsing assignments based on directive instructions
      final dynamic passDescriptor = pass['passDescriptor'];
      final List<dynamic> renderBundles = pass['renderBundles'] ?? [];

      final dynamic passEncoder = commandEncoder.beginRenderPass(passDescriptor);
      passEncoder.executeBundles(renderBundles);
      passEncoder.end();
    }
  }
}