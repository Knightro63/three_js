import 'dart:async';
import 'dart:typed_data';
import 'dart:math' as math;
import 'gltf_registry.dart';
import 'gltf_parser.dart';

import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';
import 'gltf_extensions.dart';

///*********************************/
///********** INTERNALS ************/
///*********************************/

/* CONSTANTS */

final webglConstants = {
  "FLOAT": 5126,
  //FLOAT_MAT2: 35674,
  "FLOAT_MAT3": 35675,
  "FLOAT_MAT4": 35676,
  "FLOAT_VEC2": 35664,
  "FLOAT_VEC3": 35665,
  "FLOAT_VEC4": 35666,
  "LINEAR": 9729,
  "REPEAT": 10497,
  "SAMPLER_2D": 35678,
  "POINTS": 0,
  "LINES": 1,
  "LINE_LOOP": 2,
  "LINE_STRIP": 3,
  "TRIANGLES": 4,
  "TRIANGLE_STRIP": 5,
  "TRIANGLE_FAN": 6,
  "UNSIGNED_BYTE": 5121,
  "UNSIGNED_SHORT": 5123
};

class GLTypeData {
  late int type;

  GLTypeData(this.type);

  int? getBytesPerElement() {
    return webglCTBPE[type];
  }

  dynamic view(ByteBuffer buffer, int offset, int length) {
    if (type == 5120) {
      return Int8List.view(buffer, offset, length);
    } else if (type == 5121) {
      return Uint8List.view(buffer, offset, length);
    } else if (type == 5122) {
      return Int16List.view(buffer, offset, length);
    } else if (type == 5123) {
      return Uint16List.view(buffer, offset, length);
    } else if (type == 5125) {
      return Uint32List.view(buffer, offset, length);
    } else if (type == 5126) {
      return Float32List.view(buffer, offset, length);
    } else {
      throw (" GLTFHelper GLTypeData view type: $type is not support ...");
    }
  }

  dynamic createList(int len) {
    if (type == 5120) {
      return Int8List(len);
    } else if (type == 5121) {
      return Uint8List(len);
    } else if (type == 5122) {
      return Int16List(len);
    } else if (type == 5123) {
      return Uint16List(len);
    } else if (type == 5125) {
      return Uint32List(len);
    } else if (type == 5126) {
      return Float32List(len);
    } else {
      throw (" GLTFHelper GLTypeData  createList type: $type is not support ...");
    }
  }

  static dynamic createBufferAttribute(List array, int itemSize, bool normalized) {
    if (array is Int8List) {
      return Int8BufferAttribute.fromList(array, itemSize, normalized);
    } else if (array is Uint8List) {
      return Uint8BufferAttribute.fromList(array, itemSize, normalized);
    } else if (array is Int16List) {
      return Int16BufferAttribute.fromList(array, itemSize, normalized);
    } else if (array is Uint16List) {
      return Uint16BufferAttribute.fromList(array, itemSize, normalized);
    } else if (array is Uint32List) {
      return Uint32BufferAttribute.fromList(array, itemSize, normalized);
    } else if (array is Float32List) {
      return Float32BufferAttribute.fromList(array, itemSize, normalized);
    } else {
      throw ("GLTFHelper createBufferAttribute  array.runtimeType : ${array.runtimeType} is not support yet");
    }
  }
}

final webglComponentTypes = {
  5120: Int8List,
  5121: Uint8List,
  5122: Int16List,
  5123: Uint16List,
  5125: Uint32List,
  5126: Float32List
};

final webglCTBPE = {
  5120: Int8List.bytesPerElement,
  5121: Uint8List.bytesPerElement,
  5122: Int16List.bytesPerElement,
  5123: Uint16List.bytesPerElement,
  5125: Uint32List.bytesPerElement,
  5126: Float32List.bytesPerElement
};

final webglFilters = {
  9728: NearestFilter,
  9729: LinearFilter,
  9984: NearestMipmapNearestFilter,
  9985: LinearMipmapNearestFilter,
  9986: NearestMipmapLinearFilter,
  9987: LinearMipmapLinearFilter
};

final webglWrappings = {
  33071: ClampToEdgeWrapping,
  33648: MirroredRepeatWrapping,
  10497: RepeatWrapping
};

final webglTypeSize = {
  'SCALAR': 1,
  'VEC2': 2,
  'VEC3': 3,
  'VEC4': 4,
  'MAT2': 4,
  'MAT3': 9,
  'MAT4': 16
};

final webglAttributes = {
  "POSITION": 'position',
  "NORMAL": 'normal',
  "TANGENT": 'tangent',
  "TEXCOORD_0": 'uv',
  "TEXCOORD_1": 'uv2',
  "COLOR_0": 'color',
  "WEIGHTS_0": 'skinWeight',
  "JOINTS_0": 'skinIndex',
};

