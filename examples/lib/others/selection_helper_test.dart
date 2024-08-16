import 'package:three_js/three_js.dart';
import 'package:three_js_math/three_js_math.dart';
import 'package:three_js_core/three_js_core.dart';
import 'dart:math' as math;
import 'package:flutter/widgets.dart' hide Matrix4;
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';
import 'package:flutter/material.dart' hide Matrix4;

class SelectionHelper extends CustomPainter{
	final startPoint = Vector2.zero();  
  final _pointer = Vector2.zero();

	bool isDown = false;
	bool enabled = true;

  late GlobalKey<PeripheralsState> listenableKey;
  PeripheralsState get _domElement => listenableKey.currentState!;

	SelectionHelper(this.listenableKey) {
		_domElement.addEventListener( PeripheralType.pointerdown, onPointerDown );
		_domElement.addEventListener( PeripheralType.pointermove, onPointerMove );
		_domElement.addEventListener( PeripheralType.pointerup, onPointerUp );
	}

  void onPointerDown( event ) {
    updatePointer(event);
    if (enabled == false ) return;
    startPoint.setFrom(_pointer);
    isDown = true;
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

	}

	void onSelectOver() {
		//scene.remove(selectionBox);
	}

  void render(Canvas canvas, Size size){
    print('here');

    Rect totalRect = Rect.fromLTWH(0, 0, double.infinity,double.infinity);
    canvas.saveLayer(totalRect, Paint());
     final paint = Paint()
      ..style = PaintingStyle.fill
      ..strokeWidth = 2
      ..color = Colors.blue
      ..blendMode = BlendMode.srcOver;
      canvas.drawRRect(
        RRect.fromLTRBR(
          startPoint.x, 
          startPoint.y, 
          _pointer.x, 
          _pointer.y,
          const Radius.circular(5)
        ), paint
      );
      canvas.restore();
  }

  @override
  void paint(Canvas canvas, Size size) {
    render(canvas, size);
  }

  // We should repaint whenever the board changes, such as board.selected.
  @override
  bool shouldRepaint(SelectionHelper oldDelegate) {
    return true;
  }
}