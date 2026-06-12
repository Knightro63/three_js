import 'package:three_js_core/three_js_core.dart';
import 'package:flutter_gpu/gpu.dart' as gpu; // Adjust based on your exact gpux library paths

class ImpellerRenderTarget extends RenderTarget {
  gpu.RenderTarget target;

  ImpellerRenderTarget(this.target, [super.width = 0, super.height = 0, super.options]);

  @override
  void dispose() {
    super.dispose();
  }
}