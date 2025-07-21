import "package:three_js_gpu/common/sampled_texture.dart";

/**
 * A special form of sampled texture binding type.
 * It's texture value is managed by a node object.
 *
 * @private
 * @augments SampledTexture
 */
class NodeSampledTexture extends SampledTexture {
  TextureNode textureNode;
  UniformGroupNode groupNode;
  String? access;
	/**
	 * Constructs a new node-based sampled texture.
	 *
	 * @param {string} name - The textures's name.
	 * @param {TextureNode} textureNode - The texture node.
	 * @param {UniformGroupNode} groupNode - The uniform group node.
	 * @param {?string} [access=null] - The access type.
	 */
	NodeSampledTexture(String name, this.textureNode, this.groupNode, [this.access]):super( name, textureNode != null? textureNode.value : null );

	bool needsBindingsUpdate(int generation ) {
		return this.textureNode.value != this.texture || super.needsBindingsUpdate( generation );
	}

	bool update() {
		final textureNode = this.textureNode;

		if ( this.texture != textureNode.value ) {
			this.texture = textureNode.value;
			return true;
		}

		return super.update();
	}
}

/**
 * A special form of sampled cube texture binding type.
 * It's texture value is managed by a node object.
 *
 * @private
 * @augments NodeSampledTexture
 */
class NodeSampledCubeTexture extends NodeSampledTexture {
  bool isSampledCubeTexture = true;
	/**
	 * Constructs a new node-based sampled cube texture.
	 *
	 * @param {string} name - The textures's name.
	 * @param {TextureNode} textureNode - The texture node.
	 * @param {UniformGroupNode} groupNode - The uniform group node.
	 * @param {?string} [access=null] - The access type.
	 */
	NodeSampledCubeTexture(super.name, super.textureNode, super.groupNode, [super.access] );
}

/**
 * A special form of sampled 3D texture binding type.
 * It's texture value is managed by a node object.
 *
 * @private
 * @augments NodeSampledTexture
 */
class NodeSampledTexture3D extends NodeSampledTexture {
  bool isSampledTexture3D = true;
	/**
	 * Constructs a new node-based sampled 3D texture.
	 *
	 * @param {string} name - The textures's name.
	 * @param {TextureNode} textureNode - The texture node.
	 * @param {UniformGroupNode} groupNode - The uniform group node.
	 * @param {?string} [access=null] - The access type.
	 */
	NodeSampledTexture3D(super.name, super.textureNode, super.groupNode, [super.access] );
}