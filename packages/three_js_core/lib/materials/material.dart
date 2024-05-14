import 'dart:convert';
import 'package:three_js_core/others/index.dart';

import '../core/event_dispatcher.dart';
import '../core/object_3d.dart';
import 'package:three_js_math/three_js_math.dart';
import '../textures/index.dart';

int materialId = 0;

enum MaterialProperty{
  attributes,
  alphaTest,
  bumpScale,
  alphaMap,
  aoMap,
  blendDst,
  blendDstAlpha,
  blendSrcAlpha,
  blendEquation,
  blending,
  blendSrc,
  clearcoat,
  clearcoatRoughness,
  clipIntersection,
  clipping,
  clippingPlanes,
  clipShadows,
  color,
  colorWrite,
  defines,
  depthPacking,
  depthTest,
  depthWrite,
  dithering,
  emissive,
  emissiveMap,
  flatShading,
  fog,
  fragmentShader,
  instanced,
  lights,
  linecap,
  linejoin,
  linewidth,
  matcap,
  map,
  metalness,
  metalnessMap,
  name,
  normalMap,
  normalScale,
  opacity,
  polygonOffset,
  polygonOffsetFactor,
  polygonOffsetUnits,
  premultipliedAlpha,
  reflectivity,
  roughness,
  refractionRatio,
  roughnessMap,
  shading,
  shininess,
  side,
  size,
  dashSize,
  gapSize,
  scale,
  sizeAttenuation,
  stencilZFail,
  stencilZPass,
  stencilFail,
  stencilFunc,
  stencilRef,
  stencilWrite,
  toneMapped,
  transparent,
  uniforms,
  vertexShader,
  visible,
  vertexColors,
  wireframe,
  wireframeLinewidth,
  shadowSide,
  specular;

  static MaterialProperty? getFromName(String name){
    for(int i = 0; i < values.length;i++){
      if(values[i].name == name){
        return values[i];
      } 
    }

    return null;
  }
}

/// Abstract base class for materials.
///
/// Materials describe the appearance of [page:Object objects]. They are
/// defined in a (mostly) renderer-independent way, so you don't have to
/// rewrite materials if you decide to use a different renderer.
///
/// The following properties and methods are inherited by all other material
/// types (although they may have different defaults).
class Material with EventDispatcher {
  dynamic metalnessNode;
  dynamic roughnessNode;
  dynamic normalNode;

  int id = materialId++;
  String uuid = MathUtils.generateUUID();
  String name = "";
  String type = "Material";
  bool fog = false;
  int blending = NormalBlending;
  int side = FrontSide;
  bool vertexColors = false;

  bool sizeAttenuation = false;

  Vector2? normalScale;
  Vector2? clearcoatNormalScale;

  double opacity = 1;
  bool transparent = false;
  int blendSrc = SrcAlphaFactor;
  int blendDst = OneMinusSrcAlphaFactor;
  int blendEquation = AddEquation;
  int? blendSrcAlpha;
  int? blendDstAlpha;
  int? blendEquationAlpha;
  int depthFunc = LessEqualDepth;
  bool depthTest = true;
  bool depthWrite = true;
  int stencilWriteMask = 0xff;
  int stencilFunc = AlwaysStencilFunc;
  int stencilRef = 0;
  int stencilFuncMask = 0xff;
  int stencilFail = KeepStencilOp;
  int stencilZFail = KeepStencilOp;
  int stencilZPass = KeepStencilOp;

  bool stencilWrite = false;
  List<Plane>? clippingPlanes;
  bool clipIntersection = false;
  bool clipShadows = false;

  int? shadowSide;
  bool colorWrite = true;

  double? shininess;

  String? precision;
  bool polygonOffset = false;
  double polygonOffsetFactor = 0;
  double polygonOffsetUnits = 0;

  bool dithering = false;
  double _alphaTest = 0;
  double get alphaTest => _alphaTest;
  set alphaTest(double value) {
    if ((_alphaTest > 0) != (value > 0)) {
      version++;
    }

    _alphaTest = value;
  }

  double _clearcoat = 0;
  double get clearcoat => _clearcoat;
  set clearcoat(double value) {
    if ((_clearcoat > 0) != (value > 0)) {
      version++;
    }
    _clearcoat = value;
  }

