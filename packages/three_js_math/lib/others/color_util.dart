import 'dart:typed_data';
import 'package:three_js_math/three_js_math.dart';
import 'dart:math' as math;

enum ColorSpace{
  no,
  linear,
  srgb,
  dp3,
  ldp3;

  static ColorSpace fromString(String string){
    switch (string) {
      case NoColorSpace:
        return ColorSpace.no;
      case SRGBColorSpace:
        return ColorSpace.srgb;
      case LinearDisplayP3ColorSpace:
        return ColorSpace.ldp3;
      case DisplayP3ColorSpace:
        return ColorSpace.dp3;
      default:
      return ColorSpace.linear;
    }
  }

  @override
  String toString(){
    switch (this) {
      case ColorSpace.no:
        return NoColorSpace;
      case ColorSpace.srgb:
        return SRGBColorSpace;
      case ColorSpace.ldp3:
        return LinearDisplayP3ColorSpace;
      case ColorSpace.dp3:
        return DisplayP3ColorSpace ;
      default:
      return LinearSRGBColorSpace;
    }
  }
}

class Color{
  late final Float32List storage;

  static double srgbToLinear(double c){
    return ( c < 0.04045 ) ? c * 0.0773993808 : math.pow( c * 0.9478672986 + 0.0521327014, 2.4 ).toDouble();
  }
  static double linearToSRGB(double c) {
    return ( c < 0.0031308 ) ? c * 12.92 : 1.055 * ( math.pow( c, 0.41666 ) ) - 0.055;
  }
  static double hue2rgb(double p, double q, double t) {
    if (t < 0) t += 1;
    if (t > 1) t -= 1;
    if (t < 1 / 6) return p + (q - p) * 6 * t;
    if (t < 1 / 2) return q;
    if (t < 2 / 3) return p + (q - p) * 6 * (2 / 3 - t);
    return p;
  }

  Color([double red = 0, double green = 0, double blue = 0, double alpha = 0]){
    storage = Float32List.fromList([red,green,blue,alpha]);
  }
  Color.fromList(List<double> list){
    if(list.length <= 3){
      list.add(255);
    }
    storage = Float32List.fromList(list);
  }
  Color.fromHex64(int hex){
    int alpha = (0xff000000 & hex) >> 24;
    int red = (0x00ff0000 & hex) >> 16;
    int green = (0x0000ff00 & hex) >> 8;
    int blue = (0x000000ff & hex) >> 0;

    storage = Float32List.fromList([red/255,green/255,blue/255,alpha/255]);
  }
  Color.fromHex32(int hex){
    int red = (0xff0000 & hex) >> 16;
    int green = (0x00ff00 & hex) >> 8;
    int blue = (0x0000ff & hex) >> 0;

    storage = Float32List.fromList([red/255,green/255,blue/255,0]);
  }
  Color.copy(Color source){
    storage = Float32List.fromList(source.storage);
  }

  Color clone(){
    return Color(red, green, blue, alpha);
  }

  double get red => storage[0];
  set red(double r){
    storage[0] = r;
  }
  double get green => storage[1];
  set green(double g){
    storage[1] = g;
  }
  double get blue => storage[2];
  set blue(double b){
    storage[2] = b;
  }
  double get alpha => storage[3];
  set alpha(double a){
    storage[3] = a;
  }

  int getHex() {
    return (red * 255).toInt() << 16 ^
        (green * 255).toInt() << 8 ^
        (blue * 255).toInt() << 0;
  }

