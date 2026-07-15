import 'dart:math' as math;
import 'package:three_js_animations/animations/animation_clip.dart';
import 'package:three_js_animations/tracks/index.dart';
import 'package:three_js_math/three_js_math.dart';

/// A utility class with factory methods for creating basic animation clips.
class AnimationClipCreator {
  
  /// Creates an animation clip that rotates a 3D object 360 degrees
  /// in the given period of time around the given axis.
  static AnimationClip createRotationAnimation(double period, [String axis = 'x']) {
    final List<double> times = [0.0, period];
    final List<double> values = [0.0, 360.0];
    
    final String trackName = '.rotation[$axis]';
    final track = NumberKeyframeTrack(trackName, times, values);
    
    return AnimationClip('', period, [track]);
  }

  /// Creates an animation clip that scales a 3D object from `0` to `1`
  /// in the given period of time along the given axis.
  static AnimationClip createScaleAxisAnimation(double period, [String axis = 'x']) {
    final List<double> times = [0.0, period];
    final List<double> values = [0.0, 1.0];
    
    final String trackName = '.scale[$axis]';
    final track = NumberKeyframeTrack(trackName, times, values);
    
    return AnimationClip('', period, [track]);
  }

  /// Creates an animation clip that translates a 3D object in a shake pattern
  /// in the given period.
  static AnimationClip createShakeAnimation(double duration, Vector3 shakeScale) {
    final List<double> times = [];
    final List<double> values = [];
    final tmp = Vector3();
    final math.Random random = math.Random();

    for (int i = 0; i < (duration * 10).toInt(); i++) {
      times.add(i / 10.0);
      
      // Math.random() * 2.0 - 1.0 translates to random.nextDouble() * 2.0 - 1.0
      tmp.setValues(
        random.nextDouble() * 2.0 - 1.0, 
        random.nextDouble() * 2.0 - 1.0, 
        random.nextDouble() * 2.0 - 1.0
      )
      .multiply(shakeScale)
      .toNumArray(values, values.length);
    }

    const String trackName = '.position';
    final track = VectorKeyframeTrack(trackName, times, values);
    
    return AnimationClip('', duration, [track]);
  }

  /// Creates an animation clip that scales a 3D object in a pulse pattern
  /// in the given period.
  static AnimationClip createPulsationAnimation(double duration, double pulseScale) {
    final List<double> times = [];
    final List<double> values = [];
    final tmp = Vector3();
    final math.Random random = math.Random();

    for (int i = 0; i < (duration * 10).toInt(); i++) {
      times.add(i / 10.0);
      
      final double scaleFactor = random.nextDouble() * pulseScale;
      tmp.setValues(scaleFactor, scaleFactor, scaleFactor)
         .toNumArray(values, values.length);
    }

    const String trackName = '.scale';
    final track = VectorKeyframeTrack(trackName, times, values);
    
    return AnimationClip('', duration, [track]);
  }

  /// Creates an animation clip that toggles the visibility of a 3D object.
  static AnimationClip createVisibilityAnimation(double duration) {
    final List<double> times = [0.0, duration / 2.0, duration];
    final List<num> values = [1, 0, 1];
    
    const String trackName = '.visible';
    final track = BooleanKeyframeTrack(trackName, times, values);
    
    return AnimationClip('', duration, [track]);
  }

  /// Creates an animation clip that animates the `color` property of a 3D object's
  /// material.
  static AnimationClip createMaterialColorAnimation(double duration, List<Color> colors) {
    final List<double> times = [];
    final List<double> values = [];
    final double timeStep = (colors.length > 1) ? duration / (colors.length - 1) : 0.0;

    for (int i = 0; i < colors.length; i++) {
      times.add(i * timeStep);
      final Color color = colors[i];
      values.addAll([color.red, color.green, color.blue]);
    }

    const String trackName = '.material.color';
    final track = ColorKeyframeTrack(trackName, times, values);
    
    return AnimationClip('', duration, [track]);
  }
}
