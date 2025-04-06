part of three_webgl;

class WebGLMaterials {
  bool _didDispose = false;
  WebGLRenderer renderer;
  WebGLProperties properties;

  WebGLMaterials(this.renderer, this.properties);

  void dispose(){
    if(_didDispose) return;
    _didDispose = true;
    properties.dispose();
  }

	void refreshTransformUniform(Texture? map, Map? uniform ) {
    if(map == null) return;
		if ( map.matrixAutoUpdate == true) {
			map.updateMatrix();
		}
		uniform?['value']?.setFrom( map.matrix );
	}

  void refreshFogUniforms(Map uniforms, FogBase fog) {
    uniforms["fogColor"]["value"].setFrom(fog.color);

    if (fog.isFog) {
      uniforms["fogNear"]["value"] = fog.near;
      uniforms["fogFar"]["value"] = fog.far;
    } 
    else if (fog.isFogExp2) {
      uniforms["fogDensity"]["value"] = fog.density;
    }
  }

  void refreshMaterialUniforms(Map<String, dynamic> uniforms, Material material, double pixelRatio, double height, RenderTarget? transmissionRenderTarget) {
    if (material is MeshBasicMaterial) {
      refreshUniformsCommon(uniforms, material);
    } else if (material is MeshLambertMaterial) {
      refreshUniformsCommon(uniforms, material);
    } else if (material is MeshToonMaterial) {
      refreshUniformsCommon(uniforms, material);
      refreshUniformsToon(uniforms, material);
    } else if (material is MeshPhongMaterial) {
      refreshUniformsCommon(uniforms, material);
      refreshUniformsPhong(uniforms, material);
    } else if (material is MeshStandardMaterial) {
      refreshUniformsCommon(uniforms, material);
      refreshUniformsStandard(uniforms, material);
			if ( material is MeshPhysicalMaterial ) {
				refreshUniformsPhysical( uniforms, material, transmissionRenderTarget );
      }
    } else if (material is MeshPhysicalMaterial) {
      refreshUniformsCommon(uniforms, material);
      refreshUniformsStandard(uniforms, material);
      refreshUniformsPhysical(uniforms, material, transmissionRenderTarget);
    }else if (material is MeshMatcapMaterial) {
      refreshUniformsCommon(uniforms, material);
      refreshUniformsMatcap(uniforms, material);
    } else if (material is MeshDepthMaterial) {
      refreshUniformsCommon(uniforms, material);
    } else if (material is MeshDistanceMaterial) {
      refreshUniformsCommon(uniforms, material);
      refreshUniformsDistance(uniforms, material);
    } else if (material is MeshNormalMaterial) {
      refreshUniformsCommon(uniforms, material);
    } else if (material is LineBasicMaterial) {
      refreshUniformsLine(uniforms, material);
    }else if (material is LineDashedMaterial) {
      refreshUniformsLine(uniforms, material);
      refreshUniformsDash(uniforms, material);
    }else if (material is PointsMaterial) {
      refreshUniformsPoints(uniforms, material, pixelRatio, height);
    } else if (material is SpriteMaterial) {
      refreshUniformsSprites(uniforms, material);
    } else if (material is ShadowMaterial) {
      uniforms["color"]["value"].setFrom(material.color);
      uniforms["opacity"]["value"] = material.opacity;
    } else if (material is ShaderMaterial) {
      material.uniformsNeedUpdate = false; // #15581
    }
  }