	Color lerpColors(Color color1,Color color2,double alpha ) {
		red = color1.red + ( color2.red - color1.red ) * alpha;
		green = color1.green + ( color2.green - color1.green ) * alpha;
		blue = color1.blue + ( color2.blue - color1.blue ) * alpha;
		return this;
	}
  Color fromBuffer(BufferAttribute attribute, int index) {
    storage[0] = attribute.getX(index)!.toDouble();
    storage[1] = attribute.getY(index)!.toDouble();
    storage[2] = attribute.getZ(index)!.toDouble();
    storage[3] = (attribute.getW(index) ?? 0).toDouble();
    
    return this;
  }
  Color fromNativeArray(NativeArray<num> list,[int offset = 0]) {
    storage[0] = list[offset].toDouble();
    storage[1] = list[offset+1].toDouble();
    storage[2] = list[offset+2].toDouble();
    if(list.length > 3){
      storage[3] = list[offset+3].toDouble();
    }
    return this;
  }
  Color fromUnknown(list,[int offset = 0]) {
    storage[0] = list[offset].toDouble();
    storage[1] = list[offset+1].toDouble();
    storage[2] = list[offset+2].toDouble();
    if(list.length > 3){
      storage[3] = list[offset+3].toDouble();
    }
    return this;
  }
  Color fromList(List<double> list,[int offset = 0]) {
    storage[0] = list[offset].toDouble();
    storage[1] = list[offset+1].toDouble();
    storage[2] = list[offset+2].toDouble();
    if(list.length > 3){
      storage[3] = list[offset+3].toDouble();
    }
    return this;
  }
  Color copyFromArray(List<double> list,[int offset = 0]) {
    storage[0] = list[offset].toDouble();
    storage[1] = list[offset+1].toDouble();
    storage[2] = list[offset+2].toDouble();
    if(list.length > 3){
      storage[3] = list[offset+3].toDouble();
    }
    return this;
  }
  NativeArray<num> copyIntoArray(array, [int offset = 0]) {
    array[offset] = storage[0];
    array[offset + 1] = storage[1];
    array[offset + 2] = storage[2];

    return array;
  }
  List<double> copyIntoList(List<double> array, [int offset = 0]) {
    array[offset] = storage[0];
    array[offset + 1] = storage[1];
    array[offset + 2] = storage[2];

    return array;
  }
  void setFrom(Color source){
    storage[0] = source.storage[0];
    storage[1] = source.storage[1];
    storage[2] = source.storage[2];
    if(source.storage.length > 3){
      storage[3] = source.storage[3];
    }
  }
  void setFromHex32(int hex){
    storage[0] = ((0xff0000 & hex) >> 16) / 255;
    storage[1] = ((0x00ff00 & hex) >> 8) /255;
    storage[2] = ((0x0000ff & hex) >> 0) / 255;
  }
  void setFromHex64(int hex){
    storage[3] = ((0xff000000 & hex) >> 32)/255;
    storage[0] = ((0x00ff0000 & hex) >> 16) / 255;
    storage[1] = ((0x0000ff00 & hex) >> 8) /255;
    storage[2] = ((0x000000ff & hex) >> 0) / 255;
  }
  void setValues(double r, double g, double b, [double w = 0]){
    storage[0] = r;
    storage[1] = g;
    storage[2] = b;
    storage[3] = w;
  }
  Color setFromHSL(double h, double s, double l, [ColorSpace colorSpace = ColorSpace.linear]) {
    // h,s,l ranges are in 0.0 - 1.0
    h = ((h % 1) + 1) % 1;
    s = s.clamp( 0, 1);
    l = l.clamp( 0, 1);

    if (s == 0) {
      storage[0] = l;
      storage[1] = l;
      storage[2] = l;
    } 
    else {
      final p = l <= 0.5 ? l * (1 + s) : l + s - (l * s);
      final q = (2 * l) - p;

      storage[0] = hue2rgb(q, p, h + 1 / 3);
      storage[1] = hue2rgb(q, p, h);
      storage[2] = hue2rgb(q, p, h - 1 / 3);
    }

    ColorManagement.toWorkingColorSpace( this, colorSpace );

    return this;
  }
  Color setRGB([double? r, double? g, double? b, ColorSpace colorSpace = ColorSpace.linear]) {
    red = r ?? 1.0;
    green = g ?? 1.0;
    blue = b ?? 1.0;

    ColorManagement.toWorkingColorSpace( this, colorSpace );

    return this;
  }
  Color setHSL(double h, double s, double l, [ColorSpace colorSpace = ColorSpace.linear]) {
    // h,s,l ranges are in 0.0 - 1.0
    h = ((h % 1) + 1) % 1;
    s = MathUtils.clamp(s, 0, 1);
    l = MathUtils.clamp(l, 0, 1);

    if (s == 0) {
      red = green = blue = l;
    } else {
      final p = l <= 0.5 ? l * (1 + s) : l + s - (l * s);
      final q = (2 * l) - p;

      red = Color.hue2rgb(q, p, h + 1 / 3);
      green = Color.hue2rgb(q, p, h);
      blue = Color.hue2rgb(q, p, h - 1 / 3);
    }

    ColorManagement.toWorkingColorSpace( this, colorSpace );

    return this;
  }
  Color toLinear() {
    storage[0] = srgbToLinear(red);
    storage[1] = srgbToLinear(green);
    storage[2] = srgbToLinear(blue);
    return this;
  }
	bool equals(Color c ) {
		return ( c.red == red ) && ( c.green == green ) && ( c.blue == blue );
	}
  void scale(double s) {
    storage[0] *= s;
    storage[1] *= s;
    storage[2] *= s;
  }
  Color multiply(Color color) {
    storage[0] *= color.red;
    storage[1] *= color.green;
    storage[2] *= color.blue;
    return this;
  }
  Color add(Color color) {
    storage[0] += color.red;
    storage[1] += color.green;
    storage[2] += color.blue;
    return this;
  }
  Color setScalar(double scalar) {
    red = scalar;
    green = scalar;
    blue = scalar;

    return this;
  }
  Color addScalar(num s) {
    storage[0] += s;
    storage[1] += s;
    storage[2] += s;

    return this;
  }
	String getStyle([ColorSpace colorSpace = ColorSpace.srgb]){
    Color temp = Color.copy(this);
		ColorManagement.fromWorkingColorSpace( 
      temp, 
      colorSpace 
    );

		if ( colorSpace != ColorSpace.srgb ) {
			// Requires CSS Color Module Level 4 (https://www.w3.org/TR/css-color-4/).
			return "color($colorSpace  ${ temp.red } ${ temp.green } ${ temp.blue })";
		}

		return "rgb(${( temp.red * 255 )},${( temp.green * 255 )},${( temp.blue * 255 )})";
  }

