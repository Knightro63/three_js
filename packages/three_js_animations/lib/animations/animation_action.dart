import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';
import '../interpolants/index.dart';
import 'animation_mixer.dart';
import 'animation_clip.dart';
import 'property_mixer.dart';

/// AnimationActions schedule the performance of the animations which are
/// stored in [AnimationClips].
/// 
/// Note: Most of AnimationAction's methods can be chained.
/// 
/// For an overview of the different elements of the three.js animation system
/// see the "Animation System" article in the "Next Steps" section of the
/// manual.
class AnimationAction {
  late double time;
  late num timeScale;
  late AnimationMixer mixer;
  late AnimationClip clip;
  late Object3D? localRoot;
  late int blendMode;
  late Map _interpolantSettings;
  late List<Interpolant?> interpolants;
  late List<PropertyMixer?> propertyBindings;
  late int? cacheIndex;
  late int? byClipCacheIndex;
  late Interpolant? _timeScaleInterpolant;
  late Interpolant? _weightInterpolant;
  late int loop;
  late int _loopCount;
  late num? _startTime;
  late num _effectiveTimeScale;
  late int weight;
  late num _effectiveWeight;
  late num repetitions;
  late bool paused;
  late bool enabled;
  late bool clampWhenFinished;
  late bool zeroSlopeAtStart;
  late bool zeroSlopeAtEnd;

  /// [mixer] - the `AnimationMixer` that is controlled by
  /// this action.
  /// 
  /// [clip] - the `AnimationClip` that holds the animation
  /// data for this action.
  /// 
  /// [localRoot] - the root object on which this action is
  /// performed.
  /// 
  /// [blendMode] - defines how the animation is blended/combined
  /// when two or more animations are simultaneously played.
  /// 
  /// Note: Instead of calling this constructor directly you should instantiate
  /// an AnimationAction with [AnimationMixer.clipAction] since this method
  /// provides caching for better performance.
  AnimationAction(this.mixer, this.clip, {this.localRoot, int? blendMode}) {
    this.blendMode = blendMode ?? clip.blendMode;

    final tracks = clip.tracks; 
    final nTracks = tracks.length;

    final interpolants = List<Interpolant?>.filled(nTracks, null);

    final interpolantSettings = {
      "endingStart": ZeroCurvatureEnding,
      "endingEnd": ZeroCurvatureEnding
    };

    for (int i = 0; i != nTracks; ++i) {
      final interpolant = tracks[i].createInterpolant!(null);
      interpolants[i] = interpolant;
      interpolant.settings = interpolantSettings;
    }

    _interpolantSettings = interpolantSettings;

    this.interpolants = interpolants; // bound by the mixer

    // inside: PropertyMixer (managed by the mixer)
    propertyBindings = List<PropertyMixer?>.filled(nTracks, null);

    cacheIndex = null; // for the memory manager
    byClipCacheIndex = null; // for the memory manager

    _timeScaleInterpolant = null;
    _weightInterpolant = null;

    loop = LoopRepeat;
    _loopCount = -1;

    // global mixer time when the action is to be started
    // it's set back to 'null' upon start of the action
    _startTime = null;

    // scaled local time of the action
    // gets clamped or wrapped to 0..clip.duration according to loop
    time = 0;

    timeScale = 1;
    _effectiveTimeScale = 1;

    weight = 1;
    _effectiveWeight = 1;

    repetitions = double.infinity; // no. of repetitions when looping

    paused = false; // true -> zero effective time scale
    enabled = true; // false -> zero effective weight

    clampWhenFinished = false; // keep feeding the last frame?

    zeroSlopeAtStart = true; // for smooth interpolation w/o separate
    zeroSlopeAtEnd = true; // clips for start, loop and end
  }

  /// Tells the mixer to activate the action. This method can be chained.
  /// 
  /// Note: Activating this action doesn’t necessarily mean that the animation
  /// starts immediately: If the action had already finished before (by reaching
  /// the end of its last loop), or if a time for a delayed start has been set
  /// (via [startAt]), a [reset] must be executed first.
  /// 
  /// Some other settings ([paused]=true, [enabled]=false, [weight]=0, [timeScale]=0)
  /// can prevent the animation from playing, too.
  AnimationAction play() {
    mixer.activateAction(this);
    return this;
  }

