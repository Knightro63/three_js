import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';

int sortOpaque(Pool a, Pool b ) {
	return a.z - b.z;
}

int sortTransparent(Pool a, Pool b ) {
	return b.z - a.z;
}

class Bounds{
  Bounds({
    this.boxInitialized = false,
    BoundingBox? box,
    this.sphereInitialized = false,
    BoundingSphere? sphere
  }){
    this.sphere = sphere ?? BoundingSphere();
    this.box = box ?? BoundingBox();
  }

  bool boxInitialized;
  late BoundingBox box;
  bool sphereInitialized;
  late BoundingSphere sphere;
}

class Pool{
  Pool({
    this.z = -1,
    this.start = -1,
    this.end = -1,
    this.count = 0
  });

  int z;
  int start;
  int end;
  int count = 0;
}

class ReservedRange{
  ReservedRange({
		this.vertexStart = - 1,
    this.vertexCount = - 1,
    this.indexStart = - 1,
    this.indexCount = - 1,
  });

  int vertexStart;
  int vertexCount;
  int indexStart;
  int indexCount;
}

class MultiDrawRenderList {
  List<Pool> pool = [];
  List<Pool> list = [];
  int index = 0;

	MultiDrawRenderList();

	void push( drawRange, z ) {

		final pool = this.pool;
		final list = this.list;
		if (index >= pool.length ) {
			pool.add(Pool());
		}

		final item = pool[index];
		list.add(item);
		index++;

		item.start = drawRange.start;
		item.count = drawRange.count;
		item.z = z;
	}

	void reset() {
		list.length = 0;
		index = 0;
	}

}

final ID_ATTR_NAME = 'batchId';
final _matrix = Matrix4();
final _invMatrixWorld = Matrix4();
final _identityMatrix = Matrix4();
final _projScreenMatrix = Matrix4();
final _frustum = Frustum();
final _box = BoundingBox();
final _sphere = BoundingSphere();
final _vector = Vector3();
final _renderList = MultiDrawRenderList();
final _mesh = Mesh();
final List<Intersection> _batchIntersects = [];

// @TODO: SkinnedMesh support?
// @TODO: geometry.groups support?
// @TODO: geometry.drawRange support?
// @TODO: geometry.morphAttributes support?
// @TODO: Support uniform parameter per geometry
// @TODO: Add an "optimize" function to pack geometry and remove data gaps

// copies data from attribute "src" into "target" starting at "targetOffset"
void copyAttributeData( src, target, [int targetOffset = 0 ]) {
	final itemSize = target.itemSize;
	if ( src.isInterleavedBufferAttribute || src.array.finalructor != target.array.finalructor ) {

		// use the component getters and setters if the array data cannot
		// be copied directly
		final vertexCount = src.count;
		for (int i = 0; i < vertexCount; i ++ ) {
			for (int c = 0; c < itemSize; c ++ ) {
				target.setComponent( i + targetOffset, c, src.getComponent( i, c ) );
			}
		}
	} else {
		// faster copy approach using typed array set function
		target.array.set( src.array, targetOffset * itemSize );
	}

	target.needsUpdate = true;
}

class BatchedMesh extends Mesh {
  bool isBatchedMesh = true;
  bool perObjectFrustumCulled = true;
  bool sortObjects = true;
  bool _geometryInitialized = false;
  bool _visibilityChanged = true;

  BoundingBox? boundingBox;
  BoundingSphere? boundingSphere;
  Function? customSort;

  List<Pool> _drawRanges = [];
  List<ReservedRange> _reservedRanges = [];

  List<bool> _visibility = [];
  List<bool> _active = [];
  List<Bounds> _bounds = [];
  
  late int _maxGeometryCount;
	late int _maxVertexCount;
	late int _maxIndexCount;
  int _geometryCount = 0;
  int multiDrawCount = 0;

	int get maxGeometryCount => _maxGeometryCount;
  
  late Int32List multiDrawCounts;
  late Int32List multiDrawStarts;

  Int32List? multiDrawInstances;

  DataTexture? matricesTexture;

