import 'dart:math' as math;
import 'dart:typed_data';
import 'package:three_js_advanced_exporters/usdz/zip.dart';

import './usdz/image_export.dart';
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_exporters/saveFile/saveFile.dart';
import 'package:three_js_math/three_js_math.dart';

class USDZOptions{
  bool includeAnchoringProperties;
  bool quickLookCompatible;
  int maxTextureSize;
  late Map<String,dynamic> ar;

  USDZOptions({
    this.includeAnchoringProperties = true,
    this.quickLookCompatible = false,
    this.maxTextureSize = 1024,
    Map<String,dynamic>? ar
  }){
    this.ar = ar ?? {
			'anchoring': { 'type': 'plane' },
			'planeAnchoring': { 'alignment': 'horizontal' }
    };
  }
}

class USDZExporter {
  _USDZExporter exporter = _USDZExporter();

	USDZExporter();

	void setTextureUtils( utils ) {
		exporter.textureUtils = utils;
	}

  Future<void> exportScene(String fileName, Scene scene, [String? path, USDZOptions? options ]) async{
    SaveFile.saveBytes(
      printName: fileName, 
      fileType: 'usdz', 
      bytes: await exporter.parse(scene, path: fileName, options: options), 
      path: path
    );
  }

  Future<Uint8List?> parse(Scene scene, [USDZOptions? options ]) async{
    return await exporter.parse(scene, options: options);
  }
}

class _USDZExporter {
  var textureUtils;

  _USDZExporter();

	void setTextureUtils( utils ) {
		this.textureUtils = utils;
	}

	Future<Uint8List> parse(Scene scene, {String? path, USDZOptions? options }) async{
    options ??= USDZOptions();

		final Map<String,dynamic> files = {};
		final modelFileName = 'model.usda';

		// model file should be first in USDZ archive so we init it here
		files[ modelFileName ] = null;

		String output = buildHeader();

		output += buildSceneStart( options );

		final Map<String,Material> materials = {};
		final Map<String,Texture> textures = {};

		scene.traverseVisible( ( object ){
			if ( object is Mesh ) {
				final geometry = object.geometry;
				final material = object.material;

				if ( material is MeshStandardMaterial ) {

					final geometryFileName = 'geometries/Geometry_${geometry?.id}.usda';

					if(!files.containsKey(geometryFileName) ){//! ( geometryFileName in files ) ) {
						final meshObject = buildMeshObject( geometry! );
						files[ geometryFileName ] = buildUSDFileAsString( meshObject );
					}

					if (!materials.containsKey( material.uuid) ){//! ( material.uuid in materials ) ) {
						materials[ material.uuid ] = material;
					}

					output += buildXform( object, geometry!, material );

				} 
        else {
					console.warning( 'THREE.USDZExporter: Unsupported material type (USDZ only supports MeshStandardMaterial) $object');
				}
			} 
      else if ( object is PerspectiveCamera ) {
				output += buildCamera( object );
			}
		} );


		output += buildSceneEnd();
		output += buildMaterials( materials, textures, options.quickLookCompatible );

		files[ modelFileName ] = output.codeUnits;
		output = '';

		for ( final id in textures.keys ) {
			Texture? texture = textures[ id ];

			if ( texture is CompressedTexture ) {
				if ( this.textureUtils == null ) {
					throw ( 'THREE.USDZExporter: setTextureUtils() must be called to process compressed textures.' );
				} 
        else {
					texture = await this.textureUtils.decompress( texture );
				}
			}

      if(texture != null){
        files[ 'textures/Texture_${id}.png' ] = await ImageExport.decodeImageFromList(texture.image,texture.flipY,options.maxTextureSize);
      }
		}

		// 64 byte alignment
		// https://github.com/101arrowz/fflate/issues/39#issuecomment-777263109
		int offset = 0;
		for ( final filename in files.keys ) {
			final file = files[ filename ];
			final headerSize = 34 + filename.length;

			offset += headerSize.toInt();

			final offsetMod64 = offset & 63;

			if ( offsetMod64 != 4 ) {
				final padLength = 64 - offsetMod64;
				final padding = Uint8List( padLength );

        files[ filename ] = [ file, { 'extra': { 12345: padding } } ];
			}

			offset = file?.length ?? 0;
		}

		return zipSync(files, { 'level': 0 } );
	}


  // static Uint8List createZipFile(Archive archive, String? path){
  //   console.verbose("Archivng File!");
    