	Color getHSL(Color target, [ColorSpace colorSpace = ColorSpace.linear] ) {
    final Color _color = Color();
		ColorManagement.fromWorkingColorSpace( _color..setFrom( this ), colorSpace );

		final r = _color.red, g = _color.green, b = _color.blue;
		final max = math.max( r, math.max(g, b) );
		final min = math.min( r, math.min(g, b ));

		double hue = 0;
    double saturation;
		final lightness = ( min + max ) / 2.0;

		if ( min == max ) {
			hue = 0;
			saturation = 0;
		} 
    else {
			final delta = max - min;
			saturation = lightness <= 0.5 ? delta / ( max + min ) : delta / ( 2 - max - min );

      if(max == red){
        hue = ( g - b ) / delta + ( g < b ? 6 : 0 );
      }
      else if(max == green){
        hue = ( b - r ) / delta + 2;
      } 
      else if(max == blue){
        hue = ( r - g ) / delta + 4;
      }

			hue /= 6;
		}

		target.red = hue;
		target.green = saturation;
		target.blue = lightness;

		return target;
	}

	Color offsetHSL(double h, double s, double l ) {
    final Color temp = Color();
		getHSL( temp );
		return setHSL( temp.red + h, temp.green + s, temp.blue + l );
	}

  List<num> toNumArray(List<num> array, [int offset = 0]) {
    array[offset] = storage[0];
    array[offset + 1] = storage[1];
    array[offset + 2] = storage[2];

    return array;
  }

  Color copyFromUnknown(list,[int offset = 0]) {
    storage[0] = list[offset].toDouble();
    storage[1] = list[offset+1].toDouble();
    storage[2] = list[offset+2].toDouble();
    if(list.length > 3){
      storage[3] = list[offset+3].toDouble();
    }
    return this;
  }
  Color copySRGBToLinear(Color color) {
    storage[0] = srgbToLinear(color.storage[0]);
    storage[1] = srgbToLinear(color.storage[1]);
    storage[2] = srgbToLinear(color.storage[2]);
    return this;
  }

  Color copyLinearToSRGB(Color color) {
    storage[0] = linearToSRGB(color.storage[0]);
    storage[1] = linearToSRGB(color.storage[1]);
    storage[2] = linearToSRGB(color.storage[2]);

    return this;
  }

  Color convertSRGBToLinear() {
    copySRGBToLinear(this);
    return this;
  }

  Color convertLinearToSRGB() {
    copyLinearToSRGB(this);
    return this;
  }

