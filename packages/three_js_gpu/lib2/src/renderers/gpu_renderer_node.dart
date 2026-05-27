import 'package:three_js_core/three_js_core.dart';
import 'nodes/basic_node_library.dart';

/// This alternative version of WebGPURenderer only supports node materials.
/// So classes like `MeshBasicMaterial` are not compatible.
class WebGPURenderer extends Renderer {
  // Instance properties
  final BasicNodeLibrary library;
  final bool isWebGPURenderer = true;

  /// Constructs a new WebGPU renderer.
  WebGPURenderer.create([Map<String, dynamic>? parameters]) : super() {
    // Standard node library configuration for type mapping
    // Replace with your converted BasicNodeLibrary instance
    this.library = BasicNodeLibrary(); 
  }

  /// Private helper method to handle the conditional backend creation 
  /// and the WebGL fallback mechanism logic.
  factory WebGPURenderer([Map<String, dynamic>? parameters]) {
    bool forceWebGL = parameters?['forceWebGL'] ?? false;

    if (forceWebGL) {
      // Returns the fallback WebGL backend renderer context
      // Update with your exact WebGLBackend class reference
      return WebGPURenderer.create(parameters); 
    } else {
      // Provide the fallback callback routine inside parameters map
      parameters?['getFallback'] = () {
        console.warning('WebGPURenderer: WebGPU is not available, running under WebGL2 backend.');
        // Returns WebGLBackend(parameters);
        return WebGPURenderer.create(parameters); 
      };

      // Returns the native WebGPUBackend renderer context
      // Update with your exact WebGPUBackend class reference
      return WebGPURenderer.create(parameters); 
    }
  }
}
