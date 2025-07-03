import 'dart:async';
import 'dart:math' as math;
import 'package:example/src/gui.dart';
import 'package:example/src/statistics.dart';
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_helpers/three_js_helpers.dart';
import 'package:three_js_geometry/three_js_geometry.dart';

class WebglShadowContact extends StatefulWidget {
  const WebglShadowContact({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<WebglShadowContact> {
  List<int> data = List.filled(60, 0, growable: true);
  late Timer timer;
  late three.ThreeJS threeJs;
  late final Gui gui;

  @override
  void initState() {
    gui = Gui((){setState(() {});});
    timer = Timer.periodic(const Duration(seconds: 1), (t){
      setState(() {
        data.removeAt(0);
        data.add(threeJs.clock.fps);
      });
    });
    threeJs = three.ThreeJS(
      settings: three.Settings(
        //alpha: true,
        useSourceTexture: true,
        
      ),
      
      onSetupComplete: (){setState(() {});},
      setup: setup,      rendererUpdate: renderUpdate
    );
    super.initState();
  }
  @override
  void dispose() {
    timer.cancel();
    threeJs.dispose();
    three.loading.clear();
    controls.dispose();
    super.dispose();
  }

  late three.Mesh blurPlane;
  late three.WebGLRenderTarget renderTarget;
  late three.WebGLRenderTarget renderTargetBlur;

  final meshes = [];

  late three.Camera shadowCamera;
  late CameraHelper cameraHelper;

  late three.Material depthMaterial;
  late three.Material horizontalBlurMaterial;
  late three.Material verticalBlurMaterial;

  late final three.OrbitControls controls;

  Map<String, dynamic> state = {
    "shadow": {
      "blur": 3.5,
      "darkness": 1.0,
      "opacity": 1.0,
    },
    "plane": {
      "color": 0xffffff,
      "opacity": 1.0,
    },
    "showWireframe": false,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          threeJs.build(),
          Statistics(data: data),
          if(threeJs.mounted)Positioned(
            top: 20,
            right: 20,
            child: SizedBox(
              height: threeJs.height,
              width: 240,
              child: gui.render(context)
            )
          )
        ],
      ) 
    );
  }

  void renderUpdate() {
    if (!threeJs.mounted) {
      return;
    }

    for (final mesh in meshes) {
      mesh.rotation.x += 0.01;
      mesh.rotation.y += 0.02;
    }

    // remove the background
    final initialBackground = threeJs.scene.background;
    threeJs.scene.background = null;

    // force the depthMaterial to everything
    cameraHelper.visible = false;
    threeJs.scene.overrideMaterial = depthMaterial;

		final initialClearAlpha = threeJs.renderer!.getClearAlpha();
		threeJs.renderer!.setClearAlpha( 0 );

    // render to the render target to get the depths
    threeJs.renderer!.setRenderTarget(renderTarget);
    threeJs.renderer!.render(threeJs.scene, shadowCamera);

    // and reset the override material
    threeJs.scene.overrideMaterial = null;
    cameraHelper.visible = true;

    blurShadow(state["shadow"]["blur"]);

    // a second pass to reduce the artifacts
    // (0.4 is the minimum blur amout so that the artifacts are gone)
    blurShadow(state["shadow"]["blur"] * 0.4);

    // reset and render the normal scene
    threeJs.renderer!.setRenderTarget( threeJs.renderTarget );
    threeJs.renderer!.setClearAlpha( initialClearAlpha );
    threeJs.scene.background = initialBackground;

    threeJs.renderer!.render( threeJs.scene, threeJs.camera );
  }

