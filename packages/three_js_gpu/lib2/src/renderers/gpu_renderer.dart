import 'package:three_js_core/three_js_core.dart' as core;
import 'package:three_js_math/three_js_math.dart' as math;

// WebGPU rendering layer dependencies matching your gpux implementation
import '../common/renderer.dart';
import '../webgl-fallback/WebGLBackend.dart';
import './gpu_backend.dart';
import './nodes/standard_node_library.dart';

/// This renderer is the new alternative of `WebGLRenderer`. `WebGPURenderer` has the ability
/// to target different backends. By default, the renderer tries to use a WebGPU backend if the
/// platform supports WebGPU. If not, `WebGPURenderer` falls backs to a WebGL 2 backend.
class WebGPURenderer extends Renderer {
  late StandardNodeLibrary library;
  final bool isWebGPURenderer = true;

  // Private internal constructor running parent initializations
  WebGPURenderer._internal(dynamic backend, Map<String, dynamic> parameters) 
      : super(backend, parameters) {
    
    // Overwrite the generic default value with the standard node library
    this.library = StandardNodeLibrary();

    // Utilizing core console info log from three_js_core
    core.console.info('WebGPURenderer: Production GPU context initialized.');
  }

  /// Factory constructor providing dynamic configuration analysis 
  /// before constructing the specific Renderer instance context.
  factory WebGPURenderer([Map<String, dynamic>? parameters]) {
    // Explicitly configure defaults documented in the Options typedef
    final Map<String, dynamic> params = {
      'logarithmicDepthBuffer': false,
      'reversedDepthBuffer': false,
      'alpha': true,
      'depth': true,
      'stencil': false,
      'antialias': false,
      'samples': 0,
      'forceWebGL': false,
      'multiview': false,
      'outputType': null,
      'outputBufferType': 1016, // Maps directly to HalfFloatType
      ...?parameters 
    };

    bool forceWebGL = params['forceWebGL'] == true;
    dynamic selectedBackend;

    if (forceWebGL) {
      core.console.info('WebGPURenderer: WebGL backend deployment forced via options flags.');
      selectedBackend = WebGLBackend(params);
    } else {
      // Setup dynamic fallback routing function wrapper
      params['getFallback'] = () {
        // Utilizing core console warning log from three_js_core
        core.console.warning('WebGPURenderer: WebGPU is not available, running under WebGL2 backend.');
        return WebGLBackend(params);
      };
      
      try {
        selectedBackend = WebGPUBackend(params);
      } catch (exception) {
        // Utilizing core console error log from three_js_core
        core.console.error('WebGPURenderer: WebGPU initialization hit a critical fault: $exception');
        selectedBackend = WebGLBackend(params);
      }
    }

    return WebGPURenderer._internal(selectedBackend, params);
  }
}