	BatchedMesh(int maxGeometryCount,int maxVertexCount, [int? maxIndexCount, Material? material ]):super(BufferGeometry(),material) {
		maxIndexCount ??= maxVertexCount * 2;

    _maxGeometryCount = maxGeometryCount;
		_maxVertexCount = maxVertexCount;
		_maxIndexCount = maxIndexCount;

		multiDrawCounts = Int32List( maxGeometryCount );
		multiDrawStarts = Int32List( maxGeometryCount );
    
    onBeforeRender = ({
      WebGLRenderer? renderer,
      RenderTarget? renderTarget,
      Object3D? mesh,
      Scene? scene,
      Camera? camera,
      BufferGeometry? geometry,
      Material? material,
      Map<String, dynamic>? group
    }) {
      // if visibility has not changed and frustum culling and object sorting is not required
      // then skip iterating over all items
      if ( !_visibilityChanged && !this.perObjectFrustumCulled && !sortObjects ) {
        return;
      }

      // the indexed version of the multi draw function requires specifying the start
      // offset in bytes.
      final index = geometry?.getIndex();
      final int bytesPerElement = index == null ? 1 : index.array.BYTES_PER_ELEMENT;

      final active = _active;
      final visibility = _visibility;
      final multiDrawStarts = this.multiDrawStarts;
      final multiDrawCounts = this.multiDrawCounts;
      final drawRanges = _drawRanges;
      final perObjectFrustumCulled = this.perObjectFrustumCulled;

      // prepare the frustum in the local frame
      if ( perObjectFrustumCulled ) {

        _projScreenMatrix
          .multiply2( camera!.projectionMatrix, camera.matrixWorldInverse )
          .multiply(matrixWorld );
        _frustum.setFromMatrix(
          _projScreenMatrix,
          renderer!.coordinateSystem
        );
      }

      int count = 0;
      if (sortObjects) {
        // get the camera position in the local frame
        _invMatrixWorld.setFrom(matrixWorld ).invert();
        _vector.setFromMatrixPosition( camera!.matrixWorld ).applyMatrix4( _invMatrixWorld );

        for (int i = 0, l = visibility.length; i < l; i ++ ) {
          if ( visibility[ i ] && active[ i ] ) {
            // get the bounds in world space
            getMatrixAt( i, _matrix );
            getBoundingSphereAt( i, _sphere ).applyMatrix4( _matrix );

            // determine whether the batched geometry is within the frustum
            bool culled = false;
            if ( perObjectFrustumCulled ) {
              culled = ! _frustum.intersectsSphere( _sphere );
            }

            if (!culled ) {
              // get the distance from camera used for sorting
              final z = _vector.distanceTo( _sphere.center );
              _renderList.push( drawRanges[ i ], z );
            }
          }
        }

        // Sort the draw ranges and prep for rendering
        final list = _renderList.list;
        final customSort = this.customSort;
        if ( customSort == null ) {
          list.sort( material!.transparent ? sortTransparent : sortOpaque );
        } else {
          customSort.call( this, list, camera );
        }

        for (int i = 0, l = list.length; i < l; i ++ ) {
          final item = list[ i ];
          multiDrawStarts[ count ] = item.start * bytesPerElement;
          multiDrawCounts[ count ] = item.count;
          count ++;
        }
        _renderList.reset();

      } else {
        for ( int i = 0, l = visibility.length; i < l; i ++ ) {
          if ( visibility[ i ] && active[ i ] ) {
            // determine whether the batched geometry is within the frustum
            bool culled = false;
            if ( perObjectFrustumCulled ) {
              // get the bounds in world space
              getMatrixAt( i, _matrix );
              getBoundingSphereAt( i, _sphere ).applyMatrix4( _matrix );
              culled = ! _frustum.intersectsSphere( _sphere );
            }

            if ( !culled ) {
              final range = drawRanges[ i ];
              multiDrawStarts[ count ] = range.start * bytesPerElement;
              multiDrawCounts[ count ] = range.count;
              count ++;
            }
          }
        }
      }

      multiDrawCount = count;
      _visibilityChanged = false;
    };

		_initMatricesTexture();
	}

