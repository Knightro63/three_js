import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';
import 'package:flutter/widgets.dart' hide Matrix4;
import 'package:flutter/material.dart' hide Matrix4;

class SelectionHelperOptions{
  SelectionHelperOptions({
    this.color = 0x0000ff,
    this.opacity = 0.25,
    this.button = 0
  });

  int color;
  int button;
  double opacity;
}

class SelectionHelper {
  Vector2 ratio = Vector2(0.95,0.7);
	Vector3 _startPoint = Vector3.zero();
  Vector3 _endPoint = Vector3.zero();

  Camera camera;
  final _pointer = Vector2.zero();
  late Mesh selectionBox;

  bool get isClicked => _isDown;
	bool _isDown = false;
	bool enabled = true;
  double cameraDist = -1;

  late SelectionHelperOptions options;

  late GlobalKey<PeripheralsState> listenableKey;
  PeripheralsState get _domElement => listenableKey.currentState!;

	SelectionHelper(this.listenableKey, this.camera, [SelectionHelperOptions? options]) {
    this.options = options ?? SelectionHelperOptions();
		_domElement.addEventListener( PeripheralType.pointerdown, onPointerDown );
		_domElement.addEventListener( PeripheralType.pointermove, onPointerMove );
		_domElement.addEventListener( PeripheralType.pointerup, onPointerUp );

    selectionBox = Mesh(
      PlaneGeometry(),
      MeshStandardMaterial.fromMap({
        'color': this.options.color,
        'transparent': true,
        'opacity': this.options.opacity,
        'side': DoubleSide
      })
    )..name = 'selector';
	}

  void onPointerDown( event ) {
    if (enabled == false || event.button != options.button) return;
    updatePointer(event);
    camera.add(
      selectionBox
        ..scale.setFrom(Vector3.zero())
        ..position.z = cameraDist
        ..position.x = _pointer.x
        ..position.y = _pointer.y
    );
    _isDown = true;

    _startPoint.setFrom(selectionBox.position);
    _startPoint.z = 0;
    _endPoint.setFrom(Vector3.zero());
  }
  void updatePointer(event) {
    final box = listenableKey.currentContext?.findRenderObject() as RenderBox;
    final size = box.size;
    //final local = box.globalToLocal(const Offset(0, 0));
    _pointer.x = ((event.clientX) / size.width * 2 - 1)*ratio.x;
    _pointer.y = (-(event.clientY) / size.height * 2 + 1)*ratio.y;
  }

  void onPointerMove( event ) {
    if (!enabled || !_isDown) return;
    updatePointer(event);
    _endPoint.setFrom(_pointer);
    _endPoint.z = 0;
    onSelectMove(event);
  }

  void onPointerUp (event) {
    if (!enabled || !_isDown) return;
    _isDown = false;
    onSelectOver();
  }

	void dispose() {
		_domElement.removeEventListener( PeripheralType.pointerdown, onPointerDown );
		_domElement.removeEventListener( PeripheralType.pointermove, onPointerMove );
		_domElement.removeEventListener( PeripheralType.pointerup, onPointerUp );
	}

	void onSelectMove( event ) {
    Vector3 scale = _endPoint.clone().sub(_startPoint);
    selectionBox.position.setFrom(
      _startPoint.clone().add(scale.clone().scale(0.5))
    );
    selectionBox.scale.setFrom(scale);
    selectionBox.position.z = cameraDist;
	}

	void onSelectOver() {
		camera.remove(selectionBox);
	}
}