  bool alphaToCoverage = false;
  double rotation = 0;

  bool premultipliedAlpha = false;
  bool visible = true;

  bool toneMapped = true;

  Map<String, dynamic> userData = {};

  int version = 0;

  bool isMaterial = true;
  bool flatShading = false;
  Color color = Color(1, 1, 1);

  Color? specular;
  double? specularIntensity;
  Color? specularColor;
  double? clearcoatRoughness;
  double? bumpScale;
  double? envMapIntensity;

  double metalness = 0.0;
  double roughness = 1.0;

  Texture? matcap;
  Texture? clearcoatMap;
  Texture? clearcoatRoughnessMap;
  Texture? clearcoatNormalMap;
  Texture? displacementMap;
  Texture? roughnessMap;
  Texture? metalnessMap;
  Texture? specularMap;
  Texture? specularIntensityMap;
  Texture? specularColorMap;
  Texture? sheenColorMap;

  Texture? gradientMap;
  double sheen = 0.0;
  Color? sheenColor;
  Texture? sheenTintMap;

  double sheenRoughness = 1.0;
  Texture? sheenRoughnessMap;

  double _transmission = 0.0;
  double get transmission => _transmission;
  set transmission(double value) {
    if ((_transmission > 0) != (value > 0)) {
      version++;
    }

    _transmission = value;
  }

  Texture? transmissionMap;

  double? thickness;
  Texture? thicknessMap;

  Color? attenuationColor;
  double? attenuationDistance;

  bool vertexTangents = false;

  Texture? map;
  Texture? lightMap;
  double? lightMapIntensity;
  Texture? aoMap;
  double? aoMapIntensity;

  Texture? alphaMap;
  double? displacementScale;
  double? displacementBias;

  int? normalMapType;

  Texture? normalMap;
  Texture? bumpMap;
  Texture? get envMap =>(uniforms["envMap"] == null ? null : uniforms["envMap"]["value"]);
  set envMap(value) {
    uniforms["envMap"] = {"value": value};
  }

  int? combine;

  double? refractionRatio;
  bool wireframe = false;
  double? wireframeLinewidth;
  String? wireframeLinejoin;
  String? wireframeLinecap;

  double? linewidth;
  String? linecap;
  String? linejoin;

  double? dashSize;
  double? gapSize;
  double? scale;

  Color? emissive;
  double emissiveIntensity = 1.0;
  Texture? emissiveMap;

  bool instanced = false;

  Map<String, dynamic>? defines;
  Map<String, dynamic> uniforms = {};

  String? vertexShader;
  String? fragmentShader;

  String? glslVersion;
  int? depthPacking;
  String? index0AttributeName;
  Map<String, dynamic>? extensions;
  Map<String, dynamic>? defaultAttributeValues;

  bool? lights;
  bool? clipping;

  double? ior;

  double? size;

  double? reflectivity;
  // double? get reflectivity => _reflectivity;
  // set reflectivity(double? value) {
  //   _reflectivity = value;
  // }

  bool? uniformsNeedUpdate;

  /// An optional callback that is executed immediately before the shader
  /// program is compiled. This function is called with the shader source code
  /// as a parameter. Useful for the modification of built-in materials.
  /// 
  /// Unlike properties, the callback is not supported by [clone], 
  /// [copy] and [toJson].
  Function? onBeforeCompile;

  /// In case onBeforeCompile is used, this callback can be used to identify
  /// values of settings used in onBeforeCompile, so three.js can reuse a cached
  /// shader or recompile the shader for this material as needed.
  /// 
  /// ```
  /// if(black){
  ///   shader.fragmentShader = shader.fragmentShader.replace('gl_FragColor = vec4(1)', 'gl_FragColor = vec4(0)');
  /// }
  /// ```
  /// ```
  /// material.customProgramCacheKey(){ 
  ///   return black ? '1' : '0';
  /// }
  /// ```
  /// 
  /// Unlike properties, the callback is not supported by [clone], 
  /// [copy] and [toJson].
  late Function customProgramCacheKey;

  Map<String, dynamic> extra = {};

  String? shaderid;

  String get shaderID => shaderid ?? type;
  set shaderID(value) {
    shaderid = value;
  }

  // ( /* renderer, scene, camera, geometry, object, group */ ) {}
  Function? onBeforeRender;

