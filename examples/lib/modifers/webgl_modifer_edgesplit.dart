import 'dart:async';
import 'dart:math' as math;
import 'package:example/src/gui.dart';
import 'package:flutter/material.dart';
import 'package:example/src/statistics.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_modifers/buffergeometry_utils.dart';
import 'package:three_js_modifers/edge_split_modifier.dart';

class WebglModifierEdgesplit extends StatefulWidget {
  const WebglModifierEdgesplit({super.key});
  @override
  createState() => _State();
}

class _State extends State<WebglModifierEdgesplit> {
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
      onSetupComplete: (){setState(() {});},
      setup: setup,
      settings: three.Settings(
        useOpenGL: useOpenGL
      )
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
              child: gui.render()
            )
          )
        ],
      ) 
    );
  }

  late final three.OrbitControls controls;
  late final three.Mesh? mesh;
  late final EdgeSplitModifier modifier;
  late final three.BufferGeometry baseGeometry;
  three.Texture? map;

  final Map<String,dynamic> params = {
    'smoothShading': true,
    'edgeSplit': true,
    'cutOffAngle': 20.0,
    'showMap': false,
    'tryKeepNormals': true,
  };

  Future<void> setup() async {
    threeJs.scene = three.Scene();

    threeJs.camera = three.PerspectiveCamera( 75, threeJs.width / threeJs.height );

    controls = three.OrbitControls( threeJs.camera, threeJs.globalKey );
    //controls.addEventListener( 'change', render ); // use if there is no animation loop
    controls.enableDamping = true;
    controls.dampingFactor = 0.25;
    controls.rotateSpeed = 0.35;
    controls.minZoom = 1;
    threeJs.camera.position.setValues( 0, 0, 4 );

    threeJs.scene.add( three.HemisphereLight( 0xffffff, 0x444444, 0.3 ) );

    await three.OBJLoader().fromAsset('assets/models/obj/cerberus/Cerberus.obj').then(( group ) {
      final cerberus = group!.children[ 0 ];
      final modelGeometry = cerberus.geometry;

      modifier = EdgeSplitModifier();
      baseGeometry = BufferGeometryUtils.mergeVertices( modelGeometry! );

      mesh = three.Mesh( getGeometry(), three.MeshStandardMaterial() );
      mesh?.material?.flatShading = !params['smoothShading'];
      mesh?.rotateY( - math.pi / 2 );
      mesh?.scale.setValues( 3.5, 3.5, 3.5 );
      mesh?.translateZ( 1.5 );
      threeJs.scene.add( mesh );

      if ( map != null && params['showMap'] ) {
        mesh!.material?.map = map;
        mesh!.material?.needsUpdate = true;
      }
    });


    await three.TextureLoader(flipY: true).fromAsset( 'assets/models/obj/cerberus/Cerberus_A.jpg').then(( texture ) {
      map = texture;
      map?.colorSpace = three.SRGBColorSpace;

      if ( mesh != null && params['showMap'] ) {
        mesh?.material?.map = map;
        mesh?.material?.needsUpdate = true;
      }
    });

    threeJs.addAnimationEvent((dt){
      controls.update();
    });

    final folder = gui.addFolder('Edge split modifier parameters')..open();

    folder.addButton( params, 'showMap' ).onFinishChange( updateMesh );
    folder.addButton( params, 'smoothShading' ).onFinishChange( updateMesh );
    folder.addButton( params, 'edgeSplit' ).onFinishChange( updateMesh );
    folder.addSlider( params, 'cutOffAngle',0.0,180.0 )..step(1.0)..onFinishChange( updateMesh );
    folder.addButton( params, 'tryKeepNormals' ).onFinishChange( updateMesh );
  }

  three.BufferGeometry getGeometry() {
    three.BufferGeometry geometry;

    if (params['edgeSplit']) {
      geometry = modifier.modify(
        baseGeometry,
        params['cutOffAngle'] * math.pi / 180,
        params['tryKeepNormals']
      );
    } 
    else {
      geometry = baseGeometry;
    }
    return geometry;
  }

  void updateMesh() {
    if ( mesh != null ) {
      mesh?.geometry = getGeometry();
      bool needsUpdate = mesh?.material?.flatShading == params['smoothShading'];
      mesh?.material?.flatShading = params['smoothShading'] == false;

      if ( map != null ) {
        needsUpdate = needsUpdate || mesh?.material?.map != ( params['showMap'] ? map : null );
        mesh?.material?.map = params['showMap'] ? map : null;
      }

      mesh?.material?.needsUpdate = needsUpdate;
    }
  }
}
