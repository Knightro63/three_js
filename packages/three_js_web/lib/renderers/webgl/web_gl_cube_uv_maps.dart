part of three_webgl;

class WebGLCubeUVMaps {
  bool _didDispose = false;
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
        RenderTarget? renderTarget = cubeUVmaps.get( texture );
				final currentPMREMVersion = renderTarget != null ? renderTarget.texture.pmremVersion : 0;

        if (texture.isRenderTargetTexture && texture.pmremVersion != currentPMREMVersion) {
					if ( pmremGenerator == null ) pmremGenerator = new PMREMGenerator( renderer );

					renderTarget = isEquirectMap ? pmremGenerator?.fromEquirectangular( texture, renderTarget ) : pmremGenerator?.fromCubemap( texture, renderTarget );
					renderTarget?.texture.pmremVersion = texture.pmremVersion;

					cubeUVmaps.set( texture, renderTarget );

					return renderTarget?.texture;
        } 
        else {
          if (renderTarget != null) {
            return renderTarget.texture;
          } 
          else {
            final image = texture.image;

            if ((isEquirectMap && image != null && image.height > 0) ||
                (isCubeMap && image != null && isCubeTextureComplete(image))) {
              pmremGenerator ??= PMREMGenerator(renderer);

              renderTarget = isEquirectMap ? pmremGenerator!.fromEquirectangular(texture) : pmremGenerator!.fromCubemap(texture);
              cubeUVmaps.set(texture, renderTarget);

              texture.addEventListener('dispose', onTextureDispose);

              return renderTarget.texture;
            } 
            else {
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
    if(_didDispose) return;
    _didDispose = true;
    for(final key in cubeUVmaps.keys){
      cubeUVmaps[key].dispose();
    }
    cubeUVmaps.clear();

    //if (pmremGenerator != null) {
      pmremGenerator?.dispose();
      pmremGenerator = null;
    //}

    renderer.dispose();
  }
}