  /// Tells the mixer to deactivate this action. This method can be chained.
  /// 
  /// The action will be immediately stopped and completely [reset].
  /// 
  /// Note: You can stop all active actions on the same mixer in one go via
  /// [mixer.stopAllAction].
  AnimationAction stop() {
    mixer.deactivateAction(this);

    return reset();
  }

  /// Resets the action. This method can be chained.
  /// 
  /// This method sets [paused] to false, [page:.enabled enabled]
  /// to true, [time] to `0`, interrupts any scheduled fading and
  /// warping, and removes the internal loop count and scheduling for delayed
  /// starting.
  /// 
  /// Note: .`reset` is always called by [stop], but .`reset` doesn’t
  /// call .`stop` itself. This means: If you want both, resetting and stopping,
  /// don’t call .`reset`; call .`stop` instead.
  AnimationAction reset() {
    paused = false;
    enabled = true;

    time = 0; // restart clip
    _loopCount = -1; // forget previous loops
    _startTime = null; // forget scheduling

    return stopFading().stopWarping();
  }

  /// Returns true if the action’s [time] is currently running.
  /// 
  /// In addition to being activated in the mixer (see [isScheduled]) the following conditions must be fulfilled: [paused] is equal to false, [enabled] is equal to true,
  /// [timeScale] is different from `0`, and there is no
  /// scheduling for a delayed start ([startAt]).
  ///
  /// Note: `isRunning` being true doesn’t necessarily mean that the animation
  /// can actually be seen. This is only the case, if [weight] is
  /// additionally set to a non-zero value.
  bool isRunning() {
    return enabled &&
        !paused &&
        timeScale != 0 &&
        _startTime == null &&
        mixer.isActiveAction(this);
  }

  /// Returns true, if this action is activated in the mixer.
  /// 
  /// Note: This doesn’t necessarily mean that the animation is actually running
  /// (compare the additional conditions for [isRunning]).
  bool isScheduled() {
    return mixer.isActiveAction(this);
  }

  /// Defines the time for a delayed start (usually passed as
  /// [AnimationMixer.time] + deltaTimeInSeconds). This method can be
  /// chained.
  /// 
  /// Note: The animation will only start at the given time, if .`startAt` is
  /// chained with [play], or if the action has already been
  /// activated in the mixer (by a previous call of .`play`, without stopping or
  /// resetting it in the meantime).
  AnimationAction startAt(time) {
    _startTime = time;

    return this;
  }

  /// Sets the loop [mode] and the number of [repetitions]. This method can be chained.
  AnimationAction setLoop(int mode, num repetitions) {
    loop = mode;
    this.repetitions = repetitions;

    return this;
  }

  /// Sets the [weight] and stops any scheduled fading. This method
  /// can be chained.
  /// 
  /// If [enabled] is true, the effective weight (an internal
  /// property) will also be set to this value; otherwise the effective weight
  /// (directly affecting the animation at this moment) will be set to `0`.
  /// 
  /// Note: .`enabled` will not be switched to `false` automatically, if
  /// .`weight` is set to `0` by this method.
  AnimationAction setEffectiveWeight(int weight) {
    this.weight = weight;

    // note: same logic as when updated at runtime
    _effectiveWeight = enabled ? weight : 0;

    return stopFading();
  }

  // return the weight considering fading and .enabled
  num getEffectiveWeight() {
    return _effectiveWeight;
  }

  /// Increases the [page:.weight weight] of this action gradually from `0` to
  /// `1`, within the passed time interval. This method can be chained.
  AnimationAction fadeIn(num duration) {
    return _scheduleFading(duration, 0, 1);
  }

  /// Decreases the [weight] of this action gradually from `1` to
  /// `0`, within the passed time interval. This method can be chained.
  AnimationAction fadeOut(num duration) {
    return _scheduleFading(duration, 1, 0);
  }

