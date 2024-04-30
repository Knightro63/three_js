import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';
import '../interpolants/index.dart';
import 'animation_mixer.dart';
import 'animation_clip.dart';
import 'property_mixer.dart';

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

  AnimationAction(this.mixer, this.clip,{this.localRoot, int? blendMode}) {
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

  // State & Scheduling

  AnimationAction play() {
    mixer.activateAction(this);
    return this;
  }

  AnimationAction stop() {
    mixer.deactivateAction(this);

    return reset();
  }

  AnimationAction reset() {
    paused = false;
    enabled = true;

    time = 0; // restart clip
    _loopCount = -1; // forget previous loops
    _startTime = null; // forget scheduling

    return stopFading().stopWarping();
  }

  bool isRunning() {
    return enabled &&
        !paused &&
        timeScale != 0 &&
        _startTime == null &&
        mixer.isActiveAction(this);
  }

  // return true when play has been called
  bool isScheduled() {
    return mixer.isActiveAction(this);
  }

  AnimationAction startAt(time) {
    _startTime = time;

    return this;
  }

  AnimationAction setLoop(int mode, num repetitions) {
    loop = mode;
    this.repetitions = repetitions;

    return this;
  }

  // Weight

  // set the weight stopping any scheduled fading
  // although .enabled = false yields an effective weight of zero, this
  // method does *not* change .enabled, because it would be confusing
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

  AnimationAction fadeIn(num duration) {
    return _scheduleFading(duration, 0, 1);
  }

  AnimationAction fadeOut(num duration) {
    return _scheduleFading(duration, 1, 0);
  }

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

  AnimationAction crossFadeTo(AnimationAction fadeInAction, num duration, bool warp) {
    return fadeInAction.crossFadeFrom(this, duration, warp);
  }

  AnimationAction stopFading() {
    final weightInterpolant = _weightInterpolant;

    if (weightInterpolant != null) {
      _weightInterpolant = null;
      mixer.takeBackControlInterpolant(weightInterpolant);
    }

    return this;
  }

  // Time Scale Control

  // set the time scale stopping any scheduled warping
  // although .paused = true yields an effective time scale of zero, this
  // method does *not* change .paused, because it would be confusing
  AnimationAction setEffectiveTimeScale(num timeScale) {
    this.timeScale = timeScale;
    _effectiveTimeScale = paused ? 0 : timeScale;

    return stopWarping();
  }

  // return the time scale considering warping and .paused
  num getEffectiveTimeScale() {
    return _effectiveTimeScale;
  }

  AnimationAction setDuration(num duration) {
    timeScale = clip.duration / duration;

    return stopWarping();
  }

  AnimationAction syncWith(AnimationAction action) {
    time = action.time;
    timeScale = action.timeScale;

    return stopWarping();
  }

  AnimationAction halt(num duration) {
    return warp(_effectiveTimeScale, 0, duration);
  }

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

  AnimationAction stopWarping() {
    final timeScaleInterpolant = _timeScaleInterpolant;

    if (timeScaleInterpolant != null) {
      _timeScaleInterpolant = null;
      mixer.takeBackControlInterpolant(timeScaleInterpolant);
    }

    return this;
  }

  // Object Accessors

  AnimationMixer getMixer() {
    return mixer;
  }

  AnimationClip getClip() {
    return clip;
  }

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
