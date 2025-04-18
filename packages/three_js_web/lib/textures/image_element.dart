import 'package:three_js_math/three_js_math.dart';

class ImageElement {
  String? uuid;
  dynamic url;
  late num width;
  late num height;
  String? src;
  bool complete = true;

  // NativeArray or ImageElement from dart:html
  dynamic data;
  int depth;

  ImageElement({
    this.url,
    this.src,
    this.data,
    this.width = 0,
    this.height = 0,
    this.depth = 0,
  });

  void dispose() {
    if(data is NativeArray){
      data?.dispose();
    }
  }

  @override
  String toString(){
    return {
      'uuid': uuid,
      'widht': width,
      'height': height,
      'src': src,
      'complete': complete,
      'depth': depth,
      "data": data.runtimeType
    }.toString();
  }
}
