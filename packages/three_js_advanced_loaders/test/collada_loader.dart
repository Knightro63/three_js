import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as math;

import 'package:three_js_animations/three_js_animations.dart';
import 'package:three_js_core_loaders/three_js_core_loaders.dart';
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';

class ColladaLoader extends Loader {
  late final FileLoader _loader;

  /// [manager] — The [loadingManager] for the loader to use. Default is [DefaultLoadingManager].
  /// 
  /// Creates a[FontLoader].
  ColladaLoader({LoadingManager? manager}):super(manager){
    _loader = FileLoader(manager);
  }

  @override
  void dispose(){
    super.dispose();
    _loader.dispose();
  }

  void _init(){
    _loader.setPath(path);
    _loader.setResponseType('arraybuffer');
    _loader.setRequestHeader(requestHeader);
    _loader.setWithCredentials(withCredentials);
  }

  @override
  Future<AnimationObject?> fromNetwork(Uri uri) async{
    _init();
    ThreeFile? tf = await _loader.fromNetwork(uri);
    return tf == null?null:_parse(tf.data);
  }
  @override
  Future<AnimationObject?> fromFile(File file) async{
    _init();
    ThreeFile tf = await _loader.fromFile(file);
    return _parse(tf.data);
  }
  @override
  Future<AnimationObject?> fromPath(String filePath) async{
    _init();
    ThreeFile? tf = await _loader.fromPath(filePath);
    return tf == null?null:_parse(tf.data);
  }
  @override
  Future<AnimationObject?> fromBlob(Blob blob) async{
    _init();
    ThreeFile tf = await _loader.fromBlob(blob);
    return _parse(tf.data);
  }
  @override
  Future<AnimationObject?> fromAsset(String asset, {String? package}) async{
    _init();
    ThreeFile? tf = await _loader.fromAsset(asset,package: package);
    return tf == null?null:_parse(tf.data);
  }
  @override
  Future<AnimationObject?> fromBytes(Uint8List bytes) async{
    _init();
    ThreeFile tf = await _loader.fromBytes(bytes);
    return _parse(tf.data);
  }

  Future<AnimationObject?> _parse(Uint8List bufferBytes) async{
    return parse(String.fromCharCodes(bufferBytes),null);
  }

