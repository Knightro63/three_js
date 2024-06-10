/// Abstract base class of interpolants over parametric samples.
///
/// The parameter domain is one dimensional, typically the time or a path
/// along a curve defined by the data.
///
/// The sample values can have any dimensionality and derived classes may
/// apply special interpretations to the data.
///
/// This class provides the interval seek in a Template Method, deferring
/// the actual interpolation to derived classes.
///
/// Time complexity is O(1) for linear access crossing at most two points
/// and O(log N) for random access, where N is the number of positions.
///
/// References:
///
/// http://www.oodesign.com/template-method-pattern.html
///
class Interpolant {
  late List<num> parameterPositions;
  int cachedIndex = 0;
  late List? resultBuffer;
  late List<num> sampleValues;
  late int valueSize;
  late Map<String,dynamic>? settings;

  // --- Protected interface

  Map<String,dynamic> defaultSettings = {};

	/// [parameterPositions] -- array of positions
  /// 
	/// [sampleValues] -- array of samples
  /// 
	/// [valueSize] -- number of values
  /// 
	/// [resultBuffer] -- buffer to store the interpolation results.
  /// 
  Interpolant(this.parameterPositions, this.sampleValues, this.valueSize,this.resultBuffer);

  /// Evaluate the interpolant at position [t].
  List? evaluate(num t) {
    final pp = parameterPositions;
    int i1 = cachedIndex;

    num? t1;
    num? t0;

    if (i1 < pp.length) {
      t1 = pp[i1];
    }
    if (i1 - 1 >= 0) {
      t0 = pp[i1 - 1];
    }

    validate_interval:
    {
      seek:
      {
        int right;

        linear_scan:
        {
          //- See http://jsperf.com/comparison-to-undefined/3
          //- slower code:
          //-
          //- 				if ( t >= t1 || t1 == null ) {
          forward_scan:
          if (t1 == null || t >= t1) {
            for (int giveUpAt = i1 + 2;;) {
              if (t1 == null) {
                if (t < t0!) break forward_scan;

                // after end

                i1 = pp.length;
                cachedIndex = i1;
                return afterEnd(i1 - 1, t, t0) ?? [];
              }

              if (i1 == giveUpAt) break; // this loop

              t0 = t1;

              int idx = ++i1;

              if (idx < pp.length) {
                t1 = pp[idx];
              } else {
                t1 = null;
              }

              if (t1 != null && t < t1) {
                // we have arrived at the sought interval
                break seek;
              }
            }

            // prepare binary search on the right side of the index
            right = pp.length;
            break linear_scan;
          }

          //- slower code:
          //-					if ( t < t0 || t0 == null ) {
          if (t0 == null || !(t >= t0)) {
            // looping?

            final t1global = pp[1];

            if (t < t1global) {
              i1 = 2; // + 1, using the scan for the details
              t0 = t1global;
            }

            // linear reverse scan

            for (int giveUpAt = i1 - 2;;) {
              if (t0 == null) {
                // before start

                cachedIndex = 0;
                return beforeStart(0, t, t1) ?? [];
              }

              if (i1 == giveUpAt) break; // this loop

              t1 = t0;

              int iii = --i1 - 1;
              if (iii < 0) {
                t0 = null;
              } else {
                t0 = pp[iii];
              }

              if (t0 != null && t >= t0) {
                // we have arrived at the sought interval
                break seek;
              }
            }

            // prepare binary search on the left side of the index
            right = i1;
            i1 = 0;
            break linear_scan;
          }

          // the interval is valid

          break validate_interval;
        } // linear scan

        // binary search

        while (i1 < right) {
          final mid = (i1 + right) >> 1;
          if (t < pp[mid]) {
            right = mid;
          } else {
            i1 = mid + 1;
          }
        }

        t1 = null;
        t0 = null;

        if (i1 < pp.length) {
          t1 = pp[i1];
        }
        if (i1 - 1 < pp.length) {
          t0 = pp[i1 - 1];
        }

        // check boundary cases, again

        if (t0 == null) {
          cachedIndex = 0;
          return beforeStart(0, t, t1) ?? [];
        }

        if (t1 == null) {
          i1 = pp.length;
          cachedIndex = i1;
          return afterEnd(i1 - 1, t0, t) ?? [];
        }
      } // seek

      cachedIndex = i1;

      intervalChanged(i1, t0.toInt(), t1.toInt());
    } // validate_interval

    return interpolate(i1, t0, t, t1!);
  }

  Map<String,dynamic> getSettings() {
    return settings ?? defaultSettings;
  }

  List? copySampleValue(int index) {
    // copies a sample value to the result buffer

    final result = resultBuffer,
        values = sampleValues,
        stride = valueSize,
        offset = index * stride;

    for (int i = 0; i != stride; ++i) {
      result?[i] = values[offset + i];
    }

    return result;
  }

  // Template methods for derived classes:

  List? interpolate(int i1, num t0, num t, num t1) {
    throw ('call to abstract method');
    // implementations shall return this.resultBuffer
  }

  void intervalChanged(int v1, int v2, int v3) {
    // empty
  }

  List? beforeStart(int v1, v2, v3) {
    return null;//copySampleValue(v1, v2, v3);
  }

  //( N-1, tN-1, t ), returns this.resultBuffer
  // afterEnd_: Interpolant.prototype.copySampleValue_,

  List? afterEnd(int v1, v2, v3) {
    return null;//copySampleValue(v1, v2, v3);
  }
}
