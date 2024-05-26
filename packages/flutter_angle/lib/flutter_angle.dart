library flutter_angle;

export 'desktop/index.dart'
  if (dart.library.js) 'webgl/index.dart';
//export 'webgl/index.dart';
export 'shared/webgl.dart';
export 'shared/options.dart';
export 'shared/classes.dart';