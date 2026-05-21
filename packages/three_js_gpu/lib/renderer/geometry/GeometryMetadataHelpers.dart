import 'package:three_js_core/three_js_core.dart';
import '../material/MaterialDescriptionRegistry.dart';
import 'GeometryDescriptor.dart';

const String _positionAttr = 'position';
const String _normalAttr = 'normal';
const String _colorAttr = 'color';
const String _uvAttr = 'uv';
const String _uv2Attr = 'uv2';
const String _tangentAttr = 'tangent';

extension MaterialDescriptorGeometryExtensions on MaterialDescriptor {
  /// Shared helper for deriving geometry build options from material descriptors.
  /// 
  /// This helper is used by both Vulkan and WebGPU renderers to ensure consistent
  /// attribute inclusion across targets without relying on platform-specific maps.
  GeometryBuildOptions buildGeometryOptions(BufferGeometry geometry) {
    bool requires(GeometryAttribute attribute) => requiredAttributes.contains(attribute);
    bool optional(GeometryAttribute attribute) => optionalAttributes.contains(attribute);

    bool hasAttribute(GeometryAttribute attribute) {
      return switch (attribute) {
        GeometryAttribute.position => geometry.hasAttributeFromString(_positionAttr),
        GeometryAttribute.normal => geometry.hasAttributeFromString(_normalAttr),
        GeometryAttribute.color => geometry.hasAttributeFromString(_colorAttr),
        GeometryAttribute.uv0 => geometry.hasAttributeFromString(_uvAttr),
        GeometryAttribute.uv1 => geometry.hasAttributeFromString(_uv2Attr),
        GeometryAttribute.tangent => geometry.hasAttributeFromString(_tangentAttr),
        GeometryAttribute.morphPosition || GeometryAttribute.morphNormal => geometry.morphAttributes.isNotEmpty,
        GeometryAttribute.instanceMatrix => geometry is InstancedBufferGeometry,
      };
    }

    return GeometryBuildOptions(
      includeNormals: requires(GeometryAttribute.normal) || 
          (optional(GeometryAttribute.normal) && hasAttribute(GeometryAttribute.normal)),
      includeColors: requires(GeometryAttribute.color) || 
          (optional(GeometryAttribute.color) && hasAttribute(GeometryAttribute.color)),
      includeUVs: requires(GeometryAttribute.uv0) || 
          (optional(GeometryAttribute.uv0) && hasAttribute(GeometryAttribute.uv0)),
      includeSecondaryUVs: requires(GeometryAttribute.uv1) || 
          (optional(GeometryAttribute.uv1) && hasAttribute(GeometryAttribute.uv1)),
      includeTangents: requires(GeometryAttribute.tangent) || 
          (optional(GeometryAttribute.tangent) && hasAttribute(GeometryAttribute.tangent)),
      includeMorphTargets: geometry.morphAttributes.isNotEmpty,
      includeInstancing: geometry is InstancedBufferGeometry || requires(GeometryAttribute.instanceMatrix),
    );
  }
}
