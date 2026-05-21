import 'dart:typed_data';
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';

class SceneLightingUniforms {
  const SceneLightingUniforms({
    required this.ambientColor,
    required this.fogColor,
    required this.fogParams,
    required this.mainLightDirection,
    required this.mainLightColor,
  });

  final Float32List ambientColor;
  final Float32List fogColor;
  final Float32List fogParams;
  final Float32List mainLightDirection;
  final Float32List mainLightColor;

  static final defaultUniforms = SceneLightingUniforms(
    ambientColor: Float32List.fromList([0.0, 0.0, 0.0, 1.0]),
    fogColor: Float32List.fromList([0.0, 0.0, 0.0, 0.0]),
    fogParams: Float32List.fromList([0.0, 0.0, 0.0, 0.0]),
    mainLightDirection: Float32List.fromList([0.0, -1.0, 0.0, 0.0]),
    mainLightColor: Float32List.fromList([0.0, 0.0, 0.0, 0.0]),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SceneLightingUniforms &&
          runtimeType == other.runtimeType &&
          ambientColor == other.ambientColor &&
          fogColor == other.fogColor &&
          fogParams == other.fogParams &&
          mainLightDirection == other.mainLightDirection &&
          mainLightColor == other.mainLightColor;

  @override
  int get hashCode => Object.hash(
        ambientColor,
        fogColor,
        fogParams,
        mainLightDirection,
        mainLightColor,
      );
}

SceneLightingUniforms collectSceneLightingUniforms(Object3D scene) {
  final lights = _collectLights(scene);
  
  // Filter instances matching AmbientLight
  final ambientLights = lights.whereType<AmbientLight>().toList();
  
  double ambientR = 0.0;
  double ambientG = 0.0;
  double ambientB = 0.0;
  
  for (final light in ambientLights) {
    ambientR += light.color!.red * light.intensity;
    ambientG += light.color!.green * light.intensity;
    ambientB += light.color!.blue * light.intensity;
  }

  // Identify the strongest active directional light source
  final directionalLights = lights.whereType<DirectionalLight>().toList();
  DirectionalLight? strongestDirectional;
  
  if (directionalLights.isNotEmpty) {
    strongestDirectional = directionalLights.first;
    for (final light in directionalLights) {
      if (light.intensity > strongestDirectional!.intensity) {
        strongestDirectional = light;
      }
    }
  }

  final ambientColorArray = Float32List.fromList([ambientR, ambientG, ambientB, 1.0]);

  final fog = (scene as Scene).fog;
  Color? fogColor;
  if (fog is Fog) {
    fogColor = fog.color;
  } else if (fog is FogExp2) {
    fogColor = fog.color;
  }

  final Float32List fogColorArray = fogColor != null
      ? Float32List.fromList([fogColor.red, fogColor.green, fogColor.blue, 1.0])
      : Float32List(4); // Defaults to [0.0, 0.0, 0.0, 0.0]

  final Float32List fogParamsArray;
  if (fog is Fog) {
    fogParamsArray = Float32List.fromList([fog.near, fog.far, 0.0, 1.0]);
  } else if (fog is FogExp2) {
    fogParamsArray = Float32List.fromList([fog.density, 0.0, 0.0, 2.0]);
  } else {
    fogParamsArray = Float32List(4);
  }

  final Float32List mainLightDirectionArray;
  final Float32List mainLightColorArray;

  if (strongestDirectional != null) {
    final dir = strongestDirectional.position.clone().normalize();
    mainLightDirectionArray = Float32List.fromList([dir.x, dir.y, dir.z, 0.0]);

    final color = strongestDirectional.color;
    final intensity = strongestDirectional.intensity;
    mainLightColorArray = Float32List.fromList([
      color!.red * intensity,
      color.green * intensity,
      color.blue * intensity,
      0.0,
    ]);
  } else {
    mainLightDirectionArray = Float32List.fromList([0.0, -1.0, 0.0, 0.0]);
    mainLightColorArray = Float32List(4);
  }

  return SceneLightingUniforms(
    ambientColor: ambientColorArray,
    fogColor: fogColorArray,
    fogParams: fogParamsArray,
    mainLightDirection: mainLightDirectionArray,
    mainLightColor: mainLightColorArray,
  );
}

List<Light> _collectLights(Object3D scene) {
  final registry = scene.userData['lights'];
  if (registry == null) return const [];

  if (registry is Light) {
    return [registry];
  } else if (registry is Iterable) {
    return registry.whereType<Light>().toList();
  } else if (registry is List) {
    return registry.whereType<Light>().toList();
  }
  
  return const [];
}
