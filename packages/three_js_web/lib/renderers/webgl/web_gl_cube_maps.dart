part of three_webgl;

class WebGLCubeMaps {
  bool _didDispose = false;
  WebGLRenderer renderer;
  WeakMap cubemaps = WeakMap();

  WebGLCubeMaps(this.renderer);

  Texture mapTextureMapping(Texture texture, int? mapping) {
    if (mapping == EquirectangularReflectionMapping) {
      texture.mapping = CubeReflectionMapping;
    } 
    else if (mapping == EquirectangularRefractionMapping) {
      texture.mapping = CubeRefractionMapping;
    }
    return texture;
  }

  Texture? get(Texture? texture) {
    if (texture != null && !texture.isRenderTargetTexture) {
      final mapping = texture.mapping;

      if (mapping == EquirectangularReflectionMapping || mapping == EquirectangularRefractionMapping) {
        if (cubemaps.has(texture)) {
          final cubemap = cubemaps.get(texture).texture;
          return mapTextureMapping(cubemap, texture.mapping);
        } 
        else {
          final image = texture.image;

          if (image != null && image.height > 0) {
            final renderTarget = WebGLCubeRenderTarget(image.height ~/ 2);
            renderTarget.fromEquirectangularTexture(renderer, texture);
            cubemaps.add(key: texture, value: renderTarget);

            texture.addEventListener('dispose', onTextureDispose);

            return mapTextureMapping(renderTarget.texture, texture.mapping);
          } 
          else {
            // image not yet ready. try the conversion next frame
            return null;
          }
        }
      }
    }

    return texture;
  }

  void onTextureDispose(event) {
    final texture = event.target;

    texture.removeEventListener('dispose', onTextureDispose);

    final cubemap = cubemaps.get(texture);

    if (cubemap != null) {
      cubemaps.delete(texture);
      cubemap.dispose();
    }
  }

  void dispose() {
    if(_didDispose) return;
    _didDispose = true;
    for(final key in cubemaps.keys){
      cubemaps[key].dispose();
    }
    cubemaps.clear();
    renderer.dispose();
  }
}
