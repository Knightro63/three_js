part of three_webgl;

class WebGLIndexedBufferRenderer extends BaseWebGLBufferRenderer {
  bool isWebGL2 = false;
  dynamic mode;
  dynamic type;
  late int bytesPerElement;
  dynamic gl;
  WebGLExtensions extensions;
  WebGLInfo info;
  WebGLCapabilities capabilities;

  WebGLIndexedBufferRenderer(this.gl, this.extensions, this.info, this.capabilities) {
    isWebGL2 = capabilities.isWebGL2;
  }

  @override
  void setMode(value) {
    mode = value;
  }

  @override
  void setIndex(value) {
    type = value["type"];
    bytesPerElement = value["bytesPerElement"];
  }

  @override
  void render(start, count) {
    gl.drawElements(mode, count, type, start * bytesPerElement);

    info.update(count, mode, 1);
  }

  @override
  void renderInstances(num start, num count, int? primcount) {
    if (primcount == 0) return;

    // var extension, methodName;

    // if ( isWebGL2 ) {

    // 	extension = gl;
    // 	methodName = 'drawElementsInstanced';

    // } else {

    // 	extension = extensions.get( 'ANGLE_instanced_arrays' );
    // 	methodName = 'drawElementsInstancedANGLE';

    // 	if ( extension == null ) {

    // 		print( 'three.WebGLIndexedBufferRenderer: using three.InstancedBufferGeometry but hardware does not support extension ANGLE_instanced_arrays.' );
    // 		return;

    // 	}

    // }

    // extension[ methodName ]( mode, count, type, start * bytesPerElement, primcount );

    gl.drawElementsInstanced(mode, count, type, start * bytesPerElement, primcount);

    info.update(count, mode, primcount);
  }
}
