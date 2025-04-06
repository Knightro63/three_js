import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as math;

import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';
import 'package:three_js_animations/three_js_animations.dart';
import 'package:three_js_core_loaders/three_js_core_loaders.dart';

class BVHObject{
  AnimationClip? clip;
  Skeleton? skeleton;

  BVHObject({
  	this.skeleton,
		this.clip
  });
}

///
/// Loader loads FBX file and generates Group representing FBX scene.
/// Requires FBX file to be >= 7.0 and in ASCII or >= 6400 in Binary format
/// Versions lower than this may load but will probably have errors
///
/// Needs Support:
///  Morph normals / blend shape normals
///
/// FBX format references:
/// 	https://help.autodesk.com/view/FBX/2017/ENU/?guid=__cpp_ref_index_html (C++ SDK reference)
///
/// Binary format specification:
///	https://code.blender.org/2013/08/fbx-binary-file-format-specification/
///
class BVHLoader extends Loader {
	bool animateBonePositions = true;
  bool animateBoneRotations = true;
  late final FileLoader _loader;

  /// [manager] — The [loadingManager] for the loader to use. Default is [DefaultLoadingManager].
  /// 
  /// Creates a [BVHLoader].
  BVHLoader({LoadingManager? manager, this.animateBonePositions = true, this.animateBoneRotations= true}):super(manager){
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
  Future<BVHObject?> fromNetwork(Uri uri) async{
    _init();
    ThreeFile? tf = await _loader.fromNetwork(uri);
    return tf == null?null:_parse(tf.data);
  }
  @override
  Future<BVHObject?> fromFile(File file) async{
    _init();
    ThreeFile tf = await _loader.fromFile(file);
    return _parse(tf.data);
  }
  @override
  Future<BVHObject?> fromPath(String filePath) async{
    _init();
    ThreeFile? tf = await _loader.fromPath(filePath);
    return tf == null?null:_parse(tf.data);
  }
  @override
  Future<BVHObject?> fromBlob(Blob blob) async{
    _init();
    ThreeFile tf = await _loader.fromBlob(blob);
    return _parse(tf.data);
  }
  @override
  Future<BVHObject?> fromAsset(String asset, {String? package}) async{
    _init();
    ThreeFile? tf = await _loader.fromAsset(asset,package: package);
    return tf == null?null:_parse(tf.data);
  }
  @override
  Future<BVHObject?> fromBytes(Uint8List bytes) async{
    _init();
    ThreeFile tf = await _loader.fromBytes(bytes);
    return _parse(tf.data);
  }

  Future<BVHObject> _parse(Uint8List bufferBytes) {
    return __BVHParser(String.fromCharCodes(bufferBytes), manager, animateBoneRotations, animateBoneRotations).parse();
  }

  @override
  BVHLoader setPath(String path) {
    super.setPath(path);
    return this;
  }
}

class __BVHParser {
  String text;
  LoadingManager manager;
	bool animateBonePositions = true;
  bool animateBoneRotations = true;

  __BVHParser(this.text,this.manager,this.animateBonePositions,this.animateBoneRotations);

  Future<BVHObject> parse() async {
		final lines = text.split(RegExp("[\r\n]+"));
		final bones = readBvh( lines );
		final List<Bone> threeBones = [];
		toTHREEBone( bones[ 0 ], threeBones );
		final threeClip = toTHREEAnimation( bones );

		return BVHObject(
			skeleton: Skeleton( threeBones ),
			clip: threeClip
    );
  }

