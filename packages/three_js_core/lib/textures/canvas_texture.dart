import './texture.dart';

class CanvasTexture extends Texture {
  bool isCanvasTexture = true;

  CanvasTexture([
    super.canvas,
    super.mapping, 
    super.wrapS, 
    super.wrapT, 
    super.magFilter, 
    super.minFilter, 
    super.format,
    super.type, 
    super.anisotropy
  ]){
    needsUpdate = true;
  }
}
