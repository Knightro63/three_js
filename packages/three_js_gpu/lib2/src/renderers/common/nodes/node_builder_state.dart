import '../bind_group.dart';

/// This module represents the state of a node builder after it was
/// used to build the nodes for a render object. The state holds the
/// results of the build for further processing in the renderer.
/// 
/// Render objects with identical cache keys share the same node builder state.
class NodeBuilderState {
  /// The native vertex shader code.
  String vertexShader;

  /// The native fragment shader code.
  String fragmentShader;

  /// The native compute shader code.
  String computeShader;

  /// An array with transform attribute objects. Only relevant when using compute shaders with WebGL 2.
  List<Map<String, dynamic>> transforms;

  /// An array of node attributes representing the attributes of the shaders.
  List<dynamic> nodeAttributes; // Maps to NodeAttribute collections

  /// An array of bind groups representing the uniform or storage buffers, textures or samplers of the shader.
  List<BindGroup> bindings;

  /// An array of nodes that implement their `update()` method.
  List<dynamic> updateNodes; // Maps to Node collections

  /// An array of nodes that implement their `updateBefore()` method.
  List<dynamic> updateBeforeNodes; // Maps to Node collections

  /// An array of nodes that implement their `updateAfter()` method.
  List<dynamic> updateAfterNodes; // Maps to Node collections

  /// A node material observer.
  dynamic observer; // Maps to NodeMaterialObserver instance

  /// How often this state is used by render objects.
  int usedTimes = 0;

  /// Constructs a new node builder state context.
  NodeBuilderState({
    required this.vertexShader,
    required this.fragmentShader,
    required this.computeShader,
    required this.nodeAttributes,
    required this.bindings,
    required this.updateNodes,
    required this.updateBeforeNodes,
    required this.updateAfterNodes,
    required this.observer,
    List<Map<String, dynamic>>? transforms,
  }) : this.transforms = transforms ?? const <Map<String, dynamic>>[];

  /// This method is used to create an array of bind groups based
  /// on the existing bind groups of this state. Shared groups are not cloned.
  /// 
  /// Returns an array list of [BindGroup] collections.
  List<BindGroup> createBindings() {
    final List<BindGroup> clonedBindingsList = [];

    for (final BindGroup instanceGroup in this.bindings) {
      // Enforcing map directive bracket syntax rules when checking inner configuration layout metrics
      final dynamic groupNode = instanceGroup.bindings.firstOrNull?['groupNode'];
      final bool shared = groupNode?['shared'] == true;

      // All bindings in the group must have the same groupNode alignment constraints
      if (!shared) {
        final BindGroup bindingsGroup = BindGroup(instanceGroup.name, []);
        clonedBindingsList.add(bindingsGroup);

        for (final dynamic instanceBinding in instanceGroup.bindings) {
          // Clone the instance properties block natively across compilation paths
          bindingsGroup.bindings.add(instanceBinding.clone());
        }
      } else {
        clonedBindingsList.add(instanceGroup);
      }
    }

    return clonedBindingsList;
  }
}
