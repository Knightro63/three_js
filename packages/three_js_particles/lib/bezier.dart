import './types.dart';
import 'dart:math' as math;

class CacheArray{
  List<BezierPoint> bezierPoints;
  CurveFunction curveFunction;
  List<num> referencedBy;

  CacheArray({
    required this.bezierPoints,
    required this.curveFunction,
    required this.referencedBy
  });
}

class Bezier{
  static final List<CacheArray?> cache = [];

  static double nCr(int n, int k){
    double z = 1;
    for (int i = 1; i <= k; i++){ 
      z *= (n + 1 - i) / i;
    }
    return z;
  }

  static CurveFunction createBezierCurveFunction(
    num particleSystemId,
    List<BezierPoint> bezierPoints
  ) {
    final CacheArray? cacheEntry = cache.firstWhere((item) => item?.bezierPoints == bezierPoints, orElse: () => null);

    if (cacheEntry != null) {
      if (!cacheEntry.referencedBy.contains(particleSystemId))
        cacheEntry.referencedBy.add(particleSystemId);
      return cacheEntry.curveFunction;
    }

    final CacheArray entry = CacheArray(
      referencedBy: [particleSystemId],
      bezierPoints: bezierPoints,
      curveFunction: (num percentage, [num? error]){
        if (percentage < 0) return bezierPoints[0].y;
        if (percentage > 1) return bezierPoints[bezierPoints.length - 1].y;

        int start = 0;
        int stop = bezierPoints.length - 1;

        bezierPoints.find((point, index){
          final result = percentage < (point.percentage ?? 0);
          if (result) stop = index;
          else if (point.percentage != null) start = index;
          return result;
        });

        final n = stop - start;
        final calculatedPercentage =
          (percentage - (bezierPoints[start].percentage ?? 0)) /
          ((bezierPoints[stop].percentage ?? 1) -
            (bezierPoints[start].percentage ?? 0));

        double value = 0;
        for (int i = 0; i <= n; i++) {
          final p = bezierPoints[start + i];
          final c =
            nCr(n, i) *
            math.pow(1 - calculatedPercentage, n - i) *
            math.pow(calculatedPercentage, i);
          value += c * p.y;
        }
        return value;
      },
    );

    cache.add(entry);
    return entry.curveFunction;
  }

  static void removeBezierCurveFunction(num particleSystemId){
    while (true) {
      final index = cache.indexWhere((item) =>
        item!.referencedBy.contains(particleSystemId)
      );
      if (index == -1) break;
      final entry = cache[index];
      entry!.referencedBy = entry.referencedBy.where((id) => id != particleSystemId).toList();
      if (entry.referencedBy.length == 0) cache.removeAt(index);
    }
  }

  static int get bezierCacheSize => cache.length;
}