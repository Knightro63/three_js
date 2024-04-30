import 'object_3d.dart';

/// https://github.com/mrdoob/eventdispatcher.js/
class Event {
  Event({
    this.type,
    this.target,
    this.attachment,
    this.action,
    this.direction = 1,
    this.mode,
    this.loopDelta = 0,
    this.object,
    this.value,
    this.data
  });

  late String? type;
  dynamic target;
  dynamic attachment;
  dynamic action;
  dynamic value;
  late int direction;
  dynamic data;
  late Object3D? object;
  int loopDelta = 0;
  String? mode;

  Event.fromJson(Map<String, dynamic> json) {
    type = json["type"];
    target = json["target"];
    attachment = json["attachment"];
    action = json["action"];
    direction = json["direction"];
    mode = json["mode"];
    object = json["object"];
    value = json['value'];
    data = json['data'];
  }
}

mixin EventDispatcher {
  Map<String, List<Function>>? _listeners = {};

  void addEventListener(String type, Function listener) {
    _listeners ??= {};

    Map<String, List<Function>> listeners = _listeners!;

    if (listeners[type] == null) {
      listeners[type] = [];
    }

    if (!listeners[type]!.contains(listener)) {
      listeners[type]!.add(listener);
    }
  }

  bool hasEventListener(String type, Function listener) {
    if (_listeners == null) return false;
    final listeners = _listeners!;
    return listeners[type] != null && listeners[type]!.contains(listener);
  }

  void removeEventListener(String type, Function listener) {
    if (_listeners == null) return;

    final listeners = _listeners!;
    final listenerArray = listeners[type];

    if (listenerArray != null) {
      final index = listenerArray.indexOf(listener);

      if (index != -1) {
        listenerArray.removeRange(index, index + 1);
      }
    }
  }

  void dispatchEvent(Event event) {
    if (_listeners == null || _listeners!.isEmpty) return;

    final listeners = _listeners!;
    final listenerArray = listeners[event.type];

    // print("dispatchEvent event: ${event.type} ");

    if (listenerArray != null) {
      event.target = this;

      // Make a copy, in case listeners are removed while iterating.
      final array = listenerArray.sublist(0);

      for (int i = 0, l = array.length; i < l; i++) {
        final Function fn = array[i];
        fn(event);
      }

      event.target = null;
    }
  }

  void clearListeners() {
    _listeners?.clear();
  }
}