class PathProperties {
  static const String scale = 'scale';
  static const String translation = 'position';
  static const String rotation = 'quaternion';
  static const String weights = 'morphTargetInfluences';
  static const String position = 'position';

  static String getValue(String k) {
    if (k == "scale") {
      return scale;
    } else if (k == "translation") {
      return translation;
    } else if (k == "rotation") {
      return rotation;
    } else if (k == "weights") {
      return weights;
    } else if (k == "position") {
      return position;
    } else {
      throw ("GLTFHelper PATH_PROPERTIES getValue k: $k is not support ");
    }
  }
}

final gltfInterpolation = {
  "CUBICSPLINE": null, // We use a custom interpolant (GLTFCubicSplineInterpolation) for CUBICSPLINE tracks. Each
  // keyframe track will be initialized with a default interpolation type, then modified.
  "LINEAR": InterpolateLinear,
  "STEP": InterpolateDiscrete
};

final gltfAlphaModes = {"OPAQUE": 'OPAQUE', "MASK": 'MASK', "BLEND": 'BLEND'};

///
/// Specification: https://github.com/KhronosGroup/glTF/blob/master/specification/2.0/README.md#default-material
///
Function createDefaultMaterial = (GLTFRegistry cache) {
  if (cache.get('DefaultMaterial') == null) {
    cache.add(
        "DefaultMaterial",
        MeshStandardMaterial.fromMap({
          "color": 0xFFFFFF,
          "emissive": 0x000000,
          "metalness": 1,
          "roughness": 1,
          "transparent": false,
          "depthTest": true,
          "side": FrontSide
        }));
  }

  return cache.get("DefaultMaterial");
};

Function addUnknownExtensionsToUserData = (knownExtensions,object, Map<String, dynamic> objectDef) {
  // Add unknown glTF extensions to an object's userData.
  if (objectDef["extensions"] != null) {
    objectDef["extensions"].forEach((name, value) {
      if (knownExtensions[name] == null) {
        object?.userData["gltfExtensions"] = object.userData["gltfExtensions"] ?? {};
        object?.userData["gltfExtensions"][name] = objectDef["extensions"][name];
      }
    });
  }
};

///
/// @param {Object3D|Material|BufferGeometry} object
/// @param {GLTF.definition} gltfDef
///
Function assignExtrasToUserData = (object, gltfDef) {
  if (gltfDef["extras"] != null) {
    if (gltfDef["extras"] is Map) {
      object.userData.addAll(gltfDef["extras"]);
    } 
    else {
      console.info('GLTFLoader: Ignoring primitive type .extras, ${gltfDef["extras"]}');
    }
  }
};

///
/// Specification: https://github.com/KhronosGroup/glTF/blob/master/specification/2.0/README.md#morph-targets
///
/// @param {BufferGeometry} geometry
/// @param {Array<GLTF.Target>} targets
/// @param {GLTFParser} parser
/// @return {Promise<BufferGeometry>}
///
Future<BufferGeometry> addMorphTargets(BufferGeometry geometry, targets, GLTFParser parser) async {
  bool hasMorphPosition = false;
  bool hasMorphNormal = false;
  bool hasMorphColor = false;

  for (int i = 0, il = targets.length; i < il; i++) {
    final target = targets[i];

    if (target["POSITION"] != null) hasMorphPosition = true;
    if (target["NORMAL"] != null) hasMorphNormal = true;
    if (target["COLOR_0"] != null) hasMorphColor = true;

    if (hasMorphPosition && hasMorphNormal && hasMorphColor) break;
  }

  if (!hasMorphPosition && !hasMorphNormal && !hasMorphColor) return geometry;

  List<BufferAttribute> morphPositions = [];
  List<BufferAttribute> morphNormals = [];
  List<BufferAttribute> morphColors = [];

  for (int i = 0, il = targets.length; i < il; i++) {
    final target = targets[i];

    if (hasMorphPosition) {
      final position = target["POSITION"] != null
          ? await parser.getDependency('accessor', target["POSITION"])
          : geometry.attributes["position"];

      morphPositions.add(position);
    }

    if (hasMorphNormal) {
      final normal = target["NORMAL"] != null
          ? await parser.getDependency('accessor', target["NORMAL"])
          : geometry.attributes["normal"];

      morphNormals.add(normal);
    }

    if (hasMorphColor) {
      final color = target["COLOR_0"] != null
          ? await parser.getDependency('accessor', target["COLOR_0"])
          : geometry.attributes["color"];

      morphColors.add(color);
    }
  }

  if (hasMorphPosition) geometry.morphAttributes["position"] = morphPositions;
  if (hasMorphNormal) geometry.morphAttributes["normal"] = morphNormals;
  if (hasMorphColor) geometry.morphAttributes["color"] = morphColors;

  geometry.morphTargetsRelative = true;

  return geometry;
}

