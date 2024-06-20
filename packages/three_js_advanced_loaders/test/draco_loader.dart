
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_core_loaders/three_js_core_loaders.dart';

final _taskCache = WeakMap();

class DRACOLoader extends Loader {

	DRACOLoader([super.manager]) {
		this.decoderPath = '';
		this.decoderConfig = {};
		this.decoderBinary = null;
		this.decoderPending = null;

		this.workerLimit = 4;
		this.workerPool = [];
		this.workerNextTaskID = 1;
		this.workerSourceURL = '';

		this.defaultAttributeIDs = {
			position: 'POSITION',
			normal: 'NORMAL',
			color: 'COLOR',
			uv: 'TEX_COORD'
		};
		this.defaultAttributeTypes = {
			position: 'Float32Array',
			normal: 'Float32Array',
			color: 'Float32Array',
			uv: 'Float32Array'
		};

	}

	DRACOLoader setDecoderPath( path ) {
		this.decoderPath = path;
		return this;
	}

	DRACOLoader setDecoderConfig( config ) {
		this.decoderConfig = config;
		return this;
	}

	DRACOLoader setWorkerLimit( workerLimit ) {
		this.workerLimit = workerLimit;
		return this;
	}

	load( url, onLoad, onProgress, onError ) {
		const loader = FileLoader( this.manager );

		loader.setPath( this.path );
		loader.setResponseType( 'arraybuffer' );
		loader.setRequestHeader( this.requestHeader );
		loader.setWithCredentials( this.withCredentials );

		loader.load( url, ( buffer ) => {

			this.parse( buffer, onLoad, onError );

		}, onProgress, onError );
	}


	parse( buffer, onLoad, onError = ()=>{} ) {
		this.decodeDracoFile( buffer, onLoad, null, null, SRGBColorSpace ).catch( onError );
	}

	decodeDracoFile( buffer, callback, attributeIDs, attributeTypes, vertexColorSpace = LinearSRGBColorSpace, onError = () => {} ) {
		const taskConfig = {
			attributeIDs: attributeIDs || this.defaultAttributeIDs,
			attributeTypes: attributeTypes || this.defaultAttributeTypes,
			useUniqueIDs: !! attributeIDs,
			vertexColorSpace: vertexColorSpace,
		};

		return this.decodeGeometry( buffer, taskConfig ).then( callback ).catch( onError );
	}

	decodeGeometry( buffer, taskConfig ) {
		const taskKey = JSON.stringify( taskConfig );

		// Check for an existing task using this buffer. A transferred buffer cannot be transferred
		// again from this thread.
		if ( _taskCache.has( buffer ) ) {
			const cachedTask = _taskCache.get( buffer );

			if ( cachedTask.key == taskKey ) {
				return cachedTask.promise;
			} else if ( buffer.byteLength == 0 ) {
				// Technically, it would be possible to wait for the previous task to complete,
				// transfer the buffer back, and decode again with the second configuration. That
				// is complex, and I don't know of any reason to decode a Draco buffer twice in
				// different ways, so this is left unimplemented.
				throw(
					'DRACOLoader: Unable to re-decode a buffer with different ' +
					'settings. Buffer has already been transferred.'
				);
			}
		}

		//

		let worker;
		const taskID = this.workerNextTaskID ++;
		const taskCost = buffer.byteLength;

		// Obtain a worker and assign a task, and construct a geometry instance
		// when the task completes.
		final geometryPending = _getWorker( taskID, taskCost )
			.then( ( _worker ){

				worker = _worker;

				return Promise(( resolve, reject ){

					worker._callbacks[ taskID ] = { resolve, reject };

					worker.postMessage( { type: 'decode', id: taskID, taskConfig, buffer }, [ buffer ] );

					// this.debug();
				});
			} ).then( ( message ) => _createGeometry( message.geometry ) );

		// Remove task from the task list.
		// Note: replaced '.finally()' with '.catch().then()' block - iOS 11 support (#19416)
		geometryPending
			.catch( () => true )
			.then( (){
				if ( worker && taskID ) {
					_releaseTask( worker, taskID );
					// this.debug();
				}
			});

		// Cache the task result.
		_taskCache.set( buffer, {
			'key': taskKey,
			'promise': geometryPending
		} );

		return geometryPending;
	}

