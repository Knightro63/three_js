import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_gpu/common/attributes.dart';
import 'package:three_js_gpu/common/backend.dart';
import 'package:three_js_gpu/common/bind_group.dart';
import 'package:three_js_gpu/common/constants.dart';
import 'package:three_js_gpu/common/data_map.dart';
import 'package:three_js_gpu/common/info.dart';
import 'package:three_js_gpu/common/pipelines.dart';
import 'package:three_js_gpu/common/sampled_texture.dart';
import 'package:three_js_gpu/common/storage_buffer.dart';
import 'package:three_js_gpu/common/textures.dart';
import 'package:three_js_gpu/gpu_backend.dart';

/**
 * This renderer module manages the bindings of the renderer.
 *
 * @private
 * @augments DataMap
 */
class Bindings extends DataMap {
  Backend backend;
  Textures textures;
  Pipelines pipelines;
  Attributes attributes;
  Info info;
  Nodes nodes;

	Bindings(this.backend, this.nodes, this.textures, this.attributes, this.pipelines, this.info ):super() {
		this.pipelines.bindings = this; // assign bindings to pipelines
	}

	List<BindGroup> getForRender(RenderObject renderObject ) {
		final bindings = renderObject.getBindings();

		for ( final bindGroup in bindings ) {
			final groupData = this.get( bindGroup );

			if ( groupData.bindGroup == null ) {
				this._init( bindGroup );
				this.backend.createBindings( bindGroup, bindings, 0 );
				groupData.bindGroup = bindGroup;
			}
		}

		return bindings;
	}

	List<BindGroup> getForCompute(Node computeNode ) {
		final bindings = this.nodes.getForCompute( computeNode ).bindings;

		for ( final bindGroup in bindings ) {

			final groupData = this.get( bindGroup );

			if ( groupData.bindGroup == null ) {

				this._init( bindGroup );
				this.backend.createBindings( bindGroup, bindings, 0 );
				groupData.bindGroup = bindGroup;
			}
		}

		return bindings;
	}

	void updateForCompute(Node computeNode ) {
		this._updateBindings( this.getForCompute( computeNode ) );
	}

	void updateForRender(RenderObject renderObject ) {
		this._updateBindings( this.getForRender( renderObject ) );
	}

	void _updateBindings(List<BindGroup> bindings ) {
		for (final bindGroup in bindings ) {
			this._update( bindGroup, bindings );
		}
	}

	/**
	 * Initializes the given bind group.
	 *
	 * @param {BindGroup} bindGroup - The bind group to initialize.
	 */
	_init( bindGroup ) {
		for ( final binding in bindGroup.bindings ) {
			if ( binding is SampledTexture ) {
				this.textures.updateTexture( binding.texture );
			} 
      else if ( binding is StorageBuffer ) {
				final attribute = binding.attribute;
				final attributeType = attribute.isIndirectStorageBufferAttribute ? AttributeType.indirect : AttributeType.storage;

				this.attributes.update( attribute, attributeType );
			}
		}
	}

	/**
	 * Updates the given bind group.
	 *
	 * @param {BindGroup} bindGroup - The bind group to update.
	 * @param {Array<BindGroup>} bindings - The bind groups.
	 */
	_update( bindGroup, bindings ) {
		final backend = this;

		bool needsBindingsUpdate = false;
		bool cacheBindings = true;
		int cacheIndex = 0;
		int version = 0;

		// iterate over all bindings and check if buffer updates or a new binding group is required

		for ( final binding in bindGroup.bindings ) {
			if ( binding is NodeUniformsGroup ) {
				final updated = this.nodes.updateGroup( binding );

				// every uniforms group is a uniform buffer. So if no update is required,
				// we move one with the next binding. Otherwise the next if block will update the group.
				if ( updated == false ) continue;
			}

			if ( binding.isStorageBuffer ) {
				final attribute = binding.attribute;
				final attributeType = attribute.isIndirectStorageBufferAttribute ? AttributeType.indirect : AttributeType.storage;

				this.attributes.update( attribute, attributeType );
			}

			if ( binding.isUniformBuffer ) {
				final updated = binding.update();

				if ( updated ) {
					backend.updateBinding( binding );
				}
			} 
      else if ( binding.isSampler ) {
				binding.update();
			} 
      else if ( binding.isSampledTexture ) {

				final texturesTextureData = this.textures.get( binding.texture );

				if ( binding.needsBindingsUpdate( texturesTextureData.generation ) ) needsBindingsUpdate = true;

				final updated = binding.update();

				final texture = binding.texture;

				if ( updated ) {
					this.textures.updateTexture( texture );
				}

				final textureData = backend.get( texture );

				if ( textureData.externalTexture != null || texturesTextureData is DefaultTexture ) {
					cacheBindings = false;
				} else {
					cacheIndex = cacheIndex * 10 + texture.id;
					version += texture.version;
				}

				if ( backend is WebGPUBackend == true && textureData.texture == null && textureData.externalTexture == null ) {
					// TODO: Remove this once we found why updated === false isn't bound to a texture in the WebGPU backend
					console.error( 'Bindings._update: binding should be available:', binding, updated, texture, binding.textureNode.value, needsBindingsUpdate );

					this.textures.updateTexture( texture );
					needsBindingsUpdate = true;
				}

				if ( texture.isStorageTexture == true ) {
					final textureData = this.get( texture );

					if ( binding.store == true ) {
						textureData.needsMipmap = true;
					} 
          else if ( this.textures.needsMipmaps( texture ) && textureData.needsMipmap == true ) {
						this.backend.generateMipmaps( texture );
						textureData.needsMipmap = false;
					}
				}
			}
		}

		if ( needsBindingsUpdate == true ) {
			this.backend.updateBindings( bindGroup, bindings, cacheBindings ? cacheIndex : 0, version );
		}
	}
}
