import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_postprocessing/post/index.dart';
import 'package:three_js_postprocessing/shaders/index.dart';


class LUTPass extends ShaderPass {
  LUTPass(Map<String, dynamic> options):super.fromJson(lutShader) {
    lut = options["lut"];
    intensity = options["intensity"] ?? 1;
  }

  set lut(v) {
    final material = this.material;

    if (v != lut) {
      material.uniforms["lut3d"]["value"] = null;
      material.uniforms["lut"]["value"] = null;

      if (v != null) {
        final is3dTextureDefine = v is Data3DTexture ? 1 : 0;
        if (is3dTextureDefine != material.defines!["USE_3DTEXTURE"]) {
          material.defines!["USE_3DTEXTURE"] = is3dTextureDefine;
          material.needsUpdate = true;
        }

        if (v is Data3DTexture) {
          material.uniforms["lut3d"]["value"] = v;
        } 
        else {
          material.uniforms["lut"]["value"] = v;
          material.uniforms["lutSize"]["value"] = v.image.width;
        }
      }
    }
  }

  num get lut {
    return material.uniforms["lut"]["value"] ?? material.uniforms["lut3d"]["value"];
  }

  set intensity(num v) {
    material.uniforms["intensity"]["value"] = v;
  }

  num get intensity {
    return material.uniforms["intensity"]["value"];
  }
}