  Material() {
    customProgramCacheKey = () {
      return onBeforeCompile?.toString();
    };
  }

  Material.fromJson(Map<String, dynamic> json, Map<String, dynamic> rootJson) {
    uuid = json["uuid"];
    type = json["type"];
    color.setFromHex32(json["color"]);
  }

  void onBuild(shaderobject, renderer) {}

  // onBeforeCompile(shaderobject, renderer) {}
  void setValuesFromString(Map<String, dynamic>? values) {
    if (values == null) return;

    for (final key in values.keys) {
      final newValue = values[key];

      if (newValue == null) {
        console.warning('Material setValues: $key parameter is null.');
        continue;
      }

      setValueFromString(key, newValue);
    }
  }

  /// [values] - a container with parameters.
  /// 
  /// Sets the properties based on the `values`.
  void setValues(Map<MaterialProperty, dynamic>? values) {
    if (values == null) return;

    for (final key in values.keys) {
      final newValue = values[key];

      if (newValue == null) {
        console.warning('Material setValues: $key parameter is null.');
        continue;
      }

      setValue(key, newValue);
    }
  }

  /// [type] - the parameter to change.
  /// 
  /// Sets the properties based on the `values`.
  void setValue(MaterialProperty type, dynamic newValue) {
    setValueFromString(type.name, newValue);
  }

