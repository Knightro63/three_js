import 'dart:typed_data';
import 'dart:math' as math;
import 'dart:ui';
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_gpu/lighting/SceneLightingUniforms.dart';
import 'package:three_js_gpu/lighting/ibl/PrefilterMipSelector.dart';
import 'package:three_js_gpu/renderer/webgpu/UniformBufferManager.dart';
import 'package:three_js_gpu/renderer/webgpu/WebGPUEnvironmentManager.dart';

class MaterialConverter {
  static MaterialUniformData convert(
    Material material,
    Camera camera,
    EnvironmentBinding? environmentBinding,
    SceneLightingUniforms lightingUniforms,
  ){
    final Float32List cameraPosition = Float32List.fromList([
      camera.position.x, 
      camera.position.y, 
      camera.position.z
    ]);

    if (material is MeshBasicMaterial) {
      final Float32List baseColor = Float32List.fromList([
        material.color.red,
        material.color.green,
        material.color.blue,
        material.opacity,
      ]);
      return MaterialUniformData(
        baseColor: baseColor,
        roughness: 1.0,
        metalness: 0.0,
        envIntensity: 0.0, // 0.0 unbinds all image-based specular ambient maps
        prefilterMipCount: environmentBinding?.mipCount ?? 1,
        cameraPosition: cameraPosition,
        ambientColor: Float32List.fromList([1.0, 1.0, 1.0, 1.0]), // Force full flat luminance ambient
        fogColor: lightingUniforms.fogColor,
        fogParams: lightingUniforms.fogParams,
        mainLightDirection: lightingUniforms.mainLightDirection,
        mainLightColor: Float32List.fromList([0.0, 0.0, 0.0, 0.0]), // Ignore direct dynamic directional shadows
      );
    } 
    else if (material is MeshLambertMaterial) {
      // LAMBERT: Diffuse-only matte surfaces (e.g. paper, wood, terrain)
      final Float32List baseColor = Float32List.fromList([
        (material as dynamic).color.red,
        (material as dynamic).color.green,
        (material as dynamic).color.blue,
        (material as dynamic).opacity,
      ]);
      return MaterialUniformData(
        baseColor: baseColor,
        roughness: 1.0, // Complete light scattering avoids shiny specular hotspots
        metalness: 0.0,
        envIntensity: 0.15, // Low ambient bounce fallback matching diffuse lookups
        prefilterMipCount: environmentBinding?.mipCount ?? 1,
        cameraPosition: cameraPosition,
        ambientColor: lightingUniforms.ambientColor,
        fogColor: lightingUniforms.fogColor,
        fogParams: lightingUniforms.fogParams,
        mainLightDirection: lightingUniforms.mainLightDirection,
        mainLightColor: lightingUniforms.mainLightColor,
      );
    } 
    else if (material is MeshPhongMaterial) {
      // PHONG: Highly specular glossy plastic/porcelain surface properties
      final Float32List baseColor = Float32List.fromList([
        (material as dynamic).color.red,
        (material as dynamic).color.green,
        (material as dynamic).color.blue,
        (material as dynamic).opacity,
      ]);
      
      // map shininess coefficient (typically 0-100) down to inverse microfacet roughness scale (0.02 - 0.25)
      final double shininess = (material as dynamic).shininess ?? 30.0;
      final double derivedRoughness = clampDouble(1.0 - (shininess / 120.0), 0.03, 0.3);

      return MaterialUniformData(
        baseColor: baseColor,
        roughness: derivedRoughness, // Sharp, tight reflection mirror bounds
        metalness: 0.0,
        envIntensity: 1.0, // Allow specular maps to shine brightly across the profile
        prefilterMipCount: environmentBinding?.mipCount ?? 1,
        cameraPosition: cameraPosition,
        ambientColor: lightingUniforms.ambientColor,
        fogColor: lightingUniforms.fogColor,
        fogParams: lightingUniforms.fogParams,
        mainLightDirection: lightingUniforms.mainLightDirection,
        mainLightColor: lightingUniforms.mainLightColor,
      );
    } 
    else if (material is MeshToonMaterial) {
      // TOON / CEL: Stylized banding color effects
      final Float32List baseColor = Float32List.fromList([
        (material as dynamic).color.red,
        (material as dynamic).color.green,
        (material as dynamic).color.blue,
        (material as dynamic).opacity,
      ]);
      return MaterialUniformData(
        baseColor: baseColor,
        roughness: 0.9,
        metalness: 0.0,
        envIntensity: 0.0,
        prefilterMipCount: environmentBinding?.mipCount ?? 1,
        cameraPosition: cameraPosition,
        ambientColor: lightingUniforms.ambientColor,
        fogColor: lightingUniforms.fogColor,
        fogParams: lightingUniforms.fogParams,
        mainLightDirection: lightingUniforms.mainLightDirection,
        // Maximize light color values slightly to amplify contrast gaps on cartoon shadows
        mainLightColor: lightingUniforms.mainLightColor, 
      );
    } 
    else if (material is MeshStandardMaterial) {
      final Float32List baseColor = Float32List.fromList([
        material.color.red,
        material.color.green,
        material.color.blue,
        material.opacity,
      ]);
      final double roughness = PrefilterMipSelector.clamp01(material.roughness);
      return MaterialUniformData(
        baseColor: baseColor,
        roughness: roughness,
        metalness: material.metalness,
        envIntensity: material.envMapIntensity ?? 0,
        prefilterMipCount: environmentBinding?.mipCount ?? 1,
        cameraPosition: cameraPosition,
        ambientColor: lightingUniforms.ambientColor,
        fogColor: lightingUniforms.fogColor,
        fogParams: lightingUniforms.fogParams,
        mainLightDirection: lightingUniforms.mainLightDirection,
        mainLightColor: lightingUniforms.mainLightColor,
      );
    } else {
      throw ("Material ${material.runtimeType} has not been converted yet. Please use another Material.");
    }

  }
}