import 'dart:math' as math;

import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';

enum ETTypes{None,In,Out,InOut}
/**
 * The Ease class provides a collection of easing functions for use with tween.js.
 */
class Easing{
  static Map<ETTypes,num Function(num,[num?])> Linear = {
    ETTypes.None:(amount,[power]) {
      return amount;
    },
    ETTypes.In:(amount,[power]) {
      return amount;
    },
    ETTypes.Out:(amount,[power]) {
      return amount;
    },
    ETTypes.InOut:(amount,[power]) {
      return amount;
    },
  };
  static Map<ETTypes,num Function(num,[num?])> Quadratic = {
    ETTypes.In:(amount,[power]) {
      return amount * amount;
    },
    ETTypes.Out:(amount,[power]) {
      return amount * (2 - amount);
    },
    ETTypes.InOut:(amount,[power]) {
      if ((amount *= 2) < 1) {
        return 0.5 * amount * amount;
      }
      return -0.5 * (--amount * (amount - 2) - 1);
    },
  };
  static Map<ETTypes,num Function(num,[num?])> Cubic ={
    ETTypes.In:(amount,[power]) {
      return amount * amount * amount;
    },
    ETTypes.Out:(amount,[power]) {
      return --amount * amount * amount + 1;
    },
    ETTypes.InOut:(amount,[power]) {
      if ((amount *= 2) < 1) {
        return 0.5 * amount * amount * amount;
      }
      return 0.5 * ((amount -= 2) * amount * amount + 2);
    },
  };
  static Map<ETTypes,num Function(num,[num?])> Quartic = {
    ETTypes.In:(amount,[power]) {
      return amount * amount * amount * amount;
    },
    ETTypes.Out:(amount,[power]) {
      return 1 - --amount * amount * amount * amount;
    },
    ETTypes.InOut:(amount,[power]) {
      if ((amount *= 2) < 1) {
        return 0.5 * amount * amount * amount * amount;
      }
      return -0.5 * ((amount -= 2) * amount * amount * amount - 2);
    },
  };
  static Map<ETTypes,num Function(num,[num?])> Quintic = {
    ETTypes.In:(amount,[power]) {
      return amount * amount * amount * amount * amount;
    },
    ETTypes.Out:(amount,[power]) {
      return --amount * amount * amount * amount * amount + 1;
    },
    ETTypes.InOut:(amount,[power]) {
      if ((amount *= 2) < 1) {
          return 0.5 * amount * amount * amount * amount * amount;
      }
      return 0.5 * ((amount -= 2) * amount * amount * amount * amount + 2);
    },
  };
  static Map<ETTypes,num Function(num,[num?])> Sinusoidal = {
    ETTypes.In:(amount,[power]) {
      return 1 - math.sin(((1.0 - amount) * math.pi) / 2);
    },
    ETTypes.Out:(amount,[power]) {
      return math.sin((amount * math.pi) / 2);
    },
    ETTypes.InOut:(amount,[power]) {
      return 0.5 * (1 - math.sin(math.pi * (0.5 - amount)));
    },
  };
  static Map<ETTypes,num Function(num,[num?])> Exponential = {
    ETTypes.In:(amount,[power]) {
      return amount == 0 ? 0 : math.pow(1024, amount - 1);
    },
    ETTypes.Out:(amount,[power]) {
      return amount == 1 ? 1 : 1 - math.pow(2, -10 * amount);
    },
    ETTypes.InOut:(amount,[power]) {
      if (amount == 0) {
        return 0;
      }
      if (amount == 1) {
        return 1;
      }
      if ((amount *= 2) < 1) {
        return 0.5 * math.pow(1024, amount - 1);
      }
      return 0.5 * (-math.pow(2, -10 * (amount - 1)) + 2);
    },
  };
  static Map<ETTypes,num Function(num,[num?])> Circular = {
    ETTypes.In:(amount,[power]) {
      return 1 - math.sqrt(1 - amount * amount);
    },
    ETTypes.Out:(amount,[power]) {
      return math.sqrt(1 - --amount * amount);
    },
    ETTypes.InOut:(amount,[power]) {
      if ((amount *= 2) < 1) {
        return -0.5 * (math.sqrt(1 - amount * amount) - 1);
      }
      return 0.5 * (math.sqrt(1 - (amount -= 2) * amount) + 1);
    },
  };
  static Map<ETTypes,num Function(num,[num?])> Elastic = {
    ETTypes.In:(amount,[power]) {
      if (amount == 0) {
        return 0;
      }
      if (amount == 1) {
        return 1;
      }
      return -math.pow(2, 10 * (amount - 1)) * math.sin((amount - 1.1) * 5 * math.pi);
    },
    ETTypes.Out:(amount,[power]) {
      if (amount == 0) {
        return 0;
      }
      if (amount == 1) {
        return 1;
      }
      return math.pow(2, -10 * amount) * math.sin((amount - 0.1) * 5 * math.pi) + 1;
    },
    ETTypes.InOut:(amount,[power]) {
      if (amount == 0) {
        return 0;
      }
      if (amount == 1) {
        return 1;
      }
      amount *= 2;
      if (amount < 1) {
        return -0.5 * math.pow(2, 10 * (amount - 1)) * math.sin((amount - 1.1) * 5 * math.pi);
      }
      return 0.5 * math.pow(2, -10 * (amount - 1)) * math.sin((amount - 1.1) * 5 * math.pi) + 1;
    },
  };
  static Map<ETTypes,num Function(num,[num?])> Back = {
    ETTypes.In:(amount,[power]) {
      var s = 1.70158;
      return amount == 1 ? 1 : amount * amount * ((s + 1) * amount - s);
    },
    ETTypes.Out:(amount,[power]) {
      var s = 1.70158;
      return amount == 0 ? 0 : --amount * amount * ((s + 1) * amount + s) + 1;
    },
    ETTypes.InOut:(amount,[power]) {
      var s = 1.70158 * 1.525;
      if ((amount *= 2) < 1) {
        return 0.5 * (amount * amount * ((s + 1) * amount - s));
      }
      return 0.5 * ((amount -= 2) * amount * ((s + 1) * amount + s) + 2);
    },
  };
  static Map<ETTypes,num Function(num,[num?])> Bounce ={
    ETTypes.In:(amount,[power]) {
        return 1 - Easing.Bounce[ETTypes.Out]!(1 - amount);
    },
    ETTypes.Out:(amount,[power]) {
      if (amount < 1 / 2.75) {
          return 7.5625 * amount * amount;
      }
      else if (amount < 2 / 2.75) {
          return 7.5625 * (amount -= 1.5 / 2.75) * amount + 0.75;
      }
      else if (amount < 2.5 / 2.75) {
          return 7.5625 * (amount -= 2.25 / 2.75) * amount + 0.9375;
      }
      else {
          return 7.5625 * (amount -= 2.625 / 2.75) * amount + 0.984375;
      }
    },
    ETTypes.InOut:(amount,[power]) {
      if (amount < 0.5) {
          return Easing.Bounce[ETTypes.In]!(amount * 2) * 0.5;
      }
      return Easing.Bounce[ETTypes.Out]!(amount * 2 - 1) * 0.5 + 0.5;
    },
  };
 static Map<ETTypes,num Function(num,[num?])> generatePow = {
    ETTypes.In:(amount,[power]) {
      if (power == null) { power = 4; }
      power = power < MathUtils.epsilon ? MathUtils.epsilon : power;
      power = power > 10000 ? 10000 : power;
      return math.pow(amount, power);
    },
    ETTypes.Out:(amount,[power]) {
      if (power == null) { power = 4; }
      power = power < MathUtils.epsilon ? MathUtils.epsilon : power;
      power = power > 10000 ? 10000 : power;
      return 1 - math.pow((1 - amount), power);
    },
    ETTypes.InOut:(amount,[power]) {
      if (power == null) { power = 4; }
      power = power < MathUtils.epsilon ? MathUtils.epsilon : power;
      power = power > 10000 ? 10000 : power;
      if (amount < 0.5) {
        return math.pow((amount * 2), power) / 2;
      }
      return (1 - math.pow((2 - amount * 2), power)) / 2 + 0.5;
    },
  };
}

