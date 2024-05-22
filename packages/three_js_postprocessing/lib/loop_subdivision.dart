/**
 * @description Loop Subdivision Surface
 * @about       Smooth subdivision surface modifier for use with three.js BufferGeometry.
 * @author      Stephens Nunnally <@stevinz>
 * @license     MIT - Copyright (c) 2022 Stephens Nunnally
 * @source      https://github.com/stevinz/three-subdivide
 */
/////////////////////////////////////////////////////////////////////////////////////
//
//  Functions
//      modify              Applies Loop subdivision to BufferGeometry, returns BufferGeometry
//      edgeSplit           Splits all triangles at edges shared by coplanar triangles
//      flat                One iteration of Loop subdivision, without point averaging
//      smooth              One iteration of Loop subdivision, with point averaging
//
//  Info
//      This modifier uses the Loop (Charles Loop, 1987) subdivision surface algorithm to smooth
//      modern three.js BufferGeometry.
//
//      At one point, three.js included a subdivision surface modifier in the extended examples (see bottom
//      of file for links), it was removed in r125. The modifier was originally based on the Catmull-Clark
//      algorithm, which works best for geometry with convex coplanar n-gon faces. In three.js r60 the modifier
//      was changed to utilize the Loop algorithm. The Loop algorithm was designed to work better with triangle
//      based meshes.
//
//      The Loop algorithm, however, doesn't always provide uniform results as the vertices are
//      skewed toward the most used vertex positions. A triangle based box (e.g. BoxGeometry for example) will
//      tend to favor the corners. To alleviate this issue, this implementation includes an initial pass to split
//      coplanar faces at their shared edges. It starts by splitting along the longest shared edge first, and then
//      from that midpoint it splits to any remaining coplanar shared edges.
//
//      Also by default, this implementation inserts uv coordinates, but does not average them using the Loop
//      algorithm. In some cases (often in flat geometries) this will produce undesired results, a
//      noticeable tearing will occur. In such cases, try passing 'uvSmooth' as true to enable uv averaging.
//
//  Note(s)
//      - This modifier returns a BufferGeometry instance, it does not dispose() of the old geometry.
//
//      - This modifier returns a NonIndexed geometry. An Indexed geometry can be created by using the
//        BufferGeometryUtils.mergeVertices() function, see:
//        https://threejs.org/docs/?q=buffer#examples/en/utils/BufferGeometryUtils.mergeVertices
//
//      - This modifier works best with geometry whose triangles share edges AND edge vertices. See diagram below.
//
//          OKAY          NOT OKAY
//            O              O
//           /|\            / \
//          / | \          /   \
//         /  |  \        /     \
//        O---O---O      O---O---O
//         \  |  /        \  |  /
//          \ | /          \ | /
//           \|/            \|/
//            O              O
//
//  Reference(s)
//      - Subdivision Surfaces
//          https://www.microsoft.com/en-us/research/wp-content/uploads/2016/02/thesis-10.pdf
//          https://en.wikipedia.org/wiki/Loop_subdivision_surface
//          https://cseweb.ucsd.edu/~alchern/teaching/cse167_fa21/6-3Surfaces.pdf
//
//      - Original three.js SubdivisionModifier, r124 (Loop)
//          https://github.com/mrdoob/three.js/blob/r124/examples/jsm/modifiers/SubdivisionModifier.js
//
//      - Original three.js SubdivisionModifier, r59 (Catmull-Clark)
//          https://github.com/mrdoob/three.js/blob/r59/examples/js/modifiers/SubdivisionModifier.js
//
/////////////////////////////////////////////////////////////////////////////////////

import "package:three_js_core/three_js_core.dart";
import "package:three_js_math/buffer/buffer_attribute.dart";
import "package:three_js_math/buffer/index.dart";
import "package:three_js_math/three_js_math.dart";
import 'dart:math' as math;


///// Constants

const POSITION_DECIMALS = 2;

///// Local Variables

final _average = Vector3.zero();
final _center = Vector3.zero();
final _midpoint = Vector3.zero();
final _normal = Vector3.zero();
final _temp = Vector3.zero();

final _vector0 = Vector3.zero(); // .Vector4();
final _vector1 = Vector3.zero(); // .Vector4();
final _vector2 = Vector3.zero(); // .Vector4();
final _vec0to1 = Vector3.zero();
final _vec1to2 = Vector3.zero();
final _vec2to0 = Vector3.zero();

final _position = [
    Vector3.zero(),
    Vector3.zero(),
    Vector3.zero(),
];

final _vertex = [
    Vector3.zero(),
    Vector3.zero(),
    Vector3.zero(),
];

