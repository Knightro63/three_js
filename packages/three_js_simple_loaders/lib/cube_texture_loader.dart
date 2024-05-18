import 'dart:async';
import 'dart:typed_data';
import 'dart:io';
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_core_loaders/three_js_core_loaders.dart';

class CubeTextureLoader extends Loader {
  late final ImageLoader _loader;
  final texture = CubeTexture();
  int loaded = 0;

  /// [manager] — The [loadingManager] for the loader to use. Default is [DefaultLoadingManager].
	CubeTextureLoader([super.manager]){
		_loader = ImageLoader( manager );
    texture.image = [];
  }

  @override
  void dispose(){
    super.dispose();
    _loader.dispose();
  }
  
  void _init(){
		_loader.setPath(path);
		//_loader.setResponseType('arraybuffer');
		_loader.setRequestHeader(requestHeader);
		_loader.setWithCredentials(withCredentials);
  }

  Future<CubeTexture?> fromNetworkList(List<Uri> uri) async{
    _init();
		for ( int i = 0; i < uri.length; ++ i ) {
			await fromNetwork(uri[i]);
		}
		return texture;
  }

  Future<CubeTexture> fromFileList(List<File> file) async{
    _init();
		for ( int i = 0; i < file.length; ++ i ) {
			await fromFile(file[i]);
		}
		return texture;
  }

  Future<CubeTexture?> fromPathList(List<String> filePath) async{
    _init();
		for ( int i = 0; i < filePath.length; ++ i ) {
			await fromPath(filePath[i]);
		}
		return texture;
  }

  Future<CubeTexture> fromBlobList(List<Blob> blob) async{
    _init();
		for ( int i = 0; i < blob.length; ++ i ) {
			await fromBlob(blob[i]);
		}
		return texture;
  }

  Future<CubeTexture?> fromAssetList(List<String> asset, {String? package}) async{
    _init();
		for ( int i = 0; i < asset.length; ++ i ) {
			await fromAsset(asset[i],package:package);
		}
		return texture;
  }

  Future<CubeTexture> fromBytesList(List<Uint8List> bytes) async{
    _init();
		for ( int i = 0; i < bytes.length; ++ i ) {
			await fromBytes(bytes[i]);
		}
		return texture;
  }

  @override
  Future<CubeTexture?> fromNetwork(Uri uri) async{
    final image = await _loader.fromNetwork(uri);
    texture.images.add(image);
    loaded ++;

    if ( loaded == 6 ) {
      texture.needsUpdate = true;
      return texture;
    }
    return null;
  }
  @override
  Future<CubeTexture?> fromFile(File file) async{
    final image = await _loader.fromFile(file);
    texture.images.add(image);
    loaded ++;

    if ( loaded == 6 ) {
      texture.needsUpdate = true;
      return texture;
    }
    return null;
  }
  @override
  Future<CubeTexture?> fromPath(String filePath) async{
    final image = await _loader.fromPath(filePath);
    texture.images.add(image);
    loaded ++;

    if ( loaded == 6 ) {
      texture.needsUpdate = true;
      return texture;
    }
    return null;
  }
  @override
  Future<CubeTexture?> fromBlob(Blob blob) async{
    final image = await _loader.fromBlob(blob);
    texture.images.add(image);
    loaded ++;

    if ( loaded == 6 ) {
      texture.needsUpdate = true;
      return texture;
    }
    return null;
  }
  @override
  Future<CubeTexture?> fromAsset(String asset, {String? package}) async{
    final image = await _loader.fromAsset(asset,package: package);
    texture.images.add(image);
    loaded ++;

    if ( loaded == 6 ) {
      texture.needsUpdate = true;
      return texture;
    }
    return null;
  }
  @override
  Future<CubeTexture?> fromBytes(Uint8List bytes) async{
    final image = await _loader.fromBytes(bytes);
    texture.images.add(image);
    loaded ++;

    if ( loaded == 6 ) {
      texture.needsUpdate = true;
      return texture;
    }
    return null;
  }
}