	void _initMatricesTexture() {

		// layout (1 matrix = 4 pixels)
		//      RGBA RGBA RGBA RGBA (=> column1, column2, column3, column4)
		//  with  8x8  pixel texture max   16 matrices * 4 pixels =  (8 * 8)
		//       16x16 pixel texture max   64 matrices * 4 pixels = (16 * 16)
		//       32x32 pixel texture max  256 matrices * 4 pixels = (32 * 32)
		//       64x64 pixel texture max 1024 matrices * 4 pixels = (64 * 64)

		double sizeSqrt = math.sqrt( _maxGeometryCount * 4 ); // 4 pixels needed for 1 matrix
		int size = ( sizeSqrt / 4 ).ceil() * 4;
		size = math.max( size, 4 );

		final matricesArray = Float32Array( size * size * 4 ); // 4 floats per RGBA pixel
		final matricesTexture = DataTexture( matricesArray, size, size, RGBAFormat, FloatType );

		this.matricesTexture = matricesTexture;
	}

	_initializeGeometry(BufferGeometry reference ) {

		final geometry = this.geometry;
		final maxVertexCount = _maxVertexCount;
		final maxGeometryCount = _maxGeometryCount;
		final maxIndexCount = _maxIndexCount;
		if (!_geometryInitialized) {
			for ( final attributeName in reference.attributes.keys ) {

				final srcAttribute = reference.getAttributeFromString( attributeName );
				final array = srcAttribute.array;
        final itemSize = srcAttribute.itemSize;
        final normalized = srcAttribute.normalized;

				final dstArray = array.finalructor( maxVertexCount * itemSize );
				final dstAttribute = BufferAttribute.fromUnknown( dstArray, itemSize, normalized );

				geometry?.setAttributeFromString( attributeName, dstAttribute );
			}

			if ( reference.getIndex() != null ) {

				final indexArray = maxVertexCount > 65536
					? Uint32Array( maxIndexCount )
					: Uint16Array( maxIndexCount );

        if(indexArray is Uint32Array){
			    geometry?.setIndex( Uint32BufferAttribute( indexArray, 1 ) );
        }
        else if(indexArray is Uint16Array){
          geometry?.setIndex( Uint16BufferAttribute( indexArray, 1 ) );
        }
			}

			final idArray = maxGeometryCount > 65536
				? Uint32Array( maxVertexCount )
				: Uint16Array( maxVertexCount );
        if(idArray is Uint32Array){
			    geometry?.setAttributeFromString( ID_ATTR_NAME, Uint32BufferAttribute( idArray, 1 ) );
        }
        else if(idArray is Uint16Array){
          geometry?.setAttributeFromString( ID_ATTR_NAME, Uint16BufferAttribute( idArray, 1 ) );
        }

			_geometryInitialized = true;
		}
	}

	// Make sure the geometry is compatible with the existing combined geometry attributes
	void _validateGeometry(BufferGeometry geometry ) {
		// check that the geometry doesn't have a version of our reserved id attribute
		if ( geometry.getAttributeFromString( ID_ATTR_NAME ) ) {
			throw( 'BatchedMesh: Geometry cannot use attribute "$ID_ATTR_NAME"' );
		}

		// check to ensure the geometries are using consistent attributes and indices
		final batchGeometry = this.geometry;
		if (( geometry.getIndex() != null) != (batchGeometry?.getIndex() != null) ) {

			throw( 'BatchedMesh: All geometries must consistently have "index".' );

		}

		for ( final attributeName in batchGeometry!.attributes.keys) {
			if ( attributeName == ID_ATTR_NAME ) {
				continue;
			}

			if ( !geometry.hasAttributeFromString( attributeName ) ) {
				throw( 'BatchedMesh: Added geometry missing "$attributeName". All geometries must have consistent attributes.' );
			}

			final BufferAttribute srcAttribute = geometry.getAttributeFromString( attributeName );
			final BufferAttribute dstAttribute = batchGeometry.getAttributeFromString( attributeName );
			if ( srcAttribute.itemSize != dstAttribute.itemSize || srcAttribute.normalized != dstAttribute.normalized ) {
				throw( 'BatchedMesh: All attributes must have a consistent itemSize and normalized value.' );
			}
		}
	}

