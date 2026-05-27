import 'package:three_js_core/three_js_core.dart' as core;
import 'node_materials.dart';

// Global File-Scope Shared Default Values Object
final core.MeshStandardMaterial _defaultValues = core.MeshStandardMaterial();

/// Node material version of [MeshStandardMaterial].
class MeshStandardNodeMaterial extends NodeMaterial {
  
  /// Read-only type testing identifier flag.
  final bool isMeshStandardNodeMaterial = true;

  /// Returns the explicit type tag name for runtime evaluation.
  static String get type => 'MeshStandardNodeMaterial';

  /// The emissive color overwrite node.
  dynamic emissiveNode;

  /// The metalness overwrite node.
  dynamic metalnessNode;

  /// The roughness overwrite node.
  dynamic roughnessNode;

  /// Constructs a new mesh standard node material.
  /// 
  /// [parameters] - Optional Map layer containing operational configuration flags.
  MeshStandardNodeMaterial([Map<String, dynamic>? parameters]) : super() {
    this.lights = true;
    this.emissiveNode = null;
    this.metalnessNode = null;
    this.roughnessNode = null;

    this.setDefaultValues(_defaultValues);
    if (parameters != null) {
      this.setValues(parameters);
    }
  }

  /// Overwritten since this type of material uses [EnvironmentNode]
  /// to implement the PBR (PMREM based) environment mapping.
  @override
  dynamic setupEnvironment(dynamic builder) {
    dynamic envNode = super.setupEnvironment(builder);
    
    if (envNode == null && builder.environmentNode != null) {
      envNode = builder.environmentNode;
    }
    
    return envNode != null ? core.EnvironmentNode(envNode) : null;
  }

  /// Setups the lighting model.
  @override
  dynamic setupLightingModel([dynamic builder]) {
    return core.PhysicalLightingModel();
  }

  /// Setups the specular related node variables.
  void setupSpecular() {
    final dynamic specularColorNode = core.mix(
      core.vec3(core.float(0.04)), 
      core.diffuseColor.rgb, 
      core.metalness
    );
    
    core.specularColor.assign(core.vec3(core.float(0.04)));
    core.specularColorBlended.assign(specularColorNode);
    core.specularF90.assign(core.float(1.0));
  }

  /// Setups the standard specific node variables.
  @override
  void setupVariants([dynamic builder]) {
    // METALNESS
    final dynamic resolvedMetalnessNode = this.metalnessNode != null 
        ? core.float(this.metalnessNode) 
        : core.materialMetalness;
    core.metalness.assign(resolvedMetalnessNode);

    // ROUGHNESS
    dynamic resolvedRoughnessNode = this.roughnessNode != null 
        ? core.float(this.roughnessNode) 
        : core.materialRoughness;
    resolvedRoughnessNode = core.getRoughness({
      'roughness': resolvedRoughnessNode,
    });
    core.roughness.assign(resolvedRoughnessNode);

    // SPECULAR COLOR
    this.setupSpecular();

    // DIFFUSE COLOR
    core.diffuseContribution.assign(
      core.diffuseColor.rgb.mul(resolvedMetalnessNode.oneMinus())
    );
  }

  /// Copies property values from a source instance.
  @override
  MeshStandardNodeMaterial copy(dynamic source) {
    this.emissiveNode = source.emissiveNode;
    this.metalnessNode = source.metalnessNode;
    this.roughnessNode = source.roughnessNode;
    
    super.copy(source);
    return this;
  }
}
