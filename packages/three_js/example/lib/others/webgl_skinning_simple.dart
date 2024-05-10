import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gl/flutter_gl.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_helpers/three_js_helpers.dart';

class webgl_skinning_simple extends StatefulWidget {
  String fileName;
  webgl_skinning_simple({Key? key, required this.fileName}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<webgl_skinning_simple> {
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
    camera = three.PerspectiveCamera(45, width / height, 1, 1000);
    camera.position.setValues(18, 6, 18);

    scene = three.Scene();
    scene.background = three.Color.fromHex32(0xa0a0a0);
    scene.fog = three.Fog(three.Color.fromHex32(0xa0a0a0), 70, 100);

    clock = three.Clock();

    // ground

    var geometry = three.PlaneGeometry(500, 500);
    var material =
        three.MeshPhongMaterial.fromMap({"color": 0x999999, "depthWrite": false});

    var ground = three.Mesh(geometry, material);
    ground.position.setValues(0, -5, 0);
    ground.rotation.x = -math.pi / 2;
    ground.receiveShadow = true;
    scene.add(ground);

    var grid = GridHelper(500, 100, three.Color.fromHex32(0x000000), three.Color.fromHex32(0x000000));
    grid.position.y = -5;
    grid.material?.opacity = 0.2;
    grid.material?.transparent = true;
    scene.add(grid);

    // lights

    var hemiLight = three.HemisphereLight(0xffffff, 0x444444, 0.6);
    hemiLight.position.setValues(0, 200, 0);
    scene.add(hemiLight);

    var dirLight = three.DirectionalLight(0xffffff, 0.8);
    dirLight.position.setValues(0, 20, 10);
    dirLight.castShadow = true;
    dirLight.shadow!.camera!.top = 18;
    dirLight.shadow!.camera!.bottom = -10;
    dirLight.shadow!.camera!.left = -12;
    dirLight.shadow!.camera!.right = 12;
    scene.add(dirLight);

    camera.lookAt(scene.position);

    var loader = three.GLTFLoader(null).setPath('assets/models/gltf/');

    // var result = await loader.loadAsync( 'Parrot.gltf');
    var result = await loader.fromAsset('SimpleSkinning.gltf');

    print(" gltf load sucess result: $result  ");

    object = result!.scene;

    object.traverse((child) {
      if (child is three.SkinnedMesh) child.castShadow = true;
    });

    var skeleton = SkeletonHelper(object);
    skeleton.visible = true;
    scene.add(skeleton);

    mixer = three.AnimationMixer(object);

    var clip = result.animations![0];
    if (clip != null) {
      var action = mixer!.clipAction(clip);
      action?.play();
    }

    scene.add(object);

    // scene.overrideMaterial = new three.MeshBasicMaterial();

    loaded = true;

    animate();
  }

  animate() {
    if (!mounted || disposed) {
      return;
    }

    if (!loaded) {
      return;
    }

    print(" animate render ");

    var delta = clock.getDelta();

    mixer?.update(delta);

    render();

    Future.delayed(const Duration(milliseconds: 17), () {
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