	BatchedMesh setCustomSort(Function func ) {
		customSort = func;
		return this;
	}

	void computeBoundingBox() {
		if ( this.boundingBox == null ) {
			this.boundingBox = BoundingBox();
		}

		final geometryCount = _geometryCount;
		final boundingBox = this.boundingBox;
		final active = _active;

		boundingBox?.empty();
		for (int i = 0; i < geometryCount; i ++ ) {
			if ( active[ i ] == false ) continue;
		  getMatrixAt( i, _matrix );
			getBoundingBoxAt( i, _box ).applyMatrix4( _matrix );
			boundingBox?.union( _box );
		}
	}

  @override
	void computeBoundingSphere() {
		if ( this.boundingSphere == null ) {
			this.boundingSphere = BoundingSphere();
		}

		final geometryCount = _geometryCount;
		final boundingSphere = this.boundingSphere;
		final active = _active;

		boundingSphere?.empty();
		for (int i = 0; i < geometryCount; i ++ ) {
			if ( active[ i ] == false ) continue;
			getMatrixAt( i, _matrix );
			getBoundingSphereAt( i, _sphere ).applyMatrix4( _matrix );
			boundingSphere?.union( _sphere );
		}
	}

	int addGeometry(BufferGeometry geometry, [int vertexCount = - 1, int indexCount = - 1 ]) {
		_initializeGeometry( geometry );
		_validateGeometry( geometry );

		// ensure we're not over geometry
		if (_geometryCount >= _maxGeometryCount ) {
			throw( 'BatchedMesh: Maximum geometry count reached.' );
		}

		// get the necessary range fo the geometry
		final reservedRange = ReservedRange(
			vertexStart: - 1,
			vertexCount: - 1,
			indexStart: - 1,
			indexCount: - 1,
    );

		ReservedRange? lastRange;
		final reservedRanges = _reservedRanges;
		final List<Pool> drawRanges = _drawRanges;
		final List<Bounds> bounds = _bounds;
		if (_geometryCount != 0 ) {
			lastRange = reservedRanges[ reservedRanges.length - 1 ];
		}

		if ( vertexCount == - 1 ) {
			reservedRange.vertexCount = geometry.getAttributeFromString( 'position' ).count;
		} else {
			reservedRange.vertexCount = vertexCount;
		}

		if ( lastRange == null ) {
			reservedRange.vertexStart = 0;
		} else {
			reservedRange.vertexStart = lastRange.vertexStart + lastRange.vertexCount;
		}

		final index = geometry.getIndex();
		final hasIndex = index != null;
		if ( hasIndex ) {
			if ( indexCount	== - 1 ) {
				reservedRange.indexCount = index.count;
			} else {
				reservedRange.indexCount = indexCount;
			}

			if ( lastRange == null ) {
				reservedRange.indexStart = 0;
			} else {
				reservedRange.indexStart = lastRange.indexStart + lastRange.indexCount;
			}
		}

		if (
			reservedRange.indexStart != - 1 &&
			reservedRange.indexStart + reservedRange.indexCount > _maxIndexCount ||
			reservedRange.vertexStart + reservedRange.vertexCount > _maxVertexCount
		) {

			throw( 'BatchedMesh: Reserved space request exceeds the maximum buffer size.' );

		}

		final visibility = _visibility;
		final active = _active;
		final matricesTexture = this.matricesTexture;
		final matricesArray = this.matricesTexture?.image.data;

		// push new visibility states
		visibility.add( true );
		active.add( true );

		// update id
		final geometryId = _geometryCount;
		_geometryCount ++;

		// initialize matrix information
		_identityMatrix.copyIntoArray( matricesArray, geometryId * 16 );
		matricesTexture?.needsUpdate = true;

		// add the reserved range and draw range objects
		reservedRanges.add( reservedRange );
		drawRanges.add( Pool(
			start: hasIndex ? reservedRange.indexStart : reservedRange.vertexStart,
			count: - 1
    ));
		bounds.add( Bounds(
			boxInitialized: false,
			box: BoundingBox(),
			sphereInitialized: false,
			sphere: BoundingSphere()
    ));

		// set the id for the geometry
		final idAttribute = this.geometry?.getAttributeFromString( ID_ATTR_NAME );
		for (int i = 0; i < reservedRange.vertexCount; i ++ ) {
			idAttribute.setX( reservedRange.vertexStart + i, geometryId );
		}

		idAttribute.needsUpdate = true;

		// update the geometry
		setGeometryAt( geometryId, geometry );

		return geometryId;
	}

