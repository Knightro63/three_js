import "package:three_js_gpu/common/sampler.dart";

/**
 * A special form of sampler binding type.
 * It's texture value is managed by a node object.
 *
 * @private
 * @augments Sampler
 */
class NodeSampler extends Sampler {
  UniformGroupNode groupNode;
	/**
	 * Constructs a new node-based sampler.
	 *
	 * @param {string} name - The samplers's name.
	 * @param {TextureNode} textureNode - The texture node.
	 * @param {UniformGroupNode} groupNode - The uniform group node.
	 */
	NodeSampler(String name, TextureNode? textureNode, this.groupNode ):super( name, textureNode != null? textureNode.value : null );

	/**
	 * Updates the texture value of this sampler.
	 */
	void update() {
		this.texture = this.textureNode.value;
	}
}
