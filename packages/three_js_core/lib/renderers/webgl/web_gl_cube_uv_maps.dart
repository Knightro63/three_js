part of three_webgl;

class WebGLCubeUVMaps {
  WeakMap cubeUVmaps = WeakMap();
  WebGLRenderer renderer;
  PMREMGenerator? pmremGenerator;

  WebGLCubeUVMaps(this.renderer);

  Texture? get(Texture? texture) {
    if (texture != null) {
      final mapping = texture.mapping;

      bool isEquirectMap = (mapping == EquirectangularReflectionMapping || mapping == EquirectangularRefractionMapping);
      bool isCubeMap = (mapping == CubeReflectionMapping || mapping == CubeRefractionMapping);

      // equirect/cube map to cubeUV conversion
      if (isEquirectMap || isCubeMap) {
        if (texture.isRenderTargetTexture && texture.needsPMREMUpdate == true) {
          texture.needsPMREMUpdate = false;

          dynamic renderTarget = cubeUVmaps.get(texture);

          pmremGenerator ??= PMREMGenerator(renderer);

          renderTarget = isEquirectMap
              ? pmremGenerator!.fromEquirectangular(texture, renderTarget)
              : pmremGenerator!.fromCubemap(texture, renderTarget);
          cubeUVmaps.add(key: texture, value: renderTarget);

          return renderTarget.texture;
        } else {
          if (cubeUVmaps.has(texture)) {
            return cubeUVmaps.get(texture).texture;
          } else {
            final image = texture.image;

            if ((isEquirectMap && image != null && image.height > 0) ||
                (isCubeMap && image != null && isCubeTextureComplete(image))) {
              pmremGenerator ??= PMREMGenerator(renderer);

              final renderTarget =
                  isEquirectMap ? pmremGenerator!.fromEquirectangular(texture) : pmremGenerator!.fromCubemap(texture);
              cubeUVmaps.add(key: texture, value: renderTarget);

              texture.addEventListener('dispose', onTextureDispose);

              return renderTarget.texture;
            } else {
              // image not yet ready. try the conversion next frame

              return null;
            }
          }
        }
      }
    }

    return texture;
  }

  bool isCubeTextureComplete(image) {
    int count = 0;
    const length = 6;

    for (int i = 0; i < length; i++) {
      if (image[i] != null) count++;
    }

    return count == length;
  }

  void onTextureDispose(event) {
    final texture = event.target;
    texture.removeEventListener('dispose', onTextureDispose);

    final cubemapUV = cubeUVmaps.get(texture);

    if (cubemapUV != null) {
      cubemapUV.delete(texture);
      cubemapUV.dispose();
    }
  }

  void dispose() {
    for(final key in cubeUVmaps.keys){
      cubeUVmaps[key].dispose();
    }
    cubeUVmaps.clear();

    //if (pmremGenerator != null) {
      pmremGenerator?.dispose();
      pmremGenerator = null;
    //}
  }
}
