import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gl/flutter_gl.dart';
import 'package:three_js/three_js.dart' as three;

class webgl_loader_gltf extends StatefulWidget {
  String fileName;
  webgl_loader_gltf({Key? key, required this.fileName}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<webgl_loader_gltf> {
  late FlutterGlPlugin three3dRender;
  three.WebGLRenderer? renderer;

  int? fboId;
  late double width;
  late double height;

  Size? screenSize;

  late three.Scene scene;
  late three.Camera camera;
  late three.Mesh mesh;

  double dpr = 1.0;

  var AMOUNT = 4;

  bool verbose = false;
  bool disposed = false;

  late three.Object3D object;

  late three.Texture texture;
  late three.TextureLoader textureLoader;
  final GlobalKey<three.PeripheralsState> _globalKey = GlobalKey<three.PeripheralsState>();
  late three.OrbitControls controls;
  three.WebGLRenderTarget? renderTarget;

  dynamic sourceTexture;

  @override
  void initState() {
    super.initState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    width = screenSize!.width;
    height = screenSize!.height;

    three3dRender = FlutterGlPlugin();

    Map<String, dynamic> _options = {
      "antialias": true,
      "alpha": false,
      "width": width.toInt(),
      "height": height.toInt(),
      "dpr": dpr,
      'precision': 'highp'
    };

    await three3dRender.initialize(options: _options);

    setState(() {});

    // TODO web wait dom ok!!!
    Future.delayed(const Duration(milliseconds: 100), () async {
      await three3dRender.prepareContext();

      initScene();
    });
  }

  initSize(BuildContext context) {
    if (screenSize != null) {
      return;
    }

    final mqd = MediaQuery.of(context);

    screenSize = mqd.size;
    dpr = mqd.devicePixelRatio;

    initPlatformState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.fileName),
      ),
      body: Builder(
        builder: (BuildContext context) {
          initSize(context);
          return _build(context);
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Text("render"),
        onPressed: () {
          render();
        },
      ),
    );
  }

  Widget _build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: three.Peripherals(
        key: _globalKey,
        builder: (BuildContext context) {
          return Container(
            width: width,
            height: height,
            color: Theme.of(context).canvasColor,
            child: Builder(builder: (BuildContext context) {
              if (kIsWeb) {
                return three3dRender.isInitialized
                    ? HtmlElementView(
                        viewType:
                            three3dRender.textureId!.toString())
                    : Container();
              } else {
                return three3dRender.isInitialized
                    ? Texture(textureId: three3dRender.textureId!)
                    : Container();
              }
            })
          );
        }),
    );
  }

  render() {
    int _t = DateTime.now().millisecondsSinceEpoch;
    renderer!.clear(true, true, true);
    final _gl = three3dRender.gl;

    renderer!.render(scene, camera);

    int _t1 = DateTime.now().millisecondsSinceEpoch;

    if (verbose) {
      print("render cost: ${_t1 - _t} ");
      print(renderer!.info.memory);
      print(renderer!.info.render);
    }

    // 重要 更新纹理之前一定要调用 确保gl程序执行完毕
    _gl.flush();
    controls.update();
    if (verbose) print(" render: sourceTexture: $sourceTexture ");

    if (!kIsWeb) {
      three3dRender.updateTexture(sourceTexture);
    }
  }

  initRenderer() {
    Map<String, dynamic> _options = {
      "width": width,
      "height": height,
      "gl": three3dRender.gl,
      "antialias": true,
      "canvas": three3dRender.element,
      "alpha": true,
      "clearColor": 0xffffff,
      "clearAlpha": 0,
    };

    if(!kIsWeb){
      _options['logarithmicDepthBuffer'] = true;
    }

    renderer = three.WebGLRenderer(_options);
    renderer!.setPixelRatio(dpr);
    renderer!.setSize(width, height, false);
    renderer!.shadowMap.enabled = true;

    renderer!.shadowMap.enabled = false;
    renderer!.alpha = true;
    renderer!.setClearColor(three.Color.fromHex32(0xffffff), 0);
    renderer!.autoClearDepth = true;
    renderer!.autoClearStencil = true;
    renderer!.autoClear = true;
    // renderer!.toneMapping = three.ACESFilmicToneMapping;
    // renderer!.toneMappingExposure = 1;
    // renderer!.outputEncoding = three.sRGBEncoding;

    if (!kIsWeb) {
      var pars = three.WebGLRenderTargetOptions({"format": three.RGBAFormat,"samples": 4});
      renderTarget = three.WebGLRenderTarget((width * dpr).toInt(), (height * dpr).toInt(), pars);
      renderTarget!.samples = 4;
      renderer!.setRenderTarget(renderTarget);
      sourceTexture = renderer!.getRenderTargetGLTexture(renderTarget!);
    }
    else {
      renderTarget = null;
    }
  }

  void initScene() async{
    await initPage();
    initRenderer();
    animate();
  }

  initPage() async {
    scene = three.Scene();

    camera = three.PerspectiveCamera(45, width / height, 0.25, 20);
    camera.position.setValues( - 0, 0, 2.7 );
    camera.lookAt(scene.position);

    three.OrbitControls _controls = three.OrbitControls(camera, _globalKey);
    controls = _controls;

    three.RGBELoader _loader = three.RGBELoader();
    _loader.setPath('assets/textures/equirectangular/');
    var _hdrTexture = await _loader.fromAsset('royal_esplanade_1k.hdr');
    _hdrTexture?.mapping = three.EquirectangularReflectionMapping;

    scene.background = _hdrTexture;
    scene.environment = _hdrTexture;

    scene.add( three.AmbientLight( 0xffffff ) );

    three.GLTFLoader loader = three.GLTFLoader()
        .setPath('assets/models/gltf/DamagedHelmet/glTF/');

    var result = await loader.fromAsset('DamagedHelmet.gltf');

    print(" gltf load sucess result: $result  ");

    object = result!.scene;

    // var geometry = new three.PlaneGeometry(2, 2);
    // var material = new three.MeshBasicMaterial();

    // object.traverse( ( child ) {
    //   if ( child is three.Mesh ) {
    //     material.map = child.material.map;
    //   }
    // } );

    // var mesh = new three.Mesh(geometry, material);
    // scene.add(mesh);

    // object.traverse( ( child ) {
    //   if ( child.isMesh ) {
    // child.material.map = texture;
    //   }
    // } );



    scene.add(object);
    textureLoader = three.TextureLoader(null);
    // scene.overrideMaterial = new three.MeshBasicMaterial();
  }

  animate() {
    if (!mounted || disposed) {
      return;
    }

    render();

    Future.delayed(Duration(milliseconds: 40), () {
      animate();
    });
  }
  @override
  void dispose() {
    
    print(" dispose ............. ");
    disposed = true;
    three.loading = {};
    controls.clearListeners();
    three3dRender.dispose();
    print(" dispose finish ");
    super.dispose();
  }
}
