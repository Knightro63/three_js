import 'package:three_js_core/three_js_core.dart';

/// Represents the lighting model for [MeshSSSNodeMaterial].
class SSSLightingModel extends PhysicalLightingModel {
  bool useSSS;

  /// Constructs a new physical lighting model with subsurface scattering extensions.
  SSSLightingModel([
    bool clearcoat = false,
    bool sheen = false,
    bool iridescence = false,
    bool anisotropy = false,
    bool transmission = false,
    bool dispersion = false,
    this.useSSS = false,
  ]) : super(clearcoat, sheen, iridescence, anisotropy, transmission, dispersion);

  /// Extends the default implementation with a SSS term.
  /// 
  /// Reference: Approximating Translucency for a Fast, Cheap and Convincing Subsurface Scattering Look
  @override
  void direct(Map<String, dynamic> input, dynamic builder) {
    if (this.useSSS == true) {
      final dynamic material = builder.material;
      
      // Extract structural shading variables dynamically using map bracket directives
      final dynamic thicknessColorNode = material.thicknessColorNode;
      final dynamic thicknessDistortionNode = material.thicknessDistortionNode;
      final dynamic thicknessAmbientNode = material.thicknessAmbientNode;
      final dynamic thicknessAttenuationNode = material.thicknessAttenuationNode;
      final dynamic thicknessPowerNode = material.thicknessPowerNode;
      final dynamic thicknessScaleNode = material.thicknessScaleNode;

      final dynamic lightDirection = input['lightDirection'];
      final dynamic lightColor = input['lightColor'];
      final dynamic reflectedLight = input['reflectedLight'];

      // Execute subsurface lighting mathematical calculations via TSL expressions
      final dynamic scatteringHalf = lightDirection.add(
        normalView.mul(thicknessDistortionNode)
      ).normalize();
      
      final dynamic scatteringDot = float(
        positionViewDirection.dot(scatteringHalf.negate())
            .saturate()
            .pow(thicknessPowerNode)
            .mul(thicknessScaleNode)
      );
      
      final dynamic scatteringIllu = vec3(
        scatteringDot.add(thicknessAmbientNode).mul(thicknessColorNode)
      );

      // Accumulate direct diffuse energy onto hardware render targets variables
      reflectedLight.directDiffuse.addAssign(
        scatteringIllu.mul(thicknessAttenuationNode.mul(lightColor))
      );
    }

    // Hand back loop operations to the base lighting compiler execution list
    super.direct(input, builder);
  }
}

/// This node material is an experimental extension of [MeshPhysicalNodeMaterial]
/// that implements a Subsurface scattering (SSS) term.
class MeshSSSNodeMaterial extends MeshPhysicalNodeMaterial {
  
  /// Represents the thickness color.
  dynamic thicknessColorNode;

  /// Represents the distortion factor.
  dynamic thicknessDistortionNode;

  /// Represents the thickness ambient factor.
  dynamic thicknessAmbientNode;

  /// Represents the thickness attenuation.
  dynamic thicknessAttenuationNode;

  /// Represents the thickness power.
  dynamic thicknessPowerNode;

  /// Represents the thickness scale.
  dynamic thicknessScaleNode;

  /// Returns the explicit type tag name for runtime evaluation.
  static String get type => 'MeshSSSNodeMaterial';

  /// Constructs a new mesh SSS node material.
  /// 
  /// [parameters] - Optional configuration parameter map layout layers.
  MeshSSSNodeMaterial([Map<String, dynamic>? parameters]) : super(parameters) {
    this.thicknessColorNode = null;
    this.thicknessDistortionNode = float(0.1);
    this.thicknessAmbientNode = float(0.0);
    this.thicknessAttenuationNode = float(0.1);
    this.thicknessPowerNode = float(2.0);
    this.thicknessScaleNode = float(10.0);
  }

  /// Whether the lighting model should use SSS or not.
  bool get useSSS => this.thicknessColorNode != null;

  /// Setups the translucent physical lighting model.
  @override
  dynamic setupLightingModel([dynamic builder]) {
    return SSSLightingModel(
      this.useClearcoat,
      this.useSheen,
      this.useIridescence,
      this.useAnisotropy,
      this.useTransmission,
      this.useDispersion,
      this.useSSS,
    );
  }

  /// Copies property values from a source instance profile template structure.
  @override
  MeshSSSNodeMaterial copy(dynamic source) {
    this.thicknessColorNode = source.thicknessColorNode;
    this.thicknessDistortionNode = source.thicknessDistortionNode;
    this.thicknessAmbientNode = source.thicknessAmbientNode;
    this.thicknessAttenuationNode = source.thicknessAttenuationNode;
    this.thicknessPowerNode = source.thicknessPowerNode;
    this.thicknessScaleNode = source.thicknessScaleNode;
    
    super.copy(source);
    return this;
  }
}
