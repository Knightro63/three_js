import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_gpu/gpu_backend.dart';
import 'package:three_js_math/three_js_math.dart';

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
	createBindingsLayout( bindGroup ) {

		final backend = this.backend;
		final device = backend.device;

		final entries = [];

		let index = 0;

		for ( final binding of bindGroup.bindings ) {

			final bindingGPU = {
				'binding': index ++,
				'visibility': binding.visibility
			};

			if ( binding.isUniformBuffer || binding.isStorageBuffer ) {

				final buffer = {}; // GPUBufferBindingLayout

				if ( binding.isStorageBuffer ) {

					if ( binding.visibility & 4 ) {

						// compute

						if ( binding.access == NodeAccess.READ_WRITE || binding.access == NodeAccess.WRITE_ONLY ) {

							buffer.type = GPUBufferBindingType.Storage;

						} else {

							buffer.type = GPUBufferBindingType.ReadOnlyStorage;

						}

					} else {

						buffer.type = GPUBufferBindingType.ReadOnlyStorage;

					}

				}

				bindingGPU.buffer = buffer;

			} else if ( binding.isSampler ) {

				final sampler = {}; // GPUSamplerBindingLayout

				if ( binding.texture.isDepthTexture ) {

					if ( binding.texture.compareFunction !== null ) {

						sampler.type = GPUSamplerBindingType.Comparison;

					} else if ( backend.compatibilityMode ) {

						sampler.type = GPUSamplerBindingType.NonFiltering;

					}

				}

				bindingGPU.sampler = sampler;

			} else if ( binding.isSampledTexture && binding.store ) {

				final storageTexture = {}; // GPUStorageTextureBindingLayout
				storageTexture.format = this.backend.get( binding.texture ).texture.format;

				final access = binding.access;

				if ( access == NodeAccess.READ_WRITE ) {

					storageTexture.access = GPUStorageTextureAccess.ReadWrite;

				} else if ( access == NodeAccess.WRITE_ONLY ) {

					storageTexture.access = GPUStorageTextureAccess.WriteOnly;

				} else {

					storageTexture.access = GPUStorageTextureAccess.ReadOnly;

				}

				if ( binding.texture.isArrayTexture ) {

					storageTexture.viewDimension = GPUTextureViewDimension.TwoDArray;

				} else if ( binding.texture.is3DTexture ) {

					storageTexture.viewDimension = GPUTextureViewDimension.ThreeD;

				}

				bindingGPU.storageTexture = storageTexture;

			} else if ( binding.isSampledTexture ) {

				final texture = {}; // GPUTextureBindingLayout

				final { primarySamples } = backend.utils.getTextureSampleData( binding.texture );

				if ( primarySamples > 1 ) {

					texture.multisampled = true;

					if ( ! binding.texture.isDepthTexture ) {

						texture.sampleType = GPUTextureSampleType.UnfilterableFloat;

					}

				}

				if ( binding.texture.isDepthTexture ) {

					if ( backend.compatibilityMode && binding.texture.compareFunction == null ) {

						texture.sampleType = GPUTextureSampleType.UnfilterableFloat;

					} else {

						texture.sampleType = GPUTextureSampleType.Depth;

					}

				} else if ( binding.texture.isDataTexture || binding.texture.isDataArrayTexture || binding.texture.isData3DTexture ) {

					final type = binding.texture.type;

					if ( type == IntType ) {

						texture.sampleType = GPUTextureSampleType.SInt;

					} else if ( type == UnsignedIntType ) {

						texture.sampleType = GPUTextureSampleType.UInt;

					} else if ( type == FloatType ) {

						if ( this.backend.hasFeature( 'float32-filterable' ) ) {

							texture.sampleType = GPUTextureSampleType.Float;

						} else {

							texture.sampleType = GPUTextureSampleType.UnfilterableFloat;

						}

					}

				}

				if ( binding.isSampledCubeTexture ) {

					texture.viewDimension = GPUTextureViewDimension.Cube;

				} else if ( binding.texture.isArrayTexture || binding.texture.isDataArrayTexture || binding.texture.isCompressedArrayTexture ) {

					texture.viewDimension = GPUTextureViewDimension.TwoDArray;

				} else if ( binding.isSampledTexture3D ) {

					texture.viewDimension = GPUTextureViewDimension.ThreeD;

				}

				bindingGPU.texture = texture;

			} else {

				console.error( 'WebGPUBindingUtils: Unsupported binding "${ binding }".' );

			}

			entries.push( bindingGPU );

		}

		return device.createBindGroupLayout( { entries } );

	}

	/**
	 * Creates bindings from the given bind group definition.
	 *
	 * @param {BindGroup} bindGroup - The bind group.
	 * @param {Array<BindGroup>} bindings - Array of bind groups.
	 * @param {number} cacheIndex - The cache index.
	 * @param {number} version - The version.
	 */
	createBindings( bindGroup, bindings, cacheIndex, version = 0 ) {
		final { backend, bindGroupLayoutCache } = this;
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

	/**
	 * Updates a buffer binding.
	 *
	 *  @param {Buffer} binding - The buffer binding to update.
	 */
	updateBinding(Buffef binding ) {
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
	GPUBindGroup createBindGroupIndex(Uint32Array data, GPUBindGroupLayout layout ) {
		final backend = this.backend;
		final device = backend.device;

		final usage = GPUBufferUsage.UNIFORM | GPUBufferUsage.COPY_DST;
		final index = data[ 0 ];

		final buffer = device.createBuffer( {
			'label': 'bindingCameraIndex_$index',
			'size': 16, // uint(4) * 4
			'usage': usage
		} );

		device.queue.writeBuffer( buffer, 0, data, 0 );

		final entries = [ { 'binding': 0, 'resource': { 'buffer': buffer } } ];

		return device.createBindGroup( {
			'label': 'bindGroupCameraIndex_$index',
			'layout': layout,
			'entries': entries
		} );

	}

	/**
	 * Creates a GPU bind group for the given bind group and GPU layout.
	 *
	 * @param {BindGroup} bindGroup - The bind group.
	 * @param {GPUBindGroupLayout} layoutGPU - The GPU bind group layout.
	 * @return {GPUBindGroup} The GPU bind group.
	 */
	createBindGroup( bindGroup, layoutGPU ) {

		final backend = this.backend;
		final device = backend.device;

		let bindingPoint = 0;
		final entriesGPU = [];

		for ( final binding of bindGroup.bindings ) {

			if ( binding.isUniformBuffer ) {

				final bindingData = backend.get( binding );

				if ( bindingData.buffer == null ) {

					final byteLength = binding.byteLength;
					final usage = GPUBufferUsage.UNIFORM | GPUBufferUsage.COPY_DST;

					final bufferGPU = device.createBuffer( {
						'label': 'bindingBuffer_${binding.name}',
						'size': byteLength,
						'usage': usage
					} );

					bindingData.buffer = bufferGPU;

				}

				entriesGPU.push( { binding: bindingPoint, resource: { buffer: bindingData.buffer } } );

			} else if ( binding.isStorageBuffer ) {

				final bindingData = backend.get( binding );

				if ( bindingData.buffer == null ) {

					final attribute = binding.attribute;
					//final usage = GPUBufferUsage.STORAGE | GPUBufferUsage.VERTEX | /*GPUBufferUsage.COPY_SRC |*/ GPUBufferUsage.COPY_DST;

					//backend.attributeUtils.createAttribute( attribute, usage ); // @TODO: Move it to universal renderer

					bindingData.buffer = backend.get( attribute ).buffer;

				}

				entriesGPU.add( { 'binding': bindingPoint, 'resource': { 'buffer': bindingData.buffer } } );

			} 
      else if ( binding is Sampler ) {
				final textureGPU = backend.get( binding.texture );
				entriesGPU.add( { 'binding': bindingPoint, 'resource': textureGPU.sampler } );
			} 
      else if ( binding is SampledTexture ) {
				final textureData = backend.get( binding.texture );
				let resourceGPU;

				if ( textureData.externalTexture != null ) {
					resourceGPU = device.importExternalTexture( { source: textureData.externalTexture } );
				} 
        else {
					final mipLevelCount = binding.store ? 1 : textureData.texture.mipLevelCount;
					let propertyName = 'view-${ textureData.texture.width }-${ textureData.texture.height }';

					if ( textureData.texture.depthOrArrayLayers > 1 ) {
						propertyName += '-${ textureData.texture.depthOrArrayLayers }';
					}

					propertyName += '-${ mipLevelCount }';
					resourceGPU = textureData[ propertyName ];

					if ( resourceGPU == null ) {
						final aspectGPU = GPUTextureAspect.All;

						let dimensionViewGPU;

						if ( binding.isSampledCubeTexture ) {
							dimensionViewGPU = GPUTextureViewDimension.Cube;
						} 
            else if ( binding.isSampledTexture3D ) {
							dimensionViewGPU = GPUTextureViewDimension.ThreeD;
						} 
            else if ( binding.texture.isArrayTexture || binding.texture.isDataArrayTexture || binding.texture.isCompressedArrayTexture ) {
							dimensionViewGPU = GPUTextureViewDimension.TwoDArray;
						} 
            else {
							dimensionViewGPU = GPUTextureViewDimension.TwoD;
						}

						resourceGPU = textureData[ propertyName ] = textureData.texture.createView( { 'aspect': aspectGPU, 'dimension': dimensionViewGPU, 'mipLevelCount': mipLevelCount } );
					}
				}

				entriesGPU.add( { 'binding': bindingPoint, 'resource': resourceGPU } );
			}

			bindingPoint ++;
		}

		return device.createBindGroup( {
			'label': 'bindGroup_' + bindGroup.name,
			'layout': layoutGPU,
			'entries': entriesGPU
		} );
	}
}
