import 'package:three_js_tjs_loader/three_js_tjs_loader.dart';
import './node_loader.dart';
import './node_material_loader.dart';

/// A special type of object loader for loading 3D objects using node materials.
class NodeObjectLoader extends ObjectLoader {
  
  /// Represents a dictionary of node types.
  Map<String, dynamic> nodes = {};

  /// Represents a dictionary of node material types.
  Map<String, dynamic> nodeMaterials = {};

  /// A reference to hold the `nodes` JSON property.
  List<dynamic>? _nodesJSON;

  /// Constructs a new node object loader.
  /// 
  /// [manager] - A reference to an optional loading manager.
  NodeObjectLoader([super.manager]);

  /// Defines the dictionary of node types.
  /// 
  /// Returns a fluent [NodeObjectLoader] reference to this loader.
  NodeObjectLoader setNodes(Map<String, dynamic> value) {
    this.nodes = value;
    return this;
  }

  /// Defines the dictionary of node material types.
  /// 
  /// Returns a fluent [NodeObjectLoader] reference to this loader.
  NodeObjectLoader setNodeMaterials(Map<String, dynamic> value) {
    this.nodeMaterials = value;
    return this;
  }

  /// Parses the node objects from the given JSON.
  /// 
  /// [json] - The JSON definition map.
  /// [onLoad] - Optional callback function triggered when completion ticks finish.
  @override
  dynamic parse(Map<String, dynamic> json, [Function? onLoad]) {
    this._nodesJSON = json['nodes'] as List<dynamic>?;
    
    final dynamic data = super.parse(json, onLoad);
    
    this._nodesJSON = null; // Clean up memory reference tracks
    return data;
  }

  /// Async version of [parse].
  /// 
  /// Returns a [Future] that resolves with the fully parsed 3D object.
  @override
  Future<dynamic> parseAsync(Map<String, dynamic> json) async {
    this._nodesJSON = json['nodes'] as List<dynamic>?;
    
    final dynamic data = await super.parseAsync(json);
    
    this._nodesJSON = null; // Clean up memory reference tracks
    return data;
  }

  /// Parses the node objects from the given JSON and textures dictionary.
  /// 
  /// Returns the parsed nodes map tracking.
  Map<String, dynamic> parseNodes(List<dynamic>? json, Map<String, dynamic> textures) {
    if (json != null) {
      final NodeLoader loader = NodeLoader();
      loader.setNodes(this.nodes);
      loader.setTextures(textures);
      return loader.parseNodes(json);
    }
    return <String, dynamic>{};
  }

  /// Parses the node objects from the given material JSON listings and textures dictionary.
  /// 
  /// Returns a map layer filled with completed node materials instances.
  @override
  Map<String, dynamic> parseMaterials(List<dynamic>? json, Map<String, dynamic> textures) {
    final Map<String, dynamic> materials = {};

    if (json != null) {
      final Map<String, dynamic> nodesCache = this.parseNodes(this._nodesJSON, textures);
      
      final NodeMaterialLoader loader = NodeMaterialLoader();
      loader.setTextures(textures);
      loader.setNodes(nodesCache);
      loader.setNodeMaterials(this.nodeMaterials);

      for (int i = 0, l = json.length; i < l; i++) {
        final Map<String, dynamic> data = json[i] as Map<String, dynamic>;
        final String uuid = data['uuid'].toString();
        
        // Enforcing direct map bracket parsing assignments based on directive instructions
        materials[uuid] = loader.parse(data);
      }
    }

    return materials;
  }
}
