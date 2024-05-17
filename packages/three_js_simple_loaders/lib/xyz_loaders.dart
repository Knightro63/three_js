import 'dart:io';
import 'dart:typed_data';

import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_core_loaders/three_js_core_loaders.dart';
import 'package:three_js_math/three_js_math.dart';

class XYZLoader extends Loader {
  late final FileLoader _loader;

  /// [manager] — The [loadingManager] for the loader to use. Default is [DefaultLoadingManager].
	XYZLoader([super.manager]){
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
  Future<BufferGeometry?> fromNetwork(Uri uri) async{
    _init();
    ThreeFile? tf = await _loader.fromNetwork(uri);
    return tf == null?null:_parse(tf.data);
  }
  @override
  Future<BufferGeometry> fromFile(File file) async{
    _init();
    ThreeFile tf = await _loader.fromFile(file);
    return _parse(tf.data);
  }
  @override
  Future<BufferGeometry?> fromPath(String filePath) async{
    _init();
    ThreeFile? tf = await _loader.fromPath(filePath);
    return tf == null?null:_parse(tf.data);
  }
  @override
  Future<BufferGeometry> fromBlob(Blob blob) async{
    _init();
    ThreeFile tf = await _loader.fromBlob(blob);
    return _parse(tf.data);
  }
  @override
  Future<BufferGeometry?> fromAsset(String asset, {String? package}) async{
    _init();
    ThreeFile? tf = await _loader.fromAsset(asset,package: package);
    return tf == null?null:_parse(tf.data);
  }
  @override
  Future<BufferGeometry> fromBytes(Uint8List bytes) async{
    _init();
    ThreeFile tf = await _loader.fromBytes(bytes);
    return _parse(tf.data);
  }

	BufferGeometry _parse(Uint8List bytes) {
    String text = String.fromCharCodes(bytes);

		final lines = text.split( '\n' );

		final List<double> vertices = [];
		final List<double> colors = [];
		final color = Color();

		for (String line in lines ) {
			line = line.trim();

			if (line[0] == '#') continue; // skip comments

			final lineValues = line.split(RegExp(r"\s+"));

			if ( lineValues.length == 3 ) {
				vertices.add( double.parse(lineValues[0]));
				vertices.add( double.parse(lineValues[1]));
				vertices.add( double.parse(lineValues[2]));
			}

			if ( lineValues.length == 6 ) {
				vertices.add( double.parse(lineValues[0]));
				vertices.add( double.parse(lineValues[1]));
				vertices.add( double.parse(lineValues[2]));

				final r = double.parse(lineValues[3]) / 255;
				final g = double.parse(lineValues[4]) / 255;
				final b = double.parse(lineValues[5]) / 255;

				color..setValues( r, g, b )..convertSRGBToLinear();
				colors.addAll([ color.red, color.green, color.blue ]);
			}
		}

		final geometry = BufferGeometry();
		geometry.setAttributeFromString( 'position', Float32BufferAttribute.fromList( vertices, 3 ) );

		if ( colors.isNotEmpty) {
			geometry.setAttributeFromString( 'color', Float32BufferAttribute.fromList( colors, 3 ) );
		}

		return geometry;
	}
}
