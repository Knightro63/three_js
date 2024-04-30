/// Fake Blob for fit web code when in App & Desktop
///
/// TODO
class Blob {
  dynamic data;
  late Map<String, dynamic> options;

  Blob(this.data, this.options);
}

/// TODO
createObjectURL(blob) {
  return blob;
}
