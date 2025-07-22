import 'dart:typed_data';
import 'dart:convert';
import 'dart:math' as math;
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_core_loaders/three_js_core_loaders.dart';
import 'package:three_js_math/three_js_math.dart';

final _taskCache = WeakMap();

class _DracoAttributes{
  late String position;
  late String normal;
  late String color;
  late String uv;

  _DracoAttributes({
    required this.position,
    required this.normal,
    required this.color,
    required this.uv
  });

  factory _DracoAttributes.id({
    String position = 'POSITION',
    String normal = 'NORMAL',
    String color = 'COLOR',
    String uv = 'TEX_COORD'
  }){
    return _DracoAttributes(position: position, normal: normal, color: color, uv: uv);
  }

  factory _DracoAttributes.type({
    String position = 'Float32Array',
    String normal = 'Float32Array',
    String color = 'Float32Array',
    String uv = 'Float32Array'
  }){
    return _DracoAttributes(position: position, normal: normal, color: color, uv: uv);
  }
}

class DRACOLoader extends Loader {
  final jsonEncoder = JsonEncoder();
  String decoderPath = '';
  Map decoderConfig = {};
  var decoderBinary = null;
  var decoderPending = null;

  int workerLimit = 4;
  final List workerPool = [];
  int workerNextTaskID = 1;
  String workerSourceURL = '';

  final _DracoAttributes defaultAttributeIDs = _DracoAttributes.id();
  final _DracoAttributes defaultAttributeTypes = _DracoAttributes.type();

	DRACOLoader(super.manager );

	DRACOLoader setDecoderPath(String path ) {
		this.decoderPath = path;
		return this;
	}

	DRACOLoader setDecoderConfig(Map config ) {
		this.decoderConfig = config;
		return this;
	}

	DRACOLoader setWorkerLimit(int workerLimit ) {
		this.workerLimit = workerLimit;
		return this;
	}

	load( url, onLoad, onProgress, onError ) {
		final loader = new FileLoader( this.manager );

		loader.setPath( this.path );
		loader.setResponseType( 'arraybuffer' );
		loader.setRequestHeader( this.requestHeader );
		loader.setWithCredentials( this.withCredentials );

		loader.unknown( url).then( ( buffer ){
			this.parse( buffer, onLoad, onError );
		}).catchError(onError);
	}


	parse( buffer, onLoad, onError) {
		this.decodeDracoFile( buffer, onLoad, null, null, SRGBColorSpace, onError ).catchError( onError );
	}

	decodeDracoFile( buffer, callback, attributeIDs, attributeTypes, [String vertexColorSpace = LinearSRGBColorSpace, onError]) {
		final taskConfig = {
			'attributeIDs': attributeIDs ?? this.defaultAttributeIDs,
			'attributeTypes': attributeTypes ?? this.defaultAttributeTypes,
			'useUniqueIDs': !! attributeIDs,
			'vertexColorSpace': vertexColorSpace,
		};

		return this.decodeGeometry( buffer, taskConfig ).then( callback ).catchError( onError );
	}