  /*
    reads a string array (lines) from a BVH file
    and outputs a skeleton structure including motion data

    returns thee root node:
    { name: '', channels: [], children: [] }
  */
  List<Map<String,dynamic>> readBvh(List<String> lines ) {
    if ( nextLine( lines ) != 'HIERARCHY' ) {
      console.error( 'THREE.BVHLoader: HIERARCHY expected.' );
    }

    final List<Map<String,dynamic>> list = []; // collects flat array of all bones
    final root = readNode( lines, nextLine( lines ), list );

    // read motion data

    if ( nextLine( lines ) != 'MOTION' ) {
      console.error( 'THREE.BVHLoader: MOTION expected.' );
    }

    // number of frames

    List<String> tokens = nextLine( lines ).split(RegExp(r"[\s]+"));
    final numFrames = int.parse( tokens[ 1 ] );

    if ( numFrames.isNaN ) {
      console.error( 'THREE.BVHLoader: Failed to read number of frames.' );
    }

    // frame time

    tokens = nextLine( lines ).split(RegExp(r"[\s]+"));
    final frameTime = double.parse( tokens[ 2 ] );

    if (frameTime.isNaN) {
      console.error( 'THREE.BVHLoader: Failed to read frame time.' );
    }

    // read frame data line by line

    for (int i = 0; i < numFrames; i ++ ) {
      tokens = nextLine( lines ).split(RegExp(r"[\s]+"));
      readFrameData( tokens, i * frameTime, root );
    }

    return list;
  }

  /*
    Recursively reads data from a single frame into the bone hierarchy.
    The passed bone hierarchy has to be structured in the same order as the BVH file.
    keyframe data is stored in bone.frames.

    - data: splitted string array (frame values), values are removeAt(0)ed so
    this should be empty after parsing the whole hierarchy.
    - frameTime: playback time for this keyframe.
    - bone: the bone to read frame data from.
  */
  void readFrameData(List<String> data, double frameTime, Map<String,dynamic> bone ) {
    // end sites have no motion data

    if ( bone['type'] == 'ENDSITE' ) return;

    // add keyframe

    final Map<String,dynamic> keyframe = {
      'time': frameTime,
      'position': Vector3(),
      'rotation': Quaternion()
    };

    bone['frames'].add( keyframe );

    final quat = Quaternion();

    final vx = Vector3( 1, 0, 0 );
    final vy = Vector3( 0, 1, 0 );
    final vz = Vector3( 0, 0, 1 );

    // parse values for each channel in node

    for ( int i = 0; i < bone['channels'].length; i ++ ) {
      switch ( bone['channels'][ i ] ) {
        case 'Xposition':
          keyframe['position'].x = double.parse( data.removeAt(0).trim() );
          break;
        case 'Yposition':
          keyframe['position'].y = double.parse( data.removeAt(0).trim() );
          break;
        case 'Zposition':
          keyframe['position'].z = double.parse( data.removeAt(0).trim() );
          break;
        case 'Xrotation':
          quat.setFromAxisAngle( vx, double.parse( data.removeAt(0).trim() ) * math.pi / 180 );
          keyframe['rotation'].multiply( quat );
          break;
        case 'Yrotation':
          quat.setFromAxisAngle( vy, double.parse( data.removeAt(0).trim() ) * math.pi / 180 );
          (keyframe['rotation'] as Quaternion).multiply( quat );
          break;
        case 'Zrotation':
          quat.setFromAxisAngle( vz, double.parse( data.removeAt(0).trim() ) * math.pi / 180 );
          keyframe['rotation'].multiply( quat );
          break;
        default:
          console.warning( 'THREE.BVHLoader: Invalid channel type.' );
      }
    }

    // parse child nodes

    for (int i = 0; i < bone['children'].length; i ++ ) {
      readFrameData( data, frameTime, bone['children'][ i ] );
    }
  }