  void refreshUniformsCommon(Map<String, dynamic> uniforms, Material material) {
    uniforms["opacity"]["value"] = material.opacity;

    uniforms["diffuse"]["value"].setFrom(material.color);

    if (material.emissive != null) {
      uniforms["emissive"]["value"].setFrom(material.emissive)?.scale(material.emissiveIntensity);
    }

    if (material.map != null) {
      uniforms["map"]["value"] = material.map;
      refreshTransformUniform( material.map, uniforms['mapTransform'] );
    }

    if (material.alphaMap != null) {
      uniforms["alphaMap"]["value"] = material.alphaMap;
      refreshTransformUniform( material.alphaMap!, uniforms['alphaMapTransform'] );
    }

    if (material.bumpMap != null) {
      uniforms["bumpMap"]["value"] = material.bumpMap;
      refreshTransformUniform( material.bumpMap!, uniforms['bumpMapTransform'] );
      uniforms["bumpScale"]["value"] = material.bumpScale;
      if (material.side == BackSide) uniforms["bumpScale"]["value"] *= -1;
    }

    if (material.displacementMap != null) {
      uniforms["displacementMap"]["value"] = material.displacementMap;
      refreshTransformUniform( material.displacementMap!, uniforms['displacementMapTransform'] );
      uniforms["displacementScale"]["value"] = material.displacementScale;
      uniforms["displacementBias"]["value"] = material.displacementBias;
    }

    if (material.emissiveMap != null) {
      uniforms["emissiveMap"]["value"] = material.emissiveMap;
      refreshTransformUniform( material.emissiveMap!, uniforms['emissiveMapTransform'] );
    }

    if (material.normalMap != null) {
      uniforms["normalMap"]["value"] = material.normalMap;
      refreshTransformUniform( material.normalMap!, uniforms['normalMapTransform'] );
      uniforms["normalScale"]["value"].setFrom(material.normalScale);
      if (material.side == BackSide) uniforms["normalScale"]["value"].negate();
    }

    if (material.specularMap != null) {
      uniforms["specularMap"]["value"] = material.specularMap;
      refreshTransformUniform( material.specularMap!, uniforms['specularMapTransform'] );
    }

    if (material.alphaTest > 0) {
      uniforms["alphaTest"]["value"] = material.alphaTest;
    }

		final materialProperties = properties.get( material );

		final envMap = materialProperties['envMap'];
		final envMapRotation = materialProperties['envMapRotation'] ?? Euler();

    if (envMap != null) {
      uniforms["envMap"]["value"] = envMap;
			_e1.copy( envMapRotation );

			// accommodate left-handed frame
			_e1.x *= - 1; _e1.y *= - 1; _e1.z *= - 1;

			if ( envMap is CubeTexture && envMap is! WebGL3DRenderTarget) {
				// environment maps which are not cube render targets or PMREMs follow a different convention
				_e1.y *= - 1;
				_e1.z *= - 1;
			}

      uniforms['envMapRotation']?['value'].setFromMatrix4( _m1.makeRotationFromEuler( _e1 ) );

      uniforms["flipEnvMap"]?["value"] = (envMap is CubeTexture && envMap is! WebGL3DRenderTarget) ? -1 : 1;
      uniforms["reflectivity"]["value"] = material.reflectivity;
      uniforms["ior"]["value"] = material.ior;
      uniforms["refractionRatio"]["value"] = material.refractionRatio;
    }

    if (material.lightMap != null) {
      uniforms["lightMap"]["value"] = material.lightMap;
      uniforms["lightMapIntensity"]["value"] = material.lightMapIntensity!;
      refreshTransformUniform( material.lightMap!, uniforms['lightMapTransform'] );
    }

    if (material.aoMap != null) {
      uniforms["aoMap"]["value"] = material.aoMap;
      uniforms["aoMapIntensity"]["value"] = material.aoMapIntensity;
      refreshTransformUniform( material.aoMap!, uniforms['aoMapTransform'] );
    }
  }

  void refreshUniformsLine(Map<String, dynamic> uniforms, Material material) {
    uniforms["diffuse"]["value"].setFrom(material.color);
    uniforms["opacity"]["value"] = material.opacity;

		if (material.map != null) {
			uniforms['map']['value'] = material.map;
			refreshTransformUniform( material.map, uniforms['mapTransform'] );
		}
  }

  void refreshUniformsDash(Map<String, dynamic> uniforms, Material material) {
    uniforms["dashSize"]["value"] = material.dashSize;
    uniforms["totalSize"]["value"] = (material.dashSize ?? 0) + (material.gapSize ?? 0);
    uniforms["scale"]["value"] = material.scale;
  }

  void refreshUniformsPoints(Map<String, dynamic> uniforms, Material material, double pixelRatio, double height) {
    uniforms["diffuse"]["value"].setFrom(material.color);
    uniforms["opacity"]["value"] = material.opacity;
    uniforms["size"]["value"] = material.size! * pixelRatio;
    uniforms["scale"]["value"] = height * 0.5;

    if (material.map != null) {
      uniforms["map"]["value"] = material.map;
      refreshTransformUniform( material.map, uniforms['uvTransform'] );
    }

    if (material.alphaMap != null) {
      uniforms["alphaMap"]["value"] = material.alphaMap;
      refreshTransformUniform( material.alphaMap!, uniforms['alphaMapTransform'] );  
    }

    if (material.alphaTest > 0) {
      uniforms["alphaTest"]["value"] = material.alphaTest;
    }
  }