	int setGeometryAt(int id,BufferGeometry geometry ) {
		if ( id >= _geometryCount ) {
			throw( 'BatchedMesh: Maximum geometry count reached.' );
		}

		_validateGeometry(geometry);

		final batchGeometry = this.geometry;
		final hasIndex = batchGeometry?.getIndex() != null;
		final dstIndex = batchGeometry?.getIndex();
		final srcIndex = geometry.getIndex();
		final reservedRange = _reservedRanges[ id ];
		if (
			hasIndex &&
			srcIndex!.count > reservedRange.indexCount ||
			geometry.attributes['position'].count > reservedRange.vertexCount
		) {
			throw( 'BatchedMesh: Reserved space not large enough for provided geometry.' );
		}

		// copy geometry over
		final vertexStart = reservedRange.vertexStart;
		final vertexCount = reservedRange.vertexCount;
		for ( final attributeName in batchGeometry!.attributes.keys) {
			if ( attributeName == ID_ATTR_NAME ) {
				continue;
			}

			// copy attribute data
			final srcAttribute = geometry.getAttributeFromString( attributeName );
			final dstAttribute = batchGeometry.getAttributeFromString( attributeName );
			copyAttributeData( srcAttribute, dstAttribute, vertexStart );

			// fill the rest in with zeroes
			final itemSize = srcAttribute.itemSize;
			for (int i = srcAttribute.count, l = vertexCount; i < l; i ++ ) {
				final index = vertexStart + i;
				for (int c = 0; c < itemSize; c ++ ) {
					dstAttribute.setComponent( index, c, 0 );
				}
			}

			dstAttribute.needsUpdate = true;
			dstAttribute.addUpdateRange( vertexStart * itemSize, vertexCount * itemSize );
		}

		// copy index
		if ( hasIndex ) {

			final indexStart = reservedRange.indexStart;

			// copy index data over
			for (int i = 0; i < srcIndex!.count; i ++ ) {
				dstIndex?.setX( indexStart + i, vertexStart + srcIndex.getX( i )!);
			}

			// fill the rest in with zeroes
			for (int i = srcIndex.count, l = reservedRange.indexCount; i < l; i ++ ) {
				dstIndex?.setX( indexStart + i, vertexStart );
			}

			dstIndex?.needsUpdate = true;
			dstIndex?.addUpdateRange( indexStart, reservedRange.indexCount );
		}

		// store the bounding boxes
		final bound = _bounds[ id ];
		if ( geometry.boundingBox != null ) {
			bound.box.setFrom( geometry.boundingBox! );
			bound.boxInitialized = true;
		} else {
			bound.boxInitialized = false;
		}

		if ( geometry.boundingSphere != null ) {
			bound.sphere.setFrom( geometry.boundingSphere! );
			bound.sphereInitialized = true;
		} else {
			bound.sphereInitialized = false;
		}

		// set drawRange count
		final drawRange = _drawRanges[ id ];
		final posAttr = geometry.getAttributeFromString( 'position' );
		drawRange.count = hasIndex ? srcIndex?.count : posAttr.count;
		_visibilityChanged = true;

		return id;
	}

	deleteGeometry( geometryId ) {
		// Note: User needs to call optimize() afterward to pack the data.
		final active = _active;
		if ( geometryId >= active.length || active[ geometryId ] == false ) {
			return this;
		}

		active[ geometryId ] = false;
		_visibilityChanged = true;

		return this;
	}

