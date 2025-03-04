import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';

int ascIdSort( a, b ) {
	return a - b;
}

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
    this.count = 0,
    this.index = -1
  });

  int z;
  int start;
  int end;
  int count = 0;
  int index;
}

class ReservedRange{
  ReservedRange({
		this.vertexStart = - 1,
    this.vertexCount = - 1,
    this.indexStart = - 1,
    this.indexCount = - 1
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

	void push(int start, int count, int z, int index ) {
		final pool = this.pool;
		final list = this.list;
		if ( this.index >= pool.length ) {

			pool.add(Pool(
				start: - 1,
				count: - 1,
				z: - 1,
				index: - 1,
      ));
		}

		final item = pool[ this.index ];
		list.add( item );
		this.index ++;

		item.start = start;
		item.count = count;
		item.z = z;
		item.index = index;
	}

	void reset() {
		list.length = 0;
		index = 0;
	}

}

final ID_ATTR_NAME = 'batchId';
final _matrix = Matrix4();
final _whiteColor = Color( 1, 1, 1 );
final _invMatrixWorld = Matrix4();
final _projScreenMatrix = Matrix4();
final _frustum = Frustum();
final _box = BoundingBox();
final _sphere = BoundingSphere();
final _vector = Vector3();
final _forward = Vector3();
final _temp = Vector3();
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

  BoundingBox? boundingBox;
  BoundingSphere? boundingSphere;
  Function? customSort;

	List _instanceInfo = [];
	List _geometryInfo = [];

  List _availableInstanceIds = [];
  List _availableGeometryIds = [];
  
  int _nextIndexStart = 0;
  int _nextVertexStart = 0;
  int _geometryCount = 0;

  bool _visibilityChanged = true;
  bool _geometryInitialized = false;

  List<Pool> _drawRanges = [];

  List<bool> _visibility = [];
  List<bool> _active = [];
  List<Bounds> _bounds = [];
  
  late int _maxInstanceCount;
	late int _maxVertexCount;
	late int _maxIndexCount;
  int multiDrawCount = 0;

	int get maxInstanceCount => _maxInstanceCount;
  
  late Int32List multiDrawCounts;
  late Int32List multiDrawStarts;
  Int32List? multiDrawInstances;

  Texture? matricesTexture;
	Texture? indirectTexture;
	Texture? colorsTexture;

	BatchedMesh(int maxInstanceCount,int maxVertexCount, [int? maxIndexCount, Material? material ]):super(BufferGeometry(),material) {
		maxIndexCount ??= maxVertexCount * 2;

    _maxInstanceCount = maxInstanceCount;
		_maxVertexCount = maxVertexCount;
		_maxIndexCount = maxIndexCount;

		multiDrawCounts = Int32List( maxInstanceCount );
		multiDrawStarts = Int32List( maxInstanceCount );

		_initMatricesTexture();
    _initIndirectTexture();
	}

	void _initMatricesTexture() {

		// layout (1 matrix = 4 pixels)
		//      RGBA RGBA RGBA RGBA (=> column1, column2, column3, column4)
		//  with  8x8  pixel texture max   16 matrices * 4 pixels =  (8 * 8)
		//       16x16 pixel texture max   64 matrices * 4 pixels = (16 * 16)
		//       32x32 pixel texture max  256 matrices * 4 pixels = (32 * 32)
		//       64x64 pixel texture max 1024 matrices * 4 pixels = (64 * 64)

		double sizeSqrt = math.sqrt( _maxInstanceCount * 4 ); // 4 pixels needed for 1 matrix
		int size = ( sizeSqrt / 4 ).ceil() * 4;
		size = math.max( size, 4 );

		final matricesArray = Float32Array( size * size * 4 ); // 4 floats per RGBA pixel
		final matricesTexture = DataTexture( matricesArray, size, size, RGBAFormat, FloatType );

		this.matricesTexture = matricesTexture;
	}
	_initIndirectTexture() {
		int size = math.sqrt( maxInstanceCount ).ceil();

		final indirectArray = Uint32Array( size * size );
		indirectTexture = DataTexture( indirectArray, size, size, RedIntegerFormat, UnsignedIntType );
	}
	_initializeGeometry(BufferGeometry reference ) {

		final geometry = this.geometry;
		final maxVertexCount = _maxVertexCount;
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

			_geometryInitialized = true;
		}
	}

