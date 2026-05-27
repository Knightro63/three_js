import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart' as math;

// Global File-Scope Shared Default Variables
final PointsMaterial _defaultValues = PointsMaterial();
final math.Vector2 _size = math.Vector2();

/// Node material version of [PointsMaterial].
class PointsNodeMaterial extends SpriteNodeMaterial {
  
  /// Read-only type testing identifier flag.
  final bool isPointsNodeMaterial = true;

  /// Private state backing for alpha to coverage adjustments.
  bool _useAlphaToCoverage = true;

  /// This node property provides an additional way to set the point size.
  dynamic sizeNode;

  /// Returns the explicit type tag name for runtime evaluation.
  static String get type => 'PointsNodeMaterial';

  /// Constructs a new points node material block.
  /// 
  /// [parameters] - Optional parameter Map layer configurations.
  PointsNodeMaterial([Map<String, dynamic>? parameters]) : super() {
    this.sizeNode = null;
    this.setDefaultValues(_defaultValues);
    if (parameters != null) {
      this.setValues(parameters);
    }
  }

  /// Sets up perspective space coordinates for structural view matrix math.
  @override
  dynamic setupPositionView([dynamic builder]) {
    final dynamic positionNode = this.positionNode;
    
    // Utilize internal node chaining operators directly on TSL builders
    return modelViewMatrix.mul(
      vec3(positionNode ?? positionLocal)
    ).xyz;
  }

  /// Sets up vertex offsets when point components are rendered using Sprites framework layouts.
  dynamic setupVertexSprite(dynamic builder) {
    final dynamic material = builder.material;
    final dynamic camera = builder.camera;
    
    final dynamic rotationNode = this.rotationNode;
    final dynamic scaleNode = this.scaleNode;
    final dynamic sizeNode = this.sizeNode;
    final bool sizeAttenuation = this.sizeAttenuation ?? true;

    dynamic mvp = super.setupVertex(builder);

    // Skip detailed rendering computations if the material is not verified as a NodeMaterial
    if (material.isNodeMaterial != true) {
      return mvp;
    }

    // Determine basic rendering point dimensions metrics
    dynamic pointSize = sizeNode != null ? vec2(sizeNode) : materialPointSize;
    pointSize = pointSize.mul(screenDPR);

    // Compute size attenuation changes across perspective projection matrix parameters
    if (camera.isPerspectiveCamera == true && sizeAttenuation == true) {
      // Scale by half the canvas height in logical units matching core rendering rules
      pointSize = pointSize.mul(_scale.div(positionView.z.negate()));
    }

    // Process uniform scaling node factors if present
    if (scaleNode != null && scaleNode.isNode == true) {
      pointSize = pointSize.mul(vec2(scaleNode));
    }

    // Isolate active primitive viewport coordinates layout variables
    dynamic offset = positionGeometry.xy;

    // Apply rotation configurations directly via vertex transformation matrix nodes
    if (rotationNode != null && rotationNode.isNode == true) {
      final dynamic rotation = float(rotationNode);
      offset = rotate(offset, rotation);
    }

    // Incorporate dimension offsets matrices scaling
    offset = offset.mul(pointSize);
    offset = offset.div(viewportSize.div(float(2.0)));

    // Correct spatial perspective divide configurations
    offset = offset.mul(mvp.w);

    // Concat offset transformations back onto the model-view-projection vector matrix
    mvp = mvp.add(vec4(offset, float(0.0), float(0.0)));
    return mvp;
  }

  /// Master coordinator pipeline routing vertex calculations based on runtime primitive styles.
  @override
  dynamic setupVertex(dynamic builder) {
    if (builder.object.isPoints == true) {
      return super.setupVertex(builder);
    } else {
      return this.setupVertexSprite(builder);
    }
  }

  /// Whether alpha to coverage should be used or not.
  bool get alphaToCoverage => this._useAlphaToCoverage;

  set alphaToCoverage(bool value) {
    if (this._useAlphaToCoverage != value) {
      this._useAlphaToCoverage = value;
      this.needsUpdate = true;
    }
  }
}

// Frame-update dynamic uniform tracking block mimicking JavaScript closure configurations
final dynamic _scale = uniform(1.0).onFrameUpdate((Map<String, dynamic> info) {
  final dynamic renderer = info['renderer'];
  final math.Vector2 size = renderer.getSize(_size);
  
  // Computes logical units bounds on dynamic frame ticks
  return 0.5 * size.y.toDouble();
});