class TweenGroup{
  Map _tweens = {};
  Map _tweensAddedDuringUpdate = {};

  getAll() {
    var _this = this;
    return this._tweens.keys.map((tweenId) {
      return _this._tweens[tweenId];
    });
  }
  removeAll() {
    this._tweens = {};
  }
  add(tween) {
    this._tweens[tween.getId()] = tween;
    this._tweensAddedDuringUpdate[tween.getId()] = tween;
  }
  remove(tween) {
    _tweens.remove(tween.getId());//delete this._tweens[tween.getId()];
    _tweensAddedDuringUpdate.remove(tween.getId());//delete this._tweensAddedDuringUpdate[tween.getId()];
  }
  update(time, preserve) {
      if (time == null) { time = now(); }
      if (preserve == null) { preserve = false; }
      var tweenIds = this._tweens.keys.toList();
      if (tweenIds.length == 0) {
        return false;
      }
      // Tweens are updated in "batches". If you add a new tween during an
      // update, then the new tween will be updated in the next batch.
      // If you remove a tween during an update, it may or may not be updated.
      // However, if the removed tween was added during the current batch,
      // then it will not be updated.
      while (tweenIds.length > 0) {
          this._tweensAddedDuringUpdate = {};
          for (var i = 0; i < tweenIds.length; i++) {
              var tween = this._tweens[tweenIds[i]];
              var autoStart = !preserve;
              if (tween && tween.update(time, autoStart) == false && !preserve) {
                _tweens.remove(tweenIds[i]);//delete this._tweens[tweenIds[i]];
              }
          }
          tweenIds = this._tweensAddedDuringUpdate.keys.toList();
      }
      return true;
  }
}

