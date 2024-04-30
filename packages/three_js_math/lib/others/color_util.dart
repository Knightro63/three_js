import 'dart:typed_data';
import 'package:flutter_gl/flutter_gl.dart';
import 'dart:math' as math;

enum ColorSpace{linear,srgb}

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
    storage = Float32List.fromList(list);
  }
  Color.fromHex64(int hex){
    int alpha = (0xff000000 & hex) >> 32;
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

  int getHex() {
    return (red * 255).toInt() << 16 ^
        (green * 255).toInt() << 8 ^
        (blue * 255).toInt() << 0;
  }

  Color fromNativeArray(List<num> list,[int offset = 0]) {
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
  NativeArray<num> copyIntoArray(NativeArray<num> array, [int offset = 0]) {
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

  Color toLinear() {
    storage[0] = srgbToLinear(red);
    storage[1] = srgbToLinear(green);
    storage[2] = srgbToLinear(blue);
    return this;
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
}

// JavaScript RGB-to-RGB transforms, defined as
// FN[InputColorSpace][OutputColorSpace] callback functions.
final fn = {
	ColorSpace.srgb: { 
    ColorSpace.linear: Color.srgbToLinear 
  },
	ColorSpace.linear: { 
    ColorSpace.srgb: Color.linearToSRGB 
  },
};

class ColorManagement {
	static bool legacyMode = true;

	static get workingColorSpace {
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
}