import 'dart:math' as math;
import 'dart:typed_data';
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_helpers/utils/buffer_geometry_utils.dart';
import 'package:three_js_math/three_js_math.dart';

/// A helper that can be used to display any type of texture for
/// debugging purposes. Depending on the type of texture (2D, 3D, Array),
/// the helper becomes a plane or box mesh.
class TextureHelper extends Mesh {
  late dynamic texture;

  TextureHelper(
    this.texture, {
    double width = 1.0,
    double height = 1.0,
    double depth = 1.0,
  }) : super() {
    type = 'TextureHelper';

    final String samplerType = _getSamplerType(texture);
    final double alphaValue = _getAlpha(texture);

    final String vertexShader = [
      'attribute vec3 uvw;',
      'varying vec3 vUvw;',
      'void main() {',
      '  vUvw = uvw;',
      '  gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );',
      '}',
    ].join('\n');

    final String fragmentShader = [
      'precision highp float;',
      'precision highp sampler2DArray;',
      'precision highp sampler3D;',
      'uniform $samplerType map;',
      'uniform float alpha;',
      'varying vec3 vUvw;',
      'vec4 textureHelper( in sampler2D map ) { return texture( map, vUvw.xy ); }',
      'vec4 textureHelper( in sampler2DArray map ) { return texture( map, vUvw ); }',
      'vec4 textureHelper( in sampler3D map ) { return texture( map, vUvw ); }',
      'vec4 textureHelper( in samplerCube map ) { return texture( map, vUvw ); }',
      'void main() {',
      '  gl_FragColor = linearToOutputTexel( vec4( textureHelper( map ).xyz, alpha ) );',
      '}'
    ].join('\n');

    final material = ShaderMaterial.fromMap({
      'type': 'TextureHelperMaterial',
      'side': DoubleSide,
      'transparent': true,
      'uniforms': {
        'map': {'value': texture},
        'alpha': {'value': alphaValue},
      },
      'vertexShader': vertexShader,
      'fragmentShader': fragmentShader,
    });

    final bool isCube = _checkProperty(texture, 'isCubeTexture');
    
    final BufferGeometry targetGeometry = isCube
        ? _createCubeGeometry(width, height, depth)
        : _createSliceGeometry(texture, width, height, depth);

    geometry = targetGeometry;
    this.material = material;
  }

  @override
  void dispose() {
    geometry?.dispose();
    material?.dispose();
    super.dispose();
  }
}

/// Helper to safely inspect optional/dynamic JavaScript style booleans on Texture classes
bool _checkProperty(dynamic obj, String property) {
  if (obj == null) return false;
  try {
    // Falls back to runtime evaluation if reflection properties match
    if (property == 'isCubeTexture') return obj.isCubeTexture == true;
    if (property == 'isDataArrayTexture') return obj.isDataArrayTexture == true;
    if (property == 'isCompressedArrayTexture') return obj.isCompressedArrayTexture == true;
    if (property == 'isData3DTexture') return obj.isData3DTexture == true;
    if (property == 'isCompressed3DTexture') return obj.isCompressed3DTexture == true;
  } catch (_) {}
  return false;
}

String _getSamplerType(dynamic texture) {
  if (_checkProperty(texture, 'isCubeTexture')) {
    return 'samplerCube';
  } else if (_checkProperty(texture, 'isDataArrayTexture') || _checkProperty(texture, 'isCompressedArrayTexture')) {
    return 'sampler2DArray';
  } else if (_checkProperty(texture, 'isData3DTexture') || _checkProperty(texture, 'isCompressed3DTexture')) {
    return 'sampler3D';
  } else {
    return 'sampler2D';
  }
}

int _getImageCount(dynamic texture) {
  if (_checkProperty(texture, 'isCubeTexture')) {
    return 6;
  } else if (_checkProperty(texture, 'isDataArrayTexture') || 
             _checkProperty(texture, 'isCompressedArrayTexture') || 
             _checkProperty(texture, 'isData3DTexture') || 
             _checkProperty(texture, 'isCompressed3DTexture')) {
    return texture.image?.depth?.toInt() ?? 1;
  } else {
    return 1;
  }
}

double _getAlpha(dynamic texture) {
  if (_checkProperty(texture, 'isCubeTexture')) {
    return 1.0;
  } else if (_checkProperty(texture, 'isDataArrayTexture') || 
             _checkProperty(texture, 'isCompressedArrayTexture') || 
             _checkProperty(texture, 'isData3DTexture') || 
             _checkProperty(texture, 'isCompressed3DTexture')) {
    final int depth = texture.image?.depth?.toInt() ?? 1;
    return math.max(1.0 / depth, 0.25);
  } else {
    return 1.0;
  }
}

BufferGeometry _createCubeGeometry(double width, double height, double depth) {
  final geometry = BoxGeometry(width, height, depth);
  final BufferAttribute position = geometry.attributes['position']!;
  final BufferAttribute uv = geometry.attributes['uv']!;
  
  final Float32List arrayBuffer = Float32List(uv.count * 3);
  final uvw = Float32BufferAttribute.fromList(arrayBuffer, 3);
  final _direction = Vector3();

  for (int j = 0; j < uv.count; ++j) {
    _direction.fromBuffer(position, j).normalize();
    uvw.setXYZ(j, _direction.x, _direction.y, _direction.z);
  }

  geometry.deleteAttributeFromString('uv');
  geometry.setAttributeFromString('uvw', uvw);
  return geometry;
}

BufferGeometry _createSliceGeometry(Texture texture, double width, double height, double depth) {
  final int sliceCount = _getImageCount(texture);
  final List<BufferGeometry> geometries = [];

  for (int i = 0; i < sliceCount; ++i) {
    final geometry = PlaneGeometry(width, height);
    
    if (sliceCount > 1) {
      geometry.translate(0.0, 0.0, depth * (i / (sliceCount - 1.0) - 0.5));
    }

    final BufferAttribute uv = geometry.attributes['uv']!;
    final Float32List arrayBuffer = Float32List(uv.count * 3);
    final uvw = Float32BufferAttribute.fromList(arrayBuffer, 3);

    final bool flipY = texture.flipY == true;
    final bool isArrayTex = _checkProperty(texture, 'isDataArrayTexture') || _checkProperty(texture, 'isCompressedArrayTexture');

    for (int j = 0; j < uv.count; ++j) {
      final double u = uv.getX(j)!.toDouble();
      final double rawV = uv.getY(j)!.toDouble();
      final double v = flipY ? rawV : 1.0 - rawV;
      
      double w;
      if (sliceCount == 1) {
        w = 1.0;
      } else if (isArrayTex) {
        w = i.toDouble();
      } else {
        w = i / (sliceCount - 1.0);
      }

      uvw.setXYZ(j, u, v, w);
    }

    geometry.deleteAttributeFromString('uv');
    geometry.setAttributeFromString('uvw', uvw);
    geometries.add(geometry);
  }

  // Uses the native BufferGeometryUtils package method inside three_js
  return BufferGeometryUtils.mergeGeometries(geometries)!;
}
