import 'dart:async';
import 'dart:typed_data';
import 'dart:io';
import 'dart:convert';
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';
import 'package:three_js_core_loaders/three_js_core_loaders.dart';

/// A loader for loading a [Material] in JSON format. This uses the
/// [FileLoader] internally for loading files.
class MaterialLoader extends Loader {
  late final FileLoader _loader;
  late Map textures;

  /// [manager] — The [loadingManager] for the loader to use. Default is [DefaultLoadingManager].
  /// 
  /// Creates a new [FontLoader].
  MaterialLoader([super.manager]){
    textures = {};
    _loader = FileLoader(manager);
  }

  @override
  void dispose(){
    super.dispose();
    _loader.dispose();
  }

  void _init(){
    _loader.setPath(path);
    _loader.setRequestHeader(requestHeader);
    _loader.setWithCredentials(withCredentials);
  }

  @override
  Future<Material?> fromNetwork(Uri uri) async{
    _init();
    ThreeFile? tf = await _loader.fromNetwork(uri);
    return tf == null?null:_parse(tf.data);
  }
  @override
  Future<Material?> fromFile(File file) async{
    _init();
    ThreeFile tf = await _loader.fromFile(file);
    return _parse(tf.data);
  }
  @override
  Future<Material?> fromPath(String filePath) async{
    _init();
    ThreeFile? tf = await _loader.fromPath(filePath);
    return tf == null?null:_parse(tf.data);
  }
  @override
  Future<Material?> fromBlob(Blob blob) async{
    _init();
    ThreeFile tf = await _loader.fromBlob(blob);
    return _parse(tf.data);
  }
  @override
  Future<Material?> fromAsset(String asset, {String? package}) async{
    _init();
    ThreeFile? tf = await _loader.fromAsset(asset,package: package);
    return tf == null?null:_parse(tf.data);
  }
  @override
  Future<Material?> fromBytes(Uint8List bytes) async{
    _init();
    ThreeFile tf = await _loader.fromBytes(bytes);
    return _parse(tf.data);
  }

  Material _parse(Uint8List bytes) {
    Map<String,dynamic> json = jsonDecode(String.fromCharCodes(bytes));
    return parseJson(json);
  }

