import 'dart:typed_data';

import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';

class BufferGeometryUtils {

  /// Merges a set of geometries into a single instance. 
  /// All geometries must have compatible attributes.
  static BufferGeometry? mergeGeometries(
    List<BufferGeometry> geometries, [
    bool useGroups = false,
  ]) {
    if (geometries.isEmpty) return null;

    final bool isIndexed = geometries[0].index != null;
    final Set<String> attributesUsed = Set<String>.from(geometries[0].attributes.keys);
    final Set<String> morphAttributesUsed = Set<String>.from(geometries[0].morphAttributes.keys);
    
    final Map<String, List<BufferAttribute>> attributes = {};
    final Map<String, List<List<BufferAttribute>>> morphAttributes = {};
    
    final bool? morphTargetsRelative = geometries[0].morphTargetsRelative;
    final BufferGeometry mergedGeometry = BufferGeometry();
    
    int offset = 0;

    for (int i = 0; i < geometries.length; ++i) {
      final BufferGeometry geometry = geometries[i];
      int attributesCount = 0;

      // Ensure that all geometries are indexed, or none
      if (isIndexed != (geometry.index != null)) {
        console.verbose(
          'THREE.BufferGeometryUtils: .mergeGeometries() failed with geometry at index $i. '
          'All geometries must have compatible attributes; make sure index attribute exists among all geometries, or in none of them.'
        );
        return null;
      }

      // Gather attributes, exit early if they're different
      for (final String name in geometry.attributes.keys) {
        if (!attributesUsed.contains(name)) {
          console.verbose(
            'THREE.BufferGeometryUtils: .mergeGeometries() failed with geometry at index $i. '
            'All geometries must have compatible attributes; make sure "$name" attribute exists among all geometries, or in none of them.',
          );
          return null;
        }
        
        attributes.putIfAbsent(name, () => []).add(geometry.attributes[name]!);
        attributesCount++;
      }

      // Ensure geometries have the same number of attributes
      if (attributesCount != attributesUsed.length) {
        console.verbose(
          'THREE.BufferGeometryUtils: .mergeGeometries() failed with geometry at index $i. '
          'Make sure all geometries have the same number of attributes.',
        );
        return null;
      }

      // Gather morph attributes, exit early if they're different
      if (morphTargetsRelative != geometry.morphTargetsRelative) {
        console.verbose(
          'THREE.BufferGeometryUtils: .mergeGeometries() failed with geometry at index $i. '
          '.morphTargetsRelative must be consistent throughout all geometries.',
        );
        return null;
      }

      for (final String name in geometry.morphAttributes.keys) {
        if (!morphAttributesUsed.contains(name)) {
          console.verbose(
            'THREE.BufferGeometryUtils: .mergeGeometries() failed with geometry at index $i. '
            '.morphAttributes must be consistent throughout all geometries.',
          );
          return null;
        }
        
        morphAttributes.putIfAbsent(name, () => []).add(List<BufferAttribute>.from(geometry.morphAttributes[name]!));
      }

      if (useGroups) {
        int count;
        if (isIndexed) {
          count = geometry.index!.count;
        } else if (geometry.attributes['position'] != null) {
          count = geometry.attributes['position']!.count;
        } else {
          console.verbose(
            'THREE.BufferGeometryUtils: .mergeGeometries() failed with geometry at index $i. '
            'The geometry must have either an index or a position attribute',
          );
          return null;
        }

        mergedGeometry.addGroup(offset, count, i);
        offset += count;
      }
    }

    // Merge indices
    if (isIndexed) {
      int indexOffset = 0;
      final List<int> mergedIndex = [];
      
      for (int i = 0; i < geometries.length; ++i) {
        final BufferAttribute index = geometries[i].index!;
        for (int j = 0; j < index.count; ++j) {
          // index.getX(j) typically returns a num; casting to int is required for index arrays
          final num? val = index.getX(j);
          if (val != null) {
            mergedIndex.add(val.toInt() + indexOffset);
          }
        }
        final BufferAttribute? posAttr = geometries[i].attributes['position'];
        if (posAttr != null) {
          indexOffset += posAttr.count;
        }
      }
      mergedGeometry.setIndex(mergedIndex);
    }

    // Merge attributes
    for (final String name in attributes.keys) {
      final BufferAttribute? mergedAttribute = mergeAttributes(attributes[name]!);
      if (mergedAttribute == null) {
        console.verbose(
          'THREE.BufferGeometryUtils: .mergeGeometries() failed while trying to merge the $name attribute.',
        );
        return null;
      }
      mergedGeometry.setAttributeFromString(name, mergedAttribute);
    }

    // Merge morph attributes
    for (final String name in morphAttributes.keys) {
      final int numMorphTargets = morphAttributes[name]![0].length;
      if (numMorphTargets == 0) continue;

      mergedGeometry.morphAttributes[name] = [];

      for (int i = 0; i < numMorphTargets; ++i) {
        final List<BufferAttribute> morphAttributesToMerge = [];
        for (int j = 0; j < morphAttributes[name]!.length; ++j) {
          morphAttributesToMerge.add(morphAttributes[name]![j][i]);
        }

        final BufferAttribute? mergedMorphAttribute = mergeAttributes(morphAttributesToMerge);
        if (mergedMorphAttribute == null) {
          console.verbose(
            'THREE.BufferGeometryUtils: .mergeGeometries() failed while trying to merge the $name morphAttribute.',
          );
          return null;
        }
        mergedGeometry.morphAttributes[name]!.add(mergedMorphAttribute);
      }
    }

    return mergedGeometry;
  }