  /// Causes this action to [fadeIn], fading out another action
  /// simultaneously, within the passed time interval. This method can be
  /// chained.
  /// 
  /// If warpBoolean is true, additional [warping] (gradually changes
  /// of the time scales) will be applied.
  /// 
  /// Note: Like with `fadeIn`/`fadeOut`, the fading starts/ends with a weight
  /// of `1`.
  AnimationAction crossFadeFrom(AnimationAction fadeOutAction, num duration, bool warp) {
    fadeOutAction.fadeOut(duration);
    fadeIn(duration);

    if (warp) {
      final fadeInDuration = clip.duration,
          fadeOutDuration = fadeOutAction.clip.duration,
          startEndRatio = fadeOutDuration / fadeInDuration,
          endStartRatio = fadeInDuration / fadeOutDuration;

      fadeOutAction.warp(1.0, startEndRatio, duration);
      this.warp(endStartRatio, 1.0, duration);
    }

    return this;
  }

  /// Causes this action to [fadeOut], fading in another action
  /// simultaneously, within the passed time interval. This method can be
  /// chained.
  /// 
  /// If warpBoolean is true, additional [warping] (gradually changes
  /// of the time scales) will be applied.
  /// 
  /// Note: Like with `fadeIn`/`fadeOut`, the fading starts/ends with a weight
  /// of `1`.
  AnimationAction crossFadeTo(AnimationAction fadeInAction, num duration, bool warp) {
    return fadeInAction.crossFadeFrom(this, duration, warp);
  }

  /// Stops any scheduled [page:.fadeIn fading] which is applied to this action.
  /// This method can be chained.
  AnimationAction stopFading() {
    final weightInterpolant = _weightInterpolant;

    if (weightInterpolant != null) {
      _weightInterpolant = null;
      mixer.takeBackControlInterpolant(weightInterpolant);
    }

    return this;
  }

  /// Sets the [timeScale] and stops any scheduled warping. This
  /// method can be chained.
  /// 
  /// If [ppaused] is false, the effective time scale (an internal
  /// property) will also be set to this value; otherwise the effective time
  /// scale (directly affecting the animation at this moment) will be set to
  /// `0`.
  /// 
  /// Note: .`paused` will not be switched to `true` automatically, if
  /// .`timeScale` is set to `0` by this method.
  AnimationAction setEffectiveTimeScale(num timeScale) {
    this.timeScale = timeScale;
    _effectiveTimeScale = paused ? 0 : timeScale;

    return stopWarping();
  }

  /// Returns the effective time scale (considering the current states of
  /// warping and [paused]).
  num getEffectiveTimeScale() {
    return _effectiveTimeScale;
  }

  /// Sets the duration for a single loop of this action (by adjusting
  /// [timeScale] and stopping any scheduled warping). This
  /// method can be chained.
  AnimationAction setDuration(num duration) {
    timeScale = clip.duration / duration;

    return stopWarping();
  }

  /// Synchronizes this action with the passed other action. This method can be
  /// chained.
  /// 
  /// Synchronizing is done by setting this action’s [time] and
  /// [timeScale] values to the corresponding values of the
  /// other action (stopping any scheduled warping).
  /// 
  /// Note: Future changes of the other action's `time` and `timeScale` will not
  /// be detected.
  AnimationAction syncWith(AnimationAction action) {
    time = action.time;
    timeScale = action.timeScale;

    return stopWarping();
  }

  /// Decelerates this animation's speed to `0` by decreasing [timeScale] gradually (starting from its current value), within the passed
  /// time interval. 
  /// 
  /// This method can be chained.
  AnimationAction halt(num duration) {
    return warp(_effectiveTimeScale, 0, duration);
  }

  /// Changes the playback speed, within the passed time interval, by modifying
  /// [timeScale] gradually from `startTimeScale` to
  /// `endTimeScale`. 
  /// 
  /// This method can be chained.
  AnimationAction warp(num startTimeScale, num endTimeScale, num duration) {
    final mixer = this.mixer, now = mixer.time, timeScale = this.timeScale;

    Interpolant? interpolant = _timeScaleInterpolant;

    if (interpolant == null) {
      interpolant = mixer.lendControlInterpolant();
      _timeScaleInterpolant = interpolant;
    }

    final List<num> times = interpolant.parameterPositions;
    final List<num> values = interpolant.sampleValues;

    times[0] = now;
    times[1] = now + duration;

    values[0] = startTimeScale / timeScale;
    values[1] = endTimeScale / timeScale;

    return this;
  }

