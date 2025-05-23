import 'package:flutter/widgets.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum PeripheralType{
  keydown,
  keyup,
  wheel,
  pointerdown,//touchstart,
  pointermove,//touchmove,
  pointerup,//touchend,
  pointerHover,
  pointerleave,
  pointercancel,
  pointerlockchange,
  pointerlockerror,
  contextmenu,
  resize,
  orientationchange,
  deviceorientation
}

class Peripherals extends StatefulWidget{
  final WidgetBuilder builder;

  const Peripherals({
    super.key, 
    required this.builder,
  });

  @override
  State<StatefulWidget> createState() {
    return PeripheralsState();
  }
}

class PeripheralsState extends State<Peripherals> {
  final Map<PeripheralType, List<Function>> _listeners = {};
  late FocusNode focusNode = FocusNode();

  double? _clientWidth;
  double? _clientHeight;

  double? _offsetLeft;
  double? _offsetTop;

  double get clientWidth => _clientWidth!;
  double get clientHeight => _clientHeight!;

  double get offsetLeft => _offsetLeft!;
  double get offsetTop => _offsetTop!;

  dynamic pointerLockElement;

  late final PanGestureRecognizer panGestureRecognizer;

  double _prevScale = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((t) {
      if (_clientWidth == null || _clientHeight == null) {
        RenderBox getBox = context.findRenderObject() as RenderBox;
        _clientWidth = getBox.size.width;
        _clientHeight = getBox.size.height;
        Offset temp = getBox.localToGlobal(Offset.zero);
        _offsetLeft = temp.dx;
        _offsetTop = temp.dy;
        
      }
      FocusScope.of(context).requestFocus(focusNode);
    });

    panGestureRecognizer = PanGestureRecognizer(
      supportedDevices: {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.invertedStylus,
        PointerDeviceKind.trackpad
      }
    )
    ..onStart = (event){
      _onDragEvent(context, PeripheralType.pointerdown ,event);
    }
    ..onEnd = (event){
      _onDragEvent(context, PeripheralType.pointerup, event);
    }
    ..onUpdate = (event){
      _onDragEvent(context, PeripheralType.pointermove,event);
    };
  }

  void removeAllListeners() {
    _listeners.clear();
  }

  void addEventListener(PeripheralType name, Function callback, [bool flag = false]) {
    final cls = _listeners[name] ?? [];
    cls.add(callback);
    _listeners[name] = cls;
  }

  void removeEventListener(PeripheralType name, Function callback, [bool flag = false]) {
    final cls = _listeners[name] ?? [];
    cls.remove(callback);
    _listeners[name] = cls;
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: focusNode,
      onKeyEvent: (event){
        if(event is KeyDownEvent){
          _onKeyDownEvent(context, event.logicalKey);
        }
        else if(event is KeyUpEvent){
          _onKeyUpEvent(context, event.logicalKey);
        }
      },
      child:GestureDetector(
        onScaleUpdate: (event){
          if (event.pointerCount > 1) {
            double s = event.scale-_prevScale < 0?1:-1;
            _onScaleEvent(context, PeripheralType.wheel, {'scale':s});
            _prevScale = event.scale;
          } else {
            // There's only 1 pointer on screen. This is not a scale event.
          }
        },
        child: Listener(
          onPointerPanZoomStart: panGestureRecognizer.addPointerPanZoom,
          // onPointerSignal: (event) {
          //   if (event is PointerScrollEvent) {
          //     _onPointerEvent(context, PeripheralType.wheel, event);
          //   }
          // },
          onPointerDown: (PointerDownEvent event) {
            _onPointerEvent(context, PeripheralType.pointerdown, event);
            FocusScope.of(context).requestFocus(focusNode);
          },
          onPointerMove: (PointerMoveEvent event) {
            _onPointerEvent(context, PeripheralType.pointermove, event);
          },
          onPointerUp: (PointerUpEvent event) {
            _onPointerEvent(context, PeripheralType.pointerup, event);
          },
          onPointerHover: (PointerHoverEvent event){
            _onPointerEvent(context, PeripheralType.pointerHover , event);
          },
          child: widget.builder(context),
        )
      )
    );
  }
  void _onKeyDownEvent(BuildContext context, LogicalKeyboardKey event){
    //final wpe = WebPointerEvent.fromPointerScrollEvent(context, event);
    _emit(PeripheralType.keydown, event);
  }
  void _onKeyUpEvent(BuildContext context, LogicalKeyboardKey event){
    //final wpe = WebPointerEvent.fromPointerScrollEvent(context, event);
    _emit(PeripheralType.keyup, event);
  }

  void _onScaleEvent(BuildContext context, PeripheralType type, event) {
    final wpe = WebPointerEvent.fromScaleEvent(context, event);
    _emit(type, wpe);
  }
  void _onDragEvent(BuildContext context, PeripheralType type, event) {
    final wpe = WebPointerEvent.fromDragEvent(context, event);
    _emit(type, wpe);
  }
  void _onPointerEvent(BuildContext context, PeripheralType type, PointerEvent event) {
    final wpe = WebPointerEvent.fromPointerEvent(context, event);
    _emit(type, wpe);
  }

  void _emit(PeripheralType name, event) {
    final callbacks = _listeners[name];
    if (callbacks != null && callbacks.isNotEmpty) {
      for (int i = 0; i < callbacks.length; i++) {
        final cb = callbacks[i];
        cb(event);
      }
    }
  }
}

class WebPointerEvent {
  late int pointerId;
  late int button;
  String pointerType = 'touch';
  late double clientX;
  late double clientY;
  late double pageX;
  late double pageY;

  late double movementX;
  late double movementY;

  bool ctrlKey = false;
  bool metaKey = false;
  bool shiftKey = false;
  bool isPrimary = true;

