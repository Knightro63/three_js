import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter_gl/flutter_gl.dart';
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';
import 'package:three_js_core_loaders/three_js_core_loaders.dart';

class USDAParser {

	parse(String text) {
		final Map data = {};
		final lines = text.split( '\n' );

		String? string;
		Map target = data;

		final stack = [data];

		// debugger;

		for ( final line in lines ) {
			if (line.contains('=')){
				final assignment = line.split( '=' );
				final lhs = assignment[ 0 ].trim();
				final rhs = assignment[ 1 ].trim();

				if ( rhs.endsWith( '{' ) ) {
					final Map group = {};
					stack.add(group);

					target[ lhs ] = group;
					target = group;
				} 
        else {
					target[ lhs ] = rhs;
				}
			} 
      else if (line.endsWith( '{' )) {
				final group = target[string] ?? {};
				stack.add( group );

				target[string] = group;
				target = group;
			} 
      else if ( line.endsWith( '}' ) ) {
				stack.removeLast();
				if (stack.isEmpty) continue;
				target = stack[ stack.length - 1 ];
			} 
      else if ( line.endsWith( '(' ) ) {
				final meta = {};
				stack.add(meta);

				string = line.split( '(' )[ 0 ].trim() ?? string;

				target[string] = meta;
				target = meta;

			} 
      else if(line.endsWith( ')' ) ) {
				stack.removeLast();
				target = stack[ stack.length - 1 ];
			} 
      else {
				string = line.trim();
			}
		}

		return data;
	}
}

class USDZLoader extends Loader {
  late final FileLoader _loader;