  //   ZipEncoder encoder = ZipEncoder();
  //   OutputStream outputStream;
  //   if(path != null){
  //     outputStream = OutputFileStream(
  //       path,
  //       byteOrder: ByteOrder.littleEndian,
  //     );
  //   }
  //   else{
  //     outputStream = OutputMemoryStream(
  //       byteOrder: ByteOrder.littleEndian,
  //     );
  //   }
  //   List<int>? bytes = encoder.encode(
  //     archive,
  //     level: DeflateLevel.none, 
  //     output: outputStream
  //   );
  //   return Uint8List.fromList(bytes);
  // }

  final PRECISION = 7;

  String buildHeader() {
    return '''
#usda 1.0
(
  customLayerData = {
    string creator = "Three.js USDZExporter"
  }
  defaultPrim = "Root"
  metersPerUnit = 1
  upAxis = "Y"
)

    ''';
  }

  String buildSceneStart(USDZOptions options ) {
    final alignment = options.includeAnchoringProperties == true ? '''

    token preliminary:anchoring:type = "${options.ar['anchoring']['type']}"
    token preliminary:planeAnchoring:alignment = "${options.ar['planeAnchoring']['alignment']}"
    ''' : '';
    return '''

def Xform "Root"
{
  def Scope "Scenes" (
    kind = "sceneLibrary"
  )
  {
    def Xform "Scene" (
      customData = {
        bool preliminary_collidesWithEnvironment = 0
        string sceneName = "Scene"
      }
      sceneName = "Scene"
    )
    {
      ${alignment}
    ''';
  }

  String buildSceneEnd() {
    return '''

    }
  }
}
    ''';
  }

  List<int> buildUSDFileAsString(String dataToInsert ) {
    String output = buildHeader();
    output += dataToInsert;
    return output.codeUnits;
  }

  String buildXform(Object3D object, BufferGeometry geometry, Material material ) {
    final name = 'Object_${object.id}';
    final transform = buildMatrix( object.matrixWorld );

    if ( object.matrixWorld.determinant() < 0 ) {
      console.warning( 'THREE.USDZExporter: USDZ does not support negative scales $object');
    }

    return '''

      def Xform "${ name }" (
        prepend references = @./geometries/Geometry_${ geometry.id }.usda@</Geometry>
        prepend apiSchemas = ["MaterialBindingAPI"]
      )
      {
        matrix4d xformOp:transform = ${ transform }
        uniform token[] xformOpOrder = ["xformOp:transform"]

        rel material:binding = </Materials/Material_${ material.id }>
      }
    ''';
  }

  String buildMatrix(Matrix4 matrix ) {
    final array = matrix.storage;
    return '( ${ buildMatrixRow( array, 0 ) }, ${ buildMatrixRow( array, 4 ) }, ${ buildMatrixRow( array, 8 ) }, ${ buildMatrixRow( array, 12 ) } )';
  }

  String buildMatrixRow(List array, int offset ) {
    return '(${ array[ offset + 0 ] }, ${ array[ offset + 1 ] }, ${ array[ offset + 2 ] }, ${ array[ offset + 3 ] })';
  }

  // Mesh

  String buildMeshObject(BufferGeometry geometry ) {
    final mesh = buildMesh( geometry );
    return '''

def "Geometry"
{
${mesh}
}
    ''';
  }

  String buildMesh(BufferGeometry geometry ) {
    final name = 'Geometry';
    final attributes = geometry.attributes;
    final count = attributes['position'].count;

    return '''

  def Mesh "${ name }"
  {
    int[] faceVertexCounts = [${ buildMeshVertexCount( geometry ) }]
    int[] faceVertexIndices = [${ buildMeshVertexIndices( geometry ) }]
    normal3f[] normals = [${ buildVector3Array( attributes['normal'], count )}] (
     interpolation = "vertex"
    )
    point3f[] points = [${ buildVector3Array( attributes['position'], count )}]
${ buildPrimvars( attributes ) }
    uniform token subdivisionScheme = "none"
  }
    ''';
  }

  String buildMeshVertexCount(BufferGeometry geometry ) {
    final count = geometry.index != null ? geometry.index?.count : geometry.attributes['position'].count;
    return List.filled(count~/3, 3).join(', ');
  }

  String buildMeshVertexIndices(BufferGeometry geometry ) {

    final index = geometry.index;
    final array = [];

    if ( index != null ) {
      for ( int i = 0; i < index.count; i ++ ) {
        array.add( index.getX( i )!.toInt() );
      }
    }
    else {
      final length = geometry.attributes['position'].count;
      for ( int i = 0; i < length; i ++ ) {
        array.add( i );
      }
    }

    return array.join( ', ' );
  }

