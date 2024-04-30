part of three_js_controls;

final _changeEvent = Event(type: 'change');
final _startEvent = Event(type: 'start');
final _endEvent = Event(type: 'end');
final _euler = Euler(0, 0, 0, RotationOrders.yxz);
final _vector = Vector3.zero();
final _lockEvent = Event(type: 'lock');
final _unlockEvent = Event(type: 'unlock');
final _raycaster = Raycaster();
final _plane = Plane();
final _pointer = Vector2.zero();
final _offset = Vector3.zero();
final _intersection = Vector3.zero();
final _worldPosition = Vector3.zero();
final _inverseMatrix = Matrix4.identity();
