import 'object_3d.dart'; 
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
    this.data,
    this.handedness
  });

  late String? type;
  dynamic target;
  dynamic attachment;
  dynamic action;
  dynamic value;
  dynamic handedness;
  dynamic inputSource;
  dynamic frame;
  late int direction;
  dynamic data;
  late Object3D? object;
  int loopDelta = 0;
  String? mode;

  List added = [];
  List removed = [];

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

  @override
  String toString(){
    return{
      'type': type,
      'target': target,
      'attachment': attachment,
      'action': action,
      'direction': direction,
      'mode': mode,
      'object': object,
      'value': value,
      'data': data,
      'loopDelta': loopDelta,
      'handedness': handedness
    }.toString();
  }

  void dispose(){
    object?.dispose();
  }
}

/// JavaScript events for custom objects.
/// 
/// [EventDispatcher on GitHub](https://github.com/mrdoob/eventdispatcher.js)
/// 
/// ```
/// // Adding events to a custom object
/// class Car with EventDispatcher {
/// 	start() {
/// 		this.dispatchEvent( { type: 'start', message: 'vroom vroom!' } );
/// 	}
/// }
///
/// // Using events with the custom object
/// final car = Car();
/// car.addEventListener(
///   'start', 
///   (event){
/// 	  alert( event.message );
///   }
/// );
///
/// car.start();
/// ```
///
mixin EventDispatcher {
  Map<String, List<Function>>? _listeners = {};

  void dispose(){
    _listeners?.clear();
  }

  /// [type] - The type of event to listen to.
  /// 
  /// [listener] - The function that gets called when the event is fired.
  /// 
  /// Adds a listener to an event type.
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

  /// [type] - The type of event to listen to.
  /// 
  /// [listener] - The function that gets called when the event is fired.
  /// 
  /// Checks if listener is added to an event type.
  bool hasEventListener(String type, Function listener) {
    if (_listeners == null) return false;
    final listeners = _listeners!;
    return listeners[type] != null && listeners[type]!.contains(listener);
  }

  /// type - The type of the listener that gets removed.
  /// 
  /// listener - The listener function that gets removed.
  /// 
  /// Removes a listener from an event type.
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

  /// [event] - The event that gets fired.
  /// 
  /// Fire an event type.
  void dispatchEvent(Event event) {
    if (_listeners == null || _listeners!.isEmpty) return;
    final listeners = _listeners!;
    final listenerArray = listeners[event.type];

    if (listenerArray != null) {
      event.target = this;
      final array = listenerArray.sublist(0);

      for (int i = 0, l = array.length; i < l; i++) {
        final Function fn = array[i];
        fn(event);
      }

      event.target = null;
    }
  }

  /// Remove all Listeners.
  void clearListeners() {
    _listeners?.clear();
  }
}
