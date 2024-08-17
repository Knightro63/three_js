import 'dart:typed_data';
import 'package:three_js_terrain/core.dart';
import 'dart:math' as math; 

class Gaussian{

  ///
  /// Perform Gaussian smoothing on terrain vertices.
  ///
  /// [List<Vector3>] g
  ///   The vertex array for plane geometry to modify with heightmap data. This
  ///   method sets the `z` property of each vertex.
  /// [TerrainOptions] options
  ///   A map of settings that control how the terrain is constructed and
  ///   displayed. Valid values are the same as those for the `options` parameter
  ///    of {@link THREE.Terrain}().
  /// [double] s = 1
  ///   The standard deviation of the Gaussian kernel to use. Higher values result
  ///   in smoothing across more cells of the src matrix.
  /// [int] kernelSize = 7
  ///   The size of the Gaussian kernel to use. Larger kernels result in slower
  ///   but more accurate smoothing.
  ///
  Gaussian(Float32List g, TerrainOptions options, [double s = 1, int kernelSize = 7]) {
    Terrain.fromArray2D(g, gaussian(Terrain.toArray2D(g, options), s, kernelSize));
  }

  ///
  /// Convolve an array with a kernel.
  ///
  /// [List<Float32List>] src
  ///   The source array to convolve. A nonzero-sized rectangular array of numbers.
  /// [List<Float32List>] kernel
  ///   The kernel array with which to convolve `src`.  A nonzero-sized
  ///   rectangular array of numbers smaller than `src`.
  /// [List<Float32List>?] [tgt]
  ///   The target array into which the result of the convolution should be put.
  ///   If not passed, a new array will be created. This is also the array that
  ///   this function returns. It must be at least as large as `src`.
  ///
  /// return [List<Float32List>]
  ///   An array containing the result of the convolution.
  ///
  List<Float32List> convolve(List<Float32List> src, List<Float32List> kernel, [List<Float32List>? tgt]) {
    // src and kernel must be nonzero rectangular number arrays.
    if (src.isEmpty || kernel.isEmpty) return src;
    // Initialize tracking variables.
    int i = 0, // current src x-position
        j = 0, // current src y-position
        a = 0, // current kernel x-position
        b = 0, // current kernel y-position
        w = src.length, // src width
        l = src[0].length, // src length
        m = kernel.length, // kernel width
        n = kernel[0].length; // kernel length
    // If a target isn't passed, initialize it to an array the same size as src.
    tgt ??= List.filled(w, new Float32List(l));
    // The kernel is a rectangle smaller than the source. Hold it over the
    // source so that its top-left value sits over the target position. Then,
    // for each value in the kernel, multiply it by the value in the source
    // that it is sitting on top of. The target value at that position is the
    // sum of those products.
    // For each position in the source:
    for (i = 0; i < w; i++) {
      for (j = 0; j < l; j++) {
        double last = 0;
        tgt[i][j] = 0;
        // For each position in the kernel:
        for (a = 0; a < m; a++) {
          for (b = 0; b < n; b++) {
            // If we're along the right or bottom edges of the source,
            // parts of the kernel will fall outside of the source. In
            // that case, pretend the source value is the last valid
            // value we got from the source. This gives reasonable
            // results. The alternative is to drop the edges and end up
            // with a target smaller than the source. That is
            // unreasonable for some applications, so we let the caller
            // make that choice.
            //if (typeof src[i+a] != 'undefined' && typeof src[i+a][j+b] != 'undefined') {
              last = src[i+a][j+b];
            //}
            // Multiply the source and the kernel at this position.
            // The value at the target position is the sum of these
            // products.
            tgt[i][j] += last * kernel[a][b];
          }
        }
      }
    }
    return tgt;
  }

  ///
  /// Returns the value at X of a Gaussian distribution with standard deviation S.
  ///
  double gauss(double x, double s) {
    // 2.5066282746310005 is sqrt(2*pi)
    return math.exp(-0.5 * x*x / (s*s)) / (s * 2.5066282746310005);
  }

  ///
  /// Generate a Gaussian kernel.
  ///
  /// Returns a kernel of size N approximating a 1D Gaussian distribution with
  /// standard deviation S.
  ///
  Float32List gaussianKernel1D(double s, int? n) {
    n ??= 7;
    final kernel = Float32List(n);
    int halfN = (n * 0.5).floor();
    double odd = n % 2;
    int i = 0;

    if (s == 0 || n == 0) return kernel;
    for (i = 0; i <= halfN; i++) {
      kernel[i] = gauss(s * (i - halfN - odd * 0.5), s);
    }
    for (; i < n; i++) {
      kernel[i] = kernel[n - 1 - i];
    }
    return kernel;
  }

  ///
  /// Perform Gaussian smoothing.
  ///
  ///  [List<Float32List>] src
  ///   The source array to convolve. A nonzero-sized rectangular array of numbers.
  /// [double] s = 1
  ///   The standard deviation of the Gaussian kernel to use. Higher values result
  ///   in smoothing across more cells of the src matrix.
  /// [int] kernelSize = 7
  ///   The size of the Gaussian kernel to use. Larger kernels result in slower
  ///   but more accurate smoothing.
  ///
  /// return [List<Float32List>]
  ///   An array containing the result of smoothing the src.
  ///
  List<Float32List> gaussian(List<Float32List> src, [double s= 1, int kernelSize = 7]) {
    final kernel = gaussianKernel1D(s, kernelSize);
    int l = kernelSize;
    List<Float32List> kernelH = [kernel];
    List<Float32List> kernelV = [];
    for (int i = 0; i < l; i++) {
      kernelV.add(Float32List.fromList([kernel[i]]));
    }
    return convolve(convolve(src, kernelH), kernelV);
  }
}
