import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gl/flutter_gl.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_helpers/three_js_helpers.dart';

class webgl_morphtargets extends StatefulWidget {
  String fileName;

  webgl_morphtargets({Key? key, required this.fileName}) : super(key: key);

  @override
  createState() => _State();
}

class _State extends State<webgl_morphtargets> {
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

  dynamic sourceTexture;

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
    scene = three.Scene();
    scene.background = three.Color.fromHex32(0x8FBCD4);

    camera = three.PerspectiveCamera(45, width / height, 1, 20);
    camera.position.z = 10;
    scene.add(camera);

    camera.lookAt(scene.position);

    scene.add(three.AmbientLight(0x8FBCD4, 0.4));

    var pointLight = three.PointLight(0xffffff, 1);
    camera.add(pointLight);

    var geometry = createGeometry();

    var material =
        three.MeshPhongMaterial.fromMap({"color": 0xff0000, "flatShading": true});

    mesh = three.Mesh(geometry, material);
    scene.add(mesh);

    loaded = true;

    animate();

    // scene.overrideMaterial = new three.MeshBasicMaterial();
  }

  createGeometry() {
    var geometry = three.BoxGeometry(2, 2, 2, 32, 32, 32);

    // create an empty array to  hold targets for the attribute we want to morph
    // morphing positions and normals is supported
    geometry.morphAttributes["position"] = [];

    // the original positions of the cube's vertices
    var positionAttribute = geometry.attributes["position"];

    // for the first morph target we'll move the cube's vertices onto the surface of a sphere
    List<double> spherePositions = [];

    // for the second morph target, we'll twist the cubes vertices
    List<double> twistPositions = [];
    var direction = three.Vector3(1, 0, 0);
    var vertex = three.Vector3();

    for (var i = 0; i < positionAttribute.count; i++) {
      var x = positionAttribute.getX(i);
      var y = positionAttribute.getY(i);
      var z = positionAttribute.getZ(i);

      spherePositions.addAll([
        x *
            math.sqrt(
                1 - (y * y / 2) - (z * z / 2) + (y * y * z * z / 3)),
        y *
            math.sqrt(
                1 - (z * z / 2) - (x * x / 2) + (z * z * x * x / 3)),
        z * math.sqrt(1 - (x * x / 2) - (y * y / 2) + (x * x * y * y / 3))
      ]);

      // stretch along the x-axis so we can see the twist better
      vertex.setValues(x * 2, y, z);

      vertex
          .applyAxisAngle(direction, math.pi * x / 2)
          .copyIntoArray(twistPositions, twistPositions.length);
    }

    // add the spherical positions as the first morph target
    // geometry.morphAttributes["position"][ 0 ] = new three.Float32BufferAttribute( spherePositions, 3 );
    geometry.morphAttributes["position"]!
        .add(three.Float32BufferAttribute(Float32Array.fromList(spherePositions), 3));

    // add the twisted positions as the second morph target
    geometry.morphAttributes["position"]!
        .add(three.Float32BufferAttribute(Float32Array.fromList(twistPositions), 3));

    return geometry;
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

    num _t = (DateTime.now().millisecondsSinceEpoch * 0.0005);

    var _v0 = (math.sin(_t) + 1.0) / 2.0;
    var _v1 = (math.sin(_t + 0.3) + 1.0) / 2.0;

    // print(" _v0: ${_v0} _v1: ${_v1} ");

    mesh.morphTargetInfluences![0] = _v0;
    mesh.morphTargetInfluences![1] = _v1;

    // mesh.morphTargetInfluences![0] = 0.2;

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