	decodeGeometry( buffer, Map taskConfig ) {
		String taskKey = jsonEncoder.convert(taskConfig);//JSON.stringify( taskConfig );

		// Check for an existing task using this buffer. A transferred buffer cannot be transferred
		// again from this thread.
		if ( _taskCache.has( buffer ) ) {
			final cachedTask = _taskCache.get( buffer );

			if ( cachedTask.key == taskKey ) {
				return cachedTask.promise;
			} 
      else if ( buffer.byteLength == 0 ) {
				// Technically, it would be possible to wait for the previous task to complete,
				// transfer the buffer back, and decode again with the second configuration. That
				// is complex, and I don't know of any reason to decode a Draco buffer twice in
				// different ways, so this is left unimplemented.
				throw(
					'THREE.DRACOLoader: Unable to re-decode a buffer with different ' +
					'settings. Buffer has already been transferred.'
				);
			}
		}

		//
		Worker worker;
		final taskID = this.workerNextTaskID ++;
		final taskCost = buffer.byteLength;

		// Obtain a worker and assign a task, and finalruct a geometry instance
		// when the task completes.
		final geometryPending = this._getWorker( taskID, taskCost )
			.then( ( _worker ){
				worker = _worker;

				return new Promise( ( resolve, reject ){
					worker._callbacks[ taskID ] = { resolve, reject };
					worker.postMessage( { 'type': 'decode', 'id': taskID, 'taskConfig': taskConfig, "buffer": buffer }, [ buffer ] );
				} );
			} )
			.then( ( message ) => this._createGeometry( message.geometry ) );

		// Remove task from the task list.
		// Note: replaced '.finally()' with '.catch().then()' block - iOS 11 support (#19416)
		geometryPending
			.catch( () => true )
			.then( () => {
				if ( worker && taskID ) {
					this._releaseTask( worker, taskID );
					// this.debug();
				}
			} );

		// Cache the task result.
		_taskCache.set( buffer, {
			'key': taskKey,
			'promise': geometryPending
		} );

		return geometryPending;
	}

	BufferGeometry _createGeometry(Map geometryData ) {
		final geometry = new BufferGeometry();

		if ( geometryData['index'] != null) {
			geometry.setIndex( Uint8BufferAttribute.fromList( geometryData['index'].array, 1 ) );
		}

		for (int i = 0; i < geometryData['attributes'].length; i ++ ) {
			final result = geometryData['attributes'][ i ];
			final name = result.name;
			final array = result.array;
			final itemSize = result.itemSize;

			final attribute = Float32BufferAttribute.fromList( array, itemSize );

			if ( name == 'color' ) {
				this._assignVertexColorSpace( attribute, result.vertexColorSpace );
				attribute.normalized = ( array is Float32Array ) == false;
			}

			geometry.setAttribute( name, attribute );
		}

		return geometry;
	}

	void _assignVertexColorSpace(BufferAttribute attribute, String inputColorSpace ) {

		// While .drc files do not specify colorspace, the only 'official' tooling
		// is PLY and OBJ converters, which use sRGB. We'll assume sRGB when a .drc
		// file is passed into .load() or .parse(). GLTFLoader uses internal APIs
		// to decode geometry, and vertex colors are already Linear-sRGB in there.

		if ( inputColorSpace != SRGBColorSpace ) return;

		final _color = new Color();

		for (int i = 0, il = attribute.count; i < il; i ++ ) {
			_color.fromBuffer( attribute, i );
			ColorManagement.toWorkingColorSpace( _color, ColorSpace.srgb );
			attribute.setXYZ( i, _color.red, _color.green, _color.blue );
		}
	}

	Future<> _loadLibrary(String url, String responseType ) async{
		final loader = new FileLoader( this.manager );
		loader.setPath( this.decoderPath );
		loader.setResponseType( responseType );
		loader.setWithCredentials( this.withCredentials );

		return await loader.unknown( url);//, resolve, undefined, reject );
	}

	preload() {
		this._initDecoder();
		return this;
	}

	_initDecoder() {
		if ( this.decoderPending ) return this.decoderPending;

		final useJS = typeof WebAssembly != 'object' || this.decoderConfig.type == 'js';
		final librariesPending = [];

		if ( useJS ) {
			librariesPending.add( this._loadLibrary( 'draco_decoder.js', 'text' ) );
		} else {
			librariesPending.add( this._loadLibrary( 'draco_wasm_wrapper.js', 'text' ) );
			librariesPending.add( this._loadLibrary( 'draco_decoder.wasm', 'arraybuffer' ) );
		}

		this.decoderPending = Promise.all( librariesPending ).then( ( libraries ){
				final jsContent = libraries[ 0 ];

				if ( ! useJS ) {
					this.decoderConfig['wasmBinary'] = libraries[ 1 ];
				}

				final fn = DRACOWorker.toString();

				final body = [
					'/* draco decoder */',
					jsContent,
					'',
					'/* worker */',
					fn.substring( fn.indexOf( '{' ) + 1, fn.lastIndexOf( '}' ) )
				].join( '\n' );

				this.workerSourceURL = URL.createObjectURL( new Blob( [ body ] ) );
			} );

		return this.decoderPending;
	}

