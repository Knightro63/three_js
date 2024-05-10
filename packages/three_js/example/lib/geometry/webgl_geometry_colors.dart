import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gl/flutter_gl.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_geometry/three_js_geometry.dart';

class webgl_geometry_colors extends StatefulWidget {
  String fileName;
  webgl_geometry_colors({Key? key, required this.fileName}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<webgl_geometry_colors> {
  late FlutterGlPlugin three3dRender;
  three.WebGLRenderer? renderer;

  int? fboId;
  late double width;
  late double height;

  Size? screenSize;

  late three.Scene scene;
  late three.Camera camera;
  late three.Mesh mesh;

  late three.PointLight pointLight;

  var objects = [], materials = [];

  double dpr = 1.0;

  var AMOUNT = 4;

  bool verbose = true;
  bool disposed = false;

  bool loaded = false;

  late three.Object3D object;

  late three.Texture texture;

  late three.WebGLMultisampleRenderTarget renderTarget;

  three.AnimationMixer? mixer;
  three.Clock clock = three.Clock();

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

  clickRender() {
    print(" click render... ");
    animate();
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

    // 重要 更新纹理之前一定要调用 确保gl程序执行完毕
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
    renderer!.shadowMap.enabled = true;

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
    camera = three.PerspectiveCamera(20, width / height, 1, 10000);
    camera.position.z = 1800;

    scene = three.Scene();
    scene.background = three.Color.fromHex32(0xffffff);

    var light = three.DirectionalLight(0xffffff);
    light.position.setValues(0, 0, 1);
    scene.add(light);

    // shadow

    // var canvas = document.createElement( 'canvas' );
    // canvas.width = 128;
    // canvas.height = 128;

    // var context = canvas.getContext( '2d' );
    // var gradient = context.createRadialGradient( canvas.width / 2, canvas.height / 2, 0, canvas.width / 2, canvas.height / 2, canvas.width / 2 );
    // gradient.addColorStop( 0.1, 'rgba(210,210,210,1)' );
    // gradient.addColorStop( 1, 'rgba(255,255,255,1)' );

    // context.fillStyle = gradient;
    // context.fillRect( 0, 0, canvas.width, canvas.height );

    // var shadowTexture = new three.CanvasTexture( canvas );

    var shadowMaterial = three.MeshBasicMaterial({});
    var shadowGeo = three.PlaneGeometry(300, 300, 1, 1);

    three.Mesh shadowMesh;

    shadowMesh = three.Mesh(shadowGeo, shadowMaterial);
    shadowMesh.position.y = -250;
    shadowMesh.rotation.x = -math.pi / 2;
    scene.add(shadowMesh);

    shadowMesh = three.Mesh(shadowGeo, shadowMaterial);
    shadowMesh.position.y = -250;
    shadowMesh.position.x = -400;
    shadowMesh.rotation.x = -math.pi / 2;
    scene.add(shadowMesh);

    shadowMesh = three.Mesh(shadowGeo, shadowMaterial);
    shadowMesh.position.y = -250;
    shadowMesh.position.x = 400;
    shadowMesh.rotation.x = -math.pi / 2;
    scene.add(shadowMesh);

    var radius = 200.0;

    var geometry1 = IcosahedronGeometry(radius, 1);

    var count = geometry1.attributes["position"].count;
    geometry1.setAttributeFromString('color', three.Float32BufferAttribute( Float32Array(count * 3), 3));

    var geometry2 = geometry1.clone();
    var geometry3 = geometry1.clone();

    var color = three.Color(1, 1, 1);
    var positions1 = geometry1.attributes["position"];
    var positions2 = geometry2.attributes["position"];
    var positions3 = geometry3.attributes["position"];
    var colors1 = geometry1.attributes["color"];
    var colors2 = geometry2.attributes["color"];
    var colors3 = geometry3.attributes["color"];

    for (var i = 0; i < count; i++) {
      color.setHSL((positions1.getY(i) / radius + 1) / 2, 1.0, 0.5);
      colors1.setXYZ(i, color.red, color.green, color.blue);

      color.setHSL(0, (positions2.getY(i) / radius + 1) / 2, 0.5);
      colors2.setXYZ(i, color.red, color.green, color.blue);

      color.setRGB(1, 0.8 - (positions3.getY(i) / radius + 1) / 2, 0);
      colors3.setXYZ(i, color.red, color.green, color.blue);
    }

    var material = three.MeshPhongMaterial.fromMap({
      "color": 0xffffff,
      "flatShading": true,
      "vertexColors": true,
      "shininess": 0
    });

    var wireframeMaterial = three.MeshBasicMaterial.fromMap({"color": 0x000000, "wireframe": true, "transparent": true});

    var mesh = three.Mesh(geometry1, material);
    var wireframe = three.Mesh(geometry1, wireframeMaterial);
    mesh.add(wireframe);
    mesh.position.x = -400;
    mesh.rotation.x = -1.87;
    scene.add(mesh);

    mesh = three.Mesh(geometry2, material);
    wireframe = three.Mesh(geometry2, wireframeMaterial);
    mesh.add(wireframe);
    mesh.position.x = 400;
    scene.add(mesh);

    mesh = three.Mesh(geometry3, material);
    wireframe = three.Mesh(geometry3, wireframeMaterial);
    mesh.add(wireframe);
    scene.add(mesh);

    // scene.overrideMaterial = new three.MeshBasicMaterial();

    loaded = true;

    animate();
  }

  generateTexture() {
    var pixels = Uint8Array(256 * 256 * 4);

    var x = 0, y = 0, l = pixels.length;

    for (var i = 0, j = 0; i < l; i += 4, j++) {
      x = j % 256;
      y = (x == 0) ? y + 1 : y;

      pixels[i] = 255;
      pixels[i + 1] = 255;
      pixels[i + 2] = 255;
      pixels[i + 3] = (x ^ y).floor();
    }

    return three.ImageElement(data: pixels, width: 256, height: 256);
  }

  addMesh(geometry, material) {
    var mesh = three.Mesh(geometry, material);

    mesh.position.x = (objects.length % 4) * 200 - 400;
    mesh.position.z = (objects.length / 4).floor() * 200 - 200;

    mesh.rotation.x = math.Random().nextDouble() * 200 - 100;
    mesh.rotation.y = math.Random().nextDouble() * 200 - 100;
    mesh.rotation.z = math.Random().nextDouble() * 200 - 100;

    objects.add(mesh);

    scene.add(mesh);
  }

  animate() {
    print("before animate render mounted: $mounted loaded: $loaded");

    if (!mounted || disposed) {
      return;
    }

    if (!loaded) {
      return;
    }

    print(" animate render ");

    var delta = clock.getDelta();

    render();

    // 30FPS
    Future.delayed(const Duration(milliseconds: 33), () {
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
