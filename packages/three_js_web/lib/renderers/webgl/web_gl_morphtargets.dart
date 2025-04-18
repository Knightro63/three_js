part of three_webgl;

int numericalSort(a, b) {
  return a[0] - b[0];
}

int absNumericalSort(a, b) {
  return b[1].abs() >= a[1].abs() ? 1 : -1;
}

void denormalize(Vector morph, BufferAttribute attribute) {
  double denominator = 1;
  NativeArray array = attribute is InterleavedBufferAttribute ? attribute.data!.array : attribute.array;

  if (array is Int8Array) {
    denominator = 127;
  } 
  else if (array is Int16Array) {
    denominator = 32767;
  } 
  else if (array is Int32Array) {
    denominator = 2147483647;
  } 
  else {
    console.error('three.WebGLMorphtargets: Unsupported morph attribute data type: $array');
  }

  morph.divideScalar(denominator);
}

class WebGLMorphtargets {
  bool _didDispose = false;
  final influencesList = {};
  final morphInfluences = Float32List(8);
  final morphTextures = WeakMap();
  final morph = Vector4.zero();

  List<List<num>> workInfluences = [];

  RenderingContext gl;
  WebGLCapabilities capabilities;
  WebGLTextures textures;

  WebGLMorphtargets(this.gl, this.capabilities, this.textures) {
    for (int i = 0; i < 8; i++) {
      workInfluences.add([i, 0]);
    }
  }

  void dispose(){
    if(_didDispose) return;
    _didDispose = true;
    influencesList.clear();
    morphTextures.dispose();
    workInfluences.clear();
    capabilities.dispose();
    textures.dispose();
  }

  void update(Object3D object, BufferGeometry geometry, WebGLProgram program) {
    List<num>? objectInfluences = object.morphTargetInfluences;

    final morphAttribute = geometry.morphAttributes["position"] ?? geometry.morphAttributes["normal"] ?? geometry.morphAttributes["color"];
    final morphTargetsCount = (morphAttribute != null) ? morphAttribute.length : 0;

    Map? entry = morphTextures.get(geometry);

    if (entry == null || (entry["count"] != morphTargetsCount)) {
      if (entry != null) entry["texture"].dispose();

      final hasMorphPosition = geometry.morphAttributes["position"] != null;
      final hasMorphNormals = geometry.morphAttributes["normal"] != null;
      final hasMorphColors = geometry.morphAttributes["color"] != null;

      final morphTargets = geometry.morphAttributes["position"] ?? [];
      final morphNormals = geometry.morphAttributes["normal"] ?? [];
      final morphColors = geometry.morphAttributes["color"] ?? [];

      int vertexDataCount = 0;
      if (hasMorphPosition) vertexDataCount = 1;
      if (hasMorphNormals) vertexDataCount = 2;
      if (hasMorphColors) vertexDataCount = 3;

      int width = (geometry.attributes["position"].count * vertexDataCount).toInt();
      int height = 1;

      if (width > capabilities.maxTextureSize) {
        height = (width / capabilities.maxTextureSize).ceil();
        width = capabilities.maxTextureSize.toInt();
      }

      final buffer = Float32Array((width * height * 4 * morphTargetsCount).toInt());

      final texture = DataArrayTexture(buffer, width, height, morphTargetsCount);
      texture.type = FloatType;
      texture.needsUpdate = true;

      int vertexDataStride = vertexDataCount * 4;

      for (int i = 0; i < morphTargetsCount; i++) {
        final morphTarget = morphTargets[i];

        int offset = (width * height * 4 * i).toInt();

        for (int j = 0; j < morphTarget.count; j++) {
          final stride = j * vertexDataStride;

          if (hasMorphPosition) {
            morph.fromBuffer(morphTarget, j);

            buffer[offset + stride + 0] = morph.x;
            buffer[offset + stride + 1] = morph.y;
            buffer[offset + stride + 2] = morph.z;
            buffer[offset + stride + 3] = 0;
          }

          if (hasMorphNormals) {
            final morphNormal = morphNormals[i];
            morph.fromBuffer(morphNormal, j);

            buffer[offset + stride + 4] = morph.x;
            buffer[offset + stride + 5] = morph.y;
            buffer[offset + stride + 6] = morph.z;
            buffer[offset + stride + 7] = 0;
          }

          if (hasMorphColors) {
            final morphColor = morphColors[i];
            morph.fromBuffer(morphColor, j);

            buffer[offset + stride + 8] = morph.x;
            buffer[offset + stride + 9] = morph.y;
            buffer[offset + stride + 10] = morph.z;
            buffer[offset + stride + 11] = ((morphColor.itemSize == 4) ? morph.w : 1);
          }
        }
      }

      entry = {"count": morphTargetsCount, "texture": texture, "size": Vector2(width.toDouble(), height.toDouble())};

      morphTextures.set(geometry, entry);

      void disposeTexture(event) {
        texture.dispose();
        morphTextures.delete(geometry);
        geometry.removeEventListener('dispose', disposeTexture);
      }

      geometry.addEventListener('dispose', disposeTexture);
    }

		if ( object is InstancedMesh && object.morphTexture != null ) {
			program.getUniforms().setValue( gl, 'morphTexture', object.morphTexture, textures );
		} 
    else {
      double morphInfluencesSum = 0;

      for (int i = 0; i < objectInfluences.length; i++) {
        morphInfluencesSum += objectInfluences[i];
      }

      final morphBaseInfluence = geometry.morphTargetsRelative ? 1 : 1 - morphInfluencesSum;
      program.getUniforms().setValue(gl, 'morphTargetBaseInfluence', morphBaseInfluence);
      program.getUniforms().setValue(gl, 'morphTargetInfluences', objectInfluences);
    }
    
    program.getUniforms().setValue(gl, 'morphTargetsTexture', entry["texture"], textures);
    program.getUniforms().setValue(gl, 'morphTargetsTextureSize', entry["size"]);
  }
}
