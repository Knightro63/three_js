import 'dart:typed_data';

import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_core_loaders/three_js_core_loaders.dart';
import 'package:three_js_math/matrix/matrix4.dart';
import 'package:three_js_math/vector/vector3.dart';

/**
 * A loader for the NRRD format.
 *
 * ```js
 * final loader = new NRRDLoader();
 * final volume = await loader.loadAsync( 'models/nrrd/I.nrrd' );
 * ```
 *
 * @augments Loader
 * @three_import import { NRRDLoader } from 'three/addons/loaders/NRRDLoader.js';
 */
class NRRDLoader extends Loader {
  bool segmentation = false;

	NRRDLoader(super.manager );

	/**
	 * Starts loading from the given URL and passes the loaded NRRD asset
	 * to the `onLoad()` callback.
	 *
	 * @param {string} url - The path/URL of the file to be loaded. This can also be a data URI.
	 * @param {function(Volume)} onLoad - Executed when the loading process has been finished.
	 * @param {onProgressCallback} onProgress - Executed while the loading is in progress.
	 * @param {onErrorCallback} onError - Executed when errors occur.
	 */
	load( url, onLoad, onProgress, onError ) {

		final scope = this;

		final loader = new FileLoader( scope.manager );
		loader.setPath( scope.path );
		loader.setResponseType( 'arraybuffer' );
		loader.setRequestHeader( scope.requestHeader );
		loader.setWithCredentials( scope.withCredentials );
		loader.load( url, ( data ) {
			try {
				onLoad( scope.parse( data ) );
			} catch ( e ) {
				if ( onError ) {
					onError( e );
				} else {
					console.error( e );
				}
				scope.manager.itemError( url );
			}
		}, onProgress, onError );
	}

	/**
	 * Toggles the segmentation mode.
	 *
	 * @param {boolean} segmentation - Whether to use segmentation mode or not.
	 */
	setSegmentation(bool segmentation ) {
		this.segmentation = segmentation;
	}

