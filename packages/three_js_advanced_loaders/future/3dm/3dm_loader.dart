import 'dart:math' as math;
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_core_loaders/three_js_core_loaders.dart';
import 'package:three_js_math/three_js_math.dart';

final _taskCache = new WeakMap();

class Rhino3dmLoader extends Loader {
  String libraryPath = '';
  dynamic libraryPending;
  dynamic libraryBinary;
  Map libraryConfig = {};

  String url = '';

  int workerLimit = 4;
  List workerPool = [];
  int workerNextTaskID = 1;
  String workerSourceURL = '';
  Map workerConfig = {};

  List materials = [];
	List warnings = [];

	Rhino3dmLoader([super.manager]);

	Rhino3dmLoader setLibraryPath( path ) {
		this.libraryPath = path;
		return this;
	}

	Rhino3dmLoader setWorkerLimit( workerLimit ) {
		this.workerLimit = workerLimit;
		return this;
	}

	load( url, onLoad, onProgress, onError ) {

		final loader = new FileLoader( this.manager );

		loader.setPath( this.path );
		loader.setResponseType( 'arraybuffer' );
		loader.setRequestHeader( this.requestHeader );

		this.url = url;

		loader.unknown( url).then(( buffer ){

			// Check for an existing task using this buffer. A transferred buffer cannot be transferred
			// again from this thread.
			if ( _taskCache.has( buffer ) ) {
				final cachedTask = _taskCache.get( buffer );
				return cachedTask.promise.then( onLoad ).catch( onError );
			}

			this.decodeObjects( buffer, url )
				.then((result){

					result.userData.warnings = this.warnings;
					onLoad( result );

				 })
				.catch( e => onError( e ) );

		}, onProgress, onError );

	}

	void debug() {
		console.info( 'Task load: ${this.workerPool.map( ( worker ) => worker._taskLoad )}');
	}

	decodeObjects( buffer, url ) {
		let worker;
		let taskID;

		final taskCost = buffer.byteLength;

		final objectPending = this._getWorker( taskCost )
			.then( ( _worker ){

				worker = _worker;
				taskID = this.workerNextTaskID ++;

				return new Promise( ( resolve, reject ){
					worker._callbacks[ taskID ] = { resolve, reject };
					worker.postMessage( { 'type': 'decode', 'id': taskID, 'buffer':buffer }, [ buffer ] );

					// this.debug();
				} );

			} )
			.then( ( message ) => this._createGeometry( message.data ) )
			.catch( e => {

				throw e;

			} );

		// Remove task from the task list.
		// Note: replaced '.finally()' with '.catch().then()' block - iOS 11 support (#19416)
		objectPending
			.catch( () => true )
			.then( () => {

				if ( worker && taskID ) {

					this._releaseTask( worker, taskID );

					//this.debug();

				}

			} );

		// Cache the task result.
		_taskCache.set( buffer, {
			'url': url,
			'promise': objectPending
		} );

		return objectPending;
	}

	void parse( data, onLoad, onError ) {

		this.decodeObjects( data, '' )
			.then( result => {

				result.userData.warnings = this.warnings;
				onLoad( result );

			} )
			.catch( e => onError( e ) );

	}

	_compareMaterials(Material material ) {
		final mat = Material();
		mat.name = material.name;
		mat.color.red = material.color.red;
		mat.color.green = material.color.green;
		mat.color.blue = material.color.blue;
		mat.type = material.type;
		mat.vertexColors = material.vertexColors;

		final json = JSON.stringify( mat );

		for (int i = 0; i < this.materials.length; i ++ ) {
			final m = this.materials[ i ];
			final _mat = Material();
			_mat.name = m.name;
			_mat.color.red = m.color.r;
			_mat.color.green = m.color.g;
			_mat.color.blue = m.color.b;
			_mat.type = m.type;
			_mat.vertexColors = m.vertexColors;

			if ( JSON.stringify( _mat ) == json ) {
				return m;
			}
		}

		this.materials.add( material );

		return material;
	}

