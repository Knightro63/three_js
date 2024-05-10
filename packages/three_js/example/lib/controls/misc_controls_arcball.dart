import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gl/flutter_gl.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_transform_controls/three_js_transform_controls.dart';

class misc_controls_arcball extends StatefulWidget {
  String fileName;
  misc_controls_arcball({Key? key, required this.fileName}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<misc_controls_arcball> {
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

  late three.WebGLRenderTarget renderTarget;

  dynamic sourceTexture;

  final GlobalKey<three.PeripheralsState> _globalKey =
      GlobalKey<three.PeripheralsState>();

  late ArcballControls controls;

  @override
  void initState() {
    super.initState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    width = screenSize!.width;
    height = screenSize!.height - 60;

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
          ),
        ),
      ],
    );
  }

  render() {
    int _t = DateTime.now().millisecondsSinceEpoch;
    final _gl = three3dRender.gl;

    controls.update();

    renderer!.render(scene, camera);

    int _t1 = DateTime.now().millisecondsSinceEpoch;

    if (verbose) {
      print("render cost: ${_t1 - _t} ");
      print(renderer!.info.memory);
      print(renderer!.info.render);
    }

    
    _gl.flush();

    // var pixels = _gl.readCurrentPixels(0, 0, 10, 10);
    // print(" --------------pixels............. ");
    // print(pixels);

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
      var pars = three.WebGLRenderTargetOptions({
        "minFilter": three.LinearFilter,
        "magFilter": three.LinearFilter,
        "format": three.RGBAFormat
      });
      renderTarget = three.WebGLRenderTarget(
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

  initPage() {
    var ASPECTRATIO = width / height;

    var WIDTH = (width / amount) * dpr;
    var HEIGHT = (height / amount) * dpr;

    scene = three.Scene();
    scene.background = three.Color.fromHex32(0xcccccc);
    scene.fog = three.FogExp2(three.Color.fromHex32(0xcccccc), 0.002);

    camera = three.PerspectiveCamera(45, width / height, 1, 2000);
    camera.position.setValues(0, 0, 200);
    camera.lookAt(scene.position);

    // controls

    controls = ArcballControls(camera, _globalKey, scene, 1);
    controls.addEventListener('change', (event) {
      render();
    });

    // world

    var geometry = three.BoxGeometry(30, 30, 30);
    var material =
        three.MeshPhongMaterial.fromMap({"color": 0xffff00, "flatShading": true});

    var mesh = three.Mesh(geometry, material);

    scene.add(mesh);

    // lights

    var dirLight1 = three.DirectionalLight(0xffffff);
    dirLight1.position.setValues(1, 1, 1);
    scene.add(dirLight1);

    var dirLight2 = three.DirectionalLight(0x002288);
    dirLight2.position.setValues(-1, -1, -1);
    scene.add(dirLight2);

    var ambientLight = three.AmbientLight(0x222222);
    scene.add(ambientLight);

    animate();
  }

  animate() {
    if (!mounted || disposed) {
      return;
    }

    render();

    Future.delayed(const Duration(milliseconds: 40), () {
      animate();
    });
  }

  @override
  void dispose() {
    print(" dispose ............. ");

    disposed = true;
    three3dRender.dispose();

    super.dispose();
  }
}