  /// Stops any scheduled [page:.warp warping] which is applied to this action.
  /// 
  /// This method can be chained.
  AnimationAction stopWarping() {
    final timeScaleInterpolant = _timeScaleInterpolant;
    if (timeScaleInterpolant != null) {
      _timeScaleInterpolant = null;
      mixer.takeBackControlInterpolant(timeScaleInterpolant);
    }
    return this;
  }

  // Object Accessors

  /// Returns the mixer which is responsible for playing this action.
  AnimationMixer getMixer() {
    return mixer;
  }

  /// Returns the clip which holds the animation data for this action.
  AnimationClip getClip() {
    return clip;
  }

  /// Returns the root object on which this action is performed
  Object3D getRoot() {
    return localRoot ?? mixer.root;
  }

  // Interna

  void update(num time, num deltaTime, num timeDirection, int accuIndex) {
    // called by the mixer
    if (!enabled) {
      // call ._updateWeight() to update ._effectiveWeight

      _updateWeight(time);
      return;
    }

    final startTime = _startTime;

    if (startTime != null) {
      // check for scheduled start of action

      final timeRunning = (time - startTime) * timeDirection;
      if (timeRunning < 0 || timeDirection == 0) {
        return; // yet to come / don't decide when delta = 0
      }

      // start
      _startTime = null; // unschedule
      deltaTime = timeDirection * timeRunning;
    }

    // apply time scale and advance time

    deltaTime *= _updateTimeScale(time);
    final clipTime = _updateTime(deltaTime);

    // note: _updateTime may disable the action resulting in
    // an effective weight of 0

    int weight = _updateWeight(time);

    if (weight > 0) {
      final interpolants = this.interpolants;
      final propertyMixers = propertyBindings;

      switch (blendMode) {
        case AdditiveAnimationBlendMode:
          for (int j = 0, m = interpolants.length; j != m; ++j) {
            //print("AnimationAction j: $j ${interpolants[ j ]} ${propertyMixers[ j ]} ");

            interpolants[j]!.evaluate(clipTime);
            propertyMixers[j]!.accumulateAdditive(weight);
          }

          break;

        case NormalAnimationBlendMode:
        default:
          for (int j = 0; j < interpolants.length; ++j) {
            //print("AnimationAction22 j: $j ${interpolants[ j ]} ${propertyMixers[ j ]} ");
            interpolants[j]!.evaluate(clipTime);
            //print("AnimationAction22 j: $j ----- ");
            propertyMixers[j]!.accumulate(accuIndex, weight);
          }
      }
    }
  }

  int _updateWeight(num time) {
    int weight = 0;

    if (enabled) {
      weight = this.weight;
      final interpolant = _weightInterpolant;

      if (interpolant != null) {
        int interpolantValue = interpolant.evaluate(time)?[0].toInt();

        weight *= interpolantValue;

        if (time > interpolant.parameterPositions[1]) {
          stopFading();

          if (interpolantValue == 0) {
            // faded out, disable
            enabled = false;
          }
        }
      }
    }

    _effectiveWeight = weight;
    return weight;
  }

  num _updateTimeScale(num time) {
    num timeScale = 0;

    if (!paused) {
      timeScale = this.timeScale;

      final interpolant = _timeScaleInterpolant;

      if (interpolant != null) {
        final interpolantValue = interpolant.evaluate(time)?[0];

        timeScale *= interpolantValue;

        if (time > interpolant.parameterPositions[1]) {
          stopWarping();

          if (timeScale == 0) {
            // motion has halted, pause
            paused = true;
          } else {
            // warp done - apply final time scale
            this.timeScale = timeScale;
          }
        }
      }
    }

    _effectiveTimeScale = timeScale;
    return timeScale;
  }