	Material _createMaterial([Material? material, renderEnvironment ]) {

		if ( material == null ) {
			return new MeshStandardMaterial.fromMap( {
				'color': Color( 1, 1, 1 ),
				'metalness': 0.8,
				'name': '__DEFAULT',
				'side': DoubleSide
			} );
		}

		//console.log(material)

		final mat = new MeshPhysicalMaterial.fromMap( {
			'color': new Color( material.diffuseColor.r / 255.0, material.diffuseColor.g / 255.0, material.diffuseColor.b / 255.0 ),
			'emissive': new Color( material.emissionColor.r, material.emissionColor.g, material.emissionColor.b ),
			'flatShading': material.disableLighting,
			'ior': material.indexOfRefraction,
			'name': material.name,
			'reflectivity': material.reflectivity,
			'opacity': 1.0 - material.transparency,
			'side': DoubleSide,
			'specularColor': material.specularColor,
			'transparent': material.transparency > 0 ? true : false
		} );

		mat.userData['id'] = material.id;

		if ( material.pbrSupported ) {
			final pbr = material.pbr;

			mat.anisotropy = pbr.anisotropic;
			mat.anisotropyRotation = pbr.anisotropicRotation;
			mat.color = new Color( pbr.baseColor.r, pbr.baseColor.g, pbr.baseColor.b );
			mat.clearcoat = pbr.clearcoat;
			mat.clearcoatRoughness = pbr.clearcoatRoughness;
			mat.metalness = pbr.metallic;
			mat.transmission = 1 - pbr.opacity;
			mat.roughness = pbr.roughness;
			mat.sheen = pbr.sheen;
			mat.specularIntensity = pbr.specular;
			mat.thickness = pbr.subsurface;
		}

		if ( material.pbrSupported && material.pbr.opacity == 0 && material.transparency == 1 ) {
			//some compromises

			mat.opacity = 0.2;
			mat.transmission = 1.00;
		}

		final textureLoader = new TextureLoader();

		for (int i = 0; i < material.textures.length; i ++ ) {
			final texture = material.textures[ i ];

			if ( texture.image != null ) {
				final map = textureLoader.load( texture.image );

				//console.log(texture.type )

				switch ( texture.type ) {
					case 'Bump':
						mat.bumpMap = map;
						break;
					case 'Diffuse':
						mat.map = map;
						break;
					case 'Emap':
						mat.envMap = map;
						break;
					case 'Opacity':
						mat.transmissionMap = map;
						break;
					case 'Transparency':
						mat.alphaMap = map;
						mat.transparent = true;
						break;
					case 'PBR_Alpha':
						mat.alphaMap = map;
						mat.transparent = true;
						break;
					case 'PBR_AmbientOcclusion':
						mat.aoMap = map;
						break;
					case 'PBR_Anisotropic':
						mat.anisotropyMap = map;
						break;
					case 'PBR_BaseColor':
						mat.map = map;
						break;
					case 'PBR_Clearcoat':
						mat.clearcoatMap = map;
						break;
					case 'PBR_ClearcoatBump':
						mat.clearcoatNormalMap = map;
						break;
					case 'PBR_ClearcoatRoughness':
						mat.clearcoatRoughnessMap = map;
						break;
					case 'PBR_Displacement':
						mat.displacementMap = map;
						break;
					case 'PBR_Emission':
						mat.emissiveMap = map;
						break;
					case 'PBR_Metallic':
						mat.metalnessMap = map;
						break;
					case 'PBR_Roughness':
						mat.roughnessMap = map;
						break;
					case 'PBR_Sheen':
						mat.sheenColorMap = map;
						break;
					case 'PBR_Specular':
						mat.specularColorMap = map;
						break;
					case 'PBR_Subsurface':
						mat.thicknessMap = map;
						break;
					default:
						this.warnings.add( {
							'message': 'THREE.3DMLoader: No conversion exists for 3dm ${texture.type}.',
							'type': 'no conversion'
						} );
						break;
				}

				map.wrapS = texture.wrapU == 0 ? RepeatWrapping : ClampToEdgeWrapping;
				map.wrapT = texture.wrapV == 0 ? RepeatWrapping : ClampToEdgeWrapping;

				if ( texture.repeat ) {

					map.repeat.set( texture.repeat[ 0 ], texture.repeat[ 1 ] );

				}

			}

		}

		if ( renderEnvironment != null) {
			new EXRLoader().load( renderEnvironment.image, ( texture ) {
				texture.mapping = EquirectangularReflectionMapping;
				mat.envMap = texture;
			} );
		}

		return mat;
	}

