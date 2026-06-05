import 'dart:typed_data';
import 'package:three_js_core/three_js_core.dart';
import 'package:gpux/gpux.dart';
import 'package:three_js_math/three_js_math.dart';
import '../../nodes/core/constants.dart';
import '../common/bind_group.dart';
import '../common/buffer.dart';
import '../common/nodes/node_sampled_texture.dart';
import '../common/sampled_texture.dart';
import '../common/sampler.dart';
import '../common/storage_buffer.dart';
import '../common/uniform_buffer.dart';

/**
 * A WebGPU backend utility module for managing bindings.
 *
 * When reading the documentation it's helpful to keep in mind that
 * all class definitions starting with 'GPU*' are modules from the
 * WebGPU API. So for example 'BindGroup' is a class from the engine
 * whereas 'GPUBindGroup' is a class from WebGPU.
 *
 * @private
 */
class WebGPUBindingUtils {
  WebGPUBackend backend;
  WeakMap bindGroupLayoutCache = WeakMap();

	WebGPUBindingUtils( this.backend );

	/**
	 * Creates a GPU bind group layout for the given bind group.
	 *
	 * @param {BindGroup} bindGroup - The bind group.
	 * @return {GPUBindGroupLayout} The GPU bind group layout.
	 */

  GpuBindGroupLayout createBindingsLayout(dynamic bindGroup) {
    final backend = this.backend;
    final GpuDevice device = backend.device;
    final List<GpuBindGroupLayoutEntry> entries = [];
    int index = 0;

    for (final binding in bindGroup.bindings) {
      // Visibility flags should be combined bitwise or map to GpuShaderStage flags
      final int visibility = binding.visibility; 
      
      GpuBufferBindingLayout? bufferLayout;
      GpuSamplerBindingLayout? samplerLayout;
      GpuStorageTextureBindingLayout? storageTextureLayout;
      GpuTextureBindingLayout? textureLayout;

      if (binding is UniformBuffer || binding is StorageBuffer) {
        GpuBufferBindingType type = GpuBufferBindingType.uniform;

        if (binding is StorageBuffer) {
          if ((binding.visibility & 4) != 0) { // 4 usually stands for Stage Compute
            if (binding.access == NodeAccess.readWrite || binding.access == NodeAccess.writeOnly) {
              type = GpuBufferBindingType.storage;
            } else {
              type = GpuBufferBindingType.readOnlyStorage;
            }
          } else {
            type = GpuBufferBindingType.readOnlyStorage;
          }
        } else {
          type = GpuBufferBindingType.uniform;
        }
        bufferLayout = GpuBufferBindingLayout(type: type);

      } else if (binding is Sampler) {
        GpuSamplerBindingType type = GpuSamplerBindingType.filtering; // Default WebGPU type

        if (binding.texture is DepthTexture == true) {
          if (binding.texture.compareFunction != null) {
            type = GpuSamplerBindingType.comparison;
          } else if (backend.compatibilityMode == true) {
            type = GpuSamplerBindingType.nonFiltering;
          }
        }
        samplerLayout = GpuSamplerBindingLayout(type: type);

      } else if (binding is SampledTexture && binding.store == true) {
        final GpuTextureFormat format = backend.get(binding.texture).texture.format;
        GpuStorageTextureAccess access = GpuStorageTextureAccess.readOnly;

        if (binding.access == NodeAccess.readWrite) {
          access = GpuStorageTextureAccess.readWrite;
        } else if (binding.access == NodeAccess.writeOnly) {
          access = GpuStorageTextureAccess.writeOnly;
        } else {
          access = GpuStorageTextureAccess.readOnly;
        }

        GpuTextureViewDimension viewDimension = GpuTextureViewDimension.d2;
        if (binding.texture is ArrayTexture == true) {
          viewDimension = GpuTextureViewDimension.d2Array;
        } else if (binding.texture is 3DTexture == true) {
          viewDimension = GpuTextureViewDimension.d3;
        }

        storageTextureLayout = GpuStorageTextureBindingLayout(
          binding: 0,
          format: format,
          access: access,
          viewDimension: viewDimension,
        );

      } else if (binding is SampledTexture) {
        bool multisampled = false;
        GpuTextureSampleType sampleType = GpuTextureSampleType.float;

        final sampleData = backend.utils.getTextureSampleData(binding.texture);
        final int primarySamples = sampleData.primarySamples;

        if (primarySamples > 1) {
          multisampled = true;
          if (binding.texture is DepthTexture != true) {
            sampleType = GpuTextureSampleType.unfilterableFloat;
          }
        }

        if (binding.texture is DepthTexture == true) {
          if (backend.compatibilityMode == true && binding.texture.compareFunction == null) {
            sampleType = GpuTextureSampleType.unfilterableFloat;
          } else {
            sampleType = GpuTextureSampleType.depth;
          }
        } else if (binding.texture is DataTexture == true || 
                  binding.texture is DataArrayTexture == true || 
                  binding.texture is Data3DTexture == true) {
          final type = binding.texture?.type;
          if (type == IntType) {
            sampleType = GpuTextureSampleType.sint;
          } else if (type == UnsignedIntType) {
            sampleType = GpuTextureSampleType.uint;
          } else if (type == FloatType) {
            if (backend.hasFeature('float32-filterable') == true) {
              sampleType = GpuTextureSampleType.float;
            } else {
              sampleType = GpuTextureSampleType.unfilterableFloat;
            }
          }
        }

        GpuTextureViewDimension viewDimension = GpuTextureViewDimension.d2;
        if (binding is SampledCubeTexture == true) {
          viewDimension = GpuTextureViewDimension.cube;
        } else if (binding.texture is ArrayTexture == true || 
                  binding.texture is DataArrayTexture == true || 
                  binding.texture is CompressedArrayTexture == true) {
          viewDimension = GpuTextureViewDimension.d2Array;
        } else if (binding is NodeSampledTexture3D == true) {
          viewDimension = GpuTextureViewDimension.d3;
        }

        textureLayout = GpuTextureBindingLayout(
          sampleType: sampleType,
          viewDimension: viewDimension,
          multisampled: multisampled,
        );

      } else {
        console.error('WebGPUBindingUtils: Unsupported binding "$binding".');
        index++;
        continue;
      }

      entries.add(GpuBindGroupLayoutEntry(
        binding: index++,
        visibility: visibility,
        buffer: bufferLayout,
        sampler: samplerLayout,
        storageTexture: storageTextureLayout,
        texture: textureLayout,
      ));
    }

    return device.createBindGroupLayout(entries);
  }