final _triangle = Triangle();

class LoopParameters{
  LoopParameters({
    this.split = true,
    this.uvSmooth = false,
    this.preserveEdges = false,
    this.flatOnly = false,
    int? maxTriangles,
    this.weight = 1
  }){
    this.maxTriangles = maxTriangles ?? double.maxFinite.toInt();
  }

  LoopParameters.fromJson(Map<String,dynamic> json){
    split = json['split'] ?? true;
    uvSmooth = json['uvSmooth'] ?? false;
    preserveEdges = json['preserveEdges'] ?? false;
    flatOnly = json['flatOnly'] ?? false;
    maxTriangles = json['maxTriangles'] ?? double.maxFinite.toInt();
    weight = json['weight'] ?? 1;
  }

  late bool split;
  late bool uvSmooth;
  late bool preserveEdges;
  late bool flatOnly;
  late int maxTriangles;
  late double weight;
}

/////////////////////////////////////////////////////////////////////////////////////
/////   Loop Subdivision Surface
/////////////////////////////////////////////////////////////////////////////////////

/** Loop subdivision surface modifier for use with modern three.js BufferGeometry */
class LoopSubdivision {
  /**
   * Applies Loop subdivision modifier to geometry
   *
   * @param {Object} bufferGeometry - Three.js geometry to be subdivided
   * @param {Number} iterations - How many times to run subdividion
   * @param {Object} params - Optional parameters object, see below
   * @returns {Object} Returns new, subdivided, three.js BufferGeometry object
   *
   * Optional Parameters Object
   * @param {Boolean} split - Should coplanar faces be divided along shared edges before running Loop subdivision?
   * @param {Boolean} uvSmooth - Should UV values be averaged during subdivision?
   * @param {Boolean} preserveEdges - Should edges / breaks in geometry be ignored during subdivision?
   * @param {Boolean} flatOnly - If true, subdivision generates triangles, but does not modify positions
   * @param {Number} maxTriangles - If geometry contains more than this many triangles, subdivision will not continue
   * @param {Number} weight - How much to weigh favoring heavy corners vs favoring Loop's formula
   */
  static modify(BufferGeometry bufferGeometry, [int iterations = 1, LoopParameters? params]) {
    params ??= LoopParameters();
    ///// Parameters
    params.weight = math.max(0, (math.min(1, params.weight)));

    ///// Geometries
    if (! verifyGeometry(bufferGeometry)) return bufferGeometry;
    BufferGeometry modifiedGeometry = bufferGeometry.clone();

    ///// Presplit
    if (params.split) {
      final splitGeometry = LoopSubdivision.edgeSplit(modifiedGeometry);
      modifiedGeometry.dispose();
      modifiedGeometry = splitGeometry;
    }

    ///// Apply Subdivision
    for (int i = 0; i < iterations; i++) {
      int currentTriangles = modifiedGeometry.attributes['position'].count ~/ 3;
      if (currentTriangles < params.maxTriangles) {
        BufferGeometry subdividedGeometry;

        // Subdivide
        if (params.flatOnly) {
          subdividedGeometry = LoopSubdivision.flat(modifiedGeometry, params);
        } else {
          subdividedGeometry = LoopSubdivision.smooth(modifiedGeometry, params);
        }

        // Copy and Resize Groups
        modifiedGeometry.groups.forEach((group){
          subdividedGeometry.addGroup(group['start'] * 4, group['count'] * 4, group['materialIndex']);
        });

        // Clean Up
        modifiedGeometry.dispose();
        modifiedGeometry = subdividedGeometry;
      }
    }

    ///// Return New Geometry
    return modifiedGeometry;
  }

    /////////////////////////////////////////////////////////////////////////////////////
    /////   Split Hypotenuse
    ////////////////////