  Material parseJson(Map<String,dynamic> json) {
    
    final textures = this.textures;

    getTexture(name) {
      if (textures[name] == null) {
        console.warning('MaterialLoader: Undefined texture $name');
      }
      return textures[name];
    }

    Material material;

    if (json["type"] == "MeshBasicMaterial") {
      material = MeshBasicMaterial();
    } else if (json["type"] == "MeshLambertMaterial") {
      material = MeshLambertMaterial();
    } else if (json["type"] == "MeshPhongMaterial") {
      material = MeshPhongMaterial();
    } else if (json["type"] == "MeshMatcapMaterial") {
      material = MeshMatcapMaterial();
    } else if (json["type"] == "MeshPhysicalMaterial") {
      material = MeshPhysicalMaterial();
    } else {
      throw (" MaterialLoader ${json["type"]} is not support  ");
    }

    // final material = new Materials[ json.type ]();

    if (json["uuid"] != null) material.uuid = json["uuid"];
    if (json["name"] != null) material.name = json["name"];
    if (json["color"] != null) {
      material.color.setFromHex32(json["color"]);
    }
    if (json["roughness"] != null) material.roughness = json["roughness"];
    if (json["metalness"] != null) material.metalness = json["metalness"];
    if (json["sheen"] != null) material.sheen = json["sheen"];
    if (json["sheenColor"] != null) {
      material.sheenColor = Color(0, 0, 0)..setFromHex32(json["sheenColor"]);
    }
    if (json["sheenRoughness"] != null) {
      material.sheenRoughness = json["sheenRoughness"];
    }
    if (json["emissive"] != null && material.emissive != null) {
      material.emissive!.setFromHex32(json["emissive"]);
    }
    if (json["specular"] != null && material.specular != null) {
      material.specular!.setFromHex32(json["specular"]);
    }
    if (json["specularIntensity"] != null) {
      material.specularIntensity = json["specularIntensity"];
    }
    if (json["specularColor"] != null && material.specularColor != null) {
      material.specularColor!.setFromHex32(json["specularColor"]);
    }
    if (json["shininess"] != null) material.shininess = json["shininess"];
    if (json["clearcoat"] != null) material.clearcoat = json["clearcoat"];
    if (json["clearcoatRoughness"] != null) {
      material.clearcoatRoughness = json["clearcoatRoughness"];
    }
    if (json["transmission"] != null) {
      material.transmission = json["transmission"];
    }
    if (json["thickness"] != null) material.thickness = json["thickness"];
    if (json["attenuationDistance"] != null) {
      material.attenuationDistance = json["attenuationDistance"];
    }
    if (json["attenuationColor"] != null && material.attenuationColor != null) {
      material.attenuationColor!.setFromHex32(json["attenuationColor"]);
    }
    if (json["fog"] != null) material.fog = json["fog"];
    if (json["flatShading"] != null) material.flatShading = json["flatShading"];
    if (json["blending"] != null) material.blending = json["blending"];
    if (json["combine"] != null) material.combine = json["combine"];
    if (json["side"] != null) material.side = json["side"];
    if (json["shadowSide"] != null) material.shadowSide = json["shadowSide"];
    if (json["opacity"] != null) material.opacity = json["opacity"];
    if (json["transparent"] != null) material.transparent = json["transparent"];
    if (json["alphaTest"] != null) material.alphaTest = json["alphaTest"];
    if (json["depthTest"] != null) material.depthTest = json["depthTest"];
    if (json["depthWrite"] != null) material.depthWrite = json["depthWrite"];
    if (json["colorWrite"] != null) material.colorWrite = json["colorWrite"];

    if (json["stencilWrite"] != null) {
      material.stencilWrite = json["stencilWrite"];
    }
    if (json["stencilWriteMask"] != null) {
      material.stencilWriteMask = json["stencilWriteMask"];
    }
    if (json["stencilFunc"] != null) material.stencilFunc = json["stencilFunc"];
    if (json["stencilRef"] != null) material.stencilRef = json["stencilRef"];
    if (json["stencilFuncMask"] != null) {
      material.stencilFuncMask = json["stencilFuncMask"];
    }
    if (json["stencilFail"] != null) material.stencilFail = json["stencilFail"];
    if (json["stencilZFail"] != null) {
      material.stencilZFail = json["stencilZFail"];
    }
    if (json["stencilZPass"] != null) {
      material.stencilZPass = json["stencilZPass"];
    }

    if (json["wireframe"] != null) material.wireframe = json["wireframe"];
    if (json["wireframeLinewidth"] != null) {
      material.wireframeLinewidth = json["wireframeLinewidth"];
    }
    if (json["wireframeLinecap"] != null) {
      material.wireframeLinecap = json["wireframeLinecap"];
    }
    if (json["wireframeLinejoin"] != null) {
      material.wireframeLinejoin = json["wireframeLinejoin"];
    }

    if (json["rotation"] != null) material.rotation = json["rotation"];

    if (json["linewidth"] != 1) material.linewidth = json["linewidth"];
    if (json["dashSize"] != null) material.dashSize = json["dashSize"];
    if (json["gapSize"] != null) material.gapSize = json["gapSize"];
    if (json["scale"] != null) material.scale = json["scale"];

    if (json["polygonOffset"] != null) {
      material.polygonOffset = json["polygonOffset"];
    }
    if (json["polygonOffsetFactor"] != null) {
      material.polygonOffsetFactor = json["polygonOffsetFactor"];
    }
    if (json["polygonOffsetUnits"] != null) {
      material.polygonOffsetUnits = json["polygonOffsetUnits"];
    }

    if (json["dithering"] != null) material.dithering = json["dithering"];

    if (json["alphaToCoverage"] != null) {
      material.alphaToCoverage = json["alphaToCoverage"];
    }
    if (json["premultipliedAlpha"] != null) {
      material.premultipliedAlpha = json["premultipliedAlpha"];
    }

    if (json["visible"] != null) material.visible = json["visible"];

    if (json["toneMapped"] != null) material.toneMapped = json["toneMapped"];

    if (json["userData"] != null) material.userData = json["userData"];

    if (json["vertexColors"] != null) {
      if (json["vertexColors"] is num) {
        material.vertexColors = (json["vertexColors"] > 0) ? true : false;
      } else {
        material.vertexColors = json["vertexColors"];
      }
    }

    // Shader Material

    if (json["uniforms"] != null) {
      for (final name in json["uniforms"]) {
        final uniform = json["uniforms"][name];

        material.uniforms[name] = {};

        switch (uniform.type) {
          case 't':
            material.uniforms[name].value = getTexture(uniform.value);
            break;

          case 'c':
            material.uniforms[name].value =
                Color.fromHex32(uniform.value);
            break;

          case 'v2':
            material.uniforms[name].value =
                Vector2(0, 0).copyFromArray(uniform.value);
            break;

          case 'v3':
            material.uniforms[name].value =
                Vector3(0, 0, 0).copyFromArray(uniform.value);
            break;

          case 'v4':
            material.uniforms[name].value =
                Vector4(0, 0, 0, 0).copyFromArray(uniform.value);
            break;

          case 'm3':
            material.uniforms[name].value =
                Matrix3.identity().copyFromArray(uniform.value);
            break;

          case 'm4':
            material.uniforms[name].value =
                Matrix4().copyFromArray(uniform.value);
            break;

          default:
            material.uniforms[name].value = uniform.value;
        }
      }
    }

    if (json["defines"] != null) material.defines = json["defines"];
    if (json["vertexShader"] != null) {
      material.vertexShader = json["vertexShader"];
    }
    if (json["fragmentShader"] != null) {
      material.fragmentShader = json["fragmentShader"];
    }

    if (json["extensions"] != null) {
      for (final key in json["extensions"]) {
        material.extensions?[key] = json["extensions"][key];
      }
    }

    // Deprecated

    if (json["shading"] != null) {
      material.flatShading = json["shading"] == 1;
    } // THREE.FlatShading

    // for PointsMaterial

    if (json["size"] != null) material.size = json["size"];
    if (json["sizeAttenuation"] != null) {
      material.sizeAttenuation = json["sizeAttenuation"];
    }

    // maps

    if (json["map"] != null) material.map = getTexture(json["map"]);
    if (json["matcap"] != null) material.matcap = getTexture(json["matcap"]);

    if (json["alphaMap"] != null) {
      material.alphaMap = getTexture(json["alphaMap"]);
    }

    if (json["bumpMap"] != null) material.bumpMap = getTexture(json["bumpMap"]);
    if (json["bumpScale"] != null) material.bumpScale = json["bumpScale"];

    if (json["normalMap"] != null) {
      material.normalMap = getTexture(json["normalMap"]);
    }
    if (json["normalMapType"] != null) {
      material.normalMapType = json["normalMapType"];
    }
    if (json["normalScale"] != null) {
      dynamic normalScale = json["normalScale"];

      if (normalScale is! List) {
        // Blender exporter used to export a scalar. See #7459
        normalScale = [normalScale.toDouble(), normalScale.toDouble()];
      }

      material.normalScale = Vector2(0, 0).copyFromArray(normalScale as List<double>);
    }

    if (json["displacementMap"] != null) {
      material.displacementMap = getTexture(json["displacementMap"]);
    }
    if (json["displacementScale"] != null) {
      material.displacementScale = json["displacementScale"];
    }
    if (json["displacementBias"] != null) {
      material.displacementBias = json["displacementBias"];
    }

    if (json["roughnessMap"] != null) {
      material.roughnessMap = getTexture(json["roughnessMap"]);
    }
    if (json["metalnessMap"] != null) {
      material.metalnessMap = getTexture(json["metalnessMap"]);
    }

    if (json["emissiveMap"] != null) {
      material.emissiveMap = getTexture(json["emissiveMap"]);
    }
    if (json["emissiveIntensity"] != null) {
      material.emissiveIntensity = json["emissiveIntensity"];
    }

    if (json["specularMap"] != null) {
      material.specularMap = getTexture(json["specularMap"]);
    }
    if (json["specularIntensityMap"] != null) {
      material.specularIntensityMap = getTexture(json["specularIntensityMap"]);
    }
    if (json["specularColorMap"] != null) {
      material.specularColorMap = getTexture(json["specularColorMap"]);
    }

    if (json["envMap"] != null) material.envMap = getTexture(json["envMap"]);
    if (json["envMapIntensity"] != null) {
      material.envMapIntensity = json["envMapIntensity"];
    }

    if (json["reflectivity"] != null) {
      material.reflectivity = json["reflectivity"];
    }
    if (json["refractionRatio"] != null) {
      material.refractionRatio = json["refractionRatio"];
    }

    if (json["lightMap"] != null) {
      material.lightMap = getTexture(json["lightMap"]);
    }
    if (json["lightMapIntensity"] != null) {
      material.lightMapIntensity = json["lightMapIntensity"];
    }

    if (json["aoMap"] != null) material.aoMap = getTexture(json["aoMap"]);
    if (json["aoMapIntensity"] != null) {
      material.aoMapIntensity = json["aoMapIntensity"];
    }

    if (json["gradientMap"] != null) {
      material.gradientMap = getTexture(json["gradientMap"]);
    }

    if (json["clearcoatMap"] != null) {
      material.clearcoatMap = getTexture(json["clearcoatMap"]);
    }
    if (json["clearcoatRoughnessMap"] != null) {
      material.clearcoatRoughnessMap =
          getTexture(json["clearcoatRoughnessMap"]);
    }
    if (json["clearcoatNormalMap"] != null) {
      material.clearcoatNormalMap = getTexture(json["clearcoatNormalMap"]);
    }
    if (json["clearcoatNormalScale"] != null) {
      material.clearcoatNormalScale =
          Vector2(0, 0).copyFromArray(json["clearcoatNormalScale"]);
    }

    if (json["transmissionMap"] != null) {
      material.transmissionMap = getTexture(json["transmissionMap"]);
    }
    if (json["thicknessMap"] != null) {
      material.thicknessMap = getTexture(json["thicknessMap"]);
    }

    if (json["sheenColorMap"] != null) {
      material.sheenColorMap = getTexture(json["sheenColorMap"]);
    }
    if (json["sheenRoughnessMap"] != null) {
      material.sheenRoughnessMap = getTexture(json["sheenRoughnessMap"]);
    }

    return material;
  }

  setTextures(value) {
    textures = value;
    return this;
  }
}
