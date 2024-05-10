import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gl/flutter_gl.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_helpers/three_js_helpers.dart';
import 'package:three_js_geometry/three_js_geometry.dart';

class webgl_helpers extends StatefulWidget {
  String fileName;

  webgl_helpers({Key? key, required this.fileName}) : super(key: key);

  @override
  createState() => _State();
}

class _State extends State<webgl_helpers> {
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
  three.OrbitControls? controls;

  double dpr = 1.0;

  var AMOUNT = 4;

  bool verbose = true;
  bool disposed = false;

  late three.Object3D object;

  late three.Texture texture;

  late three.PointLight light;

  VertexNormalsHelper? vnh;
  VertexTangentsHelper? vth;

  late three.WebGLMultisampleRenderTarget renderTarget;

  dynamic? sourceTexture;

  bool loaded = false;

  late three.Object3D model;

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
    camera = three.PerspectiveCamera(70, width / height, 1, 1000);
    camera.position.z = 400;

    // scene

    scene = three.Scene();

    light = three.PointLight(0xffffff);
    light.position.setValues(200, 100, 150);
    scene.add(light);

    scene.add(PointLightHelper(light, 15, three.Color.fromHex32(0xffffff)));

    var gridHelper = GridHelper(400, 40, three.Color.fromHex32(0x0000ff), three.Color.fromHex32(0x808080));
    gridHelper.position.y = -150;
    gridHelper.position.x = -150;
    scene.add(gridHelper);

    var polarGridHelper = PolarGridHelper(200, 16, 8, 64, three.Color.fromHex32(0x0000ff), three.Color.fromHex32(0x808080));
    polarGridHelper.position.y = -150;
    polarGridHelper.position.x = 200;
    scene.add(polarGridHelper);

    camera.lookAt(scene.position);

    var loader = three.GLTFLoader().setPath('assets/models/gltf/');

    var result = await loader.fromAsset('LeePerrySmith.gltf');
    // var result = await loader.loadAsync( 'animate7.gltf', null);
    // var result = await loader.loadAsync( 'untitled22.gltf', null);

    print(result);
    print(" load gltf success result: $result  ");

    model = result!.scene;

    var mesh = model.children[2];

    print(" load gltf success mesh: $mesh  ");

    mesh.geometry?.computeTangents(); // generates bad data due to degenerate UVs

    var group = three.Group();
    group.scale.scale(50);
    scene.add(group);

    // To make sure that the matrixWorld is up to date for the boxhelpers
    group.updateMatrixWorld(true);

    group.add(mesh);

    vnh = VertexNormalsHelper(mesh, 5);
    scene.add(vnh!);

    vth = VertexTangentsHelper(mesh, 5);
    scene.add(vth!);

    scene.add(BoxHelper(mesh));

    var wireframe = WireframeGeometry(mesh.geometry!);

    var line = three.LineSegments(wireframe, null);

    line.material?.depthTest = false;
    line.material?.opacity = 0.25;
    line.material?.transparent = true;
    line.position.x = 4;
    group.add(line);
    scene.add(BoxHelper(line));

    var edges = EdgesGeometry(mesh.geometry!, null);
    line = three.LineSegments(edges, null);
    line.material?.depthTest = false;
    line.material?.opacity = 0.25;
    line.material?.transparent = true;
    line.position.x = -4;
    group.add(line);
    scene.add(BoxHelper(line));

    scene.add(BoxHelper(group));
    scene.add(BoxHelper(scene));

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

    var delta = clock.getDelta();

    var time = -DateTime.now().millisecondsSinceEpoch * 0.00003;

    camera.position.x = 400 * math.cos(time);
    camera.position.z = 400 * math.sin(time);
    camera.lookAt(scene.position);

    light.position.x = math.sin(time * 1.7) * 300;
    light.position.y = math.cos(time * 1.5) * 400;
    light.position.z = math.cos(time * 1.3) * 300;

    if (vnh != null) vnh!.update();
    if (vth != null) vth!.update();

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
