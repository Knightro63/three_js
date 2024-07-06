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

      final morphAttr = geometry.morphAttributes[ name ];
      if ( morphAttr != null) {
        // tmpMorphAttributes[ name ] = Float32BufferAttribute(
        //   Float32Array( morphAttr.count * morphAttr.itemSize ),
        //   morphAttr.itemSize,
        //   morphAttr.normalized
        // );
      }
    }

    // convert the error tolerance to an amount of decimal places to truncate to
    final halfTolerance = tolerance * 0.5;
    final exponent = math.log( 1 / tolerance );
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
          hash += '${( attribute.getFrom(getters[ k ], index )! * hashMultiplier + hashAdditive ).floor() },';
        }
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
}