import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:three_js_advanced_loaders/usd/ucdc_parser.dart';
import 'package:three_js_advanced_loaders/usd/usd_composer.dart';
import 'package:three_js_advanced_loaders/usd/usda_parser.dart';
import 'package:three_js_advanced_loaders/usdz/usdz_zip.dart';
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_core_loaders/three_js_core_loaders.dart';

/// A loader for the USD format (USD, USDA, USDC, USDZ).
///
/// Supports both ASCII (USDA) and binary (USDC) USD files, as well as
/// USDZ archives containing either format.
///
/// ```dart
/// final loader = UsdLoader();
/// final model = await loader.loadAsync('model.usdz');
/// scene.add(model);
/// ```
class USDLoader extends Loader {
  late final FileLoader _loader;

	USDLoader([super.manager]){
		_loader = FileLoader(manager);
  }

  @override
  void dispose(){
    super.dispose();
    _loader.dispose();
  }
  
  void _init(){
		_loader.setPath(path);
		_loader.setResponseType('arraybuffer');
		_loader.setRequestHeader(requestHeader);
		_loader.setWithCredentials(withCredentials);
  }

  @override
  Future<Group?> fromNetwork(Uri uri) async{
    _init();
    ThreeFile? tf = await _loader.fromNetwork(uri);
    return tf == null?null:_parse(tf.data);
  }
  @override
  Future<Group> fromFile(File file) async{
    _init();
    ThreeFile tf = await _loader.fromFile(file);
    return _parse(tf.data);
  }
  @override
  Future<Group?> fromPath(String filePath) async{
    _init();
    ThreeFile? tf = await _loader.fromPath(filePath);
    return tf == null?null:_parse(tf.data);
  }
  @override
  Future<Group> fromBlob(Blob blob) async{
    _init();
    ThreeFile tf = await _loader.fromBlob(blob);
    return _parse(tf.data);
  }
  @override
  Future<Group?> fromAsset(String asset, {String? package}) async{
    _init();
    ThreeFile? tf = await _loader.fromAsset(asset,package: package);
    return tf == null?null:_parse(tf.data);
  }
  @override
  Future<Group> fromBytes(Uint8List bytes) async{
    _init();
    ThreeFile tf = await _loader.fromBytes(bytes);
    return _parse(tf.data);
  }