  void refreshUniformsSprites(Map<String, dynamic> uniforms, Material material) {
    uniforms["diffuse"]["value"].setFrom(material.color);
    uniforms["opacity"]["value"] = material.opacity;
    uniforms["rotation"]["value"] = material.rotation;

    if (material.map != null) {
      uniforms["map"]["value"] = material.map;
      refreshTransformUniform( material.map, uniforms['mapTransform'] );
    }

    if (material.alphaMap != null) {
      uniforms["alphaMap"]["value"] = material.alphaMap;
      refreshTransformUniform( material.alphaMap!, uniforms['alphaMapTransform'] );
    }

    if (material.alphaTest > 0) {
      uniforms["alphaTest"]["value"] = material.alphaTest;
    }
  }

  void refreshUniformsPhong(Map<String, dynamic> uniforms, Material material) {
    uniforms["specular"]["value"].setFrom(material.specular);
    uniforms["shininess"]["value"] = math.max<num>(material.shininess!, 1e-4); // to prevent pow( 0.0, 0.0 )
  }

  void refreshUniformsToon(Map<String, dynamic> uniforms, Material material) {
    if (material.gradientMap != null) {
      uniforms["gradientMap"]["value"] = material.gradientMap;
    }
  }

  void refreshUniformsStandard(Map<String, dynamic> uniforms, Material material) {
    uniforms["metalness"]["value"] = material.metalness;
    if (material.roughnessMap != null) {
      uniforms["roughnessMap"]["value"] = material.roughnessMap;
      refreshTransformUniform( material.metalnessMap!, uniforms['metalnessMapTransform'] );
    }

    uniforms["roughness"]["value"] = material.roughness;
    if (material.metalnessMap != null) {
      uniforms["metalnessMap"]["value"] = material.metalnessMap;
      refreshTransformUniform( material.roughnessMap, uniforms['roughnessMapTransform'] );
    }

    if (material.envMap != null) {
      //uniforms.envMap.value = material.envMap; // part of uniforms common
      uniforms["envMapIntensity"]["value"] = material.envMapIntensity;
    }
  }

