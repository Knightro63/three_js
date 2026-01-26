part of three_renderers;

class ImpellerRendererParameters{
  double width;
  double height;
  bool stencil;
  bool antialias;
  bool alpha;
  int clearColor;
  double clearAlpha;
  bool logarithmicDepthBuffer;
  bool premultipliedAlpha;
  bool preserveDrawingBuffer;
  PowerPreference powerPreference;
  bool reverseDepthBuffer;
  bool failIfMajorPerformanceCaveat;
  bool depth = true;
  Precision precision;
  ui.Canvas canvas;
  XRManager Function(ImpellerRenderer renderer, dynamic gl)? xr;

  ImpellerRendererParameters({
    required this.width,
    required this.height,
    this.stencil = true,
    this.antialias = false,
    this.alpha = false,
    this.clearAlpha = 1.0,
    this.clearColor = 0x000000,
    this.logarithmicDepthBuffer = false,
    this.depth = true,
    this.premultipliedAlpha = true,
    this.preserveDrawingBuffer = false,
    this.powerPreference = PowerPreference.defaultp,
    this.failIfMajorPerformanceCaveat = false,
    this.reverseDepthBuffer = false,
    this.precision = Precision.highp,
    required this.canvas,
    this.xr,
  });

  factory ImpellerRendererParameters.fromMap(Map<String,dynamic> map){
    return ImpellerRendererParameters(
      width: map["width"].toDouble(),
      height: map["height"].toDouble(),
      depth: map["depth"] ?? true,
      stencil: map["stencil"] ?? true,
      antialias: map["antialias"] ?? false,
      premultipliedAlpha: map["premultipliedAlpha"] ?? true,
      preserveDrawingBuffer: map["preserveDrawingBuffer"] ?? false,
      powerPreference: map["powerPreference"] ?? "default",
      failIfMajorPerformanceCaveat: map["failIfMajorPerformanceCaveat"] ?? false,
      alpha: map["alpha"] ?? false,
      canvas: map["canvas"],
      xr: map["xr"],
      precision: map['precision'],
      reverseDepthBuffer: map['reverseDepthBuffer']
    );
  }
}

class ImpellerRenderer extends Renderer{
  late final ImpellerRendererParameters parameters;

  late final ui.Canvas _canvas;

  bool antialias = false;

  // clearing

  bool autoClear = true;
  bool autoClearColor = true;
  bool autoClearDepth = true;
  bool autoClearStencil = true;

  late double _width;
  late double _height;

  double get width => _width;
  double get height => _height;

  late final ui.Rect _viewport;
  late final ui.Rect _scissor;

  bool _isContextLost = false;

  ImpellerRenderer(this.parameters){
    _width = this.parameters.width;
    _height = this.parameters.height;

    antialias = this.parameters.antialias;
    
    _viewport = ui.Rect.fromLTWH(0, 0, width, height);
    _scissor = ui.Rect.fromLTWH(0, 0, width, height);

    _canvas = this.parameters.canvas;
  }

  @override
  void dispose() {
    // TODO: implement dispose
  }

  @override
  void render(Object3D scene, Camera camera) {
    if (_isContextLost) return;

    if (scene.matrixWorldAutoUpdate) scene.updateMatrixWorld();
    
    if (camera.parent == null && camera.matrixWorldAutoUpdate) camera.updateMatrixWorld();

    if ( xr.enabled && xr.isPresenting ) {
      if (xr.cameraAutoUpdate) xr.updateCamera( camera );
    	if(kIsWeb) camera = xr.getCamera();
    }

    if (scene is Scene) {
      scene.onBeforeRender?.call(renderer: this, scene: scene, camera: camera, renderTarget: _currentRenderTarget);
    }

    final drawArea = _canvas.getLocalClipBounds();
    if (drawArea.isEmpty) {
      return;
    }
    final enableMsaa = antialias;
    final gpu.RenderTarget renderTarget = surface.getNextRenderTarget(
      drawArea.size,
      enableMsaa,
    );

    final env =
        environment.environmentMap.isEmpty()
            ? environment.withNewEnvironmentMap(
              Material.getDefaultEnvironmentMap(),
            )
            : environment;

    final encoder = SceneEncoder(renderTarget, camera, drawArea.size, env);
    root.render(encoder, Matrix4.identity());
    encoder.finish();

    final gpu.Texture texture =
        enableMsaa
            ? renderTarget.colorAttachments[0].resolveTexture!
            : renderTarget.colorAttachments[0].texture;
    final image = texture.asImage();
    _canvas.drawImage(image, drawArea.topLeft, ui.Paint());
  }

  @override
  void clear([bool color = true, bool depth = true, bool stencil = true]){

  }

  @override
  void setRenderTarget(RenderTarget? renderTarget, [int activeCubeFace = 0, int activeMipmapLevel = 0]){

  }

  @override
  RenderTarget? getRenderTarget(){
    return null;
  }
}