  /// [key] - String values of the parameter to change.
  /// 
  /// Sets the properties based on the `values`.
  void setValueFromString(String key, dynamic newValue) {
    if (key == "alphaTest") {
      alphaTest = newValue.toDouble();
    } else if (key == "bumpScale") {
      bumpScale = newValue.toDouble();
    } else if (key == "alphaMap") {
      alphaMap = newValue;
    } else if (key == "aoMap") {
      aoMap = newValue;
    } else if (key == "blendDst") {
      blendDst = newValue;
    } else if (key == "blendDstAlpha") {
      blendDstAlpha = newValue;
    } else if (key == "blendSrcAlpha") {
      blendSrcAlpha = newValue;
    } else if (key == "blendEquation") {
      blendEquation = newValue;
    } else if (key == "blending") {
      blending = newValue;
    } else if (key == "blendSrc") {
      blendSrc = newValue;
    } else if (key == "blendSrcAlpha") {
      blendSrcAlpha = newValue;
    } else if (key == "clearcoat") {
      clearcoat = newValue.toDouble();
    } else if (key == "clearcoatRoughness") {
      clearcoatRoughness = newValue.toDouble();
    } else if (key == "clipIntersection") {
      clipIntersection = newValue;
    } else if (key == "clipping") {
      clipping = newValue;
    } else if (key == "clippingPlanes") {
      clippingPlanes = newValue;
    } else if (key == "clipShadows") {
      clipShadows = newValue;
    } else if (key == "color") {
      if (newValue is Color) {
        color = newValue;
      } else {
        color = Color.fromHex32(newValue);
      }
    } else if (key == "colorWrite") {
      colorWrite = newValue;
    } else if (key == "defines") {
      defines = newValue;
    } else if (key == "depthPacking") {
      depthPacking = newValue;
    } else if (key == "depthTest") {
      depthTest = newValue;
    } else if (key == "depthWrite") {
      depthWrite = newValue;
    } else if (key == "dithering") {
      dithering = newValue;
    } else if (key == "emissive") {
      if (newValue.runtimeType == Color) {
        emissive = newValue;
      } else {
        emissive = Color.fromHex32(newValue);
      }
    } else if (key == "emissiveMap") {
      emissiveMap = newValue;
    } else if (key == "flatShading") {
      flatShading = newValue;
    } else if (key == "fog") {
      fog = newValue;
    } else if (key == "fragmentShader") {
      fragmentShader = newValue;
    }else if (key == "specularMap") {
      specularMap = newValue;
    } else if (key == "instanced") {
      instanced = newValue;
    } else if (key == "lights") {
      lights = newValue;
    } else if (key == "linecap") {
      linecap = newValue;
    } else if (key == "linejoin") {
      linejoin = newValue;
    } else if (key == "linewidth") {
      linewidth = newValue.toDouble();
    } else if (key == "matcap") {
      matcap = newValue;
    } else if (key == "map") {
      map = newValue;
    } else if (key == "metalness") {
      metalness = newValue.toDouble();
    } else if (key == "metalnessMap") {
      metalnessMap = newValue;
    } else if (key == "name") {
      name = newValue;
    } else if (key == "normalMap") {
      normalMap = newValue;
    } else if (key == "normalScale") {
      normalScale = newValue;
    } else if (key == "opacity") {
      opacity = newValue.toDouble();
    } else if (key == "polygonOffset") {
      polygonOffset = newValue;
    } else if (key == "polygonOffsetFactor") {
      polygonOffsetFactor = newValue.toDouble();
    } else if (key == "polygonOffsetUnits") {
      polygonOffsetUnits = newValue.toDouble();
    } else if (key == "premultipliedAlpha") {
      premultipliedAlpha = newValue;
    } else if (key == "reflectivity") {
      reflectivity = newValue.toDouble();
    } else if (key == "roughness") {
      roughness = newValue.toDouble();
    }else if (key == "refractionRatio") {
      refractionRatio = newValue.toDouble();
    }else if (key == "roughnessMap") {
      roughnessMap = newValue;
    } else if (key == "shading") {
      //   // for backward compatability if shading is set in the constructor
      throw ('THREE.$type: .shading has been removed. Use the boolean .flatShading instead.');
      //   this.flatShading = ( newValue == FlatShading ) ? true : false;

    } else if (key == "shininess") {
      shininess = newValue.toDouble();
    } else if (key == "side") {
      side = newValue;
    } else if (key == "size") {
      size = newValue.toDouble();
    } else if (key == "dashSize") {
      dashSize = newValue.toDouble();
    } else if (key == "gapSize") {
      gapSize = newValue.toDouble();
    } else if (key == "scale") {
      scale = newValue.toDouble();
    } else if (key == "sizeAttenuation") {
      sizeAttenuation = newValue;
    } else if (key == "stencilZFail") {
      stencilZFail = newValue;
    } else if (key == "stencilZPass") {
      stencilZPass = newValue;
    } else if (key == "stencilFail") {
      stencilFail = newValue;
    } else if (key == "stencilFunc") {
      stencilFunc = newValue;
    } else if (key == "stencilRef") {
      stencilRef = newValue;
    } else if (key == "stencilWrite") {
      stencilWrite = newValue;
    } else if (key == "toneMapped") {
      toneMapped = newValue;
    } else if (key == "transparent") {
      transparent = newValue;
    } else if (key == "uniforms") {
      uniforms = newValue;
    } else if (key == "vertexShader") {
      vertexShader = newValue;
    } else if (key == "visible") {
      visible = newValue;
    } else if (key == "vertexColors") {
      vertexColors = newValue;
    } else if (key == "wireframe") {
      wireframe = newValue;
    } else if (key == "wireframeLinewidth") {
      wireframeLinewidth = newValue.toDouble();
    } else if (key == "shadowSide") {
      shadowSide = newValue;
    } else if (key == "specular") {
      if (newValue is Color) {
        specular = newValue;
      } else {
        specular = Color.fromHex32(newValue);
      }
    } else if(key == 'glslVersion'){
      glslVersion = newValue;
    }
    else {
      throw ("Material.setValues key: $key newValue: $newValue is not support");
    }
  }

