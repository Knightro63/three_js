import "package:three_js_gpu/common/bind_group.dart";

/**
 * This module represents the state of a node builder after it was
 * used to build the nodes for a render object. The state holds the
 * results of the build for further processing in the renderer.
 *
 * Render objects with identical cache keys share the same node builder state.
 *
 * @private
 */
class NodeBuilderState {
  String vertexShader;
  String fragmentShader; 
  String computeShader;
  List<NodeAttribute> nodeAttributes;
  List<BindGroup> bindings;
  List<Node> updateNodes;
  List<Node> updateBeforeNodes; 
  List<Node> updateAfterNodes;
  NodeMaterialObserver observer; 
  List transforms;
  int usedTimes = 0;

	NodeBuilderState(
    this.vertexShader, 
    this.fragmentShader, 
    this.computeShader, 
    this.nodeAttributes, 
    this.bindings, 
    this.updateNodes, 
    this.updateBeforeNodes, 
    this.updateAfterNodes, 
    this.observer, 
    List? transforms
  ) {
		this.transforms = transforms ?? [];
	}

	/**
	 * This method is used to create a array of bind groups based
	 * on the existing bind groups of this state. Shared groups are
	 * not cloned.
	 *
	 * @return {Array<BindGroup>} A array of bind groups.
	 */
	List<BindGroup> createBindings() {
		final bindings = [];

		for ( final instanceGroup in this.bindings ) {
			final shared = instanceGroup.bindings[ 0 ].groupNode.shared; // All bindings in the group must have the same groupNode.

			if ( shared != true ) {
				final bindingsGroup = new BindGroup( instanceGroup.name, [], instanceGroup.index, instanceGroup );
				bindings.add( bindingsGroup );

				for ( final instanceBinding in instanceGroup.bindings ) {
					bindingsGroup.bindings.add( instanceBinding.clone() );
				}

			} else {
				bindings.add( instanceGroup );
			}
		}

		return bindings;
	}
}
