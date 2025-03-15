import 'dart:async';
import 'dart:math' as math;
import 'package:three_js_helpers/three_js_helpers.dart';
import 'package:flutter/material.dart';
import 'package:example/src/statistics.dart';
import 'package:three_js/three_js.dart' as three;

class BoxSelection extends StatefulWidget {
  const BoxSelection({super.key});

  @override
  createState() => _State();
}

class _State extends State<BoxSelection> {
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
      onSetupComplete: (){setState(() {});},
      setup: setup,
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
          Statistics(data: data)
        ],
      ) 
    );
  }


  Future<void> setup() async {
    threeJs.camera = three.PerspectiveCamera( 70, threeJs.width / threeJs.height, 0.1, 500 );
    threeJs.camera.position.z = 50;

    threeJs.scene = three.Scene();
    threeJs.scene.background = three.Color.fromHex32( 0xf0f0f0 );
    threeJs.scene.add(threeJs.camera);
    threeJs.scene.add( three.AmbientLight( 0xaaaaaa ) );

    final light = three.SpotLight( 0xffffff, 0.7);
    light.position.setValues( 0, 25, 50 );
    light.angle = math.pi / 5;

    //light.castShadow = true;
    light.shadow?.camera?.near = 10;
    light.shadow?.camera?.far = 100;
    light.shadow?.mapSize.width = 1024;
    light.shadow?.mapSize.height = 1024;

    threeJs.scene.add( light );

    final geometry = three.BoxGeometry();

    for (int i = 0; i < 200; i ++ ) {

      final object = three.Mesh( geometry, three.MeshLambertMaterial.fromMap( { 'color': (math.Random().nextDouble() * 0xffffff).toInt() } ) );

      object.position.x = math.Random().nextDouble() * 80 - 40;
      object.position.y = math.Random().nextDouble() * 45 - 25;
      object.position.z = math.Random().nextDouble() * 45 - 25;

      object.rotation.x = math.Random().nextDouble() * 2 * math.pi;
      object.rotation.y = math.Random().nextDouble() * 2 * math.pi;
      object.rotation.z = math.Random().nextDouble() * 2 * math.pi;

      object.scale.x = math.Random().nextDouble() * 2 + 1;
      object.scale.y = math.Random().nextDouble() * 2 + 1;
      object.scale.z = math.Random().nextDouble() * 2 + 1;

      //object.castShadow = true;
      //object.receiveShadow = true;

      threeJs.scene.add( object );
    }

    final selectionBox = SelectionBox(threeJs.camera, threeJs.scene);
    final helper = SelectionHelper(threeJs.globalKey, threeJs.camera);

    threeJs.domElement.addEventListener(three.PeripheralType.pointerdown, ( event ) {
      for (final item in selectionBox.collection ) {
        item.material?.emissive?.setFromHex32( 0x000000 );
      }

      selectionBox.startPoint.setValues(
        ( event.clientX / threeJs.width ) * 2 - 1,
        - ( event.clientY / threeJs.height ) * 2 + 1,
        0.5 );
    });

    threeJs.domElement.addEventListener(three.PeripheralType.pointermove, ( event ) {
      if ( helper.isClicked ) {
        for ( int i = 0; i < selectionBox.collection.length; i ++ ) {
          if(selectionBox.collection[ i ].name != 'selector'){
            selectionBox.collection[ i ].material?.emissive?.setFromHex32( 0x000000 );
          }
        }

        selectionBox.endPoint.setValues(
          ( event.clientX / threeJs.width ) * 2 - 1,
          - ( event.clientY / threeJs.height ) * 2 + 1,
          0.5 );

        final allSelected = selectionBox.select();

        for (int i = 0; i < allSelected.length; i ++ ) {
          if(selectionBox.collection[ i ].name != 'selector'){
            allSelected[ i ].material?.emissive?.setFromHex32( 0xffffff );
          }
        }
      }
    });

    threeJs.domElement.addEventListener(three.PeripheralType.pointerup, ( event ) {
      selectionBox.endPoint.setValues(
        ( event.clientX / threeJs.width ) * 2 - 1,
        - ( event.clientY /threeJs.height ) * 2 + 1,
        0.5 );

      final allSelected = selectionBox.select();

      for (int i = 0; i < allSelected.length; i ++ ) {
        allSelected[ i ].material?.emissive?.setFromHex32( 0xffffff );
      }
    });
  }
}