  /// meta -- object containing metadata such as textures or images for the
  /// material.
  /// 
  /// Convert the material to three.js
  /// [JSON Object/Scene format](https://github.com/mrdoob/three.js/wiki/JSON-Object-Scene-format-4).
  Map<String, dynamic> toJson({Object3dMeta? meta}) {
    final isRoot = (meta == null || meta is String);

    if (isRoot) {
      meta = Object3dMeta();
    }

    Map<String, dynamic> data = {
      "metadata": {
        "version": 4.5,
        "type": 'Material',
        "generator": 'Material.toJson'
      }
    };

    // standard Material serialization
    data["uuid"] = uuid;
    data["type"] = type;

    if (name != '') data["name"] = name;

    data["color"] = color.getHex();
    data["roughness"] = roughness;
    data["metalness"] = metalness;

    data["sheen"] = sheen;
    if (sheenColor != null && sheenColor is Color) {
      data["sheenColor"] = sheenColor!.getHex();
    }
    data["sheenRoughness"] = sheenRoughness;

    if (emissive != null) {
      data["emissive"] = emissive!.getHex();
    }
    if (emissiveIntensity != 1) {
      data["emissiveIntensity"] = emissiveIntensity;
    }

    if (specular != null) {
      data["specular"] = specular!.getHex();
    }
    if (specularIntensity != null) {
      data["specularIntensity"] = specularIntensity;
    }
    if (specularColor != null) {
      data["specularColor"] = specularColor!.getHex();
    }
    if (shininess != null) data["shininess"] = shininess;
    data["clearcoat"] = clearcoat;
    if (clearcoatRoughness != null) {
      data["clearcoatRoughness"] = clearcoatRoughness;
    }

    if (clearcoatMap != null && clearcoatMap is Texture) {
      data["clearcoatMap"] = clearcoatMap!.toJson(meta)['uuid'];
    }

    if (clearcoatRoughnessMap != null && clearcoatRoughnessMap is Texture) {
      data["clearcoatRoughnessMap"] =
          clearcoatRoughnessMap!.toJson(meta)['uuid'];
    }

    if (clearcoatNormalMap != null && clearcoatNormalMap is Texture) {
      data["clearcoatNormalMap"] = clearcoatNormalMap!.toJson(meta)['uuid'];
      data["clearcoatNormalScale"] = clearcoatNormalScale!.storage;
    }

    if (map != null && map is Texture) {
      data["map"] = map!.toJson(meta)["uuid"];
    }
    if (matcap != null && matcap is Texture) {
      data["matcap"] = matcap!.toJson(meta)["uuid"];
    }
    if (alphaMap != null && alphaMap is Texture) {
      data["alphaMap"] = alphaMap!.toJson(meta)["uuid"];
    }
    if (lightMap != null && lightMap is Texture) {
      data["lightMap"] = lightMap!.toJson(meta)["uuid"];
    }

    if (lightMap != null && lightMap is Texture) {
      data["lightMap"] = lightMap!.toJson(meta)['uuid'];
      data["lightMapIntensity"] = lightMapIntensity;
    }

    if (aoMap != null && aoMap is Texture) {
      data["aoMap"] = aoMap!.toJson(meta)['uuid'];
      data["aoMapIntensity"] = aoMapIntensity;
    }

    if (bumpMap != null && bumpMap is Texture) {
      data["bumpMap"] = bumpMap!.toJson(meta)['uuid'];
      data["bumpScale"] = bumpScale;
    }

    if (normalMap != null && normalMap is Texture) {
      data["normalMap"] = normalMap!.toJson(meta)['uuid'];
      data["normalMapType"] = normalMapType;
      data["normalScale"] = normalScale!.storage;
    }

    if (displacementMap != null && displacementMap is Texture) {
      data["displacementMap"] = displacementMap!.toJson(meta)['uuid'];
      data["displacementScale"] = displacementScale;
      data["displacementBias"] = displacementBias;
    }

    if (roughnessMap != null && roughnessMap is Texture) {
      data["roughnessMap"] = roughnessMap!.toJson(meta)['uuid'];
    }
    if (metalnessMap != null && metalnessMap is Texture) {
      data["metalnessMap"] = metalnessMap!.toJson(meta)['uuid'];
    }

    if (emissiveMap != null && emissiveMap is Texture) {
      data["emissiveMap"] = emissiveMap!.toJson(meta)['uuid'];
    }
    if (specularMap != null && specularMap is Texture) {
      data["specularMap"] = specularMap!.toJson(meta)['uuid'];
    }
    if (specularIntensityMap != null && specularIntensityMap is Texture) {
      data["specularIntensityMap"] = specularIntensityMap!.toJson(meta)['uuid'];
    }
    if (specularColorMap != null && specularColorMap is Texture) {
      data["specularColorMap"] = specularColorMap!.toJson(meta)['uuid'];
    }

    if (envMap != null && envMap is Texture) {
      data["envMap"] = envMap!.toJson(meta)['uuid'];

      data["refractionRatio"] = refractionRatio;

      if (combine != null) data["combine"] = combine;
      if (envMapIntensity != null) {
        data["envMapIntensity"] = envMapIntensity;
      }
    }

    if (gradientMap != null && gradientMap is Texture) {
      data["gradientMap"] = gradientMap!.toJson(meta)['uuid'];
    }

    data["transmission"] = transmission;
    if (transmissionMap != null && transmissionMap is Texture) {
      data["transmissionMap"] = transmissionMap!.toJson(meta)['uuid'];
    }
    if (thickness != null) data["thickness"] = thickness;
    if (thicknessMap != null && thicknessMap is Texture) {
      data["thicknessMap"] = thicknessMap!.toJson(meta)['uuid'];
    }
    if (attenuationColor != null) {
      data["attenuationColor"] = attenuationColor!.getHex();
    }
    if (attenuationDistance != null) {
      data["attenuationDistance"] = attenuationDistance;
    }

    if (size != null) data["size"] = size;
    if (shadowSide != null) data["shadowSide"] = shadowSide;
    data["sizeAttenuation"] = sizeAttenuation;

    if (blending != NormalBlending) data["blending"] = blending;
    if (side != FrontSide) data["side"] = side;
    if (vertexColors) data["vertexColors"] = true;

    if (opacity < 1) data["opacity"] = opacity;
    if (transparent == true) data["transparent"] = transparent;

    data["depthFunc"] = depthFunc;
    data["depthTest"] = depthTest;
    data["depthWrite"] = depthWrite;
    data["colorWrite"] = colorWrite;

    data["stencilWrite"] = stencilWrite;
    data["stencilWriteMask"] = stencilWriteMask;
    data["stencilFunc"] = stencilFunc;
    data["stencilRef"] = stencilRef;
    data["stencilFuncMask"] = stencilFuncMask;
    data["stencilFail"] = stencilFail;
    data["stencilZFail"] = stencilZFail;
    data["stencilZPass"] = stencilZPass;

    if (rotation != 0) {
      data["rotation"] = rotation;
    }

    if (polygonOffset == true) data["polygonOffset"] = true;
    if (polygonOffsetFactor != 0) {
      data["polygonOffsetFactor"] = polygonOffsetFactor;
    }
    if (polygonOffsetUnits != 0) {
      data["polygonOffsetUnits"] = polygonOffsetUnits;
    }

    if (linewidth != null && linewidth != 1) {
      data["linewidth"] = linewidth;
    }
    if (dashSize != null) data["dashSize"] = dashSize;
    if (gapSize != null) data["gapSize"] = gapSize;
    if (scale != null) data["scale"] = scale;

    if (dithering == true) data["dithering"] = true;

    if (alphaTest > 0) data["alphaTest"] = alphaTest;
    if (alphaToCoverage == true) {
      data["alphaToCoverage"] = alphaToCoverage;
    }
    if (premultipliedAlpha == true) {
      data["premultipliedAlpha"] = premultipliedAlpha;
    }

    if (wireframe == true) data["wireframe"] = wireframe;
    if (wireframeLinewidth != null && wireframeLinewidth! > 1) {
      data["wireframeLinewidth"] = wireframeLinewidth;
    }
    if (wireframeLinecap != 'round') {
      data["wireframeLinecap"] = wireframeLinecap;
    }
    if (wireframeLinejoin != 'round') {
      data["wireframeLinejoin"] = wireframeLinejoin;
    }

    if (visible == false) data["visible"] = false;

    if (toneMapped == false) data["toneMapped"] = false;

    if (fog == false) data["fog"] = false;

    if (jsonEncode(userData) != '{}') data["userData"] = userData;

    extractFromCache(cache) {
      final values = [];

      cache.keys.forEach((key) {
        final data = cache[key];
        data.remove("metadata");
        values.add(data);
      });

      return values;
    }

    if (isRoot) {
      final textures = extractFromCache(meta.textures);
      final images = extractFromCache(meta.images);

      if (textures.isNotEmpty) data["textures"] = textures;
      if (images.isNotEmpty) data["images"] = images;
    }

    return data;
  }

