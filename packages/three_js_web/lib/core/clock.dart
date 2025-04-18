@JS('THREE')
import 'dart:js_interop';

@JS('Clock')
class Clock {
  external bool autoStart;
  external int startTime;
  external int oldTime;
  external double elapsedTime;
  external bool running;
  int fps = 0;

  external Clock([bool autoStart = true]);
  external void start();
  external void stop();
  external double getElapsedTime();
  external double getDelta();
}

int now() {
  return DateTime.now().millisecondsSinceEpoch; // see #10732
}
