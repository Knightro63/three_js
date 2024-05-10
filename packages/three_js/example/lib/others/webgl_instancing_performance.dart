import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gl/flutter_gl.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_tjs_loader/three_js_tjs_loader.dart';

class webgl_instancing_performance extends StatefulWidget {
  String fileName;
  webgl_instancing_performance({Key? key, required this.fileName})
      : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<webgl_instancing_performance> {
  late FlutterGlPlugin three3dRender;
  three.WebGLRenderer? renderer;

  int? fboId;
  late double width;
  late double height;

  Size? screenSize;

  late three.Scene scene;
  late three.Camera camera;
  late three.Mesh mesh;

  late three.Material material;

  double dpr = 1.0;

  var AMOUNT = 4;

  bool verbose = true;
  bool disposed = false;

  int count = 1000;

  late three.WebGLRenderTarget renderTarget;

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
      var pars = three.WebGLRenderTargetOptions({
        "minFilter": three.LinearFilter,
        "magFilter": three.LinearFilter,
        "format": three.RGBAFormat
      });
      renderTarget = three.WebGLMultisampleRenderTarget(
          (width * dpr).toInt(), (height * dpr).toInt(), pars);
      renderer!.setRenderTarget(renderTarget);
      sourceTexture = renderer!.getRenderTargetGLTexture(renderTarget);
    }
  }

  initScene() async {
    initRenderer();
    await initPage();
  }

  initPage() async {
    camera = three.PerspectiveCamera(70, width / height, 1, 100);
    camera.position.z = 30;

    scene = three.Scene();
    scene.background = three.Color.fromHex32(0xffffff);

    var _loader = BufferGeometryLoader();
    material = three.MeshNormalMaterial();

    // var geometry = await _loader.loadAsync("assets/models/json/suzanne_buffergeometry.json", null);
    // geometry.computeVertexNormals();

    var geometry = three.BoxGeometry(5, 5, 5);

    // makeInstanced( geometry );

    // makeMerged( geometry );

    makeNaive(geometry);

    animate();
  }

  makeInstanced(geometry) {
    var matrix = three.Matrix4();
    var mesh = three.InstancedMesh(geometry, material, count);

    for (var i = 0; i < count; i++) {
      randomizeMatrix(matrix);
      mesh.setMatrixAt(i, matrix);
    }

    scene.add(mesh);

    //

    // var geometryByteLength = getGeometryByteLength( geometry );

    // guiStatsEl.innerHTML = [

    //   '<i>GPU draw calls</i>: 1',
    //   '<i>GPU memory</i>: ' + formatBytes( api.count * 16 + geometryByteLength, 2 )

    // ].join( '<br/>' );
  }

  makeNaive(geometry) {
    var matrix = three.Matrix4();

    for (var i = 0; i < count; i++) {
      var mesh = three.Mesh(geometry, material);
      randomizeMatrix(matrix);
      mesh.applyMatrix4(matrix);
      scene.add(mesh);
    }
  }

  var position = three.Vector3();
  var rotation = three.Euler(0, 0, 0);
  var quaternion = three.Quaternion();
  var scale = three.Vector3();

  randomizeMatrix(matrix) {
    position.x = math.Random().nextDouble() * 40 - 20;
    position.y = math.Random().nextDouble() * 40 - 20;
    position.z = math.Random().nextDouble() * 40 - 20;

    rotation.x = math.Random().nextDouble() * 2 * math.pi;
    rotation.y = math.Random().nextDouble() * 2 * math.pi;
    rotation.z = math.Random().nextDouble() * 2 * math.pi;

    quaternion.setFromEuler(rotation, false);

    scale.x = scale.y = scale.z = math.Random().nextDouble() * 1;

    matrix.compose(position, quaternion, scale);
  }

  animate() {
    if (!mounted || disposed) {
      return;
    }

    scene.rotation.x += 0.002;
    scene.rotation.y += 0.001;

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
