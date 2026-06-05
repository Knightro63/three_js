import 'package:three_js_core/three_js_core.dart';
import 'attributes.dart';
import 'backend.dart';
import 'bind_group.dart';
import 'constants.dart';
import 'data_map.dart';
import 'info.dart';
import 'nodes/node_uniforms_group.dart';
import 'nodes/nodes.dart';
import 'pipelines.dart';
import 'render_object.dart';
import 'sampled_texture.dart';
import 'sampler.dart';
import 'storage_buffer.dart';
import 'storage_texture.dart';
import 'textures.dart';
import 'uniform_buffer.dart';
import '../gpu_backend.dart';
import '../../nodes/core/node.dart';

class Bindings extends DataMap {
  Backend backend;
  Textures textures;
  Pipelines pipelines;
  Attributes attributes;
  Info info;
  Nodes nodes;

	Bindings(this.backend, this.nodes, this.textures, this.attributes, this.pipelines, this.info ):super() {
		pipelines.bindings = this; // assign bindings to pipelines
	}

	List<BindGroup> getForRender(RenderObject renderObject ) {
		final bindings = renderObject.getBindings();

		for ( final bindGroup in bindings ) {
			final groupData = get( bindGroup );

			if ( groupData.bindGroup == null ) {
				_init( bindGroup );
				backend.createBindings( bindGroup, bindings, 0 );
				groupData.bindGroup = bindGroup;
			}
		}

		return bindings;
	}

	List<BindGroup> getForCompute(Node computeNode ) {
		final bindings = nodes.getForCompute( computeNode ).bindings;

		for ( final bindGroup in bindings ) {
			final groupData = get( bindGroup );

			if ( groupData.bindGroup == null ) {
				_init( bindGroup );
				backend.createBindings( bindGroup, bindings, 0 );
				groupData.bindGroup = bindGroup;
			}
		}

		return bindings;
	}

	void updateForCompute(Node computeNode ) {
		_updateBindings(getForCompute( computeNode ) );
	}

	void updateForRender(RenderObject renderObject ) {
		_updateBindings( getForRender( renderObject ) );
	}

	void _updateBindings(List<BindGroup> bindings ) {
		for (final bindGroup in bindings ) {
			_update( bindGroup, bindings );
		}
	}

	/**
	 * Initializes the given bind group.
	 */
	void _init(BindGroup bindGroup ) {
		for ( final binding in bindGroup.bindings ) {
			if ( binding is SampledTexture ) {
				textures.updateTexture( binding.texture );
			} 
      else if ( binding is StorageBuffer ) {
				final attribute = binding.attribute;
				final attributeType = attribute.isIndirectStorageBufferAttribute ? AttributeType.indirect : AttributeType.storage;

				attributes.update( attribute, attributeType );
			}
		}
	}

	/**
	 * Updates the given bind group.
	 */
	void _update(BindGroup bindGroup, List<BindGroup> bindings ) {
		final backend = this;

		bool needsBindingsUpdate = false;
		bool cacheBindings = true;
		int cacheIndex = 0;
		int version = 0;

		// iterate over all bindings and check if buffer updates or a new binding group is required

		for ( final binding in bindGroup.bindings ) {
			if ( binding is NodeUniformsGroup ) {
				final updated = nodes.updateGroup( binding );

				// every uniforms group is a uniform buffer. So if no update is required,
				// we move one with the next binding. Otherwise the next if block will update the group.
				if ( updated == false ) continue;
			}

			if ( binding is StorageBuffer ) {
				final attribute = binding.attribute;
				final attributeType = attribute.isIndirectStorageBufferAttribute ? AttributeType.indirect : AttributeType.storage;

				attributes.update( attribute, attributeType );
			}

			if ( binding is UniformBuffer ) {
				final updated = binding.update();

				if ( updated ) {
					backend.updateBinding( binding );
				}
			} 
      else if ( binding is Sampler ) {
				binding.update();
			} 
      else if ( binding is SampledTexture ) {

				final texturesTextureData = textures.get( binding.texture );

				if ( binding.needsBindingsUpdate( texturesTextureData.generation ) ) needsBindingsUpdate = true;

				final updated = binding.update();

				final texture = binding.texture;

				if ( updated ) {
					textures.updateTexture( texture );
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

					textures.updateTexture( texture );
					needsBindingsUpdate = true;
				}

				if ( texture is StorageTexture ) {
					final textureData = get( texture );

					if ( binding.store == true ) {
						textureData.needsMipmap = true;
					} 
          else if ( textures.needsMipmaps( texture ) && textureData.needsMipmap == true ) {
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
