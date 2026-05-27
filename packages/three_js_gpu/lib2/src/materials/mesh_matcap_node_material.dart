import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart' as math;

import 'node_materials.dart';

// Global File-Scope Shared Default Values Object
final MeshMatcapMaterial _defaultValues = MeshMatcapMaterial();

/// Node material version of [MeshMatcapMaterial].
class MeshMatcapNodeMaterial extends NodeMaterial {
  
  /// Read-only type testing identifier flag.
  final bool isMeshMatcapNodeMaterial = true;

  /// Returns the explicit type tag name for runtime evaluation.
  static String get type => 'MeshMatcapNodeMaterial';

  /// Constructs a new mesh matcap node material.
  /// 
  /// [parameters] - Optional Map layer containing operational configuration flags.
  MeshMatcapNodeMaterial([Map<String, dynamic>? parameters]) : super() {
    this.setDefaultValues(_defaultValues);
    if (parameters != null) {
      this.setValues(parameters);
    }
  }

  /// Setups the matcap specific shader math node variables trees.
  @override
  void setupVariants(dynamic builder) {
    // Access standard pre-defined shader reference variables from the library context
    final dynamic uv = matcapUV;
    dynamic matcapColor;

    // Utilize bracket map directive matching to inspect active material parameter textures
    if (builder.material.matcap != null) {
      matcapColor = materialReference('matcap', 'texture').context({
        'getUV': () => uv,
      });
    } else {
      // Inline procedural shading backup tree fallback if matcap texture is absent
      matcapColor = vec3(mix(float(0.2), float(0.8), uv.y));
    }

    // Accumulate shading vectors using explicit math operator assignments
    diffuseColor.rgb.mulAssign(matcapColor.rgb);
  }
}
