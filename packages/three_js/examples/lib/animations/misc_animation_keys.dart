import 'dart:async';
import 'dart:math' as math;
import 'package:example/src/statistics.dart';
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_helpers/three_js_helpers.dart';

class MiscAnimationKeys extends StatefulWidget {
  
  const MiscAnimationKeys({super.key});

  @override
  createState() => _State();
}

class _State extends State<MiscAnimationKeys> {
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
      setup: setup
    );
    super.initState();
  }
  @override
  void dispose() {
    timer.cancel();
    threeJs.dispose();
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

  late three.Mesh mesh;
  late three.AnimationMixer mixer;
  late three.Object3D object;
  late three.Texture texture;

  Future<void> setup() async {
    threeJs.scene = three.Scene();
    threeJs.camera = three.PerspectiveCamera(40, threeJs.width / threeJs.height, 1, 1000);
    threeJs.camera.position.setValues(25, 25, 50);
    threeJs.camera.lookAt(threeJs.scene.position);

    final axesHelper = AxesHelper(10);
    threeJs.scene.add(axesHelper);

    //

    final geometry = three.BoxGeometry(5, 5, 5);
    final material = three.MeshBasicMaterial.fromMap({"color": 0xffffff, "transparent": true});
    final mesh = three.Mesh(geometry, material);
    threeJs.scene.add(mesh);

    // create a keyframe track (i.e. a timed sequence of keyframes) for each animated property
    // Note: the keyframe track type should correspond to the type of the property being animated

    // POSITION
    final positionKF = three.VectorKeyframeTrack('.position', [0, 1, 2], [0, 0, 0, 30, 0, 0, 0, 0, 0], null);

    // SCALE
    final scaleKF = three.VectorKeyframeTrack('.scale', [0, 1, 2], [1, 1, 1, 2, 2, 2, 1, 1, 1], null);

    // ROTATION
    // Rotation should be performed using quaternions, using a three.QuaternionKeyframeTrack
    // Interpolating Euler angles (.rotation property) can be problematic and is currently not supported

    // set up rotation about x axis
    final xAxis = three.Vector3(1, 0, 0);

    final qInitial = three.Quaternion().setFromAxisAngle(xAxis, 0);
    final qFinal = three.Quaternion().setFromAxisAngle(xAxis, math.pi);
    final quaternionKF = three.QuaternionKeyframeTrack(
        '.quaternion',
        [0, 1, 2],
        [
          qInitial.x,
          qInitial.y,
          qInitial.z,
          qInitial.w,
          qFinal.x,
          qFinal.y,
          qFinal.z,
          qFinal.w,
          qInitial.x,
          qInitial.y,
          qInitial.z,
          qInitial.w
        ],
        null);

    // COLOR
    final colorKF = three.ColorKeyframeTrack('.material.color', [0, 1, 2],
        [1, 0, 0, 0, 1, 0, 0, 0, 1], three.InterpolateDiscrete);

    // OPACITY
    final opacityKF = three.NumberKeyframeTrack(
        '.material.opacity', [0, 1, 2], [1, 0, 1], null);

    // create an animation sequence with the tracks
    // If a negative time value is passed, the duration will be calculated from the times of the passed tracks array
    final clip = three.AnimationClip(
        'Action', 3, [scaleKF, positionKF, quaternionKF, colorKF, opacityKF]);

    // setup the three.AnimationMixer
    mixer = three.AnimationMixer(mesh);

    // create a ClipAction and set it to play
    final clipAction = mixer.clipAction(clip);
    clipAction!.play();
    threeJs.addAnimationEvent((dt){
      mixer.update(dt);
    });
  }
}
