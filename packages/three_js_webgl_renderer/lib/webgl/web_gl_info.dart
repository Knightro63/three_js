part of three_webgl;

class WebGLInfo extends Info{
  RenderingContext gl;

  WebGLInfo(this.gl);

  void update(count, mode, instanceCount) {
    render["calls"] = render["calls"]! + 1;

    if (mode == WebGL.TRIANGLES) {
      render["triangles"] = render["triangles"]! + instanceCount * (count / 3.0);
    } else if (mode == WebGL.LINES) {
      render["lines"] = render["lines"]! + instanceCount * (count / 2);
    } else if (mode == WebGL.LINE_STRIP) {
      render["lines"] = render["lines"]! + instanceCount * (count - 1);
    } else if (mode == WebGL.LINE_LOOP) {
      render["lines"] = render["lines"]! + instanceCount * count;
    } else if (mode == WebGL.POINTS) {
      render["points"] = render["points"]! + instanceCount * count;
    } else {
      console.warning('three.WebGLInfo: Unknown draw mode: $mode ');
    }
  }
}