///
/// @param {Mesh} mesh
/// @param {GLTF.Mesh} meshDef
///
Function updateMorphTargets = (Mesh mesh, Map<String, dynamic> meshDef) {
  mesh.updateMorphTargets();

  if (meshDef["weights"] != null) {
    for (int i = 0, il = meshDef["weights"].length; i < il; i++) {
      mesh.morphTargetInfluences?[i] = meshDef["weights"][i].toDouble();
    }
  }

  // .extras has user-defined data, so check that .extras.targetNames is an array.
  if (meshDef["extras"] != null && meshDef["extras"]["targetNames"] is List) {
    final targetNames = meshDef["extras"]["targetNames"];

    if (mesh.morphTargetInfluences?.length == targetNames.length) {
      mesh.morphTargetDictionary = {};

      for (int i = 0, il = targetNames.length; i < il; i++) {
        mesh.morphTargetDictionary?[targetNames[i]] = i;
      }
    } 
    else {
      console.warning('GLTFLoader: Invalid extras.targetNames length. Ignoring names.');
    }
  }
};

Function createPrimitiveKey = (Map<String, dynamic> primitiveDef) {
  final dracoExtension = primitiveDef["extensions"] != null
      ? primitiveDef["extensions"][extensions["KHR_DRACO_MESH_COMPRESSION"]!]
      : null;
  late String geometryKey;

  if (dracoExtension != null) {
    geometryKey = 'draco:${dracoExtension["bufferView"]}:${dracoExtension["indices"]}:${createAttributesKey(dracoExtension["attributes"])}';
  } 
  else {
    geometryKey = '${primitiveDef["indices"]}:${createAttributesKey(primitiveDef["attributes"])}:${primitiveDef["mode"]}';
  }

  return geometryKey;
};

Function createAttributesKey = (Map<String, dynamic> attributes) {
  String attributesKey = '';

  final keys = attributes.keys.toList();
  keys.sort();

  for (int i = 0, il = keys.length; i < il; i++) {
    attributesKey += '${keys[i]}:${attributes[keys[i]]};';
  }

  return attributesKey;
};

double getNormalizedComponentScale(constructor) {
  print(constructor.toString());
  // Reference:
  // https://github.com/KhronosGroup/glTF/tree/master/extensions/2.0/Khronos/KHR_mesh_quantization#encoding-quantized-data

  switch (constructor.toString()) {
    case "Int8List":
    case "Int8Array":
      return 1 / 127;
    case "Uint8List":
    case "Uint8Array":
      return 1 / 255;
    case "Int16List":
    case "Int16Array":
      return 1 / 32767;
    case "Uint16List":
    case "Uint16Array":
      return 1 / 65535;

    default:
      throw ('THREE.GLTFLoader: Unsupported normalized accessor component type.');
  }
}

///
/// @param {BufferGeometry} geometry
/// @param {GLTF.Primitive} primitiveDef
/// @param {GLTFParser} parser
///
Function computeBounds =
    (BufferGeometry geometry, Map<String, dynamic> primitiveDef, GLTFParser parser) {
  Map<String, dynamic> attributes = primitiveDef["attributes"];

  final box = BoundingBox();

  if (attributes["POSITION"] != null) {
    final accessor = parser.json["accessors"][attributes["POSITION"]];

    final min = accessor["min"];
    final max = accessor["max"];

    // glTF requires 'min' and 'max', but VRM (which extends glTF) currently ignores that requirement.

    if (min != null && max != null) {
      box.set(Vector3(min[0].toDouble(), min[1].toDouble(), min[2].toDouble()),
          Vector3(max[0].toDouble(), max[1].toDouble(), max[2].toDouble()));

      // todo normalized is bool ? int ?
      if (accessor["normalized"] != null &&
          accessor["normalized"] != false &&
          accessor["normalized"] != 0) {
        final boxScale = getNormalizedComponentScale( webglComponentTypes[accessor.componentType]);
        box.min.scale(boxScale);
        box.max.scale(boxScale);
      }
    } 
    else {
      console.warning('GLTFLoader: Missing min/max properties for accessor POSITION.');

      return;
    }
  } else {
    return;
  }

  final targets = primitiveDef["targets"];

  if (targets != null) {
    final maxDisplacement = Vector3();
    final vector = Vector3();

    for (int i = 0, il = targets.length; i < il; i++) {
      final target = targets[i];

      if (target["POSITION"] != null) {
        final accessor = parser.json["accessors"][target["POSITION"]];
        final min = accessor["min"];
        final max = accessor["max"];

        // glTF requires 'min' and 'max', but VRM (which extends glTF) currently ignores that requirement.

        if (min != null && max != null) {
          // we need to get max of absolute components because target weight is [-1,1]
          vector.setX(math.max<double>(min[0].abs().toDouble(), max[0].abs().toDouble()));
          vector.setY(math.max<double>(min[1].abs().toDouble(), max[1].abs().toDouble()));
          vector.setZ(math.max<double>(min[2].abs().toDouble(), max[2].abs().toDouble()));

          if (accessor["normalized"] == true) {
            final boxScale = getNormalizedComponentScale(webglComponentTypes[accessor.componentType]);
            vector.scale(boxScale);
          }

          // Note: this assumes that the sum of all weights is at most 1. This isn't quite correct - it's more conservative
          // to assume that each target can have a max weight of 1. However, for some use cases - notably, when morph targets
          // are used to implement key-frame animations and as such only two are active at a time - this results in very large
          // boxes. So for now we make a box that's sometimes a touch too small but is hopefully mostly of reasonable size.
          maxDisplacement.max(vector);
        } 
        else {
          console.warning('GLTFLoader: Missing min/max properties for accessor POSITION.');
        }
      }
    }

    // As per comment above this box isn't conservative, but has a reasonable size for a very large number of morph targets.
    box.expandByVector(maxDisplacement);
  }

  geometry.boundingBox = box;

  final sphere = BoundingSphere();

  box.getCenter(sphere.center);
  sphere.radius = box.min.distanceTo(box.max) / 2;

  geometry.boundingSphere = sphere;
};