	_createGeometry( geometryData ) {
		final geometry = BufferGeometry();

		if ( geometryData.index ) {
			geometry.setIndex( BufferAttribute( geometryData.index.array, 1 ) );
		}

		for ( int i = 0; i < geometryData.attributes.length; i ++ ) {
			const result = geometryData.attributes[ i ];
			const name = result.name;
			const array = result.array;
			const itemSize = result.itemSize;

			const attribute = BufferAttribute( array, itemSize );

			if ( name == 'color' ) {
				_assignVertexColorSpace( attribute, result.vertexColorSpace );
				attribute.normalized = ( array instanceof Float32Array ) == false;
			}

			geometry.setAttribute( name, attribute );

		}

		return geometry;
	}

	_assignVertexColorSpace( attribute, inputColorSpace ) {
		// While .drc files do not specify colorspace, the only 'official' tooling
		// is PLY and OBJ converters, which use sRGB. We'll assume sRGB when a .drc
		// file is passed into .load() or .parse(). GLTFLoader uses internal APIs
		// to decode geometry, and vertex colors are already Linear-sRGB in there.

		if ( inputColorSpace != SRGBColorSpace ) return;

		const _color = Color();

		for (int i = 0, il = attribute.count; i < il; i ++ ) {
			_color.fromBufferAttribute( attribute, i ).convertSRGBToLinear();
			attribute.setXYZ( i, _color.r, _color.g, _color.b );
		}
	}

	_loadLibrary( url, responseType ) {
		const loader = FileLoader( this.manager );
		loader.setPath( this.decoderPath );
		loader.setResponseType( responseType );
		loader.setWithCredentials( this.withCredentials );

		return Promise( ( resolve, reject ) => {
			loader.load( url, resolve, undefined, reject );
		});
	}

	preload() {
		_initDecoder();
		return this;
	}

	_initDecoder() {
		if ( this.decoderPending ) return this.decoderPending;

		const useJS = typeof WebAssembly != 'object' || this.decoderConfig.type == 'js';
		const librariesPending = [];

		if ( useJS ) {
			librariesPending.add( this._loadLibrary( 'draco_decoder.js', 'text' ) );
		} else {
			librariesPending.add( this._loadLibrary( 'draco_wasm_wrapper.js', 'text' ) );
			librariesPending.add( this._loadLibrary( 'draco_decoder.wasm', 'arraybuffer' ) );
		}

		this.decoderPending = Promise.all( librariesPending )
			.then( ( libraries ) => {

				const jsContent = libraries[ 0 ];

				if ( ! useJS ) {

					this.decoderConfig.wasmBinary = libraries[ 1 ];

				}

				const fn = DRACOWorker.toString();

				const body = [
					'/* draco decoder */',
					jsContent,
					'',
					'/* worker */',
					fn.substring( fn.indexOf( '{' ) + 1, fn.lastIndexOf( '}' ) )
				].join( '\n' );

				this.workerSourceURL = URL.createObjectURL( Blob( [ body ] ) );

			} );

		return this.decoderPending;

	}