	parse(String text, String? path ) {
		List getElementsByTagName( xml, String name ) {
			final array = [];
			final childNodes = xml.childNodes;

			for (int i = 0, l = childNodes.length; i < l; i ++ ) {
				final child = childNodes[ i ];
				if ( child.nodeName == name ) {
					array.add( child );
				}
			}
			return array;
		}

		List<String> parseStrings(String text ) {
			if ( text.length == 0 ) return [];
			final parts = text.trim().split(' ');
			final array = List.filled(parts.length, '');

			for (int i = 0, l = parts.length; i < l; i ++ ) {
				array[i] = parts[i];
			}

			return array;
		}

		List<double> parseFloats(String text ) {
			if ( text.length == 0 ) return [];
			final parts = text.trim().split(' ');
			final array = List.filled(parts.length, 0.0);

			for (int i = 0, l = parts.length; i < l; i ++ ) {
				array[ i ] = double.parse( parts[ i ] );
			}

			return array;
		}

		List<int> parseInts(String text ) {
			if ( text.length == 0 ) return [];
			final parts = text.trim().split(' ');
			final array = List.filled(parts.length, 0);

			for (int i = 0, l = parts.length; i < l; i ++ ) {
				array[ i ] = int.parse( parts[ i ] );
			}

			return array;
		}

		String parseId(String text ) {
			return text.substring( 1 );
		}

		String generateId() {
			return 'three_default_${count++}';
		}

		isEmpty( object ) {
			return Object.keys( object ).length == 0;
		}

		// asset

		Map<String,dynamic> parseAsset( xml ) {
			return {
				'unit': parseAssetUnit( getElementsByTagName( xml, 'unit' )[ 0 ] ),
				'upAxis': parseAssetUpAxis( getElementsByTagName( xml, 'up_axis' )[ 0 ] )
			};
		}

		double parseAssetUnit(Map? xml ) {
			if ( ( xml != null ) && ( xml.containsKey( 'meter' ) == true ) ) {
				return double.parse( xml['meter']);
			} else {
				return 1; // default 1 meter
			}
		}

		String parseAssetUpAxis(Map? xml ) {
			return xml != null ? xml['textContent'] : 'Y_UP';
		}

		// library

		void parseLibrary(Map? xml, String libraryName,String nodeName, parser ) {
			final library = getElementsByTagName( xml, libraryName )[ 0 ];

			if ( library != null ) {
				final elements = getElementsByTagName( library, nodeName );

				for (int i = 0; i < elements.length; i ++ ) {
					parser( elements[ i ] );
				}
			}
		}

		void buildLibrary( data, builder ) {
			for ( final name in data ) {
				final object = data[ name ];
				object.build = builder( data[ name ] );
			}
		}

		// get

		getBuild( data, builder ) {
			if ( data.build != null ) return data.build;

			data.build = builder( data );

			return data.build;
		}

		// animation

		parseAnimation( xml ) {
			final data = {
				'sources': {},
				'samplers': {},
				'channels': {}
			};

			bool hasChildren = false;

			for (int i = 0, l = xml.childNodes.length; i < l; i ++ ) {
				final child = xml.childNodes[ i ];

				if ( child.nodeType != 1 ) continue;

				int id;

				switch ( child.nodeName ) {
					case 'source':
						id = child.getAttribute( 'id' );
						data['sources']![ id ] = parseSource( child );
						break;
					case 'sampler':
						id = child.getAttribute( 'id' );
						data['samplers']![ id ] = parseAnimationSampler( child );
						break;
					case 'channel':
						id = child.getAttribute( 'target' );
						data['channels']![ id ] = parseAnimationChannel( child );
						break;

					case 'animation':
						// hierarchy of related animations
						parseAnimation( child );
						hasChildren = true;
						break;

					default:
						console.log( child );
				}
			}

			if ( !hasChildren ) {
				// since 'id' attributes can be optional, it's necessary to generate a UUID for unqiue assignment
				library.animations[ xml.getAttribute( 'id' ) ?? MathUtils.generateUUID() ] = data;
			}
		}

		Map parseAnimationSampler( xml ) {
			final data = {
				'inputs': {},
			};

			for (int i = 0, l = xml.childNodes.length; i < l; i ++ ) {
				final child = xml.childNodes[ i ];

				if ( child.nodeType != 1 ) continue;

				switch ( child.nodeName ) {
					case 'input':
						final id = parseId( child.getAttribute( 'source' ) );
						final semantic = child.getAttribute( 'semantic' );
						data.inputs[ semantic ] = id;
						break;
				}
			}

			return data;
		}

		parseAnimationChannel( xml ) {
			final data = {};
			final String target = xml.getAttribute( 'target' );
			List<String> parts = target.split( '/' );

			final id = parts.shift();
			String sid = parts.shift();

			// check selection syntax

			final arraySyntax = ( sid.indexOf( '(' ) != - 1 );
			final memberSyntax = ( sid.indexOf( '.' ) != - 1 );

			if ( memberSyntax ) {
				parts = sid.split( '.' );
				sid = parts.shift();
				data['member'] = parts.shift();
			} else if ( arraySyntax ) {
				// array-access syntax. can be used to express fields in one-dimensional vectors or two-dimensional matrices.

				final indices = sid.split( '(' );
				sid = indices.shift();

				for (int i = 0; i < indices.length; i ++ ) {
					indices[ i ] = int.parse( indices[ i ].replaceAll(')', '' ));
				}

				data['indices'] = indices;
			}

			data['id'] = id;
			data['sid'] = sid;

			data['arraySyntax'] = arraySyntax;
			data['memberSyntax'] = memberSyntax;

			data['sampler'] = parseId( xml.getAttribute( 'source' ) );

			return data;
		}

		buildAnimation( data ) {
			final tracks = [];

			final channels = data.channels;
			final samplers = data.samplers;
			final sources = data.sources;

			for ( final target in channels ) {
				if ( channels.hasOwnProperty( target ) ) {
					final channel = channels[ target ];
					final sampler = samplers[ channel.sampler ];

					final inputId = sampler.inputs.INPUT;
					final outputId = sampler.inputs.OUTPUT;

					final inputSource = sources[ inputId ];
					final outputSource = sources[ outputId ];

					final animation = buildAnimationChannel( channel, inputSource, outputSource );

					createKeyframeTracks( animation, tracks );
				}
			}

			return tracks;
		}

		getAnimation( id ) {
			return getBuild( library.animations[ id ], buildAnimation );
		}

		buildAnimationChannel( channel, inputSource, outputSource ) {
			final node = library.nodes[ channel.id ];
			final object3D = getNode( node.id );

			final transform = node.transforms[ channel.sid ];
			final defaultMatrix = node.matrix.clone().transpose();

			var time, stride;
			var i, il, j, jl;

			final data = {};

			// the collada spec allows the animation of data in various ways.
			// depending on the transform type (matrix, translate, rotate, scale), we execute different logic

			switch ( transform ) {
				case 'matrix':
					for (int i = 0, il = inputSource.array.length; i < il; i ++ ) {
						time = inputSource.array[ i ];
						stride = i * outputSource.stride;

						if ( data[ time ] == null ) data[ time ] = {};

						if ( channel.arraySyntax == true ) {
							final value = outputSource.array[ stride ];
							final index = channel.indices[ 0 ] + 4 * channel.indices[ 1 ];

							data[ time ][ index ] = value;
						} else {
							for ( int j = 0, jl = outputSource.stride; j < jl; j ++ ) {
								data[ time ][ j ] = outputSource.array[ stride + j ];
							}
						}
					}
					break;

				case 'translate':
					console.warning( 'THREE.ColladaLoader: Animation transform type "%s" not yet implemented.', transform );
					break;

				case 'rotate':
					console.warning( 'THREE.ColladaLoader: Animation transform type "%s" not yet implemented.', transform );
					break;

				case 'scale':
					console.warning( 'THREE.ColladaLoader: Animation transform type "%s" not yet implemented.', transform );
					break;

			}

			final keyframes = prepareAnimationData( data, defaultMatrix );

			final animation = {
				'name': object3D.uuid,
				'keyframes': keyframes
			};

			return animation;

		}

		prepareAnimationData( data, defaultMatrix ) {
			ascending( a, b ) {
				return a.time - b.time;
			}

			final keyframes = [];

			for ( final time in data ) {
				keyframes.add( { 'time': double.parse( time ), 'value': data[ time ] } );
			}

			keyframes.sort( ascending );

			for ( var i = 0; i < 16; i ++ ) {
				transformAnimationData( keyframes, i, defaultMatrix.elements[ i ] );
			}

			return keyframes;
		}

		final position =Vector3();
		final scale =Vector3();
		final quaternion =Quaternion();

		createKeyframeTracks( animation, tracks ) {

			final keyframes = animation.keyframes;
			final name = animation.name;

			final times = [];
			final positionData = [];
			final quaternionData = [];
			final scaleData = [];

			for ( var i = 0, l = keyframes.length; i < l; i ++ ) {

				final keyframe = keyframes[ i ];

				final time = keyframe.time;
				final value = keyframe.value;

				matrix.fromArray( value ).transpose();
				matrix.decompose( position, quaternion, scale );

				times.add( time );
				positionData.add( position.x, position.y, position.z );
				quaternionData.add( quaternion.x, quaternion.y, quaternion.z, quaternion.w );
				scaleData.add( scale.x, scale.y, scale.z );

			}

			if ( positionData.length > 0 ) tracks.add(VectorKeyframeTrack( name + '.position', times, positionData ) );
			if ( quaternionData.length > 0 ) tracks.add(QuaternionKeyframeTrack( name + '.quaternion', times, quaternionData ) );
			if ( scaleData.length > 0 ) tracks.add(VectorKeyframeTrack( name + '.scale', times, scaleData ) );

			return tracks;

		}

		transformAnimationData( keyframes, property, defaultValue ) {
			var keyframe;
			var empty = true;
			var i, l;

			// check, if values of a property are missing in our keyframes

			for (int i = 0, l = keyframes.length; i < l; i ++ ) {
				keyframe = keyframes[ i ];

				if ( keyframe.value[ property ] == null ) {
					keyframe.value[ property ] = null; // mark as missing
				} else {
					empty = false;
				}
			}

			if ( empty == true ) {
				for (int i = 0, l = keyframes.length; i < l; i ++ ) {
					keyframe = keyframes[ i ];
					keyframe.value[ property ] = defaultValue;
				}
			} else {
				createMissingKeyframes( keyframes, property );
			}
		}

		createMissingKeyframes( keyframes, property ) {
			var prev, next;

			for ( var i = 0, l = keyframes.length; i < l; i ++ ) {
				final keyframe = keyframes[ i ];

				if ( keyframe.value[ property ] == null ) {
					prev = getPrev( keyframes, i, property );
					next = getNext( keyframes, i, property );

					if ( prev == null ) {
						keyframe.value[ property ] = next.value[ property ];
						continue;
					}

					if ( next == null ) {
						keyframe.value[ property ] = prev.value[ property ];
						continue;
					}

					interpolate( keyframe, prev, next, property );
				}
			}
		}

		getPrev( keyframes, i, property ) {
			while ( i >= 0 ) {
				final keyframe = keyframes[ i ];
				if ( keyframe.value[ property ] != null ) return keyframe;
				i --;
			}

			return null;
		}

		getNext( keyframes, i, property ) {
			while ( i < keyframes.length ) {
				final keyframe = keyframes[ i ];
				if ( keyframe.value[ property ] != null ) return keyframe;
				i ++;
			}
			return null;
		}

		interpolate( key, prev, next, property ) {
			if ( ( next.time - prev.time ) == 0 ) {
				key.value[ property ] = prev.value[ property ];
				return;
			}
			key.value[ property ] = ( ( key.time - prev.time ) * ( next.value[ property ] - prev.value[ property ] ) / ( next.time - prev.time ) ) + prev.value[ property ];
		}

		// animation clips

		parseAnimationClip( xml ) {
			final Map<String,dynamic> data = {
				'name': xml.getAttribute( 'id' ) ?? 'default',
				'start': double.parse( xml.getAttribute( 'start' ) ?? 0 ),
				'end': double.parse( xml.getAttribute( 'end' ) ?? 0 ),
				'animations': []
			};

			for ( var i = 0, l = xml.childNodes.length; i < l; i ++ ) {
				final child = xml.childNodes[ i ];
				if ( child.nodeType != 1 ) continue;
				switch ( child.nodeName ) {
					case 'instance_animation':
						data['animations'].add( parseId( child.getAttribute( 'url' ) ) );
						break;
				}
			}
			library.clips[ xml.getAttribute( 'id' ) ] = data;
		}

		buildAnimationClip( data ) {
			final tracks = [];
			final name = data.name;
			final duration = ( data.end - data.start ) ?? - 1;
			final animations = data.animations;

			for ( var i = 0, il = animations.length; i < il; i ++ ) {
				final animationTracks = getAnimation( animations[ i ] );
				for ( var j = 0, jl = animationTracks.length; j < jl; j ++ ) {
					tracks.add( animationTracks[ j ] );
				}
			}
			return AnimationClip( name, duration, tracks );
		}

		getAnimationClip( id ) {
			return getBuild( library.clips[ id ], buildAnimationClip );
		}

		// controller

		parseController( xml ) {
			final Map<String,dynamic> data = {};

			for ( var i = 0, l = xml.childNodes.length; i < l; i ++ ) {
				final child = xml.childNodes[ i ];
				if ( child.nodeType != 1 ) continue;

				switch ( child.nodeName ) {
					case 'skin':
						// there is exactly one skin per controller
						data['id'] = parseId( child.getAttribute( 'source' ) );
						data['skin'] = parseSkin( child );
						break;
					case 'morph':
						data['id'] = parseId( child.getAttribute( 'source' ) );
						console.warning( 'THREE.ColladaLoader: Morph target animation not supported yet.' );
						break;
				}
			}

			library.controllers[ xml.getAttribute( 'id' ) ] = data;
		}

		parseSkin( xml ) {
			final Map<String,dynamic> data = {
				'sources': {}
			};

			for ( var i = 0, l = xml.childNodes.length; i < l; i ++ ) {
				final child = xml.childNodes[ i ];
				if ( child.nodeType != 1 ) continue;
				switch ( child.nodeName ) {
					case 'bind_shape_matrix':
						data['bindShapeMatrix'] = parseFloats( child.textContent );
						break;
					case 'source':
						final id = child.getAttribute( 'id' );
						data['sources']![ id ] = parseSource( child );
						break;
					case 'joints':
						data['joints'] = parseJoints( child );
						break;
					case 'vertex_weights':
						data['vertexWeights'] = parseVertexWeights( child );
						break;
				}
			}
			return data;
		}

		parseJoints( xml ) {
			final data = {
				'inputs': {}
			};

			for ( var i = 0, l = xml.childNodes.length; i < l; i ++ ) {
				final child = xml.childNodes[ i ];

				if ( child.nodeType != 1 ) continue;
				switch ( child.nodeName ) {
					case 'input':
						final semantic = child.getAttribute( 'semantic' );
						final id = parseId( child.getAttribute( 'source' ) );
						data['inputs']![ semantic ] = id;
						break;
				}
			}
			return data;
		}

		parseVertexWeights( xml ) {
			final Map<String,dynamic> data = {
				'inputs': {}
			};

			for ( var i = 0, l = xml.childNodes.length; i < l; i ++ ) {
				final child = xml.childNodes[ i ];
				if ( child.nodeType != 1 ) continue;

				switch ( child.nodeName ) {
					case 'input':
						final semantic = child.getAttribute( 'semantic' );
						final id = parseId( child.getAttribute( 'source' ) );
						final offset = int.parse( child.getAttribute( 'offset' ) );
						data['inputs'][ semantic ] = { ['id']: id, ['offset']: offset };
						break;
					case 'vcount':
						data['vcount'] = parseInts( child.textContent );
						break;
					case 'v':
						data['v'] = parseInts( child.textContent );
						break;
				}
			}

			return data;
		}

		buildController( data ) {
			final Map<String,dynamic> build = {
				'id': data.id
			};

			final geometry = library.geometries[ build['id'] ];

			if ( data.skin != null ) {
				build['skin'] = buildSkin( data.skin );

				// we enhance the 'sources' property of the corresponding geometry with our skin data

				geometry.sources.skinIndices = build['skin'].indices;
				geometry.sources.skinWeights = build['skin'].weights;
			}

			return build;
		}

		buildSkin( data ) {
			descending( a, b ) {
				return b.weight - a.weight;
			}

			final BONE_LIMIT = 4;

			final Map<String,dynamic> build = {
				'joints': [], // this must be an array to preserve the joint order
				'indices': {
					'array': [],
					'stride': BONE_LIMIT
				},
				'weights': {
					'array': [],
					'stride': BONE_LIMIT
				}
			};

			final sources = data.sources;
			final vertexWeights = data.vertexWeights;

			final vcount = vertexWeights.vcount;
			final v = vertexWeights.v;
			final jointOffset = vertexWeights.inputs.JOINT.offset;
			final weightOffset = vertexWeights.inputs.WEIGHT.offset;

			final jointSource = data.sources[ data.joints.inputs.JOINT ];
			final inverseSource = data.sources[ data.joints.inputs.INV_BIND_MATRIX ];

			final weights = sources[ vertexWeights.inputs.WEIGHT.id ].array;
			var stride = 0;

			var i, j, l;

			// process skin data for each vertex

			for (int i = 0, l = vcount.length; i < l; i ++ ) {
				final jointCount = vcount[ i ]; // this is the amount of joints that affect a single vertex
				final vertexSkinData = [];

				for ( j = 0; j < jointCount; j ++ ) {
					final skinIndex = v[ stride + jointOffset ];
					final weightId = v[ stride + weightOffset ];
					final skinWeight = weights[ weightId ];

					vertexSkinData.add( { 'index': skinIndex, 'weight': skinWeight } );

					stride += 2;
				}

				// we sort the joints in descending order based on the weights.
				// this ensures, we only procced the most important joints of the vertex

				vertexSkinData.sort( descending );

				// now we provide for each vertex a set of four index and weight values.
				// the order of the skin data matches the order of vertices

				for ( j = 0; j < BONE_LIMIT; j ++ ) {
					final d = vertexSkinData[ j ];

					if ( d != null ) {
						build['indices']['array'].add( d.index );
						build['weights']['array'].add( d.weight );
					} else {
						build['indices']['array'].add( 0 );
						build['weights']['array'].add( 0 );
					}
				}
			}

			// setup bind matrix

			if ( data.bindShapeMatrix ) {
				build['bindMatrix'] =Matrix4().copyFromArray( data.bindShapeMatrix ).transpose();
			} else {
				build['bindMatrix'] =Matrix4().identity();
			}

			// process bones and inverse bind matrix data

			for (int i = 0, l = jointSource.array.length; i < l; i ++ ) {
				final name = jointSource.array[ i ];
				final boneInverse =Matrix4().copyFromArray( inverseSource.array, i * inverseSource.stride ).transpose();
				build['joints'].add( { name: name, boneInverse: boneInverse } );
			}

			return build;
		}

		getController( id ) {
			return getBuild( library.controllers[ id ], buildController );
		}

		// image

		parseImage( xml ) {
			final Map<String,dynamic> data = {
				'init_from': getElementsByTagName( xml, 'init_from' )[ 0 ].textContent
			};

			library.images[ xml.getAttribute( 'id' ) ] = data;
		}

		buildImage( data ) {
			if ( data.build != null ) return data.build;
			return data.init_from;
		}

		getImage( id ) {
			final data = library.images[ id ];

			if ( data != null ) {
				return getBuild( data, buildImage );
			}

			console.warning( 'THREE.ColladaLoader: Couldn\'t find image with ID:', id );

			return null;
		}

		// effect

		parseEffect( xml ) {
			final Map<String,dynamic> data = {};

			for ( var i = 0, l = xml.childNodes.length; i < l; i ++ ) {
				final child = xml.childNodes[ i ];

				if ( child.nodeType != 1 ) continue;
				switch ( child.nodeName ) {
					case 'profile_COMMON':
						data['profile'] = parseEffectProfileCOMMON( child );
						break;
				}
			}

			library.effects[ xml.getAttribute( 'id' ) ] = data;
		}

		parseEffectProfileCOMMON( xml ) {
			final Map<String,dynamic> data = {
				'surfaces': {},
				'samplers': {}
			};

			for ( var i = 0, l = xml.childNodes.length; i < l; i ++ ) {
				final child = xml.childNodes[ i ];
				if ( child.nodeType != 1 ) continue;

				switch ( child.nodeName ) {
					case 'newparam':
						parseEffectNewparam( child, data );
						break;
					case 'technique':
						data.technique = parseEffectTechnique( child );
						break;
					case 'extra':
						data.extra = parseEffectExtra( child );
						break;
				}
			}

			return data;
		}

		parseEffectNewparam( xml, data ) {
			final sid = xml.getAttribute( 'sid' );

			for ( var i = 0, l = xml.childNodes.length; i < l; i ++ ) {
				final child = xml.childNodes[ i ];

				if ( child.nodeType != 1 ) continue;
				switch ( child.nodeName ) {
					case 'surface':
						data.surfaces[ sid ] = parseEffectSurface( child );
						break;
					case 'sampler2D':
						data.samplers[ sid ] = parseEffectSampler( child );
						break;
				}
			}
		}

		parseEffectSurface( xml ) {
			final Map<String,dynamic> data = {};

			for ( var i = 0, l = xml.childNodes.length; i < l; i ++ ) {
				final child = xml.childNodes[ i ];

				if ( child.nodeType != 1 ) continue;
				switch ( child.nodeName ) {
					case 'init_from':
						data['init_from'] = child.textContent;
						break;
				}
			}

			return data;
		}

		parseEffectSampler( xml ) {
			final data = {};

			for ( var i = 0, l = xml.childNodes.length; i < l; i ++ ) {
				final child = xml.childNodes[ i ];

				if ( child.nodeType != 1 ) continue;
				switch ( child.nodeName ) {
					case 'source':
						data['source'] = child.textContent;
						break;
				}
			}

			return data;
		}

		parseEffectTechnique( xml ) {
			final Map<String,dynamic> data = {};

			for ( var i = 0, l = xml.childNodes.length; i < l; i ++ ) {
				final child = xml.childNodes[ i ];

				if ( child.nodeType != 1 ) continue;

				switch ( child.nodeName ) {
					case 'constant':
					case 'lambert':
					case 'blinn':
					case 'phong':
						data['type'] = child.nodeName;
						data['parameters'] = parseEffectParameters( child );
						break;

					case 'extra':
						data['extra'] = parseEffectExtra( child );
						break;
				}
			}

			return data;
		}

		parseEffectParameters( xml ) {
			final Map<String,dynamic> data = {};

			for ( var i = 0, l = xml.childNodes.length; i < l; i ++ ) {
				final child = xml.childNodes[ i ];

				if ( child.nodeType != 1 ) continue;
				switch ( child.nodeName ) {
					case 'emission':
					case 'diffuse':
					case 'specular':
					case 'bump':
					case 'ambient':
					case 'shininess':
					case 'transparency':
						data[ child.nodeName ] = parseEffectParameter( child );
						break;
					case 'transparent':
						data[ child.nodeName ] = {
							'opaque': child.hasAttribute( 'opaque' ) ? child.getAttribute( 'opaque' ) : 'A_ONE',
							'data': parseEffectParameter( child )
						};
						break;
				}
			}

			return data;
		}

		parseEffectParameter( xml ) {
			final Map<String,dynamic> data = {};

			for ( var i = 0, l = xml.childNodes.length; i < l; i ++ ) {
				final child = xml.childNodes[ i ];

				if ( child.nodeType != 1 ) continue;
				switch ( child.nodeName ) {
					case 'color':
						data[ child.nodeName ] = parseFloats( child.textContent );
						break;
					case 'float':
						data[ child.nodeName ] = double.parse( child.textContent );
						break;
					case 'texture':
						data[ child.nodeName ] = { 'id': child.getAttribute( 'texture' ), 'extra': parseEffectParameterTexture( child ) };
						break;
				}
			}

			return data;
		}

		parseEffectParameterTexture( xml ) {
			final Map<String,dynamic> data = {
				'technique': {}
			};

			for ( var i = 0, l = xml.childNodes.length; i < l; i ++ ) {
				final child = xml.childNodes[ i ];

				if ( child.nodeType != 1 ) continue;

				switch ( child.nodeName ) {
					case 'extra':
						parseEffectParameterTextureExtra( child, data );
						break;
				}
			}

			return data;
		}

		parseEffectParameterTextureExtra( xml, data ) {
			for ( var i = 0, l = xml.childNodes.length; i < l; i ++ ) {
				final child = xml.childNodes[ i ];

				if ( child.nodeType != 1 ) continue;
				switch ( child.nodeName ) {
					case 'technique':
						parseEffectParameterTextureExtraTechnique( child, data );
						break;
				}
			}
		}

		parseEffectParameterTextureExtraTechnique( xml, data ) {
			for ( var i = 0, l = xml.childNodes.length; i < l; i ++ ) {
				final child = xml.childNodes[ i ];

				if ( child.nodeType != 1 ) continue;
				switch ( child.nodeName ) {
					case 'repeatU':
					case 'repeatV':
					case 'offsetU':
					case 'offsetV':
						data.technique[ child.nodeName ] = double.parse( child.textContent );
						break;

					case 'wrapU':
					case 'wrapV':
						// some files have values for wrapU/wrapV which become NaN via int.parse

						if ( child.textContent.toUpperCase() == 'TRUE' ) {
							data.technique[ child.nodeName ] = 1;
						} else if ( child.textContent.toUpperCase() == 'FALSE' ) {
							data.technique[ child.nodeName ] = 0;
						} else {
							data.technique[ child.nodeName ] = int.parse( child.textContent );
						}
						break;

					case 'bump':
						data[ child.nodeName ] = parseEffectExtraTechniqueBump( child );
						break;
				}
			}
		}

		parseEffectExtra( xml ) {
			final Map<String,dynamic> data = {};

			for ( var i = 0, l = xml.childNodes.length; i < l; i ++ ) {
				final child = xml.childNodes[ i ];

				if ( child.nodeType != 1 ) continue;
				switch ( child.nodeName ) {
					case 'technique':
						data.technique = parseEffectExtraTechnique( child );
						break;
				}
			}

			return data;
		}

		parseEffectExtraTechnique( xml ) {
			final Map<String,dynamic> data = {};

			for ( var i = 0, l = xml.childNodes.length; i < l; i ++ ) {
				final child = xml.childNodes[ i ];

				if ( child.nodeType != 1 ) continue;
				switch ( child.nodeName ) {
					case 'double_sided':
						data[ child.nodeName ] = int.parse( child.textContent );
						break;
					case 'bump':
						data[ child.nodeName ] = parseEffectExtraTechniqueBump( child );
						break;
				}
			}

			return data;
		}

		parseEffectExtraTechniqueBump( xml ) {
			final Map<String,dynamic> data = {};

			for ( var i = 0, l = xml.childNodes.length; i < l; i ++ ) {
				final child = xml.childNodes[ i ];

				if ( child.nodeType != 1 ) continue;
				switch ( child.nodeName ) {
					case 'texture':
						data[ child.nodeName ] = { 'id': child.getAttribute( 'texture' ), 'texcoord': child.getAttribute( 'texcoord' ), extra: parseEffectParameterTexture( child ) };
						break;
				}
			}

			return data;
		}

		buildEffect( data ) {
			return data;
		}

		getEffect( id ) {
			return getBuild( library.effects[ id ], buildEffect );
		}

		// material

		parseMaterial( xml ) {
			final Map<String,dynamic> data = {
				'name': xml.getAttribute( 'name' )
			};

			for ( var i = 0, l = xml.childNodes.length; i < l; i ++ ) {
				final child = xml.childNodes[ i ];
				if ( child.nodeType != 1 ) continue;

				switch ( child.nodeName ) {
					case 'instance_effect':
						data['url'] = parseId( child.getAttribute( 'url' ) );
						break;
				}
			}

			library.materials[ xml.getAttribute( 'id' ) ] = data;
		}

		getTextureLoader( image ) {
			var loader;

			var extension = image.slice( ( image.lastIndexOf( '.' ) - 1 >>> 0 ) + 2 ); // http://www.jstips.co/en/javascript/get-file-extension/
			extension = extension.toLowerCase();

			switch ( extension ) {
				case 'tga':
					loader = tgaLoader;
					break;
				default:
					loader = textureLoader;
			}

			return loader;
		}

		buildMaterial( data ) {
			final effect = getEffect( data.url );
			final technique = effect.profile.technique;
			var material;

			switch ( technique.type ) {
				case 'phong':
				case 'blinn':
					material =MeshPhongMaterial();
					break;
				case 'lambert':
					material =MeshLambertMaterial();
					break;
				default:
					material =MeshBasicMaterial();
					break;
			}

			material.name = data.name ?? '';

			getTexture( textureObject, [colorSpace]) {
				final sampler = effect.profile.samplers[ textureObject.id ];
				var image = null;

				// get image

				if ( sampler != null ) {
					final surface = effect.profile.surfaces[ sampler.source ];
					image = getImage( surface.init_from );
				} else {
					console.warning( 'THREE.ColladaLoader: Undefined sampler. Access image directly (see #12530).' );
					image = getImage( textureObject.id );
				}

				// create texture if image is avaiable

				if ( image != null ) {
					final loader = getTextureLoader( image );

					if ( loader != null ) {
						final texture = loader.load( image );
						final extra = textureObject.extra;

						if ( extra != null && extra.technique != null && isEmpty( extra.technique ) == false ) {
							final technique = extra.technique;

							texture.wrapS = technique.wrapU ? RepeatWrapping : ClampToEdgeWrapping;
							texture.wrapT = technique.wrapV ? RepeatWrapping : ClampToEdgeWrapping;

							texture.offset.set( technique.offsetU || 0, technique.offsetV || 0 );
							texture.repeat.set( technique.repeatU || 1, technique.repeatV || 1 );
						} else {
							texture.wrapS = RepeatWrapping;
							texture.wrapT = RepeatWrapping;
						}

						if ( colorSpace != null ) {
							texture.colorSpace = colorSpace;
						}

						return texture;
					} else {
						console.warning( 'THREE.ColladaLoader: Loader for texture %s not found.', image );
						return null;
					}
				} else {
					console.warning( 'THREE.ColladaLoader: Couldn\'t create texture with ID:', textureObject.id );
					return null;
				}
			}

			final parameters = technique.parameters;

			for ( final key in parameters ) {
				final parameter = parameters[ key ];

				switch ( key ) {
					case 'diffuse':
						if ( parameter.color ) material.color.fromArray( parameter.color );
						if ( parameter.texture ) material.map = getTexture( parameter.texture, SRGBColorSpace );
						break;
					case 'specular':
						if ( parameter.color && material.specular ) material.specular.fromArray( parameter.color );
						if ( parameter.texture ) material.specularMap = getTexture( parameter.texture );
						break;
					case 'bump':
						if ( parameter.texture ) material.normalMap = getTexture( parameter.texture );
						break;
					case 'ambient':
						if ( parameter.texture ) material.lightMap = getTexture( parameter.texture, SRGBColorSpace );
						break;
					case 'shininess':
						if ( parameter.float && material.shininess ) material.shininess = parameter.float;
						break;
					case 'emission':
						if ( parameter.color && material.emissive ) material.emissive.fromArray( parameter.color );
						if ( parameter.texture ) material.emissiveMap = getTexture( parameter.texture, SRGBColorSpace );
						break;
				}
			}

			material.color.convertSRGBToLinear();
			if ( material.specular ) material.specular.convertSRGBToLinear();
			if ( material.emissive ) material.emissive.convertSRGBToLinear();

			var transparent = parameters[ 'transparent' ];
			var transparency = parameters[ 'transparency' ];

			// <transparency> does not exist but <transparent>

			if ( transparency == null && transparent ) {
				transparency = {
					'float': 1
				};
			}

			// <transparent> does not exist but <transparency>

			if ( transparent == null && transparency ) {
				transparent = {
					'opaque': 'A_ONE',
					data: {
						'color': [ 1, 1, 1, 1 ]
					} };
			}

			if ( transparent && transparency ) {
				// handle case if a texture exists but no color

				if ( transparent.data.texture ) {
					material.transparent = true;
				} else {

					final color = transparent.data.color;
					switch ( transparent.opaque ) {
						case 'A_ONE':
							material.opacity = color[ 3 ] * transparency.float;
							break;
						case 'RGB_ZERO':
							material.opacity = 1 - ( color[ 0 ] * transparency.float );
							break;
						case 'A_ZERO':
							material.opacity = 1 - ( color[ 3 ] * transparency.float );
							break;
						case 'RGB_ONE':
							material.opacity = color[ 0 ] * transparency.float;
							break;
						default:
							console.warning( 'THREE.ColladaLoader: Invalid opaque type "%s" of transparent tag.', transparent.opaque );
					}

					if ( material.opacity < 1 ) material.transparent = true;
				}
			}

			if ( technique.extra != null && technique.extra.technique != null ) {
				final techniques = technique.extra.technique;

				for ( final k in techniques ) {
					final v = techniques[ k ];

					switch ( k ) {
						case 'double_sided':
							material.side = ( v == 1 ? DoubleSide : FrontSide );
							break;
						case 'bump':
							material.normalMap = getTexture( v.texture );
							material.normalScale =Vector2( 1, 1 );
							break;
					}
				}
			}

			return material;
		}

		getMaterial( id ) {
			return getBuild( library.materials[ id ], buildMaterial );
		}

		// camera

		parseCamera( xml ) {
			final data = {
				'name': xml.getAttribute( 'name' )
			};

			for ( var i = 0, l = xml.childNodes.length; i < l; i ++ ) {
				final child = xml.childNodes[ i ];
				if ( child.nodeType != 1 ) continue;

				switch ( child.nodeName ) {
					case 'optics':
						data.optics = parseCameraOptics( child );
						break;
				}
			}

			library.cameras[ xml.getAttribute( 'id' ) ] = data;
		}

		parseCameraOptics( xml ) {
			for ( var i = 0; i < xml.childNodes.length; i ++ ) {
				final child = xml.childNodes[ i ];
				switch ( child.nodeName ) {
					case 'technique_common':
						return parseCameraTechnique( child );
				}
			}
			return {};
		}

		parseCameraTechnique( xml ) {
			final data = {};
			for ( var i = 0; i < xml.childNodes.length; i ++ ) {
				final child = xml.childNodes[ i ];
				switch ( child.nodeName ) {
					case 'perspective':
					case 'orthographic':
						data['technique'] = child.nodeName;
						data['parameters'] = parseCameraParameters( child );
						break;
				}
			}

			return data;
		}

		parseCameraParameters( xml ) {
			final Map<String,dynamic> data = {};

			for ( var i = 0; i < xml.childNodes.length; i ++ ) {
				final child = xml.childNodes[ i ];

				switch ( child.nodeName ) {
					case 'xfov':
					case 'yfov':
					case 'xmag':
					case 'ymag':
					case 'znear':
					case 'zfar':
					case 'aspect_ratio':
						data[ child.nodeName ] = double.parse( child.textContent );
						break;
				}
			}

			return data;
		}

		buildCamera( data ) {
			var camera;

			switch ( data.optics.technique ) {
				case 'perspective':
					camera =PerspectiveCamera(
						data.optics.parameters.yfov,
						data.optics.parameters.aspect_ratio,
						data.optics.parameters.znear,
						data.optics.parameters.zfar
					);
					break;
				case 'orthographic':
					var ymag = data.optics.parameters.ymag;
					var xmag = data.optics.parameters.xmag;
					final aspectRatio = data.optics.parameters.aspect_ratio;

					xmag = ( xmag == null ) ? ( ymag * aspectRatio ) : xmag;
					ymag = ( ymag == null ) ? ( xmag / aspectRatio ) : ymag;

					xmag *= 0.5;
					ymag *= 0.5;

					camera =OrthographicCamera(
						- xmag, xmag, ymag, - ymag, // left, right, top, bottom
						data.optics.parameters.znear,
						data.optics.parameters.zfar
					);
					break;
				default:
					camera =PerspectiveCamera();
					break;
			}

			camera.name = data.name ?? '';
			return camera;
		}

		getCamera( id ) {
			final data = library.cameras[ id ];

			if ( data != null ) {
				return getBuild( data, buildCamera );
			}

			console.warning( 'THREE.ColladaLoader: Couldn\'t find camera with ID:', id );
			return null;
		}

		// light

		parseLight( xml ) {
			var data = {};

			for ( var i = 0, l = xml.childNodes.length; i < l; i ++ ) {
				final child = xml.childNodes[ i ];

				if ( child.nodeType != 1 ) continue;
				switch ( child.nodeName ) {
					case 'technique_common':
						data = parseLightTechnique( child );
						break;
				}
			}

			library.lights[ xml.getAttribute( 'id' ) ] = data;
		}

		parseLightTechnique( xml ) {
			final Map<String,dynamic> data = {};

			for ( var i = 0, l = xml.childNodes.length; i < l; i ++ ) {
				final child = xml.childNodes[ i ];

				if ( child.nodeType != 1 ) continue;
				switch ( child.nodeName ) {
					case 'directional':
					case 'point':
					case 'spot':
					case 'ambient':
						data.technique = child.nodeName;
						data.parameters = parseLightParameters( child );
				}
			}

			return data;
		}

		parseLightParameters( xml ) {
			final Map<String,dynamic> data = {};

			for ( var i = 0, l = xml.childNodes.length; i < l; i ++ ) {
				final child = xml.childNodes[ i ];

				if ( child.nodeType != 1 ) continue;
				switch ( child.nodeName ) {
					case 'color':
						final array = parseFloats( child.textContent );
						data['color'] =Color().copyFromArray( array ).convertSRGBToLinear();
						break;
					case 'falloff_angle':
						data['falloffAngle'] = double.parse( child.textContent );
						break;
					case 'quadratic_attenuation':
						final f = double.tryParse( child.textContent );
						data['distance'] = f != null? math.sqrt( 1 / f ) : 0;
						break;
				}
			}

			return data;
		}

		buildLight( data ) {
			var light;

			switch ( data.technique ) {
				case 'directional':
					light =DirectionalLight();
					break;
				case 'point':
					light =PointLight();
					break;
				case 'spot':
					light =SpotLight();
					break;
				case 'ambient':
					light =AmbientLight();
					break;
			}

			if ( data.parameters.color ) light.color.copy( data.parameters.color );
			if ( data.parameters.distance ) light.distance = data.parameters.distance;

			return light;
		}

		getLight( id ) {
			final data = library.lights[ id ];

			if ( data != null ) {
				return getBuild( data, buildLight );
			}

			console.warning( 'THREE.ColladaLoader: Couldn\'t find light with ID:', id );

			return null;
		}

		// geometry

		parseGeometry( xml ) {
			final Map<String,dynamic> data = {
				'name': xml.getAttribute( 'name' ),
				'sources': {},
				'vertices': {},
				'primitives': []
			};

			final mesh = getElementsByTagName( xml, 'mesh' )[ 0 ];

			// the following tags inside geometry are not supported yet (see https://github.com/mrdoob/three.js/pull/12606): convex_mesh, spline, brep
			if ( mesh == null ) return;

			for ( var i = 0; i < mesh.childNodes.length; i ++ ) {
				final child = mesh.childNodes[ i ];

				if ( child.nodeType != 1 ) continue;

				final id = child.getAttribute( 'id' );
				switch ( child.nodeName ) {
					case 'source':
						data['sources'][ id ] = parseSource( child );
						break;
					case 'vertices':
						// data.sources[ id ] = data.sources[ parseId( getElementsByTagName( child, 'input' )[ 0 ].getAttribute( 'source' ) ) ];
						data['vertices'] = parseGeometryVertices( child );
						break;
					case 'polygons':
						console.warning( 'THREE.ColladaLoader: Unsupported primitive type: ', child.nodeName );
						break;
					case 'lines':
					case 'linestrips':
					case 'polylist':
					case 'triangles':
						data['primitives'].add( parseGeometryPrimitive( child ) );
						break;
					default:
						console.info( child );
				}
			}
			library.geometries[ xml.getAttribute( 'id' ) ] = data;
		}

		parseSource( xml ) {
			final Map<String,dynamic> data = {
				'array': [],
				'stride': 3
			};

			for ( var i = 0; i < xml.childNodes.length; i ++ ) {
				final child = xml.childNodes[ i ];

				if ( child.nodeType != 1 ) continue;
				switch ( child.nodeName ) {
					case 'float_array':
						data['array'] = parseFloats( child.textContent );
						break;
					case 'Name_array':
						data['array'] = parseStrings( child.textContent );
						break;
					case 'technique_common':
						final accessor = getElementsByTagName( child, 'accessor' )[ 0 ];
						if ( accessor != null ) {
							data['stride'] = int.parse( accessor.getAttribute( 'stride' ) );
						}
						break;
				}
			}

			return data;
		}

		parseGeometryVertices( xml ) {
			final data = {};

			for ( var i = 0; i < xml.childNodes.length; i ++ ) {
				final child = xml.childNodes[ i ];
				if ( child.nodeType != 1 ) continue;
				data[ child.getAttribute( 'semantic' ) ] = parseId( child.getAttribute( 'source' ) );
			}

			return data;
		}

		parseGeometryPrimitive( xml ) {
			final Map<String,dynamic> primitive = {
				'type': xml.nodeName,
				'material': xml.getAttribute( 'material' ),
				'count': int.parse( xml.getAttribute( 'count' ) ),
				'inputs': {},
				'stride': 0,
				'hasUV': false
			};

			for ( var i = 0, l = xml.childNodes.length; i < l; i ++ ) {
				final child = xml.childNodes[ i ];

				if ( child.nodeType != 1 ) continue;
				switch ( child.nodeName ) {
					case 'input':
						final id = parseId( child.getAttribute( 'source' ) );
						final semantic = child.getAttribute( 'semantic' );
						final offset = int.parse( child.getAttribute( 'offset' ) );
						final set = int.parse( child.getAttribute( 'set' ) );
						final inputname = ( set > 0 ? semantic + set : semantic );
						primitive['inputs'][ inputname ] = { id: id, offset: offset };
						primitive['stride'] = math.max( primitive['stride'], offset + 1 );
						if ( semantic == 'TEXCOORD' ) primitive['hasUV'] = true;
						break;
					case 'vcount':
						primitive['vcount'] = parseInts( child.textContent );
						break;
					case 'p':
						primitive['p'] = parseInts( child.textContent );
						break;
				}
			}

			return primitive;
		}

		groupPrimitives( primitives ) {
			final Map<String,dynamic> build = {};

			for ( var i = 0; i < primitives.length; i ++ ) {
				final primitive = primitives[ i ];
				if ( build[ primitive.type ] == null ) build[ primitive.type ] = [];
				build[ primitive.type ].add( primitive );
			}

			return build;
		}

		checkUVCoordinates( primitives ) {
			var count = 0;

			for ( var i = 0, l = primitives.length; i < l; i ++ ) {
				final primitive = primitives[ i ];
				if ( primitive.hasUV == true ) {
					count ++;
				}
			}

			if ( count > 0 && count < primitives.length ) {
				primitives.uvsNeedsFix = true;
			}
		}

		buildGeometry( data ) {
			final Map<String,dynamic> build = {};

			final sources = data.sources;
			final vertices = data.vertices;
			final primitives = data.primitives;

			if ( primitives.length == 0 ) return {};

			// our goal is to create one buffer geometry for a single type of primitives
			// first, we group all primitives by their type

			final groupedPrimitives = groupPrimitives( primitives );

			for ( final type in groupedPrimitives ) {
				final primitiveType = groupedPrimitives[ type ];
				checkUVCoordinates( primitiveType );
				build[ type ] = buildGeometryType( primitiveType, sources, vertices );
			}

			return build;
		}

		buildGeometryType( primitives, sources, vertices ) {
			final build = {};

			final position = { 'array': [], 'stride': 0 };
			final normal = { 'array': [], 'stride': 0 };
			final uv = { 'array': [], 'stride': 0 };
			final uv1 = { 'array': [], 'stride': 0 };
			final color = { 'array': [], 'stride': 0 };

			final skinIndex = { 'array': [], 'stride': 4 };
			final skinWeight = { 'array': [], 'stride': 4 };

			final geometry =BufferGeometry();

			final materialKeys = [];

			var start = 0;

			for ( var p = 0; p < primitives.length; p ++ ) {
				final primitive = primitives[ p ];
				final inputs = primitive.inputs;

				// groups

				var count = 0;

				switch ( primitive.type ) {

					case 'lines':
					case 'linestrips':
						count = primitive.count * 2;
						break;

					case 'triangles':
						count = primitive.count * 3;
						break;

					case 'polylist':

						for ( var g = 0; g < primitive.count; g ++ ) {

							final vc = primitive.vcount[ g ];

							switch ( vc ) {

								case 3:
									count += 3; // single triangle
									break;

								case 4:
									count += 6; // quad, subdivided into two triangles
									break;

								default:
									count += ( vc - 2 ) * 3; // polylist with more than four vertices
									break;

							}

						}

						break;

					default:
						console.warning( 'THREE.ColladaLoader: Unknow primitive type:', primitive.type );

				}

				geometry.addGroup( start, count, p );
				start += count;

				// material

				if ( primitive.material ) {
					materialKeys.add( primitive.material );
				}

				// geometry data

				for ( final name in inputs ) {
					final input = inputs[ name ];

					switch ( name )	{
						case 'VERTEX':
							for ( final key in vertices ) {
								final id = vertices[ key ];

								switch ( key ) {
									case 'POSITION':
										final prevLength = position.array.length;
										buildGeometryData( primitive, sources[ id ], input.offset, position.array );
										position.stride = sources[ id ].stride;

										if ( sources.skinWeights && sources.skinIndices ) {

											buildGeometryData( primitive, sources.skinIndices, input.offset, skinIndex.array );
											buildGeometryData( primitive, sources.skinWeights, input.offset, skinWeight.array );

										}

										// see #3803

										if ( primitive.hasUV == false && primitives.uvsNeedsFix == true ) {
											final count = ( position.array.length - prevLength ) / position.stride;
											for ( var i = 0; i < count; i ++ ) {
												uv['array'].add( 0, 0 );
											}
										}
										break;
									case 'NORMAL':
										buildGeometryData( primitive, sources[ id ], input.offset, normal.array );
										normal.stride = sources[ id ].stride;
										break;

									case 'COLOR':
										buildGeometryData( primitive, sources[ id ], input.offset, color.array );
										color.stride = sources[ id ].stride;
										break;

									case 'TEXCOORD':
										buildGeometryData( primitive, sources[ id ], input.offset, uv.array );
										uv.stride = sources[ id ].stride;
										break;

									case 'TEXCOORD1':
										buildGeometryData( primitive, sources[ id ], input.offset, uv1.array );
										uv.stride = sources[ id ].stride;
										break;

									default:
										console.warning( 'THREE.ColladaLoader: Attribute "%s" not handled in geometry build process.', key );

								}

							}

							break;

						case 'NORMAL':
							buildGeometryData( primitive, sources[ input.id ], input.offset, normal.array );
							normal.stride = sources[ input.id ].stride;
							break;

						case 'COLOR':
							buildGeometryData( primitive, sources[ input.id ], input.offset, color.array, true );
							color.stride = sources[ input.id ].stride;
							break;

						case 'TEXCOORD':
							buildGeometryData( primitive, sources[ input.id ], input.offset, uv.array );
							uv.stride = sources[ input.id ].stride;
							break;

						case 'TEXCOORD1':
							buildGeometryData( primitive, sources[ input.id ], input.offset, uv1.array );
							uv1.stride = sources[ input.id ].stride;
							break;

					}

				}

			}

			// build geometry

			if ( position.array.length > 0 ) geometry.setAttributeFromString( 'position',Float32BufferAttribute( position.array, position.stride ) );
			if ( normal.array.length > 0 ) geometry.setAttributeFromString( 'normal',Float32BufferAttribute( normal.array, normal.stride ) );
			if ( color.array.length > 0 ) geometry.setAttributeFromString( 'color',Float32BufferAttribute( color.array, color.stride ) );
			if ( uv.array.length > 0 ) geometry.setAttributeFromString( 'uv',Float32BufferAttribute( uv.array, uv.stride ) );
			if ( uv1.array.length > 0 ) geometry.setAttributeFromString( 'uv1',Float32BufferAttribute( uv1.array, uv1.stride ) );

			if ( skinIndex.array.length > 0 ) geometry.setAttributeFromString( 'skinIndex',Float32BufferAttribute( skinIndex.array, skinIndex.stride ) );
			if ( skinWeight.array.length > 0 ) geometry.setAttributeFromString( 'skinWeight',Float32BufferAttribute( skinWeight.array, skinWeight.stride ) );

			build.data = geometry;
			build.type = primitives[ 0 ].type;
			build.materialKeys = materialKeys;

			return build;

		}

		buildGeometryData( primitive, source, offset, array, isColor = false ) {

			final indices = primitive.p;
			final stride = primitive.stride;
			final vcount = primitive.vcount;

			pushVector( i ) {

				var index = indices[ i + offset ] * sourceStride;
				final length = index + sourceStride;

				for ( ; index < length; index ++ ) {

					array.add( sourceArray[ index ] );

				}

				if ( isColor ) {

					// convert the vertex colors from srgb to linear if present
					final startIndex = array.length - sourceStride - 1;
					tempColor.setRGB(
						array[ startIndex + 0 ],
						array[ startIndex + 1 ],
						array[ startIndex + 2 ]
					).convertSRGBToLinear();

					array[ startIndex + 0 ] = tempColor.r;
					array[ startIndex + 1 ] = tempColor.g;
					array[ startIndex + 2 ] = tempColor.b;

				}

			}

			final sourceArray = source.array;
			final sourceStride = source.stride;

			if ( primitive.vcount != null ) {

				var index = 0;

				for ( var i = 0, l = vcount.length; i < l; i ++ ) {

					final count = vcount[ i ];

					if ( count == 4 ) {

						final a = index + stride * 0;
						final b = index + stride * 1;
						final c = index + stride * 2;
						final d = index + stride * 3;

						pushVector( a ); pushVector( b ); pushVector( d );
						pushVector( b ); pushVector( c ); pushVector( d );

					} else if ( count == 3 ) {

						final a = index + stride * 0;
						final b = index + stride * 1;
						final c = index + stride * 2;

						pushVector( a ); pushVector( b ); pushVector( c );

					} else if ( count > 4 ) {

						for ( var k = 1, kl = ( count - 2 ); k <= kl; k ++ ) {

							final a = index + stride * 0;
							final b = index + stride * k;
							final c = index + stride * ( k + 1 );

							pushVector( a ); pushVector( b ); pushVector( c );

						}

					}

					index += stride * count;

				}

			} else {

				for ( var i = 0, l = indices.length; i < l; i += stride ) {

					pushVector( i );

				}

			}

		}

		getGeometry( id ) {

			return getBuild( library.geometries[ id ], buildGeometry );

		}

		// kinematics

		parseKinematicsModel( xml ) {

			final data = {
				name: xml.getAttribute( 'name' ) || '',
				joints: {},
				links: []
			};

			for ( var i = 0; i < xml.childNodes.length; i ++ ) {

				final child = xml.childNodes[ i ];

				if ( child.nodeType != 1 ) continue;

				switch ( child.nodeName ) {

					case 'technique_common':
						parseKinematicsTechniqueCommon( child, data );
						break;

				}

			}

			library.kinematicsModels[ xml.getAttribute( 'id' ) ] = data;

		}

		buildKinematicsModel( data ) {

			if ( data.build != null ) return data.build;

			return data;

		}

		getKinematicsModel( id ) {

			return getBuild( library.kinematicsModels[ id ], buildKinematicsModel );

		}

		parseKinematicsTechniqueCommon( xml, data ) {

			for ( var i = 0; i < xml.childNodes.length; i ++ ) {

				final child = xml.childNodes[ i ];

				if ( child.nodeType != 1 ) continue;

				switch ( child.nodeName ) {

					case 'joint':
						data.joints[ child.getAttribute( 'sid' ) ] = parseKinematicsJoint( child );
						break;

					case 'link':
						data.links.add( parseKinematicsLink( child ) );
						break;

				}

			}

		}

		parseKinematicsJoint( xml ) {

			var data;

			for ( var i = 0; i < xml.childNodes.length; i ++ ) {

				final child = xml.childNodes[ i ];

				if ( child.nodeType != 1 ) continue;

				switch ( child.nodeName ) {

					case 'prismatic':
					case 'revolute':
						data = parseKinematicsJointParameter( child );
						break;

				}

			}

			return data;

		}

		parseKinematicsJointParameter( xml ) {

			final data = {
				sid: xml.getAttribute( 'sid' ),
				name: xml.getAttribute( 'name' ) || '',
				axis:Vector3(),
				limits: {
					min: 0,
					max: 0
				},
				type: xml.nodeName,
				static: false,
				zeroPosition: 0,
				middlePosition: 0
			};

			for ( var i = 0; i < xml.childNodes.length; i ++ ) {

				final child = xml.childNodes[ i ];

				if ( child.nodeType != 1 ) continue;

				switch ( child.nodeName ) {

					case 'axis':
						final array = parseFloats( child.textContent );
						data.axis.fromArray( array );
						break;
					case 'limits':
						final max = child.getElementsByTagName( 'max' )[ 0 ];
						final min = child.getElementsByTagName( 'min' )[ 0 ];

						data.limits.max = double.parse( max.textContent );
						data.limits.min = double.parse( min.textContent );
						break;

				}

			}

			// if min is equal to or greater than max, consider the joint static

			if ( data.limits.min >= data.limits.max ) {

				data.static = true;

			}

			// calculate middle position

			data.middlePosition = ( data.limits.min + data.limits.max ) / 2.0;

			return data;

		}

		parseKinematicsLink( xml ) {

			final data = {
				sid: xml.getAttribute( 'sid' ),
				name: xml.getAttribute( 'name' ) || '',
				attachments: [],
				transforms: []
			};

			for ( var i = 0; i < xml.childNodes.length; i ++ ) {

				final child = xml.childNodes[ i ];

				if ( child.nodeType != 1 ) continue;

				switch ( child.nodeName ) {

					case 'attachment_full':
						data.attachments.add( parseKinematicsAttachment( child ) );
						break;

					case 'matrix':
					case 'translate':
					case 'rotate':
						data.transforms.add( parseKinematicsTransform( child ) );
						break;

				}

			}

			return data;

		}

		parseKinematicsAttachment( xml ) {

			final data = {
				joint: xml.getAttribute( 'joint' ).split( '/' ).pop(),
				transforms: [],
				links: []
			};

			for ( var i = 0; i < xml.childNodes.length; i ++ ) {

				final child = xml.childNodes[ i ];

				if ( child.nodeType != 1 ) continue;

				switch ( child.nodeName ) {

					case 'link':
						data.links.add( parseKinematicsLink( child ) );
						break;

					case 'matrix':
					case 'translate':
					case 'rotate':
						data.transforms.add( parseKinematicsTransform( child ) );
						break;

				}

			}

			return data;

		}

		parseKinematicsTransform( xml ) {

			final data = {
				type: xml.nodeName
			};

			final array = parseFloats( xml.textContent );

			switch ( data.type ) {

				case 'matrix':
					data.obj =Matrix4();
					data.obj.fromArray( array ).transpose();
					break;

				case 'translate':
					data.obj =Vector3();
					data.obj.fromArray( array );
					break;

				case 'rotate':
					data.obj =Vector3();
					data.obj.fromArray( array );
					data.angle = MathUtils.degToRad( array[ 3 ] );
					break;

			}

			return data;

		}

		// physics

		parsePhysicsModel( xml ) {

			final data = {
				name: xml.getAttribute( 'name' ) || '',
				rigidBodies: {}
			};

			for ( var i = 0; i < xml.childNodes.length; i ++ ) {

				final child = xml.childNodes[ i ];

				if ( child.nodeType != 1 ) continue;

				switch ( child.nodeName ) {

					case 'rigid_body':
						data.rigidBodies[ child.getAttribute( 'name' ) ] = {};
						parsePhysicsRigidBody( child, data.rigidBodies[ child.getAttribute( 'name' ) ] );
						break;

				}

			}

			library.physicsModels[ xml.getAttribute( 'id' ) ] = data;

		}

		parsePhysicsRigidBody( xml, data ) {

			for ( var i = 0; i < xml.childNodes.length; i ++ ) {

				final child = xml.childNodes[ i ];

				if ( child.nodeType != 1 ) continue;

				switch ( child.nodeName ) {

					case 'technique_common':
						parsePhysicsTechniqueCommon( child, data );
						break;

				}

			}

		}

		parsePhysicsTechniqueCommon( xml, data ) {

			for ( var i = 0; i < xml.childNodes.length; i ++ ) {

				final child = xml.childNodes[ i ];

				if ( child.nodeType != 1 ) continue;

				switch ( child.nodeName ) {

					case 'inertia':
						data.inertia = parseFloats( child.textContent );
						break;

					case 'mass':
						data.mass = parseFloats( child.textContent )[ 0 ];
						break;

				}

			}

		}

		// scene

		parseKinematicsScene( xml ) {

			final data = {
				bindJointAxis: []
			};

			for ( var i = 0; i < xml.childNodes.length; i ++ ) {

				final child = xml.childNodes[ i ];

				if ( child.nodeType != 1 ) continue;

				switch ( child.nodeName ) {

					case 'bind_joint_axis':
						data.bindJointAxis.add( parseKinematicsBindJointAxis( child ) );
						break;

				}

			}

			library.kinematicsScenes[ parseId( xml.getAttribute( 'url' ) ) ] = data;

		}

		parseKinematicsBindJointAxis( xml ) {

			final data = {
				target: xml.getAttribute( 'target' ).split( '/' ).pop()
			};

			for ( var i = 0; i < xml.childNodes.length; i ++ ) {

				final child = xml.childNodes[ i ];

				if ( child.nodeType != 1 ) continue;

				switch ( child.nodeName ) {

					case 'axis':
						final param = child.getElementsByTagName( 'param' )[ 0 ];
						data.axis = param.textContent;
						final tmpJointIndex = data.axis.split( 'inst_' ).pop().split( 'axis' )[ 0 ];
						data.jointIndex = tmpJointIndex.substring( 0, tmpJointIndex.length - 1 );
						break;

				}

			}

			return data;

		}

		buildKinematicsScene( data ) {

			if ( data.build != null ) return data.build;

			return data;

		}

		getKinematicsScene( id ) {

			return getBuild( library.kinematicsScenes[ id ], buildKinematicsScene );

		}

		setupKinematics() {

			final kinematicsModelId = Object.keys( library.kinematicsModels )[ 0 ];
			final kinematicsSceneId = Object.keys( library.kinematicsScenes )[ 0 ];
			final visualSceneId = Object.keys( library.visualScenes )[ 0 ];

			if ( kinematicsModelId == null || kinematicsSceneId == null ) return;

			final kinematicsModel = getKinematicsModel( kinematicsModelId );
			final kinematicsScene = getKinematicsScene( kinematicsSceneId );
			final visualScene = getVisualScene( visualSceneId );

			final bindJointAxis = kinematicsScene.bindJointAxis;
			final jointMap = {};

			for ( var i = 0, l = bindJointAxis.length; i < l; i ++ ) {

				final axis = bindJointAxis[ i ];

				// the result of the following query is an element of type 'translate', 'rotate','scale' or 'matrix'

				final targetElement = collada.querySelector( '[sid="' + axis.target + '"]' );

				if ( targetElement ) {

					// get the parent of the transform element

					final parentVisualElement = targetElement.parentElement;

					// connect the joint of the kinematics model with the element in the visual scene

					connect( axis.jointIndex, parentVisualElement );

				}

			}

			connect( jointIndex, visualElement ) {

				final visualElementName = visualElement.getAttribute( 'name' );
				final joint = kinematicsModel.joints[ jointIndex ];

				visualScene.traverse( ( object ) {

					if ( object.name == visualElementName ) {

						jointMap[ jointIndex ] = {
							object: object,
							transforms: buildTransformList( visualElement ),
							joint: joint,
							position: joint.zeroPosition
						};

					}

				} );

			}

			final m0 =Matrix4();

			kinematics = {

				joints: kinematicsModel && kinematicsModel.joints,

				getJointValue: ( jointIndex ) {

					final jointData = jointMap[ jointIndex ];

					if ( jointData ) {

						return jointData.position;

					} else {

						console.warning( 'THREE.ColladaLoader: Joint ' + jointIndex + ' doesn\'t exist.' );

					}

				},

				setJointValue: ( jointIndex, value ) {

					final jointData = jointMap[ jointIndex ];

					if ( jointData ) {

						final joint = jointData.joint;

						if ( value > joint.limits.max || value < joint.limits.min ) {

							console.warning( 'THREE.ColladaLoader: Joint ' + jointIndex + ' value ' + value + ' outside of limits (min: ' + joint.limits.min + ', max: ' + joint.limits.max + ').' );

						} else if ( joint.static ) {

							console.warning( 'THREE.ColladaLoader: Joint ' + jointIndex + ' is static.' );

						} else {

							final object = jointData.object;
							final axis = joint.axis;
							final transforms = jointData.transforms;

							matrix.identity();

							// each update, we have to apply all transforms in the correct order

							for ( var i = 0; i < transforms.length; i ++ ) {

								final transform = transforms[ i ];

								// if there is a connection of the transform node with a joint, apply the joint value

								if ( transform.sid && transform.sid.indexOf( jointIndex ) != - 1 ) {

									switch ( joint.type ) {

										case 'revolute':
											matrix.multiply( m0.makeRotationAxis( axis, MathUtils.degToRad( value ) ) );
											break;

										case 'prismatic':
											matrix.multiply( m0.makeTranslation( axis.x * value, axis.y * value, axis.z * value ) );
											break;

										default:
											console.warning( 'THREE.ColladaLoader: Unknown joint type: ' + joint.type );
											break;

									}

								} else {

									switch ( transform.type ) {

										case 'matrix':
											matrix.multiply( transform.obj );
											break;

										case 'translate':
											matrix.multiply( m0.makeTranslation( transform.obj.x, transform.obj.y, transform.obj.z ) );
											break;

										case 'scale':
											matrix.scale( transform.obj );
											break;

										case 'rotate':
											matrix.multiply( m0.makeRotationAxis( transform.obj, transform.angle ) );
											break;

									}

								}

							}

							object.matrix.copy( matrix );
							object.matrix.decompose( object.position, object.quaternion, object.scale );

							jointMap[ jointIndex ].position = value;

						}

					} else {

						console.log( 'THREE.ColladaLoader: ' + jointIndex + ' does not exist.' );

					}

				}

			};

		}

		buildTransformList( node ) {

			final transforms = [];

			final xml = collada.querySelector( '[id="' + node.id + '"]' );

			for ( var i = 0; i < xml.childNodes.length; i ++ ) {

				final child = xml.childNodes[ i ];

				if ( child.nodeType != 1 ) continue;

				var array, vector;

				switch ( child.nodeName ) {

					case 'matrix':
						array = parseFloats( child.textContent );
						final matrix =Matrix4().fromArray( array ).transpose();
						transforms.add( {
							sid: child.getAttribute( 'sid' ),
							type: child.nodeName,
							obj: matrix
						} );
						break;

					case 'translate':
					case 'scale':
						array = parseFloats( child.textContent );
						vector =Vector3().fromArray( array );
						transforms.add( {
							sid: child.getAttribute( 'sid' ),
							type: child.nodeName,
							obj: vector
						} );
						break;

					case 'rotate':
						array = parseFloats( child.textContent );
						vector =Vector3().fromArray( array );
						final angle = MathUtils.degToRad( array[ 3 ] );
						transforms.add( {
							sid: child.getAttribute( 'sid' ),
							type: child.nodeName,
							obj: vector,
							angle: angle
						} );
						break;

				}

			}

			return transforms;

		}

		// nodes

		prepareNodes( xml ) {

			final elements = xml.getElementsByTagName( 'node' );

			// ensure all node elements have id attributes

			for ( var i = 0; i < elements.length; i ++ ) {

				final element = elements[ i ];

				if ( element.hasAttribute( 'id' ) == false ) {

					element.setAttributeFromString( 'id', generateId() );

				}

			}

		}

		final matrix =Matrix4();
		final vector =Vector3();

		parseNode( xml ) {

			final data = {
				name: xml.getAttribute( 'name' ) || '',
				type: xml.getAttribute( 'type' ),
				id: xml.getAttribute( 'id' ),
				sid: xml.getAttribute( 'sid' ),
				matrix:Matrix4(),
				nodes: [],
				instanceCameras: [],
				instanceControllers: [],
				instanceLights: [],
				instanceGeometries: [],
				instanceNodes: [],
				transforms: {}
			};

			for ( var i = 0; i < xml.childNodes.length; i ++ ) {

				final child = xml.childNodes[ i ];

				if ( child.nodeType != 1 ) continue;

				var array;

				switch ( child.nodeName ) {

					case 'node':
						data.nodes.add( child.getAttribute( 'id' ) );
						parseNode( child );
						break;

					case 'instance_camera':
						data.instanceCameras.add( parseId( child.getAttribute( 'url' ) ) );
						break;

					case 'instance_controller':
						data.instanceControllers.add( parseNodeInstance( child ) );
						break;

					case 'instance_light':
						data.instanceLights.add( parseId( child.getAttribute( 'url' ) ) );
						break;

					case 'instance_geometry':
						data.instanceGeometries.add( parseNodeInstance( child ) );
						break;

					case 'instance_node':
						data.instanceNodes.add( parseId( child.getAttribute( 'url' ) ) );
						break;

					case 'matrix':
						array = parseFloats( child.textContent );
						data.matrix.multiply( matrix.fromArray( array ).transpose() );
						data.transforms[ child.getAttribute( 'sid' ) ] = child.nodeName;
						break;

					case 'translate':
						array = parseFloats( child.textContent );
						vector.fromArray( array );
						data.matrix.multiply( matrix.makeTranslation( vector.x, vector.y, vector.z ) );
						data.transforms[ child.getAttribute( 'sid' ) ] = child.nodeName;
						break;

					case 'rotate':
						array = parseFloats( child.textContent );
						final angle = MathUtils.degToRad( array[ 3 ] );
						data.matrix.multiply( matrix.makeRotationAxis( vector.fromArray( array ), angle ) );
						data.transforms[ child.getAttribute( 'sid' ) ] = child.nodeName;
						break;

					case 'scale':
						array = parseFloats( child.textContent );
						data.matrix.scale( vector.fromArray( array ) );
						data.transforms[ child.getAttribute( 'sid' ) ] = child.nodeName;
						break;

					case 'extra':
						break;

					default:
						console.log( child );

				}

			}

			if ( hasNode( data.id ) ) {

				console.warning( 'THREE.ColladaLoader: There is already a node with ID %s. Exclude current node from further processing.', data.id );

			} else {

				library.nodes[ data.id ] = data;

			}

			return data;

		}

		parseNodeInstance( xml ) {

			final data = {
				id: parseId( xml.getAttribute( 'url' ) ),
				materials: {},
				skeletons: []
			};

			for ( var i = 0; i < xml.childNodes.length; i ++ ) {

				final child = xml.childNodes[ i ];

				switch ( child.nodeName ) {

					case 'bind_material':
						final instances = child.getElementsByTagName( 'instance_material' );

						for ( var j = 0; j < instances.length; j ++ ) {

							final instance = instances[ j ];
							final symbol = instance.getAttribute( 'symbol' );
							final target = instance.getAttribute( 'target' );

							data.materials[ symbol ] = parseId( target );

						}

						break;

					case 'skeleton':
						data.skeletons.add( parseId( child.textContent ) );
						break;

					default:
						break;

				}

			}

			return data;

		}

		buildSkeleton( skeletons, joints ) {

			final boneData = [];
			final sortedBoneData = [];

			var i, j, data;

			// a skeleton can have multiple root bones. collada expresses this
			// situtation with multiple "skeleton" tags per controller instance

			for ( i = 0; i < skeletons.length; i ++ ) {

				final skeleton = skeletons[ i ];

				var root;

				if ( hasNode( skeleton ) ) {

					root = getNode( skeleton );
					buildBoneHierarchy( root, joints, boneData );

				} else if ( hasVisualScene( skeleton ) ) {

					// handle case where the skeleton refers to the visual scene (#13335)

					final visualScene = library.visualScenes[ skeleton ];
					final children = visualScene.children;

					for ( var j = 0; j < children.length; j ++ ) {

						final child = children[ j ];

						if ( child.type == 'JOINT' ) {

							final root = getNode( child.id );
							buildBoneHierarchy( root, joints, boneData );

						}

					}

				} else {

					console.error( 'THREE.ColladaLoader: Unable to find root bone of skeleton with ID:', skeleton );

				}

			}

			// sort bone data (the order is defined in the corresponding controller)

			for ( i = 0; i < joints.length; i ++ ) {

				for ( j = 0; j < boneData.length; j ++ ) {

					data = boneData[ j ];

					if ( data.bone.name == joints[ i ].name ) {

						sortedBoneData[ i ] = data;
						data.processed = true;
						break;

					}

				}

			}

			// add unprocessed bone data at the end of the list

			for ( i = 0; i < boneData.length; i ++ ) {

				data = boneData[ i ];

				if ( data.processed == false ) {

					sortedBoneData.add( data );
					data.processed = true;

				}

			}

			// setup arrays for skeleton creation

			final bones = [];
			final boneInverses = [];

			for ( i = 0; i < sortedBoneData.length; i ++ ) {

				data = sortedBoneData[ i ];

				bones.add( data.bone );
				boneInverses.add( data.boneInverse );

			}

			returnSkeleton( bones, boneInverses );

		}

		buildBoneHierarchy( root, joints, boneData ) {

			// setup bone data from visual scene

			root.traverse( ( object ) {

				if ( object.isBone == true ) {

					var boneInverse;

					// retrieve the boneInverse from the controller data

					for ( var i = 0; i < joints.length; i ++ ) {

						final joint = joints[ i ];

						if ( joint.name == object.name ) {

							boneInverse = joint.boneInverse;
							break;

						}

					}

					if ( boneInverse == null ) {

						// Unfortunately, there can be joints in the visual scene that are not part of the
						// corresponding controller. In this case, we have to create a dummy boneInverse matrix
						// for the respective bone. This bone won't affect any vertices, because there are no skin indices
						// and weights defined for it. But we still have to add the bone to the sorted bone list in order to
						// ensure a correct animation of the model.

						boneInverse =Matrix4();

					}

					boneData.add( { bone: object, boneInverse: boneInverse, processed: false } );

				}

			} );

		}

		buildNode( data ) {

			final objects = [];

			final matrix = data.matrix;
			final nodes = data.nodes;
			final type = data.type;
			final instanceCameras = data.instanceCameras;
			final instanceControllers = data.instanceControllers;
			final instanceLights = data.instanceLights;
			final instanceGeometries = data.instanceGeometries;
			final instanceNodes = data.instanceNodes;

			// nodes

			for ( var i = 0, l = nodes.length; i < l; i ++ ) {

				objects.add( getNode( nodes[ i ] ) );

			}

			// instance cameras

			for ( var i = 0, l = instanceCameras.length; i < l; i ++ ) {

				final instanceCamera = getCamera( instanceCameras[ i ] );

				if ( instanceCamera != null ) {

					objects.add( instanceCamera.clone() );

				}

			}

			// instance controllers

			for ( var i = 0, l = instanceControllers.length; i < l; i ++ ) {

				final instance = instanceControllers[ i ];
				final controller = getController( instance.id );
				final geometries = getGeometry( controller.id );
				final newObjects = buildObjects( geometries, instance.materials );

				final skeletons = instance.skeletons;
				final joints = controller.skin.joints;

				final skeleton = buildSkeleton( skeletons, joints );

				for ( var j = 0, jl = newObjects.length; j < jl; j ++ ) {

					final object = newObjects[ j ];

					if ( object.isSkinnedMesh ) {

						object.bind( skeleton, controller.skin.bindMatrix );
						object.normalizeSkinWeights();

					}

					objects.add( object );

				}

			}

			// instance lights

			for ( var i = 0, l = instanceLights.length; i < l; i ++ ) {

				final instanceLight = getLight( instanceLights[ i ] );

				if ( instanceLight != null ) {

					objects.add( instanceLight.clone() );

				}

			}

			// instance geometries

			for ( var i = 0, l = instanceGeometries.length; i < l; i ++ ) {

				final instance = instanceGeometries[ i ];

				// a single geometry instance in collada can lead to multiple object3Ds.
				// this is the case when primitives are combined like triangles and lines

				final geometries = getGeometry( instance.id );
				final newObjects = buildObjects( geometries, instance.materials );

				for ( var j = 0, jl = newObjects.length; j < jl; j ++ ) {

					objects.add( newObjects[ j ] );

				}

			}

			// instance nodes

			for ( var i = 0, l = instanceNodes.length; i < l; i ++ ) {

				objects.add( getNode( instanceNodes[ i ] ).clone() );

			}

			var object;

			if ( nodes.length == 0 && objects.length == 1 ) {

				object = objects[ 0 ];

			} else {

				object = ( type == 'JOINT' ) ?Bone() :Group();

				for ( var i = 0; i < objects.length; i ++ ) {

					object.add( objects[ i ] );

				}

			}

			object.name = ( type == 'JOINT' ) ? data.sid : data.name;
			object.matrix.copy( matrix );
			object.matrix.decompose( object.position, object.quaternion, object.scale );

			return object;

		}

		final fallbackMaterial =MeshBasicMaterial( {
			name: Loader.DEFAULT_MATERIAL_NAME,
			color: 0xff00ff
		} );

		resolveMaterialBinding( keys, instanceMaterials ) {

			final materials = [];

			for ( var i = 0, l = keys.length; i < l; i ++ ) {

				final id = instanceMaterials[ keys[ i ] ];

				if ( id == null ) {

					console.warning( 'THREE.ColladaLoader: Material with key %s not found. Apply fallback material.', keys[ i ] );
					materials.add( fallbackMaterial );

				} else {

					materials.add( getMaterial( id ) );

				}

			}

			return materials;

		}

		buildObjects( geometries, instanceMaterials ) {

			final objects = [];

			for ( final type in geometries ) {

				final geometry = geometries[ type ];

				final materials = resolveMaterialBinding( geometry.materialKeys, instanceMaterials );

				// handle case if no materials are defined

				if ( materials.length == 0 ) {

					if ( type == 'lines' || type == 'linestrips' ) {

						materials.add(LineBasicMaterial() );

					} else {

						materials.add(MeshPhongMaterial() );

					}

				}

				// Collada allows to use phong and lambert materials with lines. Replacing these cases with LineBasicMaterial.

				if ( type == 'lines' || type == 'linestrips' ) {

					for ( var i = 0, l = materials.length; i < l; i ++ ) {

						final material = materials[ i ];

						if ( material.isMeshPhongMaterial == true || material.isMeshLambertMaterial == true ) {

							final lineMaterial =LineBasicMaterial();

							// copy compatible properties

							lineMaterial.color.copy( material.color );
							lineMaterial.opacity = material.opacity;
							lineMaterial.transparent = material.transparent;

							// replace material

							materials[ i ] = lineMaterial;

						}

					}

				}

				// regard skinning

				final skinning = ( geometry.data.attributes.skinIndex != null );

				// choose between a single or multi materials (material array)

				final material = ( materials.length == 1 ) ? materials[ 0 ] : materials;

				// now create a specific 3D object

				var object;

				switch ( type ) {

					case 'lines':
						object =LineSegments( geometry.data, material );
						break;

					case 'linestrips':
						object =Line( geometry.data, material );
						break;

					case 'triangles':
					case 'polylist':
						if ( skinning ) {

							object =SkinnedMesh( geometry.data, material );

						} else {

							object =Mesh( geometry.data, material );

						}

						break;

				}

				objects.add( object );

			}

			return objects;

		}

		hasNode( id ) {

			return library.nodes[ id ] != null;

		}

		getNode( id ) {

			return getBuild( library.nodes[ id ], buildNode );

		}

		// visual scenes

		parseVisualScene( xml ) {

			final data = {
				name: xml.getAttribute( 'name' ),
				children: []
			};

			prepareNodes( xml );

			final elements = getElementsByTagName( xml, 'node' );

			for ( var i = 0; i < elements.length; i ++ ) {

				data.children.add( parseNode( elements[ i ] ) );

			}

			library.visualScenes[ xml.getAttribute( 'id' ) ] = data;

		}

		buildVisualScene( data ) {

			final group =Group();
			group.name = data.name;

			final children = data.children;

			for ( var i = 0; i < children.length; i ++ ) {

				final child = children[ i ];

				group.add( getNode( child.id ) );

			}

			return group;

		}

		hasVisualScene( id ) {

			return library.visualScenes[ id ] != null;

		}

		getVisualScene( id ) {

			return getBuild( library.visualScenes[ id ], buildVisualScene );

		}

		// scenes

		parseScene( xml ) {

			final instance = getElementsByTagName( xml, 'instance_visual_scene' )[ 0 ];
			return getVisualScene( parseId( instance.getAttribute( 'url' ) ) );

		}

		setupAnimations() {

			final clips = library.clips;

			if ( isEmpty( clips ) == true ) {

				if ( isEmpty( library.animations ) == false ) {

					// if there are animations but no clips, we create a default clip for playback

					final tracks = [];

					for ( final id in library.animations ) {

						final animationTracks = getAnimation( id );

						for ( var i = 0, l = animationTracks.length; i < l; i ++ ) {

							tracks.add( animationTracks[ i ] );

						}

					}

					animations.add(AnimationClip( 'default', - 1, tracks ) );

				}

			} else {

				for ( final id in clips ) {

					animations.add( getAnimationClip( id ) );

				}

			}

		}

		// convert the parser error element into text with each child elements text
		// separated bylines.

		parserErrorToText( parserError ) {

			var result = '';
			final stack = [ parserError ];

			while ( stack.length ) {

				final node = stack.shift();

				if ( node.nodeType == Node.TEXT_NODE ) {

					result += node.textContent;

				} else {

					result += '\n';
					stack.add.apply( stack, node.childNodes );

				}

			}

			return result.trim();

		}

		if ( text.length == 0 ) {

			return { scene:Scene() };

		}

		final xml =DOMParser().parseFromString( text, 'application/xml' );

		final collada = getElementsByTagName( xml, 'COLLADA' )[ 0 ];

		final parserError = xml.getElementsByTagName( 'parsererror' )[ 0 ];
		if ( parserError != null ) {

			// Chrome will return parser error with a div in it

			final errorElement = getElementsByTagName( parserError, 'div' )[ 0 ];
			var errorText;

			if ( errorElement ) {

				errorText = errorElement.textContent;

			} else {

				errorText = parserErrorToText( parserError );

			}

			console.error( 'THREE.ColladaLoader: Failed to parse collada file.\n', errorText );

			return null;

		}

		// metadata

		final version = collada.getAttribute( 'version' );
		console.debug( 'THREE.ColladaLoader: File version', version );

		final asset = parseAsset( getElementsByTagName( collada, 'asset' )[ 0 ] );
		final textureLoader =TextureLoader( this.manager );
		textureLoader.setPath( this.resourcePath ?? path ).setCrossOrigin( this.crossOrigin );

		var tgaLoader;

		if ( TGALoader ) {

			tgaLoader =TGALoader( this.manager );
			tgaLoader.setPath( this.resourcePath ?? path );

		}

		//

		final tempColor =Color();
		final animations = [];
		var kinematics = {};
		var count = 0;

		//

		final library = {
			animations: {},
			clips: {},
			controllers: {},
			images: {},
			effects: {},
			materials: {},
			cameras: {},
			lights: {},
			geometries: {},
			nodes: {},
			visualScenes: {},
			kinematicsModels: {},
			physicsModels: {},
			kinematicsScenes: {}
		};

		parseLibrary( collada, 'library_animations', 'animation', parseAnimation );
		parseLibrary( collada, 'library_animation_clips', 'animation_clip', parseAnimationClip );
		parseLibrary( collada, 'library_controllers', 'controller', parseController );
		parseLibrary( collada, 'library_images', 'image', parseImage );
		parseLibrary( collada, 'library_effects', 'effect', parseEffect );
		parseLibrary( collada, 'library_materials', 'material', parseMaterial );
		parseLibrary( collada, 'library_cameras', 'camera', parseCamera );
		parseLibrary( collada, 'library_lights', 'light', parseLight );
		parseLibrary( collada, 'library_geometries', 'geometry', parseGeometry );
		parseLibrary( collada, 'library_nodes', 'node', parseNode );
		parseLibrary( collada, 'library_visual_scenes', 'visual_scene', parseVisualScene );
		parseLibrary( collada, 'library_kinematics_models', 'kinematics_model', parseKinematicsModel );
		parseLibrary( collada, 'library_physics_models', 'physics_model', parsePhysicsModel );
		parseLibrary( collada, 'scene', 'instance_kinematics_scene', parseKinematicsScene );

		buildLibrary( library.animations, buildAnimation );
		buildLibrary( library.clips, buildAnimationClip );
		buildLibrary( library.controllers, buildController );
		buildLibrary( library.images, buildImage );
		buildLibrary( library.effects, buildEffect );
		buildLibrary( library.materials, buildMaterial );
		buildLibrary( library.cameras, buildCamera );
		buildLibrary( library.lights, buildLight );
		buildLibrary( library.geometries, buildGeometry );
		buildLibrary( library.visualScenes, buildVisualScene );

		setupAnimations();
		setupKinematics();

		final scene = parseScene( getElementsByTagName( collada, 'scene' )[ 0 ] );
		scene.animations = animations;

		if ( asset.upAxis == 'Z_UP' ) {

			console.warning( 'THREE.ColladaLoader: You are loading an asset with a Z-UP coordinate system. The loader just rotates the asset to transform it into Y-UP. The vertex data are not converted, see #24289.' );
			scene.rotation.set( - Math.PI / 2, 0, 0 );

		}

		scene.scale.multiplyScalar( asset.unit );

		return {
			get animations() {

				console.warning( 'THREE.ColladaLoader: Please access animations over scene.animations now.' );
				return animations;

			},
			kinematics: kinematics,
			library: library,
			scene: scene
		};

	}
}