	/**
	 * Parses the given NRRD data and returns the resulting volume data.
	 *
	 * @param {ArrayBuffer} data - The raw NRRD data as an array buffer.
	 * @return {Volume} The parsed volume.
	 */
	parse(List data ) {
		List _data = data;
		int _dataPointer = 0;

		final _nativeLittleEndian = Int16List.fromList( [ 1 ] ).buffer.asUint8List()[ 0 ] > 0;
		bool _littleEndian = true;
		final headerObject = {};
		//Flips typed array endianness in-place. Based on https://github.com/kig/DataStream.js/blob/master/DataStream.js.

		flipEndianness( array, int chunkSize ) {
			final u8 = new Uint8List( array.buffer, array.byteOffset, array.byteLength );
			for ( int i = 0; i < array.byteLength; i += chunkSize ) {
				for (int j = i + chunkSize - 1, k = i; j > k; j --, k ++ ) {
					final tmp = u8[ k ];
					u8[ k ] = u8[ j ];
					u8[ j ] = tmp;
				}
			}

			return array;
		}

		scan(String type, int chunks ) {
			int _chunkSize = 1;
			dynamic _array_type = Uint8List;

			switch ( type ) {

				// 1 byte data types
				case 'uchar':
					break;
				case 'schar':
					_array_type = Int8List;
					break;
				// 2 byte data types
				case 'ushort':
					_array_type = Uint16List;
					_chunkSize = 2;
					break;
				case 'sshort':
					_array_type = Int16List;
					_chunkSize = 2;
					break;
				// 4 byte data types
				case 'uint':
					_array_type = Uint32List;
					_chunkSize = 4;
					break;
				case 'sint':
					_array_type = Int32List;
					_chunkSize = 4;
					break;
				case 'float':
					_array_type = Float32List;
					_chunkSize = 4;
					break;
				case 'complex':
					_array_type = Float64List;
					_chunkSize = 8;
					break;
				case 'double':
					_array_type = Float64List;
					_chunkSize = 8;
					break;
			}

			// increase the data pointer in-place
			dynamic _bytes = _array_type( _data.sublist( _dataPointer,_dataPointer += chunks * _chunkSize ) );

			// if required, flip the endianness of the bytes
			if ( _nativeLittleEndian != _littleEndian ) {
				// we need to flip here since the format doesn't match the native endianness
				_bytes = flipEndianness( _bytes, _chunkSize );
			}

			// return the byte array
			return _bytes;
		}



		//parse the header
		parseHeader( header ) {
			let data, field, fn, i, l, m;
			final lines = header.split( '/\r?\n/' );
      int _len = lines.length;
      int _i = 0;
			for ( _i = 0; _i < _len; _i ++ ) {
				l = lines[ _i ];
				if ( l.match( '/NRRD\d+/' ) ) {
					headerObject['isNrrd'] = true;
				} else if ( ! l.match( '/^#/' ) && ( m = l.match( '/(.*):(.*)/' ) ) ) {
					field = m[ 1 ].trim();
					data = m[ 2 ].trim();
					fn = _fieldFunctions[ field ];
					if ( fn ) {
						fn.call( headerObject, data );
					} else {
						headerObject[ field ] = data;
					}
				}
			}

			if ( ! headerObject['isNrrd'] ) {
				throw( 'Not an NRRD file' );
			}

			if ( headerObject['encoding'] == 'bz2' || headerObject['encoding'] == 'bzip2' ) {
				throw( 'Bzip is not supported' );
			}

			if (headerObject['vectors'] == null) {
				//if no space direction is set, let's use the identity
				headerObject['vectors'] = [ ];
				headerObject['vectors'].add( [ 1, 0, 0 ] );
				headerObject['vectors'].add( [ 0, 1, 0 ] );
				headerObject['vectors'].add( [ 0, 0, 1 ] );

				//apply spacing if defined
				if ( headerObject['spacings'] != null) {
					for ( i = 0; i <= 2; i ++ ) {
						if (!(headerObject['spacings'][ i ] as num).isNaN) {
							for (int j = 0; j <= 2; j ++ ) {
								headerObject['vectors'][ i ][ j ] *= headerObject['spacings'][ i ];
							}
						}
					}
				}
			}
		}

		//parse the data when registered as one of this type : 'text', 'ascii', 'txt'
		parseDataAsText( data, [int? start, int? end] ) {
			String number = '';
			start = start ?? 0;
			end = end ?? data.length;
			int value;
			//length of the result is the product of the sizes
			final lengthOfTheResult = headerObject['sizes'].reduce( ( previous, current ) {
				return previous * current;
			}, 1 );

			int base = 10;
			if ( headerObject['encoding'] == 'hex' ) {
				base = 16;
			}

			final result = headerObject.__array( lengthOfTheResult );
			int resultIndex = 0;
			num Function(String, [int? radix]) parsingFunction = (string,[int? radix]){return int.parse(string,radix: radix);};
			if ( headerObject['__array'] == Float32List || headerObject['__array'] == Float64List ) {
				parsingFunction = (string,[int? radix]){return double.parse(string);};
			}

			for (int i = start; i < end!; i ++ ) {
				value = data[ i ];
				//if value is not a space
				if ( ( value < 9 || value > 13 ) && value != 32 ) {
					number += String.fromCharCode( value );
				}
        else {
					if ( number != '' ) {
						result[ resultIndex ] = parsingFunction( number, base );
						resultIndex ++;
					}
					number = '';
				}
			}

			if ( number != '' ) {
				result[ resultIndex ] = parsingFunction( number, base );
				resultIndex ++;
			}

			return result;
		}

		final _bytes = scan( 'uchar', data.byteLength );
		final _length = _bytes.length;
		let _header = null;
		int _data_start = 0;
		int i;
		for ( i = 1; i < _length; i ++ ) {
			if ( _bytes[ i - 1 ] == 10 && _bytes[ i ] == 10 ) {
				// we found two line breaks in a row
				// now we know what the header is
				_header = this._parseChars( _bytes, 0, i - 2 );
				// this is were the data starts
				_data_start = i + 1;
				break;
			}
		}

		// parse the header
		parseHeader( _header );
		_data = _bytes.subarray( _data_start ); // the data without header
		if ( headerObject['encoding'].substring( 0, 2 ) == 'gz' ) {

			// we need to decompress the datastream
			// here we start the unzipping and get a typed Uint8Array back
			_data = fflate.gunzipSync( new Uint8List.fromList( _data ) );

		} 
    else if ( headerObject['encoding'] == 'ascii' || headerObject['encoding'] == 'text' || headerObject['encoding'] == 'txt' || headerObject['encoding'] == 'hex' ) {
			_data = parseDataAsText( _data );
		} 
    else if ( headerObject['encoding'] == 'raw' ) {
			//we need to copy the array to create a new array buffer, else we retrieve the original arraybuffer with the header
			final _copy = new Uint8List( _data.length );

			for (int i = 0; i < _data.length; i ++ ) {
				_copy[ i ] = _data[ i ];
			}
			_data = _copy;
		}

		// .. let's use the underlying array buffer
		_data = _data.buffer;

		final volume = new Volume();
		volume.header = headerObject;
		volume.segmentation = this.segmentation;
		//
		// parse the (unzipped) data to a datastream of the correct type
		//
		volume.data = new headerObject.__array( _data );
		// get the min and max intensities
		final min_max = volume.computeMinMax();
		final min = min_max[ 0 ];
		final max = min_max[ 1 ];
		// attach the scalar range to the volume
		volume.windowLow = min;
		volume.windowHigh = max;

		// get the image dimensions
		volume.dimensions = [ headerObject['sizes'][ 0 ], headerObject['sizes'][ 1 ], headerObject['sizes'][ 2 ] ];
		volume.xLength = volume.dimensions[ 0 ];
		volume.yLength = volume.dimensions[ 1 ];
		volume.zLength = volume.dimensions[ 2 ];

		// Identify axis order in the space-directions matrix from the header if possible.
		if ( headerObject['vectors'] != null) {

			final xIndex = headerObject['vectors'].indexWhere( (vector) => vector[ 0 ] != 0 );
			final yIndex = headerObject['vectors'].indexWhere( (vector) => vector[ 1 ] != 0 );
			final zIndex = headerObject['vectors'].indexWhere( (vector) => vector[ 2 ] != 0 );

			final axisOrder = [];

			if ( xIndex != yIndex && xIndex != zIndex && yIndex != zIndex ) {
				axisOrder[ xIndex ] = 'x';
				axisOrder[ yIndex ] = 'y';
				axisOrder[ zIndex ] = 'z';
			} 
      else {
				axisOrder[ 0 ] = 'x';
				axisOrder[ 1 ] = 'y';
				axisOrder[ 2 ] = 'z';
			}
			volume.axisOrder = axisOrder;
		} 
    else {
			volume.axisOrder = [ 'x', 'y', 'z' ];
		}

		// spacing
		final spacingX = Vector3().copyFromArray( headerObject['vectors'][ 0 ] ).length;
		final spacingY = Vector3().copyFromArray( headerObject['vectors'][ 1 ] ).length;
		final spacingZ = Vector3().copyFromArray( headerObject['vectors'][ 2 ] ).length;
		volume.spacing = [ spacingX, spacingY, spacingZ ];

		// Create IJKtoRAS matrix
		volume.matrix = new Matrix4();

		final transitionMatrix = new Matrix4();

		if ( headerObject['space'] == 'left-posterior-superior' ) {
			transitionMatrix.setValues(
				- 1, 0, 0, 0,
				0, - 1, 0, 0,
				0, 0, 1, 0,
				0, 0, 0, 1
			);
		} else if ( headerObject['space'] == 'left-anterior-superior' ) {
			transitionMatrix.setValues(
				1, 0, 0, 0,
				0, 1, 0, 0,
				0, 0, - 1, 0,
				0, 0, 0, 1
			);
		}


		if (headerObject['vectors'] == null) {
			volume.matrix.set(
				1, 0, 0, 0,
				0, 1, 0, 0,
				0, 0, 1, 0,
				0, 0, 0, 1 );

		} 
    else {
			final v = headerObject['vectors'];

			final ijk_to_transition = Matrix4().setValues(
				v[ 0 ][ 0 ], v[ 1 ][ 0 ], v[ 2 ][ 0 ], 0,
				v[ 0 ][ 1 ], v[ 1 ][ 1 ], v[ 2 ][ 1 ], 0,
				v[ 0 ][ 2 ], v[ 1 ][ 2 ], v[ 2 ][ 2 ], 0,
				0, 0, 0, 1
			);

			final transition_to_ras = Matrix4().multiply2( ijk_to_transition, transitionMatrix );

			volume.matrix = transition_to_ras;
		}

		volume.inverseMatrix = Matrix4();
		volume.inverseMatrix.copy( volume.matrix ).invert();

		volume.RASDimensions = [
			( volume.xLength * spacingX ).floor(),
			( volume.yLength * spacingY ).floor(),
			( volume.zLength * spacingZ ).floor()
		];

		// .. and set the default threshold
		// only if the threshold was not already set
		if ( volume.lowerThreshold == - double.infinity ) {
			volume.lowerThreshold = min;
		}

		if ( volume.upperThreshold == double.infinity ) {
			volume.upperThreshold = max;
		}

		return volume;
	}

