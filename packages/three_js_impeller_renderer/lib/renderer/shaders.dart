import 'package:flutter_gpu/gpu.dart' as gpu;

const String _kShaderBundlePath = 'packages/three_js_impeller_renderer/build/shaderbundles/TestLibrary.shaderbundle';
// NOTE: If you're building a library, the path must be prefixed
//       with a package name. For example:
//      'packages/my_cool_renderer/build/shaderbundles/my_renderer.shaderbundle'

gpu.ShaderLibrary? _shaderLibrary;
gpu.ShaderLibrary get shaderLibrary {
  if (_shaderLibrary != null) {
    return _shaderLibrary!;
  }
  _shaderLibrary = gpu.ShaderLibrary.fromAsset(_kShaderBundlePath);
  if (_shaderLibrary != null) {
    return _shaderLibrary!;
  }

  throw Exception("Failed to load shader bundle! ($_kShaderBundlePath)");
}