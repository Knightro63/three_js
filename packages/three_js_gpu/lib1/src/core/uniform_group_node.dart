import '../../src/core/node.dart';

/// This node can be used to group single instances of {@link UniformNode}
/// and manage them as a uniform buffer.
///
/// In most cases, the predefined nodes `objectGroup`, `renderGroup` and `frameGroup`
/// will be used when defining the {@link UniformNode#groupNode} property.
///
/// - `objectGroup`: Uniform buffer per object.
/// - `renderGroup`: Shared uniform buffer, updated once per render call.
/// - `frameGroup`: Shared uniform buffer, updated once per frame.
class UniformGroupNode extends Node {
  String name;
  bool shared;
  int order;


  @override
	String get type => 'UniformGroupNode';

	UniformGroupNode(this.name,[this.shared = false, this.order = 1 ]):super();

  @override
	serialize( data ) {
		super.serialize( data );

		data.name = name;
		data.version = version;
		data.shared = shared;
	}

  @override
	deserialize( data ) {
		super.deserialize( data );

		name = data.name;
		version = data.version;
		shared = data.shared;
	}
}

/// TSL function for creating a uniform group node with the given name.
uniformGroup( name ) => UniformGroupNode( name );

/// TSL function for creating a shared uniform group node with the given name and order.
sharedUniformGroup( name, [order = 0] ) => UniformGroupNode( name, true, order );

/// TSL object that represents a shared uniform group node which is updated once per frame.
final frameGroup = sharedUniformGroup( 'frame' );

/// TSL object that represents a shared uniform group node which is updated once per render.
final renderGroup = sharedUniformGroup( 'render' );

/// TSL object that represents a uniform group node which is updated once per object.
final objectGroup = uniformGroup( 'object' );