  /// Merges a list of BufferAttributes into a single instances.
  /// All attributes must have identical array layouts, structural item sizes, and metadata.
  static BufferAttribute? mergeAttributes(List<BufferAttribute> attributes) {
    if (attributes.isEmpty) return null;

    dynamic sampleArray = attributes[0].array;
    Type? arrayType = sampleArray?.runtimeType;
    
    int? itemSize;
    bool? normalized;
    int gpuType = -1;
    int arrayLength = 0;

    // 1. Validation and Size Tracking Pass
    for (int i = 0; i < attributes.length; ++i) {
      final BufferAttribute attribute = attributes[i];

      if (arrayType != attribute.array.runtimeType) {
        console.verbose(
          'THREE.BufferGeometryUtils: .mergeAttributes() failed. '
          'BufferAttribute.array must be of consistent array types across matching attributes.',
        );
        return null;
      }

      itemSize ??= attribute.itemSize;
      if (itemSize != attribute.itemSize) {
        console.verbose(
          'THREE.BufferGeometryUtils: .mergeAttributes() failed. '
          'BufferAttribute.itemSize must be consistent across matching attributes.',

        );
        return null;
      }

      normalized ??= attribute.normalized;
      if (normalized != attribute.normalized) {
        console.verbose(
          'THREE.BufferGeometryUtils: .mergeAttributes() failed. '
          'BufferAttribute.normalized must be consistent across matching attributes.',

        );
        return null;
      }

      if (gpuType == -1) {
        gpuType = attribute.gpuType;
      }
      if (gpuType != attribute.gpuType) {
        console.verbose(
          'THREE.BufferGeometryUtils: .mergeAttributes() failed. '
          'BufferAttribute.gpuType must be consistent across matching attributes.',

        );
        return null;
      }

      arrayLength += attribute.count * itemSize;
    }
  
    // 2. Allocate the Output Native Type Array Container
    late final BufferAttribute result;
    dynamic mergedArray;

    if (sampleArray is Float32List) {
      mergedArray = Float32List(arrayLength);
      result = Float32BufferAttribute.fromList(mergedArray, itemSize!, normalized!);
    } else if (sampleArray is Int32List) {
      mergedArray = Int32List(arrayLength);
      result = Int32BufferAttribute.fromList(mergedArray, itemSize!, normalized!);
    } else if (sampleArray is Uint32List) {
      mergedArray = Uint32List(arrayLength);
      result = Uint32BufferAttribute(mergedArray, itemSize!, normalized!);
    } else if (sampleArray is Uint16List) {
      mergedArray = Uint16List(arrayLength);
      result = Uint16BufferAttribute(mergedArray, itemSize!, normalized!);
    } else if (sampleArray is Uint8List) {
      mergedArray = Uint8List(arrayLength);
      result = Uint8BufferAttribute(mergedArray, itemSize!, normalized!);
    } else {
      // Fallback default allocation profile strategy
      mergedArray = Float32List(arrayLength);
      result = Float32BufferAttribute(mergedArray, itemSize!, normalized!);
    }

    int offset = 0;

    // 3. Populate Array Buffers
    for (int i = 0; i < attributes.length; ++i) {
      final BufferAttribute attribute = attributes[i];

      // Mirroring standard JS logic wrapper blocks
      // Note: If three_js introduces an explicit 'isInterleavedBufferAttribute' property checker,
      // evaluate it here. Otherwise, direct assignments handle standard layouts cleanly.
      bool isInterleaved = false;
      try {
        isInterleaved = attribute is InterleavedBufferAttribute;
      } catch (_) {}

      if (isInterleaved) {
        final int tupleOffset = offset ~/ itemSize;
        for (int j = 0; j < attribute.count; j++) {
          for (int c = 0; c < itemSize; c++) {
            final double? value = (attribute as InterleavedBufferAttribute).getComponent(j, c);
            if (value != null) {
              (result as InterleavedBufferAttribute).setComponent(j + tupleOffset, c, value);
            }
          }
        }
      } 
      else {
        // Replaces JS array.set(source, targetOffset) with standard typed list slice sets
        final dynamic srcList = attribute.array;
        // In three_js wrapper abstractions, use the underlying list container loops
        for (int k = 0; k < srcList.length; k++) {
          mergedArray[offset + k] = srcList[k];
        }
      }
      
      offset += attribute.count * itemSize;
    }

    if (gpuType != -1) {
      result.gpuType = gpuType;
    }

    return result;
  }
}