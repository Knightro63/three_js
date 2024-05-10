import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gl/flutter_gl.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_helpers/three_js_helpers.dart';

class webgl_animation_keyframes extends StatefulWidget {
  String fileName;

  webgl_animation_keyframes({Key? key, required this.fileName})
      : super(key: key);

  @override
  createState() => webgl_animation_keyframesState();
}

class webgl_animation_keyframesState extends State<webgl_animation_keyframes> {
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

  var amount = 4;

  bool verbose = false;
  bool disposed = false;

  late three.Object3D object;

  late three.Texture texture;

  late three.WebGLMultisampleRenderTarget renderTarget;

  dynamic sourceTexture;

  bool loaded = false;

  late three.Object3D model;

  final Map<String, List<Function>> _listeners = {};

  final GlobalKey<three.PeripheralsState> _globalKey = GlobalKey<three.PeripheralsState>();

  @override
  void initState() {
    print('CACHE: ${three.Cache.files.keys}');
    super.initState();
  }

  addEventListener(String name, Function callback, [bool flag = false]) {
    var _cls = _listeners[name] ?? [];
    _cls.add(callback);
    _listeners[name] = _cls;
  }

  removeEventListener(String name, Function callback, [bool flag = false]) {
    var _cls = _listeners[name] ?? [];
    _cls.remove(callback);
    _listeners[name] = _cls;
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

  emit(String name, event) {
    var _callbacks = _listeners[name];
    if (_callbacks != null && _callbacks.isNotEmpty) {
      var _len = _callbacks.length;
      for (int i = 0; i < _len; i++) {
        var _cb = _callbacks[i];
        _cb(event);
      }
    }
  }

  Widget _build(BuildContext context) {
    return Column(
      children: [
        Container(
          child: Stack(
            children: [
              three.Peripherals(
                key: _globalKey,
                builder: (BuildContext conetxt) {
                  return Container(
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
    camera = three.PerspectiveCamera(45, width / height, 1, 100);
    camera.position.setValues(8, 4, 12);

    // scene

    scene = three.Scene();

    var pmremGenerator = three.PMREMGenerator(renderer);
    scene.background = three.Color.fromHex32(0xbfe3dd);
    scene.environment = pmremGenerator.fromScene(RoomEnvironment(), 0.04).texture;

    var ambientLight = three.AmbientLight( 0xcccccc, 0.4 );
    scene.add( ambientLight );

    var pointLight = three.PointLight( 0xffffff, 0.8 );
    camera.add( pointLight );

    scene.add(camera);

    camera.lookAt(scene.position);

    var loader = three.GLTFLoader().setPath('assets/models/gltf/test/');

    var result = await loader.fromAsset('tokyo.gltf');
    // var result = await loader.loadAsync( 'animate7.gltf', null);
    // var result = await loader.loadAsync( 'untitled22.gltf', null);

    print(result);

    print(" load gltf success result: $result  ");

    model = result!.scene;

    print(" load gltf success model: $model  ");

    model.position.setValues(1, 1, 0);
    model.scale.setValues(0.01, 0.01, 0.01);
    scene.add(model);

    mixer = three.AnimationMixer(model);
    mixer.clipAction(result.animations![0], null, null)!.play();

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

    mixer.update(delta);

    controls?.update();

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
    three.loading.clear();

    super.dispose();
  }
}
