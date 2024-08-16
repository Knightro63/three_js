import 'package:three_js/three_js.dart';
import 'package:three_js_math/three_js_math.dart';
import 'package:three_js_core/three_js_core.dart';
import 'dart:math' as math;
import 'package:flutter/widgets.dart' hide Matrix4;
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';
import 'package:flutter/material.dart' hide Matrix4;

class SelectionHelper {
	Vector3 startPoint = Vector3.zero();
  Vector3 startBoxPos = Vector3.zero();
  Vector3 endPoint = Vector3.zero();

  Object3D scene;
  Camera camera;
  final _raycaster = Raycaster();
  final _pointer = Vector2.zero();
  late Mesh selectionBox;
  final _distance = 5.0;

	bool isDown = false;
	bool enabled = true;

  late GlobalKey<PeripheralsState> listenableKey;
  PeripheralsState get _domElement => listenableKey.currentState!;

	SelectionHelper(this.listenableKey, this.camera, this.scene) {
		_domElement.addEventListener( PeripheralType.pointerdown, onPointerDown );
		_domElement.addEventListener( PeripheralType.pointermove, onPointerMove );
		_domElement.addEventListener( PeripheralType.pointerup, onPointerUp );

    selectionBox = Mesh(
      PlaneGeometry(),
      MeshStandardMaterial.fromMap({
        'color': 0x0000ff,
        'transparent': true,
        'opacity': 0.25,
        'side': DoubleSide
      })
    )..name = 'selector';
	}

  void onPointerDown( event ) {
    updatePointer(event);
    if (enabled == false ) return;
    _raycaster.setFromCamera(_pointer, camera);
    _raycaster.ray.at(_distance, selectionBox.position);
    scene.add(
      selectionBox
        ..scale.setFrom(Vector3.zero())
        ..lookAt(camera.position)
    );
    isDown = true;

    startBoxPos.setFrom(selectionBox.position);
    startPoint.setFrom(selectionBox.position);
    endPoint.setFrom(Vector3.zero());
  }
  void updatePointer(event) {
    final box = listenableKey.currentContext?.findRenderObject() as RenderBox;
    final size = box.size;
    final local = box.globalToLocal(const Offset(0, 0));

    _pointer.x = (event.clientX - local.dx) / size.width * 2 - 1;
    _pointer.y = -(event.clientY - local.dy) / size.height * 2 + 1;
  }

  void onPointerMove( event ) {
    updatePointer(event);
    if (enabled == false ) return;
    if (isDown ) {
      _raycaster.setFromCamera(_pointer, camera);
      _raycaster.ray.at(_distance, endPoint);
      onSelectMove(event);
    }
  }

  void onPointerUp (event) {
    if (enabled == false ) return;
    isDown = false;
    onSelectOver();
  }

	void dispose() {
		_domElement.removeEventListener( PeripheralType.pointerdown, onPointerDown );
		_domElement.removeEventListener( PeripheralType.pointermove, onPointerMove );
		_domElement.removeEventListener( PeripheralType.pointerup, onPointerUp );
	}

	void onSelectMove( event ) {
    Vector3 scale = endPoint.clone().sub(startPoint);
    selectionBox.position.setFrom(
      startBoxPos.clone().add(scale.clone().scale(.5)..z = 0)
    );
    selectionBox.scale.setFrom(scale);
	}

	void onSelectOver() {
		scene.remove(selectionBox);
	}
}
