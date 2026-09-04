abstract class Info {

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


  void update(count, mode, instanceCount);

  void reset() {
    render["frame"] = render["frame"]! + 1;
    render["calls"] = 0;
    render["triangles"] = 0;
    render["points"] = 0;
    render["lines"] = 0;
  }

  void dispose(){}
}
