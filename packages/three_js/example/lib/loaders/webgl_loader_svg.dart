import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gl/flutter_gl.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_helpers/three_js_helpers.dart';
import 'package:three_js_geometry/three_js_geometry.dart';
import 'package:three_js_svg/three_js_svg.dart';

class webgl_loader_svg extends StatefulWidget {
  String fileName;
  webgl_loader_svg({Key? key, required this.fileName}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<webgl_loader_svg> {
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

  late three.Object3D object;

  late three.Texture texture;

  late three.WebGLMultisampleRenderTarget renderTarget;

  dynamic? sourceTexture;

  var guiData = {
    "currentURL": 'assets/models/svg/tiger.svg',
    // "currentURL": 'assets/models/svg/energy.svg',
    // "currentURL": 'assets/models/svg/hexagon.svg',
    // "currentURL": 'assets/models/svg/lineJoinsAndCaps.svg',
    // "currentURL": 'assets/models/svg/multiple-css-classes.svg',
    // "currentURL": 'assets/models/svg/threejs.svg',
    // "currentURL": 'assets/models/svg/zero-radius.svg',
    "drawFillShapes": true,
    "drawStrokes": true,
    "fillShapesWireframe": false,
    "strokesWireframe": false
  };

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
    camera = three.PerspectiveCamera(50, width / height, 1, 1000);
    camera.position.setValues(0, 0, 200);

    loadSVG(guiData["currentURL"]);

    animate();
  }

  loadSVG(url) {
    //

    scene = three.Scene();
    scene.background = three.Color.fromHex32(0xb0b0b0);

    //

    var helper = GridHelper(160, 10);
    helper.rotation.x = math.pi / 2;
    scene.add(helper);

    //

    SVGLoader loader = SVGLoader();

    loader.fromAsset(url).then((data) {
      print(data);
      List<three.ShapePath> paths = data!.paths;

      three.Group group = three.Group();
      group.scale.scale(0.25);
      group.position.x = -70;
      group.position.y = 70;
      group.rotateZ(math.pi);
      group.rotateY(math.pi);
      //group.scale.y *= -1;

      for (int i = 0; i < paths.length; i++) {
        three.ShapePath path = paths[i];

        var fillColor = path.userData?["style"]["fill"];
        if (guiData["drawFillShapes"] == true &&
            fillColor != null &&
            fillColor != 'none') {
          three.MeshBasicMaterial material = three.MeshBasicMaterial.fromMap({
            "color": three.Color().setStyle(fillColor).convertSRGBToLinear(),
            "opacity": path.userData?["style"]["fillOpacity"],
            "transparent": true,
            "side": three.DoubleSide,
            "depthWrite": false,
            "wireframe": guiData["fillShapesWireframe"]
          });

          var shapes = SVGLoader.createShapes(path);

          for (int j = 0; j < shapes.length; j++) {
            var shape = shapes[j];

            ShapeGeometry geometry = ShapeGeometry([shape]);
            three.Mesh mesh = three.Mesh(geometry, material);

            group.add(mesh);
          }
        }

        var strokeColor = path.userData?["style"]["stroke"];

        if (guiData["drawStrokes"] == true &&
            strokeColor != null &&
            strokeColor != 'none') {
          three.MeshBasicMaterial material = three.MeshBasicMaterial.fromMap({
            "color": three.Color().setStyle(strokeColor).convertSRGBToLinear(),
            "opacity": path.userData?["style"]["strokeOpacity"],
            "transparent": true,
            "side": three.DoubleSide,
            "depthWrite": false,
            "wireframe": guiData["strokesWireframe"]
          });

          for (int j = 0, jl = path.subPaths.length; j < jl; j++) {
            three.Path subPath = path.subPaths[j];
            var geometry = SVGLoader.pointsToStroke(
                subPath.getPoints(), path.userData?["style"]);

            if (geometry != null) {
              var mesh = three.Mesh(geometry, material);

              group.add(mesh);
            }
          }
        }
      }

      scene.add(group);

      render();
    });
  }

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
