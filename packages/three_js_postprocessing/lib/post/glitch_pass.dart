import 'dart:typed_data';
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';
import 'package:three_js_postprocessing/post/index.dart';
import 'package:three_js_postprocessing/shaders/digital_glitch.dart';
import 'pass.dart';
import 'dart:math' as math;

class GlitchPass extends Pass {
  bool goWild = false;
  num curF = 0;
  late num randX;

  GlitchPass(int? dtSize) : super() {
    final shader = digitalGlitch;
    uniforms = UniformsUtils.clone(shader["uniforms"]);
    dtSize ??= 64;

    uniforms['tDisp']["value"] = generateHeightmap(dtSize);

    material = ShaderMaterial.fromMap({
      "uniforms": uniforms,
      "vertexShader": shader["vertexShader"],
      "fragmentShader": shader["fragmentShader"]
    });

    fsQuad = FullScreenQuad(material);
    generateTrigger();
  }

  static double randFloat(double low, double high) {
    return low +math.Random().nextDouble() * (high - low);
  }
  static int randInt(int low, int high) {
    return low + (math.Random().nextDouble() * (high - low + 1)).floor();
  }
  @override
  void render(renderer, writeBuffer, readBuffer,{double? deltaTime, bool? maskActive}) {
    uniforms['tDiffuse']["value"] = readBuffer.texture;
    uniforms['seed']["value"] = math.Random().nextDouble(); //default seeding
    uniforms['byp']["value"] = 0;

    if (curF % randX == 0 || goWild == true) {
      uniforms['amount']["value"] = math.Random().nextDouble() / 30;
      uniforms['angle']["value"] = randFloat(-math.pi, math.pi);
      uniforms['seed_x']["value"] = randFloat(-1, 1);
      uniforms['seed_y']["value"] = randFloat(-1, 1);
      uniforms['distortion_x']["value"] = randFloat(0, 1);
      uniforms['distortion_y']["value"] = randFloat(0, 1);
      curF = 0;
      generateTrigger();
    } else if (curF % randX < randX / 5) {
      uniforms['amount']["value"] = math.Random().nextDouble() / 90;
      uniforms['angle']["value"] = randFloat(-math.pi, math.pi);
      uniforms['distortion_x']["value"] = randFloat(0, 1);
      uniforms['distortion_y']["value"] = randFloat(0, 1);
      uniforms['seed_x']["value"] = randFloat(-0.3, 0.3);
      uniforms['seed_y']["value"] = randFloat(-0.3, 0.3);
    } 
    else if (goWild == false) {
      uniforms['byp']["value"] = 1;
    }

    curF++;

    if (renderToScreen) {
      renderer.setRenderTarget(null);
      fsQuad.render(renderer);
    } else {
      renderer.setRenderTarget(writeBuffer);
      if (clear) renderer.clear();
      fsQuad.render(renderer);
    }
  }

  void generateTrigger() {
    randX = randInt(120, 240);
  }

  DataTexture generateHeightmap(int dtSize) {
    final dataArr = Float32List(dtSize * dtSize * 3);
    final length = dtSize * dtSize;

    for (int i = 0; i < length; i++) {
      final val = randFloat(0, 1);
      dataArr[i * 3 + 0] = val;
      dataArr[i * 3 + 1] = val;
      dataArr[i * 3 + 2] = val;
    }

    return DataTexture(dataArr, dtSize, dtSize, RGBFormat, FloatType);
  }
}
