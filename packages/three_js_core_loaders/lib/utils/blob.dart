/// Fake Blob for fit web code when in App & Desktop
///
class Blob {
  dynamic data;
  late Map<String, dynamic> options;
  Blob(this.data, this.options);
}

dynamic createObjectURL(dynamic blob) {
  return blob;
}
