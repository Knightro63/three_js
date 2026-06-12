import 'package:flutter_gpu/gpu.dart';
import 'package:three_js_core/three_js_core.dart';

class GpuInfo {
  Map<String, int> memory = {
    "geometries": 0, 
    "textures": 0
  };

  Map<String, double> render = {
    "frame": 0.0, 
    "calls": 0.0, 
    "triangles": 0.0, 
    "points": 0.0, 
    "lines": 0.0
  };

  dynamic programs;
  bool autoReset = true;

  double get frame => render['frame']!;
  double get calls => render['calls']!;
  double get triangles => render['triangles']!;
  double get lines => render['lines']!;
  double get points => render['points']!;


  void update(count, PrimitiveType mode, instanceCount) {
    render["calls"] = render["calls"]! + 1;

    if (mode == PrimitiveType.triangleStrip) {
      render["triangles"] = render["triangles"]! + instanceCount * (count / 3.0);
    } else if (mode == PrimitiveType.line) {
      render["lines"] = render["lines"]! + instanceCount * (count / 2);
    } else if (mode == PrimitiveType.lineStrip) {
      render["lines"] = render["lines"]! + instanceCount * (count - 1);
    }  else if (mode == PrimitiveType.point) {
      render["points"] = render["points"]! + instanceCount * count;
    } else {
      console.warning('three.WebGLInfo: Unknown draw mode: $mode ');
    }
  }

  void reset() {
    render["frame"] = render["frame"]! + 1;
    render["calls"] = 0;
    render["triangles"] = 0;
    render["points"] = 0;
    render["lines"] = 0;
  }

  void dispose(){}
}