	_createGeometry( data ) {

		final object = new Object3D();
		final instanceDefinitionObjects = [];
		final instanceDefinitions = [];
		final instanceReferences = [];

		object.userData[ 'layers' ] = data.layers;
		object.userData[ 'groups' ] = data.groups;
		object.userData[ 'settings' ] = data.settings;
		object.userData['settings'][ 'renderSettings' ] = data.renderSettings;
		object.userData[ 'objectType' ] = 'File3dm';
		object.userData[ 'materials' ] = null;

		object.name = this.url;

		dynamic objects = data.objects;
		final materials = data.materials;

		for (int i = 0; i < objects.length; i ++ ) {
			final obj = objects[ i ];
			final attributes = obj.attributes;

			switch ( obj.objectType ) {
				case 'InstanceDefinition':
					instanceDefinitions.add( obj );
					break;
				case 'InstanceReference':
					instanceReferences.add( obj );
					break;
				default:
					dynamic matId = null;

					switch ( attributes.materialSource.name ) {
						case 'ObjectMaterialSource_MaterialFromLayer':
							//check layer index
							if ( attributes.layerIndex >= 0 ) {
								matId = data.layers[ attributes.layerIndex ].renderMaterialIndex;
							}
							break;
						case 'ObjectMaterialSource_MaterialFromObject':
							if ( attributes.materialIndex >= 0 ) {
								matId = attributes.materialIndex;
							}
							break;
					}

					dynamic material = null;

					if ( matId >= 0 ) {
						final rMaterial = materials[ matId ];
						material = this._createMaterial( rMaterial, data.renderEnvironment );
					}

					final _object = this._createObject( obj, material );

					if ( _object == null ) {
						continue;
					}

					final layer = data.layers[ attributes.layerIndex ];

					_object.visible = layer ? data.layers[ attributes.layerIndex ].visible : true;
					if ( attributes.isInstanceDefinitionObject ) {
						instanceDefinitionObjects.add( _object );
					} else {
						object.add( _object );
					}

					break;
			}
		}

		for (int i = 0; i < instanceDefinitions.length; i ++ ) {
			final iDef = instanceDefinitions[ i ];
			objects = [];

			for (int j = 0; j < iDef.attributes.objectIds.length; j ++ ) {

				final objId = iDef.attributes.objectIds[ j ];

				for (int p = 0; p < instanceDefinitionObjects.length; p ++ ) {
					final idoId = instanceDefinitionObjects[ p ].userData.attributes.id;
					if ( objId == idoId ) {
						objects.add( instanceDefinitionObjects[ p ] );
					}
				}
			}

			// Currently clones geometry and does not take advantage of instancing

			for (int j = 0; j < instanceReferences.length; j ++ ) {
				final iRef = instanceReferences[ j ];

				if ( iRef.geometry.parentIdefId == iDef.attributes.id ) {
					final iRefObject = new Object3D();
					final xf = iRef.geometry.xform.array;

					final matrix = new Matrix4();
					matrix.storage.set(xf);

					iRefObject.applyMatrix4( matrix );

					for (int p = 0; p < objects.length; p ++ ) {
						iRefObject.add( objects[ p ].clone( true ) );
					}
					object.add( iRefObject );
				}
			}
		}

		object.userData[ 'materials' ] = this.materials;
		object.name = '';
		return object;

	}

	_createObject( obj, mat ) {
		final loader = BufferGeometryLoader();
		final attributes = obj.attributes;

		let geometry, material, _color, color;

		switch ( obj.objectType ) {
			case 'Point':
			case 'PointSet':
				geometry = loader.parse( obj.geometry );
				if ( geometry.attributes.hasOwnProperty( 'color' ) ) {
					material = new PointsMaterial.fromMap( { 'vertexColors': true, 'sizeAttenuation': false, 'size': 2 } );
				} else {
					_color = attributes.drawColor;
					color = new Color( _color.r / 255.0, _color.g / 255.0, _color.b / 255.0 );
					material = new PointsMaterial.fromMap( { 'color': color, 'sizeAttenuation': false, 'size': 2 } );
				}

				material = this._compareMaterials( material );

				final points = new Points( geometry, material );
				points.userData[ 'attributes' ] = attributes;
				points.userData[ 'objectType' ] = obj.objectType;

				if ( attributes.name ) {
					points.name = attributes.name;
				}

				return points;

			case 'Mesh':
			case 'Extrusion':
			case 'SubD':
			case 'Brep':
				if ( obj.geometry == null ) return;
				geometry = loader.parse( obj.geometry );

				if ( mat == null ) {
					mat = this._createMaterial();
				}

				if ( geometry.attributes.hasOwnProperty( 'color' ) ) {
					mat.vertexColors = true;
				}

				mat = this._compareMaterials( mat );

				final mesh = new Mesh( geometry, mat );
				mesh.castShadow = attributes.castsShadows;
				mesh.receiveShadow = attributes.receivesShadows;
				mesh.userData[ 'attributes' ] = attributes;
				mesh.userData[ 'objectType' ] = obj.objectType;

				if ( attributes.name ) {
					mesh.name = attributes.name;
				}

				return mesh;

			case 'Curve':

				geometry = loader.parse( obj.geometry );

				_color = attributes.drawColor;
				color = new Color( _color.r / 255.0, _color.g / 255.0, _color.b / 255.0 );

				material = new LineBasicMaterial( { color: color } );
				material = this._compareMaterials( material );

				final lines = new Line( geometry, material );
				lines.userData[ 'attributes' ] = attributes;
				lines.userData[ 'objectType' ] = obj.objectType;

				if ( attributes.name ) {

					lines.name = attributes.name;

				}

				return lines;

			case 'TextDot':

				geometry = obj.geometry;

				final ctx = document.createElement( 'canvas' ).getContext( '2d' );
				final font = '${geometry.fontHeight}px ${geometry.fontFace}';
				ctx.font = font;
				final width = ctx.measureText( geometry.text ).width + 10;
				final height = geometry.fontHeight + 10;

				final r = window.devicePixelRatio;

				ctx.canvas.width = width * r;
				ctx.canvas.height = height * r;
				ctx.canvas.style.width = width + 'px';
				ctx.canvas.style.height = height + 'px';
				ctx.setTransform( r, 0, 0, r, 0, 0 );

				ctx.font = font;
				ctx.textBaseline = 'middle';
				ctx.textAlign = 'center';
				color = attributes.drawColor;
				ctx.fillStyle = 'rgba(${color.r},${color.g},${color.b},${color.a})';
				ctx.fillRect( 0, 0, width, height );
				ctx.fillStyle = 'white';
				ctx.fillText( geometry.text, width / 2, height / 2 );

				final texture = new CanvasTexture( ctx.canvas );
				texture.minFilter = LinearFilter;
				texture.wrapS = ClampToEdgeWrapping;
				texture.wrapT = ClampToEdgeWrapping;

				material = new SpriteMaterial.fromJson({ 'map': texture, 'depthTest': false });
				final sprite = new Sprite( material );
				sprite.position.setValues( geometry.point[ 0 ], geometry.point[ 1 ], geometry.point[ 2 ] );
				sprite.scale.setValues( width / 10, height / 10, 1.0 );

				sprite.userData[ 'attributes' ] = attributes;
				sprite.userData[ 'objectType' ] = obj.objectType;

				if ( attributes.name ) {
					sprite.name = attributes.name;
				}

				return sprite;

			case 'Light':
				geometry = obj.geometry;
				let light;

				switch ( geometry.lightStyle.name ) {
					case 'LightStyle_WorldPoint':
						light = new PointLight();
						light.castShadow = attributes.castsShadows;
						light.position.set( geometry.location[ 0 ], geometry.location[ 1 ], geometry.location[ 2 ] );
						light.shadow.normalBias = 0.1;
						break;
					case 'LightStyle_WorldSpot':
						light = new SpotLight();
						light.castShadow = attributes.castsShadows;
						light.position.set( geometry.location[ 0 ], geometry.location[ 1 ], geometry.location[ 2 ] );
						light.target.position.set( geometry.direction[ 0 ], geometry.direction[ 1 ], geometry.direction[ 2 ] );
						light.angle = geometry.spotAngleRadians;
						light.shadow.normalBias = 0.1;
						break;
					case 'LightStyle_WorldRectangular':
						light = new RectAreaLight();
						final width = ( geometry.width[ 2 ] ).abs();
						final height = ( geometry.length[ 0 ] ).abs();
						light.position.set( geometry.location[ 0 ] - ( height / 2 ), geometry.location[ 1 ], geometry.location[ 2 ] - ( width / 2 ) );
						light.height = height;
						light.width = width;
						light.lookAt( geometry.direction[ 0 ], geometry.direction[ 1 ], geometry.direction[ 2 ] );
						break;
					case 'LightStyle_WorldDirectional':
						light = new DirectionalLight();
						light.castShadow = attributes.castsShadows;
						light.position.set( geometry.location[ 0 ], geometry.location[ 1 ], geometry.location[ 2 ] );
						light.target.position.set( geometry.direction[ 0 ], geometry.direction[ 1 ], geometry.direction[ 2 ] );
						light.shadow.normalBias = 0.1;
						break;
					case 'LightStyle_WorldLinear':
						// no conversion exists, warning has already been printed to the console
						break;
					default:
						break;
				}

				if ( light != null) {
					light.intensity = geometry.intensity;
					_color = geometry.diffuse;
					color = new Color( _color.r / 255.0, _color.g / 255.0, _color.b / 255.0 );
					light.color = color;
					light.userData[ 'attributes' ] = attributes;
					light.userData[ 'objectType' ] = obj.objectType;
				}

				return light;
		}
	}