class Interpolation{
  static num linear (List v, num k) {
    var m = v.length - 1;
    var f = m * k;
    var i = f.floor();
    var fn = Utils.linear;
    if (k < 0) {
      return fn(v[0], v[1], f);
    }
    if (k > 1) {
      return fn(v[m], v[m - 1], m - f);
    }
    return fn(v[i], v[i + 1 > m ? m : i + 1], f - i);
  }
  static num bezier (List v, num k) {
    double b = 0;
    int n = v.length - 1;
    var pw = math.pow;
    var bn = Utils.bernstein;
    for (int i = 0; i <= n; i++) {
      b += pw(1 - k, n - i) * pw(k, i) * v[i] * bn(n, i);
    }
    return b;
  }
  num catmullRom (List v, num k) {
    int m = v.length - 1;
    num f = m * k;
    int i = f.floor();
    var fn = Utils.catmullRom;
    if (v[0] == v[m]) {
      if (k < 0) {
        i = ((f = m * (1 + k))).floor();
      }
      return fn(v[(i - 1 + m) % m], v[i], v[(i + 1) % m], v[(i + 2) % m], f - i);
    }
    else {
      if (k < 0) {
        return v[0] - (fn(v[0], v[0], v[1], v[1], -f) - v[0]);
      }
      if (k > 1) {
        return v[m] - (fn(v[m], v[m], v[m - 1], v[m - 1], f - m) - v[m]);
      }
      return fn(v[i > 0? i - 1 : 0], v[i], v[m < i + 1 ? m : i + 1], v[m < i + 2 ? m : i + 2], f - i);
    }
  }
}
class Utils{
  static num linear (num p0, num p1, num t) {
    return (p1 - p0) * t + p0;
  }
  static num bernstein (int n, int i) {
    var fc = Utils.factorial;
    return fc(n) / fc(i) / fc(n - i);
  }
  static factorial(int n) {
    var a = [1];
    return (int n) {
      var s = 1;
      if (a[n] > 0) {
        return a[n];
      }
      for (int i = n; i > 1; i--) {
        s *= i;
      }
      a[n] = s;
      return s;
    };
  }
  static num catmullRom (num p0, num p1, num p2, num p3, num t) {
    double v0 = (p2 - p0) * 0.5;
    double v1 = (p3 - p1) * 0.5;
    num t2 = t * t;
    num t3 = t * t2;
    return (2 * p1 - 2 * p2 + v0 + v1) * t3 + (-3 * p1 + 3 * p2 - 2 * v0 - v1) * t2 + v0 * t + p1;
  }
}

