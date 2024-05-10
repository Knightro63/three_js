import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gl/flutter_gl.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_helpers/three_js_helpers.dart';

class webgl_animation_skinning_morph extends StatefulWidget {
  String fileName;

  webgl_animation_skinning_morph({Key? key, required this.fileName}): super(key: key);

  @override
  createState() => _State();
}

class _State extends State<webgl_animation_skinning_morph> {
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
  late three.Clock clock;
  three.OrbitControls? controls;

  double dpr = 1.0;

  var AMOUNT = 4;

  bool verbose = false;
  bool disposed = false;

  late three.Object3D object;

  late three.Texture texture;

  late three.WebGLMultisampleRenderTarget renderTarget;

  dynamic sourceTexture;

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
    //Future.delayed(const Duration(milliseconds: 100), () async {
      await three3dRender.prepareContext();

      initScene();
    //});
  }

  Future<bool> initSize(BuildContext context) async{
    if (screenSize != null) {
      return false;
    }

    final mqd = MediaQuery.of(context);

    screenSize = mqd.size;
    dpr = mqd.devicePixelRatio;

    initPlatformState();
    return true;
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.fileName),
      ),
      body: FutureBuilder<bool>(
        future: initSize(context),
        builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
          if (!snapshot.hasData) {
            return CircularProgressIndicator();
          }
          else{
            return SingleChildScrollView(child: _build(context));
          }
        }
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
    renderer!.shadowMap.enabled = true;
    renderer!.outputEncoding = three.sRGBEncoding;

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
    camera = three.PerspectiveCamera(45, width / height, 0.1, 1000);
    camera.position.setValues(-5, 3, 10);
    camera.lookAt(three.Vector3(0, 2, 0));

    clock = three.Clock();

    scene = three.Scene();
    scene.background = three.Color.fromHex32(0xffffff);
    scene.fog = three.Fog(three.Color.fromHex32(0xa0a0a0), 10, 50);

    var hemiLight = three.HemisphereLight(0xffffff, 0x444444);
    hemiLight.position.setValues(0, 20, 0);
    scene.add(hemiLight);

    var dirLight = three.DirectionalLight(0xffffff);
    dirLight.position.setValues(0, 20, 10);

    scene.add(dirLight);

    // scene.add( new three.CameraHelper( dirLight.shadow.camera ) );

    // ground

    var mesh = three.Mesh(three.PlaneGeometry(2000, 2000), three.MeshPhongMaterial.fromMap({"color": 0x999999, "depthWrite": true}));
    mesh.rotation.x = -math.pi / 2;
    scene.add(mesh);

    var grid = GridHelper(200, 40, three.Color.fromHex32(0x000000), three.Color.fromHex32(0x000000));
    grid.material?.opacity = 0.2;
    grid.material?.transparent = true;
    scene.add(grid);

    var loader = three.GLTFLoader().setPath('assets/models/gltf/RobotExpressive/');
    var result = await loader.fromAsset('RobotExpressive.gltf');

    model = result!.scene;
    scene.add(model);

    model.traverse((object) {
      if (object is three.Mesh) object.castShadow = true;
    });

    //

    var skeleton = SkeletonHelper(model);
    skeleton.visible = true;
    scene.add(skeleton);

    //

    // createPanel();

    //

    var animations = result.animations!;

    mixer = three.AnimationMixer(model);

    var idleAction = mixer.clipAction(animations[0]);
    var walkAction = mixer.clipAction(animations[2]);
    var runAction = mixer.clipAction(animations[1]);

    // var actions = [ idleAction, walkAction, runAction ];
    idleAction!.play();
    // activateAllActions();
    
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