  double _updateTime(num deltaTime) {
    num duration = clip.duration;
    final loop = this.loop;

    double time = this.time + deltaTime;
    int loopCount = _loopCount;

    final pingPong = (loop == LoopPingPong);

    if (deltaTime == 0) {
      if (loopCount == -1) return time;

      return (pingPong && (loopCount & 1) == 1) ? duration - time : time;
    }

    if (loop == LoopOnce) {
      if (loopCount == -1) {
        // just started

        _loopCount = 0;
        _setEndings(true, true, false);
      }

      handle_stop:
      {
        if (time >= duration) {
          time = duration.toDouble();
        } else if (time < 0) {
          time = 0;
        } else {
          this.time = time;

          break handle_stop;
        }

        if (clampWhenFinished) {
          paused = true;
        } else {
          enabled = false;
        }

        this.time = time;

        mixer.dispatchEvent(
          Event(
            type: 'finished',
            action: this,
            direction: deltaTime < 0 ? -1 : 1
          )
        );
      }
    } 
    else {
      // repetitive Repeat or PingPong
      if (loopCount == -1) {
        // just started

        if (deltaTime >= 0) {
          loopCount = 0;

          _setEndings(true, repetitions == 0, pingPong);
        } 
        else {
          // when looping in reverse direction, the initial
          // transition through zero counts as a repetition,
          // so leave loopCount at -1
          _setEndings(repetitions == 0, true, pingPong);
        }
      }

      if (time >= duration || time < 0) {
        int loopDelta = duration == 0?0:(time / duration).floor(); // signed
        time -= duration * loopDelta;

        loopCount += loopDelta.abs();

        final pending = repetitions - loopCount;

        if (pending <= 0) {
          // have to stop (switch state, clamp time, fire event)

          if (clampWhenFinished) {
            paused = true;
          } else {
            enabled = false;
          }

          time = deltaTime > 0 ? duration.toDouble() : 0;

          this.time = time;

          mixer.dispatchEvent(
            Event(
              type: 'finished',
              action: this,
              direction: deltaTime > 0 ? 1 : -1
            )
          );
        } else {
          // keep running

          if (pending == 1) {
            // entering the last round

            final atStart = deltaTime < 0;
            _setEndings(atStart, !atStart, pingPong);
          } else {
            _setEndings(false, false, pingPong);
          }

          _loopCount = loopCount;

          this.time = time;

          mixer.dispatchEvent(
            Event(
              type: 'loop', 
              action: this, 
              loopDelta: loopDelta
            )
          );
        }
      } else {
        this.time = time;
      }

      if (pingPong && (loopCount & 1) == 1) {
        // invert time for the "pong round"

        return duration - time;
      }
    }

    return time;
  }

  void _setEndings(bool atStart,bool atEnd,bool pingPong) {
    final settings = _interpolantSettings;

    if (pingPong) {
      settings["endingStart"] = ZeroSlopeEnding;
      settings["endingEnd"] = ZeroSlopeEnding;
    } else {
      // assuming for LoopOnce atStart == atEnd == true

      if (atStart) {
        settings["endingStart"] =
            zeroSlopeAtStart ? ZeroSlopeEnding : ZeroCurvatureEnding;
      } else {
        settings["endingStart"] = WrapAroundEnding;
      }

      if (atEnd) {
        settings["endingEnd"] =
            zeroSlopeAtEnd ? ZeroSlopeEnding : ZeroCurvatureEnding;
      } else {
        settings["endingEnd"] = WrapAroundEnding;
      }
    }
  }

  AnimationAction _scheduleFading(num duration, num weightNow, num weightThen) {
    final AnimationMixer mixer = this.mixer;
    final num now = mixer.time;
    Interpolant? interpolant = _weightInterpolant;

    if (interpolant == null) {
      interpolant = mixer.lendControlInterpolant();
      _weightInterpolant = interpolant;
    }

    final times = interpolant.parameterPositions;
    final values = interpolant.sampleValues;

    times[0] = now;
    values[0] = weightNow;
    times[1] = now + duration;
    values[1] = weightThen;

    return this;
  }
}
