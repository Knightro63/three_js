/*
 In options, we can specify:
 * Texture parameters for an auto-generated target texture
 * depthBuffer/stencilBuffer: Booleans to indicate if we should generate these buffers
*/
// import "package:universal_html/html.dart";

part of three_renderers;

class RenderTarget with EventDispatcher {
  bool _didDispose = false;
  late int width;
  late int height;
  int depth = 1;

  late bool depthBuffer;
  late bool resolveDepthBuffer;
  late bool resolveStencilBuffer;
  // bool isWebGLCubeRenderTarget = false;
  // bool isWebGL3DRenderTarget = false;
  // bool isWebGLArrayRenderTarget = false;
  bool isXRRenderTarget = false;
  // bool isWebGLMultipleRenderTargets = false;

  List<Texture> textures = [];
  //late Texture _texture;
  late Vector4 scissor;
  late bool scissorTest;
  late Vector4 viewport;

  late bool stencilBuffer;
  DepthTexture? depthTexture;

  late int _samples;
  late WebGLRenderTargetOptions options;

  int get samples => _samples;

  set samples(int value) {
    console.warning("Important warn: make sure set samples before setRenderTarget  ");
    _samples = value;
  }

	Texture get texture => textures[0];

	set texture(Texture value ) {
    if(textures.isEmpty){
      textures.add(value);
    }
    else{
		  textures[0] = value;
    }
	}


  RenderTarget(this.width, this.height, [WebGLRenderTargetOptions? options]):super(){
    scissor = Vector4(0, 0, width.toDouble(), height.toDouble());
    scissorTest = false;

    viewport = Vector4(0, 0, width.toDouble(), height.toDouble());

    this.options = options ?? WebGLRenderTargetOptions();

    final image = ImageElement(width: width, height: height, depth: 1);

    final texture = Texture(
      image, 
      this.options.mapping, 
      this.options.wrapS, 
      this.options.wrapT, 
      this.options.magFilter,
      this.options.minFilter, 
      this.options.format, 
      this.options.type, 
      this.options.anisotropy, 
      this.options.encoding
    );
    
    texture.isRenderTargetTexture = true;
    texture.flipY = false;
    texture.generateMipmaps = this.options.generateMipmaps;
    texture.internalFormat = this.options.internalFormat;
    texture.minFilter = this.options.minFilter != null ? this.options.minFilter! : LinearFilter;
		textures = [];

		final count = this.options.count;
		for (int i = 0; i < count; i ++ ) {
			textures.add(texture.clone());
			textures[i].isRenderTargetTexture = true;
		}
    
    depthBuffer = this.options.depthBuffer != null ? this.options.depthBuffer! : true;
    stencilBuffer = this.options.stencilBuffer;
    depthTexture = this.options.depthTexture;

		resolveDepthBuffer = this.options.resolveDepthBuffer;
		resolveStencilBuffer = this.options.resolveStencilBuffer;

    _samples = (options != null && options.samples != null) ? options.samples! : 0;
  }

  RenderTarget clone() {
    return RenderTarget(1,1).copy( this );
  }

  RenderTarget copy(RenderTarget source){
		height = source.height;
    width = source.width;
		depth = source.depth;

		scissor.setFrom( source.scissor );
		scissorTest = source.scissorTest;

		viewport.setFrom( source.viewport );

		textures.length = 0;

		for (int i = 0, il = source.textures.length; i < il; i ++ ) {
			textures.add(source.textures[ i ].clone());
			textures[ i ].isRenderTargetTexture = true;
		}

		// ensure image object is not shared, see #20328

		final image = source.texture.image;
		texture.source = Source( image );

		depthBuffer = source.depthBuffer;
		stencilBuffer = source.stencilBuffer;

		resolveDepthBuffer = source.resolveDepthBuffer;
		resolveStencilBuffer = source.resolveStencilBuffer;

		if ( source.depthTexture != null ) depthTexture = source.depthTexture!.clone();

		samples = source.samples;

		return this;
  }

  void setSize(int width, int height, [int depth = 1]) {
    if (this.width != width || this.height != height || this.depth != depth) {
      this.width = width;
      this.height = height;
      this.depth = depth;

			for (int i = 0, il = textures.length; i < il; i ++ ) {
				textures[ i ].image.width = width;
				textures[ i ].image.height = height;
				textures[ i ].image.depth = depth;
			}

      dispose();
    }

    viewport.setValues(0, 0, width.toDouble(), height.toDouble());
    scissor.setValues(0, 0, width.toDouble(), height.toDouble());
  }

