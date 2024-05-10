import 'dart:async';
import 'dart:math' as math;
import 'package:example/src/demo.dart';
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_helpers/three_js_helpers.dart';
import 'package:three_js_geometry/three_js_geometry.dart';

class WebglShadowContact extends StatefulWidget {
  final String fileName;
  const WebglShadowContact({super.key, required this.fileName});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<WebglShadowContact> {
  late Demo demo;

  @override
  void initState() {
    demo = Demo(
      settings: DemoSettings(
        alpha: true
      ),
      fileName: widget.fileName,
      onSetupComplete: (){setState(() {});},
      setup: setup,
      rendererUpdate: renderUpdate
    );
    super.initState();
  }
  @override
  void dispose() {
    demo.dispose();
    super.dispose();
  }

  late three.Mesh blurPlane;
  late three.WebGLRenderTarget renderTarget2;
  late three.WebGLRenderTarget renderTargetBlur;

  final meshes = [];

  late three.Camera shadowCamera;
  late CameraHelper cameraHelper;

  late three.Material depthMaterial;
  late three.Material horizontalBlurMaterial;
  late three.Material verticalBlurMaterial;

  Map<String, dynamic> state = {
    "shadow": {
      "blur": 3.5,
      "darkness": 1,
      "opacity": 1,
    },
    "plane": {
      "color": 0xffffff,
      "opacity": 1,
    },
    "showWireframe": false,
  };

  @override
  Widget build(BuildContext context) {
    return demo.threeDart();
  }

  void renderUpdate() {
    if (!demo.mounted) {
      return;
    }

    for (final mesh in meshes) {
      mesh.rotation.x += 0.01;
      mesh.rotation.y += 0.02;
    }

    // remove the background
    final initialBackground = demo.scene.background;
    demo.scene.background = null;

    // force the depthMaterial to everything
    cameraHelper.visible = false;
    demo.scene.overrideMaterial = depthMaterial;

    // render to the render target to get the depths
    demo.renderer!.setRenderTarget(renderTarget2);
    demo.renderer!.render(demo.scene, shadowCamera);

    // and reset the override material
    demo.scene.overrideMaterial = null;
    cameraHelper.visible = true;

    blurShadow(state["shadow"]["blur"]);

    // a second pass to reduce the artifacts
    // (0.4 is the minimum blur amout so that the artifacts are gone)
    blurShadow(state["shadow"]["blur"] * 0.4);

    // reset and render the normal scene
    demo.renderer!.setRenderTarget(demo.renderTarget);
    demo.scene.background = initialBackground;
  }

  // renderTarget --> blurPlane (horizontalBlur) --> renderTargetBlur --> blurPlane (verticalBlur) --> renderTarget
  void blurShadow(double amount) {
    blurPlane.visible = true;

    // blur horizontally and draw in the renderTargetBlur
    blurPlane.material = horizontalBlurMaterial;
    blurPlane.material!.uniforms["tDiffuse"]["value"] = renderTarget2.texture;
    horizontalBlurMaterial.uniforms["h"]["value"] = amount * 1 / 256;

    demo.renderer!.setRenderTarget(renderTargetBlur);
    demo.renderer!.render(blurPlane, shadowCamera);

    // blur vertically and draw in the main renderTarget
    blurPlane.material = verticalBlurMaterial;
    blurPlane.material!.uniforms["tDiffuse"]["value"] = renderTargetBlur.texture;
    verticalBlurMaterial.uniforms["v"]["value"] = amount * 1 / 256;

    demo.renderer!.setRenderTarget(renderTarget2);
    demo.renderer!.render(blurPlane, shadowCamera);

    blurPlane.visible = false;
  }

  Future<void> setup() async {
    late three.Group shadowGroup;
    late three.Mesh plane;
    late three.Mesh fillPlane;

    const planeWidth = 2.5;
    const planeHeight = 2.5;
    const cameraHeight = 0.3;

    demo.camera = three.PerspectiveCamera(50, demo.width / demo.height, 0.1, 100);
    demo.camera.position.setValues(0.5, 1, 2);

    demo.scene = three.Scene();
    demo.scene.background = three.Color.fromHex32(0xffffff);

    demo.camera.lookAt(demo.scene.position);

    // add the example meshes

    final geometries = [
      three.BoxGeometry(0.4, 0.4, 0.4),
      IcosahedronGeometry(0.3),
      TorusKnotGeometry(0.4, 0.05, 256, 24, 1, 3)
    ];

    final material = three.MeshNormalMaterial();

    for (int i = 0, l = geometries.length; i < l; i++) {
      final angle = (i / l) * math.pi * 2;

      final geometry = geometries[i];
      final mesh = three.Mesh(geometry, material);
      mesh.position.y = 0.1;
      mesh.position.x = math.cos(angle) / 2.0;
      mesh.position.z = math.sin(angle) / 2.0;
      demo.scene.add(mesh);
      meshes.add(mesh);
    }

    // the container, if you need to move the plane just move this
    shadowGroup = three.Group();
    shadowGroup.position.y = -0.3;
    demo.scene.add(shadowGroup);

    final pars = three.WebGLRenderTargetOptions({"format": three.RGBAFormat});
    // the render target that will show the shadows in the plane texture
    renderTarget2 = three.WebGLRenderTarget(512, 512, pars);
    renderTarget2.texture.generateMipmaps = false;

    // the render target that we will use to blur the first render target
    renderTargetBlur = three.WebGLRenderTarget(512, 512, pars);
    renderTargetBlur.texture.generateMipmaps = false;

    // make a plane and make it face up
    final planeGeometry = three.PlaneGeometry(planeWidth, planeHeight).rotateX(math.pi / 2);
    final planeMaterial = three.MeshBasicMaterial.fromMap({
      "map": renderTarget2.texture,
      "opacity": state["shadow"]!["opacity"]!,
      "transparent": true,
      "depthWrite": false,
    });
    plane = three.Mesh(planeGeometry, planeMaterial);
    // make sure it's rendered after the fillPlane
    plane.renderOrder = 1;
    shadowGroup.add(plane);

    // the plane onto which to blur the texture
    blurPlane = three.Mesh(planeGeometry, null);
    blurPlane.visible = false;
    shadowGroup.add(blurPlane);

    // the plane with the color of the ground
    final fillPlaneMaterial = three.MeshBasicMaterial.fromMap({
      "color": state["plane"]["color"],
      "opacity": state["plane"]["opacity"],
      "transparent": true,
      "depthWrite": false,
    });
    fillPlane = three.Mesh(planeGeometry, fillPlaneMaterial);
    fillPlane.rotateX(math.pi);
    shadowGroup.add(fillPlane);

    // the camera to render the depth material from
    shadowCamera = three.OrthographicCamera(-planeWidth / 2,
        planeWidth / 2, planeHeight / 2, -planeHeight / 2, 0, cameraHeight);
    shadowCamera.rotation.x = math.pi / 2; // get the camera to look up
    shadowGroup.add(shadowCamera);

    cameraHelper = CameraHelper(shadowCamera);

    // like MeshDepthMaterial, but goes from black to transparent
    depthMaterial = three.MeshDepthMaterial();
    depthMaterial.userData["darkness"] = {"value": state["shadow"]["darkness"]};
    depthMaterial.onBeforeCompile = (shader, renderer) {
      shader.uniforms["darkness"] = depthMaterial.userData["darkness"];
      shader.fragmentShader = """
        uniform float darkness;
        ${shader.fragmentShader.replaceFirst('gl_FragColor = vec4( vec3( 1.0 - fragCoordZ ), opacity );', 'gl_FragColor = vec4( vec3( 0.0 ), ( 1.0 - fragCoordZ ) * darkness );')}
      """;
    };

    depthMaterial.depthTest = false;
    depthMaterial.depthWrite = false;

    horizontalBlurMaterial = three.ShaderMaterial.fromMap(three.horizontalBlurShader);
    horizontalBlurMaterial.depthTest = false;

    verticalBlurMaterial = three.ShaderMaterial.fromMap(three.verticalBlurShader);
    verticalBlurMaterial.depthTest = false;
  }
}
