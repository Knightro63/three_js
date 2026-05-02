part of three_webgl;

class AngleAnimation {
  dynamic context;
  bool isAnimating = false;
  dynamic animationLoop;
  dynamic requestId;

  AngleAnimation();

  void onAnimationFrame(double time, int frame) {
    animationLoop(time, frame);
    requestId = context.requestAnimationFrame(onAnimationFrame);
  }

  void start() {
    if (isAnimating == true) return;
    if (animationLoop == null) return;

    requestId = context.requestAnimationFrame(onAnimationFrame);
    isAnimating = true;
  }

  void stop() {
    context?.cancelAnimationFrame(requestId);
    isAnimating = false;
  }

  void setAnimationLoop(callback) {
    animationLoop = callback;
  }

  void setContext(value) {
    context = value;
  }
}
