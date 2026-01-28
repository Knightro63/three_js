// /*
//  In options, we can specify:
//  * Texture parameters for an auto-generated target texture
//  * depthBuffer/stencilBuffer: Booleans to indicate if we should generate these buffers
// */
// // import "package:universal_html/html.dart";

// part of three_renderers;

// class WebGLRenderTarget extends RenderTarget {
//   bool isWebGLRenderTarget = true;
//   bool _didDispose = false;
//   WebGLRenderTarget(super.width, super.height, [super.options]);

//   @override
//   WebGLRenderTarget clone() {
//     return WebGLRenderTarget(width, height, options).copy(this);
//   }

//   @override
//   WebGLRenderTarget copy(RenderTarget source) {
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
//   }
// }

// // class WebGLRenderTargetOptions {
// //   int? wrapS;
// //   int? wrapT;
// //   int? wrapR;
// //   int? magFilter;
// //   int? minFilter;
// //   int? format;
// //   int? type;
// //   int? anisotropy;
// //   bool? depthBuffer;
// //   int? mapping;

// //   bool stencilBuffer = false;
// //   bool generateMipmaps = false;
// //   DepthTexture? depthTexture;
// //   int? encoding;

// //   bool useMultisampleRenderToTexture = false;
// //   bool ignoreDepth = false;
// //   bool useRenderToTexture = false;

// //   int? samples;
// //   int? internalFormat;
// //   int count = 1;

// //   bool resolveDepthBuffer = false;
// //   bool resolveStencilBuffer = false;

// //   void dispose(){
// //     depthTexture?.dispose();
// //     depthTexture = null;
// //   }

// //   WebGLRenderTargetOptions([Map<String, dynamic>? json]) {
// //     json ??= {};
// //     if (json["wrapS"] != null) {
// //       wrapS = json["wrapS"];
// //     }
// //     if(json['count'] != null){
// //       count = json['count'];
// //     }
// //     if(json['resolveDepthBuffer'] != null){
// //       resolveDepthBuffer = json['resolveDepthBuffer'];
// //     }
// //     if(json['resolveStencilBuffer'] != null){
// //       resolveStencilBuffer = json['resolveStencilBuffer'];
// //     }
// //     if(json['internalFormat'] != null){
// //       internalFormat = json['internalFormat'];
// //     }
// //     if (json["wrapT"] != null) {
// //       wrapT = json["wrapT"];
// //     }
// //     if (json["wrapR"] != null) {
// //       wrapR = json["wrapR"];
// //     }
// //     if (json["magFilter"] != null) {
// //       magFilter = json["magFilter"];
// //     }
// //     if (json["minFilter"] != null) {
// //       minFilter = json["minFilter"];
// //     }
// //     if (json["format"] != null) {
// //       format = json["format"];
// //     }
// //     if (json["type"] != null) {
// //       type = json["type"];
// //     }
// //     if (json["anisotropy"] != null) {
// //       anisotropy = json["anisotropy"];
// //     }
// //     if (json["depthBuffer"] != null) {
// //       depthBuffer = json["depthBuffer"];
// //     }
// //     if (json["mapping"] != null) {
// //       mapping = json["mapping"];
// //     }
// //     if (json["generateMipmaps"] != null) {
// //       generateMipmaps = json["generateMipmaps"];
// //     }
// //     if (json["depthTexture"] != null) {
// //       depthTexture = json["depthTexture"];
// //     }
// //     if (json["encoding"] != null) {
// //       encoding = json["encoding"];
// //     }
// //     if (json["useMultisampleRenderToTexture"] != null) {
// //       useMultisampleRenderToTexture = json["useMultisampleRenderToTexture"];
// //     }
// //     if (json["ignoreDepth"] != null) {
// //       ignoreDepth = json["ignoreDepth"];
// //     }
// //     if (json["useRenderToTexture"] != null) {
// //       useRenderToTexture = json["useRenderToTexture"];
// //     }

// //     samples = json["samples"];
// //   }

// //   Map<String, dynamic> toJson() {
// //     return {
// //       "wrapS": wrapS,
// //       "wrapT": wrapT,
// //       "wrapR": wrapR,
// //       "magFilter": magFilter,
// //       "minFilter": minFilter,
// //       'internalFormat': internalFormat,
// //       "format": format,
// //       'count': count,
// //       "type": type,
// //       'resolveStencilBuffer': resolveStencilBuffer,
// //       'resolveDepthBuffer': resolveDepthBuffer,
// //       "anisotropy": anisotropy,
// //       "depthBuffer": depthBuffer,
// //       "mapping": mapping,
// //       "stencilBuffer": stencilBuffer,
// //       "generateMipmaps": generateMipmaps,
// //       "depthTexture": depthTexture,
// //       "encoding": encoding,
// //       "useMultisampleRenderToTexture": useMultisampleRenderToTexture,
// //       "ignoreDepth": ignoreDepth,
// //       "useRenderToTexture": useRenderToTexture,
// //       "samples": samples
// //     };
// //   }
// // }