  /// Return a new material with the same parameters as this material.
  Material clone() {
    throw ("Material.clone $type need implement.... ");
  }

  /// Copy the parameters from the passed material into this material.
  Material copy(Material source) {
    name = source.name;

    blending = source.blending;
    side = source.side;
    vertexColors = source.vertexColors;

    opacity = source.opacity;
    transparent = source.transparent;

    blendSrc = source.blendSrc;
    blendDst = source.blendDst;
    blendEquation = source.blendEquation;
    blendSrcAlpha = source.blendSrcAlpha;
    blendDstAlpha = source.blendDstAlpha;
    blendEquationAlpha = source.blendEquationAlpha;

    depthFunc = source.depthFunc;
    depthTest = source.depthTest;
    depthWrite = source.depthWrite;

    stencilWriteMask = source.stencilWriteMask;
    stencilFunc = source.stencilFunc;
    stencilRef = source.stencilRef;
    stencilFuncMask = source.stencilFuncMask;
    stencilFail = source.stencilFail;
    stencilZFail = source.stencilZFail;
    stencilZPass = source.stencilZPass;
    stencilWrite = source.stencilWrite;

    final srcPlanes = source.clippingPlanes;
    List<Plane>? dstPlanes;

    if (srcPlanes != null) {
      final n = srcPlanes.length;
      dstPlanes = List<Plane>.filled(n, Plane());

      for (int i = 0; i != n; ++i) {
        dstPlanes[i] = srcPlanes[i].clone();
      }
    }

    clippingPlanes = dstPlanes;
    clipIntersection = source.clipIntersection;
    clipShadows = source.clipShadows;

    shadowSide = source.shadowSide;

    colorWrite = source.colorWrite;

    precision = source.precision;

    polygonOffset = source.polygonOffset;
    polygonOffsetFactor = source.polygonOffsetFactor;
    polygonOffsetUnits = source.polygonOffsetUnits;

    dithering = source.dithering;

    alphaTest = source.alphaTest;
    alphaToCoverage = source.alphaToCoverage;
    premultipliedAlpha = source.premultipliedAlpha;

    visible = source.visible;

    toneMapped = source.toneMapped;

    userData = json.decode(json.encode(source.userData));

    return this;
  }