	// Make sure the geometry is compatible with the existing combined geometry attributes
	void _validateGeometry(BufferGeometry geometry ) {
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

	/**
	 * Validates the instance defined by the given ID.
	 *
	 * @param {number} instanceId - The the instance to validate.
	 */
	validateInstanceId( instanceId ) {
		final instanceInfo = this._instanceInfo;
		if ( instanceId < 0 || instanceId >= instanceInfo.length || instanceInfo[ instanceId ].active == false ) {
			throw( 'THREE.BatchedMesh: Invalid instanceId ${instanceId}. Instance is either out of range or has been deleted.');
		}
	}

	/**
	 * Validates the geometry defined by the given ID.
	 *
	 * @param {number} geometryId - The the geometry to validate.
	 */
	validateGeometryId( geometryId ) {
		final geometryInfoList = this._geometryInfo;
		if ( geometryId < 0 || geometryId >= geometryInfoList.length || geometryInfoList[ geometryId ].active == false ) {
			throw( 'THREE.BatchedMesh: Invalid geometryId ${geometryId}. Geometry is either out of range or has been deleted.' );
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

	/**
	 * Adds a new instance to the batch using the geometry of the given ID and returns
	 * a new id referring to the new instance to be used by other functions.
	 *
	 * @param {number} geometryId - The ID of a previously added geometry via {@link BatchedMesh#addGeometry}.
	 * @return {number} The instance ID.
	 */
	addInstance( geometryId ) {
		final atCapacity = this._instanceInfo.length >= this.maxInstanceCount;

		// ensure we're not over geometry
		if ( atCapacity && this._availableInstanceIds.length == 0 ) {
			throw( 'THREE.BatchedMesh: Maximum item count reached.' );
		}

		final instanceInfo = {
			'visible': true,
			'active': true,
			'geometryIndex': geometryId,
		};

		int? drawId;

		// Prioritize using previously freed instance ids
		if ( this._availableInstanceIds.length > 0 ) {
			this._availableInstanceIds.sort( ascIdSort );

			drawId = this._availableInstanceIds.removeAt(0);
			this._instanceInfo[ drawId! ] = instanceInfo;
		} 
    else {
			drawId = this._instanceInfo.length;
			this._instanceInfo.add( instanceInfo );
		}

		final matricesTexture = this.matricesTexture;
		_matrix.identity().copyIntoArray( matricesTexture!.image.data, drawId * 16 );
		matricesTexture.needsUpdate = true;

		final colorsTexture = this.colorsTexture;
		if ( colorsTexture != null) {
			_whiteColor.copyIntoArray( colorsTexture.image.data, drawId * 4 );
			colorsTexture.needsUpdate = true;
		}

		this._visibilityChanged = true;
		return drawId;
	}

	int addGeometry(BufferGeometry geometry, [int reservedVertexCount = - 1, int reservedIndexCount = - 1 ]) {
		this._initializeGeometry( geometry );

		this._validateGeometry( geometry );

		final geometryInfo = {
			// geometry information
			'vertexStart': - 1,
			'vertexCount': - 1,
			'reservedVertexCount': - 1,

			'indexStart': - 1,
			'indexCount': - 1,
			'reservedIndexCount': - 1,

			// draw range information
			'start': - 1,
			'count': - 1,

			// state
			'boundingBox': null,
			'boundingSphere': null,
			'active': true,
		};

		final geometryInfoList = this._geometryInfo;
		geometryInfo['vertexStart'] = this._nextVertexStart;
		geometryInfo['reservedVertexCount'] = reservedVertexCount == - 1 ? geometry.getAttributeFromString( 'position' ).count : reservedVertexCount;

		final index = geometry.getIndex();
		final hasIndex = index != null;

		if ( hasIndex ) {
			geometryInfo['indexStart'] = this._nextIndexStart;
			geometryInfo['reservedIndexCount'] = reservedIndexCount == - 1 ? index.count : reservedIndexCount;
		}

		if (
			geometryInfo['indexStart'] != - 1 &&
			(geometryInfo['indexStart'] as int) + (geometryInfo['reservedIndexCount'] as int) > this._maxIndexCount ||
			(geometryInfo['vertexStart'] as int) + (geometryInfo['reservedVertexCount'] as int) > this._maxVertexCount
		) {
			throw( 'THREE.BatchedMesh: Reserved space request exceeds the maximum buffer size.' );
		}

		// update id
		int geometryId;
		if ( this._availableGeometryIds.length > 0 ) {
			this._availableGeometryIds.sort( ascIdSort );

			geometryId = this._availableGeometryIds.removeAt(0);
			geometryInfoList[ geometryId ] = geometryInfo;
		} 
    else {
			geometryId = this._geometryCount;
			this._geometryCount ++;
			geometryInfoList.add( geometryInfo );
		}

		// update the geometry
		this.setGeometryAt( geometryId, geometry );

		// increment the next geometry position
		this._nextIndexStart = (geometryInfo['indexStart'] as int) + (geometryInfo['reservedIndexCount'] as int);
		this._nextVertexStart = (geometryInfo['vertexStart'] as int) + (geometryInfo['reservedVertexCount'] as int);

		return geometryId;
	}

	int setGeometryAt(int geometryId, BufferGeometry geometry ) {
		if ( geometryId >= this._geometryCount ) {
			throw( 'THREE.BatchedMesh: Maximum geometry count reached.' );
		}

		this._validateGeometry( geometry );

		final batchGeometry = this.geometry;
		final hasIndex = batchGeometry?.getIndex() != null;
		final dstIndex = batchGeometry?.getIndex();
		final srcIndex = geometry.getIndex();
		final geometryInfo = this._geometryInfo[ geometryId ];
		if (
			hasIndex &&
			(srcIndex?.count ?? 0) > geometryInfo.reservedIndexCount ||
			geometry.attributes['position'].count > geometryInfo.reservedVertexCount
		) {
			throw( 'THREE.BatchedMesh: Reserved space not large enough for provided geometry.' );
		}

		// copy geometry buffer data over
		final vertexStart = geometryInfo.vertexStart;
		final reservedVertexCount = geometryInfo.reservedVertexCount;
		geometryInfo.vertexCount = geometry.getAttributeFromString( 'position' ).count;

		for ( final attributeName in batchGeometry!.attributes.keys ) {
			// copy attribute data
			final srcAttribute = geometry.getAttributeFromString( attributeName );
			final dstAttribute = batchGeometry.getAttributeFromString( attributeName );
			copyAttributeData( srcAttribute, dstAttribute, vertexStart );

			// fill the rest in with zeroes
			final itemSize = srcAttribute.itemSize;
			for ( int i = srcAttribute.count, l = reservedVertexCount; i < l; i ++ ) {
				final index = vertexStart + i;
				for ( int c = 0; c < itemSize; c ++ ) {
					dstAttribute.setComponent( index, c, 0 );
				}
			}

			dstAttribute.needsUpdate = true;
			dstAttribute.addUpdateRange( vertexStart * itemSize, reservedVertexCount * itemSize );

		}

		// copy index
		if ( hasIndex ) {

			final indexStart = geometryInfo.indexStart;
			final reservedIndexCount = geometryInfo.reservedIndexCount;
			geometryInfo.indexCount = geometry.getIndex()?.count;

			// copy index data over
			for (int i = 0; i < (srcIndex?.count ?? 0); i ++ ) {
				dstIndex?.setX( indexStart + i, vertexStart + srcIndex?.getX( i ) );
			}

			// fill the rest in with zeroes
			for (int i = srcIndex?.count ?? 0, l = reservedIndexCount; i < l; i ++ ) {
				dstIndex?.setX( indexStart + i, vertexStart );
			}

			dstIndex?.needsUpdate = true;
			dstIndex?.addUpdateRange( indexStart, geometryInfo.reservedIndexCount );
		}

		// update the draw range
		geometryInfo.start = hasIndex ? geometryInfo.indexStart : geometryInfo.vertexStart;
		geometryInfo.count = hasIndex ? geometryInfo.indexCount : geometryInfo.vertexCount;

		// store the bounding boxes
		geometryInfo.boundingBox = null;
		if ( geometry.boundingBox != null ) {
			geometryInfo.boundingBox = geometry.boundingBox?.clone();
		}

		geometryInfo.boundingSphere = null;
		if ( geometry.boundingSphere != null ) {
			geometryInfo.boundingSphere = geometry.boundingSphere?.clone();
		}

		this._visibilityChanged = true;
		return geometryId;
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
    source as BatchedMesh;
		super.copy( source );

		this.geometry = source.geometry?.clone();
		this.perObjectFrustumCulled = source.perObjectFrustumCulled;
		this.sortObjects = source.sortObjects;
		this.boundingBox = source.boundingBox != null ? source.boundingBox?.clone() : null;
		this.boundingSphere = source.boundingSphere != null ? source.boundingSphere?.clone() : null;

		this._geometryInfo = source._geometryInfo.sublist(0);
    // .map( info => ( {
		// 	...info,

		// 	boundingBox: info.boundingBox !== null ? info.boundingBox.clone() : null,
		// 	boundingSphere: info.boundingSphere !== null ? info.boundingSphere.clone() : null,
		// } ) );
		this._instanceInfo = source._instanceInfo.sublist(0);//.map( info => ( { ...info } ) );

		this._maxInstanceCount = source._maxInstanceCount;
		this._maxVertexCount = source._maxVertexCount;
		this._maxIndexCount = source._maxIndexCount;

		this._geometryInitialized = source._geometryInitialized;
		this._geometryCount = source._geometryCount;
		this.multiDrawCounts = source.multiDrawCounts.sublist(0);
		this.multiDrawStarts = source.multiDrawStarts.sublist(0);

		this.matricesTexture = source.matricesTexture?.clone();
		this.matricesTexture?.image.data = this.matricesTexture?.image.data.slice();

		if ( this.colorsTexture != null ) {
			this.colorsTexture = source.colorsTexture?.clone();
			this.colorsTexture?.image.data = this.colorsTexture?.image.data.slice();
		}

		return this;
	}

  @override
	void dispose() {
    super.dispose();
		// Assuming the geometry is not shared with other meshes
		geometry?.dispose();

		matricesTexture?.dispose();
		matricesTexture = null;

		indirectTexture?.dispose();
		indirectTexture = null;

		colorsTexture?.dispose();
		colorsTexture = null;
	}

  @override
	OnBeforeRender? get onBeforeRender =>({
    WebGLRenderer? renderer,
    RenderTarget? renderTarget,
    Object3D? mesh,
    Scene? scene,
    Camera? camera,
    BufferGeometry? geometry,
    Material? material,
    Map<String, dynamic>? group
  }){
		// if visibility has not changed and frustum culling and object sorting is not required
		// then skip iterating over all items
		if ( ! this._visibilityChanged && ! this.perObjectFrustumCulled && ! this.sortObjects ) {
			return null;
		}

		// the indexed version of the multi draw function requires specifying the start
		// offset in bytes.
		final index = geometry!.getIndex();
		final bytesPerElement = index == null ? 1 : index.array.BYTES_PER_ELEMENT;

		final instanceInfo = _instanceInfo;
		final multiDrawStarts = this.multiDrawStarts;
		final multiDrawCounts = this.multiDrawCounts;
		final geometryInfoList = _geometryInfo;
		final perObjectFrustumCulled = this.perObjectFrustumCulled;
		final indirectTexture = this.indirectTexture;
		final indirectArray = indirectTexture?.image.data;

		// prepare the frustum in the local frame
		if ( perObjectFrustumCulled ) {

			_matrix.multiply2( camera!.projectionMatrix, camera.matrixWorldInverse )
				.multiply( this.matrixWorld );
			_frustum.setFromMatrix(
				_matrix,
				//renderer!.coordinateSystem
			);
		}

		int multiDrawCount = 0;
		if ( this.sortObjects ) {

			// get the camera position in the local frame
			_matrix.setFrom( this.matrixWorld ).invert();
			_vector.setFromMatrixPosition( camera!.matrixWorld ).applyMatrix4( _matrix );
			_forward.setValues( 0, 0, - 1 ).transformDirection( camera.matrixWorld ).transformDirection( _matrix );

			for (int i = 0, l = instanceInfo.length; i < l; i ++ ) {
				if ( instanceInfo[ i ].visible && instanceInfo[ i ].active ) {

					final geometryId = instanceInfo[ i ].geometryIndex;

					// get the bounds in world space
					this.getMatrixAt( i, _matrix );
					this.getBoundingSphereAt( geometryId, _sphere ).applyMatrix4( _matrix );

					// determine whether the batched geometry is within the frustum
					bool culled = false;
					if ( perObjectFrustumCulled ) {
						culled = ! _frustum.intersectsSphere( _sphere );
					}

					if ( ! culled ) {
						// get the distance from camera used for sorting
						final geometryInfo = geometryInfoList[ geometryId ];
						final z = _temp.sub2( _sphere.center, _vector ).dot( _forward );
						_renderList.push( geometryInfo.start, geometryInfo.count, z.toInt(), i );
					}
				}
			}

			// Sort the draw ranges and prep for rendering
			final list = _renderList.list;
			final customSort = this.customSort;
			if ( customSort == null ) {
				list.sort( material?.transparent != null? sortTransparent : sortOpaque );
			} else {
				customSort.call( this, list, camera );
			}

			for (int i = 0, l = list.length; i < l; i ++ ) {
				final item = list[ i ];
				multiDrawStarts[ multiDrawCount ] = item.start * bytesPerElement;
				multiDrawCounts[ multiDrawCount ] = item.count;
				indirectArray[ multiDrawCount ] = item.index;
				multiDrawCount ++;
			}

			_renderList.reset();

		} else {
			for ( int i = 0, l = instanceInfo.length; i < l; i ++ ) {
				if ( instanceInfo[ i ].visible && instanceInfo[ i ].active ) {

					final geometryId = instanceInfo[ i ].geometryIndex;

					// determine whether the batched geometry is within the frustum
					bool culled = false;
					if ( perObjectFrustumCulled ) {
						// get the bounds in world space
						this.getMatrixAt( i, _matrix );
						this.getBoundingSphereAt( geometryId, _sphere ).applyMatrix4( _matrix );
						culled = ! _frustum.intersectsSphere( _sphere );
					}

					if ( ! culled ) {
						final geometryInfo = geometryInfoList[ geometryId ];
						multiDrawStarts[ multiDrawCount ] = geometryInfo.start * bytesPerElement;
						multiDrawCounts[ multiDrawCount ] = geometryInfo.count;
						indirectArray[ multiDrawCount ] = i;
						multiDrawCount ++;
					}
				}
			}
		}

		indirectTexture?.needsUpdate = true;
		this.multiDrawCount = multiDrawCount;
		this._visibilityChanged = false;

    return null;
  };

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