    /**
     * Applies one iteration of split subdivision. Splits all triangles at edges shared by coplanar triangles.
     * Starts by splitting at longest shared edge, followed by splitting from that center edge point to the
     * center of any other shared edges.
     */
    static edgeSplit(geometry) {

        ///// Geometries
        if (! verifyGeometry(geometry)) return geometry;
        final existing = (geometry.index != null) ? geometry.toNonIndexed() : geometry.clone();
        final split = BufferGeometry();

        ///// Attributes
        final attributeList = gatherAttributes(existing);
        final vertexCount = existing.attributes['position'].count;
        final posAttribute = existing.getAttributeFromString('position');
        final norAttribute = existing.getAttributeFromString('normal');
        final edgeHashToTriangle = {};
        final triangleEdgeHashes = [];
        final edgeLength = {};
        final triangleExist = [];

        ///// Edges
        for (int i = 0; i < vertexCount; i += 3) {

            // Positions
            _vector0.fromBuffer(posAttribute, i + 0);
            _vector1.fromBuffer(posAttribute, i + 1);
            _vector2.fromBuffer(posAttribute, i + 2);
            _normal.fromBuffer(norAttribute, i);
            final vecHash0 = hashFromVector(_vector0);
            final vecHash1 = hashFromVector(_vector1);
            final vecHash2 = hashFromVector(_vector2);

            // Verify Area
            final triangleSize = _triangle.set(_vector0, _vector1, _vector2).getArea();
            triangleExist.add(! fuzzy(triangleSize, 0));
            if (! triangleExist[i ~/ 3]) {
                triangleEdgeHashes.add([]);
                continue;
            }

            // Calculate Normals
            calcNormal(_normal, _vector0, _vector1, _vector2);
            final normalHash = hashFromVector(_normal);

            // Vertex Hashes
            final hashes = [
                '${vecHash0}_${vecHash1}_$normalHash', // [0]: 0to1
                '${vecHash1}_${vecHash0}_$normalHash', // [1]: 1to0
                '${vecHash1}_${vecHash2}_$normalHash', // [2]: 1to2
                '${vecHash2}_${vecHash1}_$normalHash', // [3]: 2to1
                '${vecHash2}_${vecHash0}_$normalHash', // [4]: 2to0
                '${vecHash0}_${vecHash2}_$normalHash', // [5]: 0to2
            ];

            // Store Edge Hashes
            final index = i / 3;
            for (int j = 0; j < hashes.length; j++) {
                // Attach Triangle Index to Edge Hash
                if (edgeHashToTriangle[hashes[j]] == null) edgeHashToTriangle[hashes[j]] = [];
                edgeHashToTriangle[hashes[j]].add(index);

                // Edge Length
                if (edgeLength[hashes[j]] == null) {
                    if (j == 0 || j == 1) edgeLength[hashes[j]] = _vector0.distanceTo(_vector1);
                    if (j == 2 || j == 3) edgeLength[hashes[j]] = _vector1.distanceTo(_vector2);
                    if (j == 4 || j == 5) edgeLength[hashes[j]] = _vector2.distanceTo(_vector0);
                }
            }

            // Triangle Edge Reference
            triangleEdgeHashes.add([ hashes[0], hashes[2], hashes[4] ]);
        }

        // Loop Subdivide Function
        List<double> splitAttribute(BufferAttribute attribute, String attributeName, [bool morph = false]) {
            const newTriangles = 4; /* maximum number of triangles */
            final arrayLength = (vertexCount * attribute.itemSize) * newTriangles;
            final List<num> floatArray = List.filled(arrayLength, 0, growable: true);//attribute.array.sublist(0,arrayLength);//.constructor(arrayLength);
            floatArray.replaceRange(0, attribute.array.length, attribute.array.sublist(0));
            final processGroups = (attributeName == 'position' && ! morph && existing.groups.length > 0);
            int? groupStart; 
            int? groupMaterial;

            int index = 0;
            int skipped = 0;
            int step = attribute.itemSize;

            for (int i = 0; i < vertexCount; i += 3) {
                // Verify Triangle is Valid
                if (! triangleExist[i ~/ 3]) {
                    skipped += 3;
                    continue;
                }

                // Get Triangle Points
                _vector0.fromBuffer(attribute, i + 0);
                _vector1.fromBuffer(attribute, i + 1);
                _vector2.fromBuffer(attribute, i + 2);

                // Check for Shared Edges
                final existingIndex = i ~/ 3;
                final edgeHash0to1 = triangleEdgeHashes[existingIndex][0];
                final edgeHash1to2 = triangleEdgeHashes[existingIndex][1];
                final edgeHash2to0 = triangleEdgeHashes[existingIndex][2];

                final edgeCount0to1 = edgeHashToTriangle[edgeHash0to1].length;
                final edgeCount1to2 = edgeHashToTriangle[edgeHash1to2].length;
                final edgeCount2to0 = edgeHashToTriangle[edgeHash2to0].length;
                final sharedCount = (edgeCount0to1 + edgeCount1to2 + edgeCount2to0) - 3;

                // New Index (Before New Triangles, used for Groups)
                final int loopStartIndex = ((index * 3) / step) ~/ 3;

                // No Shared Edges
                if (sharedCount == 0) {
                  setTriangle(floatArray, index, step, _vector0, _vector1, _vector2); 
                  index += (step * 3);
                } 
                else {
                    final length0to1 = edgeLength[edgeHash0to1];
                    final length1to2 = edgeLength[edgeHash1to2];
                    final length2to0 = edgeLength[edgeHash2to0];

                    // Add New Triangle Positions
                    if ((length0to1 > length1to2 || edgeCount1to2 <= 1) &&
                        (length0to1 > length2to0 || edgeCount2to0 <= 1) && edgeCount0to1 > 1) {
                        _center.setFrom(_vector0).add(_vector1).divideScalar(2.0);
                        if (edgeCount2to0 > 1) {
                            _midpoint.setFrom(_vector2).add(_vector0).divideScalar(2.0);
                            setTriangle(floatArray, index, step, _vector0, _center, _midpoint); index += (step * 3);
                            setTriangle(floatArray, index, step, _center, _vector2, _midpoint); index += (step * 3);
                        } else {
                            setTriangle(floatArray, index, step, _vector0, _center, _vector2); index += (step * 3);
                        }
                        if (edgeCount1to2 > 1) {
                            _midpoint.setFrom(_vector1).add(_vector2).divideScalar(2.0);
                            setTriangle(floatArray, index, step, _center, _vector1, _midpoint); index += (step * 3);
                            setTriangle(floatArray, index, step, _midpoint, _vector2, _center); index += (step * 3);
                        } else {
                            setTriangle(floatArray, index, step, _vector1, _vector2, _center); index += (step * 3);
                        }

                    } else if ((length1to2 > length2to0 || edgeCount2to0 <= 1) && edgeCount1to2 > 1) {
                        _center.setFrom(_vector1).add(_vector2).divideScalar(2.0);
                        if (edgeCount0to1 > 1) {
                            _midpoint.setFrom(_vector0).add(_vector1).divideScalar(2.0);
                            setTriangle(floatArray, index, step, _center, _midpoint, _vector1); index += (step * 3);
                            setTriangle(floatArray, index, step, _midpoint, _center, _vector0); index += (step * 3);
                        } else {
                            setTriangle(floatArray, index, step, _vector1, _center, _vector0); index += (step * 3);
                        }
                        if (edgeCount2to0 > 1) {
                            _midpoint.setFrom(_vector2).add(_vector0).divideScalar(2.0);
                            setTriangle(floatArray, index, step, _center, _vector2, _midpoint); index += (step * 3);
                            setTriangle(floatArray, index, step, _midpoint, _vector0, _center); index += (step * 3);
                        } else {
                            setTriangle(floatArray, index, step, _vector2, _vector0, _center); index += (step * 3);
                        }

                    } else if (edgeCount2to0 > 1) {
                        _center.setFrom(_vector2).add(_vector0).divideScalar(2.0);
                        if (edgeCount1to2 > 1) {
                            _midpoint.setFrom(_vector1).add(_vector2).divideScalar(2.0);
                            setTriangle(floatArray, index, step, _vector2, _center, _midpoint); index += (step * 3);
                            setTriangle(floatArray, index, step, _center, _vector1, _midpoint); index += (step * 3);
                        } else {
                            setTriangle(floatArray, index, step, _vector2, _center, _vector1); index += (step * 3);
                        }
                        if (edgeCount0to1 > 1) {
                            _midpoint.setFrom(_vector0).add(_vector1).divideScalar(2.0);
                            setTriangle(floatArray, index, step, _vector0, _midpoint, _center); index += (step * 3);
                            setTriangle(floatArray, index, step, _midpoint, _vector1, _center); index += (step * 3);
                        } else {
                            setTriangle(floatArray, index, step, _vector0, _vector1, _center); index += (step * 3);
                        }

                    } else {
                        setTriangle(floatArray, index, step, _vector0, _vector1, _vector2); index += (step * 3);
                    }
                }

                // Process Groups
                if (processGroups) {
                    existing.groups.forEach((group){
                        if (group['start'] == (i - skipped)) {
                            if (groupStart != null && groupMaterial != null) {
                                split.addGroup(groupStart!, loopStartIndex - groupStart!, groupMaterial!);
                            }
                            groupStart = loopStartIndex;
                            groupMaterial = group['materialIndex'];
                        }
                    });
                }

                // Reset Skipped Triangle Counter
                skipped = 0;
            }

            // Resize Array
            final reducedCount = (index * 3) ~/ step;
            final List<double> reducedArray = List.filled(reducedCount, 0.0);//attribute.array.sublist(0,reducedCount);//.constructor(reducedCount);
            final len = floatArray.length > reducedCount?reducedCount:floatArray.length;
            for (int i = 0; i < len; i++) {
              reducedArray[i] = floatArray[i].toDouble();
            }

            // Final Group
            if (processGroups && groupStart != null && groupMaterial != null) {
                split.addGroup(groupStart!, (((index * 3) / step) ~/ 3) - groupStart!, groupMaterial!);
            }

            return reducedArray;
        }

        ///// Build Geometry, Set Attributes
        attributeList.forEach((attributeName){
            final attribute = existing.getAttributeFromString(attributeName);
            if (attribute == null) return;
            final floatArray = splitAttribute(attribute, attributeName);
            split.setAttributeFromString(attributeName, Float32BufferAttribute.fromList(floatArray, attribute.itemSize));
        });

        ///// Morph Attributes
        final morphAttributes = existing.morphAttributes;
        for (final attributeName in morphAttributes.keys) {
            final List<BufferAttribute> array = [];
            final morphAttribute = morphAttributes[attributeName];

            // Process Array of Float32BufferAttributes
            for (int i = 0, l = morphAttribute.length; i < l; i++) {
                if (morphAttribute[i].count != vertexCount) continue;
                final floatArray = splitAttribute(morphAttribute[i], attributeName, true);
                array.add(Float32BufferAttribute.fromList(floatArray, morphAttribute[i].itemSize));
            }
            split.morphAttributes[attributeName] = array;
        }
        split.morphTargetsRelative = existing.morphTargetsRelative;

        // Clean Up, Return New Geometry
        existing.dispose();
        return split;
    }