	_getWorker( taskID, taskCost ) {

		return this._initDecoder().then( (){

			if ( this.workerPool.length < this.workerLimit ) {

				final worker = new Worker( this.workerSourceURL );

				worker._callbacks = {};
				worker._taskCosts = {};
				worker._taskLoad = 0;

				worker.postMessage( { 'type': 'init', 'decoderConfig': this.decoderConfig } );

				worker.onmessage = ( e ) {
					final message = e.data;

					switch ( message.type ) {
						case 'decode':
							worker._callbacks[ message.id ].resolve( message );
							break;
						case 'error':
							worker._callbacks[ message.id ].reject( message );
							break;
						default:
							console.error( 'THREE.DRACOLoader: Unexpected message, "' + message.type + '"' );
					}
				};

				this.workerPool.add( worker );
			} 
      else {
				this.workerPool.sort( ( a, b ) {
					return a._taskLoad > b._taskLoad ? - 1 : 1;
				});
			}

			final worker = this.workerPool[ this.workerPool.length - 1 ];
			worker._taskCosts[ taskID ] = taskCost;
			worker._taskLoad += taskCost;
			return worker;

		} );

	}

	_releaseTask(Map worker, taskID ) {
		worker['_taskLoad'] = worker['_taskLoad']-worker['_taskCosts'][ taskID ];
		worker._callbacks[ taskID ];
		worker._taskCosts[ taskID ];
	}

	debug() {
		console.verbose( 'Task load: ${this.workerPool.map( ( worker ) => worker['_taskLoad'] )}');
	}

	DRACOLoader dispose() {
		for (int i = 0; i < this.workerPool.length; ++ i ) {
			this.workerPool[ i ].terminate();
		}

		this.workerPool.length = 0;
		if ( this.workerSourceURL != '' ) {
			URL.revokeObjectURL( this.workerSourceURL );
		}

		return this;
	}
}

/* WEB WORKER */