  String buildVector3Array(BufferAttribute? attribute,int count ) {
    if ( attribute == null ) {
      console.warning( 'USDZExporter: Normals missing.' );
      return List.filled(count, '(0, 0, 0)').join(', ');
    }

    final array = [];

    for (int i = 0; i < attribute.count; i ++ ) {
      final x = attribute.getX( i );
      final y = attribute.getY( i );
      final z = attribute.getZ( i );

      array.add( '(${ x!.toStringAsFixed( PRECISION ) }, ${ y!.toStringAsFixed( PRECISION ) }, ${ z!.toStringAsFixed( PRECISION ) })' );
    }

    return array.join( ', ' );
  }

  String buildVector2Array(BufferAttribute attribute ) {
    final array = [];

    for (int i = 0; i < attribute.count; i ++ ) {
      final x = attribute.getX( i );
      final y = attribute.getY( i );

      array.add( '(${ x!.toStringAsFixed( PRECISION ) }, ${ (1 - y!).toStringAsFixed( PRECISION ) })' );
    }

    return array.join( ', ' );
  }

  String buildPrimvars(Map<String,dynamic> attributes ) {
    String string = '';

    for (int i = 0; i < 4; i ++ ) {
      final id = ( i > 0 ? i : '' );
      final attribute = attributes['uv$id'];

      if ( attribute != null ) {
        string += '''
      texCoord2f[] primvars:st${ id } = [${ buildVector2Array( attribute )}] (
        interpolation = "vertex"
      )
        ''';
      }
    }

    // vertex colors

    final colorAttribute = attributes['color'];

    if ( colorAttribute != null ) {
      final count = colorAttribute.count;

      string += '''

    color3f[] primvars:displayColor = [${buildVector3Array( colorAttribute, count )}](
      interpolation = "vertex"
    )
      ''';
    }

    return string;
  }

  // Materials

  String buildMaterials(Map<dynamic,Material> materials, Map<String,Texture> textures, [bool quickLookCompatible = false] ) {
    final array = [];

    for ( final uuid in materials.keys ) {
      final material = materials[ uuid ];
      array.add( buildMaterial( material!, textures, quickLookCompatible ) );
    }

    return '''

def "Materials"
{
${ array.join( '' ) }
}
    ''';
  }