		/*
		 Recursively parses the HIERARCHY section of the BVH file

		 - lines: all lines of the file. lines are consumed as we go along.
		 - firstline: line containing the node type and name e.g. 'JOINT hip'
		 - list: collects a flat list of nodes

		 returns: a BVH node including children
		*/
		readNode(List<String> lines, String firstline, List<Map<String,dynamic>> list ) {
			final Map<String,dynamic> node = { 'name': '', 'type': '', 'frames': [] };
			list.add( node );

			// parse node type and name

			List<String> tokens = firstline.split(RegExp(r"[\s]+"));
    
			if ( tokens[ 0 ].toUpperCase() == 'END' && tokens[ 1 ].toUpperCase() == 'SITE' ) {
				node['type'] = 'ENDSITE';
				node['name'] = 'ENDSITE'; // bvh end sites have no name
			} else {
				node['name'] = tokens.length > 1? tokens[ 1 ]:'';
				node['type'] = tokens[ 0 ].toUpperCase();
			}

			if ( nextLine( lines ) != '{' ) {
				console.error( 'THREE.BVHLoader: Expected opening { after type & name' );
			}

			// parse OFFSET

			tokens = nextLine( lines ).split(RegExp(r"[\s]+"));

			if ( tokens[ 0 ] != 'OFFSET' ) {
				console.error( 'THREE.BVHLoader: Expected OFFSET but got: ' + tokens[ 0 ] );
			}

			if ( tokens.length != 4 ) {
				console.error( 'THREE.BVHLoader: Invalid number of values for OFFSET.' );
			}

			final offset = Vector3(
				double.parse( tokens[ 1 ] ),
				double.parse( tokens[ 2 ] ),
				double.parse( tokens[ 3 ] )
			);

			if ( offset.x.isNaN || offset.y.isNaN || offset.z.isNaN ) {
				console.error( 'THREE.BVHLoader: Invalid values of OFFSET.' );
			}

			node['offset'] = offset;

			// parse CHANNELS definitions

			if ( node['type'] != 'ENDSITE' ) {
				tokens = nextLine( lines ).split(RegExp(r"[\s]+"));

				if ( tokens[ 0 ] != 'CHANNELS' ) {
					console.error( 'THREE.BVHLoader: Expected CHANNELS definition.' );
				}

				final numChannels = int.parse( tokens[ 1 ] );
				node['channels'] = tokens..sublist(2, numChannels);
				node['children'] = [];
			}

			// read children

			while ( true ) {
				final line = nextLine( lines );
				if ( line == '}' ) {
					return node;
				} else {
					node['children']?.add( readNode( lines, line, list ) );
				}
			}
		}

  /*
    recursively converts the internal bvh node structure to a Bone hierarchy

    source: the bvh root node
    list: pass an empty array, collects a flat list of all converted THREE.Bones

    returns the root Bone
  */
  Bone toTHREEBone(Map<String,dynamic> source, list ) {
    final bone = Bone();
    list.add( bone );

    bone.position.add( source['offset'] );
    bone.name = source['name'];

    if ( source['type'] != 'ENDSITE' ) {
      for (int i = 0; i < source['children'].length; i ++ ) {
        bone.add( toTHREEBone( source['children'][ i ], list ) );
      }
    }

    return bone;
  }

  /*
    builds a AnimationClip from the keyframe data saved in each bone.

    bone: bvh root node

    returns: a AnimationClip containing position and quaternion tracks
  */
  AnimationClip toTHREEAnimation(List<Map<String,dynamic>> bones ) {
    final List<KeyframeTrack> tracks = [];

    // create a position and quaternion animation track for each node

    for (int i = 0; i < bones.length; i ++ ) {
      final bone = bones[ i ];

      if ( bone['type'] == 'ENDSITE' )
        continue;

      // track data

      final List<num> times = [];
      final List<num> positions = [];
      final List<num> rotations = [];

      for (int j = 0; j < bone['frames'].length; j ++ ) {
        final Map<String, dynamic> frame = bone['frames'][ j ];

        times.add( frame['time'] );

        // the animation system animates the position property,
        // so we have to add the joint offset to all values

        positions.add( frame['position'].x + bone['offset'].x );
        positions.add( frame['position'].y + bone['offset'].y );
        positions.add( frame['position'].z + bone['offset'].z );

        rotations.add( frame['rotation'].x );
        rotations.add( frame['rotation'].y );
        rotations.add( frame['rotation'].z );
        rotations.add( frame['rotation'].w );

      }

      if ( this.animateBonePositions ) {
        tracks.add( VectorKeyframeTrack( bone['name'] + '.position', times, positions ) );
      }

      if ( this.animateBoneRotations ) {
        tracks.add( QuaternionKeyframeTrack( bone['name'] + '.quaternion', times, rotations ) );
      }
    }

    return AnimationClip( 'animation', - 1, tracks );
  }

  /*
    returns the next non-empty line in lines
  */
  String nextLine(List<String> lines ) {
    String line = '';
    // skip empty lines
    while (lines.isNotEmpty && ( line = lines.removeAt(0).trim() ).length == 0 ) { }
    return line;
  }
}