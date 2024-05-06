/// Object for keeping track of time. This uses
/// [DateTime.now().millisecondsSinceEpoch](https://api.flutter.dev/flutter/dart-core/DateTime-class.html).
class Clock {
  late bool autoStart;
  late int startTime;
  late int oldTime;
  late double elapsedTime;
  late bool running;

  //// [autoStart] — (optional) whether to automatically start the clock when
  /// [getDelta]() is called for the first time. Default is `true`.
  Clock([bool? autoStart]) {
    this.autoStart = (autoStart != null) ? autoStart : true;

    startTime = 0;
    oldTime = 0;
    elapsedTime = 0;

    running = false;
  }

  /// Starts clock. Also sets the [startTime] and [oldTime] to the
  /// current time, sets [elapsedTime] to `0` and [running] to
  /// `true`.
  void start() {
    startTime = now();

    oldTime = startTime;
    elapsedTime = 0;
    running = true;
  }

  /// Stops clock and sets [page:Clock.oldTime oldTime] to the current time.
  void stop() {
    getElapsedTime();
    running = false;
    autoStart = false;
  }

  /// Get the seconds passed since the clock started and sets [oldTime] to
  /// the current time.
  /// 
  /// If [autoStart] is `true` and the clock is not running, also starts
  /// the clock.
  double getElapsedTime() {
    getDelta();
    return elapsedTime;
  }

  /// Get the seconds passed since the time [oldTime] was set and sets
  /// [oldTime] to the current time.
  /// 
  /// If [autoStart] is `true` and the clock is not running, also starts
  /// the clock.
  double getDelta() {
    double diff = 0;

    if (autoStart && !running) {
      start();
      return 0;
    }

    if (running) {
      final newTime = now();
      diff = (newTime - oldTime) / 1000;
      oldTime = newTime;
      elapsedTime += diff;
    }

    return diff;
  }
}

int now() {
  return DateTime.now().millisecondsSinceEpoch; // see #10732
}