class Sequence {
  static int _nextId = 0;
  static int nextId(){
    return Sequence._nextId++;
  }
}

//TweenGroup mainGroup = TweenGroup();

class Tween{
  int _duration = 1000;
  bool _isPaused = false;
  int _pauseStart = 0;
  bool _isDynamic = false;
  int _initialRepeat = 0;
  int _repeat = 0;
  bool _yoyo = false;
  bool _isPlaying = false;
  bool _reversed = false;
  int _delayTime = 0;
  int _startTime = 0;
  bool _isChainStopped = false;
  bool _propertiesAreSetUp = false;
  bool _goToEnd = false;
  bool _onStartCallbackFired = false;
  bool _onEveryStartCallbackFired = false;

  Map _valuesStart = {};
  Map _valuesEnd = {};
  Map _valuesStartRepeat = {};

  List<Tween> _chainedTweens = [];

  num Function(num) _easing = Easing.Linear[ETTypes.None]!;//.Linear.None;
  num Function(List,num) _interpolation = Interpolation.linear;
  int _id = Sequence.nextId();
  late TweenGroup _group;

  int? _repeatDelayTime;

  void Function(dynamic)? _onStartCallback;
  void Function(dynamic)? _onEveryStartCallback;
  void Function(dynamic,dynamic)? _onUpdateCallback;
  void Function(dynamic)? _onRepeatCallback;
  void Function(dynamic)? _onCompleteCallback;
  void Function(dynamic)? _onStopCallback;

  final _object;

  Tween(this._object,[ TweenGroup? group]) {
    this._group = group ?? TweenGroup();
  }

  void dispose(){
    _valuesStart.clear();
    _valuesEnd.clear();
    _valuesStartRepeat.clear();
    _chainedTweens.clear();
  
    _onStartCallback = null;
    _onEveryStartCallback = null;
    _onUpdateCallback = null;
    _onRepeatCallback = null;
    _onCompleteCallback = null;
    _onStopCallback = null;
  }

  int getId() {
    return this._id;
  }
  bool isPlaying() {
    return this._isPlaying;
  }
  bool isPaused() {
    return this._isPaused;
  }
  num getDuration() {
    return this._duration;
  }

