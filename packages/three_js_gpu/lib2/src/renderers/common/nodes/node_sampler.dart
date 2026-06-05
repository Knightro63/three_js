import "../../../nodes/core/uniform_group_node.dart";
import "../sampler.dart";

/// A special form of sampler binding type.
/// It's texture value is managed by a node object.
class NodeSampler extends Sampler {
  UniformGroupNode groupNode;

	NodeSampler(String name, TextureNode? textureNode, this.groupNode ):super( name, textureNode != null? textureNode.value : null );

	/// Updates the texture value of this sampler.
	void update() {
		texture = this.textureNode.value;
	}
}
