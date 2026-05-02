class ImageElement {
  String? uuid;
  dynamic url;
  late num width;
  late num height;
  String? src;
  bool complete = true;

  // TypedeData or ImageElement
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

  void dispose() {}

  @override
  String toString(){
    return {
      'uuid': uuid,
      'width': width,
      'height': height,
      'src': src,
      'complete': complete,
      'depth': depth,
      "data": data.runtimeType
    }.toString();
  }
}