	getInstanceCountAt(int id ) {
		if (multiDrawInstances == null ) return null;
		return multiDrawInstances?[ id ];
	}

	setInstanceCountAt( id, instanceCount ) {
		multiDrawInstances ??= Int32List.fromList(List.filled(_maxGeometryCount, 1));
		multiDrawInstances?[ id ] = instanceCount;

		return id;
	}

	// get bounding box and compute it if it doesn't exist
	getBoundingBoxAt( id, target ) {
		final active = _active;
		if ( active[ id ] == false ) {
			return null;
		}

		// compute bounding box
		final bound = _bounds[ id ];
		final box = bound.box;
		final geometry = this.geometry;
		if ( bound.boxInitialized == false ) {

			box.empty();

			final index = geometry?.index;
			final position = geometry?.attributes['position'];
			final drawRange = _drawRanges[ id ];
			for (int i = drawRange.start, l = drawRange.start + drawRange.count; i < l; i ++ ) {
				int iv = i;
				if ( index != null) {
					iv = index.getX( iv )!.toInt();
				}

				box.expandByPoint( _vector.fromBuffer( position, iv ) );
			}

			bound.boxInitialized = true;
		}

		target.copy( box );
		return target;
	}

	// get bounding sphere and compute it if it doesn't exist
	getBoundingSphereAt( id, target ) {
		final active = _active;
		if ( active[ id ] == false ) {
			return null;
		}

		// compute bounding sphere
		final bound = _bounds[ id ];
		final sphere = bound.sphere;
		final geometry = this.geometry;
		if ( bound.sphereInitialized == false ) {

			sphere.empty();

			getBoundingBoxAt( id, _box );
			_box.getCenter( sphere.center );

			final index = geometry?.index;
			final position = geometry?.attributes['position'];
			final drawRange = _drawRanges[ id ];

			double maxRadiusSq = 0;
			for (int i = drawRange.start, l = drawRange.start + drawRange.count; i < l; i ++ ) {
				int iv = i;
				if ( index != null) {
					iv = index.getX(iv)!.toInt();
				}

				_vector.fromBuffer( position, iv );
				maxRadiusSq = math.max( maxRadiusSq, sphere.center.distanceToSquared( _vector ) );
			}

			sphere.radius = math.sqrt( maxRadiusSq );
			bound.sphereInitialized = true;
		}

		target.copy( sphere );
		return target;
	}

	BatchedMesh setMatrixAt( geometryId, Matrix4 matrix ) {
		// @TODO: Map geometryId to index of the arrays because
		//        optimize() can make geometryId mismatch the index

		final active = _active;
		final matricesTexture = this.matricesTexture;
		final matricesArray = this.matricesTexture?.image.data;
		final geometryCount = _geometryCount;
		if ( geometryId >= geometryCount || active[ geometryId ] == false ) {
			return this;
		}
		matrix.fromNativeArray( matricesArray, geometryId * 16 );
		matricesTexture?.needsUpdate = true;

		return this;
	}

	Matrix4? getMatrixAt( geometryId,Matrix4 matrix ) {
		final active = _active;
		final matricesArray = matricesTexture?.image.data;
		final geometryCount = _geometryCount;
		if ( geometryId >= geometryCount || active[ geometryId ] == false ) {
			return null;
		}
    
		return matrix.fromNativeArray( matricesArray, geometryId * 16 );
	}

	BatchedMesh setVisibleAt( geometryId, value ) {
		final visibility = _visibility;
		final active = _active;
		final geometryCount = _geometryCount;

		// if the geometry is out of range, not active, or visibility state
		// does not change then return early
		if (
			geometryId >= geometryCount ||
			active[ geometryId ] == false ||
			visibility[ geometryId ] == value
		) {
			return this;
		}

		visibility[ geometryId ] = value;
		_visibilityChanged = true;

		return this;
	}

