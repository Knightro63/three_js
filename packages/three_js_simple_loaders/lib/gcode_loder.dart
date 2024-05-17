import "dart:io";
import 'dart:math' as math;
import "dart:typed_data";
import "package:three_js_core/three_js_core.dart";
import "package:three_js_core_loaders/three_js_core_loaders.dart";
import "package:three_js_math/three_js_math.dart";

/**
 * GCodeLoader is used to load gcode files usually used for 3D printing or CNC applications.
 *
 * Gcode files are composed by commands used by machines to create objects.
 *
 * @class GCodeLoader
 * @param {Manager} manager Loading manager.
 */

class GCodeLoader extends Loader {
  late final FileLoader _loader;
  bool splitLayer;

  /// [manager] — The [loadingManager] for the loader to use. Default is [DefaultLoadingManager].
  /// 
  /// Creates a [OBJLoader].
  GCodeLoader([super.manager, this.splitLayer = false]){
    _loader = FileLoader(manager);
  }

  void _init(){
    _loader.setPath(path);
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

	Group _parse(Uint8List bytes) {
    String data = String.fromCharCodes(bytes);
    final object = Group();

		_Line state = _Line( 
      x: 0, 
      y: 0, 
      z: 0, 
      e: 0, 
      f: 0, 
      extruding: false, 
      relative: false 
    );
		final layers = [];

		_Line? currentLayer;

		final pathMaterial = LineBasicMaterial.fromMap( { 'color': 0xFF0000 } );
		pathMaterial.name = 'path';

		final extrudingMaterial = LineBasicMaterial.fromMap( { 'color': 0x00FF00 } );
		extrudingMaterial.name = 'extruded';

		void newLayer( line ) {
			currentLayer = _Line( 
        vertex: [], 
        pathVertex: [], 
        z: line.z 
      );
			layers.add( currentLayer );
		}

		//Create lie segment between p1 and p2
		void addSegment( p1, p2 ) {
			if ( currentLayer == null ) {
				newLayer( p1 );
			}

			if ( state.extruding! ) {
				currentLayer?.vertex?.addAll([ p1.x, p1.y, p1.z ]);
				currentLayer?.vertex?.addAll([ p2.x, p2.y, p2.z ]);
			} else {
				currentLayer?.pathVertex?.addAll([ p1.x, p1.y, p1.z ]);
				currentLayer?.pathVertex?.addAll([ p2.x, p2.y, p2.z ]);
			}
		}

		double delta(double v1, double v2 ) {
			return state.relative! ? v2 : v2 - v1;
		}

		double absolute(double v1, double v2 ) {
			return state.relative! ? v1 + v2 : v2;
		}

		final lines = data.replaceAll(RegExp(r'/;.+/g'), '' ).split( '\n' );

		for (int i = 0; i < lines.length; i ++ ) {

			final tokens = lines[i].split( ' ' );
			final cmd = tokens[0].toUpperCase();

			//Argumments
			final args = _Line();
			tokens.removeAt(0);
      //tokens.forEach( ( token ) {
      for(final token in tokens){
				if (token[0] != '') {
					final key = token[0].toLowerCase();
					final value = double.parse(token.substring( 1 ));
					args[key] = value;
				}
			}

			//Process commands
			//G0/G1 – Linear Movement
			if ( cmd == 'G0' || cmd == 'G1' ) {
				final line = _Line(
					x: args.x != null ? absolute( state.x!, args.x! ) : state.x,
					y: args.y != null ? absolute( state.y!, args.y! ) : state.y,
					z: args.z != null ? absolute( state.z!, args.z! ) : state.z,
					e: args.e != null ? absolute( state.e!, args.e! ) : state.e,
					f: args.f != null ? absolute( state.f!, args.f! ) : state.f,
        );

				//Layer change detection is or made by watching Z, it's made by watching when we extrude at a Z position
				if ( delta( state.e!, line.e! ) > 0 ) {
					state.extruding = delta( state.e!, line.e! ) > 0;
					if ( currentLayer == null || line.z != currentLayer!.z ) {
						newLayer( line );
					}
				}

				addSegment( state, line );
				state = line;

			} else if ( cmd == 'G2' || cmd == 'G3' ) {
				//G2/G3 - Arc Movement ( G2 clock wise and G3 counter clock wise )
				//console.warn( 'THREE.GCodeLoader: Arc command not supported' );
			} else if ( cmd == 'G90' ) {
				//G90: Set to Absolute Positioning
				state.relative = false;
			} else if ( cmd == 'G91' ) {
				//G91: Set to state.relative Positioning
				state.relative = true;
			} else if ( cmd == 'G92' ) {
				//G92: Set Position
				final line = state;
				line.x = args.x ?? line.x;
				line.y = args.y ?? line.y;
				line.z = args.z ?? line.z;
				line.e = args.e ?? line.e;

			} else {
			  console.warning( 'THREE.GCodeLoader: Command not supported: $cmd');
			}
		}

		void addObject(List<double> vertex, bool extruding, int i ) {
			final geometry = BufferGeometry();
			geometry.setAttributeFromString( 'position', Float32BufferAttribute.fromList( vertex, 3 ) );
			final segments = LineSegments( geometry, extruding ? extrudingMaterial : pathMaterial );
			segments.name = 'layer$i';
			object.add( segments );
		}

		
		object.name = 'gcode';

		if (splitLayer ) {
			for (int i = 0; i < layers.length; i ++ ) {
				final layer = layers[ i ];
				addObject( layer.vertex, true, i );
				addObject( layer.pathVertex, false, i );
			}
		} else {
			final List<double> vertex = [];
			final List<double> pathVertex = [];

			for(int i = 0; i < layers.length; i ++ ) {
				final layer = layers[ i ];
				final layerVertex = layer.vertex;
				final layerPathVertex = layer.pathVertex;

				for(int j = 0; j < layerVertex.length; j ++ ) {
					vertex.add( layerVertex[ j ] );
				}

				for(int j = 0; j < layerPathVertex.length; j ++ ) {
					pathVertex.add( layerPathVertex[ j ] );
				}
			}

			addObject( vertex, true, layers.length );
			addObject( pathVertex, false, layers.length );
		}

		object.rotation.set( - math.pi / 2, 0, 0 );
		return object;
	}
}

class _Line{
  double? x;
  double? y;
  double? z;
  double? e;
  double? f;

  bool? extruding;
  bool? relative;

  List? vertex;
  List? pathVertex;

  _Line({
    this.x,
    this.y,
    this.z,
    this.e,
    this.f,
    this.extruding,
    this.relative,
    this.pathVertex,
    this.vertex
  });

  operator []=(String key, dynamic value) => (){
    switch (key.toLowerCase()) {
      case 'x':
        x = value;
        break;
      case 'y':
        y = value;
        break;
      case 'z':
        z = value;
        break;
      case 'e':
        e = value;
        break;
      case 'f':
        f = value;
        break;
      case 'extruding':
        extruding = value;
        break;
      case 'relative':
        relative = value;
        break;
      case 'pathVertex':
        pathVertex = value;
        break;
      case 'vertex':
        vertex = value;
        break;
    }
  };
}