	_initLibrary() {

		if ( ! this.libraryPending ) {

			// Load rhino3dm wrapper.
			final jsLoader = new FileLoader( this.manager );
			jsLoader.setPath( this.libraryPath );
			final jsContent = new Promise( ( resolve, reject ){
				jsLoader.load( 'rhino3dm.js', resolve, null, reject );
			});

			// Load rhino3dm WASM binary.
			final binaryLoader = new FileLoader( this.manager );
			binaryLoader.setPath( this.libraryPath );
			binaryLoader.setResponseType( 'arraybuffer' );
			final binaryContent = new Promise( ( resolve, reject ){
				binaryLoader.load( 'rhino3dm.wasm', resolve, null, reject );
			} );

			this.libraryPending = Promise.all( [ jsContent, binaryContent ] )
				.then( ( [ jsContent, binaryContent ] ){

					//this.libraryBinary = binaryContent;
					this.libraryConfig.wasmBinary = binaryContent;

					final fn = Rhino3dmWorker.toString();

					final body = [
						'/* rhino3dm.js */',
						jsContent,
						'/* worker */',
						fn.substring( fn.indexOf( '{' ) + 1, fn.lastIndexOf( '}' ) )
					].join( '\n' );

					this.workerSourceURL = URL.createObjectURL( new Blob( [ body ] ) );
				} );
		}

		return this.libraryPending;
	}

	_getWorker( taskCost ) {
		return this._initLibrary().then( (){
			if ( this.workerPool.length < this.workerLimit ) {
				final worker = new Worker( this.workerSourceURL );

				worker._callbacks = {};
				worker._taskCosts = {};
				worker._taskLoad = 0;

				worker.postMessage( {
					type: 'init',
					libraryConfig: this.libraryConfig
				} );

				worker.onmessage = (e){
					final message = e.data;
					switch ( message.type ) {
						case 'warning':
							this.warnings.add( message.data );
							console.warning( message.data );
							break;
						case 'decode':
							worker._callbacks[ message.id ].resolve( message );
							break;
						case 'error':
							worker._callbacks[ message.id ].reject( message );
							break;
						default:
							console.error( 'THREE.Rhino3dmLoader: Unexpected message, "' + message.type + '"' );
					}
				};

				this.workerPool.add( worker );
			} else {
				this.workerPool.sort(( a, b ) {
					return a._taskLoad > b._taskLoad ? - 1 : 1;
				} );
			}

			final worker = this.workerPool[ this.workerPool.length - 1 ];
			worker._taskLoad += taskCost;
			return worker;
		} );
	}