	_getWorker( taskID, taskCost ) {
		return this._initDecoder().then( () => {

			if ( this.workerPool.length < this.workerLimit ) {
				const worker = Worker( this.workerSourceURL );

				worker._callbacks = {};
				worker._taskCosts = {};
				worker._taskLoad = 0;

				worker.postMessage( { type: 'init', decoderConfig: this.decoderConfig } );

				worker.onmessage = function ( e ) {

					const message = e.data;

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

			} else {
				this.workerPool.sort( function ( a, b ) {
					return a._taskLoad > b._taskLoad ? - 1 : 1;
				});
			}

			const worker = this.workerPool[ this.workerPool.length - 1 ];
			worker._taskCosts[ taskID ] = taskCost;
			worker._taskLoad += taskCost;
			return worker;
		});
	}

	_releaseTask( worker, taskID ) {
		worker._taskLoad -= worker._taskCosts[ taskID ];
		delete worker._callbacks[ taskID ];
		delete worker._taskCosts[ taskID ];
	}

	debug() {
		console.log( 'Task load: ', this.workerPool.map( ( worker ) => worker._taskLoad ) );
	}

	dispose() {
		for ( int i = 0; i < this.workerPool.length; ++ i ) {
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

function DRACOWorker() {
	let decoderConfig;
	let decoderPending;

	onmessage = function ( e ) {

		const message = e.data;

		switch ( message.type ) {
			case 'init':
				decoderConfig = message.decoderConfig;
				decoderPending = Promise( function ( resolve/*, reject*/ ) {
					decoderConfig.onModuleLoaded = function ( draco ) {
						// Module is Promise-like. Wrap before resolving to avoid loop.
						resolve( { draco: draco } );
					};

					DracoDecoderModule( decoderConfig ); // eslint-disable-line no-undef
				});
				break;

			case 'decode':
				const buffer = message.buffer;
				const taskConfig = message.taskConfig;
				decoderPending.then( ( module ){

					const draco = module.draco;
					const decoder = draco.Decoder();

					try {
						const geometry = decodeGeometry( draco, decoder, Int8Array( buffer ), taskConfig );
						const buffers = geometry.attributes.map( ( attr ) => attr.array.buffer );
						if ( geometry.index ) buffers.add( geometry.index.array.buffer );
						self.postMessage( { type: 'decode', id: message.id, geometry }, buffers );
					} catch ( error ) {
						console.error( error );
						self.postMessage( { type: 'error', id: message.id, error: error.message } );
					} finally {
						draco.destroy( decoder );
					}
				});
				break;

		}
	};

	function decodeGeometry( draco, decoder, array, taskConfig ) {
		const attributeIDs = taskConfig.attributeIDs;
		const attributeTypes = taskConfig.attributeTypes;

		let dracoGeometry;
		let decodingStatus;

		const geometryType = decoder.GetEncodedGeometryType( array );

		if ( geometryType == draco.TRIANGULAR_MESH ) {

			dracoGeometry = draco.Mesh();
			decodingStatus = decoder.DecodeArrayToMesh( array, array.byteLength, dracoGeometry );

		} else if ( geometryType == draco.POINT_CLOUD ) {
			dracoGeometry = draco.PointCloud();
			decodingStatus = decoder.DecodeArrayToPointCloud( array, array.byteLength, dracoGeometry );
		} else {
			throw( 'DRACOLoader: Unexpected geometry type.' );
		}

		if ( ! decodingStatus.ok() || dracoGeometry.ptr == 0 ) {
			throw( 'DRACOLoader: Decoding failed: ' + decodingStatus.error_msg() );
		}

		const geometry = { index: null, attributes: [] };

		// Gather all vertex attributes.
		for ( const attributeName in attributeIDs ) {

			const attributeType = self[ attributeTypes[ attributeName ] ];

			let attribute;
			let attributeID;

			// A Draco file may be created with default vertex attributes, whose attribute IDs
			// are mapped 1:1 from their semantic name (POSITION, NORMAL, ...). Alternatively,
			// a Draco file may contain a custom set of attributes, identified by known unique
			// IDs. glTF files always do the latter, and `.drc` files typically do the former.
			if ( taskConfig.useUniqueIDs ) {

				attributeID = attributeIDs[ attributeName ];
				attribute = decoder.GetAttributeByUniqueId( dracoGeometry, attributeID );

			} else {
				attributeID = decoder.GetAttributeId( dracoGeometry, draco[ attributeIDs[ attributeName ] ] );
				if ( attributeID == - 1 ) continue;
				attribute = decoder.GetAttribute( dracoGeometry, attributeID );
			}

			const attributeResult = decodeAttribute( draco, decoder, dracoGeometry, attributeName, attributeType, attribute );
			if ( attributeName == 'color' ) {
				attributeResult.vertexColorSpace = taskConfig.vertexColorSpace;
			}

			geometry.attributes.add( attributeResult );

		}

		// Add index.
		if ( geometryType == draco.TRIANGULAR_MESH ) {
			geometry.index = decodeIndex( draco, decoder, dracoGeometry );
		}

		draco.destroy( dracoGeometry );

		return geometry;
	}

	function decodeIndex( draco, decoder, dracoGeometry ) {
		const numFaces = dracoGeometry.num_faces();
		const numIndices = numFaces * 3;
		const byteLength = numIndices * 4;

		const ptr = draco._malloc( byteLength );
		decoder.GetTrianglesUInt32Array( dracoGeometry, byteLength, ptr );
		const index = Uint32Array( draco.HEAPF32.buffer, ptr, numIndices ).slice();
		draco._free( ptr );

		return { array: index, itemSize: 1 };
	}

	function decodeAttribute( draco, decoder, dracoGeometry, attributeName, attributeType, attribute ) {
		const numComponents = attribute.num_components();
		const numPoints = dracoGeometry.num_points();
		const numValues = numPoints * numComponents;
		const byteLength = numValues * attributeType.BYTES_PER_ELEMENT;
		const dataType = getDracoDataType( draco, attributeType );

		const ptr = draco._malloc( byteLength );
		decoder.GetAttributeDataArrayForAllPoints( dracoGeometry, attribute, dataType, byteLength, ptr );
		const array = attributeType( draco.HEAPF32.buffer, ptr, numValues ).slice();
		draco._free( ptr );

		return {
			name: attributeName,
			array: array,
			itemSize: numComponents
		};
	}

	function getDracoDataType( draco, attributeType ) {
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
}
