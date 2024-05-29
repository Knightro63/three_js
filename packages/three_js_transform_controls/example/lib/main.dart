import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'package:three_js_transform_controls/three_js_transform_controls.dart';
import 'package:three_js_core/three_js_core.dart' as three;
import 'package:three_js_math/three_js_math.dart' as tmath;

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

  double dpr = 1.0;

  final int amount = 4;

  bool verbose = false;
  bool disposed = false;

  late three.WebGLRenderTarget renderTarget;

  dynamic sourceTexture;

  final GlobalKey<three.PeripheralsState> _globalKey =GlobalKey<three.PeripheralsState>();
  late ArcballControls controls;

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

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    width = screenSize!.width;
    height = screenSize!.height - 60;

    three3dRender = FlutterGlPlugin();

    Map<String, dynamic> options = {
      "antialias": true,
      "alpha": false,
      "width": width.toInt(),
      "height": height.toInt(),
      "dpr": dpr
    };

    await three3dRender.initialize(options: options);

    setState(() {});

    Future.delayed(const Duration(milliseconds: 100), () async {
      await three3dRender.prepareContext();
      initScene();
    });
  }

  void initSize(BuildContext context) {
    if (screenSize != null) {
      return;
    }

    final mqd = MediaQuery.of(context);

    screenSize = mqd.size;
    dpr = mqd.devicePixelRatio;

    initPlatformState();
  }

  void render() {
    int t = DateTime.now().millisecondsSinceEpoch;
    final gl = three3dRender.gl;

    controls.update();

    renderer!.render(scene, camera);

    int t1 = DateTime.now().millisecondsSinceEpoch;

    if (verbose) {
      print("render cost: ${t1 - t} ");
      print(renderer!.info.memory);
      print(renderer!.info.render);
    }

    gl.flush();

    if (verbose) print(" render: sourceTexture: $sourceTexture ");

    if (!kIsWeb) {
      three3dRender.updateTexture(sourceTexture);
    }
  }

  void initRenderer() {
    Map<String, dynamic> options = {
      "width": width,
      "height": height,
      "gl": three3dRender.gl,
      "antialias": true,
      "canvas": three3dRender.element
    };
    renderer = three.WebGLRenderer(options);
    renderer!.setPixelRatio(dpr);
    renderer!.setSize(width, height, false);
    renderer!.shadowMap.enabled = false;

    if (!kIsWeb) {
      final pars = three.WebGLRenderTargetOptions({
        "minFilter": tmath.LinearFilter,
        "magFilter": tmath.LinearFilter,
        "format": tmath.RGBAFormat
      });
      renderTarget = three.WebGLRenderTarget(
          (width * dpr).toInt(), (height * dpr).toInt(), pars);
      renderTarget.samples = 4;
      renderer!.setRenderTarget(renderTarget);
      sourceTexture = renderer!.getRenderTargetGLTexture(renderTarget);
    }
  }

  void initScene() {
    initRenderer();
    initPage();
  }

  void initPage() {
    //final aspectRatio = this.width / this.height;

    final width = (this.width / amount) * dpr;
    final height = (this.height / amount) * dpr;

    scene = three.Scene();
    scene.background = tmath.Color.fromHex32(0xcccccc);
    scene.fog = three.FogExp2(0xcccccc, 0.002);

    camera = three.PerspectiveCamera(45, width / height, 1, 2000);
    camera.position.setValues(0, 0, 200);
    camera.lookAt(scene.position);

    // controls

    controls = ArcballControls(camera, _globalKey, scene, 1);
    controls.addEventListener('change', (event) {
      render();
    });

    // world

    final geometry = three.BoxGeometry(30, 30, 30);
    final material =
        three.MeshPhongMaterial.fromMap({"color": 0xffff00, "flatShading": true});

    final mesh = three.Mesh(geometry, material);

    scene.add(mesh);

    // lights

    final dirLight1 = three.DirectionalLight(0xffffff);
    dirLight1.position.setValues(1, 1, 1);
    scene.add(dirLight1);

    final dirLight2 = three.DirectionalLight(0x002288);
    dirLight2.position.setValues(-1, -1, -1);
    scene.add(dirLight2);

    final ambientLight = three.AmbientLight(0x222222);
    scene.add(ambientLight);

    animate();
  }

  void animate() {
    if (!mounted || disposed) {
      return;
    }

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
    return Stack(
      children: [
        three.Peripherals(
          key: _globalKey,
          builder: (BuildContext context) {
            return Container(
                width: width,
                height: height,
                color: Colors.black,
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
                }));
          }),
      ],
    );
  }
}

