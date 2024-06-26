import 'dart:math' as math;
import 'package:xml/xpath.dart';
import 'package:three_js_animations/three_js_animations.dart';
import 'package:three_js_core_loaders/three_js_core_loaders.dart';
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';
import 'package:xml/xml.dart';
import '../tga_loader.dart';
import 'collada_data.dart';

class ColladaKeyFrame{
  ColladaKeyFrame(this.time,this.value);

  double time;
  Map value;
}

class ColladaParser{
  LoadingManager? manager;

  final position =Vector3();
  final scale =Vector3();
  final quaternion =Quaternion();
  final matrix =Matrix4();
  final vector =Vector3();

  int count = 0;

  final tempColor =Color();
  final List<AnimationClip> animations = [];
  Map<String,dynamic> kinematics = {};

  final Map<String,Map<String,dynamic>> library = {
    'animations': {},
    'clips': {},
    'controllers': {},
    'images': {},
    'effects': {},
    'materials': {},
    'cameras': {},
    'lights': {},
    'geometries': {},
    'nodes': {},
    'visualScenes': {},
    'kinematicsModels': {},
    'physicsModels': {},
    'kinematicsScenes': <String,dynamic>{}
  };

  String text;
  late XmlElement collada;
  late TGALoader tgaLoader;
  late TextureLoader textureLoader;
  Map<String, dynamic> asset = {};

  ColladaParser(this.manager, this.text, String? path, String crossOrigin){
		final xml = XmlDocument.parse(text);

		collada = xml.getElement('COLLADA')!;
    
    asset = parseAsset( collada.getElement('asset')!);//getElementsByTagName( collada, 'asset' )[ 0 ]
    textureLoader = TextureLoader(manager: manager, flipY: true);
    textureLoader.setPath(path ?? '').setCrossOrigin(crossOrigin );

    tgaLoader = TGALoader( manager );
    tgaLoader.setPath(path ?? '' );
    
  }

	Future<ColladaData?> parse() async{
		if (text.isEmpty) {
			return ColladaData(scene: Scene());
		}

		// metadata

		final version = collada.getAttribute( 'version' );
		console.info( 'ColladaLoader: File version $version');

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

		await buildLibrary( library['animations']!, buildAnimation );
		await buildLibrary( library['clips']!, buildAnimationClip );
		await buildLibrary( library['controllers']!, buildController );
		await buildLibrary( library['images']!, buildImage );
		await buildLibrary( library['effects']!, buildEffect );
		await buildLibrary( library['materials']!, buildMaterial );
		await buildLibrary( library['cameras']!, buildCamera );
		await buildLibrary( library['lights']!, buildLight );
		await buildLibrary( library['geometries']!, buildGeometry );
		await buildLibrary( library['visualScenes']!, buildVisualScene );

		await setupAnimations();
		await setupKinematics();

		final AnimationObject scene = await parseScene( collada.getElement( 'scene' )!);
		scene.animations = animations;

		if ( asset['upAxis'] == 'Z_UP' ) {
			console.warning( 'ColladaLoader: You are loading an asset with a Z-UP coordinate system. The loader just rotates the asset to transform it into Y-UP. The vertex data are not converted, see #24289.' );
			scene.rotation.set( - math.pi / 2, 0.0, 0.0 );
		}

		scene.scale.scale( asset['unit'] );

		return ColladaData(
			animations: animations,
			kinematics: kinematics,
			library: library,
			scene: scene
    );
	}

  // library

  void parseLibrary(XmlElement xml, String libraryName, String nodeName, parser ) {
    final library = xml.getElement(libraryName);

    if ( library != null ) {
      for (final element in library.findAllElements(nodeName)) {
        parser(element);
      }
    }
  }

  Future<void> buildLibrary(Map<String,dynamic> data, builder ) async{
    for ( final name in data.keys ) {
      final object = data[ name ]!;
      object['build'] = await builder( data[ name ] );
    }
  }

  // get
  bool hasVisualScene( id ) {
    return library['visualScenes']?[ id ] != null;
  }
  bool hasNode( id ) {
    return library['nodes']?[ id ] != null;
  }
  
  Future getNode( id ) async{
    final data = library['nodes']![ id ];
    if ( data['build'] != null ) return data['build'];
    data['build'] = await buildNode(data);

    return data['build'];
  }

  // animation

  parseAnimation(XmlElement xml ) {
    final Map<String,dynamic> data = {
      'sources': {},
      'samplers': {},
      'channels': {}
    };

    bool hasChildren = false;

    for (final child in xml.descendantElements ) {
      String id;

      switch ( child.name.local ) {
        case 'source':
          id = child.getAttribute( 'id' )!;
          data['sources']![ id ] = parseSource( child );
          break;
        case 'sampler':
          id = child.getAttribute( 'id' )!;
          data['samplers']![ id ] = parseAnimationSampler( child );
          break;
        case 'channel':
          id = child.getAttribute( 'target' )!;
          data['channels']![ id ] = parseAnimationChannel( child );
          break;

        case 'animation':
          // hierarchy of related animations
          parseAnimation( child );
          hasChildren = true;
          break;

        default:
          console.info( child );
      }
    }

    if ( !hasChildren ) {
      // since 'id' attributes can be optional, it's necessary to generate a UUID for unqiue assignment
      library['animations']![ xml.getAttribute( 'id' ) ?? MathUtils.generateUUID() ] = data;
    }
  }

