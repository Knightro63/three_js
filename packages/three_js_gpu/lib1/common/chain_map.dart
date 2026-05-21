
import 'package:three_js_core/three_js_core.dart';

class ChainMap {
  WeakMap weakMap = WeakMap();

	ChainMap();

	/**
	 * Returns the value for the given array of keys.
	 *
	 * @param {Array<Object>} keys - List of keys.
	 * @return {any} The value. Returns `undefined` if no value was found.
	 */
	dynamic get(List keys ) {
		WeakMap? map = weakMap;

		for (int i = 0; i < keys.length - 1; i ++ ) {
			map = map?.get( keys[ i ] );
			if ( map == null ) return null;
		}

		return map?.get( keys[ keys.length - 1 ] );
	}

	ChainMap set(List keys, value ) {
		WeakMap? map = weakMap;

		for (int i = 0; i < keys.length - 1; i ++ ) {
			final key = keys[ i ];
			if ( map?.contains( key ) == false ) map?.set( key, WeakMap() );
			map = map?.get( key );
		}

		map?.set( keys[ keys.length - 1 ], value );

		return this;
	}

	/**
	 * Deletes a value for the given keys.
	 *
	 * @param {Array<Object>} keys - The keys.
	 * @return {boolean} Returns `true` if the value has been removed successfully and `false` if the value has not be found.
	 */
	bool delete(List keys ) {
		WeakMap? map = weakMap;

		for (int i = 0; i < keys.length - 1; i ++ ) {
			map = map?.get( keys[ i ] );
			if ( map == null ) return false;
		}

    bool temp = map?.contains( keys[ keys.length - 1 ] ) ?? false;
    map?.delete( keys[ keys.length - 1 ] );

		return temp;
	}

}
