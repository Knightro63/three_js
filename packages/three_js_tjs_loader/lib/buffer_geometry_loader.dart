import 'dart:async';
import 'dart:typed_data';
import 'dart:convert' as convert;
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:three_js_core/three_js_core.dart';
import 'package:flutter_gl/flutter_gl.dart';
import 'package:three_js_math/three_js_math.dart';
import 'package:three_js_core_loaders/three_js_core_loaders.dart';

class BufferGeometryLoader extends Loader {
  late final FileLoader _loader;

  BufferGeometryLoader([super.manager]){
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
  Future<BufferGeometry?> fromNetwork(Uri uri) async{
    _init();
    ThreeFile? tf = await _loader.fromNetwork(uri);
    return tf == null?null:_parse(tf.data);
  }
  @override
  Future<BufferGeometry> fromFile(File file) async{
    _init();
    ThreeFile tf = await _loader.fromFile(file);
    return _parse(tf.data);
  }
  @override
  Future<BufferGeometry?> fromPath(String filePath) async{
    _init();
    ThreeFile? tf = await _loader.fromPath(filePath);
    return tf == null?null:_parse(tf.data);
  }
  @override
  Future<BufferGeometry> fromBlob(Blob blob) async{
    _init();
    ThreeFile tf = await _loader.fromBlob(blob);
    return _parse(tf.data);
  }
  @override
  Future<BufferGeometry?> fromAsset(String asset, {String? package}) async{
    _init();
    ThreeFile? tf = await _loader.fromAsset(asset,package: package);
    return tf == null?null:_parse(tf.data);
  }
  @override
  Future<BufferGeometry> fromBytes(Uint8List bytes) async{
    _init();
    ThreeFile tf = await _loader.fromBytes(bytes);
    return _parse(tf.data);
  }
  BufferGeometry _parse(Uint8List bytes) {
    Map<String,dynamic> json = convert.jsonDecode(String.fromCharCodes(bytes));
    return parseJson(json);
  }
  BufferGeometry parseJson(Map<String,dynamic> json) {
    final interleavedBufferMap = {};
    final arrayBufferMap = {};

    getArrayBuffer(json, uuid) {
      if (arrayBufferMap[uuid] != null) return arrayBufferMap[uuid];

      final arrayBuffers = json.arrayBuffers;
      final arrayBuffer = arrayBuffers[uuid];

      final ab = Uint32Array(arrayBuffer).buffer;

      arrayBufferMap[uuid] = ab;

      return ab;
    }

    getInterleavedBuffer(json, uuid) {
      if (interleavedBufferMap[uuid] != null) return interleavedBufferMap[uuid];

      final interleavedBuffers = json.interleavedBuffers;
      final interleavedBuffer = interleavedBuffers[uuid];

      final buffer = getArrayBuffer(json, interleavedBuffer.buffer);

      final array = getTypedArray(interleavedBuffer.type, buffer);
      final ib = InterleavedBuffer(array, interleavedBuffer.stride);
      ib.uuid = interleavedBuffer.uuid;

      interleavedBufferMap[uuid] = ib;

      return ib;
    }

    final geometry = json["isInstancedBufferGeometry"] == true
        ? InstancedBufferGeometry()
        : BufferGeometry();

    final index = json["data"]["index"];

    if (index != null) {
      final typedArray = getTypedArray(index["type"], index["array"]);
      geometry.setIndex(getTypedAttribute(typedArray, 1, false));
    }

    final attributes = json["data"]["attributes"];

    for (final key in attributes.keys) {
      final attribute = attributes[key];
      BaseBufferAttribute bufferAttribute;

      if (attribute["isInterleavedBufferAttribute"] == true) {
        final interleavedBuffer =
            getInterleavedBuffer(json["data"], attribute["data"]);
        bufferAttribute = InterleavedBufferAttribute(
            interleavedBuffer,
            attribute["itemSize"],
            attribute["offset"],
            attribute["normalized"]);
      } else {
        final typedArray = getTypedArray(attribute["type"], attribute["array"]);
        // final bufferAttributeConstr = attribute.isInstancedBufferAttribute ? InstancedBufferAttribute : BufferAttribute;
        if (attribute["isInstancedBufferAttribute"] == true) {
          bufferAttribute = InstancedBufferAttribute(
              typedArray, attribute["itemSize"], attribute["normalized"]);
        } else {
          bufferAttribute = getTypedAttribute(typedArray, attribute["itemSize"],attribute["normalized"] == true);
        }
      }

      if (attribute["name"] != null) bufferAttribute.name = attribute["name"];
      if (attribute["usage"] != null) {
        if (bufferAttribute is InstancedBufferAttribute) {
          bufferAttribute.setUsage(attribute["usage"]);
        }
      }

      if (attribute["updateRange"] != null) {
        if (bufferAttribute is InterleavedBufferAttribute) {
          bufferAttribute.updateRange?['offset'] =
              attribute["updateRange"]["offset"];
          bufferAttribute.updateRange?['count'] =
              attribute["updateRange"]["count"];
        }
      }

      geometry.setAttribute(key, bufferAttribute);
    }

    final morphAttributes = json["data"]["morphAttributes"];

    if (morphAttributes != null) {
      for (final key in morphAttributes.keys) {
        final attributeArray = morphAttributes[key];

        final array = <BufferAttribute>[];

        for (int i = 0, il = attributeArray.length; i < il; i++) {
          final attribute = attributeArray[i];
          BufferAttribute bufferAttribute;

          if (attribute is InterleavedBufferAttribute) {
            final interleavedBuffer = getInterleavedBuffer(json["data"], attribute.data);
            bufferAttribute = InterleavedBufferAttribute(interleavedBuffer, attribute.itemSize, attribute.offset, attribute.normalized);
          } else {
            final typedArray = getTypedArray(attribute.type, attribute.array);
            bufferAttribute = getTypedAttribute(typedArray, attribute.itemSize, attribute.normalized);
          }

          if (attribute.name != null) bufferAttribute.name = attribute.name;
          array.add(bufferAttribute);
        }

        geometry.morphAttributes[key] = array;
      }
    }

    final morphTargetsRelative = json["data"]["morphTargetsRelative"];

    if (morphTargetsRelative == true) {
      geometry.morphTargetsRelative = true;
    }

    final groups = json["data"]["groups"] ??
        json["data"]["drawcalls"] ??
        json["data"]["offsets"];

    if (groups != null) {
      for (int i = 0, n = groups.length; i != n; ++i) {
        final group = groups[i];

        geometry.addGroup(
            group["start"], group["count"], group["materialIndex"]);
      }
    }

    final boundingSphere = json["data"]["boundingSphere"];

    if (boundingSphere != null) {
      final center = Vector3(0, 0, 0);

      if (boundingSphere["center"] != null) {
        center.copyFromArray(boundingSphere["center"]);
      }

      geometry.boundingSphere = BoundingSphere(center, boundingSphere["radius"]);
    }

    if (json["name"] != null) geometry.name = json["name"];
    if (json["userData"] != null) geometry.userData = json["userData"];

    return geometry;
  }
}

NativeArray getTypedArray(String type, List buffer) {
  if (type == "Uint32Array" || type == "Uint32List") {
    return Uint32Array.from(List<int>.from(buffer));
  } else if (type == "Uint16Array" || type == "Uint16List") {
    return Uint16Array.from(List<int>.from(buffer));
  } else if (type == "Float32Array" || type == "Float32List") {
    return Float32Array.from(List<double>.from(buffer));
  } else {
    throw (" Util.dart getTypedArray type: $type is not support ");
  }
}

BufferAttribute getTypedAttribute(NativeArray array, int itemSize,
    [bool normalized = false]) {
  if (array is Uint32Array) {
    return Uint32BufferAttribute(array, itemSize, normalized);
  } else if (array is Uint16Array) {
    return Uint16BufferAttribute(array, itemSize, normalized);
  } else if (array is Float32Array) {
    return Float32BufferAttribute(array, itemSize, normalized);
  } else {
    throw (" Util.dart getTypedArray type: ${array.runtimeType} is not support ");
  }
}
