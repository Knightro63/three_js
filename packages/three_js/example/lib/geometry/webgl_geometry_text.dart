import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gl/flutter_gl.dart';
import 'package:three_js/three_js.dart' as three;

class webgl_geometry_text extends StatefulWidget {
  String fileName;
  webgl_geometry_text({Key? key, required this.fileName}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<webgl_geometry_text> {
  late FlutterGlPlugin three3dRender;
  three.WebGLRenderer? renderer;

  int? fboId;
  late double width;
  late double height;

  Size? screenSize;

  late three.Scene scene;
  late three.Camera camera;
  late three.Mesh mesh;
  late three.Group group;
  late three.GroupMaterial materials;

  double dpr = 1.0;

  var amount = 4;

  bool verbose = false;
  bool disposed = false;

  String text = "Three Dart";

  late three.WebGLRenderTarget renderTarget;

  dynamic sourceTexture;

  double fontHeight = 20,
      size = 70,
      hover = 30,
      bevelThickness = 2,
      bevelSize = 1.5;

  int curveSegments = 4;
  bool bevelEnabled = true;
  bool mirror = true;

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

      await initScene();
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
    // CAMERA

    camera = three.PerspectiveCamera(30, width / height, 1, 1500);
    camera.position.setValues(0, 400, 700);

    var cameraTarget = three.Vector3(0, 50, 0);
    camera.lookAt(cameraTarget);

    // SCENE

    scene = three.Scene();
    scene.background = three.Color.fromHex32(0x000000);
    scene.fog = three.Fog(three.Color.fromHex32(0x000000), 250, 1400);
    // LIGHTS

    var dirLight = three.DirectionalLight(0xffffff, 0.125);
    dirLight.position.setValues(0, 0, 1).normalize();
    scene.add(dirLight);

    var pointLight = three.PointLight(0xffffff, 1.5);
    pointLight.position.setValues(0, 100, 90);
    scene.add(pointLight);

    // Get text from hash

    pointLight.color!.setHSL(math.Random().nextDouble(), 1, 0.5);
    // hex = decimalToHex( pointLight.color!.getHex() );

    materials = three.GroupMaterial([
      three.MeshPhongMaterial.fromMap({"color": 0xffffff, "flatShading": true}), // front
      three.MeshPhongMaterial.fromMap({"color": 0xffffff}) // side
    ]);

    group = three.Group();

    // change size position fit mobile
    group.position.y = 50;
    group.scale.setValues(1, 1, 1);

    scene.add(group);

    var font = await loadFont();

    createText(font);

    var plane = three.Mesh(
        three.PlaneGeometry(10000, 10000),
        three.MeshBasicMaterial.fromMap({"color": 0xffffff, "opacity": 0.5, "transparent": true}));
    plane.position.y = -100;
    plane.rotation.x = -math.pi / 2;
    scene.add(plane);

    animate();
  }

  Future<three.TYPRFont> loadFont() async {
    var loader = three.TYPRLoader();
    var font = await loader.fromAsset("assets/pingfang.ttf");
    loader.dispose();

    return font!;
  }

  createText(font) {
    var textGeo = three.TextGeometry(text, three.TextGeometryOptions(
      font: font,
      size: size,
      depth: fontHeight,
      curveSegments: curveSegments,
      bevelThickness: bevelThickness,
      bevelSize: bevelSize,
      bevelEnabled: bevelEnabled
    ));

    textGeo.computeBoundingBox();

    var centerOffset =
        -0.5 * (textGeo.boundingBox!.max.x - textGeo.boundingBox!.min.x);

    var textMesh1 = three.Mesh(textGeo, materials);

    textMesh1.position.x = centerOffset;
    textMesh1.position.y = hover;
    textMesh1.position.z = 0;

    textMesh1.rotation.x = 0;
    textMesh1.rotation.y = math.pi * 2;

    group.add(textMesh1);

    if (mirror) {
      var textMesh2 = three.Mesh(textGeo, materials);

      textMesh2.position.x = centerOffset;
      textMesh2.position.y = -hover;
      textMesh2.position.z = height;

      textMesh2.rotation.x = math.pi;
      textMesh2.rotation.y = math.pi * 2;

      group.add(textMesh2);
    }
  }

  // decimalToHex( d ) {

  //   var hex = Number( d ).toString( 16 );
  //   hex = "000000".substring( 0, 6 - hex.length ) + hex;
  //   return hex.toUpperCase();

  // }

  animate() {
    if (!mounted || disposed) {
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
