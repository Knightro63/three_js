part of three_shaders;

Map<String, dynamic> uniformsLib = {
  "common": {
    "diffuse": {"value": Color.fromHex32(0xffffff)},
    "opacity": {"value": 1.0},
    "map": <String,dynamic>{'value': null},
    "mapTransform": {"value": Matrix3.identity()},
    "alphaMap": <String,dynamic>{'value': null},
    "alphaMapTransform": {"value": Matrix3.identity()},
    "alphaTest": {"value": 0.0},
    "uvTransform": {"value": Matrix3.identity()},
    "uv2Transform": {"value": Matrix3.identity()},
  },
  "specularmap": {
    "specularMap": <String,dynamic>{'value': null},
    'specularMapTransform': { 'value': Matrix3.identity() }
  },
  "envmap": {
    "envMap": {},
    "flipEnvMapX": {"value": -1},
    "flipEnvMapY": {"value": 1},
    
    'envMapRotation': { 'value': Matrix3.identity() },
    "flipEnvMap": {"value": -1},
    "reflectivity": {"value": 1.0}, // basic, lambert, phong
    "ior": {"value": 1.5}, // physical
    "refractionRatio": {"value": 0.98}, // basic, lambert, phong
  },
  "aomap": {
    "aoMap": <String,dynamic>{'value': null},
    "aoMapIntensity": {"value": 1},
    'aoMapTransform': { 'value': Matrix3.identity() }
  },
  "lightmap": {
    "lightMap": <String,dynamic>{'value': null},
    "lightMapIntensity": {"value": 1},
    'lightMapTransform': { 'value': Matrix3.identity() }
  },
  "emissivemap": {
    "emissiveMap": <String,dynamic>{'value': null},
    'emissiveMapTransform': { 'value': Matrix3.identity() }
  },
  "bumpmap": {
    "bumpMap": <String,dynamic>{'value': null},
    'bumpMapTransform': { 'value': Matrix3.identity() },
    "bumpScale": {"value": 1}
  },
  "normalmap": {
    "normalMap": <String,dynamic>{'value': null},
    'normalMapTransform': { 'value': Matrix3.identity() },
    "normalScale": {"value": Vector2(1, 1)}
  },
  "displacementmap": {
    "displacementMap": <String,dynamic>{'value': null},
    'displacementMapTransform': { 'value': Matrix3.identity() },
    "displacementScale": {"value": 1},
    "displacementBias": {"value": 0}
  },
  "roughnessmap": {
    "roughnessMap": <String,dynamic>{'value': null},
    'roughnessMapTransform': { 'value': Matrix3.identity() }
  },
  "metalnessmap": {
    "metalnessMap": <String,dynamic>{'value': null},
    'metalnessMapTransform': { 'value': Matrix3.identity() }
  },
  "gradientmap": {
    "gradientMap": <String,dynamic>{'value': null}
  },
  "fog": {
    "fogDensity": {"value": 0.00025},
    "fogNear": {"value": 1},
    "fogFar": {"value": 2000},
    "fogColor": {"value": Color(0, 0, 0)}
  },
  "lights": {
    "ambientLightColor": {"value": []},

    "lightProbe": {"value": []},

    "directionalLights": {
      "value": [],
      "properties": {"direction": {}, "color": {}}
    },

    "directionalLightShadows": {
      "value": [],
      "properties": {"shadowBias": {}, "shadowNormalBias": {}, "shadowRadius": {}, "shadowMapSize": {}}
    },

    "directionalShadowMap": {"value": []},
    "directionalShadowMatrix": {"value": []},

    "spotLights": {
      "value": [],
      "properties": {
        "color": {},
        "position": {},
        "direction": {},
        "distance": {},
        "coneCos": {},
        "penumbraCos": {},
        "decay": {}
      }
    },

    "spotLightShadows": {
      "value": [],
      "properties": {"shadowBias": {}, "shadowNormalBias": {}, "shadowRadius": {}, "shadowMapSize": {}}
    },

    'spotLightMap': { 'value': [] },
    "spotShadowMap": {"value": []},
    "spotShadowMatrix": {"value": []},
    'spotLightMatrix': { 'value': [] },

    "pointLights": {
      "value": [],
      "properties": {"color": {}, "position": {}, "decay": {}, "distance": {}}
    },

    "pointLightShadows": {
      "value": [],
      "properties": {
        "shadowBias": {},
        "shadowNormalBias": {},
        "shadowRadius": {},
        "shadowMapSize": {},
        "shadowCameraNear": {},
        "shadowCameraFar": {}
      }
    },

    "pointShadowMap": {"value": []},
    "pointShadowMatrix": {"value": []},

    "hemisphereLights": {
      "value": [],
      "properties": {"direction": {}, "skyColor": {}, "groundColor": {}}
    },

    // TODO (abelnation): RectAreaLight BRDF data needs to be moved from example to main src
    "rectAreaLights": {
      "value": [],
      "properties": {"color": {}, "position": {}, "width": {}, "height": {}}
    },

    "ltc_1": <String,dynamic>{'value': null},
    "ltc_2": <String,dynamic>{'value': null}
  },
  "points": {
    "diffuse": {"value": Color.fromHex32(0xffffff)},
    "opacity": {"value": 1.0},
    "size": {"value": 1.0},
    "scale": {"value": 1.0},
    "map": <String,dynamic>{'value': null},
    "alphaMap": <String,dynamic>{'value': null},
    'alphaMapTransform': { 'value': Matrix3.identity() },
    "alphaTest": {"value": 0.0},
    "uvTransform": {"value": Matrix3.identity()}
  },
  "sprite": {
    "diffuse": {"value": Color.fromHex32(0xffffff)},
    "opacity": {"value": 1.0},
    "center": {"value": Vector2(0.5, 0.5)},
    "rotation": {"value": 0.0},
    "map": <String,dynamic>{'value': null},
    'mapTransform': { 'value': Matrix3.identity() },
    "alphaMap": <String,dynamic>{'value': null},
    'alphaMapTransform': { 'value': Matrix3.identity() },
    "alphaTest": {"value": 0.0},
    "uvTransform": {"value": Matrix3.identity()}
  }
};
