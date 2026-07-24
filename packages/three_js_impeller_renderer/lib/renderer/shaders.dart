import 'package:flutter_gpu/gpu.dart' as gpu;

gpu.ShaderLibrary? _shaderLibrary;
gpu.ShaderLibrary shaderLibrary(String bundle,{String? package}) {
  String path = 'build/shaderbundles/$bundle.shaderbundle';
  if(package != null){
    path = 'packages/$package/build/shaderbundles/$bundle.shaderbundle';
  }
  if (_shaderLibrary != null) {
    return _shaderLibrary!;
  }
  _shaderLibrary = gpu.ShaderLibrary.fromAsset(path);
  if (_shaderLibrary != null) {
    return _shaderLibrary!;
  }

  throw Exception("Failed to load shader bundle! ($path)");
}