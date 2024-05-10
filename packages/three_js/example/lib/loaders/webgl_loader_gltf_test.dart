import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gl/flutter_gl.dart';
import 'package:three_js/three_js.dart' as three;

class webgl_loader_gltf_test extends StatefulWidget {
  String fileName;
  webgl_loader_gltf_test({Key? key, required this.fileName}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<webgl_loader_gltf_test> {
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

  var amount = 4;

  bool verbose = false;
  bool disposed = false;

  late three.Object3D object;

  late three.Texture texture;

  late three.WebGLMultisampleRenderTarget renderTarget;

  dynamic? sourceTexture;

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
      "dpr": dpr
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
          return SingleChildScrollView(child: _build(context));
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
    return Column(
      children: [
        Container(
          child: Stack(
            children: [
              Container(
                  width: width,
                  height: height,
                  color: Colors.black,
                  child: Builder(builder: (BuildContext context) {
                    if (kIsWeb) {
                      return three3dRender.isInitialized
                          ? HtmlElementView(
                              viewType: three3dRender.textureId!.toString())
                          : Container();
                    } else {
                      return three3dRender.isInitialized
                          ? Texture(textureId: three3dRender.textureId!)
                          : Container();
                    }
                  })),
            ],
          ),
        ),
      ],
    );
  }

  render() {
    int _t = DateTime.now().millisecondsSinceEpoch;

    final _gl = three3dRender.gl;

    renderer!.render(scene, camera);

    int _t1 = DateTime.now().millisecondsSinceEpoch;

    if (verbose) {
      print("render cost: ${_t1 - _t} ");
      print(renderer!.info.memory);
      print(renderer!.info.render);
    }

    
    _gl.flush();

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
      "canvas": three3dRender.element
    };
    renderer = three.WebGLRenderer(_options);
    renderer!.setPixelRatio(dpr);
    renderer!.setSize(width, height, false);
    renderer!.shadowMap.enabled = false;

    if (!kIsWeb) {
      var pars = three.WebGLRenderTargetOptions({"format": three.RGBAFormat});
      renderTarget = three.WebGLMultisampleRenderTarget(
          (width * dpr).toInt(), (height * dpr).toInt(), pars);
      renderTarget.samples = 4;
      renderer!.setRenderTarget(renderTarget);
      sourceTexture = renderer!.getRenderTargetGLTexture(renderTarget);
    }
  }

  initScene() {
    initRenderer();
    initPage();
  }

  initPage() async {
    camera = three.PerspectiveCamera(45, width / height, 0.25, 20);
    camera.position.setValues(-1.8, 0.6, 2.7);

    // scene

    scene = three.Scene();

    var ambientLight = three.AmbientLight(0xcccccc, 0.4);
    scene.add(ambientLight);

    var pointLight = three.PointLight(0xffffff, 0.8);

    pointLight.position.setValues(0, 0, 18);

    scene.add(pointLight);
    scene.add(camera);

    camera.lookAt(scene.position);

    var _loader = three.RGBELoader(null);
    _loader.setPath('assets/textures/equirectangular/');
    var _hdrTexture = await _loader.fromAsset('royal_esplanade_1k.hdr');

    _hdrTexture?.mapping = three.EquirectangularReflectionMapping;

    // print("_hdrTexture 1: ${_hdrTexture} ");
    // print("_hdrTexture 2: ${_hdrTexture.image} ");
    // print("_hdrTexture 3: ${_hdrTexture.image.data} ");
    // print("_hdrTexture 3: ${_hdrTexture.image.data.toDartList()} ");

    scene.background = _hdrTexture;
    scene.environment = _hdrTexture;

    var textureLoader = three.TextureLoader();
    texture = (await textureLoader.fromAsset('assets/textures/uv_grid_directx.jpg'))!;

    texture.magFilter = three.LinearFilter;
    texture.minFilter = three.LinearMipmapLinearFilter;
    texture.generateMipmaps = true;
    texture.needsUpdate = true;

    // var loader = three.GLTFLoader( null ).setPath( 'assets/models/gltf/DamagedHelmet/glTF/' );
    var loader = three.GLTFLoader().setPath('assets/models/gltf/test/');

    var result = await loader.fromAsset('animate7.gltf');

    object = result!.scene;

    // object.traverse( ( child ) {
    //   if ( child.isMesh ) {
    // child.material.map = texture;
    //   }
    // } );

    scene.add(object);

    // scene.overrideMaterial = new three.MeshBasicMaterial();

    animate();
  }

  animate() {
    if (!mounted || disposed) {
      return;
    }

    render();

    // Future.delayed(Duration(milliseconds: 40), () {
    //   animate();
    // });
  }

  @override
  void dispose() {
    print(" dispose ............. ");
    disposed = true;
    three3dRender.dispose();

    super.dispose();
  }
}
