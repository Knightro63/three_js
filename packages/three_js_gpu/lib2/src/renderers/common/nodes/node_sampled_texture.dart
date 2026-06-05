import "../../../nodes/core/uniform_group_node.dart";
import "../sampled_texture.dart";

/// A special form of sampled texture binding type.
/// It's texture value is managed by a node object.
class NodeSampledTexture extends SampledTexture {
  TextureNode textureNode;
  UniformGroupNode groupNode;
  String? access;

	NodeSampledTexture(String name, this.textureNode, this.groupNode, [this.access]):super( name, textureNode != null? textureNode.value : null );

  @override
	bool needsBindingsUpdate(int generation ) {
		return textureNode.value != texture || super.needsBindingsUpdate( generation );
	}

  @override
	bool update() {
		final textureNode = this.textureNode;

		if ( texture != textureNode.value ) {
			texture = textureNode.value;
			return true;
		}

		return super.update();
	}
}

/// A special form of sampled cube texture binding type.
/// It's texture value is managed by a node object.
class NodeSampledCubeTexture extends NodeSampledTexture {
  bool isSampledCubeTexture = true;
	NodeSampledCubeTexture(super.name, super.textureNode, super.groupNode, [super.access] );
}

/// A special form of sampled 3D texture binding type.
/// It's texture value is managed by a node object.
class NodeSampledTexture3D extends NodeSampledTexture {
  bool isSampledTexture3D = true;
	NodeSampledTexture3D(super.name, super.textureNode, super.groupNode, [super.access] );
}