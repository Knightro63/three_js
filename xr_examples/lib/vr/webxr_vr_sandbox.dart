import 'dart:async';
import 'dart:js_interop';
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_objects/three_js_objects.dart';
import 'package:three_js_xr/three_js_xr.dart';
import 'package:three_js_geometry/three_js_geometry.dart';
import 'dart:math' as math;

class WebXRVRSandbox extends StatefulWidget {
  const WebXRVRSandbox({super.key});
  @override
  createState() => _State();
}

class _State extends State<WebXRVRSandbox> {
  List<int> data = List.filled(60, 0, growable: true);
  late Timer timer;
  late three.ThreeJS threeJs;

  @override
  void initState() {
    timer = Timer.periodic(const Duration(seconds: 1), (t){
      setState(() {
        data.removeAt(0);
        data.add(threeJs.clock.fps);
      });
    });
    threeJs = three.ThreeJS(
      onSetupComplete: () async{setState(() {});},
      setup: setup,
      settings: three.Settings(
        xr: xrSetup,
        toneMapping: three.ACESFilmicToneMapping,
        toneMappingExposure: 1
      )
    );
    super.initState();
  }
  @override
  void dispose() {
    timer.cancel();
    threeJs.dispose();
    three.loading.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          threeJs.build(),
          if(threeJs.mounted) VRButton(threeJs: threeJs)
        ],
      ) 
    );
  }

  late three.Raycaster raycaster;
  XRReferenceSpace? baseReferenceSpace;

  WebXRWorker xrSetup(three.WebGLRenderer renderer, dynamic gl){
    return WebXRWorker(renderer,gl);
  }
  final Map<String,dynamic> parameters = {
    'radius': 0.6,
    'tube': 0.2,
    'tubularSegments': 150,
    'radialSegments': 20,
    'p': 2,
    'q': 3,
    'thickness': 0.5
  };

  Future<void> setup() async {
    threeJs.renderer?.xr.enabled = true;
    //(threeJs.renderer?.xr as WebXRWorker).addEventListener( 'sessionstart', (event) => baseReferenceSpace = (threeJs.renderer?.xr as WebXRWorker).getReferenceSpace() );

    threeJs.scene = three.Scene();

    three.RGBELoader()
      .setPath( 'textures/equirectangular/' )
      .fromAsset( 'moonless_golf_1k.hdr').then(( texture ) {
        texture.mapping = three.EquirectangularReflectionMapping;
        threeJs.scene.background = texture;
        threeJs.scene.environment = texture;
      });

    threeJs.camera = three.PerspectiveCamera( 50, threeJs.width / threeJs.height, 0.1, 10 );
    threeJs.camera.position.setValues( 0, 1.6, 1.5 );

    //
    final torusGeometry = three.TorusKnotGeometry(0.6,0.2,150,20,2,3);
    final torusMaterial = three.MeshPhysicalMaterial.fromMap( {
      'transmission': 1.0, 'roughness': 0, 'metalness': 0.25, 'thickness': 0.5, 'side': three.DoubleSide
    } );
    final torus = three.Mesh( torusGeometry, torusMaterial );
    torus.name = 'torus';
    torus.position.y = 1.5;
    torus.position.z = - 2;
    threeJs.scene.add( torus );

    final cylinderGeometry = three.CylinderGeometry( 1, 1, 0.1, 50 );
    final cylinderMaterial = three.MeshStandardMaterial();
    final cylinder = three.Mesh( cylinderGeometry, cylinderMaterial );
    cylinder.position.z = - 2;
    threeJs.scene.add( cylinder );

    // lensflare
    final loader = three.TextureLoader();
    final texture0 = (await loader.fromAsset( 'textures/lensflare/lensflare0.png' ))!;
    final texture3 = (await loader.fromAsset( 'textures/lensflare/lensflare3.png' ))!;

    final lensflare = Lensflare();
    lensflare.position.setValues( 0, 5, - 5 );
    lensflare.addElement( LensflareElement( texture0, 700, 0 ) );
    lensflare.addElement( LensflareElement( texture3, 60, 0.6 ) );
    lensflare.addElement( LensflareElement( texture3, 70, 0.7 ) );
    lensflare.addElement( LensflareElement( texture3, 120, 0.9 ) );
    lensflare.addElement( LensflareElement( texture3, 70, 1 ) );
    threeJs.scene.add( lensflare );

    //
    final reflector = Reflector( three.PlaneGeometry( 2, 2 ), {
      'textureWidth': threeJs.width * threeJs.dpr,
      'textureHeight': threeJs.height * threeJs.dpr
    });
    reflector.position.x = 1;
    reflector.position.y = 1.5;
    reflector.position.z = - 3;
    reflector.rotation.y = - math.pi / 4;
    // TOFIX: Reflector breaks transmission
    threeJs.scene.add( reflector );

    final frameGeometry = three.BoxGeometry( 2.1, 2.1, 0.1 );
    final frameMaterial = three.MeshPhongMaterial();
    final frame = three.Mesh( frameGeometry, frameMaterial );
    frame.position.z = - 0.07;
    reflector.add( frame );

    //
    final geometry = three.BufferGeometry();
    geometry.setFromPoints( [ three.Vector3( 0, 0, 0 ), three.Vector3( 0, 0, - 5 ) ] );

    final controller1 = (threeJs.renderer?.xr as WebXRWorker).getController( 0 );
    controller1?.add( three.Line( geometry ) );
    threeJs.scene.add( controller1 );

    final controller2 = (threeJs.renderer?.xr as WebXRWorker).getController( 1 );
    controller2?.add( three.Line( geometry ) );
    threeJs.scene.add( controller2 );

    //
    final controllerModelFactory = XRControllerModelFactory();

    final controllerGrip1 = (threeJs.renderer?.xr as WebXRWorker).getControllerGrip( 0 );
    controllerGrip1?.add( controllerModelFactory.createControllerModel( controllerGrip1 ) );
    threeJs.scene.add( controllerGrip1 );

    final controllerGrip2 = (threeJs.renderer?.xr as WebXRWorker).getControllerGrip( 1 );
    controllerGrip2?.add( controllerModelFactory.createControllerModel( controllerGrip2 ) );
    threeJs.scene.add( controllerGrip2 );

    // GUI
    void onChange() {
      torus.geometry?.dispose();
      torus.geometry = three.TorusKnotGeometry(0.6,0.2,150,20,2,3);
    }

    void onThicknessChange() {
      torus.material?.thickness = parameters['thickness'];
    }

    final gui = Gui( { width: 300 } );
    gui.add( parameters, 'radius', 0.0, 1.0 ).onChange( onChange );
    gui.add( parameters, 'tube', 0.0, 1.0 ).onChange( onChange );
    gui.add( parameters, 'tubularSegments', 10, 150, 1 ).onChange( onChange );
    gui.add( parameters, 'radialSegments', 2, 20, 1 ).onChange( onChange );
    gui.add( parameters, 'p', 1, 10, 1 ).onChange( onChange );
    gui.add( parameters, 'q', 0, 10, 1 ).onChange( onChange );
    gui.add( parameters, 'thickness', 0, 1 ).onChange( onThicknessChange );
    gui.domElement.style.visibility = 'hidden';

    final group = InteractiveGroup( threeJs.renderer, threeJs.camera );
    threeJs.scene.add( group );

    final mesh = HTMLMesh( gui.domElement );
    mesh.position.x = - 0.75;
    mesh.position.y = 1.5;
    mesh.position.z = - 0.5;
    mesh.rotation.y = math.pi / 4;
    mesh.scale.setScalar( 2 );
    group.add( mesh );


    // Add stats.js
    stats = Stats();
    stats.dom.style.width = '80px';
    stats.dom.style.height = '48px';
    document.body.appendChild( stats.dom );

    statsMesh = HTMLMesh( stats.dom );
    statsMesh.position.x = - 0.75;
    statsMesh.position.y = 2;
    statsMesh.position.z = - 0.6;
    statsMesh.rotation.y = Math.PI / 4;
    statsMesh.scale.setScalar( 2.5 );
    group.add( statsMesh );
  }
}
