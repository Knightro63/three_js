import 'image_element.dart';
import './texture.dart';

class DataTexture extends Texture {
  DataTexture([
    data,
    int? width,
    int? height,
    int? format,
    int? type,
    int? mapping,
    int? wrapS,
    int? wrapT,
    int? magFilter,
    int? minFilter,
    int? anisotropy,
    int? encoding
  ]):super(null, mapping, wrapS, wrapT, magFilter, minFilter, format, type, anisotropy, encoding) {
    image = ImageElement(data: data, width: width ?? 1, height: height ?? 1);

    generateMipmaps = false;
    flipY = false;
    unpackAlignment = 1;
  }

  factory DataTexture.fromMap(Map<String,dynamic> map){
    return DataTexture(
      map['data'],
      map['width'],
      map['height'],
      map['format'],
      map['type'],
      map['mapping'],
      map['wrapS'],
      map['wrapT'],
      map['magFilter'],
      map['minFilter'],
      map['anisotropy'],
      map['encoding']
    );
  }
}