	_releaseTask( worker, taskID ) {
		worker._taskLoad -= worker._taskCosts[ taskID ];
		delete worker._callbacks[ taskID ];
		delete worker._taskCosts[ taskID ];
	}

	dispose() {
		for ( int i = 0; i < this.workerPool.length; ++ i ) {
			this.workerPool[ i ].terminate();
		}

		this.workerPool.length = 0;
		return this;
	}
}

/* WEB WORKER */

function Rhino3dmWorker() {

	let libraryPending;
	let libraryConfig;
	let rhino;
	let taskID;

	onmessage = ( e ) {
		final message = e.data;

		switch ( message.type ) {
			case 'init':
				libraryConfig = message.libraryConfig;
				final wasmBinary = libraryConfig.wasmBinary;
				let RhinoModule;
				libraryPending = new Promise( function ( resolve ) {
					/* Like Basis Loader */
					RhinoModule = { wasmBinary, onRuntimeInitialized: resolve };
					rhino3dm( RhinoModule ); // eslint-disable-line no-undef
				 } ).then( (){
					rhino = RhinoModule;
				 } );
				break;
			case 'decode':
				taskID = message.id;
				final buffer = message.buffer;
				libraryPending.then( () => {

					try {
						final data = decodeObjects( rhino, buffer );
						self.postMessage( { type: 'decode', id: message.id, data } );
					} catch ( error ) {
						self.postMessage( { type: 'error', id: message.id, error } );
					}
				} );
				break;
		}
	};

	function decodeObjects( rhino, buffer ) {
		final arr = new Uint8Array( buffer );
		final doc = rhino.File3dm.fromByteArray( arr );

		final objects = [];
		final materials = [];
		final layers = [];
		final views = [];
		final namedViews = [];
		final groups = [];
		final strings = [];

		//Handle objects

		final objs = doc.objects();
		final cnt = objs.count;

		for ( int i = 0; i < cnt; i ++ ) {
			final _object = objs.get( i );
			final object = extractObjectData( _object, doc );

			_object.delete();

			if ( object ) {
				objects.add( object );
			}
		}

		// Handle instance definitions
		// console.log( `Instance Definitions Count: ${doc.instanceDefinitions().count()}` );

		for ( int i = 0; i < doc.instanceDefinitions().count; i ++ ) {
			final idef = doc.instanceDefinitions().get( i );
			final idefAttributes = extractProperties( idef );
			idefAttributes.objectIds = idef.getObjectIds();
			objects.add( { geometry: null, attributes: idefAttributes, objectType: 'InstanceDefinition' } );
		}

		// Handle materials

		final textureTypes = [
			// rhino.TextureType.Bitmap,
			rhino.TextureType.Diffuse,
			rhino.TextureType.Bump,
			rhino.TextureType.Transparency,
			rhino.TextureType.Opacity,
			rhino.TextureType.Emap
		];

		final pbrTextureTypes = [
			rhino.TextureType.PBR_BaseColor,
			rhino.TextureType.PBR_Subsurface,
			rhino.TextureType.PBR_SubsurfaceScattering,
			rhino.TextureType.PBR_SubsurfaceScatteringRadius,
			rhino.TextureType.PBR_Metallic,
			rhino.TextureType.PBR_Specular,
			rhino.TextureType.PBR_SpecularTint,
			rhino.TextureType.PBR_Roughness,
			rhino.TextureType.PBR_Anisotropic,
			rhino.TextureType.PBR_Anisotropic_Rotation,
			rhino.TextureType.PBR_Sheen,
			rhino.TextureType.PBR_SheenTint,
			rhino.TextureType.PBR_Clearcoat,
			rhino.TextureType.PBR_ClearcoatBump,
			rhino.TextureType.PBR_ClearcoatRoughness,
			rhino.TextureType.PBR_OpacityIor,
			rhino.TextureType.PBR_OpacityRoughness,
			rhino.TextureType.PBR_Emission,
			rhino.TextureType.PBR_AmbientOcclusion,
			rhino.TextureType.PBR_Displacement
		];

		for ( int i = 0; i < doc.materials().count; i ++ ) {
			final _material = doc.materials().get( i );
			final material = extractProperties( _material );
			final textures = [];

			textures.add( ...extractTextures( _material, textureTypes, doc ) );
			material.pbrSupported = _material.physicallyBased().supported;

			if ( material.pbrSupported ) {
				textures.add( ...extractTextures( _material, pbrTextureTypes, doc ) );
				material.pbr = extractProperties( _material.physicallyBased() );
			}

			material.textures = textures;
			materials.add( material );
			_material.delete();
		}

		// Handle layers

		for ( int i = 0; i < doc.layers().count; i ++ ) {
			final _layer = doc.layers().get( i );
			final layer = extractProperties( _layer );
			layers.add( layer );
			_layer.delete();
		}

		// Handle views

		for (int i = 0; i < doc.views().count; i ++ ) {
			final _view = doc.views().get( i );
			final view = extractProperties( _view );

			views.add( view );
			_view.delete();
		}

		// Handle named views

		for ( int i = 0; i < doc.namedViews().count; i ++ ) {
			final _namedView = doc.namedViews().get( i );
			final namedView = extractProperties( _namedView );

			namedViews.add( namedView );
			_namedView.delete();
		}

		// Handle groups

		for ( int i = 0; i < doc.groups().count; i ++ ) {

			final _group = doc.groups().get( i );
			final group = extractProperties( _group );

			groups.add( group );

			_group.delete();

		}

		// Handle settings

		final settings = extractProperties( doc.settings() );

		//TODO: Handle other document stuff like dimstyles, instance definitions, bitmaps etc.

		// Handle dimstyles
		// console.log( `Dimstyle Count: ${doc.dimstyles().count()}` );

		// Handle bitmaps
		// console.log( `Bitmap Count: ${doc.bitmaps().count()}` );

		// Handle strings
		// console.log( `Document Strings Count: ${doc.strings().count()}` );
		// Note: doc.strings().documentUserTextCount() counts any doc.strings defined in a section
		// console.log( `Document User Text Count: ${doc.strings().documentUserTextCount()}` );

		final strings_count = doc.strings().count;

		for (int i = 0; i < strings_count; i ++ ) {
			strings.add( doc.strings().get( i ) );
		}

		// Handle Render Environments for Material Environment

		// get the id of the active render environment skylight, which we'll use for environment texture
		final reflectionId = doc.settings().renderSettings().renderEnvironments.reflectionId;

		final rc = doc.renderContent();

		let renderEnvironment = null;

		for (int i = 0; i < rc.count; i ++ ) {
			final content = rc.get( i );

			switch ( content.kind ) {
				case 'environment':

					final id = content.id;

					// there could be multiple render environments in a 3dm file
					if ( id != reflectionId ) break;

					final renderTexture = content.findChild( 'texture' );
					final fileName = renderTexture.fileName;

					for (int j = 0; j < doc.embeddedFiles().count; j ++ ) {

						final _fileName = doc.embeddedFiles().get( j ).fileName;

						if ( fileName == _fileName ) {

							final background = doc.getEmbeddedFileAsBase64( fileName );
							final backgroundImage = 'data:image/png;base64,' + background;
							renderEnvironment = { type: 'renderEnvironment', image: backgroundImage, name: fileName };

						}

					}

					break;

			}

		}

		// Handle Render Settings

		final renderSettings = {
			ambientLight: doc.settings().renderSettings().ambientLight,
			backgroundColorTop: doc.settings().renderSettings().backgroundColorTop,
			backgroundColorBottom: doc.settings().renderSettings().backgroundColorBottom,
			useHiddenLights: doc.settings().renderSettings().useHiddenLights,
			depthCue: doc.settings().renderSettings().depthCue,
			flatShade: doc.settings().renderSettings().flatShade,
			renderBackFaces: doc.settings().renderSettings().renderBackFaces,
			renderPoints: doc.settings().renderSettings().renderPoints,
			renderCurves: doc.settings().renderSettings().renderCurves,
			renderIsoParams: doc.settings().renderSettings().renderIsoParams,
			renderMeshEdges: doc.settings().renderSettings().renderMeshEdges,
			renderAnnotations: doc.settings().renderSettings().renderAnnotations,
			useViewportSize: doc.settings().renderSettings().useViewportSize,
			scaleBackgroundToFit: doc.settings().renderSettings().scaleBackgroundToFit,
			transparentBackground: doc.settings().renderSettings().transparentBackground,
			imageDpi: doc.settings().renderSettings().imageDpi,
			shadowMapLevel: doc.settings().renderSettings().shadowMapLevel,
			namedView: doc.settings().renderSettings().namedView,
			snapShot: doc.settings().renderSettings().snapShot,
			specificViewport: doc.settings().renderSettings().specificViewport,
			groundPlane: extractProperties( doc.settings().renderSettings().groundPlane ),
			safeFrame: extractProperties( doc.settings().renderSettings().safeFrame ),
			dithering: extractProperties( doc.settings().renderSettings().dithering ),
			skylight: extractProperties( doc.settings().renderSettings().skylight ),
			linearWorkflow: extractProperties( doc.settings().renderSettings().linearWorkflow ),
			renderChannels: extractProperties( doc.settings().renderSettings().renderChannels ),
			sun: extractProperties( doc.settings().renderSettings().sun ),
			renderEnvironments: extractProperties( doc.settings().renderSettings().renderEnvironments ),
			postEffects: extractProperties( doc.settings().renderSettings().postEffects ),

		};

		doc.delete();

		return { objects, materials, layers, views, namedViews, groups, strings, settings, renderSettings, renderEnvironment };

	}

	function extractTextures( m, tTypes, d ) {

		final textures = [];

		for ( int i = 0; i < tTypes.length; i ++ ) {

			final _texture = m.getTexture( tTypes[ i ] );
			if ( _texture ) {

				let textureType = tTypes[ i ].constructor.name;
				textureType = textureType.substring( 12, textureType.length );
				final texture = extractTextureData( _texture, textureType, d );
				textures.add( texture );
				_texture.delete();

			}

		}

		return textures;

	}

	function extractTextureData( t, tType, d ) {

		final texture = { type: tType };

		final image = d.getEmbeddedFileAsBase64( t.fileName );

		texture.wrapU = t.wrapU;
		texture.wrapV = t.wrapV;
		texture.wrapW = t.wrapW;
		final uvw = t.uvwTransform.toFloatArray( true );

		texture.repeat = [ uvw[ 0 ], uvw[ 5 ] ];

		if ( image ) {

			texture.image = 'data:image/png;base64,' + image;

		} else {

			self.postMessage( { type: 'warning', id: taskID, data: {
				message: `THREE.3DMLoader: Image for ${tType} texture not embedded in file.`,
				type: 'missing resource'
			}

			} );

			texture.image = null;

		}

		return texture;

	}

	function extractObjectData( object, doc ) {

		final _geometry = object.geometry();
		final _attributes = object.attributes();
		let objectType = _geometry.objectType;
		let geometry, attributes, position, data, mesh;

		// skip instance definition objects
		//if( _attributes.isInstanceDefinitionObject ) { continue; }

		// TODO: handle other geometry types
		switch ( objectType ) {

			case rhino.ObjectType.Curve:

				final pts = curveToPoints( _geometry, 100 );

				position = {};
				attributes = {};
				data = {};

				position.itemSize = 3;
				position.type = 'Float32Array';
				position.array = [];

				for ( int j = 0; j < pts.length; j ++ ) {

					position.array.add( pts[ j ][ 0 ] );
					position.array.add( pts[ j ][ 1 ] );
					position.array.add( pts[ j ][ 2 ] );

				}

				attributes.position = position;
				data.attributes = attributes;

				geometry = { data };

				break;

			case rhino.ObjectType.Point:

				final pt = _geometry.location;

				position = {};
				final color = {};
				attributes = {};
				data = {};

				position.itemSize = 3;
				position.type = 'Float32Array';
				position.array = [ pt[ 0 ], pt[ 1 ], pt[ 2 ] ];

				final _color = _attributes.drawColor( doc );

				color.itemSize = 3;
				color.type = 'Float32Array';
				color.array = [ _color.r / 255.0, _color.g / 255.0, _color.b / 255.0 ];

				attributes.position = position;
				attributes.color = color;
				data.attributes = attributes;

				geometry = { data };

				break;

			case rhino.ObjectType.PointSet:
			case rhino.ObjectType.Mesh:

				geometry = _geometry.toThreejsJSON();

				break;

			case rhino.ObjectType.Brep:

				final faces = _geometry.faces();
				mesh = new rhino.Mesh();

				for ( int faceIndex = 0; faceIndex < faces.count; faceIndex ++ ) {

					final face = faces.get( faceIndex );
					final _mesh = face.getMesh( rhino.MeshType.Any );

					if ( _mesh ) {

						mesh.append( _mesh );
						_mesh.delete();

					}

					face.delete();

				}

				if ( mesh.faces().count > 0 ) {

					mesh.compact();
					geometry = mesh.toThreejsJSON();
					faces.delete();

				}

				mesh.delete();

				break;

			case rhino.ObjectType.Extrusion:

				mesh = _geometry.getMesh( rhino.MeshType.Any );

				if ( mesh ) {

					geometry = mesh.toThreejsJSON();
					mesh.delete();

				}

				break;

			case rhino.ObjectType.TextDot:

				geometry = extractProperties( _geometry );

				break;

			case rhino.ObjectType.Light:

				geometry = extractProperties( _geometry );

				if ( geometry.lightStyle.name == 'LightStyle_WorldLinear' ) {

					self.postMessage( { type: 'warning', id: taskID, data: {
						message: `THREE.3DMLoader: No conversion exists for ${objectType.constructor.name} ${geometry.lightStyle.name}`,
						type: 'no conversion',
						guid: _attributes.id
					}

					} );

				}

				break;

			case rhino.ObjectType.InstanceReference:

				geometry = extractProperties( _geometry );
				geometry.xform = extractProperties( _geometry.xform );
				geometry.xform.array = _geometry.xform.toFloatArray( true );

				break;

			case rhino.ObjectType.SubD:

				// TODO: precalculate resulting vertices and faces and warn on excessive results
				_geometry.subdivide( 3 );
				mesh = rhino.Mesh.createFromSubDControlNet( _geometry, false );
				if ( mesh ) {

					geometry = mesh.toThreejsJSON();
					mesh.delete();

				}

				break;

				/*
				case rhino.ObjectType.Annotation:
				case rhino.ObjectType.Hatch:
				case rhino.ObjectType.ClipPlane:
				*/

			default:

				self.postMessage( { type: 'warning', id: taskID, data: {
					message: `THREE.3DMLoader: Conversion not implemented for ${objectType.constructor.name}`,
					type: 'not implemented',
					guid: _attributes.id
				}

				} );

				break;

		}

		if ( geometry ) {

			attributes = extractProperties( _attributes );
			attributes.geometry = extractProperties( _geometry );

			if ( _attributes.groupCount > 0 ) {

				attributes.groupIds = _attributes.getGroupList();

			}

			if ( _attributes.userStringCount > 0 ) {

				attributes.userStrings = _attributes.getUserStrings();

			}

			if ( _geometry.userStringCount > 0 ) {

				attributes.geometry.userStrings = _geometry.getUserStrings();

			}

			if ( _attributes.decals().count > 0 ) {

				self.postMessage( { type: 'warning', id: taskID, data: {
					message: 'THREE.3DMLoader: No conversion exists for the decals associated with this object.',
					type: 'no conversion',
					guid: _attributes.id
				}

				} );

			}

			attributes.drawColor = _attributes.drawColor( doc );

			objectType = objectType.constructor.name;
			objectType = objectType.substring( 11, objectType.length );

			return { geometry, attributes, objectType };

		} else {

			self.postMessage( { type: 'warning', id: taskID, data: {
				message: `THREE.3DMLoader: ${objectType.constructor.name} has no associated mesh geometry.`,
				type: 'missing mesh',
				guid: _attributes.id
			}

			} );

		}

	}

	function extractProperties( object ) {
		final result = {};

		for ( final property in object ) {
			final value = object[ property ];

			if ( typeof value != 'function' ) {
				if ( typeof value == 'object' && value != null && value.hasOwnProperty( 'constructor' ) ) {
					result[ property ] = { name: value.constructor.name, value: value.value };
				} else if ( typeof value == 'object' && value != null ) {
					result[ property ] = extractProperties( value );
				} else {
					result[ property ] = value;
				}
			} else {
				// these are functions that could be called to extract more data.
				//console.log( `${property}: ${object[ property ].constructor.name}` );
			}
		}

		return result;

	}

	List curveToPoints( curve, pointLimit ) {
		int pointCount = pointLimit;
		List rc = [];
		final ts = [];

		if ( curve is rhino.LineCurve ) {
			return [ curve.pointAtStart, curve.pointAtEnd ];
		}

		if ( curve is rhino.PolylineCurve ) {
			pointCount = curve.pointCount;
			for (int i = 0; i < pointCount; i ++ ) {
				rc.add( curve.point( i ) );
			}

			return rc;
		}

		if ( curve is rhino.PolyCurve ) {
			final segmentCount = curve.segmentCount;

			for ( int i = 0; i < segmentCount; i ++ ) {
				final segment = curve.segmentCurve( i );
				final segmentArray = curveToPoints( segment, pointCount );
				rc = rc.concat( segmentArray );
				segment.delete();
			}

			return rc;
		}

		if ( curve is rhino.ArcCurve ) {
			pointCount = math.floor( curve.angleDegrees / 5 );
			pointCount = pointCount < 2 ? 2 : pointCount;
			// alternative to this hardcoded version: https://stackoverflow.com/a/18499923/2179399
		}

		if ( curve is rhino.NurbsCurve && curve.degree == 1 ) {
			final pLine = curve.tryGetPolyline();

			for (int i = 0; i < pLine.count; i ++ ) {
				rc.add( pLine.get( i ) );
			}

			pLine.delete();

			return rc;
		}

		final domain = curve.domain;
		final divisions = pointCount - 1.0;

		for (int j = 0; j < pointCount; j ++ ) {
			final t = domain[ 0 ] + ( j / divisions ) * ( domain[ 1 ] - domain[ 0 ] );

			if ( t == domain[ 0 ] || t == domain[ 1 ] ) {
				ts.add( t );
				continue;
			}

			final tan = curve.tangentAt( t );
			final prevTan = curve.tangentAt( ts.slice( - 1 )[ 0 ] );

			// Duplicated from THREE.Vector3
			// How to pass imports to worker?

			final tS = tan[ 0 ] * tan[ 0 ] + tan[ 1 ] * tan[ 1 ] + tan[ 2 ] * tan[ 2 ];
			final ptS = prevTan[ 0 ] * prevTan[ 0 ] + prevTan[ 1 ] * prevTan[ 1 ] + prevTan[ 2 ] * prevTan[ 2 ];

			final denominator = math.sqrt( tS * ptS );

			double angle;

			if ( denominator == 0 ) {
				angle = math.pi / 2;
			} else {
				final theta = ( tan.x * prevTan.x + tan.y * prevTan.y + tan.z * prevTan.z ) / denominator;
				angle = math.acos( math.max( - 1, math.min( 1, theta ) ) );
			}

			if ( angle < 0.1 ) continue;
			ts.add( t );
		}

		rc = ts.map( t => curve.pointAt( t ) );
		return rc;
	}
}
