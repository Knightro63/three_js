import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gl/flutter_gl.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_helpers/three_js_helpers.dart';

class webgl_clipping_intersection extends StatefulWidget {
  String fileName;

  webgl_clipping_intersection({Key? key, required this.fileName})
      : super(key: key);

  @override
  createState() => _State();
}

class _State extends State<webgl_clipping_intersection> {
  late FlutterGlPlugin three3dRender;
  three.WebGLRenderer? renderer;

  int? fboId;
  late double width;
  late double height;

  Size? screenSize;

  late three.Scene scene;
  late three.Camera camera;
  late three.Mesh mesh;

  late three.AnimationMixer mixer;
  three.Clock clock = three.Clock();

  double dpr = 1.0;

  var amount = 4;

  bool verbose = false;
  bool disposed = false;

  late three.Object3D object;

  late three.Texture texture;

  late three.WebGLMultisampleRenderTarget renderTarget;

  dynamic? sourceTexture;

  bool loaded = false;

  late three.Object3D model;

  final Map<String, List<Function>> _listeners = {};

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
          clickRender();
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
                  child: Container(
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
                      }))),
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
    renderer!.localClippingEnabled = true;

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
    Map<String, dynamic> params = {
      "clipIntersection": true,
      "planeConstant": 0,
      "showHelpers": false
    };

    var clipPlanes = [
      three.Plane(three.Vector3(1, 0, 0), 0),
      three.Plane(three.Vector3(0, -1, 0), 0),
      three.Plane(three.Vector3(0, 0, -1), 0)
    ];

    scene = three.Scene();

    camera = three.PerspectiveCamera(40, width / height, 1, 200);

    camera.position.setValues(-1.5, 2.5, 3.0);

    camera.lookAt(scene.position);

    var light = three.HemisphereLight(0xffffff, 0x080808, 1.5);
    light.position.setValues(-1.25, 1, 1.25);
    scene.add(light);

    // const helper = new three.CameraHelper( light.shadow.camera );
    // scene.add( helper );

    //

    var group = three.Group();

    for (var i = 1; i <= 30; i += 2) {
      var geometry = three.SphereGeometry(i / 30, 48, 24);

      var material = three.MeshLambertMaterial.fromMap({
        "color": three.Color(0, 0, 0).setHSL(math.Random().nextDouble(), 0.5, 0.5),
        "side": three.DoubleSide,
        "clippingPlanes": clipPlanes,
        "clipIntersection": params["clipIntersection"]
      });

      group.add(three.Mesh(geometry, material));
    }

    scene.add(group);

    // helpers

    var helpers = three.Group();
    helpers.add(PlaneHelper(clipPlanes[0], 2, 0xff0000));
    helpers.add(PlaneHelper(clipPlanes[1], 2, 0x00ff00));
    helpers.add(PlaneHelper(clipPlanes[2], 2, 0x0000ff));
    helpers.visible = params["showHelpers"]!;
    scene.add(helpers);

    // gui
    //

    loaded = true;

    animate();

    // scene.overrideMaterial = new three.MeshBasicMaterial();
  }

  clickRender() {
    print("clickRender..... ");
    animate();
  }

  animate() {
    if (!mounted || disposed) {
      return;
    }

    if (!loaded) {
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
