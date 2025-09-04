import 'dart:math' as math;
import 'dart:typed_data';
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';

/**
 * Utility class for sampling weighted random points on the surface of a mesh.
 *
 * Building the sampler is a one-time O(n) operation. Once built, any number of
 * random samples may be selected in O(logn) time. Memory usage is O(n).
 *
 * References:
 * - http://www.joesfer.com/?p=84
 * - https://stackoverflow.com/a/4322940/1314762
 */

class MeshSurfaceSampler {
  final _face = Triangle();
  final _color = Vector3();

  late BufferGeometry geometry;

  late Float32BufferAttribute positionAttribute;
  late Float32BufferAttribute? colorAttribute;
  Float32BufferAttribute? weightAttribute;
  Float32List? distribution;
  late double Function() randomFunction;

  MeshSurfaceSampler(Mesh mesh) {
    BufferGeometry? geometry = mesh.geometry;

    if (geometry == null || geometry.attributes['position'].itemSize != 3 ) {
      throw ( 'MeshSurfaceSampler: Requires BufferGeometry triangle mesh.' );
    }

    if ( geometry.index == null ) {
      console.warning( 'MeshSurfaceSampler: Converting geometry to non-indexed BufferGeometry.' );
      geometry = geometry.toNonIndexed();
    }

    this.geometry = geometry;
    randomFunction = math.Random().nextDouble;
    positionAttribute = this.geometry.getAttributeFromString( 'position' );
    colorAttribute = this.geometry.getAttributeFromString( 'color' );
    weightAttribute = null;
    distribution = null;
  }

  MeshSurfaceSampler setWeightAttribute(String? name){
    weightAttribute = name != null?geometry.getAttributeFromString(name):null;
    return this;
  }

  MeshSurfaceSampler build() {
    final positionAttribute = this.positionAttribute;
    final weightAttribute = this.weightAttribute;
    final faceWeights = Float32List( positionAttribute.count ~/ 3 ); // Accumulate weights for each mesh face.

    for ( int i = 0; i < positionAttribute.count; i += 3 ) {
      num faceWeight = 1.0;

      if ( weightAttribute != null ) {
        faceWeight = weightAttribute.getX( i )! + weightAttribute.getX( i + 1 )! + weightAttribute.getX( i + 2 )!;
      }

      if(i < positionAttribute.count) {
        _face.a.fromBuffer( positionAttribute, i );
      }
      
      if(i + 1 < positionAttribute.count) {
        _face.b.fromBuffer( positionAttribute, i + 1 );
      }
      
      if(i + 2 < positionAttribute.count) {
        _face.c.fromBuffer( positionAttribute, i + 2 );
      }

      faceWeight *= _face.getArea();
      faceWeights[ i ~/ 3 ] = faceWeight.toDouble();
    } // Store cumulative total face weights in an array, where weight index
    // corresponds to face index.


    distribution = Float32List( positionAttribute.count ~/ 3 );
    num cumulativeTotal = 0;

    for(int i = 0; i < faceWeights.length; i ++) {
      cumulativeTotal += faceWeights[ i ];
      distribution![ i ] = cumulativeTotal.toDouble();
    }

    return this;
  }

  MeshSurfaceSampler setRandomGenerator( randomFunction ) {
    this.randomFunction = randomFunction;
    return this;
  }

  MeshSurfaceSampler sample(Vector3 targetPosition,[Vector3? targetNormal,Color? targetColor ]) {
    final cumulativeTotal = distribution![distribution!.length - 1 ];
    final faceIndex = binarySearch( randomFunction() * cumulativeTotal );
    return sampleFace( faceIndex, targetPosition, targetNormal, targetColor );
  }

  int binarySearch( x ) {
    final dist = distribution;
    int start = 0;
    int end = dist!.length - 1;
    int index = - 1;

    while(start <= end){
      final mid = ( ( start + end ) / 2 ).ceil();

      if ( mid == 0 || dist[ mid - 1 ] <= x && dist[ mid ] > x ) {
        index = mid;
        break;
      }
      else if ( x < dist[ mid ] ) {
        end = mid - 1;
      } 
      else {
        start = mid + 1;
      }
    }

    return index;
  }

  MeshSurfaceSampler sampleFace(int faceIndex,Vector3 targetPosition,[Vector3? targetNormal,Color? targetColor ]) {
    double u = randomFunction();
    double v = randomFunction();

    if ( u + v > 1 ) {
      u = 1 - u;
      v = 1 - v;
    }

    _face.a.fromBuffer( positionAttribute, faceIndex * 3 );
    _face.b.fromBuffer( positionAttribute, faceIndex * 3 + 1 );
    _face.c.fromBuffer( positionAttribute, faceIndex * 3 + 2 );

    targetPosition.setValues( 0, 0, 0 ).addScaled( _face.a, u ).addScaled( _face.b, v ).addScaled( _face.c, 1 - ( u + v ) );

    if ( targetNormal != null ) {
      _face.getNormal( targetNormal );
    }

    if ( targetColor != null && colorAttribute != null ) {
      _face.a.fromBuffer( colorAttribute!, faceIndex * 3 );
      _face.b.fromBuffer( colorAttribute!, faceIndex * 3 + 1 );
      _face.c.fromBuffer( colorAttribute!, faceIndex * 3 + 2 );

      _color.setValues( 0, 0, 0 ).addScaled( _face.a, u ).addScaled( _face.b, v ).addScaled( _face.c, 1 - ( u + v ) );

      targetColor.red = _color.x;
      targetColor.green = _color.y;
      targetColor.blue = _color.z;
    }

    return this;
  }
}

