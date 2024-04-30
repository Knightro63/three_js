class ImageElement {
  String? uuid;
  dynamic url;
  late num width;
  late num height;
  String? src;
  bool complete = true;

  // NativeArray or ImageElement from dart:html
  dynamic data;
  int depth = 1;

  ImageElement({
    this.url,
    this.data,
    this.width = 1,
    this.height = 1,
    this.depth = 1,
  });

  void dispose() {
    data?.dispose();
  }

  @override
  String toString(){
    return {
      'uuid': uuid,
      'widht': width,
      'height': height,
      'src': src,
      'complete': complete,
      'depth': depth
    }.toString();
  }
}
