import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';

class StereoEffect {
  final _stereo = StereoCamera();
  WebGLRenderer renderer;
  final size = Vector2();

	StereoEffect(this.renderer) {
		_stereo.aspect = 0.5;
  }

  void setEyeSeparation(double eyeSep) {
    _stereo.eyeSep = eyeSep;
  }

  void setSize(double width, double height) {
    renderer.setSize( width, height );
  }

  void render(Scene scene, Camera camera) {
    if ( scene.matrixWorldAutoUpdate == true ) scene.updateMatrixWorld();
    if ( camera.parent == null && camera.matrixWorldAutoUpdate == true ) camera.updateMatrixWorld();

    _stereo.update( camera );

    final currentAutoClear = renderer.autoClear;
    renderer.getSize( size );

    renderer.autoClear = false;
    renderer.clear();

    renderer.setScissorTest( true );

    renderer.setScissor( 0, 0, size.width / 2, size.height );
    renderer.setViewport( 0, 0, size.width / 2, size.height );
    renderer.render( scene, _stereo.cameraL );

    renderer.setScissor( size.width / 2, 0, size.width / 2, size.height );
    renderer.setViewport( size.width / 2, 0, size.width / 2, size.height );
    renderer.render( scene, _stereo.cameraR );

    renderer.setScissorTest( false );
    renderer.autoClear = currentAutoClear;
  }
}