  /// Parses the given USDZ data and returns the resulting group.
  ///
  /// The returned group is created synchronously, but any referenced textures
  /// are loaded asynchronously. Provide [onLoad] to be notified once all
  /// textures have finished loading.
  ///
  /// [bytes] `Uint8List`.
  /// Returns the parsed asset as a [Group].
  Future<Group> _parse(Uint8List bytes) async{
    final usda = USDAParser();
    final usdc = USDCParser();

    Uint8List toUint8List(dynamic data) {
      if (data is Uint8List) return data;
      if (data is ByteBuffer) return data.asUint8List();
      if (data is List<int>) return Uint8List.fromList(data);
      throw ArgumentError('Unsupported binary format');
    }

    String getLowercaseExtension(String filename) {
      final int lastDot = filename.lastIndexOf('.');
      if (lastDot < 0) return '';
      final int lastSlash = filename.lastIndexOf('/');
      if (lastSlash > lastDot) return '';
      return filename.substring(lastDot + 1).toLowerCase();
    }

    bool isCrateFile(Uint8List fileBuffer) {
      final List<int> crateHeader = [0x50, 0x58, 0x52, 0x2D, 0x55, 0x53, 0x44, 0x43]; // PXR-USDC
      if (fileBuffer.length < crateHeader.length) return false;
      for (int i = 0; i < crateHeader.length; i++) {
        if (fileBuffer[i] != crateHeader[i]) return false;
      }
      return true;
    }

    bool isAsciiFile(Uint8List fileBuffer) {
      final List<String> crateHeader = ['#','u', 's', 'd', 'a']; // #usda

      if (fileBuffer.length < crateHeader.length) return false;
      for (int i = 0; i < crateHeader.length; i++) {
        final char = String.fromCharCode(fileBuffer[i]);
        if (char != crateHeader[i]) return false;
      }
      return true;
    }

    Map<String, dynamic> parseAssets(Map<String, dynamic> zip) {
      final Map<String, dynamic> data = {};
      for (final String filename in zip.keys) {
        final dynamic fileBytes = zip[filename];
        final String ext = getLowercaseExtension(filename);

        if (ext == 'png' || ext == 'jpg' || ext == 'jpeg' || ext == 'avif') {
          // Keep raw image bytes and create object URLs lazily in USDComposer.
          data[filename] = fileBytes;
          continue;
        }

        if (ext != 'usd' && ext != 'usda' && ext != 'usdc') continue;

        if (isCrateFile(fileBytes)) {
          data[filename] = usdc.parseData(toUint8List(fileBytes));
        } else {
          data[filename] = usda.parseData(utf8.decode(toUint8List(fileBytes)));
        }
      }
      return data;
    }

    Map<String, dynamic> findUSD(Map<String, dynamic> zip) {
      final List<String> fileNames = zip.keys.toList();
      if (fileNames.isEmpty) {
        return {'file': null, 'filename': '', 'basePath': ''};
      }

      final String firstFileName = fileNames[0];
      final String ext = getLowercaseExtension(firstFileName);
      bool isCrate = false;
      final int lastSlash = firstFileName.lastIndexOf('/');
      final String basePath = lastSlash >= 0 ? firstFileName.substring(0, lastSlash) : '';

      // Per AOUSD core spec v1.0.1 section 16.4.1.2, the first ZIP entry is the root layer.
      // ASCII files can end in either .usda or .usd.
      if (ext == 'usda') {
        return {'file': zip[firstFileName], 'filename': firstFileName, 'basePath': basePath};
      }

      if (ext == 'usdc') {
        isCrate = true;
      } else if (ext == 'usd') {
        if (!isCrateFile(zip[firstFileName])) {
          return {'file': zip[firstFileName], 'filename': firstFileName, 'basePath': basePath};
        } else {
          isCrate = true;
        }
      }

      if (isCrate) {
        return {'file': zip[firstFileName], 'filename': firstFileName, 'basePath': basePath};
      }

      return {'file': null, 'filename': '', 'basePath': ''};
    }

    Future<Group> finalize(USDComposer composer, Group group) async{
      await Future.wait(composer.texturePromises).then((_) {});
      return group;
    }

    // USDC (standalone Binary Crate)
    if (isCrateFile(bytes)) {
      final composer = USDComposer(manager);
      final Map<String, dynamic> data = usdc.parseData(bytes);
      return await finalize(composer, composer.compose(data, basePath: path));
    }

    // USDA (standalone String)
    if (isAsciiFile(bytes)) {
      final composer = USDComposer(manager);
      final Map<String, dynamic> data = usda.parseData(String.fromCharCodes(bytes));
      return await finalize(composer, composer.compose(data, basePath: path));
    }

    // USDZ (ZIP package identifier check)
    if (bytes.isNotEmpty && bytes[0] == 0x50 && bytes[1] == 0x4B) {
      final Map<String, dynamic> zip = USDZIP.unzip(bytes);//unzipSync(bytes); // Assumed utility matching your framework
      final Map<String, dynamic> assets = parseAssets(zip);
      final Map<String, dynamic> usdInfo = findUSD(zip);

      final dynamic file = usdInfo['file'];
      final String filename = usdInfo['filename'] ?? '';
      final String basePath = usdInfo['basePath'] ?? '';

      if (file == null) {
        throw StateError('THREE.USDLoader: Invalid USDZ package. The first ZIP entry must be a USD layer (.usd/.usda/.usdc).');
      }

      final composer = USDComposer(manager);
      final dynamic data = assets[filename];
      if (data == null) {
        throw StateError('THREE.USDLoader: Failed to parse root layer "$filename".');
      }

      return await finalize(composer, composer.compose(data, assets: assets, basePath: basePath));
    }

    // USDA (standalone, as ArrayBuffer bytes layout fallback)
    final composer = USDComposer(manager);
    final String text = utf8.decode(bytes);
    final Map<String, dynamic> data = usda.parseData(text);
    return await finalize(composer, composer.compose(data, basePath: path));
  }
}