	_parseChars( array, start, end ) {
		// without borders, use the whole array
		if ( start == null ) {
			start = 0;
		}

		if ( end == null ) {
			end = array.length;
		}

		String output = '';
		// create and append the chars
		int i = 0;
		for ( i = start; i < end; ++ i ) {
			output += String.fromCharCode( array[ i ] );
		}

		return output;
	}

  final _fieldFunctions = {
    'type': ( data ) {
      switch ( data ) {
        case 'uchar':
        case 'unsigned char':
        case 'uint8':
        case 'uint8_t':
          __array = Uint8List;
          break;
        case 'signed char':
        case 'int8':
        case 'int8_t':
          __array = Int8List;
          break;
        case 'short':
        case 'short int':
        case 'signed short':
        case 'signed short int':
        case 'int16':
        case 'int16_t':
          __array = Int16List;
          break;
        case 'ushort':
        case 'unsigned short':
        case 'unsigned short int':
        case 'uint16':
        case 'uint16_t':
          __array = Uint16List;
          break;
        case 'int':
        case 'signed int':
        case 'int32':
        case 'int32_t':
          __array = Int32List;
          break;
        case 'uint':
        case 'unsigned int':
        case 'uint32':
        case 'uint32_t':
          __array = Uint32List;
          break;
        case 'float':
          __array = Float32List;
          break;
        case 'double':
          __array = Float64List;
          break;
        default:
          throw( 'Unsupported NRRD data type: ' + data );

      }

      return this.type = data;
    },
    'endian': ( data ) {
      return this.endian = data;
    },
    'encoding': ( data ) {
      return this.encoding = data;
    },
    'dimension': ( data ) {
      return this.dim = parseInt( data, 10 );
    },
    'sizes': ( data ) {
      int i;
      return this.sizes = ( () {
        final _ref = data.split( /\s+/ );
        final _results = [];

        for (int _i = 0, _len = _ref.length; _i < _len; _i ++ ) {
          i = _ref[ _i ];
          _results.add( int.parse( i, radix: 10 ) );
        }

        return _results;
      } )();
    },
    'space': ( data ) {
      return this.space = data;
    },
    'space origin': ( data ) {
      return this.space_origin = data.split( '(' )[ 1 ].split( ')' )[ 0 ].split( ',' );
    },
    'space directions': ( data ) {
      let f, v;
      final parts = data.match( /\(.*?\)/g );
      return this.vectors = ( () {
        final _results = [];

        for (int _i = 0, _len = parts.length; _i < _len; _i ++ ) {
          v = parts[ _i ];
          _results.add( ( () {

            final _ref = v.slice( 1, - 1 ).split( /,/ );
            final _results2 = [];

            for (int _j = 0, _len2 = _ref.length; _j < _len2; _j ++ ) {
              f = _ref[ _j ];
              _results2.add( double.parse( f ) );
            }

            return _results2;
          } )() );
        }

        return _results;
      } )();
    },

    'spacings': ( data ) {
      let f;
      final parts = data.split( /\s+/ );
      return this.spacings = (() {
        final _results = [];

        for (int _i = 0, _len = parts.length; _i < _len; _i ++ ) {
          f = parts[ _i ];
          _results.add( double.parse( f ) );
        }

        return _results;
      } )();
    }
  };
}