	USDZLoader([super.manager]){
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
  Future<BufferGeometry?> fromNetwork(Uri uri) async{
    _init();
    ThreeFile? tf = await _loader.fromNetwork(uri);
    return tf == null?null:_parse(tf.data);
  }
  @override
  Future<BufferGeometry> fromFile(File file) async{
    _init();
    ThreeFile tf = await _loader.fromFile(file);
    return _parse(tf.data);
  }
  @override
  Future<BufferGeometry?> fromPath(String filePath) async{
    _init();
    ThreeFile? tf = await _loader.fromPath(filePath);
    return tf == null?null:_parse(tf.data);
  }
  @override
  Future<BufferGeometry> fromBlob(Blob blob) async{
    _init();
    ThreeFile tf = await _loader.fromBlob(blob);
    return _parse(tf.data);
  }
  @override
  Future<BufferGeometry?> fromAsset(String asset, {String? package}) async{
    _init();
    ThreeFile? tf = await _loader.fromAsset(asset,package: package);
    return tf == null?null:_parse(tf.data);
  }
  @override
  Future<BufferGeometry> fromBytes(Uint8List bytes) async{
    _init();
    ThreeFile tf = await _loader.fromBytes(bytes);
    return _parse(tf.data);
  }

	_parse(Uint8List buffer) {
		final parser = USDAParser();

		parseAssets(zip) {
			final data = {};
			final loader = FileLoader();

			loader.setResponseType( 'arraybuffer' );

			for (final filename in zip ) {
				if ( filename.endsWith( 'png' ) ) {
					final blob =  Blob( [ zip[ filename ] ], { type: { type: 'image/png' } } );
					data[ filename ] = URL.createObjectURL( blob );
				}

				if ( filename.endsWith( 'usd' ) || filename.endsWith( 'usda' ) ) {
					if (isCrateFile(zip[filename])){
						console.warning( 'THREE.USDZLoader: Crate files (.usdc or binary .usd) are not supported.' );
						continue;
					}

					final text = fflate.strFromU8( zip[ filename ] );
					data[ filename ] = parser.parse( text );
				}
			}

			return data;
		}

		bool isCrateFile(Uint8List buffer){
			// Check if this a crate file. First 7 bytes of a crate file are "PXR-USDC".
			final fileHeader = buffer.sublist(0, 7);
			final crateHeader = Uint8List.fromList([0x50, 0x58, 0x52, 0x2D, 0x55, 0x53, 0x44, 0x43]);

			// If this is not a crate file, we assume it is a plain USDA file.
			return fileHeader.every((index){return fileHeader[index] == crateHeader[index];});
		}

		findUSD( zip) {
			if ( zip.length < 1 ) return null;

			final firstFileName = zip.keys[0];
			bool isCrate = false;

			// As per the USD specification, the first entry in the zip archive is used as the main file ("UsdStage").
			// ASCII files can end in either .usda or .usd.
			// See https://openusd.org/release/spec_usdz.html#layout
			if ( firstFileName.endsWith( 'usda' ) ) return zip[ firstFileName ];

			if ( firstFileName.endsWith( 'usdc' ) ) {
				isCrate = true;
			} 
      else if ( firstFileName.endsWith( 'usd' ) ) {
				// If this is not a crate file, we assume it is a plain USDA file.
				if ( ! isCrateFile( zip[ firstFileName ] ) ) {
					return zip[ firstFileName ];
				} else {
					isCrate = true;
				}
			}

			if ( isCrate ) {
				console.warning('USDZLoader: Crate files (.usdc or binary .usd) are not supported.' );
			}

			return null;
		}

		final zip = fflate.unzipSync(Uint8List.fromList(buffer));

		// console.log( zip );

		final assets = parseAssets( zip );

		// console.log( assets )

		final file = findUSD( zip );

		if ( file == null ) {
			console.warning( 'USDZLoader: No usda file found.' );
			return Group();
		}


		// Parse file

		final text = fflate.strFromU8( file );
		final root = parser.parse( text );

		// Build scene

		findGeometry( data,[ id ]) {
			if (!data) return null;
			if (id != null) {

				final def = 'def Mesh "$id"';

				if ( def in data ) {
					return data[ def ];
				}
			}

			for(final name in data){
				final object = data[ name ];
				if ( name.startsWith( 'def Mesh' ) ) {

					// Move points to Mesh
					if ( 'point3f[] points' in data ) {
						object[ 'point3f[] points' ] = data[ 'point3f[] points' ];
					}

					// Move st to Mesh
					if ( 'texCoord2f[] primvars:st' in data ) {
						object[ 'texCoord2f[] primvars:st' ] = data[ 'texCoord2f[] primvars:st' ];
					}

					// Move st indices to Mesh
					if ( 'int[] primvars:st:indices' in data ) {
						object[ 'int[] primvars:st:indices' ] = data[ 'int[] primvars:st:indices' ];
					}

					return object;
				}


				if (object is Object ) {
					final geometry = findGeometry(object);
					if ( geometry ) return geometry;
				}
			}
		}

		findMeshGeometry( data ) {
			if (!data) return null;

			if ('prepend references' in data) {
				final String reference = data['prepend references'];
				final parts = reference.split( '@' );
				final path = parts[1].replaceAll('/^.\//', '');
				final id = parts[2].replaceAll('/^<\//', '' ).replaceAll('/>\$/', '' );

				return findGeometry(assets[path], id);
			}

			return findGeometry(data);
		}

	  buildGeometry( data ) {
			if (!data) return null;
			BufferGeometry geometry = BufferGeometry();

			if ( 'int[] faceVertexIndices' in data ) {
				final indices = JSON.parse( data[ 'int[] faceVertexIndices' ] );
				geometry.setIndex( indices );
			}

			if ( 'point3f[] points' in data ) {
				final positions = json.parse( data[ 'point3f[] points' ].replace( /[()]*/g, '' ) );
				final attribute = BufferAttribute(Float32Array( positions ), 3 );
				geometry.setAttributeFromString( 'position', attribute );
			}

			if ( 'normal3f[] normals' in data ) {
				final normals = JSON.parse( data[ 'normal3f[] normals' ].replace( /[()]*/g, '' ) );
				final attribute = BufferAttribute(Float32Array( normals ), 3 );
				geometry.setAttributeFromString( 'normal', attribute );
			} 
      else {
				geometry.computeVertexNormals();
			}

			if ( 'float2[] primvars:st' in data ) {
				data[ 'texCoord2f[] primvars:st' ] = data[ 'float2[] primvars:st' ];
			}

			if ( 'texCoord2f[] primvars:st' in data ) {
				final uvs = JSON.parse( data[ 'texCoord2f[] primvars:st' ].replaceAll('/[()]*/g', '' ) );
				final attribute = BufferAttribute(Float32Array( uvs ), 2);

				if ( 'int[] primvars:st:indices' in data ) {
					geometry = geometry.toNonIndexed();

					final indices = JSON.parse( data[ 'int[] primvars:st:indices' ] );
					geometry.setAttributeFromString( 'uv', toFlatBufferAttribute( attribute, indices ) );
				} 
        else {
					geometry.setAttributeFromString( 'uv', attribute );
				}
			}

			return geometry;
		}

		toFlatBufferAttribute( attribute, indices ) {
			final array = attribute.array;
			final itemSize = attribute.itemSize;
			final array2 = array.constructor( indices.length * itemSize );

			int index = 0, index2 = 0;
			for ( int i = 0, l = indices.length; i < l; i ++ ) {
				index = indices[ i ] * itemSize;
				for ( int j = 0; j < itemSize; j ++ ) {
					array2[ index2 ++ ] = array[ index ++ ];
				}
			}

			return BufferAttribute( array2, itemSize );
		}

		findMeshMaterial( data ) {
			if ( ! data ) return null;
			if ( 'rel material:binding' in data ) {

				final String reference = data[ 'rel material:binding' ];
				final id = reference.replaceAll('/^<\//', '' ).replaceAll('/>\$/', '' );
				final parts = id.split( '/' );

				return findMaterial( root, ' "${ parts[ 1 ] }"');
			}

			return findMaterial( data );
		}

		findMaterial( data, [String id = '' ]) {
			for ( final name in data ) {
				final object = data[ name ];

				if ( name.startsWith( 'def Material$id') ) {
					return object;
				}

				if (object is Object ) {
					final material = findMaterial( object, id );
					if ( material ) return material;
				}
			}
		}

		setTextureParams( map, data_value ) {

			// rotation, scale and translation

			if ( data_value[ 'float inputs:rotation' ] ) {
				map.rotation = double.parse( data_value[ 'float inputs:rotation' ] );
			}

			if ( data_value[ 'float2 inputs:scale' ] ) {
				map.repeat = Vector2().fromArray( JSON.parse( '[' + data_value[ 'float2 inputs:scale' ].replace( /[()]*/g, '' ) + ']' ) );
			}

			if ( data_value[ 'float2 inputs:translation' ] ) {
				map.offset = Vector2().fromArray( JSON.parse( '[' + data_value[ 'float2 inputs:translation' ].replace( /[()]*/g, '' ) + ']' ) );
			}
		}

		buildMaterial( data ) {
			final material = MeshPhysicalMaterial();

			if ( data != null) {
				if ( 'def Shader "PreviewSurface"' in data ) {
					final surface = data[ 'def Shader "PreviewSurface"' ];

					if ( 'color3f inputs:diffuseColor.connect' in surface ) {
						final path = surface[ 'color3f inputs:diffuseColor.connect' ];
						final sampler = findTexture( root, /(\w+).output/.exec( path )[ 1 ] );

						material.map = buildTexture( sampler );
						material.map.colorSpace = SRGBColorSpace;

						if ( 'def Shader "Transform2d_diffuse"' in data ) {
							setTextureParams( material.map, data[ 'def Shader "Transform2d_diffuse"' ] );
						}

					} 
          else if ( 'color3f inputs:diffuseColor' in surface ) {
						final color = surface[ 'color3f inputs:diffuseColor' ].replace( /[()]*/g, '' );
						material.color.fromArray( JSON.parse( '[' + color + ']' ) );
					}

					if ( 'color3f inputs:emissiveColor.connect' in surface ) {
						final path = surface[ 'color3f inputs:emissiveColor.connect' ];
						final sampler = findTexture( root, /(\w+).output/.exec( path )[ 1 ] );

						material.emissiveMap = buildTexture( sampler );
						material.emissiveMap.colorSpace = SRGBColorSpace;
						material.emissive?.setFromHex32( 0xffffff );

						if ( 'def Shader "Transform2d_emissive"' in data ) {
							setTextureParams( material.emissiveMap, data[ 'def Shader "Transform2d_emissive"' ] );
						}
					} 
          else if ( 'color3f inputs:emissiveColor' in surface ) {
						final color = surface[ 'color3f inputs:emissiveColor' ].replace( /[()]*/g, '' );
						material.emissive.fromArray( JSON.parse( '[' + color + ']' ) );
					}

					if ( 'normal3f inputs:normal.connect' in surface ) {
						final path = surface[ 'normal3f inputs:normal.connect' ];
						final sampler = findTexture( root, /(\w+).output/.exec( path )[ 1 ] );

						material.normalMap = buildTexture( sampler );
						material.normalMap.colorSpace = NoColorSpace;

						if ( 'def Shader "Transform2d_normal"' in data ) {
							setTextureParams( material.normalMap, data[ 'def Shader "Transform2d_normal"' ] );
						}
					}

					if ( 'float inputs:roughness.connect' in surface ) {
						final path = surface[ 'float inputs:roughness.connect' ];
						final sampler = findTexture( root, /(\w+).output/.exec( path )[ 1 ] );

						material.roughness = 1.0;
						material.roughnessMap = buildTexture( sampler );
						material.roughnessMap.colorSpace = NoColorSpace;

						if ( 'def Shader "Transform2d_roughness"' in data ) {
							setTextureParams( material.roughnessMap, data[ 'def Shader "Transform2d_roughness"' ] );
						}
					} 
          else if ( 'float inputs:roughness' in surface ) {
						material.roughness = parseFloat( surface[ 'float inputs:roughness' ] );
					}

					if ( 'float inputs:metallic.connect' in surface ) {
						final path = surface[ 'float inputs:metallic.connect' ];
						final sampler = findTexture( root, /(\w+).output/.exec( path )[ 1 ] );

						material.metalness = 1.0;
						material.metalnessMap = buildTexture( sampler );
						material.metalnessMap.colorSpace = NoColorSpace;

						if ( 'def Shader "Transform2d_metallic"' in data ) {
							setTextureParams( material.metalnessMap, data[ 'def Shader "Transform2d_metallic"' ] );
						}
					} 
          else if ( 'float inputs:metallic' in surface ) {
						material.metalness = parseFloat( surface[ 'float inputs:metallic' ] );
					}

					if ( 'float inputs:clearcoat.connect' in surface ) {

						final path = surface[ 'float inputs:clearcoat.connect' ];
						final sampler = findTexture( root, /(\w+).output/.exec( path )[ 1 ] );

						material.clearcoat = 1.0;
						material.clearcoatMap = buildTexture( sampler );
						material.clearcoatMap.colorSpace = NoColorSpace;

						if ( 'def Shader "Transform2d_clearcoat"' in data ) {
							setTextureParams( material.clearcoatMap, data[ 'def Shader "Transform2d_clearcoat"' ] );
						}
					} 
          else if ( 'float inputs:clearcoat' in surface ) {
						material.clearcoat = parseFloat( surface[ 'float inputs:clearcoat' ] );
					}

					if ( 'float inputs:clearcoatRoughness.connect' in surface ) {
						final path = surface[ 'float inputs:clearcoatRoughness.connect' ];
						final sampler = findTexture( root, /(\w+).output/.exec( path )[ 1 ] );

						material.clearcoatRoughness = 1.0;
						material.clearcoatRoughnessMap = buildTexture( sampler );
						material.clearcoatRoughnessMap.colorSpace = NoColorSpace;

						if ( 'def Shader "Transform2d_clearcoatRoughness"' in data ) {
							setTextureParams( material.clearcoatRoughnessMap, data[ 'def Shader "Transform2d_clearcoatRoughness"' ] );
						}
					} 
          else if ( 'float inputs:clearcoatRoughness' in surface ) {
						material.clearcoatRoughness = parseFloat( surface[ 'float inputs:clearcoatRoughness' ] );
					}

					if ( 'float inputs:ior' in surface ) {
						material.ior = parseFloat( surface[ 'float inputs:ior' ] );
					}

					if ( 'float inputs:occlusion.connect' in surface ) {
						final path = surface[ 'float inputs:occlusion.connect' ];
						final sampler = findTexture( root, /(\w+).output/.exec( path )[ 1 ] );

						material.aoMap = buildTexture( sampler );
						material.aoMap.colorSpace = NoColorSpace;

						if ( 'def Shader "Transform2d_occlusion"' in data ) {
							setTextureParams( material.aoMap, data[ 'def Shader "Transform2d_occlusion"' ] );
						}
					}
				}

				if ( 'def Shader "diffuseColor_texture"' in data ) {
					final sampler = data[ 'def Shader "diffuseColor_texture"' ];

					material.map = buildTexture( sampler );
					material.map.colorSpace = SRGBColorSpace;
				}

				if ( 'def Shader "normal_texture"' in data ) {
					final sampler = data[ 'def Shader "normal_texture"' ];

					material.normalMap = buildTexture( sampler );
					material.normalMap.colorSpace = NoColorSpace;
				}
			}

			return material;
		}

		findTexture( data, id ) {
			for ( final name in data ) {
				final object = data[ name ];

				if ( name.startsWith( 'def Shader "$id"' ) ) {
					return object;
				}

				if ( typeof object === 'object' ) {
					final texture = findTexture( object, id );
					if ( texture ) return texture;
				}
			}
		}

		buildTexture( data ) {
			if ( 'asset inputs:file' in data ) {
				final path = data[ 'asset inputs:file' ].replace( /@*/g, '' );
				final loader = TextureLoader();
				final texture = loader.load( assets[ path ] );
				final map = {
					'"clamp"': ClampToEdgeWrapping,
					'"mirror"': MirroredRepeatWrapping,
					'"repeat"': RepeatWrapping
				};

				if ( 'token inputs:wrapS' in data ) {
					texture.wrapS = map[ data[ 'token inputs:wrapS' ] ];
				}

				if ( 'token inputs:wrapT' in data ) {
					texture.wrapT = map[ data[ 'token inputs:wrapT' ] ];
				}

				return texture;
			}

			return null;
		}

		buildObject( data ) {
			final geometry = buildGeometry( findMeshGeometry( data ) );
			final material = buildMaterial( findMeshMaterial( data ) );
			final mesh = geometry ? Mesh( geometry, material ) : Object3D();

			if ( 'matrix4d xformOp:transform' in data ) {
				final array = JSON.parse( '[' + data[ 'matrix4d xformOp:transform' ].replace( /[()]*/g, '' ) + ']' );

				mesh.matrix.fromArray( array );
				mesh.matrix.decompose( mesh.position, mesh.quaternion, mesh.scale );
			}

			return mesh;
		}

		buildHierarchy( data, group ) {
			for ( final name in data ) {
				if ( name.startsWith( 'def Scope' ) ) {
					buildHierarchy( data[ name ], group );
				} 
        else if ( name.startsWith( 'def Xform' ) ) {
					final mesh = buildObject( data[ name ] );

					if ('/def Xform "(\w+)"/'.test( name ) ) {
						mesh.name = '/def Xform "(\w+)"/'.exec( name )[ 1 ];
					}

					group.add( mesh );
					buildHierarchy( data[ name ], mesh );
				}
			}
		}

		final group = Group();

		buildHierarchy( root, group );
		return group;
	}
}