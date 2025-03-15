part of three_shaders;

List cloneUniformsGroups<T>( src ) {
	final dst = <T>[];

	for (int u = 0; u < src.length; u ++ ) {
		dst.add( src[ u ].clone() );
	}
	return dst;
}

Map<String, dynamic> cloneUniforms(Map<String, dynamic> src) {
  final dst = <String, dynamic>{};

  for (final u in src.keys) {
    dst[u] = <String,dynamic>{};

    for (final p in src[u].keys) {
      final property = src[u][p];

      if (property != null &&
          (property is Color ||
              property is Matrix3 ||
              property is Matrix4 ||
              property is Vector2 ||
              property is Vector3 ||
              property is Vector4 ||
              property is Texture ||
              property is Quaternion)) {
        dst[u][p] = property.clone();
      } else if (property is List) {
        dst[u][p] = property.sublist(0);
      } else {
        dst[u][p] = property;
      }
    }
  }

  return dst;
}

Map<String, dynamic> mergeUniforms(uniforms) {
  Map<String, dynamic> merged = <String, dynamic>{};

  for (int u = 0; u < uniforms.length; u++) {
    final tmp = cloneUniforms(uniforms[u]);

    for (final p in tmp.keys) {
      merged[p] = tmp[p];
    }
  }

  return merged;
}

String getUnlitUniformColorSpace(WebGLRenderer renderer ) {
	final currentRenderTarget = renderer.getRenderTarget();

	if ( currentRenderTarget == null ) {
		return renderer.outputColorSpace;
	}

	if (currentRenderTarget.isXRRenderTarget) {
		return currentRenderTarget.texture.colorSpace;
	}
	return ColorManagement.workingColorSpace.toString();
}


class UniformsUtils {
  static Map<String, dynamic> clone(Map<String, dynamic> p) {
    return cloneUniforms(p);
  }

  static Map<String, dynamic> merge(p) {
    return mergeUniforms(p);
  }
}
