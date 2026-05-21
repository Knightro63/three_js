import 'package:three_js_core/three_js_core.dart';

class Info {
  bool autoReset = true;
  int frame = 0;
  int calls = 0;

  Map<String,int> render = {
    'calls': 0,
    'frameCalls': 0,
    'drawCalls': 0,
    'triangles': 0,
    'points': 0,
    'lines': 0,
    'timestamp': 0,
  };

  Map<String,int> compute = {
    'calls': 0,
    'frameCalls': 0,
    'timestamp': 0
  };

  Map<String,int> memory = {
    'geometries': 0,
    'textures': 0
  };

	Info();

	void update(Object3D object, int count, int instanceCount ) {
		render['drawCalls'] = render['drawCalls']! + 1;

		if ( object is Mesh || object is Sprite ) {
			render['triangles'] = render['triangles']! + instanceCount * ( count ~/ 3 );
		} else if ( object is Points ) {
			render['points'] = render['points']! + instanceCount * count;
		} else if ( object is LineSegments ) {
			render['lines'] = render['lines']! + instanceCount * ( count ~/ 2 );
		} else if ( object is Line ) {
			render['lines'] = render['lines']! +instanceCount * ( count - 1 );
		} else {
			console.error( 'THREE.WebGPUInfo: Unknown object type.' );
		}
	}

	void reset() {
		render['drawCalls'] = 0;
		render['frameCalls'] = 0;
		compute['frameCalls'] = 0;

		render['triangles'] = 0;
		render['points'] = 0;
		render['lines'] = 0;
	}


	void dispose() {
		reset();
		calls = 0;

		render['calls'] = 0;
		compute['calls'] = 0;

		render['timestamp'] = 0;
		compute['timestamp'] = 0;
		memory['geometries'] = 0;
		memory['textures'] = 0;
	}
}