  void refreshUniformsPhysical(Map<String, dynamic> uniforms,Material material, RenderTarget? transmissionRenderTarget) {
    uniforms["ior"]["value"] = material.ior; // also part of uniforms common

    if (material.sheen > 0) {
      uniforms["sheenColor"]["value"].setFrom(material.sheenColor).multiplyScalar( material.sheen );

      uniforms["sheenRoughness"]["value"] = material.sheenRoughness;

      if (material.sheenColorMap != null) {
        uniforms["sheenColorMap"]["value"] = material.sheenColorMap;
        refreshTransformUniform( material.sheenColorMap!, uniforms['sheenColorMapTransform'] );
      }

      if (material.sheenRoughnessMap != null) {
        uniforms["sheenRoughnessMap"]["value"] = material.sheenRoughnessMap;
        refreshTransformUniform( material.sheenRoughnessMap!, uniforms['sheenRoughnessMapTransform'] );
      }
    }

    if (material.clearcoat > 0) {
      uniforms["clearcoat"]["value"] = material.clearcoat;
      uniforms["clearcoatRoughness"]["value"] = material.clearcoatRoughness;

      if (material.clearcoatMap != null) {
        uniforms["clearcoatMap"]["value"] = material.clearcoatMap;
        refreshTransformUniform( material.clearcoatMap!, uniforms['clearcoatMapTransform'] );
      }

      if (material.clearcoatRoughnessMap != null) {
        uniforms["clearcoatRoughnessMap"]["value"] = material.clearcoatRoughnessMap;
        refreshTransformUniform( material.clearcoatRoughnessMap!, uniforms['clearcoatRoughnessMapTransform'] );
      }

      if (material.clearcoatNormalMap != null) {
        uniforms["clearcoatNormalMap"]["value"] = material.clearcoatNormalMap;
        refreshTransformUniform( material.clearcoatNormalMap!, uniforms['clearcoatNormalMapTransform'] );
        uniforms["clearcoatNormalScale"]["value"].setFrom(material.clearcoatNormalScale);
        if (material.side == BackSide) {
          uniforms["clearcoatNormalScale"]["value"].negate();
        }
      }
    }

		if (material is MeshPhysicalMaterial &&  material.dispersion > 0 ) {
			uniforms['dispersion']['value'] = material.dispersion;
		}

		if (material is MeshPhysicalMaterial && material.iridescence > 0 ) {
			uniforms['iridescence']['value'] = material.iridescence;
			uniforms['iridescenceIOR']['value'] = material.iridescenceIOR;
			uniforms['iridescenceThicknessMinimum']['value'] = material.iridescenceThicknessRange[ 0 ];
			uniforms['iridescenceThicknessMaximum']['value'] = material.iridescenceThicknessRange[ 1 ];

			if ( material.iridescenceMap != null) {
				uniforms['iridescenceMap']['value'] = material.iridescenceMap;
				refreshTransformUniform( material.iridescenceMap!, uniforms['iridescenceMapTransform'] );
			}

			if ( material.iridescenceThicknessMap != null) {
				uniforms['iridescenceThicknessMap']['value'] = material.iridescenceThicknessMap;
				refreshTransformUniform( material.iridescenceThicknessMap!, uniforms['iridescenceThicknessMapTransform'] );
			}
		}

    if (material.transmission > 0) {
      uniforms["transmission"]["value"] = material.transmission;
      uniforms["transmissionSamplerMap"]["value"] = transmissionRenderTarget?.texture;
      uniforms["transmissionSamplerSize"]["value"].setValues(transmissionRenderTarget?.width.toDouble() ?? 0.0, transmissionRenderTarget?.height.toDouble() ?? 0.0);

      if (material.transmissionMap != null) {
        uniforms["transmissionMap"]["value"] = material.transmissionMap;
        refreshTransformUniform( material.transmissionMap, uniforms['transmissionMapTransform'] );
      }

      uniforms["thickness"]["value"] = material.thickness;

      if (material.thicknessMap != null) {
        uniforms["thicknessMap"]["value"] = material.thicknessMap;
        refreshTransformUniform( material.thicknessMap!, uniforms['thicknessMapTransform'] );
      }

      uniforms["attenuationDistance"]["value"] = material.attenuationDistance;
      uniforms["attenuationColor"]["value"].setFrom(material.attenuationColor);
    }

		if (material is MeshPhysicalMaterial && material.anisotropy > 0 ) {
			uniforms['anisotropyVector']['value'].setValues( material.anisotropy * math.cos( material.anisotropyRotation ), material.anisotropy * math.sin( material.anisotropyRotation ) );
			if ( material.anisotropyMap != null) {
				uniforms['anisotropyMap']['value'] = material.anisotropyMap;
				refreshTransformUniform( material.anisotropyMap!, uniforms['anisotropyMapTransform'] );
			}
		}

    uniforms["specularIntensity"]["value"] = material.specularIntensity;
    uniforms["attenuationColor"]["value"].setFrom(material.attenuationColor);
    if (material.specularColorMap != null) {
      uniforms["specularColorMap"]["value"] = material.specularColorMap;
      refreshTransformUniform( material.specularColorMap!, uniforms['specularColorMapTransform'] );
    }
    if (material.specularIntensityMap != null) {
      uniforms["specularIntensityMap"]["value"] = material.specularIntensityMap;
      refreshTransformUniform( material.specularIntensityMap!, uniforms['specularIntensityMapTransform'] );
    }
  }

  void refreshUniformsMatcap(Map<String, dynamic> uniforms, Material material) {
    if (material.matcap != null) {
      uniforms["matcap"]["value"] = material.matcap;
    }
  }

  void refreshUniformsDistance(Map<String, dynamic> uniforms, MeshDistanceMaterial material) {
    final light = properties.get( material )['light'];

		uniforms['referencePosition']['value'].setFromMatrixPosition( light.matrixWorld );
		uniforms['nearDistance']['value'] = light.shadow.camera.near;
		uniforms['farDistance']['value'] = light.shadow.camera.far;

    // uniforms["referencePosition"]["value"].setFrom(material.referencePosition);
    // uniforms["nearDistance"]["value"] = material.nearDistance;
    // uniforms["farDistance"]["value"] = material.farDistance;
  }
}