  /////////////////////////////////////////////////////////////////////////////////////
  /////   Flat
  ////////////////////

  /** Applies one iteration of Loop (flat) subdivision (1 triangle split into 4 triangles) */
  static flat(BufferGeometry geometry, [LoopParameters? params]) {
    params ??= LoopParameters();

    ///// Geometries
    if (! verifyGeometry(geometry)) return geometry;
    final existing = (geometry.index != null) ? geometry.toNonIndexed() : geometry.clone();
    final loop = BufferGeometry();

    ///// Attributes
    final attributeList = gatherAttributes(existing);
    final vertexCount = existing.attributes['position'].count;

    ///// Build Geometry
    attributeList.forEach((attributeName){
      final attribute = existing.getAttributeFromString(attributeName);
      if (attribute == null) return;
      loop.setAttributeFromString(attributeName, LoopSubdivision.flatAttribute(attribute, vertexCount, params));
    });

    ///// Morph Attributes
    final morphAttributes = existing.morphAttributes;
    for (final attributeName in morphAttributes.keys) {
      final List<BufferAttribute>array = [];
      final morphAttribute = morphAttributes[attributeName]!;

        // Process Array of Float32BufferAttributes
      for (int i = 0, l = morphAttribute.length; i < l; i++) {
        if (morphAttribute[i].count != vertexCount) continue;
        array.add(LoopSubdivision.flatAttribute(morphAttribute[i], vertexCount, params));
      }
      loop.morphAttributes[attributeName] = array;
    }
    loop.morphTargetsRelative = existing.morphTargetsRelative;

    ///// Clean Up
    existing.dispose();
    return loop;
  }

