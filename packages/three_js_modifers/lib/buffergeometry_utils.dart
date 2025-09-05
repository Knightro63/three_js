import 'dart:math' as math;

import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';

class BufferGeometryUtils{
  static BufferGeometry mergeVertices(BufferGeometry geometry, [double tolerance = 1e-4] ) {
    tolerance = math.max( tolerance, MathUtils.epsilon );

    // Generate an index buffer if the geometry doesn't have one, or optimize it
    // if it's already available.
    final hashToIndex = {};
    final indices = geometry.getIndex();
    final positions = geometry.getAttributeFromString( 'position' );
    final vertexCount = indices != null? indices.count : positions.count;

    // next value for triangle indices
    int nextIndex = 0;

    // attributes and attribute arrays
    final attributeNames = geometry.attributes.keys.toList();
    final tmpAttributes = {};
    final tmpMorphAttributes = {};
    final newIndices = [];
    final getters = [ 'getX', 'getY', 'getZ', 'getW' ];
    final setters = [ 'setX', 'setY', 'setZ', 'setW' ];

    // Initialize the arrays, allocating space conservatively. Extra
    // space will be trimmed in the last step.
    for (int i = 0, l = attributeNames.length; i < l; i ++ ) {
      final name = attributeNames[ i ];
      final attr = geometry.attributes[ name ];
      tmpAttributes[ name ] = Float32BufferAttribute(
        Float32Array( attr.count * attr.itemSize ),
        attr.itemSize,
        attr.normalized
      );

      final morphAttributes = geometry.morphAttributes[ name ];
      if ( morphAttributes != null) {
        if ( ! tmpMorphAttributes[ name ] ) tmpMorphAttributes[ name ] = [];
        int j = 0;
        morphAttributes.forEach( ( morphAttr){
        final array = Float32Array(morphAttr.count * morphAttr.itemSize);//morphAttr.array.constructor( morphAttr.count * morphAttr.itemSize );
          tmpMorphAttributes[ name ][ j ] = Float32BufferAttribute(array, morphAttr.itemSize, morphAttr.normalized);//morphAttr.constructor( array, morphAttr.itemSize, morphAttr.normalized );
          j++;
        } );
      }
    }

    // convert the error tolerance to an amount of decimal places to truncate to
    final halfTolerance = tolerance * 0.5;
    final exponent = math.log( 1 / tolerance )/math.ln10;
    final hashMultiplier = math.pow( 10, exponent );
    final hashAdditive = halfTolerance * hashMultiplier;
    for (int i = 0; i < vertexCount; i ++ ) {
      final int index = indices != null? indices.getX( i )!.toInt() : i;

      // Generate a hash for the vertex attributes at the current index 'i'
      String hash = '';
      for (int j = 0, l = attributeNames.length; j < l; j ++ ) {
        final name = attributeNames[ j ];
        final attribute = geometry.getAttributeFromString( name );
        final itemSize = attribute.itemSize;
        for (int k = 0; k < itemSize; k ++ ) {
          // double tilde truncates the decimal value
          hash += '${( attribute.getFrom(getters[ k ], index )! * hashMultiplier + hashAdditive).truncate() },';        }
      }

      // Add another reference to the vertex if it's already
      // used by another index
      if (hashToIndex.containsKey(hash)) {
        newIndices.add( hashToIndex[ hash ] );
      }
      else {
        // copy data to the index in the temporary attributes
        for (int j = 0, l = attributeNames.length; j < l; j ++ ) {
          final name = attributeNames[ j ];
          final attribute = geometry.getAttributeFromString( name );
          final morphAttr = geometry.morphAttributes[ name ];
          final itemSize = attribute.itemSize;
          final newarray = tmpAttributes[ name ];
          final newMorphArrays = tmpMorphAttributes[ name ];

          for (int k = 0; k < itemSize; k ++ ) {

            final getterFunc = getters[ k ];
            final setterFunc = setters[ k ];
            newarray.setFrom( setterFunc, nextIndex, attribute.getFrom(getterFunc, index ) );

            if ( morphAttr != null) {
              for (int m = 0, ml = morphAttr.length; m < ml; m ++ ) {
                newMorphArrays[ m ][ setterFunc ]( nextIndex, morphAttr[ m ].getFrom(getterFunc, index ) );
              }
            }
          }
        }

        hashToIndex[ hash ] = nextIndex;
        newIndices.add( nextIndex );
        nextIndex ++;
      }
    }

    // generate result BufferGeometry
    final result = geometry.clone();
    for ( final name in geometry.attributes.keys ) {

      final tmpAttribute = tmpAttributes[ name ];

      result.setAttributeFromString( name, Float32BufferAttribute.fromList(
        tmpAttribute.array.sublist( 0, nextIndex * tmpAttribute.itemSize ),
        tmpAttribute.itemSize,
        tmpAttribute.normalized,
      ) );

      if (!tmpMorphAttributes.containsKey(name)) continue;

      for (int j = 0; j < tmpMorphAttributes[ name ].length; j ++ ) {
        final tmpMorphAttribute = tmpMorphAttributes[ name ][ j ];

        result.morphAttributes[ name ]![ j ] = Float32BufferAttribute.fromList(
          tmpMorphAttribute.array.sublist( 0, nextIndex * tmpMorphAttribute.itemSize ),
          tmpMorphAttribute.itemSize,
          tmpMorphAttribute.normalized,
        );
      }
    }

    result.setIndex( newIndices );
    return result;
  }

