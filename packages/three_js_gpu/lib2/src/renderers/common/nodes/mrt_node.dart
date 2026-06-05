// Predefined blend modes for MRT nodes.
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';

import '../../../nodes/code/node_builder.dart';
import '../../../nodes/core/node.dart';
import '../blendmode.dart';
import 'output_struct_node.dart';

final _noBlending = BlendMode(NoBlending);
final _materialBlending = BlendMode(MaterialBlending);

/// Returns the MRT texture index for the given name.
int getTextureIndex(List<Texture> textures, String name) {
  for (int i = 0; i < textures.length; i++) {
    if (textures[i].name == name) {
      return i;
    }
  }
  return -1;
}

/// This node can be used setup a MRT context for rendering.
class MRTNode extends OutputStructNode {
  /// A dictionary representing the MRT outputs.
  final Map<String, dynamic> outputNodes;

  /// A dictionary storing the blend modes for each output.
  late final Map<String, BlendMode> blendModes;

  /// This flag can be used for type testing.
  final bool isMRTNode = true;

  @override
  String get type => 'MRTNode';

  /// Constructs a new output struct node.
  MRTNode(this.outputNodes) : super() {
    blendModes = {'output': _materialBlending};
  }

  /// Sets the blend mode for the given output name.
  MRTNode setBlendMode(String name, BlendMode blend) {
    blendModes[name] = blend;
    return this;
  }

  /// Returns the blend mode for the given output name.
  BlendMode getBlendMode(String name) {
    return blendModes[name] ?? _noBlending;
  }

  /// Returns `true` if the MRT node has an output with the given name.
  bool has(String name) {
    return outputNodes[name] != null;
  }

  /// Returns the output node for the given name.
  dynamic get(String name) {
    return outputNodes[name];
  }

  /// Merges the outputs of the given MRT node with the outputs of this node.
  MRTNode merge(MRTNode mrtNode) {
    final outputs = {...outputNodes, ...mrtNode.outputNodes};
    final blendings = {...blendModes, ...mrtNode.blendModes};
    
    final mrtTarget = mrt(outputs);
    mrtTarget.blendModes = blendings;
    return mrtTarget;
  }

  @override
  Node? setup(NodeBuilder builder) {
    final mrt = builder.renderer.getRenderTarget();
    final List<Node> members = [];
    final textures = mrt?.textures;
    if(textures != null){
      for (final name in outputNodes.keys) {
        final index = getTextureIndex(textures, name);
        final type = builder.getOutputType(index);
        members[index] = outputNodes[name].convert(type);
      }
    }

    this.members = members;
    return super.setup(builder);
  }
}

/// TSL function for creating a MRT node.
MRTNode mrt(Map<String, dynamic> outputNodes) {
  return nodeProxy(MRTNode, outputNodes);
}
