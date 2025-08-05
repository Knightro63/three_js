import 'package:flutter_angle/flutter_angle.dart';
import 'package:uuid/uuid.dart';
import 'dart:typed_data';
import 'dart:math' as math;

extension ListExtension on List{
  void set<T>(List<T> newList, [int index = 0]) {
   setAll(index, newList.sublist(0, math.min(newList.length, length)));
  }

  T? getMinValue<T extends num>() {
    if (isEmpty) return null; //return 9999999;

    List l = sublist(0);
    T min = l[0];

    for (int i = 1; i < length; ++i) {
      if (l[i] < min) min = l[i];
    }

    return min;
  }

  T? getMaxValue<T extends num>(){
    if (isEmpty) return null; // return -99999999;

    List l = sublist(0);

    T max = l[0];

    for (int i = 1; i < length; ++i) {
      final newVal = l[i];
      if (newVal > max) max = l[i];
    }
    return max;
  }

  void listSetter<T>(int idx, dynamic value) {
    if (length > idx) {
      this[idx] = value;
    } else if (length == idx) {
      add(value);
    } else {
      addAll(List<T>.filled(idx + 1 - length, 0 as T));
      this[idx] = value;
    }
  }
}

extension DoubleUtil on double{
  double toRad(){
    return this*(math.pi / 180);
  }
  double toDeg(){
    return this*(180.0 / math.pi);
  }
}

class MathUtils{
  static const double epsilon = 4.94065645841247E-324;
  static int maxSafeInteger = 9007199254740991;
  
  static double deg2rad = math.pi / 180.0;
  static double rad2deg = 180.0 / math.pi;

  static double degToRad(double val){
    return val*(math.pi / 180);
  }
  static double radToDeg(double val){
    return val*(180.0 / math.pi);
  }

  static bool isPowerOfTwo(int value) {
    return (value & (value - 1)) == 0 && value != 0;
  }
  static double log2(num x) {
    return math.log(x) / math.ln2;
  }
  static String generateUUID() {
    final uuid = const Uuid().v4();
    // .toLowerCase() here flattens concatenated strings to save heap memory space.
    return uuid.toLowerCase();
  }
  static num mapLinear<T extends num>(T x, T a1, T a2, T b1, T b2) {
    return b1 + (x - a1) * (b2 - b1) / (a2 - a1);
  }
  static T clamp<T extends num>(T value, T min, T max) {
    return math.max(min, math.min(max, value));
  }
  static double ceilPowerOfTwo<T extends num>(T value) {
    return math.pow(2, (math.log(value) / math.ln2).ceil().toDouble()).toDouble();
  }
  static double floorPowerOfTwo<T extends num>(T value) {
    return math.pow(2, (math.log(value) / math.ln2).floor().toDouble()).toDouble();
  }
  static T? listGetMaxValue<T extends num>(List<T> array) {
    if (array.isEmpty) return null; // return -99999999;

    T max = array[0];

    for (int i = 1, l = array.length; i < l; ++i) {
      if (array[i] > max) max = array[i];
    }

    return max;
  }

  static int toHalfFloat(num val) {
    final _floatView = Float32List(1);
    final _int32View = Int32List.view(_floatView.buffer);
    // Source: http://gamedev.stackexchange.com/questions/17326/conversion-of-a-number-from-single-precision-floating-point-representation-to-a/17410#17410

    /* This method is faster than the OpenEXR implementation (very often
		* used, eg. in Ogre), with the additional benefit of rounding, inspired
		* by James Tursa?s half-precision code. */

    _floatView[0] = val.toDouble();
    final x = _int32View[0];

    int bits = (x >> 16) & 0x8000; /* Get the sign */
    int m = (x >> 12) & 0x07ff; /* Keep one extra bit for rounding */
    final e = (x >> 23) & 0xff; /* Using int is faster here */

    /* If zero, or denormal, or exponent underflows too much for a denormal
			* half, return signed zero. */
    if (e < 103) return bits;

    /* If NaN, return NaN. If Inf or exponent overflow, return Inf. */
    if (e > 142) {
      bits |= 0x7c00;
      /* If exponent was 0xff and one mantissa bit was set, it means NaN,
						* not Inf, so make sure we set one mantissa bit too. */
      // bits |= ( ( e == 255 ) ? 0 : 1 ) && ( x & 0x007fffff );
      bits |= (e == 255 ? (x & 0x007fffff) : 1);

      return bits;
    }

    /* If exponent underflows but not too much, return a denormal */
    if (e < 113) {
      m |= 0x0800;
      /* Extra rounding may overflow and set mantissa to 0 and exponent
				* to 1, which is OK. */
      bits |= (m >> (114 - e)) + ((m >> (113 - e)) & 1);
      return bits;
    }

    bits |= ((e - 112) << 10) | (m >> 1);
    /* Extra rounding. An overflow will set mantissa to 0 and increment
			* the exponent, which is OK. */
    bits += m & 1;
    return bits;
  }