  /// Frees the GPU-related resources allocated by this instance. Call this
  /// method whenever this instance is no longer used in your app.
  /// 
  /// Material textures must be be disposed of by the dispose() method of
  /// [Texture].
  void dispose() {
    dispatchEvent(Event(type: "dispose"));
  }

  Object? getProperty(String propertyName) {
    if (propertyName == "vertexParameters") {
      return color;
    } else if (propertyName == "opacity") {
      return opacity;
    } else if (propertyName == "color") {
      return color;
    } else if (propertyName == "emissive") {
      return emissive;
    } else if (propertyName == "flatShading") {
      return flatShading;
    } else if (propertyName == "wireframe") {
      return wireframe;
    } else if (propertyName == "vertexColors") {
      return vertexColors;
    } else if (propertyName == "transparent") {
      return transparent;
    } else if (propertyName == "depthTest") {
      return depthTest;
    } else if (propertyName == "depthWrite") {
      return depthWrite;
    } else if (propertyName == "visible") {
      return visible;
    } else if (propertyName == "blending") {
      return blending;
    } else if (propertyName == "side") {
      return side;
    } else if (propertyName == "roughness") {
      return roughness;
    } else if (propertyName == "metalness") {
      return metalness;
    } else {
      throw ("Material.getProperty type: $type propertyName: $propertyName is not support ");
    }
  }
  void operator []=(String key, dynamic value) => setProperty(key, value);
  void setProperty(String propertyName, dynamic value) {
    if (propertyName == "color") {
      color = value;
    } else if (propertyName == "opacity") {
      opacity = value;
    } else if (propertyName == "emissive") {
      emissive = value;
    } else if (propertyName == "flatShading") {
      flatShading = value;
    } else if (propertyName == "wireframe") {
      wireframe = value;
    } else if (propertyName == "vertexColors") {
      vertexColors = value;
    } else if (propertyName == "transparent") {
      transparent = value;
    } else if (propertyName == "depthTest") {
      depthTest = value;
    } else if (propertyName == "depthWrite") {
      depthWrite = value;
    } else if (propertyName == "visible") {
      visible = value;
    } else if (propertyName == "blending") {
      blending = value;
    } else if (propertyName == "side") {
      side = value;
    } else if (propertyName == "roughness") {
      roughness = value;
    } else if (propertyName == "metalness") {
      metalness = value;
    } else {
      throw ("Material.setProperty type: $type propertyName: $propertyName is not support ");
    }
  }

  set needsUpdate(bool value) {
    if (value == true) version++;
  }
}