	/**
	 * Creates bindings from the given bind group definition.
	 *
	 * @param {BindGroup} bindGroup - The bind group.
	 * @param {Array<BindGroup>} bindings - Array of bind groups.
	 * @param {number} cacheIndex - The cache index.
	 * @param {number} version - The version.
	 */
	createBindings(BindGroup bindGroup, List<BindGroup> bindings, int cacheIndex, [int version = 0] ) {
		final backend = this.backend;
    final bindGroupLayoutCache = this.bindGroupLayoutCache;
		final bindingsData = backend.get( bindGroup );

		// setup (static) binding layout and (dynamic) binding group

		let bindLayoutGPU = bindGroupLayoutCache.get( bindGroup.bindingsReference );

		if ( bindLayoutGPU == null ) {
			bindLayoutGPU = this.createBindingsLayout( bindGroup );
			bindGroupLayoutCache.set( bindGroup.bindingsReference, bindLayoutGPU );
		}

		let bindGroupGPU;

		if ( cacheIndex > 0 ) {
			if ( bindingsData.groups == null ) {
				bindingsData.groups = [];
				bindingsData.versions = [];
			}

			if ( bindingsData.versions[ cacheIndex ] == version ) {
				bindGroupGPU = bindingsData.groups[ cacheIndex ];
			}
		}

		if ( bindGroupGPU == null ) {
			bindGroupGPU = this.createBindGroup( bindGroup, bindLayoutGPU );

			if ( cacheIndex > 0 ) {
				bindingsData.groups[ cacheIndex ] = bindGroupGPU;
				bindingsData.versions[ cacheIndex ] = version;
			}
		}

		bindingsData.group = bindGroupGPU;
		bindingsData.layout = bindLayoutGPU;
	}

	/// Updates a buffer binding.
	void updateBinding(Buffer binding ) {
		final backend = this.backend;
		final device = backend.device;

		final buffer = binding.buffer;
		final bufferGPU = backend.get( binding ).buffer;

		device.queue.writeBuffer( bufferGPU, 0, buffer, 0 );
	}