	bool getVisibleAt( geometryId ) {
		final visibility = _visibility;
		final active = _active;
		final geometryCount = _geometryCount;

		// return early if the geometry is out of range or not active
		if ( geometryId >= geometryCount || active[ geometryId ] == false ) {
			return false;
		}

		return visibility[ geometryId ];
	}

  @override
	void raycast(Raycaster raycaster,List<Intersection> intersects ) {
		final visibility = _visibility;
		final active = _active;
		final drawRanges = _drawRanges;
		final geometryCount = _geometryCount;
		final matrixWorld = this.matrixWorld;
		final batchGeometry = geometry;

		// iterate over each geometry
		_mesh.material = material;
		_mesh.geometry?.index = batchGeometry!.index;
		_mesh.geometry?.attributes = batchGeometry!.attributes;

		_mesh.geometry?.boundingBox ??= BoundingBox();
		_mesh.geometry?.boundingSphere ??= BoundingSphere();

		for ( int i = 0; i < geometryCount; i ++ ) {
			if ( ! visibility[ i ] || ! active[ i ] ) {
				continue;
			}

			final drawRange = drawRanges[ i ];
			_mesh.geometry?.setDrawRange( drawRange.start, drawRange.count );

			// ge the intersects
			getMatrixAt( i, _mesh.matrixWorld )?.premultiply( matrixWorld );
			getBoundingBoxAt( i, _mesh.geometry?.boundingBox );
			getBoundingSphereAt( i, _mesh.geometry?.boundingSphere );
			_mesh.raycast( raycaster, _batchIntersects );

			// add batch id to the intersects
			for (int j = 0, l = _batchIntersects.length; j < l; j ++ ) {
				final intersect = _batchIntersects[ j ];
				intersect.object = this;
				intersect.batchId = i;
				intersects.add( intersect );
			}

			_batchIntersects.length = 0;
		}

		_mesh.material = null;
		_mesh.geometry?.index = null;
		_mesh.geometry?.attributes = {};
		_mesh.geometry?.setDrawRange( 0, double.maxFinite.toInt() );
	}

  @override
	BatchedMesh copy(Object3D source, [bool? recursive]) {
		super.copy( source );
		geometry = source.geometry?.clone();

    if(source is BatchedMesh){
      perObjectFrustumCulled = source.perObjectFrustumCulled;
      sortObjects = source.sortObjects;
      boundingBox = source.boundingBox?.clone();
      boundingSphere = source.boundingSphere?.clone();

      _drawRanges = source._drawRanges.sublist(0);//.map( (range){return range;}).toList();
      _reservedRanges = source._reservedRanges.sublist(0);//.map( (range){return range;}).toList();

      _visibility = source._visibility.sublist(0);
      _active = source._active.sublist(0);
      _bounds = source._bounds.map(
        (bound){
          return Bounds(
            boxInitialized: bound.boxInitialized,
            box: bound.box.clone(),
            sphereInitialized: bound.sphereInitialized,
            sphere: bound.sphere.clone()
          );
        }
      ).toList();

      _maxGeometryCount = source._maxGeometryCount;
      _maxVertexCount = source._maxVertexCount;
      _maxIndexCount = source._maxIndexCount;

      _geometryInitialized = source._geometryInitialized;
      _geometryCount = source._geometryCount;
      multiDrawCounts = source.multiDrawCounts.sublist(0);
      multiDrawStarts = source.multiDrawStarts.sublist(0);

      matricesTexture = source.matricesTexture?.clone() as DataTexture?;
    }
		matricesTexture?.image.data = matricesTexture?.image.slice();

		return this;
	}

  @override
	void dispose() {
    super.dispose();
		// Assuming the geometry is not shared with other meshes
		geometry?.dispose();

		matricesTexture?.dispose();
		matricesTexture = null;
	}

  @override
  void onBeforeShadow({
    WebGLRenderer? renderer,
    Object3D? scene,
    Camera? camera,
    Camera? shadowCamera,
    BufferGeometry? geometry,
    Material? material,
    Map<String, dynamic>? group
  }) {
    onBeforeRender?.call(renderer: renderer, camera: shadowCamera, geometry: geometry, material: material);
  }
}