  // renderTarget --> blurPlane (horizontalBlur) --> renderTargetBlur --> blurPlane (verticalBlur) --> renderTarget
  void blurShadow(double amount) {
    blurPlane.visible = true;

    // blur horizontally and draw in the renderTargetBlur
    blurPlane.material = horizontalBlurMaterial;
    blurPlane.material!.uniforms["tDiffuse"]["value"] = renderTarget.texture;
    horizontalBlurMaterial.uniforms["h"]["value"] = amount * 1 / 256;

    threeJs.renderer!.setRenderTarget(renderTargetBlur);
    threeJs.renderer!.render(blurPlane, shadowCamera);

    // blur vertically and draw in the main renderTarget
    blurPlane.material = verticalBlurMaterial;
    blurPlane.material!.uniforms["tDiffuse"]["value"] = renderTargetBlur.texture;
    verticalBlurMaterial.uniforms["v"]["value"] = amount * 1 / 256;

    threeJs.renderer!.setRenderTarget(renderTarget);
    threeJs.renderer!.render(blurPlane, shadowCamera);

    blurPlane.visible = false;
  }

  Future<void> setup() async {
    late three.Group shadowGroup;
    late three.Mesh plane;
    late three.Mesh fillPlane;

    const planeWidth = 2.5;
    const planeHeight = 2.5;
    const cameraHeight = 0.3;

    threeJs.camera = three.PerspectiveCamera(50, threeJs.width / threeJs.height, 0.1, 100);
    threeJs.camera.position.setValues(0.5, 1, 2);

    threeJs.scene = three.Scene();
    threeJs.scene.background = three.Color.fromHex32(0xffffff);

    threeJs.camera.lookAt(threeJs.scene.position);

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
      threeJs.scene.add(mesh);
      meshes.add(mesh);
    }

    // the container, if you need to move the plane just move this
    shadowGroup = three.Group();
    shadowGroup.position.y = -0.3;
    threeJs.scene.add(shadowGroup);

    final pars = three.WebGLRenderTargetOptions({"format": three.RGBAFormat});
    // the render target that will show the shadows in the plane texture
    renderTarget = three.WebGLRenderTarget(512, 512, pars);
    renderTarget.texture.generateMipmaps = false;

    // the render target that we will use to blur the first render target
    renderTargetBlur = three.WebGLRenderTarget(512, 512, pars);
    renderTargetBlur.texture.generateMipmaps = false;

    // make a plane and make it face up
    final planeGeometry = three.PlaneGeometry(planeWidth, planeHeight).rotateX(math.pi / 2);
    final planeMaterial = three.MeshBasicMaterial.fromMap({
      "map": renderTarget.texture,
      "opacity": state["shadow"]!["opacity"]!,
      "transparent": true,
      "depthWrite": false,
    });
    plane = three.Mesh(planeGeometry, planeMaterial);
    // make sure it's rendered after the fillPlane
    plane.renderOrder = 1;
    shadowGroup.add(plane);

    plane.rotateY(math.pi);

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

    controls = three.OrbitControls( threeJs.camera, threeJs.globalKey );

    final shadowFolder = gui.addFolder( 'shadow' )..open();
    final planeFolder = gui.addFolder( 'plane' )..open();
    final folder = gui.addFolder('gui')..open();

    shadowFolder.addSlider( state['shadow'], 'blur', 0, 15).step(0.1);
    shadowFolder.addSlider( state['shadow'], 'darkness', 1, 5)..step(0.1)..onChange((d) {
      depthMaterial.userData['darkness']['value'] = state['shadow']['darkness'];
    } );
    shadowFolder.addSlider( state['shadow'], 'opacity', 0, 1)..step(0.01 )..onChange((d) {
      plane.material?.opacity = state['shadow']['opacity'];
    } );
    planeFolder.addColor( state['plane'], 'color' ).onChange((d) {
      fillPlane.material?.color = three.Color.fromHex32( state['plane']['color'] );
    } );
    planeFolder.addSlider( state['plane'], 'opacity', 0, 1)..step(0.01)..onChange((d) {
      fillPlane.material?.opacity = state['plane']['opacity'];
    } );

    folder.addButton( state, 'showWireframe' ).onChange((d) {
      if ( state['showWireframe'] ) {
        threeJs.scene.add( cameraHelper );
      } 
      else {
        threeJs.scene.remove( cameraHelper );
      }
    });
  }
}