	/**
	 * Creates a GPU bind group for the camera index.
	 *
	 * @param {Uint32Array} data - The index data.
	 * @param {GPUBindGroupLayout} layout - The GPU bind group layout.
	 * @return {GPUBindGroup} The GPU bind group.
	 */
  GpuBindGroup createBindGroupIndex(Uint32List data, GpuBindGroupLayout layout) {
    final GpuDevice device = backend.device;
    
    // gpux combines flags via logical OR or bitwise operations depending on native bindings
    final usage = GpuBufferUsage.uniform | GpuBufferUsage.copyDst;
    final int index = data[0];

    // gpux descriptors use structured classes instead of loose Map strings
    final buffer = device.createBuffer(
      label: 'bindingCameraIndex_$index',
      size: 16, // uint32(4) * 4
      usage: usage,
    );

    // gpux queue implementation typically mirrors WebGPU specification patterns
    device.queue.writeBuffer(
      buffer,
      data.buffer.asUint8List(),
      bufferOffset: 0,
      dataOffset: 0,
    );

    final entries = [
      GpuBindGroupEntry.buffer(
        binding: 0,
        buffer: buffer,
      )
    ];

    return device.createBindGroup(
      label: 'bindGroupCameraIndex_$index',
      layout: layout,
      entries: entries,
    );
  }

  GpuBindGroup createBindGroup(dynamic bindGroup, GpuBindGroupLayout layoutGPU) {
    final GpuDevice device = backend.device;
    int bindingPoint = 0;
    final List<GpuBindGroupEntry> entriesGPU = [];

    for (final binding in bindGroup.bindings) {
      if (binding.isUniformBuffer) {
        final bindingData = backend.get(binding);
        if (bindingData.buffer == null) {
          final int byteLength = binding.byteLength;
          final usage = GpuBufferUsage.uniform | GpuBufferUsage.copyDst;
          
          final bufferGPU = device.createBuffer(
            label: 'bindingBuffer_${binding.name}',
            size: byteLength,
            usage: usage,
          );
          bindingData.buffer = bufferGPU;
        }
        
        entriesGPU.add(GpuBindGroupEntry.buffer(
          binding: bindingPoint,
          buffer: bindingData.buffer,
        ));
        
      } else if (binding.isStorageBuffer) {
        final bindingData = backend.get(binding);
        if (bindingData.buffer == null) {
          final attribute = binding.attribute;
          bindingData.buffer = backend.get(attribute).buffer;
        }
        
        entriesGPU.add(GpuBindGroupEntry.buffer(
          binding: bindingPoint,
          buffer: bindingData.buffer,
        ));
        
      } else if (binding is Sampler) {
        final textureGPU = backend.get(binding.texture);
        
        entriesGPU.add(GpuBindGroupEntry.sampler(
          binding: bindingPoint,
          sampler: textureGPU.sampler, // Direct GpuSampler object assignment
        ));
        
      } else if (binding is SampledTexture) {
        final textureData = backend.get(binding.texture);
        dynamic resourceGPU; // GpuExternalTexture or GpuTextureView
        
        if (textureData.externalTexture != null) {
          resourceGPU = device.importExternalTexture(GpuExternalTextureDescriptor(
            source: textureData.externalTexture,
          ));
        } else {
          final int mipLevelCount = binding.store ? 1 : textureData.texture.mipLevelCount;
          String propertyName = 'view-${textureData.texture.width}-${textureData.texture.height}';
          
          if (textureData.texture.depthOrArrayLayers > 1) {
            propertyName += '-${textureData.texture.depthOrArrayLayers}';
          }
          propertyName += '-$mipLevelCount';
          
          resourceGPU = textureData[propertyName];
          
          if (resourceGPU == null) {
            final aspectGPU = GpuTextureAspect.all;
            GpuTextureViewDimension dimensionViewGPU;
            
            if (binding is SampledCubeTexture) {
              dimensionViewGPU = GpuTextureViewDimension.cube;
            } else if (binding is SampledTexture3D) {
              dimensionViewGPU = GpuTextureViewDimension.d3;
            } else if (binding.texture is ArrayTexture || 
                       binding.texture is DataArrayTexture || 
                       binding.texture is CompressedArrayTexture) {
              dimensionViewGPU = GpuTextureViewDimension.d2Array;
            } else {
              dimensionViewGPU = GpuTextureViewDimension.d2;
            }
            
            resourceGPU = textureData[propertyName] = textureData.texture.createView(
              aspect: aspectGPU,
              dimension: dimensionViewGPU,
              mipLevelCount: mipLevelCount,
            );
          }
        }
        
        entriesGPU.add(GpuBindGroupEntry(
          binding: bindingPoint,
          resource: resourceGPU, // Casts gracefully into binding point target
        ));
      }
      
      bindingPoint++;
    }

    return device.createBindGroup(
      label: 'bindGroup_${bindGroup.name}',
      layout: layoutGPU,
      entries: entriesGPU,
    );
  }
}