  int deltaMode = 0;
  double deltaY = 0.0;
  double deltaX = 0.0;

  List<EventTouch> touches = [];
  List<EventTouch> changedTouches = [];

  WebPointerEvent();

  static String getPointerType(event) {
    return event.kind == PointerDeviceKind.touch ? 'touch' : 'mouse';
  }

  static int getButton(event) {
    if(event is DragUpdateDetails || event is DragStartDetails){
      return 0;
    }
    else if(event is ScaleUpdateDetails){
      return 4;
    }
    else if (
      event.kind == PointerDeviceKind.touch && 
      event is PointerDownEvent
    ) {
      return 0;
    }
    else if(event is PointerPanZoomUpdateEvent){
      return 2;
    }
    else {
      final leftButtonPressed = event.buttons & 1 > 0;
      final rightButtonPressed = event.buttons & 2 > 0;
      final middleButtonPressed = event.buttons & 4 > 0;

      // Left button takes precedence over other
      if (leftButtonPressed) return 0;
      // 2nd priority is the right button
      if (rightButtonPressed) return 2;
      // Lastly the middle button
      if (middleButtonPressed) return 1;

      // Other buttons pressed? Just return the default (left)
      return 0;
    }
  }

  static WebPointerEvent convertPointerEvent(BuildContext context, PointerEvent event) {
    final wpe = WebPointerEvent();

    wpe.pointerId = event.pointer;
    wpe.pointerType = getPointerType(event);
    wpe.button = getButton(event);

    RenderBox getBox = context.findRenderObject() as RenderBox;
    final local = getBox.globalToLocal(event.position);
    wpe.clientX = local.dx;
    wpe.clientY = local.dy;
    wpe.pageX = event.position.dx;
    wpe.pageY = event.position.dy;

    //if(event is PointerMoveEvent || event is PointerHoverEvent) {
      wpe.movementX = event.delta.dx;
      wpe.movementY = event.delta.dy;
    //}

    if (event is PointerScrollEvent) {
      wpe.deltaX = event.scrollDelta.dx;
      wpe.deltaY = event.scrollDelta.dy;
    }
    else if(event is PointerPanZoomUpdateEvent){
      wpe.deltaX = event.localPanDelta.dx;
      wpe.deltaY = event.localPanDelta.dy;

      wpe.clientX = event.position.dx - event.pan.dx;
      wpe.clientY = event.position.dy - event.pan.dy;
    }
    final EventTouch touch = EventTouch();

    touch.pointer = event.pointer;
    touch.pageX = event.position.dx;
    touch.pageY = event.position.dy;
    touch.clientX = local.dx;
    touch.clientY = local.dy;

    wpe.touches.add(touch);
    wpe.changedTouches = [touch];

    return wpe;
  }

  static WebPointerEvent convertDragEvent(BuildContext context, event) {
    final wpe = WebPointerEvent();

    wpe.pointerId = 512;
    wpe.pointerType = 'touch_pad';
    wpe.button = 0;

    RenderBox getBox = context.findRenderObject() as RenderBox;
    final local = getBox.globalToLocal(event.globalPosition);
    wpe.clientX = local.dx;
    wpe.clientY = local.dy;

    wpe.pageX = event.globalPosition.dx;
    wpe.pageY = event.globalPosition.dy;
    if(event is! DragStartDetails && event is! DragEndDetails){
      wpe.movementX = event.delta.dx;
      wpe.movementY = event.delta.dy;
    }

    wpe.deltaX = event.globalPosition.dx;
    wpe.deltaY = event.globalPosition.dy;
    wpe.clientX = event.globalPosition.dx;
    wpe.clientY = event.globalPosition.dy;

    final EventTouch touch = EventTouch();

    touch.pointer = 512;
    touch.pageX = event.localPosition.dx;
    touch.pageY = event.localPosition.dy;
    touch.clientX = event.localPosition.dx;
    touch.clientY = event.localPosition.dy;

    wpe.touches.add(touch);
    wpe.changedTouches = [touch];

    return wpe;
  }
  static WebPointerEvent convertScaleEvent(BuildContext context, event) {
    final wpe = WebPointerEvent();

    wpe.pointerId = 522;
    wpe.pointerType = 'mouse';
    wpe.button = 4;

    wpe.clientX = event['scale'];
    wpe.clientY = event['scale'];

    wpe.pageX = event['scale'];
    wpe.pageY = event['scale'];
    wpe.movementX = event['scale'];
    wpe.movementY = event['scale'];

    wpe.deltaX = event['scale'];
    wpe.deltaY = event['scale'];

    wpe.clientX = event['scale'];
    wpe.clientY = event['scale'];

    final EventTouch touch = EventTouch();

    touch.pointer = 522;
    touch.pageX = event['scale'];
    touch.pageY = event['scale'];

    touch.clientX = event['scale'];
    touch.clientY = event['scale'];

    wpe.touches.add(touch);
    wpe.changedTouches = [touch];

    return wpe;
  }

  factory WebPointerEvent.fromPointerEvent(BuildContext context, PointerEvent event) {
    return convertPointerEvent(context, event);
  }
  factory WebPointerEvent.fromDragEvent(BuildContext context, event) {
    return convertDragEvent(context, event);
  }
  factory WebPointerEvent.fromScaleEvent(BuildContext context, event) {
    return convertScaleEvent(context, event);
  }
  @override
  String toString() {
    return "pointerId: $pointerId button: $button pointerType: $pointerType clientX: $clientX clientY: $clientY pageX: $pageX pageY: $pageY ";
  }
}

class EventTouch {
  late int pointer;
  double? pageX;
  double? pageY;

  double? clientX;
  double? clientY;
}