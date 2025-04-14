import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';
import 'property_binding.dart';

/// Buffered scene graph property that allows weighted accumulation; used internally.
/// 
/// Buffer with size [valueSize] * 4.
/// 
/// 
/// This has the layout: [ incoming | accu0 | accu1 | orig ]
/// 
/// 
/// Interpolators can use .buffer as their .result and the data then goes to
/// `incoming`. `accu0` and `accu1` are used frame-interleaved for the
/// cumulative result and are compared to detect changes. `orig` stores the
/// original state of the property.
class PropertyMixer {
  late PropertyBinding binding;
  late int valueSize;
  late Function _mixBufferRegion;
  late Function _mixBufferRegionAdditive;
  late Function _setIdentity;
  late int _origIndex;
  late int _addIndex;
  late int _workIndex;
  late int useCount;
  late int referenceCount;
  late double cumulativeWeight;
  late double cumulativeWeightAdditive;
  late List buffer;
  late int? cacheIndex;

  PropertyMixer(this.binding, String typeName, this.valueSize) {
    Function mixFunction, mixFunctionAdditive, setIdentity;

    // buffer layout: [ incoming | accu0 | accu1 | orig | addAccu | (optional work) ]
    //
    // interpolators can use .buffer as their .result
    // the data then goes to 'incoming'
    //
    // 'accu0' and 'accu1' are used frame-interleaved for
    // the cumulative result and are compared to detect
    // changes
    //
    // 'orig' stores the original state of the property
    //
    // 'add' is used for additive cumulative results
    //
    // 'work' is optional and is only present for quaternion types. It is used
    // to store intermediate quaternion multiplication results
    switch (typeName) {
      case 'quaternion':
        mixFunction = _slerp;
        mixFunctionAdditive = _slerpAdditive;
        setIdentity = _setAdditiveIdentityQuaternion;

        buffer = List<num>.filled(valueSize * 6, 0);
        _workIndex = 5;

        break;

      case 'string':
      case 'bool':
        mixFunction = _select;

        // Use the regular mix function and for additive on these types,
        // additive is not relevant for non-numeric types
        mixFunctionAdditive = _select;

        setIdentity = _setAdditiveIdentityOther;

        console.info("PropertyMixer  todo  typeName: $typeName");
        buffer = List<String?>.filled(valueSize * 5, null);
        // this.buffer = new Array( valueSize * 5 );

        break;

      default:
        mixFunction = _lerp;
        mixFunctionAdditive = _lerpAdditive;
        setIdentity = _setAdditiveIdentityNumeric;

        buffer = List<num>.filled(valueSize * 5, 0);
    }

    _mixBufferRegion = mixFunction;
    _mixBufferRegionAdditive = mixFunctionAdditive;
    _setIdentity = setIdentity;
    _origIndex = 3;
    _addIndex = 4;

    cumulativeWeight = 0;
    cumulativeWeightAdditive = 0;

    useCount = 0;
    referenceCount = 0;
  }

  /// Accumulate data in [buffer][accuIndex]
  /// `incoming` region into `accu[i]`.

  /// If weight is `0` this does nothing.
  void accumulate(int accuIndex, double weight) {
    // note: happily accumulating nothing when weight = 0, the caller knows
    // the weight and shouldn't have made the call in the first place

    final buffer = this.buffer;
    int stride = valueSize;
    int offset = accuIndex * stride + stride;
    double currentWeight = cumulativeWeight;

    if (currentWeight == 0) {
      // accuN := incoming * weight
      for (int i = 0; i != stride; ++i) {
        buffer[offset + i] = buffer[i];
      }
      currentWeight = weight;
    } 
    else {
      // accuN := accuN + incoming * weight
      currentWeight += weight;
      final mix = weight / currentWeight;
      _mixBufferRegion(buffer, offset, 0, mix, stride);
    }

    cumulativeWeight = currentWeight;
  }

  /// Accumulate data in the `incoming` region into 'add'.
  /// 
	/// If weight is `0` this does nothing.
  void accumulateAdditive(double weight) {
    final buffer = this.buffer,
        stride = valueSize,
        offset = stride * _addIndex;

    if (cumulativeWeightAdditive == 0) {
      // add = identity

      _setIdentity();
    }

    // add := add + incoming * weight

    _mixBufferRegionAdditive(buffer, offset, 0, weight, stride);
    cumulativeWeightAdditive += weight;
  }

