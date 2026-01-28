import 'package:three_js_math/three_js_math.dart';

abstract class State {
  Map<String, dynamic> get buffers;

  void enable(id);
  void disable(id);

  void scissor(Vector4 scissor) ;
  void viewport(Vector4 viewport);

  void setBlending(int blending);
  void setScissorTest(bool scissorTest);

  void reset();
  void dispose();
}