///
/// @param {BufferGeometry} geometry
/// @param {GLTF.Primitive} primitiveDef
/// @param {GLTFParser} parser
/// @return {Promise<BufferGeometry>}
///
Function addPrimitiveAttributes =
    (BufferGeometry geometry, Map<String, dynamic> primitiveDef, GLTFParser parser) async {
  final attributes = primitiveDef["attributes"];

  List pending = [];

  assignAttributeAccessor(accessorIndex, attributeName) async {
    final accessor = await parser.getDependency('accessor', accessorIndex);
    return geometry.setAttributeFromString(attributeName, accessor);
  }

  List<String> attKeys = geometry.attributes.keys.toList();

  for (final gltfAttributeName in attributes.keys) {
    //final value = attributes[gltfAttributeName];

    final threeAttributeName = webglAttributes[gltfAttributeName] ?? gltfAttributeName.toLowerCase();

    // Skip attributes already provided by e.g. Draco extension.
    if (attKeys.contains(threeAttributeName)) {
      // skip
    } 
    else {
      await assignAttributeAccessor(
          attributes[gltfAttributeName], threeAttributeName);
      pending.add(geometry);
    }
  }

  if (primitiveDef["indices"] != null && geometry.index == null) {
    final accessor =
        await parser.getDependency('accessor', primitiveDef["indices"]);
    geometry.setIndex(accessor);
  }

  assignExtrasToUserData(geometry, primitiveDef);

  computeBounds(geometry, primitiveDef, parser);

  return primitiveDef["targets"] != null
      ? await addMorphTargets(geometry, primitiveDef["targets"], parser)
      : geometry;
};

///
/// @param {BufferGeometry} geometry
/// @param {Number} drawMode
/// @return {BufferGeometry}
///
Function toTrianglesDrawMode = (BufferGeometry geometry, num drawMode) {
  BufferAttribute? index = geometry.getIndex();

  // generate index if not present

  if (index == null) {
    final indices = [];

    final position = geometry.getAttributeFromString('position');

    if (position != null) {
      for (int i = 0; i < position.count; i++) {
        indices.add(i);
      }

      geometry.setIndex(indices);
      index = geometry.getIndex();
    } 
    else {
      console.warning('GLTFLoader.toTrianglesDrawMode(): Undefined position attribute. Processing not possible.');
      return geometry;
    }
  }

  //

  final numberOfTriangles = index!.count - 2;
  final newIndices = [];

  if (drawMode == TriangleFanDrawMode) {
    // gl.TRIANGLE_FAN

    for (int i = 1; i <= numberOfTriangles; i++) {
      newIndices.add(index.getX(0));
      newIndices.add(index.getX(i));
      newIndices.add(index.getX(i + 1));
    }
  } else {
    // gl.TRIANGLE_STRIP

    for (int i = 0; i < numberOfTriangles; i++) {
      if (i % 2 == 0) {
        newIndices.add(index.getX(i));
        newIndices.add(index.getX(i + 1));
        newIndices.add(index.getX(i + 2));
      } else {
        newIndices.add(index.getX(i + 2));
        newIndices.add(index.getX(i + 1));
        newIndices.add(index.getX(i));
      }
    }
  }

  if ((newIndices.length / 3) != numberOfTriangles) {
    console.warning('GLTFLoader.toTrianglesDrawMode(): Unable to generate correct amount of triangles.');
  }

  // build final geometry

  final newGeometry = geometry.clone();
  newGeometry.setIndex(newIndices);

  return newGeometry;
};