  String buildMaterial(Material material, Map<String,Texture> textures, [bool quickLookCompatible = false ]) {
    final pad = '			';
    final inputs = [];
    final samplers = [];

    String buildTexture(Texture texture, mapType, [Color? color]) {
      final id = '${texture.source.uuid}_${texture.flipY}';
      textures[ id ] = texture;
      final uv = texture.channel > 0 ? 'st${texture.channel}' : 'st';

      final WRAPPINGS = {
        1000: 'repeat', // RepeatWrapping
        1001: 'clamp', // ClampToEdgeWrapping
        1002: 'mirror' // MirroredRepeatWrapping
      };

      final repeat = texture.repeat.clone();
      final offset = texture.offset.clone();
      final rotation = texture.rotation;

      // rotation is around the wrong point. after rotation we need to shift offset again so that we're rotating around the right spot
      final xRotationOffset = math.sin( rotation );
      final yRotationOffset = math.cos( rotation );

      // texture coordinates start in the opposite corner, need to correct
      offset.y = 1 - offset.y - repeat.y;

      // turns out QuickLook is buggy and interprets texture repeat inverted/applies operations in a different order.
      // Apple Feedback: 	FB10036297 and FB11442287
      if ( quickLookCompatible ) {
        // This is NOT correct yet in QuickLook, but comes close for a range of models.
        // It becomes more incorrect the bigger the offset is

        offset.x = offset.x / repeat.x;
        offset.y = offset.y / repeat.y;

        offset.x += xRotationOffset / repeat.x;
        offset.y += yRotationOffset - 1;
      } 
      else {
        // results match glTF results exactly. verified correct in usdview.
        offset.x += xRotationOffset * repeat.x;
        offset.y += ( 1 - yRotationOffset ) * repeat.y;
      }

      return '''
    def Shader "PrimvarReader_${ mapType }"
    {
      uniform token info:id = "UsdPrimvarReader_float2"
      float2 inputs:fallback = (0.0, 0.0)
      token inputs:varname = "${ uv }"
      float2 outputs:result
    }

    def Shader "Transform2d_${ mapType }"
    {
      uniform token info:id = "UsdTransform2d"
      token inputs:in.connect = </Materials/Material_${ material.id }/PrimvarReader_${ mapType }.outputs:result>
      float inputs:rotation = ${ ( rotation * ( 180 / math.pi ) ).toStringAsFixed( PRECISION ) }
      float2 inputs:scale = ${ buildVector2( repeat ) }
      float2 inputs:translation = ${ buildVector2( offset ) }
      float2 outputs:result
    }

    def Shader "Texture_${ texture.id }_${ mapType }"
    {
      uniform token info:id = "UsdUVTexture"
      asset inputs:file = @textures/Texture_${ id }.png@
      float2 inputs:st.connect = </Materials/Material_${ material.id }/Transform2d_${ mapType }.outputs:result>
      ${ color != null ? 'float4 inputs:scale = ' + buildColor4( color ) : '' }
      token inputs:sourceColorSpace = "${ texture.colorSpace == NoColorSpace ? 'raw' : 'sRGB' }"
      token inputs:wrapS = "${ WRAPPINGS[ texture.wrapS ] }"
      token inputs:wrapT = "${ WRAPPINGS[ texture.wrapT ] }"
      float outputs:r
      float outputs:g
      float outputs:b
      float3 outputs:rgb
      ${ material.transparent || material.alphaTest > 0.0 ? 'float outputs:a' : '' }
    }
      ''';
    }


    if ( material.side == DoubleSide ) {
      console.warning( 'THREE.USDZExporter: USDZ does not support double sided materials $material');
    }

    if ( material.map != null ) {
      inputs.add( '${ pad }color3f inputs:diffuseColor.connect = </Materials/Material_${ material.id }/Texture_${ material.map?.id }_diffuse.outputs:rgb>' );

      if ( material.transparent ) {
        inputs.add( '${ pad }float inputs:opacity.connect = </Materials/Material_${ material.id }/Texture_${ material.map?.id }_diffuse.outputs:a>' );
      } 
      else if ( material.alphaTest > 0.0 ) {
        inputs.add( '${ pad }float inputs:opacity.connect = </Materials/Material_${ material.id }/Texture_${ material.map?.id }_diffuse.outputs:a>' );
        inputs.add( '${ pad }float inputs:opacityThreshold = ${material.alphaTest}' );
      }

      samplers.add( buildTexture( material.map!, 'diffuse', material.color ) );
    } 
    else {
      inputs.add( '${ pad }color3f inputs:diffuseColor = ${ buildColor( material.color ) }' );
    }

    if ( material.emissiveMap != null ) {
      inputs.add( '${ pad }color3f inputs:emissiveColor.connect = </Materials/Material_${ material.id }/Texture_${ material.emissiveMap!.id }_emissive.outputs:rgb>' );
      samplers.add( buildTexture( material.emissiveMap!, 'emissive', new Color( material.emissive!.red * material.emissiveIntensity, material.emissive!.green * material.emissiveIntensity, material.emissive!.blue * material.emissiveIntensity ) ) );
    }
    else if ( (material.emissive?.getHex() ?? 0) > 0 ) {
      inputs.add( '${ pad }color3f inputs:emissiveColor = ${ buildColor( material.emissive! ) }''' );
    }

    if ( material.normalMap != null ) {
      inputs.add( '${ pad }normal3f inputs:normal.connect = </Materials/Material_${ material.id }/Texture_${ material.normalMap!.id }_normal.outputs:rgb>' );
      samplers.add( buildTexture( material.normalMap!, 'normal' ) );
    }

    if ( material.aoMap != null ) {
      inputs.add( '${ pad }float inputs:occlusion.connect = </Materials/Material_${ material.id }/Texture_${ material.aoMap!.id }_occlusion.outputs:r>' );
      samplers.add( buildTexture( material.aoMap!, 'occlusion', new Color( material.aoMapIntensity!, material.aoMapIntensity!, material.aoMapIntensity! ) ) );
    }

    if ( material.roughnessMap != null ) {
      inputs.add( '${ pad }float inputs:roughness.connect = </Materials/Material_${ material.id }/Texture_${ material.roughnessMap!.id }_roughness.outputs:g>' );
      samplers.add( buildTexture( material.roughnessMap!, 'roughness', new Color( material.roughness, material.roughness, material.roughness ) ) );
    } 
    else {
      inputs.add( '${ pad }float inputs:roughness = ${ material.roughness }' );
    }

    if ( material.metalnessMap != null ) {
      inputs.add( '${ pad }float inputs:metallic.connect = </Materials/Material_${ material.id }/Texture_${ material.metalnessMap!.id }_metallic.outputs:b>' );
      samplers.add( buildTexture( material.metalnessMap!, 'metallic', new Color( material.metalness, material.metalness, material.metalness ) ) );
    } 
    else {
      inputs.add( '${ pad }float inputs:metallic = ${ material.metalness }' );
    }

    if ( material.alphaMap != null ) {
      inputs.add( '${pad}float inputs:opacity.connect = </Materials/Material_${material.id}/Texture_${material.alphaMap!.id}_opacity.outputs:r>' );
      inputs.add( '${pad}float inputs:opacityThreshold = 0.0001' );
      samplers.add( buildTexture( material.alphaMap!, 'opacity' ) );
    } 
    else {
      inputs.add( '${pad}float inputs:opacity = ${material.opacity}' );
    }

    if ( material is MeshPhysicalMaterial ) {
      if ( material.clearcoatMap != null ) {
        inputs.add( '${pad}float inputs:clearcoat.connect = </Materials/Material_${material.id}/Texture_${material.clearcoatMap!.id}_clearcoat.outputs:r>' );
        samplers.add( buildTexture( material.clearcoatMap!, 'clearcoat', new Color( material.clearcoat, material.clearcoat, material.clearcoat ) ) );
      } 
      else {
        inputs.add( '${pad}float inputs:clearcoat = ${material.clearcoat}' );
      }

      if ( material.clearcoatRoughnessMap != null ) {
        inputs.add( '${pad}float inputs:clearcoatRoughness.connect = </Materials/Material_${material.id}/Texture_${material.clearcoatRoughnessMap!.id}_clearcoatRoughness.outputs:g>' );
        samplers.add( buildTexture( material.clearcoatRoughnessMap!, 'clearcoatRoughness', new Color( material.clearcoatRoughness!, material.clearcoatRoughness!, material.clearcoatRoughness! ) ) );
      } 
      else {
        inputs.add( '${pad}float inputs:clearcoatRoughness = ${material.clearcoatRoughness}' );
      }

      inputs.add( '${ pad }float inputs:ior = ${ material.ior }' );
    }

    return '''

  def Material "Material_${ material.id }"
  {
    def Shader "PreviewSurface"
    {
      uniform token info:id = "UsdPreviewSurface"
${ inputs.join( '\n' ) }
      int inputs:useSpecularWorkflow = 0
      token outputs:surface
    }
    token outputs:surface.connect = </Materials/Material_${ material.id }/PreviewSurface.outputs:surface>
${ samplers.join( '\n' ) }
  }
    ''';
  }

