import 'package:three_js_core/three_js_core.dart';
import 'node_materials.dart';

// Global File-Scope Shared Default Values Object
final SpriteMaterial _defaultValues = SpriteMaterial();

/// Node material version of [SpriteMaterial].
class SpriteNodeMaterial extends NodeMaterial {
  
  /// Read-only type testing identifier flag.
  final bool isSpriteNodeMaterial = true;

  /// Private state tracking field for the size attenuation feature.
  bool _useSizeAttenuation = true;

  /// The custom operational vertex position offset node.
  dynamic positionNode;

  /// The rotation calculation overwrite node.
  dynamic rotationNode;

  /// The custom vertex layout scaling factor node.
  dynamic scaleNode;

  /// Returns the explicit type tag name for runtime evaluation.
  static String get type => 'SpriteNodeMaterial';

  /// Constructs a new sprite node material block.
  /// 
  /// [parameters] - Optional configuration parameter Map layout tracking.
  SpriteNodeMaterial([Map<String, dynamic>? parameters]) : super() {
    this.positionNode = null;
    this.rotationNode = null;
    this.scaleNode = null;
    this.transparent = true;

    this.setDefaultValues(_defaultValues);
    if (parameters != null) {
      this.setValues(parameters);
    }
  }

  /// Setups the position node in view space. This method implements
  /// the custom sprite billboard vertex shader calculations.
  @override
  dynamic setupPositionView(dynamic builder) {
    final dynamic object = builder.object;
    final dynamic camera = builder.camera;
    
    final dynamic positionNode = this.positionNode;
    final dynamic rotationNode = this.rotationNode;
    final dynamic scaleNode = this.scaleNode;
    final bool sizeAttenuation = this.sizeAttenuation;

    // Utilize bracket math operator node cascading 
    final dynamic mvPosition = modelViewMatrix.mul(
      vec3(positionNode ?? float(0))
    );

    // Compute dynamic object transform scaling using bracket directives on world matrices
    dynamic scale = vec2(
      modelWorldMatrix[0].xyz.length(), 
      modelWorldMatrix[1].xyz.length()
    );

    if (scaleNode != null) {
      scale = scale.mul(vec2(scaleNode));
    }

    if (camera.isPerspectiveCamera == true && sizeAttenuation == false) {
      scale = scale.mul(mvPosition.z.negate());
    }

    dynamic alignedPosition = positionGeometry.xy;

    if (object.center != null && object.center.isVector2 == true) {
      // Direct asset context references via standard reference blocks
      final dynamic center = reference('center', 'vec2', object);
      alignedPosition = alignedPosition.sub(center.sub(float(0.5)));
    }

    alignedPosition = alignedPosition.mul(scale);

    final dynamic rotation = float(rotationNode ?? materialRotation);
    final dynamic rotatedPosition = rotate(alignedPosition, rotation);

    // Reconstruct the 4D homogenous spatial projection vector coordinate layout
    return vec4(mvPosition.xy.add(rotatedPosition), mvPosition.zw);
  }

  /// Copies property values from a source instance profile template configuration.
  @override
  SpriteNodeMaterial copy(dynamic source) {
    this.positionNode = source.positionNode;
    this.rotationNode = source.rotationNode;
    this.scaleNode = source.scaleNode;
    
    super.copy(source);
    return this;
  }

  /// Whether to use size attenuation or not.
  bool get sizeAttenuation => this._useSizeAttenuation;

  set sizeAttenuation(bool value) {
    if (this._useSizeAttenuation != value) {
      this._useSizeAttenuation = value;
      this.needsUpdate = true;
    }
  }
}