  static BufferAttribute flatAttribute(BufferAttribute attribute, int vertexCount, [LoopParameters? params]) {
    params ??= LoopParameters();
    const newTriangles = 4;
    final arrayLength = (vertexCount * attribute.itemSize) * newTriangles;
    final List<double> floatArray = List.filled(arrayLength, 0.0);//attribute.array.constructor(arrayLength);
    final len = floatArray.length > arrayLength?arrayLength:floatArray.length;
    for (int i = 0; i < len; i++) {
      floatArray[i] = attribute.array[i].toDouble();
    }
    int index = 0;
    int step = attribute.itemSize;
    for (int i = 0; i < vertexCount; i += 3) {
      // Original Vertices
      _vector0.fromBuffer(attribute, i + 0);
      _vector1.fromBuffer(attribute, i + 1);
      _vector2.fromBuffer(attribute, i + 2);

      // Midpoints
      _vec0to1.setFrom(_vector0).add(_vector1).divideScalar(2.0);
      _vec1to2.setFrom(_vector1).add(_vector2).divideScalar(2.0);
      _vec2to0.setFrom(_vector2).add(_vector0).divideScalar(2.0);

      // Add New Triangle Positions
      setTriangle(floatArray, index, step, _vector0, _vec0to1, _vec2to0); 
      index += (step * 3);
      setTriangle(floatArray, index, step, _vector1, _vec1to2, _vec0to1);
      index += (step * 3);
      setTriangle(floatArray, index, step, _vector2, _vec2to0, _vec1to2); 
      index += (step * 3);
      setTriangle(floatArray, index, step, _vec0to1, _vec1to2, _vec2to0); 
      index += (step * 3);
    }

    return Float32BufferAttribute.fromList(floatArray, attribute.itemSize);
  }