  /// Method to merge multiple [BufferGeometry] objects into a single geometry.
  ///
  /// All geometries must have:
  /// - The same set of attributes (e.g., `position`, `normal`, `uv`).
  /// - The same set of morph attributes (if any).
  /// - The same indexing type (either all indexed or all non-indexed).
  /// - The same `morphTargetsRelative` flag.
  ///
  /// If [useGroups] is `true`, the resulting geometry will contain groups
  /// corresponding to each input geometry. This is useful for assigning
  /// different materials to different parts of the merged geometry.
  ///
  /// Returns:
  /// - A new merged [BufferGeometry] if successful.
  /// - `null` if the geometries are incompatible or merging fails.
  static BufferGeometry? mergeGeometries(List<BufferGeometry> geometries,
      [bool useGroups = false]) {
    if (geometries.isEmpty) return null;

    // Check if the first geometry is indexed
    final bool isIndexed = geometries[0].getIndex() != null;

    // Store the set of attribute names and morph attribute names from the first geometry
    final attributesUsed = Set<String>.from(geometries[0].attributes.keys);
    final morphAttributesUsed =
        Set<String>.from(geometries[0].morphAttributes.keys);

    // Maps to collect attributes and morph attributes from all geometries
    final Map<String, List<BufferAttribute>> attributes = {};
    final Map<String, List<List<BufferAttribute>>> morphAttributes = {};

    // All geometries must have the same morphTargetsRelative flag
    final bool morphTargetsRelative = geometries[0].morphTargetsRelative;
    final mergedGeometry = BufferGeometry();

    int offset = 0;

    // --- Iterate over all geometries ---
    for (int i = 0; i < geometries.length; i++) {
      final geometry = geometries[i];
      int attributesCount = 0;

      // Ensure all geometries are either indexed or non-indexed
      if (isIndexed != (geometry.getIndex() != null)) return null;

      // Collect attributes
      for (final name in geometry.attributes.keys) {
        if (!attributesUsed.contains(name)) return null;

        attributes.putIfAbsent(name, () => []);
        attributes[name]!.add(geometry.getAttributeFromString(name));
        attributesCount++;
      }

      if (attributesCount != attributesUsed.length) return null;

      // Collect morph attributes
      if (morphTargetsRelative != geometry.morphTargetsRelative) return null;

      for (final name in geometry.morphAttributes.keys) {
        if (!morphAttributesUsed.contains(name)) return null;

        morphAttributes.putIfAbsent(name, () => []);
        morphAttributes[name]!.add(geometry.morphAttributes[name]!);
      }

      // Add groups if requested
      if (useGroups) {
        int count;
        if (isIndexed) {
          count = geometry.getIndex()!.count;
        } else if (geometry.getAttributeFromString('position') != null) {
          count = geometry.getAttributeFromString('position').count;
        } else {
          return null;
        }
        mergedGeometry.addGroup(offset, count, i);
        offset += count;
      }
    }

    // --- Merge indices ---
    if (isIndexed) {
      int indexOffset = 0;
      final List<int> mergedIndex = [];
      for (final geometry in geometries) {
        final index = geometry.getIndex()!;
        for (int j = 0; j < index.count; j++) {
          mergedIndex.add(index.getX(j)!.toInt() + indexOffset);
        }
        indexOffset =
            (indexOffset + geometry.getAttributeFromString('position').count)
                .toInt();
      }
      mergedGeometry.setIndex(mergedIndex);
    }

    // --- Merge attributes --
    for (final name in attributes.keys) {
      final mergedAttribute = _mergeAttributes(attributes[name]!);
      if (mergedAttribute == null) return null;

      mergedGeometry.setAttributeFromString(name, mergedAttribute);
    }

    // --- Merge morph attributes ---
    for (final name in morphAttributes.keys) {
      final numMorphTargets = morphAttributes[name]![0].length;
      if (numMorphTargets == 0) continue;

      mergedGeometry.morphAttributes[name] = [];

      for (int i = 0; i < numMorphTargets; i++) {
        final morphToMerge = <BufferAttribute>[];
        for (int j = 0; j < morphAttributes[name]!.length; j++) {
          morphToMerge.add(morphAttributes[name]![j][i]);
        }
        final mergedMorph = _mergeAttributes(morphToMerge);
        if (mergedMorph == null) return null;

        mergedGeometry.morphAttributes[name]!.add(mergedMorph);
      }
    }

    return mergedGeometry;
  }

  /// Merges a list of [BufferAttribute] objects into a single attribute.
  ///
  /// Requirements:
  /// - All attributes must have the same [itemSize] and [normalized] flag.
  ///
  /// Returns:
  /// - A new [BufferAttribute] containing all merged data.
  /// - `null` if attributes are incompatible.
  static BufferAttribute? _mergeAttributes(List<BufferAttribute> attributes) {
    if (attributes.isEmpty) return null;

    final itemSize = attributes[0].itemSize;
    final normalized = attributes[0].normalized;

    int count = 0;
    for (final attr in attributes) {
      if (attr.itemSize != itemSize || attr.normalized != normalized) {
        return null;
      }
      count += attr.count;
    }

    // Create a new array to hold all merged attribute data
    final array = Float32Array(count * itemSize);

    int offset = 0;
    for (final attr in attributes) {
      final Float32Array srcArray = attr.array as Float32Array;
      array.set(srcArray.toDartList(), offset);
      offset += srcArray.length;
    }
    return Float32BufferAttribute(array, itemSize, normalized);
  }
}