  void createMissingKeyframes(List<ColladaKeyFrame> keyframes, property ) {
    ColladaKeyFrame? prev, next;

    for (int i = 0, l = keyframes.length; i < l; i ++ ) {
      final keyframe = keyframes[ i ];

      if ( keyframe.value[ property ] == null ) {
        prev = getPrev( keyframes, i, property );
        next = getNext( keyframes, i, property );

        if ( prev == null ) {
          keyframe.value[ property ] = next?.value[ property ];
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

  void transformAnimationData(List<ColladaKeyFrame> keyframes, property, defaultValue ) {
    ColladaKeyFrame keyframe;
    bool empty = true;

    // check, if values of a property are missing in our keyframes

    for (int i = 0; i < keyframes.length; i ++ ) {
      keyframe = keyframes[ i ];

      if ( keyframe.value[ property ] == null ) {
        keyframe.value[ property ] = null; // mark as missing
      } 
      else {
        empty = false;
      }
    }

    if ( empty ) {
      for (int i = 0, l = keyframes.length; i < l; i ++ ) {
        keyframe = keyframes[ i ];
        keyframe.value[ property ] = defaultValue;
      }
    } 
    else {
      createMissingKeyframes( keyframes, property );
    }
  }
  
  List<ColladaKeyFrame> prepareAnimationData( data, defaultMatrix ) {
    int ascending(ColladaKeyFrame a, ColladaKeyFrame b ) {
      return (a.time - b.time).toInt();
    }

    final List<ColladaKeyFrame> keyframes = [];

    for ( final time in data.keys ) {
      keyframes.add( ColladaKeyFrame(time, data[ time ]));
    }

    keyframes.sort( ascending );

    for (int i = 0; i < 16; i ++ ) {
      transformAnimationData( keyframes, i, defaultMatrix.storage[ i ] );
    }

    return keyframes;
  }

  Future<Map<String, dynamic>> buildAnimationChannel(Map<String,dynamic> channel, inputSource, outputSource ) async{
    final node = library['nodes']![ channel['id'] ];
    final object3D = await getNode( node['id'] );

    final transform = node['transforms'][ channel['sid'] ];
    final defaultMatrix = node['matrix'].clone().transpose();

    var time, stride;

    final Map data = {};

    // the collada spec allows the animation of data in various ways.
    // depending on the transform type (matrix, translate, rotate, scale), we execute different logic

    switch ( transform ) {
      case 'matrix':
        for (int i = 0, il = inputSource['array'].length; i < il; i ++ ) {
          time = inputSource['array'][ i ];
          stride = i * outputSource['stride'];

          if ( data[ time ] == null ) data[ time ] = {};

          if ( channel['arraySyntax'] == true ) {
            final value = outputSource['array'][ stride ];
            final index = channel['indices'][ 0 ] + 4 * channel['indices'][ 1 ];

            data[ time ][ index ] = value;
          } else {
            for ( int j = 0, jl = outputSource['stride']; j < jl; j ++ ) {
              data[ time ][ j ] = outputSource['array'][ stride + j ];
            }
          }
        }
        break;

      case 'translate':
        console.warning( 'ColladaLoader: Animation transform type "$transform" not yet implemented. ');
        break;

      case 'rotate':
        console.warning( 'ColladaLoader: Animation transform type "$transform" not yet implemented.' );
        break;

      case 'scale':
        console.warning( 'ColladaLoader: Animation transform type "$transform" not yet implemented.' );
        break;

    }

    final keyframes = prepareAnimationData( data, defaultMatrix );

    final animation = {
      'name': object3D.uuid,
      'keyframes': keyframes
    };

    return animation;
  }

  Future<List<KeyframeTrack>> buildAnimation(Map<String,dynamic> data ) async{
    final List<KeyframeTrack> tracks = [];

    final channels = data['channels'];
    final samplers = data['samplers'];
    final sources = data['sources'];

    for ( final target in channels.keys ) {
      final channel = channels[ target ];
      final sampler = samplers[ channel['sampler'] ];

      final inputId = sampler['inputs']['INPUT'];
      final outputId = sampler['inputs']['OUTPUT'];

      final inputSource = sources[ inputId ];
      final outputSource = sources[ outputId ];

      final animation = await buildAnimationChannel( channel, inputSource, outputSource );

      createKeyframeTracks( animation, tracks );
    }

    return tracks;
  }

  Future getAnimation( id ) async{
    //return getBuild( library['animations']![ id ], buildAnimation );
    final data = library['animations']![ id ];
    if ( data['build'] != null ) return data['build'];
    data['build'] = await buildAnimation(data);

    return data['build'];
  }
  // animation clips

  void parseAnimationClip(XmlElement xml ) {
    final Map<String,dynamic> data = {
      'name': xml.getAttribute( 'id' ) ?? 'default',
      'start': double.parse( xml.getAttribute( 'start' ) ?? '0' ),
      'end': double.parse( xml.getAttribute( 'end' ) ?? '0' ),
      'animations': []
    };

    for (final child in xml.descendantElements) {
      
      switch ( child.name.local ) {
        case 'instance_animation':
          data['animations'].add( parseId( child.getAttribute( 'url' )! ) );
          break;
      }
    }
    library['clips']![ xml.getAttribute( 'id' )! ] = data;
  }

  Future<AnimationClip> buildAnimationClip(Map<String,dynamic> data ) async{
    final List<KeyframeTrack> tracks = [];
    final name = data['name'];
    final duration = ( data['end'] - data['start'] ) ?? - 1;
    final animations = data['animations'];

    for (int i = 0, il = animations.length; i < il; i ++ ) {
      final animationTracks = await getAnimation( animations[ i ] );
      for (int j = 0, jl = animationTracks.length; j < jl; j ++ ) {
        tracks.add( animationTracks[ j ] );
      }
    }
    return AnimationClip( name, duration, tracks );
  }

  getAnimationClip( id ) {
    return getBuild( library['clips']![ id ], buildAnimationClip );
  }

  // controller

  void parseController(XmlElement xml ) {
    final Map<String,dynamic> data = {};

    for (final child in xml.descendantElements) {
      switch ( child.name.local ) {
        case 'skin':
          // there is exactly one skin per controller
          data['id'] = parseId( child.getAttribute( 'source' )! );
          data['skin'] = parseSkin( child );
          break;
        case 'morph':
          data['id'] = parseId( child.getAttribute( 'source' )! );
          console.warning( 'ColladaLoader: Morph target animation not supported yet.' );
          break;
      }
    }

    library['controllers']![ xml.getAttribute( 'id' )! ] = data;
  }

  Map<String, dynamic> buildController(Map<String,dynamic> data ) {
    final Map<String,dynamic> build = {
      'id': data['id']
    };

    final geometry = library['geometries']![ build['id'] ];

    if ( data['skin'] != null ) {
      build['skin'] = buildSkin( data['skin'] );
      geometry['sources']['skinIndices'] = build['skin']['indices'];
      geometry['sources']['skinWeights'] = build['skin']['weights'];
    }

    return build;
  }

  getController( id ) {
    return getBuild( library['controllers']![ id ], buildController );
  }

  // image

  void parseImage(XmlElement xml ) {
    final Map<String,dynamic> data = {
      'init_from': xml.getElement('init_from')?.innerText,
    };

    library['images']![ xml.getAttribute( 'id' )! ] = data;
  }

  buildImage(Map<String,dynamic> data ) {
    if ( data['build'] != null ) return data['build'];
    return data['init_from'];
  }

  getImage( id ) {
    final data = library['images']![ id ];
    if ( data != null ) {
      return getBuild( data, buildImage );
    }

    console.warning( 'ColladaLoader: Couldn\'t find image with ID: $id');

    return null;
  }

  // effect

  Map<String, dynamic> parseEffectSurface(XmlElement xml ) {
    final Map<String,dynamic> data = {};

    for (final child in xml.descendantElements) {
      switch ( child.name.local ) {
        case 'init_from':
          data['init_from'] = child.innerText;
          break;
      }
    }

    return data;
  }

  Map<String, dynamic> parseEffectSampler(XmlElement xml ) {
    final Map<String, dynamic> data = {};

    for (final child in xml.descendantElements) {
      switch ( child.name.local ) {
        case 'source':
          data['source'] = child.innerText;
          break;
      }
    }

    return data;
  }
  
  Map<String, dynamic> parseEffectTechnique(XmlElement xml ) {
    final Map<String,dynamic> data = {};

    for (final child in xml.descendantElements) {
      switch ( child.name.local ) {
        case 'constant':
        case 'lambert':
        case 'blinn':
        case 'phong':
          data['type'] = child.name.local;
          data['parameters'] = parseEffectParameters( child );
          break;
        case 'extra':
          data['extra'] = parseEffectExtra( child );
          break;
      }
    }

    return data;
  }

  void parseEffectNewparam(XmlElement xml, Map<String, dynamic> data ) {
    final sid = xml.getAttribute( 'sid' );

    for (final child in xml.descendantElements) {
      switch ( child.name.local ) {
        case 'surface':
          data['surfaces'][ sid ] = parseEffectSurface( child );
          break;
        case 'sampler2D':
          data['samplers'][ sid ] = parseEffectSampler( child );
          break;
      }
    }
  }

  Map<String, dynamic> parseEffectProfileCOMMON(XmlElement xml ) {
    final Map<String,dynamic> data = {
      'surfaces': <String,dynamic>{},
      'samplers': <String,dynamic>{}
    };

    for (final child in xml.descendantElements) {
      switch ( child.name.local ) {
        case 'newparam':
          parseEffectNewparam( child, data );
          break;
        case 'technique':
          data['technique'] = parseEffectTechnique( child );
          break;
        case 'extra':
          data['extra'] = parseEffectExtra( child );
          break;
      }
    }

    return data;
  }
  
  void parseEffect(XmlElement xml ) {
    final Map<String,dynamic> data = {};

    for (final child in xml.descendantElements) {
      switch ( child.name.local ) {
        case 'profile_COMMON':
          data['profile'] = parseEffectProfileCOMMON( child );
          break;
      }
    }

    library['effects']![ xml.getAttribute( 'id' )! ] = data;
  }

  Map<String, dynamic> buildEffect(Map<String, dynamic> data ) {
    return data;
  }

  getEffect( id ) {
    return getBuild( library['effects']![ id ], buildEffect );
  }

  void parseMaterial(XmlElement xml ) {
    final Map<String,dynamic> data = {
      'name': xml.getAttribute( 'name' )
    };

    for (final child in xml.descendantElements) {
      switch ( child.name.local ) {
        case 'instance_effect':
          data['url'] = parseId( child.getAttribute( 'url' )! );
          break;
      }
    }

    library['materials']![ xml.getAttribute( 'id' )! ] = data;
  }

  Loader getTextureLoader(String image ) {
    Loader? loader;

    var extension = image.split( '.' ).last; // http://www.jstips.co/en/javascript/get-file-extension/
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

  Future<Material?> buildMaterial(Map<String,dynamic> data ) async{
    final effect = getEffect( data['url'] );
    final Map<String,dynamic> technique = effect['profile']['technique'];
    Material? material;

    switch ( technique['type'] ) {
      case 'phong':
      case 'blinn':
        material = MeshPhongMaterial();
        break;
      case 'lambert':
        material = MeshLambertMaterial();
        break;
      default:
        material = MeshBasicMaterial();
        break;
    }

    material.name = data['name'] ?? '';

    Future<Texture?> getTexture( textureObject, [colorSpace]) async{
      final sampler = effect['profile']['samplers'][ textureObject['id'] ];
      var image;

      // get image

      if ( sampler != null ) {
        final surface = effect['profile']['surfaces'][ sampler['source'] ];
        image = getImage( surface['init_from'] );
      } 
      else {
        console.warning( 'ColladaLoader: Undefined sampler. Access image directly (see #12530).' );
        image = getImage( textureObject['id'] );
      }

      // create texture if image is avaiable

      if ( image != null ) {
        final loader = getTextureLoader( image );
        final Texture texture = (await loader.unknown( image ))!;
        final extra = textureObject['extra'];

        if ( extra != null && extra['technique'] != null && !isEmpty( extra['technique'] )) {
          final technique = extra['technique'];

          texture.wrapS = technique['wrapU'] ? RepeatWrapping : ClampToEdgeWrapping;
          texture.wrapT = technique['wrapV'] ? RepeatWrapping : ClampToEdgeWrapping;

          texture.offset.setValues( technique['offsetU'] ?? 0, technique['offsetV'] ?? 0 );
          texture.repeat.setValues( technique['repeatU'] ?? 1, technique['repeatV'] ?? 1 );
        } 
        else {
          texture.wrapS = RepeatWrapping;
          texture.wrapT = RepeatWrapping;
        }

        if ( colorSpace != null ) {
          texture.colorSpace = colorSpace;
        }

        return texture;
      } 
      else {
        console.warning( 'ColladaLoader: Couldn\'t create texture with ID: ${textureObject['id']}');
        return null;
      }
    }

    final Map<String,dynamic> parameters = technique['parameters'];

    for ( final key in parameters.keys ) {
      final Map<String,dynamic> parameter = parameters[ key ];

      switch ( key ) {
        case 'diffuse':
          if ( parameter['color']  != null ) material.color.copyFromArray( parameter['color'] );
          if ( parameter['texture']  != null ) material.map = await getTexture( parameter['texture'], SRGBColorSpace );
          break;
        case 'specular':
          if ( parameter['color']  != null && material.specular  != null ) material.specular?.copyFromArray( parameter['color'] );
          if ( parameter['texture'] != null) material.specularMap = await getTexture( parameter['texture'] );
          break;
        case 'bump':
          if ( parameter['texture']  != null ) material.normalMap = await getTexture( parameter['texture'] );
          break;
        case 'ambient':
          if ( parameter['texture']  != null ) material.lightMap = await getTexture( parameter['texture'], SRGBColorSpace );
          break;
        case 'shininess':
          if ( parameter['float']  != null && material.shininess  != null ) material.shininess = parameter['float'];
          break;
        case 'emission':
          if ( parameter['color'] != null && material.emissive  != null ) material.emissive?.copyFromArray( parameter['color'] );
          if ( parameter['texture']  != null ) material.emissiveMap = await getTexture( parameter['texture'], SRGBColorSpace );
          break;
      }
    }

    material.color.convertSRGBToLinear();
    if ( material.specular != null) material.specular?.convertSRGBToLinear();
    if ( material.emissive != null) material.emissive?.convertSRGBToLinear();

    Map<String,dynamic>? transparent = parameters[ 'transparent' ];
    Map<String,dynamic>? transparency = parameters[ 'transparency' ];

    // <transparency> does not exist but <transparent>

    if ( transparency == null && transparent != null) {
      transparency = {
        'float': 1
      };
    }

    // <transparent> does not exist but <transparency>

    if ( transparent == null && transparency != null) {
      transparent = {
        'opaque': 'A_ONE',
        'data': {
          'color': [ 1, 1, 1, 1 ]
        } };
    }

    if ( transparent != null && transparency != null) {
      // handle case if a texture exists but no color

      if ( transparent['data']?['texture'] != null) {
        material.transparent = true;
      } 
      else {
        final List<double> color = transparent['data']['color'];
        switch ( transparent['opaque'] ) {
          case 'A_ONE':
            material.opacity = color[ 3 ] * transparency['float'];
            break;
          case 'RGB_ZERO':
            material.opacity = 1 - ( color[ 0 ] * transparency['float'] );
            break;
          case 'A_ZERO':
            material.opacity = 1 - ( color[ 3 ] * transparency['float'] );
            break;
          case 'RGB_ONE':
            material.opacity = color[ 0 ] * transparency['float'];
            break;
          default:
            console.warning( 'ColladaLoader: Invalid opaque type "%s" of transparent tag. ${transparent['opaque']}');
        }

        if ( material.opacity < 1 ) material.transparent = true;
      }
    }

    if ( technique['extra']?['technique'] != null ) {
      final techniques = technique['extra']['technique'];

      for ( final k in techniques ) {
        final v = techniques[ k ];

        switch ( k ) {
          case 'double_sided':
            material.side = ( v == 1 ? DoubleSide : FrontSide );
            break;
          case 'bump':
            material.normalMap = await getTexture( v.texture );
            material.normalScale = Vector2( 1, 1 );
            break;
        }
      }
    }

    return material;
  }

  Future getMaterial( id ) async {
    final data = library['materials']![ id ];
    if ( data['build'] != null ) return data['build'];
    data['build'] = await buildMaterial(data);

    return data['build'];
  }

  Future<List<Material>> resolveMaterialBinding( keys, instanceMaterials ) async{
    final fallbackMaterial = MeshBasicMaterial.fromMap( {
      'name': '__DEFAULT',
      'color': 0xff00ff
    });

    final List<Material> materials = [];

    for (int i = 0, l = keys.length; i < l; i ++ ) {
      final id = instanceMaterials[ keys[ i ] ];

      if ( id == null ) {
        console.warning( 'ColladaLoader: Material with key ${keys[ i ]} not found. Apply fallback material.');
        materials.add( fallbackMaterial );
      } 
      else {
        materials.add( await getMaterial( id ) );
      }
    }

    return materials;
  }

  Future<List<Object3D>> buildObjects(Map<String,dynamic> geometries, instanceMaterials ) async{
    final List<Object3D> objects = [];
    
    for ( final type in geometries.keys ) {
      
      final Map<String,dynamic> geometry = geometries[ type ];
      final List<Material> materials = await resolveMaterialBinding( geometry['materialKeys'], instanceMaterials );
      // handle case if no materials are defined

      if ( materials.isEmpty) {
        if ( type == 'lines' || type == 'linestrips' ) {
          materials.add(LineBasicMaterial() );
        } 
        else {
          materials.add(MeshPhongMaterial() );
        }
      }

      // Collada allows to use phong and lambert materials with lines. Replacing these cases with LineBasicMaterial.
      if ( type == 'lines' || type == 'linestrips' ) {
        for (int i = 0, l = materials.length; i < l; i ++ ) {
          final material = materials[ i ];

          if ( material is MeshPhongMaterial || material is MeshLambertMaterial) {
            final lineMaterial = LineBasicMaterial();
            lineMaterial.color.setFrom( material.color );
            lineMaterial.opacity = material.opacity;
            lineMaterial.transparent = material.transparent;
            materials[ i ] = lineMaterial;
          }
        }
      }

      // regard skinning
      final skinning = ( geometry['data'].attributes['skinIndex'] != null );
      final Material? material = ( materials.length == 1 ) ? materials[ 0 ] : GroupMaterial(materials);

      Object3D? object;

      switch ( type ) {
        case 'lines':
          object = LineSegments( geometry['data'], material );
          break;
        case 'linestrips':
          object = Line( geometry['data'], material );
          break;
        case 'triangles':
        case 'polylist':
          if ( skinning ) {
            object = SkinnedMesh( geometry['data'], material );
          } 
          else {
            object = Mesh( geometry['data'], material );
          }
          break;
      }
      if(object != null){
        objects.add( object );
      }
    }

    return objects;
  }

  Map<String,dynamic> parseCameraParameters(XmlElement xml ) {
    final Map<String,dynamic> data = {};

    for (final child in xml.descendantElements) {
      switch ( child.name.local ) {
        case 'xfov':
        case 'yfov':
        case 'xmag':
        case 'ymag':
        case 'znear':
        case 'zfar':
        case 'aspect_ratio':
          data[ child.name.local ] = double.parse( child.innerText );
          break;
      }
    }
    return data;
  }

  Map<String, dynamic> parseCameraTechnique(XmlElement xml ) {
    final Map<String, dynamic> data = {};
    for (final child in xml.descendantElements) {
      switch ( child.name.local ) {
        case 'perspective':
        case 'orthographic':
          data['technique'] = child.name.local;
          data['parameters'] = parseCameraParameters( child );
          break;
      }
    }

    return data;
  }

  Map<String, dynamic> parseCameraOptics(XmlElement xml ) {
    for (final child in xml.descendantElements) {
      switch ( child.name.local ) {
        case 'technique_common':
          return parseCameraTechnique( child );
      }
    }
    return {};
  }

  void parseCamera(XmlElement xml ) {
    final Map<String, dynamic> data = {
      'name': xml.getAttribute( 'name' )
    };

    for (final child in xml.descendantElements) {
      switch ( child.name.local ) {
        case 'optics':
          data['optics'] = parseCameraOptics( child );
          break;
      }
    }

    library['cameras']![ xml.getAttribute( 'id' )! ] = data;
  }

  Camera? buildCamera(Map<String, dynamic> data ) {
    Camera? camera;

    switch ( data['optics']['technique'] ) {
      case 'perspective':
        camera = PerspectiveCamera(
          data['optics']['parameters']['yfov'],
          data['optics']['parameters']['aspect_ratio'],
          data['optics']['parameters']['znear'],
          data['optics']['parameters']['zfar']
        );
        break;
      case 'orthographic':
        var ymag = data['optics']['parameters']['ymag'];
        var xmag = data['optics']['parameters']['xmag'];
        final aspectRatio = data['optics']['parameters']['aspect_ratio'];

        xmag = ( xmag == null ) ? ( ymag * aspectRatio ) : xmag;
        ymag = ( ymag == null ) ? ( xmag / aspectRatio ) : ymag;

        xmag *= 0.5;
        ymag *= 0.5;

        camera = OrthographicCamera(
          - xmag, xmag, ymag, - ymag, // left, right, top, bottom
          data['optics']['parameters']['znear'],
          data['optics']['parameters']['zfar']
        );
        break;
      default:
        camera =PerspectiveCamera();
        break;
    }

    camera.name = data['name'] ?? '';
    return camera;
  }

  getCamera( id ) {
    final data = library['cameras']![ id ];

    if ( data != null ) {
      return getBuild( data, buildCamera );
    }

    console.warning( 'ColladaLoader: Couldn\'t find camera with ID: $id');
    return null;
  }

  Map<String, dynamic> parseLightParameters(XmlElement xml ) {
    final Map<String,dynamic> data = {};

    for (final child in xml.descendantElements) {
      switch ( child.name.local ) {
        case 'color':
          final array = parseFloats( child.innerText );
          data['color'] =Color().copyFromArray( array ).convertSRGBToLinear();
          break;
        case 'falloff_angle':
          data['falloffAngle'] = double.parse( child.innerText );
          break;
        case 'quadratic_attenuation':
          final f = double.tryParse( child.innerText );
          data['distance'] = f != null? math.sqrt( 1 / f ) : 0;
          break;
      }
    }

    return data;
  }

  Map<String, dynamic> parseLightTechnique(XmlElement xml ) {
    final Map<String,dynamic> data = {};

    for (final child in xml.descendantElements) {
      switch ( child.name.local ) {
        case 'directional':
        case 'point':
        case 'spot':
        case 'ambient':
          data['technique'] = child.name.local;
          data['parameters'] = parseLightParameters( child );
      }
    }

    return data;
  }

  void parseLight(XmlElement xml ) {
    Map<String, dynamic> data = {};

    for (final child in xml.descendantElements) {
      switch ( child.name.local ) {
        case 'technique_common':
          data = parseLightTechnique( child );
          break;
      }
    }

    library['lights']![ xml.getAttribute( 'id' )! ] = data;
  }

  Light? buildLight( data ) {
    Light? light;

    switch ( data['technique'] ) {
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

    if ( data['parameters']['color'] != null) light?.color?.setFrom( data['parameters']['color'] );
    if ( data['parameters']['distance'] != null) light?.distance = data['parameters']['distance'];

    return light;
  }

  getLight( id ) {
    final data = library['lights']?[ id ];

    if ( data != null ) {
      return getBuild( data, buildLight );
    }

    console.warning( 'ColladaLoader: Couldn\'t find light with ID: $id');

    return null;
  }

  // geometry

  Map<String, dynamic> parseGeometryPrimitive(XmlElement xml ) {
    final Map<String,dynamic> primitive = {
      'type': xml.name.local,
      'material': xml.getAttribute( 'material' ),
      'count': int.parse( xml.getAttribute( 'count' )! ),
      'inputs': <String,dynamic>{},
      'stride': 0,
      'hasUV': false
    };

    for (final child in xml.descendantElements) {
      switch ( child.name.local ) {
        case 'input':
          final id = parseId( child.getAttribute( 'source' )! );
          final semantic = child.getAttribute( 'semantic' )!;
          final offset = int.parse( child.getAttribute( 'offset' )! );
          final set = int.parse( child.getAttribute( 'set' ) ?? '0');
          final String inputname = ( set > 0 ? semantic + set.toString() : semantic );
          primitive['inputs'][ inputname ] = { 'id': id, 'offset': offset };
          primitive['stride'] = math.max<int>( primitive['stride'], offset + 1 );
          if ( semantic == 'TEXCOORD' ) primitive['hasUV'] = true;
          break;
        case 'vcount':
          primitive['vcount'] = parseInts( child.innerText );
          break;
        case 'p':
          primitive['p'] = parseInts( child.innerText );
          break;
      }
    }

    return primitive;
  }

  Map<String, dynamic> parseGeometryVertices(XmlElement xml ) {
    final Map<String, dynamic> data = {};
    for (final child in xml.descendantElements) {
      data[ child.getAttribute( 'semantic' )! ] = parseId( child.getAttribute( 'source' )! );
    }
    return data;
  }

  void parseGeometry(XmlElement xml ) {
    final Map<String,dynamic> data = {
      'name': xml.getAttribute( 'name' ),
      'sources': {},
      'vertices': {},
      'primitives': []
    };

    final mesh = xml.getElement('mesh' );

    // the following tags inside geometry are not supported yet (see https://github.com/mrdoob/three.js/pull/12606): convex_mesh, spline, brep
    if ( mesh == null ) return;

    for (final child in mesh.descendantElements) {
      final id = child.getAttribute( 'id' );

      switch ( child.name.local ) {
        case 'source':
          data['sources'][ id ] = parseSource( child );
          break;
        case 'vertices':
          //data['sources'][ id ] = data['sources'][ parseId( child.getElement('input' )!.getAttribute( 'source' )! ) ];
          data['vertices'] = parseGeometryVertices( child );
          break;
        case 'polygons':
          console.warning( 'ColladaLoader: Unsupported primitive type: ${child.name.local}');
          break;
        case 'lines':
        case 'linestrips':
        case 'polylist':
        case 'triangles':
          data['primitives'].add(parseGeometryPrimitive(child));
          break;
        default:
          console.info( child.name.local );
      }
    }
    library['geometries']![ xml.getAttribute( 'id' )! ] = data;
  }

  groupPrimitives(List primitives ) {
    final Map<String,dynamic> build = {};

    for (int i = 0; i < primitives.length; i ++ ) {
      final primitive = primitives[ i ];
      if ( build[ primitive['type'] ] == null ) build[ primitive['type'] ] = [];
      build[ primitive['type'] ].add( primitive );
    }

    return build;
  }

  checkUVCoordinates( primitives ) {
    int count = 0;

    for (int i = 0, l = primitives.length; i < l; i ++ ) {
      final primitive = primitives[ i ];
      if ( primitive['hasUV'] == true ) {
        count ++;
      }
    }

    if ( count > 0 && count < primitives.length ) {
      primitives['uvsNeedsFix'] = true;
    }
  }

  buildGeometryData(Map<String, dynamic> primitive, Map<String, dynamic>? source, int offset, array, [bool isColor = false ]) {
    //offset ??= 0;
    final List<int> indices = primitive['p'];
    final int stride = primitive['stride'];
    final List<int>? vcount = primitive['vcount'];

    final sourceArray = source?['array'];
    final sourceStride = source?['stride'];

    pushVector( i ) {
      var index = indices[ i + offset ] * sourceStride;
      final length = index + sourceStride;

      for ( ; index < length; index ++ ) {
        array.add( sourceArray[ index ].toDouble() );
      }

      if ( isColor ) {
        // convert the vertex colors from srgb to linear if present
        final startIndex = array.length - sourceStride - 1;
        tempColor.setRGB(
          array[ startIndex + 0 ],
          array[ startIndex + 1 ],
          array[ startIndex + 2 ]
        ).convertSRGBToLinear();

        array[ startIndex + 0 ] = tempColor.red;
        array[ startIndex + 1 ] = tempColor.green;
        array[ startIndex + 2 ] = tempColor.blue;
      }
    }

    if ( primitive['vcount'] != null ) {
      int index = 0;

      for (int i = 0, l = vcount!.length; i < l; i ++ ) {
        final int count = vcount[ i ];

        if ( count == 4 ) {
          final a = index + stride * 0;
          final b = index + stride * 1;
          final c = index + stride * 2;
          final d = index + stride * 3;

          pushVector( a ); pushVector( b ); pushVector( d );
          pushVector( b ); pushVector( c ); pushVector( d );
        } 
        else if ( count == 3 ) {
          final a = index + stride * 0;
          final b = index + stride * 1;
          final c = index + stride * 2;

          pushVector( a ); pushVector( b ); pushVector( c );
        } 
        else if ( count > 4 ) {
          for (int k = 1, kl = ( count - 2 ); k <= kl; k ++ ) {

            final a = index + stride * 0;
            final b = index + stride * k;
            final c = index + stride * ( k + 1 );

            pushVector( a ); pushVector( b ); pushVector( c );
          }
        }

        index += stride * count;
      }
    } 
    else {
      for (int i = 0, l = indices.length; i < l; i += stride ) {
        pushVector( i );
      }
    }
  }

  Map<String, dynamic> buildGeometryType( primitives, sources, vertices ) {
    final Map<String,dynamic> build = {};
    final Map<String,dynamic> position = { 'array': <double>[], 'stride': 0 };
    final Map<String,dynamic> normal = { 'array': <double>[], 'stride': 0 };
    final Map<String,dynamic> uv = { 'array': <double>[], 'stride': 0 };
    final Map<String,dynamic> uv1 = { 'array': <double>[], 'stride': 0 };
    final Map<String,dynamic> color = { 'array': <double>[], 'stride': 0 };

    final Map<String,dynamic> skinIndex = { 'array': <double>[], 'stride': 4 };
    final Map<String,dynamic> skinWeight = { 'array': <double>[], 'stride': 4 };

    final geometry = BufferGeometry();
    final materialKeys = [];
    int start = 0;

    for (int p = 0; p < primitives.length; p ++ ) {
      final primitive = primitives[ p ];
      final Map<dynamic, dynamic> inputs = primitive['inputs'];
      int count = 0;

      switch ( primitive['type'] ) {
        case 'lines':
        case 'linestrips':
          count = primitive['count'] * 2;
          break;
        case 'triangles':
          count = primitive['count'] * 3;
          break;
        case 'polylist':
          for (int g = 0; g < primitive['count']; g ++ ) {
            final int vc = primitive['vcount'][ g ];
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
          console.warning( 'ColladaLoader: Unknow primitive type: ${primitive['type']}');
      }

      geometry.addGroup( start, count, p );
      start += count;

      // material

      if ( primitive['material'] != null) {
        materialKeys.add( primitive['material'] );
      }

      // geometry data
      for ( final name in inputs.keys ) {
        final input = inputs[ name ];
        switch ( name )	{
          case 'VERTEX':
            for ( final key in vertices.keys ) {
              final id = vertices[ key ];
 
              switch ( key ) {
                case 'POSITION':
                  final prevLength = position['array'].length;
                  buildGeometryData( primitive, sources[ id ], input['offset'], position['array'] );
                  position['stride'] = sources[ id ]['stride'];

                  if ( sources['skinWeights'] != null && sources['skinIndices'] != null) {
                    buildGeometryData( primitive, sources['skinIndices'], input['offset'], skinIndex['array'] );
                    buildGeometryData( primitive, sources['skinWeights'], input['offset'], skinWeight['array'] );
                  }

                  // see #3803
                  if ( primitive['hasUV'] == false && primitive['uvsNeedsFix'] == true ) {
                    final count = ( position['array'].length - prevLength ) / position['stride'];
                    for (int i = 0; i < count; i ++ ) {
                      uv['array'].add( 0, 0 );
                    }
                  }
                  break;
                case 'NORMAL':
                  buildGeometryData( primitive, sources[ id ], input['offset'], normal['array'] );
                  normal['stride'] = sources[ id ]['stride'];
                  break;
                case 'COLOR':
                  buildGeometryData( primitive, sources[ id ], input['offset'], color['array'] );
                  color['stride'] = sources[ id ]['stride'];
                  break;
                case 'TEXCOORD':
                  buildGeometryData( primitive, sources[ id ], input['offset'], uv['array'] );
                  uv['stride'] = sources[ id ]['stride'];
                  break;
                case 'TEXCOORD1':
                  buildGeometryData( primitive, sources[ id ], input['offset'], uv1['array'] );
                  uv['stride'] = sources[ id ]['stride'];
                  break;
                default:
                  console.warning( 'ColladaLoader: Attribute "%s" not handled in geometry build process. $key');
              }
            }
            break;
          case 'NORMAL':
            buildGeometryData( primitive, sources[ input['id'] ], input['offset'], normal['array'] );
            normal['stride'] = sources[ input['id'] ]?['stride'];
            break;
          case 'COLOR':
            buildGeometryData( primitive, sources[ input['id'] ], input['offset'], color['array'], true );
            color['stride'] = sources[ input['id'] ]?['stride'];
            break;
          case 'TEXCOORD':
            buildGeometryData( primitive, sources[ input['id'] ], input['offset'], uv['array'] );
            uv['stride'] = sources[ input['id'] ]?['stride'];
            break;
          case 'TEXCOORD1':
            buildGeometryData( primitive, sources[ input['id'] ], input['offset'], uv1['array'] );
            uv1['stride'] = sources[ input['id'] ]?['stride'];
            break;
        }
      }
    }

    // build geometry
    if ( position['array'].isNotEmpty ) geometry.setAttributeFromString( 'position',Float32BufferAttribute.fromList( position['array'], position['stride'] ) );
    if ( normal['array'].isNotEmpty ) geometry.setAttributeFromString( 'normal',Float32BufferAttribute.fromList( normal['array'], normal['stride'] ) );
    if ( color['array'].isNotEmpty ) geometry.setAttributeFromString( 'color',Float32BufferAttribute.fromList( color['array'], color['stride'] ) );
    if ( uv['array'].isNotEmpty ) geometry.setAttributeFromString( 'uv',Float32BufferAttribute.fromList( uv['array'], uv['stride'] ) );
    if ( uv1['array'].isNotEmpty ) geometry.setAttributeFromString( 'uv1',Float32BufferAttribute.fromList( uv1['array'], uv1['stride'] ) );

    if ( skinIndex['array'].isNotEmpty ) geometry.setAttributeFromString( 'skinIndex',Float32BufferAttribute.fromList( skinIndex['array'], skinIndex['stride'] ) );
    if ( skinWeight['array'].isNotEmpty ) geometry.setAttributeFromString( 'skinWeight',Float32BufferAttribute.fromList( skinWeight['array'], skinWeight['stride'] ) );

    build['data'] = geometry;
    build['type'] = primitives[ 0 ]['type'];
    build['materialKeys'] = materialKeys;

    return build;
  }

  Map<String, dynamic> buildGeometry(Map<String,dynamic> data ) {
    final Map<String,dynamic> build = {};

    final sources = data['sources'];
    final vertices = data['vertices'];
    final primitives = data['primitives'];

    if ( primitives.isEmpty ) return {};

    // our goal is to create one buffer geometry for a single type of primitives
    // first, we group all primitives by their type

    final groupedPrimitives = groupPrimitives( primitives );
    for ( final type in groupedPrimitives.keys ) {
      final primitiveType = groupedPrimitives[ type ];
      checkUVCoordinates( primitiveType );
      build[ type ] = buildGeometryType( primitiveType, sources, vertices );
    }

    return build;
  }

  getGeometry( id ) {
    return getBuild( library['geometries']![ id ], buildGeometry );
  }

  // kinematics

  Map<String, dynamic> buildKinematicsModel(Map<String,dynamic> data ) {
    if ( data['build'] != null ) return data['build'];
    return data;
  }

  getKinematicsModel( id ) {
    return getBuild( library['kinematicsModels']![ id ], buildKinematicsModel );
  }

  void parseKinematicsTechniqueCommon(XmlElement xml, Map<String, dynamic> data ) {
    for (final child in xml.descendantElements) {
      switch ( child.name.local ) {
        case 'joint':
          data['joints'][ child.getAttribute( 'sid' ) ] = parseKinematicsJoint( child );
          break;
        case 'link':
          data['links'].add( parseKinematicsLink( child ) );
          break;
      }
    }
  }

  void parseKinematicsModel(XmlElement xml ) {
    final Map<String,dynamic> data = {
      'name': xml.getAttribute( 'name' ) ?? '',
      'joints': {},
      'links': []
    };

    for (final child in xml.descendantElements) {
      switch ( child.name.local ) {
        case 'technique_common':
          parseKinematicsTechniqueCommon( child, data );
          break;
      }
    }

    library['kinematicsModels']![ xml.getAttribute( 'id' )! ] = data;
  }

  // physics

  void parsePhysicsTechniqueCommon(XmlElement xml, Map<String, dynamic> data ) {
    for (final child in xml.descendantElements) {
      switch ( child.name.local ) {
        case 'inertia':
          data['inertia'] = parseFloats( child.innerText );
          break;

        case 'mass':
          data['mass'] = parseFloats( child.innerText )[ 0 ];
          break;
      }
    }
  }

  parsePhysicsRigidBody(XmlElement xml, Map<String,dynamic> data ) {
    for (final child in xml.descendantElements) {
      switch ( child.name.local ) {
        case 'technique_common':
          parsePhysicsTechniqueCommon( child, data );
          break;
      }
    }
  }

  void parsePhysicsModel(XmlElement xml ) {
    final Map<String,dynamic> data = {
      'name': xml.getAttribute( 'name' ) ?? '',
      'rigidBodies': <String,dynamic>{}
    };

    for (final child in xml.descendantElements) {
      switch ( child.name.local ) {
        case 'rigid_body':
          data['rigidBodies'][ child.getAttribute( 'name' ) ] = <String,dynamic>{};
          parsePhysicsRigidBody( child, data['rigidBodies'][ child.getAttribute( 'name' ) ] );
          break;
      }
    }

    library['physicsModels']![ xml.getAttribute( 'id' )! ] = data;
  }

  // scene
  Map<String, dynamic> parseKinematicsBindJointAxis(XmlElement xml ) {
    final Map<String, dynamic> data = {
      'target': xml.getAttribute( 'target' )?.split( '/' ).removeLast()
    };

    for (final child in xml.descendantElements) {
      switch ( child.name.local ) {
        case 'axis':
          final param = child.getElement( 'param' );
          data['axis'] = param?.innerText;
          final tmpJointIndex = (data['axis'] as String).split( 'inst_' ).removeLast().split( 'axis' )[ 0 ];
          data['jointIndex'] = tmpJointIndex.substring( 0, tmpJointIndex.length - 1 );
          break;
      }
    }

    return data;
  }

  void parseKinematicsScene(XmlElement xml ) {
    final Map<String, dynamic> data = {
      'bindJointAxis': []
    };

    for (final child in xml.descendantElements) {
      switch ( child.name.local ) {
        case 'bind_joint_axis':
          data['bindJointAxis']!.add( parseKinematicsBindJointAxis( child ) );
          break;
      }
    }

    library['kinematicsScenes']![ parseId( xml.getAttribute( 'url' )! ) ] = data;
  }

  Future<AnimationObject> buildVisualScene(Map<String,dynamic> data) async{
    final group = AnimationObject();
    group.name = data['name'] ?? '';

    final children = data['children'];

    for (final child in children) {
      group.add( await getNode( child['id'] ) );
    }

    return group;
  }

  Map<String, dynamic> buildKinematicsScene(Map<String, dynamic>  data ) {
    if ( data['build'] != null ) return data['build'];
    return data;
  }

  Future<AnimationObject> getVisualScene( id ) async{
    final data = library['visualScenes']![ id ];
    if ( data?['build'] != null ) return data['build'];
    data['build'] = await buildVisualScene( data );

    return data['build'];
  }

  getKinematicsScene( id ) {
    final Map<String, dynamic> data = library['kinematicsScenes']![ id ];
    if ( data['build'] != null ) return data['build'];
    data['build'] = buildKinematicsScene( data );

    return data['build'];
  }

  buildTransformList(XmlElement node ) {
    final transforms = [];
    final elements = collada.xpath( '//node[@id="${node.getAttribute('id')}"]' );
    for (final child in elements) {
      var array, vector;
      switch ( child.parentElement!.name.local ) {
        case 'matrix':
          array = parseFloats( child.innerText );
          final matrix =Matrix4().copyFromArray( array ).transpose();
          transforms.add( {
            'sid': child.getAttribute( 'sid' ),
            'type': child.parentElement!.name.local,
            'obj': matrix
          } );
          break;

        case 'translate':
        case 'scale':
          array = parseFloats( child.innerText );
          vector =Vector3().copyFromArray( array );
          transforms.add( {
            'sid': child.getAttribute( 'sid' ),
            'type': child.parentElement!.name.local,
            'obj': vector
          } );
          break;

        case 'rotate':
          array = parseFloats( child.innerText );
          vector =Vector3().copyFromArray( array );
          final angle = MathUtils.degToRad( array[ 3 ] );
          transforms.add( {
            'sid': child.getAttribute( 'sid' ),
            'type': child.parentElement!.name.local,
            'obj': vector,
            'angle': angle
          } );
          break;
      }
    }

    return transforms;
  }

  Future<void> setupKinematics() async{
    final kinematicsModelId = library['kinematicsModels']?.keys;
    final kinematicsSceneId = library['kinematicsScenes']?.keys;
    final visualSceneId = library['visualScenes']?.keys;
    if ( kinematicsModelId == null || kinematicsModelId.isEmpty || kinematicsSceneId == null || kinematicsSceneId.isEmpty) return;

    final kinematicsModel = getKinematicsModel( kinematicsModelId.toList()[0] );
    final kinematicsScene = getKinematicsScene( kinematicsSceneId.toList()[0] );
    final visualScene = await getVisualScene( visualSceneId!.toList()[0] );

    final bindJointAxis = kinematicsScene['bindJointAxis'];
    final jointMap = {};

    connect( jointIndex, XmlElement visualElement ) {
      final visualElementName = visualElement.getAttribute( 'name' );
      final joint = kinematicsModel['joints'][ jointIndex ];

      visualScene.traverse( ( object ) {
        if ( object.name == visualElementName ) {
          jointMap[ jointIndex ] = {
            'object': object,
            'transforms': buildTransformList( visualElement ),
            'joint': joint,
            'position': joint['zeroPosition']
          };
        }
      } );
    }

    for (int i = 0, l = bindJointAxis.length; i < l; i ++ ) {
      final axis = bindJointAxis[ i ];
      List<XmlNode> targetElement = collada.xpath( '//translate[@sid="${axis['target']}"]' ).toList();
      targetElement += collada.xpath( '//rotate[@sid="${axis['target']}"]' ).toList();
      targetElement += collada.xpath( '//matrix[@sid="${axis['target']}"]' ).toList();
      targetElement += collada.xpath( '//scale[@sid="${axis['target']}"]' ).toList();
      if ( targetElement.isNotEmpty) {
        final parentVisualElement = targetElement[0].parentElement;
        connect( axis['jointIndex'], parentVisualElement! );
      }
    }

    final m0 = Matrix4();
    kinematics = {
      'joints': kinematicsModel['joints'],

      'getJointValue': ( jointIndex ) {
        final jointData = jointMap[ jointIndex ];

        if ( jointData != null) {
          return jointData['position'];
        } else {
          console.warning( 'ColladaLoader: Joint $jointIndex doesn\'t exist.' );
        }
      },

      'setJointValue': ( jointIndex, value ) {
        final jointData = jointMap[ jointIndex ];

        if ( jointData ) {
          final joint = jointData.joint;

          if ( value > joint.limits.max || value < joint.limits.min ) {
            console.warning( 'ColladaLoader: Joint $jointIndex value $value outside of limits (min: ${joint['limits']['min']}, max: ${joint['limits']['max']}).' );
          } 
          else if ( joint.static ) {
            console.warning( 'ColladaLoader: Joint $jointIndex is static.' );
          } 
          else {
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
                    console.warning( 'ColladaLoader: Unknown joint type: ${joint.type}');
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
          console.info( 'ColladaLoader: $jointIndex does not exist.' );
        }
      }
    };
  }

  // nodes

  void prepareNodes(XmlElement xml ) {
    final elements = xml.findAllElements( 'node' );
    // ensure all node elements have id attributes
    for (final element in elements) {
      if ( element.getAttribute( 'id' ) == null) {
        element.setAttribute( 'id', generateId() );
      }
    }
  }

  Map<String, dynamic> parseNodeInstance(XmlElement xml ) {
    final Map<String,dynamic> data = {
      'id': parseId( xml.getAttribute( 'url' )! ),
      'materials': {},
      'skeletons': []
    };

    for (final child in xml.descendantElements) {
      switch ( child.name.local ) {
        case 'bind_material':
          final instances = child.findAllElements( 'instance_material' );
          for (final instance in instances) {
            final symbol = instance.getAttribute( 'symbol' );
            final target = instance.getAttribute( 'target' );

            data['materials'][ symbol ] = parseId( target! );
          }
          break;
        case 'skeleton':
          data['skeletons'].add( parseId( child.innerText ) );
          break;
        default:
          break;
      }
    }

    return data;
  }

  Map<String, dynamic> parseNode(XmlElement xml ) {
    final Map<String,dynamic> data = {
      'name': xml.getAttribute( 'name' ) ?? '',
      'type': xml.getAttribute( 'type' ),
      'id': xml.getAttribute( 'id' ),
      'sid': xml.getAttribute( 'sid' ),
      'matrix':Matrix4(),
      'nodes': [],
      'instanceCameras': [],
      'instanceControllers': [],
      'instanceLights': [],
      'instanceGeometries': [],
      'instanceNodes': [],
      'transforms': {}
    };

    for (final child in xml.descendantElements) {
      var array;
      switch ( child.name.local ) {
        case 'node':
          data['nodes'].add( child.getAttribute( 'id' ) );
          //parseNode( child );
          break;
        case 'instance_camera':
          data['instanceCameras'].add( parseId( child.getAttribute( 'url' )! ) );
          break;
        case 'instance_controller':
          data['instanceControllers'].add( parseNodeInstance( child ) );
          break;
        case 'instance_light':
          data['instanceLights'].add( parseId( child.getAttribute( 'url' )! ) );
          break;
        case 'instance_geometry':
          data['instanceGeometries'].add( parseNodeInstance( child ) );
          break;
        case 'instance_node':
          data['instanceNodes'].add( parseId( child.getAttribute( 'url' )! ) );
          break;
        case 'matrix':
          array = parseFloats( child.innerText );
          data['matrix'].multiply( matrix.copyFromArray( array ).transpose() );
          data['transforms'][ child.getAttribute( 'sid' ) ] = child.name.local;
          break;
        case 'translate':
          array = parseFloats( child.innerText );
          vector.copyFromArray( array );
          data['matrix'].multiply( matrix.makeTranslation( vector.x, vector.y, vector.z ) );
          data['transforms'][ child.getAttribute( 'sid' ) ] = child.name.local;
          break;
        case 'rotate':
          array = parseFloats( child.innerText );
          final angle = MathUtils.degToRad( array[ 3 ] );
          data['matrix'].multiply( matrix.makeRotationAxis( vector.copyFromArray( array ), angle ) );
          data['transforms'][ child.getAttribute( 'sid' ) ] = child.name.local;
          break;
        case 'scale':
          array = parseFloats( child.innerText );
          (data['matrix'] as Matrix4).scaleByVector( vector.copyFromArray( array ) );
          data['transforms'][ child.getAttribute( 'sid' ) ] = child.name.local;
          break;
        case 'extra':
          break;
        default:
          console.info( child.name.local );
      }
    }

    if ( hasNode( data['id'] ) ) {
      console.warning( 'ColladaLoader: There is already a node with ID ${data['id']}. Exclude current node from further processing.');
    } 
    else {
      library['nodes']![ data['id'] ] = data;
    }

    return data;
  }

  void buildBoneHierarchy(Object3D root, joints, List<Map<String,dynamic>> boneData ) {
    // setup bone data from visual scene
    root.traverse( ( object ) {
      if ( object is Bone) {
        Matrix4? boneInverse;
        // retrieve the boneInverse from the controller data

        for (final joint in joints) {
          if ( joint['name'] == object.name ) {
            boneInverse = joint['boneInverse'];
            break;
          }
        }

        boneInverse ??= Matrix4();
        boneData.add({'bone': object, 'boneInverse': boneInverse, 'processed': false } );
      }
    });
  }

  Future<Skeleton> buildSkeleton( skeletons, joints ) async{
    final List<Map<String, dynamic>> boneData = [];
    final sortedBoneData = [];

    // a skeleton can have multiple root bones. collada expresses this
    // situtation with multiple "skeleton" tags per controller instance

    for (final skeleton in skeletons) {
      if ( hasNode( skeleton ) ) {
        final root = await getNode( skeleton );
        buildBoneHierarchy( root, joints, boneData );
      } 
      else if ( hasVisualScene( skeleton ) ) {
        final visualScene = library['visualScenes']![ skeleton ];
        final children = visualScene.children;

        for (int j = 0; j < children.length; j ++ ) {
          final child = children[ j ];
          if ( child.type == 'JOINT' ) {
            final root = await getNode( child.id );
            buildBoneHierarchy( root, joints, boneData );
          }
        }
      } 
      else {
        console.error( 'ColladaLoader: Unable to find root bone of skeleton with ID: $skeleton');
      }
    }

    // sort bone data (the order is defined in the corresponding controller)

    for (final joint in joints) {
      for (int j = 0; j < boneData.length; j ++ ) {
        final data = boneData[ j ];
        if ( data['bone'].name == joint['name'] ) {
          sortedBoneData.add(data);
          data['processed'] = true;
          break;
        }
      }
    }

    // add unprocessed bone data at the end of the list

    for (int i = 0; i < boneData.length; i ++ ) {
      final data = boneData[ i ];
      if ( data['processed'] == false ) {
        sortedBoneData.add( data );
        data['processed'] = true;
      }
    }

    // setup arrays for skeleton creation

    final List<Bone> bones = [];
    final List<Matrix4> boneInverses = [];

    for (int i = 0; i < sortedBoneData.length; i ++ ) {
      final data = sortedBoneData[ i ];
      bones.add( data['bone'] );
      boneInverses.add( data['boneInverse'] );
    }

    return Skeleton( bones, boneInverses );
  }

  Future<Object3D?> buildNode(Map<String,dynamic> data ) async {
    final objects = [];

    final matrix = data['matrix'];
    final nodes = data['nodes'];
    final type = data['type'];
    final instanceCameras = data['instanceCameras'];
    final instanceControllers = data['instanceControllers'];
    final instanceLights = data['instanceLights'];
    final instanceGeometries = data['instanceGeometries'];
    final instanceNodes = data['instanceNodes'];

    // nodes

    for (final node in nodes) {
      objects.add(await getBuild( library['nodes']![ node ], buildNode ));
    }

    // instance cameras

    for (int i = 0, l = instanceCameras.length; i < l; i ++ ) {
      final instanceCamera = await getCamera( instanceCameras[ i ] );
      if ( instanceCamera != null ) {
        objects.add( instanceCamera.clone() );
      }
    }

    // instance controllers

    for (int i = 0, l = instanceControllers.length; i < l; i ++ ) {
      final instance = instanceControllers[ i ];
      final controller = await getController( instance['id'] );
      final geometries = await getGeometry( controller['id'] );
      final newObjects = await buildObjects( geometries, instance['materials'] );

      final skeletons = instance['skeletons'];
      final joints = controller['skin']['joints'];

      final skeleton = await buildSkeleton( skeletons, joints );

      for (int j = 0, jl = newObjects.length; j < jl; j ++ ) {
        final object = newObjects[ j ];

        if (object is SkinnedMesh) {
          object.bind( skeleton, controller['skin']['bindMatrix'] );
          object.normalizeSkinWeights();
        }

        objects.add( object );
      }
    }

    // instance lights

    for (int i = 0, l = instanceLights.length; i < l; i ++ ) {
      final instanceLight = getLight( instanceLights[ i ] );

      if ( instanceLight != null ) {
        objects.add( instanceLight.clone() );
      }
    }

    // instance geometries

    for (int i = 0, l = instanceGeometries.length; i < l; i ++ ) {
      final instance = instanceGeometries[ i ];
      final geometries = await getGeometry( instance['id'] );
      final newObjects = await buildObjects( geometries, instance['materials'] );

      for (int j = 0, jl = newObjects.length; j < jl; j ++ ) {
        objects.add( newObjects[ j ] );
      }
    }

    // instance nodes

    for (int i = 0, l = instanceNodes.length; i < l; i ++ ) {
      objects.add( (await getNode( instanceNodes[ i ] )).clone() );
    }

    Object3D? object;

    if ( nodes.length == 0 && objects.length == 1 ) {
      object = objects[ 0 ];
    } 
    else {
      object = ( type == 'JOINT' ) ?Bone() :Group();
      for (int i = 0; i < objects.length; i ++ ) {
        object.add( objects[ i ] );
      }
    }

    object?.name = ( type == 'JOINT' ) ? data['sid'] : data['name'];
    object?.matrix.setFrom( matrix );
    object?.matrix.decompose( object.position, object.quaternion, object.scale );

    return object;
  }

  void parseVisualScene(XmlElement xml ) {
    final Map<String,dynamic> data = {
      'name': xml.getAttribute( 'name' ),
      'children': []
    };

    prepareNodes(xml);

    final elements = xml.findAllElements('node' );
    for (final element in elements) {
      data['children'].add( parseNode( element) );
    }
    library['visualScenes']![ xml.getAttribute( 'id' )! ] = data;
  }

  // scenes

  Future<AnimationObject> parseScene(XmlElement xml ) async{
    final instance = xml.getElement('instance_visual_scene' );
    return await getVisualScene( parseId( instance!.getAttribute( 'url' )! ) );
  }

  Future<void> setupAnimations() async{
    final clips = library['clips'];

    if (isEmpty( clips )) {
      if (!isEmpty(library['animations'])) {

        // if there are animations but no clips, we create a default clip for playback

        final List<KeyframeTrack> tracks = [];

        for ( final id in library['animations']!.keys) {
          final animationTracks = await getAnimation( id );
          for (int i = 0, l = animationTracks?.length ?? 0; i < l; i ++ ) {
            tracks.add( animationTracks[ i ] );
          }
        }

        animations.add(AnimationClip( 'default', - 1, tracks ) );
      }
    } 
    else {
      for ( final id in clips!.keys ) {
        animations.add( getAnimationClip( id ) );
      }
    }
  }

  Map<String, dynamic> parseSource(XmlElement xml ) {
    final Map<String,dynamic> data = {
      'array': [],
      'stride': 3
    };

    for (final child in xml.descendantElements) {
      switch ( child.name.local ) {
        case 'float_array':
          data['array'] = parseFloats( child.innerText );
          break;
        case 'Name_array':
          data['array'] = parseStrings( child.innerText );
          break;
        case 'technique_common':
          final accessor = child.getElement('accessor' );
          if ( accessor != null ) {
            data['stride'] = int.parse( accessor.getAttribute( 'stride' )! );
          }
          break;
      }
    }

    return data;
  }

  List<String> parseStrings(String text ) {
    if ( text.isEmpty ) return [];
    final parts = text.trim().split(' ');
    final array = List.filled(parts.length, '');

    for (int i = 0, l = parts.length; i < l; i ++ ) {
      array[i] = parts[i];
    }

    return array;
  }

  List<double> parseFloats(String text ) {
    if(text.isEmpty) return [];
    final parts = text.trim().split(' ');
    final array = List.filled(parts.length, 0.0);

    for (int i = 0, l = parts.length; i < l; i ++ ) {
      array[ i ] = double.parse( parts[ i ] );
    }

    return array;
  }

  List<int> parseInts(String text ) {
    if ( text.isEmpty) return [];
    final parts = text.trim().split(' ');
    final array = List.filled(parts.length, 0);

    for (int i = 0, l = parts.length; i < l; i ++ ) {
      array[i] = int.parse( parts[ i ] );
    }

    return array;
  }

  String parseId(String text ) {
    return text.substring( 1 );
  }

  String generateId() {
    return 'three_default_${count++}';
  }

  bool isEmpty(Map? object ) {
    if(object == null) return true;
    return object.keys.isEmpty;
  }

  double parseAssetUnit(XmlElement? xml ) {
    if ( xml != null  && xml.getAttribute( 'meter' ) != null ) {
      return double.parse( xml.getAttribute( 'meter' )!);
    } else {
      return 1; // default 1 meter
    }
  }

  String parseAssetUpAxis(XmlElement? xml ) {
    return xml?.innerText != null ? xml!.innerText : 'Y_UP';
  }

  Map<String,dynamic> parseAsset(XmlElement xml ) {
    return {
      'unit': parseAssetUnit( xml.getElement('unit')),//getElementsByTagName( xml, 'unit' )[ 0 ] ),
      'upAxis': parseAssetUpAxis( xml.getElement('up_axis')),//getElementsByTagName( xml, 'up_axis' )[ 0 ] )
    };
  }

  Map<String,dynamic> parseAnimationSampler(XmlElement xml ) {
    final Map<String,dynamic> data = {
      'inputs': {},
    };

    for (final child in xml.descendantElements) {
      switch (child.name.local) {
        case 'input':
          final id = parseId( child.getAttribute( 'source' )!);
          final semantic = child.getAttribute( 'semantic' );
          data['inputs']![semantic] = id;
          break;
      }
    }

    return data;
  }

  Map<String,dynamic> parseAnimationChannel(XmlElement xml ) {
    final Map<String,dynamic> data = {};
    final String target = xml.getAttribute( 'target' )!;
    List<String> parts = target.split( '/' );

    final id = parts.removeAt(0);
    String sid = parts.removeAt(0);

    // check selection syntax

    final arraySyntax = sid.contains( '(' );
    final memberSyntax = sid.contains( '.' );

    if ( memberSyntax ) {
      parts = sid.split( '.' );
      sid = parts.removeAt(0);
      data['member'] = parts.removeAt(0);
    } else if ( arraySyntax ) {
      // array-access syntax. can be used to express fields in one-dimensional vectors or two-dimensional matrices.

      final indiceStrings = sid.split( '(' );
      final indices = [];
      sid = indiceStrings.removeAt(0);

      for (int i = 0; i < indices.length; i ++ ) {
        indices[ i ] = int.parse( indiceStrings[ i ].replaceAll(')', '' ));
      }

      data['indices'] = indices;
    }

    data['id'] = id;
    data['sid'] = sid;

    data['arraySyntax'] = arraySyntax;
    data['memberSyntax'] = memberSyntax;

    data['sampler'] = parseId( xml.getAttribute( 'source' )! );

    return data;
  }

  ColladaKeyFrame? getPrev(List<ColladaKeyFrame> keyframes, int i, property ) {
    while ( i >= 0 ) {
      final keyframe = keyframes[ i ];
      if ( keyframe.value[ property ] != null ) return keyframe;
      i--;
    }
    return null;
  }

  ColladaKeyFrame? getNext(List<ColladaKeyFrame> keyframes, int i, property ) {
    while ( i < keyframes.length ) {
      final keyframe = keyframes[ i ];
      if ( keyframe.value[ property ] != null ) return keyframe;
      i++;
    }
    return null;
  }

  void interpolate(ColladaKeyFrame key, ColladaKeyFrame prev, ColladaKeyFrame next, property ) {
    if ( ( next.time - prev.time ) == 0 ) {
      key.value[ property ] = prev.value[ property ];
      return;
    }
    key.value[ property ] = ( ( key.time - prev.time ) * ( next.value[ property ] - prev.value[ property ] ) / ( next.time - prev.time ) ) + prev.value[ property ];
  }

  getBuild(Map<String, dynamic> data, builder ) {
    if ( data['build'] != null ) return data['build'];
    data['build'] = builder( data );

    return data['build'];
  }

  Map<String,dynamic> parseJoints(XmlElement xml ) {
    final Map<String,dynamic> data = {
      'inputs': <String,dynamic>{}
    };

    for (final child in xml.descendantElements){
      switch ( child.name.local ) {
        case 'input':
          final semantic = child.getAttribute( 'semantic' );
          final id = parseId( child.getAttribute( 'source' )! );
          data['inputs']![ semantic ] = id;
          break;
      }
    }
    return data;
  }

  Map<String,dynamic> parseSkin(XmlElement xml ) {
    final Map<String,dynamic> data = {
      'sources': {}
    };

    for (final child in xml.descendantElements) {
      
      switch ( child.name.local ) {
        case 'bind_shape_matrix':
          data['bindShapeMatrix'] = parseFloats( child.innerText );
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

  Map<String,dynamic> parseVertexWeights(XmlElement xml ) {
    final Map<String,dynamic> data = {
      'inputs': {}
    };

    for (final child in xml.descendantElements) {
      switch ( child.name.local ) {
        case 'input':
          final semantic = child.getAttribute( 'semantic' );
          final id = parseId( child.getAttribute( 'source' )! );
          final offset = int.parse( child.getAttribute( 'offset' )! );
          data['inputs'][ semantic ] = { 'id': id, 'offset': offset };
          break;
        case 'vcount':
          data['vcount'] = parseInts( child.innerText );
          break;
        case 'v':
          data['v'] = parseInts( child.innerText );
          break;
      }
    }

    return data;
  }

  Map<String,dynamic> parseEffectParameter(XmlElement xml ) {
    final Map<String,dynamic> data = {};

    for (final child in xml.descendantElements) {
      switch ( child.name.local ) {
        case 'color':
          data[ child.name.local ] = parseFloats( child.innerText );
          break;
        case 'float':
          data[ child.name.local ] = double.tryParse( child.innerText);
          break;
        case 'texture':
          data[ child.name.local ] = { 'id': child.getAttribute( 'texture' ), 'extra': parseEffectParameterTexture( child ) };
          break;
      }
    }

    return data;
  }
  
  Map<String,dynamic> parseEffectParameters(XmlElement xml ) {
    final Map<String,dynamic> data = {};

    for (final child in xml.descendantElements) {
      switch ( child.name.local ) {
        case 'emission':
        case 'diffuse':
        case 'specular':
        case 'bump':
        case 'ambient':
        case 'shininess':
        case 'transparency':
          data[ child.name.local ] = parseEffectParameter( child );
          break;
        case 'transparent':
          data[ child.name.local ] = {
            'opaque': child.getAttribute( 'opaque' ) ?? 'A_ONE',
            'data': parseEffectParameter( child )
          };
          break;
      }
    }

    return data;
  }

  Map<String,dynamic> parseEffectParameterTexture(XmlElement xml ) {
    final Map<String,dynamic> data = {
      'technique': {}
    };

    for (final child in xml.descendantElements) {
      switch ( child.name.local ) {
        case 'extra':
          parseEffectParameterTextureExtra( child, data );
          break;
      }
    }

    return data;
  }

  void parseEffectParameterTextureExtra(XmlElement xml, data ) {
    for (final child in xml.descendantElements) {
      switch ( child.name.local ) {
        case 'technique':
          parseEffectParameterTextureExtraTechnique( child, data );
          break;
      }
    }
  }

  void parseEffectParameterTextureExtraTechnique(XmlElement xml, data ) {
    for (final child in xml.descendantElements) {
      switch ( child.name.local ) {
        case 'repeatU':
        case 'repeatV':
        case 'offsetU':
        case 'offsetV':
          data['technique'][ child.name.local ] = double.parse( child.innerText );
          break;

        case 'wrapU':
        case 'wrapV':
          // some files have values for wrapU/wrapV which become NaN via int.parse

          if ( child.innerText.toUpperCase() == 'TRUE' ) {
            data['technique'][ child.name.local ] = 1;
          } else if ( child.innerText.toUpperCase() == 'FALSE' ) {
            data['technique'][ child.name.local ] = 0;
          } else {
            data['technique'][ child.name.local ] = int.parse( child.innerText);
          }
          break;

        case 'bump':
          data[ child.name.local ] = parseEffectExtraTechniqueBump( child );
          break;
      }
    }
  }

  Map<String,dynamic> parseEffectExtra(XmlElement xml ) {
    final Map<String,dynamic> data = {};

    for (final child in xml.descendantElements) {
      switch ( child.name.local ) {
        case 'technique':
          data['technique'] = parseEffectExtraTechnique( child );
          break;
      }
    }

    return data;
  }

  Map<String,dynamic> parseEffectExtraTechnique(XmlElement xml ) {
    final Map<String,dynamic> data = {};

    for (final child in xml.descendantElements) {
      switch ( child.name.local ) {
        case 'double_sided':
          data[ child.name.local ] = int.parse( child.innerText );
          break;
        case 'bump':
          data[ child.name.local ] = parseEffectExtraTechniqueBump( child );
          break;
      }
    }

    return data;
  }

  Map<String,dynamic> parseEffectExtraTechniqueBump(XmlElement xml ) {
    final Map<String,dynamic> data = {};

    for (final child in xml.descendantElements) {
      switch ( child.name.local ) {
        case 'texture':
          data[ child.name.local ] = { 'id': child.getAttribute( 'texture' ), 'texcoord': child.getAttribute( 'texcoord' ), 'extra': parseEffectParameterTexture( child ) };
          break;
      }
    }

    return data;
  }

  Map<String, dynamic> buildSkin(Map<String, dynamic> data ) {
    int descending( a, b ) {
      return (b['weight'] - a['weight']).toInt();
    }

    const BONE_LIMIT = 4;

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

    final sources = data['sources'];
    final Map<String, dynamic> vertexWeights = data['vertexWeights'];

    final vcount = vertexWeights['vcount'];
    final v = vertexWeights['v'];
    final jointOffset = vertexWeights['inputs']['JOINT']['offset'];
    final weightOffset = vertexWeights['inputs']['WEIGHT']['offset'];

    final jointSource = data['sources'][ data['joints']['inputs']['JOINT'] ];
    final inverseSource = data['sources'][ data['joints']['inputs']['INV_BIND_MATRIX'] ];
    final weights = sources[ vertexWeights['inputs']['WEIGHT']['id'] ]['array'];
    var stride = 0;

    // process skin data for each vertex

    for (int i = 0, l = vcount.length; i < l; i ++ ) {
      final jointCount = vcount[ i ]; // this is the amount of joints that affect a single vertex
      final vertexSkinData = [];

      for (int j = 0; j < jointCount; j ++ ) {
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

      for (int j = 0; j < BONE_LIMIT; j ++ ) {
        final d = vertexSkinData.length > j ? vertexSkinData[ j ]:null;

        if ( d != null ) {
          build['indices']['array'].add( d['index'] );
          build['weights']['array'].add( d['weight'] );
        } 
        else {
          build['indices']['array'].add( 0 );
          build['weights']['array'].add( 0 );
        }
      }
    }

    // setup bind matrix

    if ( data['bindShapeMatrix'] != null) {
      build['bindMatrix'] = Matrix4().copyFromArray( data['bindShapeMatrix'] ).transpose();
    } 
    else {
      build['bindMatrix'] = Matrix4().identity();
    }

    // process bones and inverse bind matrix data

    for (int i = 0, l = jointSource['array'].length; i < l; i ++ ) {
      final name = jointSource['array'][ i ];
      final boneInverse = Matrix4().copyFromArray( inverseSource['array'], (i * inverseSource['stride']).toInt() ).transpose();
      build['joints'].add( { 'name': name, 'boneInverse': boneInverse } );
    }

    return build;
  }

  Map<String,dynamic> parseKinematicsAttachment(XmlElement xml ) {
    final Map<String,dynamic> data = {
      'joint': xml.getAttribute( 'joint' )?.split( '/' ).removeLast(),
      'transforms': [],
      'links': []
    };

    for (final child in xml.descendantElements) {
      switch ( child.name.local ) {
        case 'link':
          data['links'].add( parseKinematicsLink( child ) );
          break;
        case 'matrix':
        case 'translate':
        case 'rotate':
          data['transforms'].add( parseKinematicsTransform( child ) );
          break;
      }
    }
    return data;
  }

  Map<String,dynamic> parseKinematicsLink(XmlElement xml ) {
    final Map<String,dynamic> data = {
      'sid': xml.getAttribute( 'sid' ),
      'name': xml.getAttribute( 'name' ) ?? '',
      'attachments': [],
      'transforms': []
    };

    for (final child in xml.descendantElements) {
      switch ( child.name.local ) {
        case 'attachment_full':
          data['attachments'].add( parseKinematicsAttachment( child ) );
          break;
        case 'matrix':
        case 'translate':
        case 'rotate':
          data['transforms'].add( parseKinematicsTransform( child ) );
          break;
      }
    }

    return data;
  }

  Map<String,dynamic>? parseKinematicsJoint(XmlElement xml ) {
    Map<String,dynamic>? data;

    for (final child in xml.descendantElements) {
      switch ( child.name.local ) {
        case 'prismatic':
        case 'revolute':
          data = parseKinematicsJointParameter( child );
          break;
      }
    }

    return data;
  }

  Map<String,dynamic> parseKinematicsJointParameter(XmlElement xml ) {

    final Map<String,dynamic> data = {
      'sid': xml.getAttribute( 'sid' ),
      'name': xml.getAttribute( 'name' ) ?? '',
      'axis':Vector3(),
      'limits': {
        'min': 0.0,
        'max': 0.0
      },
      'type': xml.name.local,
      'static': false,
      'zeroPosition': 0,
      'middlePosition': 0
    };

    for (final child in xml.descendantElements) {
      switch ( child.name.local ) {
        case 'axis':
          final array = parseFloats( child.innerText );
          data['axis'].copyFromArray( array );
          break;
        case 'limits':
          final max = child.getElement( 'max' )!;
          final min = child.getElement( 'min' )!;

          data['limits']['max'] = double.parse( max.innerText );
          data['limits']['min'] = double.parse( min.innerText );
          break;
      }
    }

    if ( data['limits']['min'] >= data['limits']['max'] ) {
      data['static'] = true;
    }

    data['middlePosition'] = ( data['limits']['min'] + data['limits']['max'] ) / 2.0;

    return data;
  }

  Map<String,dynamic> parseKinematicsTransform(XmlElement xml ) {
    final Map<String,dynamic> data = {
      'type': xml.name.local
    };

    final array = parseFloats( xml.innerText );

    switch (data['type']) {

      case 'matrix':
        data['obj'] =Matrix4();
        data['obj'].copyFromArray( array ).transpose();
        break;
      case 'translate':
        data['obj'] =Vector3();
        data['obj'].copyFromArray( array );
        break;
      case 'rotate':
        data['obj'] =Vector3();
        data['obj'].copyFromArray( array );
        data['angle'] = MathUtils.degToRad( array[ 3 ] );
        break;
    }
    return data;
  }

  List<KeyframeTrack> createKeyframeTracks(Map<String,dynamic> animation, List<KeyframeTrack> tracks ) {
    final keyframes = animation['keyframes'];
    final name = animation['name'];

    final List<num> times = [];
    final List<num> positionData = [];
    final List<num> quaternionData = [];
    final List<num> scaleData = [];

    for (int i = 0, l = keyframes.length; i < l; i ++ ) {
      final ColladaKeyFrame keyframe = keyframes[ i ];
      final time = keyframe.time;
      final value = keyframe.value;

      matrix.copyFromArray(  List<double>.from(value.values.toList())).transpose();
      matrix.decompose( position, quaternion, scale );

      times.add( time );
      positionData.addAll([ position.x, position.y, position.z ]);
      quaternionData.addAll([ quaternion.x, quaternion.y, quaternion.z, quaternion.w ]);
      scaleData.addAll([ scale.x, scale.y, scale.z ]);
    }

    if ( positionData.isNotEmpty) tracks.add(VectorKeyframeTrack( name + '.position', times, positionData ) );
    if ( quaternionData.isNotEmpty) tracks.add(QuaternionKeyframeTrack( name + '.quaternion', times, quaternionData ) );
    if ( scaleData.isNotEmpty) tracks.add(VectorKeyframeTrack( name + '.scale', times, scaleData ) );

    return tracks;
  }
}