    /////////////////////////////////////////////////////////////////////////////////////
    /////   Smooth
    ////////////////////

    /** Applies one iteration of Loop (smooth) subdivision (1 triangle split into 4 triangles) */
    static smooth(geometry, [LoopParameters? params]) {
      params ??= LoopParameters();

      ///// Geometries
      if (! verifyGeometry(geometry)) return geometry;
      final existing = (geometry.index != null) ? geometry.toNonIndexed() : geometry.clone();
      final flat = LoopSubdivision.flat(existing, params);
      final loop = BufferGeometry();

      ///// Attributes
      final attributeList = gatherAttributes(existing);
      final vertexCount = existing.attributes['position'].count;
      final posAttribute = existing.getAttributeFromString('position');
      final flatPosition = flat.getAttributeFromString('position');
      final hashToIndex = {};             // Position hash mapped to index values of same position
      final existingNeighbors = {};       // Position hash mapped to existing vertex neighbors
      final flatOpposites = {};           // Position hash mapped to edge point opposites
      final existingEdges = {};

      void addNeighbor(posHash, neighborHash, index) {
        if (existingNeighbors[posHash] == null) existingNeighbors[posHash] = {};
        if (existingNeighbors[posHash][neighborHash] == null) existingNeighbors[posHash][neighborHash] = [];
        existingNeighbors[posHash][neighborHash].add(index);
      }

      void addOpposite(posHash, index) {
        if (flatOpposites[posHash] == null) flatOpposites[posHash] = [];
        flatOpposites[posHash].add(index);
      }

      void addEdgePoint(posHash, edgeHash) {
        if (existingEdges[posHash] == null) existingEdges[posHash] = [];
        existingEdges[posHash].add(edgeHash);
      }

      ///// Existing Vertex Hashes
      for (int i = 0; i < vertexCount; i += 3) {
        final posHash0 = hashFromVector(_vertex[0].fromBuffer(posAttribute, i + 0));
        final posHash1 = hashFromVector(_vertex[1].fromBuffer(posAttribute, i + 1));
        final posHash2 = hashFromVector(_vertex[2].fromBuffer(posAttribute, i + 2));

        // Neighbors (of Existing Geometry)
        addNeighbor(posHash0, posHash1, i + 1);
        addNeighbor(posHash0, posHash2, i + 2);
        addNeighbor(posHash1, posHash0, i + 0);
        addNeighbor(posHash1, posHash2, i + 2);
        addNeighbor(posHash2, posHash0, i + 0);
        addNeighbor(posHash2, posHash1, i + 1);

        // Opposites (of FlatSubdivided vertices)
        _vec0to1.setFrom(_vertex[0]).add(_vertex[1]).divideScalar(2.0);
        _vec1to2.setFrom(_vertex[1]).add(_vertex[2]).divideScalar(2.0);
        _vec2to0.setFrom(_vertex[2]).add(_vertex[0]).divideScalar(2.0);
        final hash0to1 = hashFromVector(_vec0to1);
        final hash1to2 = hashFromVector(_vec1to2);
        final hash2to0 = hashFromVector(_vec2to0);
        addOpposite(hash0to1, i + 2);
        addOpposite(hash1to2, i + 0);
        addOpposite(hash2to0, i + 1);

        // Track Edges for 'edgePreserve'
        addEdgePoint(posHash0, hash0to1);
        addEdgePoint(posHash0, hash2to0);
        addEdgePoint(posHash1, hash0to1);
        addEdgePoint(posHash1, hash1to2);
        addEdgePoint(posHash2, hash1to2);
        addEdgePoint(posHash2, hash2to0);
      }

      ///// Flat Position to Index Map
      for (int i = 0; i < flat.attributes['position'].count; i++) {
        final posHash = hashFromVector(_temp.fromBuffer(flatPosition, i));
        if (hashToIndex[posHash] == null) hashToIndex[posHash] = [];
        hashToIndex[posHash].add(i);
      }

        List<double> subdivideAttribute(String attributeName, BufferAttribute existingAttribute, BufferAttribute flattenedAttribute) {
          final arrayLength = (flat.attributes['position'].count * flattenedAttribute.itemSize);
          final List<double> floatArray = List.filled(arrayLength, 0.0);//attribute.array.constructor(arrayLength);
          final len = floatArray.length > arrayLength?arrayLength:floatArray.length;
          for (int i = 0; i < len; i++) {
            floatArray[i] = existingAttribute.array[i].toDouble();
          }
          // Process Triangles
          int index = 0;
          for (int i = 0; i < flat.attributes['position'].count; i += 3) {
              // Process Triangle Points
              for (int v = 0; v < 3; v++) {
                if (attributeName == 'uv' && !params!.uvSmooth) {
                  _vertex[v].fromBuffer(flattenedAttribute, i + v);
                } 
                else if (attributeName == 'normal') { // && params.normalSmooth) {
                  _position[v].fromBuffer(flatPosition, i + v);
                  final positionHash = hashFromVector(_position[v]);
                  final positions = hashToIndex[positionHash];

                  final k = positions.length;
                  final beta = 0.75 / k;
                  final startWeight = 1.0 - (beta * k);

                  _vertex[v].fromBuffer(flattenedAttribute, i + v);
                  _vertex[v].scale(startWeight);

                  positions.forEach((positionIndex){
                      _average.fromBuffer(flattenedAttribute, positionIndex);
                      _average.scale(beta);
                      _vertex[v].add(_average);
                  });
                } 
                else { // 'position', 'color', etc...
                  _vertex[v].fromBuffer(flattenedAttribute, i + v);
                  _position[v].fromBuffer(flatPosition, i + v);

                  final positionHash = hashFromVector(_position[v]);
                  final neighbors = existingNeighbors[positionHash];
                  final opposites = flatOpposites[positionHash];

                  ///// Adjust Source Vertex
                  if (neighbors != null) {
                    // Check Edges have even Opposite Points
                    if (params!.preserveEdges) {
                      final edgeSet = existingEdges[positionHash];
                      bool hasPair = true;
                      for (final edgeHash in edgeSet.keys) {
                        if (flatOpposites[edgeHash].length % 2 != 0) hasPair = false;
                      }
                      if (! hasPair) continue;
                    }

                    // Number of Neighbors
                    final k = neighbors.keys.length;

                    ///// Loop's Formula
                    final beta = 1 / k * ((5/8) - math.pow((3/8) + (1/4) * math.cos(2 * math.pi / k), 2));

                    ///// Warren's Formula
                    // final beta = (k > 3) ? 3 / (8 * k) : ((k == 3) ? 3 / 16 : 0);

                    ///// Stevinz' Formula
                    // final beta = 0.5 / k;

                    ///// Corners
                    final heavy = (1 / k) / k;

                    ///// Interpolate Beta -> Heavy
                    final weight = lerp(heavy, beta, params.weight);

                    ///// Average with Neighbors
                    final startWeight = 1.0 - (weight * k);
                    _vertex[v].scale(startWeight);

                    for (final neighborHash in neighbors.keys) {
                      final neighborIndices = neighbors[neighborHash];

                      _average.setValues(0, 0, 0);
                      for (int j = 0; j < neighborIndices.length; j++) {
                        _average.add(_temp.fromBuffer(existingAttribute, neighborIndices[j]));
                      }
                      _average.divideScalar(neighborIndices.length);

                      _average.scale(weight);
                      _vertex[v].add(_average);
                    }
                  } 
                  else if (opposites && opposites.length == 2) {
                    final k = opposites.length;
                    const beta = 0.125; /* 1/8 */
                    final startWeight = 1.0 - (beta * k);
                    _vertex[v].scale(startWeight);

                    opposites.forEach((oppositeIndex){
                        _average.fromBuffer(existingAttribute, oppositeIndex);
                        _average.scale(beta);
                        _vertex[v].add(_average);
                    });
                  }
                }
              }

              // Add New Triangle Position
              setTriangle(floatArray, index, flattenedAttribute.itemSize, _vertex[0], _vertex[1], _vertex[2]);
              index += (flattenedAttribute.itemSize * 3);
          }

          final List<double> toSend = [];

          for(int i = 0; i < floatArray.length; i++){
            toSend.add(floatArray[i].toDouble());
          }

          return toSend;
        }

        ///// Build Geometry, Set Attributes
        attributeList.forEach((attributeName){
            final existingAttribute = existing.getAttributeFromString(attributeName);
            final flattenedAttribute = flat.getAttributeFromString(attributeName);
            if (existingAttribute == null || flattenedAttribute == null) return;

            final floatArray = subdivideAttribute(attributeName, existingAttribute, flattenedAttribute);
            loop.setAttributeFromString(attributeName, Float32BufferAttribute.fromList(floatArray, flattenedAttribute.itemSize));
        });

        ///// Morph Attributes
        final morphAttributes = existing.morphAttributes;
        for (final attributeName in morphAttributes.keys) {
          final List<BufferAttribute> array = [];
          final morphAttribute = morphAttributes[attributeName];

          // Process Array of Float32BufferAttributes
          for (int i = 0, l = morphAttribute.length; i < l; i++) {
            if (morphAttribute[i].count != vertexCount) continue;
            final existingAttribute = morphAttribute[i];
            final flattenedAttribute = LoopSubdivision.flatAttribute(morphAttribute[i], morphAttribute[i].count, params);

            final floatArray = subdivideAttribute(attributeName, existingAttribute, flattenedAttribute);
            array.add(Float32BufferAttribute.fromList(floatArray, flattenedAttribute.itemSize));
          }
          loop.morphAttributes[attributeName] = array;
        }
        loop.morphTargetsRelative = existing.morphTargetsRelative;

        ///// Clean Up
        flat.dispose();
        existing.dispose();
        return loop;
    }
}