DRACOWorker() {
	let decoderConfig;
	let decoderPending;

	onmessage = ( e ) {

		final message = e.data;

		switch ( message.type ) {

			case 'init':
				decoderConfig = message.decoderConfig;
				decoderPending = new Promise( ( resolve/*, reject*/ ) {

					decoderConfig.onModuleLoaded = ( draco ) {

						// Module is Promise-like. Wrap before resolving to avoid loop.
						resolve( { draco: draco } );

					};

					DracoDecoderModule( decoderConfig ); // eslint-disable-line no-undef

				} );
				break;

			case 'decode':
				final buffer = message.buffer;
				final taskConfig = message.taskConfig;
				decoderPending.then( ( module ){

					final draco = module.draco;
					final decoder = draco.Decoder();

					try {
						final geometry = decodeGeometry( draco, decoder, new Int8Array( buffer ), taskConfig );
						final buffers = geometry.attributes.map( ( attr ) => attr.array.buffer );

						if ( geometry.index ) buffers.push( geometry.index.array.buffer );
						print( { 'type': 'decode', 'id': message.id, 'geometry':geometry }, buffers );
					} 
          catch ( error ) {
						console.error( error );
						print( { 'type': 'error', 'id': message.id, 'error': error.message } );
					} finally {
						draco.destroy( decoder );
					}
				} );
				break;
		}
	};
	Map<String,dynamic> decodeIndex( draco, decoder, dracoGeometry ) {

		final numFaces = dracoGeometry.num_faces();
		final numIndices = numFaces * 3;
		final byteLength = numIndices * 4;

		final ptr = draco._malloc( byteLength );
		decoder.GetTrianglesUInt32Array( dracoGeometry, byteLength, ptr );
		final index = new Uint32Array( draco.HEAPF32.buffer, ptr, numIndices ).slice();
		draco._free( ptr );

		return { 'array': index, 'itemSize': 1 };

	}

	getDracoDataType( draco, attributeType ) {
		switch ( attributeType ) {
			case Float32Array: return draco.DT_FLOAT32;
			case Int8Array: return draco.DT_INT8;
			case Int16Array: return draco.DT_INT16;
			case Int32Array: return draco.DT_INT32;
			case Uint8Array: return draco.DT_UINT8;
			case Uint16Array: return draco.DT_UINT16;
			case Uint32Array: return draco.DT_UINT32;
		}
	}

	Map<String,dynamic> decodeAttribute( draco, decoder, dracoGeometry, attributeName, attributeType, attribute ) {
		final numComponents = attribute.num_components();
		final numPoints = dracoGeometry.num_points();
		final numValues = numPoints * numComponents;
		final byteLength = numValues * attributeType.BYTES_PER_ELEMENT;
		final dataType = getDracoDataType( draco, attributeType );

		final ptr = draco._malloc( byteLength );
		decoder.GetAttributeDataArrayForAllPoints( dracoGeometry, attribute, dataType, byteLength, ptr );
		final array = attributeType( draco.HEAPF32.buffer, ptr, numValues ).slice();
		draco._free( ptr );

		return {
			'name': attributeName,
			'array': array,
			'itemSize': numComponents
		};
	}

	decodeGeometry( draco, decoder, array, Map taskConfig ) {
		final attributeIDs = taskConfig['attributeIDs'];
		final attributeTypes = taskConfig['attributeTypes'];

		dynamic dracoGeometry;
		dynamic decodingStatus;

		final geometryType = decoder.GetEncodedGeometryType( array );

		if ( geometryType == draco.TRIANGULAR_MESH ) {
			dracoGeometry = draco.Mesh();
			decodingStatus = decoder.DecodeArrayToMesh( array, array.byteLength, dracoGeometry );
		} else if ( geometryType == draco.POINT_CLOUD ) {
			dracoGeometry = draco.PointCloud();
			decodingStatus = decoder.DecodeArrayToPointCloud( array, array.byteLength, dracoGeometry );
		} else {
			throw( 'THREE.DRACOLoader: Unexpected geometry type.' );
		}

		if ( ! decodingStatus.ok() || dracoGeometry.ptr == 0 ) {
			throw( 'THREE.DRACOLoader: Decoding failed: ' + decodingStatus.error_msg() );
		}

		final geometry = { 'index': null, 'attributes': [] };

		// Gather all vertex attributes.
		for ( final attributeName in attributeIDs ) {
			final attributeType = attributeTypes[ attributeName ];

			BufferAttribute attribute;
			dynamic attributeID;

			// A Draco file may be created with default vertex attributes, whose attribute IDs
			// are mapped 1:1 from their semantic name (POSITION, NORMAL, ...). Alternatively,
			// a Draco file may contain a custom set of attributes, identified by known unique
			// IDs. glTF files always do the latter, and `.drc` files typically do the former.
			if ( taskConfig['useUniqueIDs'] != null) {
				attributeID = attributeIDs[ attributeName ];
				attribute = decoder.GetAttributeByUniqueId( dracoGeometry, attributeID );
			} 
      else {
				attributeID = decoder.GetAttributeId( dracoGeometry, draco[ attributeIDs[ attributeName ] ] );

				if ( attributeID == - 1 ) continue;
				attribute = decoder.GetAttribute( dracoGeometry, attributeID );
			}

			final attributeResult = decodeAttribute( draco, decoder, dracoGeometry, attributeName, attributeType, attribute );

			if ( attributeName == 'color' ) {
				attributeResult['vertexColorSpace'] = taskConfig['vertexColorSpace'];
			}

			geometry['attributes']?.add( attributeResult );
		}

		// Add index.
		if ( geometryType == draco.TRIANGULAR_MESH ) {
			geometry['index'] = decodeIndex( draco, decoder, dracoGeometry );
		}

		draco.destroy( dracoGeometry );
		return geometry;
	}
}
