part of three_webgl;

class BaseWebGLBufferRenderer {
  void setIndex(value) {
    throw (" BaseWebGLBufferRenderer.setIndex value: $value  ");
  }

  void render(int start, int count) {
    throw (" BaseWebGLBufferRenderer.render start: $start $count  ");
  }

  void renderInstances(int start, int count, int primcount) {
    throw (" BaseWebGLBufferRenderer.renderInstances start: $start $count primcount: $primcount  ");
  }

  void setMode(value) {
    throw (" BaseWebGLBufferRenderer.setMode value: $value ");
  }

  void renderMultiDraw(List<int> starts, List<int> counts, int drawCount) {
    throw (" BaseWebGLBufferRenderer.renderMultiDraw not supported ");
  }

  void renderMultiDrawInstances(List<int> starts, List<int> counts, int drawCount, List<int> primcount ) {
    throw (" BaseWebGLBufferRenderer.renderMultiDrawInstances not supported ");
  }
}

class WebGLBufferRenderer extends BaseWebGLBufferRenderer {
  bool _didDispose = false;
  RenderingContext gl;
  bool isWebGL2 = true;
  dynamic mode;
  WebGLExtensions extensions;
  WebGLInfo info;

  WebGLBufferRenderer(this.gl, this.extensions, this.info);

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
  void render(int start, int count) {
    gl.drawArrays(mode, start, count);
    info.update(count, mode, 1);
  }

  @override
  void renderInstances(int start, int count, int primcount) {
    if (primcount == 0) return;
    gl.drawArraysInstanced(mode, start, count, primcount);
    info.update(count, mode, primcount);
  }

  @override
	void renderMultiDraw(List<int> starts, List<int> counts, int drawCount) {
		if ( drawCount == 0 ) return;
		final extension = extensions.get( 'WEBGL_multi_draw' );

		if ( extension == null ) {
			for (int i = 0; i < drawCount; i ++ ) {
				render(starts[i], counts[i]);
			}
		} 
    else {
			extension.multiDrawArraysWEBGL( mode, starts, 0, counts, 0, drawCount );
			int elementCount = 0;
			for (int i = 0; i < drawCount; i ++ ) {
				elementCount += counts[i];
			}

			info.update( elementCount, mode, 1 );
		}
	}

  @override
	void renderMultiDrawInstances(List<int> starts, List<int> counts, int drawCount, List<int> primcount ) {
		if ( drawCount == 0 ) return;
		final extension = extensions.get( 'WEBGL_multi_draw' );

		if ( extension == null ) {
			for (int i = 0; i < starts.length; i ++ ) {
				renderInstances(starts[i], counts[i], primcount[i]);
			}
		} 
    else {
			extension.multiDrawArraysInstancedWEBGL( mode, starts, 0, counts, 0, primcount, 0, drawCount );

			int elementCount = 0;
			for (int i = 0; i < drawCount; i ++ ) {
				elementCount += counts[ i ];
			}
			for (int i = 0; i < primcount.length; i ++ ) {
				info.update(elementCount, mode, primcount[i]);
			}
		}
	}
}