  static fromHalfFloat(num value) {
    final val = value.toInt();
    final m = val >> 10;
    final uint32View = Uint32List( 4 );
    final mantissaTable = Uint32List( 2048 );
    final exponentTable = Uint32List( 64 );
    final offsetTable = Uint32List( 64 );

    for (int i = 1; i < 1024; ++ i ) {
      int m = i << 13; // zero pad mantissa bits
      int e = 0; // zero exponent

      // normalized
      while ( ( m & 0x00800000 ) == 0 ) {
        m <<= 1;
        e -= 0x00800000; // decrement exponent
      }

      m &= ~ 0x00800000; // clear leading 1 bit
      e += 0x38800000; // adjust bias

      mantissaTable[ i ] = m | e;
    }

    for (int i = 1024; i < 2048; ++ i ) {
      mantissaTable[ i ] = 0x38000000 + ( ( i - 1024 ) << 13 );
    }

    for (int i = 1; i < 31; ++ i ) {
      exponentTable[ i ] = i << 23;
    }

    exponentTable[ 31 ] = 0x47800000;
    exponentTable[ 32 ] = 0x80000000;

    for (int i = 33; i < 63; ++ i ) {
      exponentTable[ i ] = 0x80000000 + ( ( i - 32 ) << 23 );
    }

    exponentTable[ 63 ] = 0xc7800000;

    for (int i = 1; i < 64; ++ i ) {
      if ( i != 32 ) {
        offsetTable[ i ] = 1024;
      }
    }

    uint32View[ 0 ] = mantissaTable[offsetTable[ m ] + ( val & 0x3ff ) ] + exponentTable[ m ];
    return uint32View.buffer.asFloat32List();
  }

  ///
  /// Denormalizes the given value according to the given typed array.
  ///
  /// @param {number} value - The value to denormalize.
  /// @param {TypedArray} array - The typed array that defines the data type of the value.
  /// @return {number} The denormalize (float) value in the range `[0,1]`.
  ///
  static double denormalize(num value, NativeArray array ) {
    switch (array.runtimeType) {
      case Float32Array:
        return value*1.0;
      case Uint32Array:
        return value / 4294967295.0;
      case Uint16Array:
        return value / 65535.0;
      case Uint8Array:
        return value / 255.0;
      case Int32Array:
        return math.max( value / 2147483647.0, - 1.0 );
      case Int16Array:
        return math.max( value / 32767.0, - 1.0 );
      case Int8Array:
        return math.max( value / 127.0, - 1.0 );
      default:
        throw( 'Invalid component type.' );
    }
  }

  ///
  /// Normalizes the given value according to the given typed array.
  ///
  /// @param {number} value - The float value in the range `[0,1]` to normalize.
  /// @param {TypedArray} array - The typed array that defines the data type of the value.
  /// @return {number} The normalize value.
  ///
  static double normalize( num value, NativeArray array ) {
    switch ( array.runtimeType ) {
      case Float32Array:
        return value.toDouble();
      case Uint32Array:
        return ( value * 4294967295.0 ).roundToDouble();
      case Uint16Array:
        return ( value * 65535.0 ).roundToDouble();
      case Uint8Array:
        return ( value * 255.0 ).roundToDouble();
      case Int32Array:
        return ( value * 2147483647.0 ).roundToDouble();
      case Int16Array:
        return ( value * 32767.0 ).roundToDouble();
      case Int8Array:
        return ( value * 127.0 ).roundToDouble();
      default:
        throw( 'Invalid component type.' );
    }
  }
  // static void listSetter<T>(List<T> list, int idx, dynamic value) {
  //   if (list.length > idx) {
  //     list[idx] = value;
  //   } else if (list.length == idx) {
  //     list.add(value);
  //   } else {
  //     list.addAll(List<T>.filled(idx + 1 - list.length, 0 as T));
  //     list[idx] = value;
  //   }
  // }
}