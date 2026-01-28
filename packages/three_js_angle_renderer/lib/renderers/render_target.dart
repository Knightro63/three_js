// /*
//  In options, we can specify:
//  * Texture parameters for an auto-generated target texture
//  * depthBuffer/stencilBuffer: Booleans to indicate if we should generate these buffers
// */

// part of three_renderers;

// class AngleRenderTarget extends RenderTarget {
//   bool _didDispose = false;
  
//   AngleRenderTarget(super.width, super.height, [super.options]);

//   @override
//   AngleRenderTarget clone() {
//     return AngleRenderTarget(width, height, options)..copy(this);
//   }

//   @override
//   AngleRenderTarget copy(RenderTarget source) {
//     super.copy(source);
//     return this;
//   }

//   @override
//   bool is3D() {
//     return texture is Data3DTexture || texture is DataArrayTexture;
//   }

//   @override
//   void dispose() {
//     if(_didDispose) return;
//     _didDispose = true;
//     dispatchEvent(Event(type: "dispose"));
//     depthTexture?.dispose();
//     texture.dispose();
//     options.dispose();

//     // textures.forEach((t){
//     //   t.dispose();
//     // });
//     // textures.clear();
//   }
// }