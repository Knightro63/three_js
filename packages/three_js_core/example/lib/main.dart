import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_gl/flutter_gl.dart';
import 'package:three_js_core/three_js_core.dart' as three;
import 'package:three_js_math/three_js_math.dart' as tmath;
import 'dart:math' as math;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const WebglGeometries(),
    );
  }
}


class WebglGeometries extends StatefulWidget {
  const WebglGeometries({super.key});
  @override
  createState() => _State();
}

class _State extends State<WebglGeometries> {
  late FlutterGlPlugin three3dRender;
  three.WebGLRenderer? renderer;

  int? fboId;
  late double width;
  late double height;

  Size? screenSize;

  late three.Scene scene;
  late three.Camera camera;
  late three.Mesh mesh;

  three.Clock clock = three.Clock();

  double dpr = 1.0;

  final int amount = 4;

  bool verbose = false;
  bool disposed = false;

  late three.Object3D object;

  late three.Texture texture;

  int startTime = 0;

  late three.WebGLMultisampleRenderTarget renderTarget;

  dynamic sourceTexture;

  bool loaded = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    print(" dispose ............. ");
    disposed = true;
    three3dRender.dispose();
    super.dispose();
  }


  void initSize(BuildContext context) async {
    if(screenSize != null){
      return;
    }

    final mqd = MediaQuery.of(context);
    screenSize = mqd.size;
    width = screenSize!.width;
    height = screenSize!.height;
    dpr = mqd.devicePixelRatio;

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

    Future.delayed(const Duration(milliseconds: 100), () async {
      await three3dRender.prepareContext();
      initScene();
    });
  }

  void render() {
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

  void initRenderer() {
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
    renderer!.shadowMap.enabled = true;
    renderer!.localClippingEnabled = true;

    if (!kIsWeb) {
      final pars = three.WebGLRenderTargetOptions({"format": tmath.RGBAFormat});
      renderTarget = three.WebGLMultisampleRenderTarget((width * dpr).toInt(), (height * dpr).toInt(), pars);
      renderTarget.samples = 4;
      renderer!.setRenderTarget(renderTarget);
      sourceTexture = renderer!.getRenderTargetGLTexture(renderTarget);
    }
  }

  Future<void> initScene() async{
    initRenderer();
    await initPage();
  }

  Future<void> initPage() async {
    camera = three.PerspectiveCamera(45, width / height, 1, 2000);
    camera.position.y = 200;

    scene = three.Scene();

    three.Mesh object;

    final ambientLight = three.AmbientLight(0xcccccc, 0.4);
    scene.add(ambientLight);

    final pointLight = three.PointLight(0xffffff, 0.8);
    camera.add(pointLight);
    scene.add(camera);

    final material = three.MeshPhongMaterial({
      three.MaterialProperty.side: tmath.DoubleSide, 
      three.MaterialProperty.wireframe: true
    });

    object = three.Mesh(three.SphereGeometry(75, 20, 10), material);
    object.position.setValues(-300, 0, 200);
    scene.add(object);

    object = three.Mesh(three.PlaneGeometry(100, 100, 4, 4), material);
    object.position.setValues(-300, 0, 0);
    scene.add(object);

    object = three.Mesh(three.BoxGeometry(100, 100, 100, 4, 4, 4), material);
    object.position.setValues(-100, 0, 0);
    scene.add(object);


    startTime = DateTime.now().millisecondsSinceEpoch;
    loaded = true;

    animate();  
  }

  void clickRender() {
    print("clickRender..... ");
    animate();
  }

  void animate() {
    if (!mounted || disposed) {
      return;
    }

    if (!loaded) {
      return;
    }

    final timer = DateTime.now().millisecondsSinceEpoch * 0.0001;

    camera.position.x = math.cos(timer) * 800;
    camera.position.z = math.sin(timer) * 800;

    //print(camera.position);

    camera.lookAt(scene.position);

    scene.traverse((object) {
      if (object is three.Mesh) {
        object.rotation.x = timer * 5;
        object.rotation.y = timer * 2.5;
      }
    });

    render();

    Future.delayed(const Duration(milliseconds: 40), () {
      animate();
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: Builder(
        builder: (BuildContext context) {
          initSize(context);
          return Container(
            width: width,
            height: height,
            color: Colors.black,
            child: Builder(
              builder: (BuildContext context) {
                if (kIsWeb) {
                  return three3dRender.isInitialized
                      ? HtmlElementView(
                          viewType: three3dRender.textureId!.toString())
                      : Container();
                } 
                else {
                  return three3dRender.isInitialized
                      ? Texture(textureId: three3dRender.textureId!)
                      : Container();
                }
            }),
          );
        },
      ),
    );
  }
}

