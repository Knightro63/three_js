/**
 * {@link NodeBuilder} is going to create instances of this class during the build process
 * of nodes. They represent the final shader uniforms that are going to be generated
 * by the builder. A dictionary of node uniforms is maintained in {@link NodeBuilder#uniforms}
 * for this purpose.
 */
class NodeUniform {
  String name;
  String type;
  UniformNodenode node;

	NodeUniform(this.name, this.type, this.node );

	get value{
		return this.node.value;
	}

	set value( val ) {
		this.node.value = val;
	}

	int get id{
		return this.node.id;
	}

	UniformGroupNode get groupNode{
		return this.node.groupNode;
	}
}
