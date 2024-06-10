import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';

import 'package:three_js_advanced_loaders/usdz/usdz_zip.dart';
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';
import 'package:three_js_core_loaders/three_js_core_loaders.dart';

class USDAParser {

	Map<String, dynamic> parse(String text) {
		final Map<String, dynamic> data = {};
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
					final Map<String, dynamic> group = {};
					stack.add(group);

					target[ lhs ] = group;
					target = group;
				} 
        else {
					target[ lhs ] = rhs;
				}
			} 
      else if (line.endsWith( '{' )) {
				final Map<String,dynamic> group = target[string] ?? {};
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
				final Map<String, dynamic> meta = {};
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
  Future<Group?> fromNetwork(Uri uri) async{
    _init();
    ThreeFile? tf = await _loader.fromNetwork(uri);
    return tf == null?null:_parse(tf.data);
  }
  @override
  Future<Group> fromFile(File file) async{
    _init();
    ThreeFile tf = await _loader.fromFile(file);
    return _parse(tf.data);
  }
  @override
  Future<Group?> fromPath(String filePath) async{
    _init();
    ThreeFile? tf = await _loader.fromPath(filePath);
    return tf == null?null:_parse(tf.data);
  }
  @override
  Future<Group> fromBlob(Blob blob) async{
    _init();
    ThreeFile tf = await _loader.fromBlob(blob);
    return _parse(tf.data);
  }
  @override
  Future<Group?> fromAsset(String asset, {String? package}) async{
    _init();
    ThreeFile? tf = await _loader.fromAsset(asset,package: package);
    return tf == null?null:_parse(tf.data);
  }
  @override
  Future<Group> fromBytes(Uint8List bytes) async{
    _init();
    ThreeFile tf = await _loader.fromBytes(bytes);
    return _parse(tf.data);
  }

	Group _parse(Uint8List buffer) {
		final parser = USDAParser();

		bool isCrateFile(Uint8List buffer){
			// Check if this a crate file. First 7 bytes of a crate file are "PXR-USDC".
			final fileHeader = buffer.sublist(0, 7);
			final crateHeader = Uint8List.fromList([0x50, 0x58, 0x52, 0x2D, 0x55, 0x53, 0x44, 0x43]);

      bool allSame = true;

      for(int i = 0; i < fileHeader.length;i++){
        if(fileHeader[i] == crateHeader[i]){
          allSame = false;
          break;
        }
      }

			// If this is not a crate file, we assume it is a plain USDA file.
			return allSame;
		}

		Map<String,dynamic> parseAssets(Map<String,dynamic> zip) {
			final Map<String,dynamic> data = {};
			final loader = FileLoader();

			loader.setResponseType( 'arraybuffer' );
			for (final String filename in zip.keys) {
				if ( filename.endsWith( 'png' ) ) {
					//final blob =  Blob( zip[ filename ], { 'type': { 'type': 'image/png' } } );
					data[ filename ] = zip[ filename ];//createObjectURL( blob );
				}
				else if ( filename.endsWith( 'usd' ) || filename.endsWith( 'usda' ) ) {
					if (isCrateFile(zip[filename])){
						console.warning( 'USDZLoader: Crate files (.usdc or binary .usd) are not supported.' );
						continue;
					}

          final bytes = USDZIP.strFromU8(zip[ filename ]);
					data[ filename ] = parser.parse(String.fromCharCodes(bytes));
				}
			}

			return data;
		}

		dynamic findUSD(Map<String,dynamic> zip) {
			if ( zip.isEmpty ) return null;

			final String firstFileName = zip.keys.first;
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
				if (!isCrateFile(zip[firstFileName])) {
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

		final zip = USDZIP.unzip(buffer);
		final assets = parseAssets( zip );
		final file = findUSD( zip );
		if ( file == null ) {
			console.warning( 'USDZLoader: No usda file found.' );
			return Group();
		}

		// Parse file
		final text = String.fromCharCodes(file);
		final root = parser.parse( text );

		// Build scene

		Map<String,dynamic>? findGeometry(Map<String,dynamic>? data,[ id ]) {
			if (data == null) return null;
			if (id != null) {

				final def = 'def Mesh "$id"';

				if (data.containsKey(def) ) {
					return data[ def ];
				}
			}

			for(final name in data.keys){
				final object = data[ name ];
				if ( name.startsWith( 'def Mesh' ) ) {

					// Move points to Mesh
					if (data.containsKey('point3f[] points')) {
						object[ 'point3f[] points' ] = data[ 'point3f[] points' ];
					}

					// Move st to Mesh
					if (data.containsKey('texCoord2f[] primvars:st') ) {
						object[ 'texCoord2f[] primvars:st' ] = data[ 'texCoord2f[] primvars:st' ];
					}

					// Move st indices to Mesh
					if ( data.containsKey('int[] primvars:st:indices') ) {
						object[ 'int[] primvars:st:indices' ] = data[ 'int[] primvars:st:indices' ];
					}

					return object;
				}


				if (object is Map<String,dynamic> ) {
					final geometry = findGeometry(object);
					if ( geometry != null) return geometry;
				}
			}

      return null;
		}

		Map<String,dynamic>? findMeshGeometry(Map<String,dynamic>? data ) {
			if (data == null) return null;

			if (data.containsKey('prepend references')) {
				final String reference = data['prepend references'];
				final parts = reference.split( '@' );
				final path = parts[1].replaceAll(r'/^.\//', '');
				final id = parts[2].replaceAll(r'/^<\//', '' ).replaceAll(r'/>\$/', '' );

				return findGeometry(assets[path], id);
			}

			return findGeometry(data);
		}

		Float32BufferAttribute toFlatBufferAttribute(Float32BufferAttribute attribute, List<int> indices ) {
			final Float32Array array = attribute.array;
			final itemSize = attribute.itemSize;
			late final Float32Array array2 = Float32Array(indices.length * itemSize);//array.constructor( indices.length * itemSize );

			int index = 0, index2 = 0;
			for ( int i = 0, l = indices.length; i < l; i ++ ) {
				index = indices[ i ] * itemSize;
				for ( int j = 0; j < itemSize; j ++ ) {
					array2[ index2 ++ ] = array[ index ++ ];
				}
			}

      return Float32BufferAttribute(array2, itemSize);
		}

	  BufferGeometry? buildGeometry(Map<String,dynamic>? data ) {
			if (data == null) return null;
			BufferGeometry geometry = BufferGeometry();

			if ( data.containsKey('int[] faceVertexIndices') ) {
				final indices = List<int>.from(json.decode( data[ 'int[] faceVertexIndices' ] ));
				geometry.setIndex( indices );
			}

			if (data.containsKey('point3f[] points') ) {
				final positions = List<double>.from(json.decode( data[ 'point3f[] points' ].replaceAll(RegExp('[()]*'), '' ) ));
				final attribute = Float32BufferAttribute.fromList(positions, 3 );
				geometry.setAttributeFromString( 'position', attribute );
			}

			if (data.containsKey('normal3f[] normals') ) {
				final normals = List<double>.from(json.decode( data[ 'normal3f[] normals' ].replaceAll(RegExp('[()]*'), '' ) ));
				final attribute = Float32BufferAttribute.fromList(normals , 3 );
				geometry.setAttributeFromString( 'normal', attribute );
			} 
      else {
				geometry.computeVertexNormals();
			}

			if (data.containsKey('float2[] primvars:st') ) {
				data[ 'texCoord2f[] primvars:st' ] = data[ 'float2[] primvars:st' ];
			}

			if ( data.containsKey('texCoord2f[] primvars:st') ) {
				final uvs = List<double>.from(json.decode( data[ 'texCoord2f[] primvars:st' ].replaceAll(RegExp('[()]*'), '' ) ));
				final attribute = Float32BufferAttribute.fromList(uvs , 2);

				if ( data.containsKey('int[] primvars:st:indices') ) {
					geometry = geometry.toNonIndexed();

					final indices = List<int>.from(json.decode( data[ 'int[] primvars:st:indices' ] ));
					geometry.setAttributeFromString( 'uv', toFlatBufferAttribute( attribute, indices ) );
				} 
        else {
					geometry.setAttributeFromString( 'uv', attribute );
				}
			}

			return geometry;
		}

		Map<String,dynamic>? findMaterial(Map<String,dynamic> data, [String id = '' ]) {
			for ( final name in data.keys ) {
				final object = data[ name ];

				if ( name.startsWith( 'def Material$id') ) {
					return object;
				}

				if (object is Map<String,dynamic>) {
					final material = findMaterial( object, id );
					if ( material != null) return material;
				}
			}

      return null;
		}

		Map<String,dynamic>? findMeshMaterial(Map<String,dynamic>? data ) {
			if ( data == null) return null;
			if ( data.containsKey('rel material:binding') ) {

				final String reference = data[ 'rel material:binding' ];
				final id = reference.replaceAll(r'/^<\//', '' ).replaceAll('/>\$/', '' );
				final parts = id.split( '/' );

				return findMaterial( root, ' "${ parts[ 1 ] }"');
			}

			return findMaterial( data );
		}

		void setTextureParams(Texture? map, Map<String,dynamic> dataValue) {
			if ( dataValue[ 'float inputs:rotation' ] ) {
				map?.rotation = double.parse( dataValue[ 'float inputs:rotation' ] );
			}

			if ( dataValue[ 'float2 inputs:scale' ] ) {
				map?.repeat = Vector2.zero().copyFromArray( List<double>.from(json.decode( '[${dataValue[ 'float2 inputs:scale' ].replaceAll(RegExp('[()]*'), '' )}]' ) ));
			}

			if ( dataValue[ 'float2 inputs:translation' ] ) {
				map?.offset = Vector2.zero().copyFromArray( List<double>.from(json.decode( '[${dataValue[ 'float2 inputs:translation' ].replaceAll(RegExp('[()]*'), '' )}]' ) ));
			}
		}

		Map<String,dynamic>? findTexture(Map<String,dynamic> data, String id ) {
			for ( final name in data.keys ) {
				final object = data[ name ];

				if ( name.startsWith( 'def Shader "$id"' ) ) {
					return object;
				}

				if (object is Map<String,dynamic>) {
					final texture = findTexture( object, id );
					if ( texture != null) return texture;
				}
			}

      return null;
		}

		Future<Texture?> buildTexture(Map? data ) async{
      if(data == null) return null;
			if ( data.containsKey('asset inputs:file') ) {
				final path = data[ 'asset inputs:file' ].replaceAll( RegExp('@*'), '' );
				final loader = TextureLoader();
				final texture = await loader.fromBytes( assets[ path ] );
				final Map<String,dynamic> map = {
					'"clamp"': ClampToEdgeWrapping,
					'"mirror"': MirroredRepeatWrapping,
					'"repeat"': RepeatWrapping
				};

				if ( data.containsKey('token inputs:wrapS') ) {
					texture?.wrapS = map[ data[ 'token inputs:wrapS' ] ];
				}

				if ( data.containsKey('token inputs:wrapT') ) {
					texture?.wrapT = map[ data[ 'token inputs:wrapT' ] ];
				}

				return texture;
			}

			return null;
		}

		Future<Material> buildMaterial(Map? data ) async{
			final material = MeshPhysicalMaterial();

			if ( data != null) {
				if ( data.containsKey('def Shader "PreviewSurface"') ) {
					final Map surface = data[ 'def Shader "PreviewSurface"' ];

					if ( surface.containsKey('color3f inputs:diffuseColor.connect') ) {
						final path = surface[ 'color3f inputs:diffuseColor.connect' ];
            final id = RegExp(r'(\w+).output',caseSensitive: false,multiLine: true).allMatches(path).first.group(1)!;
						final sampler = findTexture( root, id );

						material.map = await buildTexture( sampler );
						material.map?.colorSpace = SRGBColorSpace;

						if ( data.containsKey('def Shader "Transform2d_diffuse"') ) {
							setTextureParams( material.map, data[ 'def Shader "Transform2d_diffuse"' ] );
						}

					} 
          else if ( surface.containsKey('color3f inputs:diffuseColor') ) {
						final color = List<double>.from(surface[ 'color3f inputs:diffuseColor' ].replaceAll( RegExp('[()]*'), '' ));
						material.color.copyFromArray( List<double>.from(json.decode( '[$color]' )) );
					}

					if ( surface.containsKey('color3f inputs:emissiveColor.connect') ) {
						final path = surface[ 'color3f inputs:emissiveColor.connect' ];
            final id = RegExp(r'(\w+).output',caseSensitive: false,multiLine: true).allMatches(path).first.group(1)!;
						final sampler = findTexture( root, id );

						material.emissiveMap = await buildTexture( sampler );
						material.emissiveMap?.colorSpace = SRGBColorSpace;
						material.emissive?.setFromHex32( 0xffffff );

						if ( data.containsKey('def Shader "Transform2d_emissive"') ) {
							setTextureParams( material.emissiveMap, data[ 'def Shader "Transform2d_emissive"' ] );
						}
					} 
          else if ( surface.containsKey('color3f inputs:emissiveColor') ) {
						final color = List<double>.from(surface[ 'color3f inputs:emissiveColor' ].replaceAll( RegExp('[()]*'), '' ));
						material.emissive?.copyFromArray( List<double>.from(json.decode( '[$color]' )) );
					}

					if ( surface.containsKey('normal3f inputs:normal.connect') ) {
						final path = surface[ 'normal3f inputs:normal.connect' ];
            final id = RegExp(r'(\w+).output',caseSensitive: false,multiLine: true).allMatches(path).first.group(1)!;
						final sampler = findTexture( root, id );

						material.normalMap = await buildTexture( sampler );
						material.normalMap?.colorSpace = NoColorSpace;

						if ( data.containsKey('def Shader "Transform2d_normal"') ) {
							setTextureParams( material.normalMap, data[ 'def Shader "Transform2d_normal"' ] );
						}
					}

					if ( surface.containsKey('float inputs:roughness.connect') ) {
						final path = surface[ 'float inputs:roughness.connect' ];
            final id = RegExp(r'(\w+).output',caseSensitive: false,multiLine: true).allMatches(path).first.group(1)!;
						final sampler = findTexture( root, id );

						material.roughness = 1.0;
						material.roughnessMap = await buildTexture( sampler );
						material.roughnessMap?.colorSpace = NoColorSpace;

						if ( data.containsKey('def Shader "Transform2d_roughness"') ) {
							setTextureParams( material.roughnessMap, data[ 'def Shader "Transform2d_roughness"' ] );
						}
					} 
          else if ( surface.containsKey('float inputs:roughness') ) {
						material.roughness = double.parse( surface[ 'float inputs:roughness' ] );
					}

					if ( surface.containsKey('float inputs:metallic.connect') ) {
						final path = surface[ 'float inputs:metallic.connect' ];
            final id = RegExp(r'(\w+).output',caseSensitive: false,multiLine: true).allMatches(path).first.group(1)!;
						final sampler = findTexture( root, id );

						material.metalness = 1.0;
						material.metalnessMap = await buildTexture( sampler );
						material.metalnessMap?.colorSpace = NoColorSpace;

						if ( data.containsKey('def Shader "Transform2d_metallic"') ) {
							setTextureParams( material.metalnessMap, data[ 'def Shader "Transform2d_metallic"' ] );
						}
					} 
          else if ( surface.containsKey('float inputs:metallic') ) {
						material.metalness = double.parse( surface[ 'float inputs:metallic' ] );
					}

					if ( surface.containsKey('float inputs:clearcoat.connect') ) {

						final path = surface[ 'float inputs:clearcoat.connect' ];
            final id = RegExp(r'(\w+).output',caseSensitive: false,multiLine: true).allMatches(path).first.group(1)!;
						final sampler = findTexture( root, id );

						material.clearcoat = 1.0;
						material.clearcoatMap = await buildTexture( sampler );
						material.clearcoatMap?.colorSpace = NoColorSpace;

						if ( data.containsKey('def Shader "Transform2d_clearcoat"') ) {
							setTextureParams( material.clearcoatMap, data[ 'def Shader "Transform2d_clearcoat"' ] );
						}
					} 
          else if ( surface.containsKey('float inputs:clearcoat') ) {
						material.clearcoat = double.parse( surface[ 'float inputs:clearcoat' ] );
					}

					if ( surface.containsKey('float inputs:clearcoatRoughness.connect') ) {
						final path = surface[ 'float inputs:clearcoatRoughness.connect' ];
            final id = RegExp(r'(\w+).output',caseSensitive: false,multiLine: true).allMatches(path).first.group(1)!;
						final sampler = findTexture( root, id );

						material.clearcoatRoughness = 1.0;
						material.clearcoatRoughnessMap = await buildTexture( sampler );
						material.clearcoatRoughnessMap?.colorSpace = NoColorSpace;

						if ( data.containsKey('def Shader "Transform2d_clearcoatRoughness"') ) {
							setTextureParams( material.clearcoatRoughnessMap, data[ 'def Shader "Transform2d_clearcoatRoughness"' ] );
						}
					} 
          else if ( surface.containsKey('float inputs:clearcoatRoughness') ) {
						material.clearcoatRoughness = double.parse( surface[ 'float inputs:clearcoatRoughness' ] );
					}

					if ( surface.containsKey('float inputs:ior') ) {
						material.ior = double.parse( surface[ 'float inputs:ior' ] );
					}

					if ( surface.containsKey('float inputs:occlusion.connect') ) {
						final path = surface[ 'float inputs:occlusion.connect' ];
            final id = RegExp(r'(\w+).output',caseSensitive: false,multiLine: true).allMatches(path).first.group(1)!;
						final sampler = findTexture( root, id);

						material.aoMap = await buildTexture( sampler );
						material.aoMap?.colorSpace = NoColorSpace;

						if ( data.containsKey('def Shader "Transform2d_occlusion"') ) {
							setTextureParams( material.aoMap, data[ 'def Shader "Transform2d_occlusion"' ] );
						}
					}
				}

				if ( data.containsKey('def Shader "diffuseColor_texture"') ) {
					final sampler = data[ 'def Shader "diffuseColor_texture"' ];

					material.map = await buildTexture( sampler );
					material.map?.colorSpace = SRGBColorSpace;
				}

				if ( data.containsKey('def Shader "normal_texture"') ) {
					final sampler = data[ 'def Shader "normal_texture"' ];

					material.normalMap = await buildTexture( sampler );
					//material.normalMap.colorSpace = NoColorSpace;
				}
			}

			return material;
		}

		Future<Object3D> buildObject(Map<String,dynamic> data ) async{
			final geometry = buildGeometry( findMeshGeometry( data ) );
			final material = await buildMaterial( findMeshMaterial( data ) );
			final mesh = geometry != null? Mesh( geometry, material ) : Object3D();

			if ( data.containsKey('matrix4d xformOp:transform') ) {
				final array = List<double>.from(json.decode( '[${data[ 'matrix4d xformOp:transform' ].replaceAll( RegExp(r'[()]*'), '' )}]' ));

				mesh.matrix.copyFromArray( array );
				mesh.matrix.decompose( mesh.position, mesh.quaternion, mesh.scale );
			}

			return mesh;
		}

		Future<void> buildHierarchy(Map<String,dynamic> data, Object3D group ) async{
			for ( final name in data.keys ) {
				if ( name.startsWith( 'def Scope' ) ) {
					buildHierarchy( data[ name ], group );
				} 
        else if ( name.startsWith( 'def Xform' ) ) {
					final mesh = await buildObject( data[ name ] );
					if (name.contains('def Xform "') ) {
						mesh.name = RegExp(r'def Xform "(\w+)"',caseSensitive: false,multiLine: true).allMatches(name).first.group(1)!;//r'/def Xform "(\w+)"/'.exec( name )[ 1 ];
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