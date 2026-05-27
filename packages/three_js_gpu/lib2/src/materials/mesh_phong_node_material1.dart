import 'package:three_js_core/three_js_core.dart';
import 'node_materials.dart';

// Global File-Scope Shared Default Values Object
final MeshPhongMaterial _defaultValues = MeshPhongMaterial();

/// Node material version of [MeshPhongMaterial].
class MeshPhongNodeMaterial extends NodeMaterial {
  
  /// Read-only type testing identifier flag.
  final bool isMeshPhongNodeMaterial = true;

  /// Returns the explicit type tag name for runtime evaluation.
  static String get type => 'MeshPhongNodeMaterial';

  /// The shininess overwrite node.
  dynamic shininessNode;

  /// The specular color overwrite node.
  dynamic specularNode;

  /// Constructs a new mesh phong node material.
  /// 
  /// [parameters] - Optional Map layer containing operational configuration flags.
  MeshPhongNodeMaterial([Map<String, dynamic>? parameters]) : super() {
    this.lights = true;
    this.shininessNode = null;
    this.specularNode = null;

    this.setDefaultValues(_defaultValues);
    if (parameters != null) {
      this.setValues(parameters);
    }
  }

  /// Overwritten since this type of material uses [BasicEnvironmentNode]
  /// to implement the default environment mapping context.
  @override
  dynamic setupEnvironment(dynamic builder) {
    final dynamic envNode = super.setupEnvironment(builder);
    return envNode != null ? BasicEnvironmentNode(envNode) : null;
  }

  /// Setups the phong lighting model calculation pipeline.
  @override
  dynamic setupLightingModel([dynamic builder]) {
    return PhongLightingModel();
  }

  /// Setups the phong specific mathematical shader node variables.
  @override
  void setupVariants([dynamic builder]) {
    // SHININESS
    final dynamic rawShininessNode = this.shininessNode != null 
        ? float(this.shininessNode) 
        : materialShininess;
        
    // Chain the native TSL limit boundary max evaluator to prevent pow( 0.0, 0.0 ) micro faults
    final dynamic resolvedShininessNode = rawShininessNode.max(float(1e-4));
    shininess.assign(resolvedShininessNode);

    // SPECULAR COLOR
    final dynamic resolvedSpecularNode = this.specularNode ?? materialSpecular;
    specularColor.assign(resolvedSpecularNode);
  }

  /// Copies property values from a source instance profile template.
  @override
  MeshPhongNodeMaterial copy(dynamic source) {
    this.shininessNode = source.shininessNode;
    this.specularNode = source.specularNode;
    
    super.copy(source);
    return this;
  }
}
