part of three_webgl;

class WebGLIndexedBufferRenderer extends BaseWebGLBufferRenderer {
  bool _didDispose = false;
  dynamic mode;
  dynamic type;
  late int bytesPerElement;
  RenderingContext gl;
  WebGLExtensions extensions;
  WebGLInfo info;

  WebGLIndexedBufferRenderer(this.gl, this.extensions, this.info);

  void dispose(){
    if(_didDispose) return;
    _didDispose = true;
    extensions.dispose();
    info.dispose();
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
  void render(int start, int count) {
    gl.drawElements(mode, count, type, start * bytesPerElement);
    info.update(count, mode, 1);
  }

  @override
  void renderInstances(int start, int count, int primcount) {
    if (primcount == 0) return;
    gl.drawElementsInstanced(mode, count, type, start * bytesPerElement, primcount);
    info.update(count, mode, primcount);
  }

	void renderMultiDraw(List<int> starts,List<int> counts,int drawCount ) {
		if ( drawCount == 0 ) return;
		final extension = extensions.get( 'WEBGL_multi_draw' );

    extension.multiDrawElementsWEBGL( mode, counts, 0, type, starts, 0, drawCount );
    int elementCount = 0;
    for ( int i = 0; i < drawCount; i ++ ) {
      elementCount += counts[ i ];
    }
    info.update( elementCount, mode, 1 );
	}

	void renderMultiDrawInstances(List<int> starts,List<int> counts,int drawCount,List<int> primcount ) {
		if ( drawCount == 0 ) return;
		final extension = extensions.get( 'WEBGL_multi_draw' );

		if ( extension == null ) {
			for (int i = 0; i < starts.length; i ++ ) {
				renderInstances( starts[ i ] ~/ bytesPerElement, counts[ i ], primcount[ i ] );
			}
		} 
    else {
			extension.multiDrawElementsInstancedWEBGL( mode, counts, 0, type, starts, 0, primcount, 0, drawCount );

			int elementCount = 0;
			for (int i = 0; i < drawCount; i ++ ) {
				elementCount += counts[ i ];
			}

			for (int i = 0; i < primcount.length; i ++ ) {
				info.update( elementCount, mode, primcount[ i ] );
			}
		}
	}
}
