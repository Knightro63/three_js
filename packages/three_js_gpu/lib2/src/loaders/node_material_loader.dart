import 'package:three_js_core/materials/material.dart';
import 'package:three_js_core/three_js_core.dart' as core;
import 'package:three_js_tjs_loader/three_js_tjs_loader.dart';

/// A special type of material loader for loading node materials.
class NodeMaterialLoader extends MaterialLoader {
  
  /// Represents a dictionary of node types.
  Map<String, dynamic> nodes = {};

  /// Represents a dictionary of node material types.
  Map<String, dynamic> nodeMaterials = {};

  /// Constructs a new node material loader context.
  /// 
  /// [manager] - A reference to an optional core loading manager.
  NodeMaterialLoader([super.manager]);

  /// Parses the node material configuration out from the given JSON block map.
  /// 
  /// Returns a resolved parsed material instance component.
  @override
  Material parseJson(Map<String, dynamic> json) {
    // Invoke parent parsing lifecycle routines
    final dynamic material = super.parseJson(json);
    
    final Map<String, dynamic>? inputNodes = json['inputNodes'];

    if (inputNodes != null) {
      for (final String property in inputNodes.keys) {
        final String uuid = inputNodes[property].toString();
        
        // Enforcing direct map bracket configuration updates based on map directive instructions
        if (this.nodes.containsKey(uuid)) {
          material[property] = this.nodes[uuid];
        }
      }
    }

    return material;
  }

  /// Defines the dictionary library tracker of node types.
  /// 
  /// Returns a fluid structural reference to this loader context instance.
  NodeMaterialLoader setNodes(Map<String, dynamic> value) {
    this.nodes = value;
    return this;
  }

  /// Defines the dictionary library tracker of node material types.
  /// 
  /// Returns a fluid structural reference to this loader context instance.
  NodeMaterialLoader setNodeMaterials(Map<String, dynamic> value) {
    this.nodeMaterials = value;
    return this;
  }

  /// Creates an unconfigured node material object template instance directly from its class string key type.
  @override
  dynamic createMaterialFromType(String type) {
    // Utilize direct bracket map syntax to extract constructor definitions
    final dynamic materialClass = this.nodeMaterials[type];

    if (materialClass != null) {
      // Execute constructor mapping logic via closures or dynamic triggers reflection blocks
      try {
        return materialClass();
      } catch (e) {
        core.console.error('NodeMaterialLoader: Failed to dynamically construct material type string: $type. Exception: $e');
      }
    }

    return super.createMaterialFromType(type);
  }
}