  String buildColor(Color color ) {
    return '(${ color.red }, ${ color.green }, ${ color.blue })';
  }

  String buildColor4(Color color ) {
    return '(${ color.red }, ${ color.green }, ${ color.blue }, 1.0)';
  }

  String buildVector2(Vector vector ) {
    return '(${ vector.x }, ${ vector.y })';
  }


  String buildCamera(PerspectiveCamera camera ) {
    final name = camera.name != ''?camera.name:'Camera_${camera.id}';
    final transform = buildMatrix( camera.matrixWorld );

    if ( camera.matrixWorld.determinant() < 0 ) {
      console.warning( 'THREE.USDZExporter: USDZ does not support negative scales $camera');
    }

    if ( camera is OrthographicCamera ) {
      return '''def Camera "${name}"
    {
      matrix4d xformOp:transform = ${ transform }
      uniform token[] xformOpOrder = ["xformOp:transform"]

      float2 clippingRange = (${ camera.near.toStringAsFixed( PRECISION ) }, ${ camera.far.toStringAsFixed( PRECISION ) })
      float horizontalAperture = ${ (( camera.left.abs()  + camera.right.abs() ) * 10 ).toStringAsFixed( PRECISION ) }
      float verticalAperture = ${ ( ( camera.top.abs()  + camera.bottom.abs() ) * 10 ).toStringAsFixed( PRECISION ) }
      token projection = "orthographic"
    }
      ''';
    } 
    else {
      return '''def Camera "${name}"
    {
      matrix4d xformOp:transform = ${ transform }
      uniform token[] xformOpOrder = ["xformOp:transform"]

      float2 clippingRange = (${ camera.near.toStringAsFixed( PRECISION ) }, ${ camera.far.toStringAsFixed( PRECISION ) })
      float focalLength = ${ camera.getFocalLength().toStringAsFixed( PRECISION ) }
      float focusDistance = ${ camera.focus.toStringAsFixed( PRECISION ) }
      float horizontalAperture = ${ camera.getFilmWidth().toStringAsFixed( PRECISION ) }
      token projection = "perspective"
      float verticalAperture = ${ camera.getFilmHeight().toStringAsFixed( PRECISION ) }
    }
      ''';
    }
  }
}