  Tween to(Map target, [int duration = 1000]) {
    if (this._isPlaying) throw('Can not call Tween.to() while Tween is already started or paused. Stop the Tween first.');
    this._valuesEnd = target;
    this._propertiesAreSetUp = false;
    this._duration = duration < 0 ? 0 : duration;
    return this;
  }
  Tween duration([int duration = 1000]) {
    this._duration = duration < 0 ? 0 : duration;
    return this;
  }
  Tween dynamicF([bool isDynamic = false]) {
    this._isDynamic = isDynamic;
    return this;
  }
  Tween start([int? time, bool overrideStartingValues = false]) {
    time ??= now();
    if (this._isPlaying) {
        return this;
    }
    // eslint-disable-next-line
    this._group.add(this);
    this._repeat = this._initialRepeat;
    if (this._reversed) {
      // If we were reversed (f.e. using the yoyo feature) then we need to
      // flip the tween direction back to forward.
      this._reversed = false;
      for (var property in this._valuesStartRepeat.keys) {
        this._swapEndStartRepeatValues(property);
        this._valuesStart[property] = this._valuesStartRepeat[property];
      }
    }
    this._isPlaying = true;
    this._isPaused = false;
    this._onStartCallbackFired = false;
    this._onEveryStartCallbackFired = false;
    this._isChainStopped = false;
    this._startTime = time + this._delayTime;
    if (!this._propertiesAreSetUp || overrideStartingValues) {
      this._propertiesAreSetUp = true;
      // If dynamic is not enabled, clone the end values instead of using the passed-in end values.
      if (!this._isDynamic) {
        var tmp = {};
        for (var prop in this._valuesEnd.keys){
          tmp[prop] = this._valuesEnd[prop];
        }
        this._valuesEnd = tmp;
      }
      this._setupProperties(this._object, this._valuesStart, this._valuesEnd, this._valuesStartRepeat, overrideStartingValues);
    }
    return this;
  }
  Tween startFromCurrentValues([int? time]) {
    return this.start(time, true);
  }
  void _setupProperties(_object, _valuesStart, _valuesEnd, _valuesStartRepeat, overrideStartingValues) {
    for (var property in _valuesEnd.keys) {
      var startValue = _object[property];
      var startValueIsArray = startValue is List;
      var propType = startValueIsArray ? 'array' : startValue.runtimeType;
      var isInterpolationList = !startValueIsArray && _valuesEnd[property] is List;
      // If `to()` specifies a property that doesn't exist in the source object,
      // we should not set that property in the object
      if (propType == 'null' || propType == 'function') {
        continue;
      }
      // Check if an Array was provided as property value
      if (isInterpolationList) {
        var endValues = _valuesEnd[property];
        if (endValues.length == 0) {
          continue;
        }
          // Handle an array of relative values.
        // Creates a local copy of the Array with the start value at the front
        var temp = [startValue];
        for (var i = 0, l = endValues.length; i < l; i += 1) {
          var value = this._handleRelativeValue(startValue, endValues[i]);
          if (value.isNaN) {
            isInterpolationList = false;
            console.warning('Found invalid interpolation list. Skipping.');
            break;
          }
          temp.add(value);
        }
        if (isInterpolationList) {
          // if (_valuesStart[property] == null) { // handle end values only the first time. NOT NEEDED? setupProperties is now guarded by _propertiesAreSetUp.
          _valuesEnd[property] = temp;
          // }
        }
      }
      // handle the deepness of the values
      if ((propType == 'object' || startValueIsArray) && startValue && !isInterpolationList) {
        _valuesStart[property] = startValueIsArray ? [] : {};
        var nestedObject = startValue;
        for (var prop in nestedObject) {
          _valuesStart[property][prop] = nestedObject[prop];
        }
        // TODO? repeat nested values? And yoyo? And array values?
        _valuesStartRepeat[property] = startValueIsArray ? [] : {};
        var endValues = _valuesEnd[property];
        // If dynamic is not enabled, clone the end values instead of using the passed-in end values.
        if (!this._isDynamic) {
          var tmp = {};
          for (var prop in endValues){
            tmp[prop] = endValues[prop];
          }
          _valuesEnd[property] = endValues = tmp;
        }
        this._setupProperties(nestedObject, _valuesStart[property], endValues, _valuesStartRepeat[property], overrideStartingValues);
      }
      else {
        // Save the starting value, but only once unless override is requested.
        if (_valuesStart[property] == null || overrideStartingValues) {
          _valuesStart[property] = startValue;
        }
        if (!startValueIsArray) {
          // eslint-disable-next-line
          // @ts-ignore FIXME?
          _valuesStart[property] *= 1.0; // Ensures we're using numbers, not strings
        }
        if (isInterpolationList) {
          // eslint-disable-next-line
          // @ts-ignore FIXME?
          _valuesStartRepeat[property] = _valuesEnd[property].slice().reverse();
        }
        else {
          _valuesStartRepeat[property] = _valuesStart[property] ?? 0;
        }
      }
    }
  }
  Tween stop() {
    if (!this._isChainStopped) {
      this._isChainStopped = true;
      this.stopChainedTweens();
    }
    if (!this._isPlaying) {
      return this;
    }
    // eslint-disable-next-line
    this._group.remove(this);
    this._isPlaying = false;
    this._isPaused = false;
    this._onStopCallback?.call(this._object);
    return this;
  }
  Tween end() {
    this._goToEnd = true;
    this.update(double.maxFinite.toInt());
    return this;
  }
  Tween pause([int? time]) {
    time ??= now();
    if (this._isPaused || !this._isPlaying) {
      return this;
    }
    this._isPaused = true;
    this._pauseStart = time;
    // eslint-disable-next-line
    this._group.remove(this);
    return this;
  }
  Tween resume([int? time]) {
    time ??= now();
    if (this._isPaused || this._isPlaying) {
      return this;
    }
    this._isPaused = false;
    this._startTime += time - this._pauseStart;
    this._pauseStart = 0;
    // eslint-disable-next-line
    this._group.add(this);
    return this;
  }
  Tween stopChainedTweens() {
    for (int i = 0, numChainedTweens = this._chainedTweens.length; i < numChainedTweens; i++) {
      this._chainedTweens[i].stop();
    }
    return this;
  }
  Tween group([TweenGroup? group]) {
    group ??= TweenGroup();
    this._group = group;
    return this;
  }
  Tween delay([int amount = 0]) {
    this._delayTime = amount;
    return this;
  }
  Tween repeat([int times = 0]) {
    this._initialRepeat = times;
    this._repeat = times;
    return this;
  }
  Tween repeatDelay(amount) {
    this._repeatDelayTime = amount;
    return this;
  }
  Tween yoyo([bool yoyo = false]) {
    this._yoyo = yoyo;
    return this;
  }
  Tween easing([num Function(num, [num?])? easingFunction]) {
    easingFunction ??= Easing.Linear[ETTypes.None];
    this._easing = easingFunction!;
    return this;
  }
  Tween interpolation([num Function(List, num)? interpolationFunction]) {
    interpolationFunction ??= Interpolation.linear;
    this._interpolation = interpolationFunction;
    return this;
  }
  // eslint-disable-next-line
  Tween chain() {
    List<Tween> tweens = [];
    // TODO
    // for (var _i = 0; _i < arguments.length; _i++) {
    //   tweens[_i] = arguments[_i];
    // }
    this._chainedTweens = tweens;
    return this;
  }
  Tween onStart(callback) {
    this._onStartCallback = callback;
    return this;
  }
  Tween onEveryStart(callback) {
    this._onEveryStartCallback = callback;
    return this;
  }
  Tween onUpdate(callback) {
    this._onUpdateCallback = callback;
    return this;
  }
  Tween onRepeat(callback) {
    this._onRepeatCallback = callback;
    return this;
  }
  Tween onComplete(callback) {
    this._onCompleteCallback = callback;
    return this;
  }
  Tween onStop(callback) {
    this._onStopCallback = callback;
    return this;
  }
    /**
     * @returns true if the tween is still playing after the update, false
     * otherwise (calling update on a paused tween still returns true because
     * it is still playing, just paused).
     */
    bool update([int? time, bool autoStart = true]) {
        var _this = this;
        int? _a;
        time ??= now();
        if (this._isPaused)
          return true;
        var endTime = this._startTime + this._duration;
        if (!this._goToEnd && !this._isPlaying) {
          if (time > endTime)
            return false;
          if (autoStart)
            this.start(time, true);
        }
        this._goToEnd = false;
        if (time < this._startTime) {
          return true;
        }
        if (this._onStartCallbackFired == false) {
          this._onStartCallback?.call(this._object);
          this._onStartCallbackFired = true;
        }
        if (this._onEveryStartCallbackFired == false) {
          this._onEveryStartCallback?.call(this._object);
          this._onEveryStartCallbackFired = true;
        }
        var elapsedTime = time - this._startTime;
        int durationAndDelay = this._duration + ((_a = this._repeatDelayTime) != null && _a != null ? _a : this._delayTime);
        var totalTime = this._duration + this._repeat * durationAndDelay;
        calculateElapsedPortion() {
            if (_this._duration == 0)
              return 1;
            if (elapsedTime > totalTime) {
              return 1;
            }
            var timesRepeated = (elapsedTime / durationAndDelay).truncate();
            var timeIntoCurrentRepeat = elapsedTime - timesRepeated * durationAndDelay;
            // TODO use %?
            // const timeIntoCurrentRepeat = elapsedTime % durationAndDelay
            var portion = math.min<num>(timeIntoCurrentRepeat / _this._duration, 1);
            if (portion == 0 && elapsedTime == _this._duration) {
              return 1;
            }
            return portion;
        };
        var elapsed = calculateElapsedPortion();
        var value = this._easing(elapsed);
        // properties transformations
        this._updateProperties(this._object, this._valuesStart, this._valuesEnd, value);
        this._onUpdateCallback?.call(this._object, elapsed);
        if (this._duration == 0 || elapsedTime >= this._duration) {
            if (this._repeat > 0) {
                int completeCount = math.min<int>(((elapsedTime - this._duration) / durationAndDelay).truncate() + 1, this._repeat);
                if (this._repeat.isFinite) {
                  this._repeat -= completeCount;
                }
                // Reassign starting values, restart by making startTime = now
                for (final property in this._valuesStartRepeat.keys) {
                  if (!this._yoyo && this._valuesEnd[property] is String) {
                    this._valuesStartRepeat[property] =
                        // eslint-disable-next-line
                        // @ts-ignore FIXME?
                        this._valuesStartRepeat[property] + double.parse(this._valuesEnd[property]);
                  }
                  if (this._yoyo) {
                    this._swapEndStartRepeatValues(property);
                  }
                  this._valuesStart[property] = this._valuesStartRepeat[property];
                }
                if (this._yoyo) {
                    this._reversed = !this._reversed;
                }
                this._startTime += durationAndDelay * completeCount;
                this._onRepeatCallback?.call(this._object);
                this._onEveryStartCallbackFired = false;
                return true;
            }
            else {
              this._onCompleteCallback?.call(this._object);
              for (var i = 0, numChainedTweens = this._chainedTweens.length; i < numChainedTweens; i++) {
                // Make the chained tweens start exactly at the time they should,
                // even if the `update()` method was called way past the duration of the tween
                this._chainedTweens[i].start(this._startTime + this._duration, false);
              }
              this._isPlaying = false;
              return false;
            }
        }
        return true;
    }
  void _updateProperties(_object, _valuesStart, _valuesEnd, value) {
    for (var property in _valuesEnd.keys) {
      // Don't update properties that do not exist in the source object
      if (_valuesStart[property] == null) {
        continue;
      }
      var start = _valuesStart[property] ?? 0;
      var end = _valuesEnd[property];
      var startIsArray = _object[property] is List;
      var endIsArray = end is List;
      var isInterpolationList = !startIsArray && endIsArray;

      if (isInterpolationList) {
        _object[property] = this._interpolation(end, value);
      }
      else if (end is Map) {
        // eslint-disable-next-line
        // @ts-ignore FIXME?
        this._updateProperties(_object[property], start, end, value);
      }
      else {
        // Parses relative end values with start as base (e.g.: +10, -3)
        end = this._handleRelativeValue(start, end);
        // Protect against non numeric properties.
        if (end is num || end is int || end is double) {
          _object[property] = start + (end - start) * value;
        }
      }
    }
  }
  num _handleRelativeValue(num start, dynamic end) {
    if (end is! String) {
      return end;
    }
    if (end[0] == '+' || end[0] == '-') {
      return start + double.parse(end);
    }
    return double.parse(end);
  }
  void _swapEndStartRepeatValues(property) {
    var tmp = this._valuesStartRepeat[property];
    var endValue = this._valuesEnd[property];
    if (endValue is String) {
      this._valuesStartRepeat[property] = this._valuesStartRepeat[property] + double.parse(endValue);
    }
    else {
      this._valuesStartRepeat[property] = this._valuesEnd[property];
    }
    this._valuesEnd[property] = tmp;
  }
}