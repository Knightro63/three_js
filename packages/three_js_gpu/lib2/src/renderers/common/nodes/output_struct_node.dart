
import '../../../nodes/code/node_builder.dart';
import '../../../nodes/core/node.dart';

/// This node can be used to define multiple outputs in a shader programs.
class OutputStructNode extends Node {
  /// An array of nodes which defines the output.
  List<Node> members;

  /// This flag can be used for type testing.
  final bool isOutputStructNode = true;

  @override
  String get type => 'OutputStructNode';

  /// Constructs a new output struct node. 
  /// Takes a flexible list of [members].
  OutputStructNode([this.members = const []]) : super();

  @override
  String generateNodeType(dynamic builder) {
    return 'OutputType';
  }

  @override
  String generate(NodeBuilder builder,[String? type]) {
    final nodeData = builder.getDataFromNode(this);

    if (nodeData.membersLayout == null) {
      final List<Map<String, dynamic>> membersLayout = [];

      for (int i = 0; i < members.length; i++) {
        final name = 'm$i';
        final type = members[i].getNodeType(builder);
        membersLayout.add({'name': name, 'type': type, 'index': i});
      }

      nodeData.membersLayout = membersLayout;
      nodeData.structType = builder.getOutputStructTypeFromNode(this, nodeData.membersLayout);
    }

    // Fixed the original JS reference bug by ensuring propertyName is defined
    final String propertyName = builder.getOutputStructName(); 
    final structPrefix = propertyName.isNotEmpty ? '$propertyName.' : '';

    for (int i = 0; i < members.length; i++) {
      final snippet = members[i].build(builder, nodeData.membersLayout[i]['type']);
      builder.addLineFlowCode('$structPrefix\m$i = $snippet', this);
    }

    return propertyName;
  }
}

/// TSL function for creating an output struct node.
OutputStructNode outputStruct([List<Node> members = const []]) {
  return nodeProxy(OutputStructNode, members);
}
