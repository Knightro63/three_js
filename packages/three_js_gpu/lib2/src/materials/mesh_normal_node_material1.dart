import 'package:three_js_core/three_js_core.dart';
import 'node_materials.dart';

// Global File-Scope Shared Default Values Object
final MeshNormalMaterial _defaultValues = MeshNormalMaterial();

/// Node material version of [MeshNormalMaterial].
class MeshNormalNodeMaterial extends NodeMaterial {
  
  /// Read-only type testing identifier flag.
  final bool isMeshNormalNodeMaterial = true;

  /// Returns the explicit type tag name for runtime evaluation.
  static String get type => 'MeshNormalNodeMaterial';

  /// Constructs a new mesh normal node material.
  /// 
  /// [parameters] - Optional Map containing operational configuration flags.
  MeshNormalNodeMaterial([Map<String, dynamic>? parameters]) : super() {
    this.setDefaultValues(_defaultValues);
    if (parameters != null) {
      this.setValues(parameters);
    }
  }

  /// Overwrites the default implementation by computing the diffuse color
  /// based on the normal data vectors.
  @override
  void setupDiffuseColor([dynamic builder]) {
    // Check for runtime user overwrites before falling back to material opacity node tracks
    final dynamic opacityNode = this.opacityNode != null 
        ? float(this.opacityNode) 
        : materialOpacity;

    // By convention, a normal packed to RGB is in sRGB color space. Convert it to working color space.
    diffuseColor.assign(
      colorSpaceToWorking(
        vec4(directionToColor(normalView), opacityNode), 
        SRGBColorSpace
      )
    );
  }
}