/////////////////////////////////////////////////////////////////////////////////////
/////   Local Functions, Hash
/////////////////////////////////////////////////////////////////////////////////////

final int _positionShift = math.pow(10, POSITION_DECIMALS).toInt();

/** Compares two numbers to see if they're almost the same */
bool fuzzy(num a,num b, [double tolerance = 0.00001]) {
  return ((a < (b + tolerance)) && (a > (b - tolerance)));
}

/** Generates hash strong from Number */
String hashFromNumber(num num, [int? shift]) {
  shift ??= _positionShift;
  int roundedNumber = round(num.toInt() * shift);
  if (roundedNumber == 0) roundedNumber = 0; /* prevent -0 (signed 0 can effect math.atan2(), etc.) */
  return '$roundedNumber';
}

/** Generates hash strong from Vector3.zero */
String hashFromVector(Vector3 vector, [int? shift]) {
  shift ??= _positionShift;
  return '${hashFromNumber(vector.x, shift)},${hashFromNumber(vector.y, shift)},${hashFromNumber(vector.z, shift)}';
}

double lerp(double x, double y, double t) {
  return (1 - t) * x + t * y;
}

int round(int x) {
  return (x + ((x > 0) ? 0.5 : -0.5).toInt()) << 0;
}

/////////////////////////////////////////////////////////////////////////////////////
/////   Local Functions, Geometry
/////////////////////////////////////////////////////////////////////////////////////