  /// Apply the state of [buffer] `accu[i]` to the
	/// binding when accus differ.
  void apply(accuIndex) {
    final stride = valueSize,
        buffer = this.buffer,
        offset = accuIndex * stride + stride,
        weight = cumulativeWeight,
        weightAdditive = cumulativeWeightAdditive,
        binding = this.binding;

    cumulativeWeight = 0;
    cumulativeWeightAdditive = 0;

    if (weight < 1) {
      // accuN := accuN + original * ( 1 - cumulativeWeight )

      final originalValueOffset = stride * _origIndex;

      _mixBufferRegion(
        buffer, 
        offset, 
        originalValueOffset, 
        1 - weight.toDouble(), 
        stride
      );
    }

    if (weightAdditive > 0) {
      // accuN := accuN + additive accuN
      _mixBufferRegionAdditive(buffer, offset, _addIndex * stride, 1.0, stride);
    }

    for (int i = stride, e = stride + stride; i != e; ++i) {
      if (buffer[i] != buffer[i + stride]) {
        // value has changed -> update scene graph
        binding.setValue(buffer, offset);
        break;
      }
    }
  }

  /// Remember the state of the bound property and copy it to both accus.
  void saveOriginalState() {
    final binding = this.binding;

    final buffer = this.buffer,
        stride = valueSize,
        originalValueOffset = stride * _origIndex;

    binding.getValue(buffer, originalValueOffset);

    // accu[0..1] := orig -- initially detect changes against the original
    for (int i = stride, e = originalValueOffset; i != e; ++i) {
      buffer[i] = buffer[originalValueOffset + (i % stride)];
    }

    // Add to identity for additive
    _setIdentity();

    cumulativeWeight = 0;
    cumulativeWeightAdditive = 0;
  }

  /// Apply the state previously taken via 'saveOriginalState' to the binding.
  void restoreOriginalState() {
    final originalValueOffset = valueSize * 3;
    binding.setValue(buffer, originalValueOffset);
  }

  void _setAdditiveIdentityNumeric() {
    final startIndex = _addIndex * valueSize;
    final endIndex = startIndex + valueSize;

    for (int i = startIndex; i < endIndex; i++) {
      buffer[i] = 0;
    }
  }

  void _setAdditiveIdentityQuaternion() {
    _setAdditiveIdentityNumeric();
    buffer[_addIndex * valueSize + 3] = 1;
  }

  void _setAdditiveIdentityOther() {
    final startIndex = _origIndex * valueSize;
    final targetIndex = _addIndex * valueSize;

    for (int i = 0; i < valueSize; i++) {
      buffer[targetIndex + i] = buffer[startIndex + i];
    }
  }

  void _select(buffer, int dstOffset, int srcOffset, double t, int stride) {
    if (t >= 0.5) {
      for (int i = 0; i != stride; ++i) {
        buffer[dstOffset + i] = buffer[srcOffset + i];
      }
    }
  }

  void _slerp(buffer, int dstOffset, int srcOffset, double t, int stride) {
    Quaternion.slerpFlat(buffer, dstOffset, buffer, dstOffset, buffer, srcOffset, t);
  }

  void _slerpAdditive(buffer, int dstOffset, int srcOffset, double t, int stride) {
    final workOffset = _workIndex * stride;

    // Store result in intermediate buffer offset
    Quaternion.multiplyQuaternionsFlat(buffer, workOffset, buffer, dstOffset, buffer, srcOffset);

    // Slerp to the intermediate result
    Quaternion.slerpFlat(buffer, dstOffset, buffer, dstOffset, buffer, workOffset, t);
  }

  void _lerp(buffer, int dstOffset, int srcOffset, double t, int stride) {
    final s = 1 - t;

    for (int i = 0; i != stride; ++i) {
      final j = dstOffset + i;

      buffer[j] = buffer[j] * s + buffer[srcOffset + i] * t;
    }
  }

  void _lerpAdditive(buffer, dstOffset, srcOffset, t, stride) {
    for (int i = 0; i != stride; ++i) {
      final j = dstOffset + i;

      buffer[j] = buffer[j] + buffer[srcOffset + i] * t;
    }
  }
}