	Color applyMatrix3(Matrix3 m){
		final r = red, g = green, b = blue;
		final e = m.storage;

		storage[0] = e[ 0 ] * r + e[ 3 ] * g + e[ 6 ] * b;
		storage[1] = e[ 1 ] * r + e[ 4 ] * g + e[ 7 ] * b;
		storage[2] = e[ 2 ] * r + e[ 5 ] * g + e[ 8 ] * b;

		return this;
	}

	Color getRGB(Color target, [ColorSpace? colorSpace ] ) {
    final Color _color = Color();
    colorSpace ??= ColorManagement.workingColorSpace;
		ColorManagement.fromWorkingColorSpace( Color.copy( this ), colorSpace );

		target.red = _color.red;
		target.green = _color.green;
		target.blue = _color.blue;

		return target;
	}
}

final lsrgb2ldp3 = Matrix3.identity().setValues(
	0.8224621, 0.177538, 0.0,
	0.0331941, 0.9668058, 0.0,
	0.0170827, 0.0723974, 0.9105199,
);

final ldp32lsrgb =  Matrix3.identity().setValues(
	1.2249401, - 0.2249404, 0.0,
	- 0.0420569, 1.0420571, 0.0,
	- 0.0196376, - 0.0786361, 1.0982735
);

// JavaScript RGB-to-RGB transforms, defined as
// FN[InputColorSpace][OutputColorSpace] callback functions.
final fn = <ColorSpace,dynamic>{
	ColorSpace.srgb: { 
    ColorSpace.linear: Color.srgbToLinear,
    'transfer': SRGBTransfer,
    'primaries': Rec709Primaries,
		'toReference': (Color color ) => color.convertSRGBToLinear(),
		'fromReference': (Color color ) => color.convertLinearToSRGB(),
  },
	ColorSpace.linear: { 
    ColorSpace.srgb: Color.linearToSRGB ,
    'transfer': LinearTransfer,
    'primaries': Rec709Primaries,
		'toReference': (Color color ) => color,
		'fromReference': (Color color ) => color,
  },
	ColorSpace.dp3: { 
    ColorSpace.dp3: Color.srgbToLinear,
    'transfer': SRGBTransfer,
    'primaries': P3Primaries,
		'toReference': (Color color ) => color.convertSRGBToLinear().applyMatrix3( ldp32lsrgb ),
		'fromReference': (Color color ) => color.applyMatrix3( lsrgb2ldp3 ).convertLinearToSRGB(),
  },
	ColorSpace.ldp3: { 
    ColorSpace.ldp3: Color.linearToSRGB ,
    'transfer': LinearTransfer,
    'primaries': P3Primaries,
		'toReference': (Color color ) => color.applyMatrix3( ldp32lsrgb ),
		'fromReference': (Color color ) => color.applyMatrix3( lsrgb2ldp3 ),
  },
};

class ColorManagement {
	static bool legacyMode = true;

	static ColorSpace get workingColorSpace {
		return ColorSpace.linear;
	}

  @Deprecated('ColorManagement: .workingColorSpace is readonly.')
	static set workingColorSpace( colorSpace ) {}

	static Color convert(Color color, ColorSpace? sourceColorSpace, ColorSpace? targetColorSpace){
		if(
      legacyMode || 
      sourceColorSpace == targetColorSpace || 
      sourceColorSpace == null || 
      targetColorSpace == null
    ) {
			return color;
		}

		if (
      fn[sourceColorSpace] != null && 
      fn[sourceColorSpace]![targetColorSpace] != null
    ){
			final fnC = fn[sourceColorSpace]![targetColorSpace]!;

			color.storage[0] = fnC(color.red);
			color.storage[1] = fnC(color.green);
			color.storage[2] = fnC(color.blue);

			return color;
		}

		throw( 'Unsupported color space conversion.' );
	}

	static Color fromWorkingColorSpace(Color color, ColorSpace? targetColorSpace){
		return convert(color, workingColorSpace, targetColorSpace);
	}

	static Color toWorkingColorSpace(Color color, ColorSpace? sourceColorSpace){
		return convert(color, sourceColorSpace, workingColorSpace);
	}

	static String? getPrimaries(ColorSpace colorSpace ) {
    //if(colorSpace == ColorSpace.no) return null;
		return fn[colorSpace]['primaries'];
	}

	static String getTransfer(ColorSpace colorSpace) {
		if (colorSpace == ColorSpace.no) return LinearTransfer;
		return fn[colorSpace]!['transfer'];
	}
}