void calcNormal(Vector3 target,Vector3 vec1,Vector3 vec2,Vector3 vec3) {
  _temp.sub2(vec1, vec2);
  target.sub2(vec2, vec3);
  target.cross(_temp).normalize();
}

List<String> gatherAttributes(BufferGeometry geometry) {
  final contains = geometry.attributes.keys.toList();
  final attributeList = ['position', 'normal', 'uv'];//Array.from(Set(desired.concat(contains)));
  for(int i = 0; i < contains.length;i++){
    if(!attributeList.contains(contains[i])){
      attributeList.add(contains[i]);
    }
  }
  return attributeList;
}

void setTriangle(positions,int index,int step,Vector3 vec0,Vector3 vec1,Vector3 vec2) {
  if (step >= 1) {
    positions[index + 0 + (step * 0)] = vec0.x;
    positions[index + 0 + (step * 1)] = vec1.x;
    positions[index + 0 + (step * 2)] = vec2.x;
  }
  if (step >= 2) {
    positions[index + 1 + (step * 0)] = vec0.y;
    positions[index + 1 + (step * 1)] = vec1.y;
    positions[index + 1 + (step * 2)] = vec2.y;
  }
  if (step >= 3) {
    positions[index + 2 + (step * 0)] = vec0.z;
    positions[index + 2 + (step * 1)] = vec1.z;
    positions[index + 2 + (step * 2)] = vec2.z;
  }
  // if (step >= 4) {
  //   positions[index + 3 + (step * 0)] = vec0.w;
  //   positions[index + 3 + (step * 1)] = vec1.w;
  //   positions[index + 3 + (step * 2)] = vec2.w;
  // }
}

bool verifyGeometry(BufferGeometry? geometry) {
  if (geometry == null) {
    console.warning('LoopSubdivision: Geometry provided is null');
    return false;
  }

  if (geometry.attributes['position'] == null) {
    console.warning('LoopSubdivision: Geometry provided missing required position attribute');
    return false;
  }

  if (geometry.attributes['normal'] == null) {
    geometry.computeVertexNormals();
  }
  return true;
}