import 'package:three_js_core/three_js_core.dart';

class DataMap {
  WeakMap data = WeakMap();

	DataMap();

	get( object ) {
		dynamic map = data.get( object );

		if ( map == null ) {
			map = {};
			data.set( object, map );
		}

		return map;
	}

	Map? delete( object ) {
		Map? map;
		if ( data.has( object ) ) {
			map = data.get( object );
			data.delete( object );
		}
		return map;
	}

	bool has( object ) {
		return data.has( object );
	}

	void dispose() {
		data = WeakMap();
	}
}