  bool is3D() {
    throw ("RenderTarget is3D need implemnt ");
  }

  void dispose() {
    dispatchEvent(Event(type: "dispose"));
  }
}

class WebGLRenderTarget extends RenderTarget {
  bool isWebGLRenderTarget = true;
  WebGLRenderTarget(super.width, super.height, [super.options]);

  @override
  WebGLRenderTarget clone() {
    return WebGLRenderTarget(width, height, options).copy(this);
  }

  @override
  WebGLRenderTarget copy(RenderTarget source) {
    super.copy(source);
    return this;
  }

  @override
  bool is3D() {
    return texture is Data3DTexture || texture is DataArrayTexture;
  }

  @override
  void dispose() {
    if(_didDispose) return;
    _didDispose = true;
    dispatchEvent(Event(type: "dispose"));
    depthTexture?.dispose();
    texture.dispose();
    options.dispose();
  }
}

class WebGLRenderTargetOptions {
  int? wrapS;
  int? wrapT;
  int? wrapR;
  int? magFilter;
  int? minFilter;
  int? format;
  int? type;
  int? anisotropy;
  bool? depthBuffer;
  int? mapping;

  bool stencilBuffer = false;
  bool generateMipmaps = false;
  DepthTexture? depthTexture;
  int? encoding;

  bool useMultisampleRenderToTexture = false;
  bool ignoreDepth = false;
  bool useRenderToTexture = false;

  int? samples;
  int? internalFormat;
  int count = 1;

  bool resolveDepthBuffer = false;
  bool resolveStencilBuffer = false;

  void dispose(){
    depthTexture?.dispose();
    depthTexture = null;
  }

  WebGLRenderTargetOptions([Map<String, dynamic>? json]) {
    json ??= {};
    if (json["wrapS"] != null) {
      wrapS = json["wrapS"];
    }
    if(json['count'] != null){
      count = json['count'];
    }
    if(json['resolveDepthBuffer'] != null){
      resolveDepthBuffer = json['resolveDepthBuffer'];
    }
    if(json['resolveStencilBuffer'] != null){
      resolveStencilBuffer = json['resolveStencilBuffer'];
    }
    if(json['internalFormat'] != null){
      internalFormat = json['internalFormat'];
    }
    if (json["wrapT"] != null) {
      wrapT = json["wrapT"];
    }
    if (json["wrapR"] != null) {
      wrapR = json["wrapR"];
    }
    if (json["magFilter"] != null) {
      magFilter = json["magFilter"];
    }
    if (json["minFilter"] != null) {
      minFilter = json["minFilter"];
    }
    if (json["format"] != null) {
      format = json["format"];
    }
    if (json["type"] != null) {
      type = json["type"];
    }
    if (json["anisotropy"] != null) {
      anisotropy = json["anisotropy"];
    }
    if (json["depthBuffer"] != null) {
      depthBuffer = json["depthBuffer"];
    }
    if (json["mapping"] != null) {
      mapping = json["mapping"];
    }
    if (json["generateMipmaps"] != null) {
      generateMipmaps = json["generateMipmaps"];
    }
    if (json["depthTexture"] != null) {
      depthTexture = json["depthTexture"];
    }
    if (json["encoding"] != null) {
      encoding = json["encoding"];
    }
    if (json["useMultisampleRenderToTexture"] != null) {
      useMultisampleRenderToTexture = json["useMultisampleRenderToTexture"];
    }
    if (json["ignoreDepth"] != null) {
      ignoreDepth = json["ignoreDepth"];
    }
    if (json["useRenderToTexture"] != null) {
      useRenderToTexture = json["useRenderToTexture"];
    }

    samples = json["samples"];
  }

  Map<String, dynamic> toJson() {
    return {
      "wrapS": wrapS,
      "wrapT": wrapT,
      "wrapR": wrapR,
      "magFilter": magFilter,
      "minFilter": minFilter,
      'internalFormat': internalFormat,
      "format": format,
      'count': count,
      "type": type,
      'resolveStencilBuffer': resolveStencilBuffer,
      'resolveDepthBuffer': resolveDepthBuffer,
      "anisotropy": anisotropy,
      "depthBuffer": depthBuffer,
      "mapping": mapping,
      "stencilBuffer": stencilBuffer,
      "generateMipmaps": generateMipmaps,
      "depthTexture": depthTexture,
      "encoding": encoding,
      "useMultisampleRenderToTexture": useMultisampleRenderToTexture,
      "ignoreDepth": ignoreDepth,
      "useRenderToTexture": useRenderToTexture,
      "samples": samples
    };
  }
}
