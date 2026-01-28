import 'atmosphere.dart';
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';
import './shaders/index.dart';

/*
MIT License

Copyright (c) 2023 Daniel Greenheck

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

class PlanetGeneratorParameters{
  int type;
  double radius;
  double amplitude;
  double sharpness;
  double offset;
  double period;
  double persistence;
  double lacunarity;
  int octaves;
  double undulation;
  double ambientIntensity;
  double diffuseIntensity;
  double specularIntensity;
  double shininess;
  late final Vector3 lightDirection;
  late final Color lightColor;
  double bumpStrength;
  double bumpOffset;
  late final Color color1;
  late final Color color2;
  late final Color color3;
  late final Color color4;
  late final Color color5;
  double transition2;
  double transition3;
  double transition4;
  double transition5;
  double blend12;
  double blend23;
  double blend34;
  double blend45;

  PlanetGeneratorParameters({
    this.type = 2,
    this.radius = 20.1,
    this.amplitude = 1.19,
    this.sharpness = 2.6,
    this.offset = -0.016,
    this.period = 0.6,
    this.persistence = 0.484,
    this.lacunarity = 1.8,
    this.octaves = 8,
    this.undulation = 0,
    this.ambientIntensity = 0.02,
    this.diffuseIntensity = 1,
    this.specularIntensity = 2,
    this.shininess = 10,
    Vector3? lightDirection,
    Color? lightColor,
    this.bumpStrength = 1,
    this.bumpOffset = 0.001,
    Color? color1,
    Color? color2,
    Color? color3,
    Color? color4,
    Color? color5,
    this.transition2 = 0.071,
    this.transition3 = 0.215,
    this.transition4 = 0.372,
    this.transition5 = 1.2,
    this.blend12 = 0.152,
    this.blend23 = 0.152,
    this.blend34 = 0.104,
    this.blend45 = 0.168,
  }){
    this.lightDirection = lightDirection ?? Vector3(1,1,1);
    this.lightColor = lightColor ?? Color.fromHex32(0xffffff);
    this.color1 = color1 ?? Color(0.014, 0.117, 0.279);
    this.color2 = color2 ?? Color(0.080, 0.527, 0.351);
    this.color3 = color3 ?? Color(0.620, 0.516, 0.372);
    this.color4 = color4 ?? Color(0.149, 0.254, 0.084);
    this.color5 = color5 ?? Color(0.150, 0.150, 0.150);
  }

  dynamic operator [] (key) => uniforms[key]['value'];
  void operator []=(String key, dynamic value) => setProperty(key, value);

  void setProperty(String key, value){
    if(key == 'type'){
      type = value;
    }
    else if(key == 'radius'){
      radius = value;
    }
    else if(key == 'amplitude'){
      amplitude = value;
    }
    else if(key == 'sharpness'){
      sharpness = value;
    }
    else if(key == 'offset'){
      offset = value;
    }
    else if(key == 'period'){
      period = value;
    }
    else if(key == 'persistence'){
      persistence = value;
    }
    else if(key == 'lacunarity'){
      lacunarity = value;
    }
    else if(key == 'octaves'){
      octaves = value.toInt();
    }
    else if(key == 'undulation'){
      undulation = value;
    }
    else if(key == 'ambientIntensity'){
      ambientIntensity = value;
    }
    else if(key == 'diffuseIntensity'){
      diffuseIntensity = value;
    }
    else if(key == 'shininess'){
      shininess = value;
    }
    else if(key == 'lightDirection'){
      lightDirection = value;
    }
    else if(key == 'lightColor'){
      if(value is int){
        lightColor = Color.fromHex32(value);
        return;
      }
      lightColor = value;
    }
    else if(key == 'bumpStrength'){
      bumpStrength = value;
    }
    else if(key == 'bumpOffset'){
      bumpOffset = value;
    }
    else if(key == 'color1'){
      if(value is int){
        color1 = Color.fromHex32(value);
        return;
      }
      color1 = value;
    }
    else if(key == 'color2'){
      if(value is int){
        color2 = Color.fromHex32(value);
        return;
      }
      color2 = value;
    }
    else if(key == 'color3'){
      if(value is int){
        color3 = Color.fromHex32(value);
        return;
      }
      color3 = value;
    }
    else if(key == 'color4'){
      if(value is int){
        color4 = Color.fromHex32(value);
        return;
      }
      color4 = value;
    }
    else if(key == 'color5'){
      if(value is int){
        color5 = Color.fromHex32(value);
        return;
      }
      color5 = value;
    }
    else if(key == 'transition2'){
      transition2 = value;
    }
    else if(key == 'transition3'){
      transition3 = value;
    }
    else if(key == 'transition4'){
      transition4 = value;
    }
    else if(key == 'transition5'){
      transition5 = value;
    }
    else if(key == 'blend12'){
      blend12 = value;
    }
    else if(key == 'blend23'){
      blend23 = value;
    }
    else if(key == 'blend34'){
      blend34 = value;
    }
    else if(key == 'blend45'){
      blend45 = value;
    }
  }

  Map<String,dynamic> get json => { 
    'type': type,
    'radius': radius,
    'amplitude': amplitude,
    'sharpness': sharpness,
    'offset': offset,
    'period': period,
    'persistence': persistence,
    'lacunarity': lacunarity,
    'octaves': octaves,
    'undulation': undulation,
    'ambientIntensity': ambientIntensity,
    'diffuseIntensity': diffuseIntensity,
    'specularIntensity': specularIntensity,
    'shininess': shininess,
    'lightDirection': lightDirection,
    'lightColor': lightColor,
    'bumpStrength': bumpStrength,
    'bumpOffset': bumpOffset,
    'color1': color1,
    'color2': color2,
    'color3': color3,
    'color4': color4,
    'color5': color5,
    'transition2': transition2,
    'transition3': transition3,
    'transition4': transition4,
    'transition5': transition5,
    'blend12': blend12,
    'blend23': blend23,
    'blend34': blend34,
    'blend45': blend45
  };

  Map<String,dynamic> get uniforms => { 
    'type': {'value': type },
    'radius': {'value': radius },
    'amplitude': {'value': amplitude },
    'sharpness': {'value': sharpness },
    'offset': {'value': offset },
    'period': {'value': period },
    'persistence': {'value': persistence },
    'lacunarity': {'value': lacunarity },
    'octaves': {'value': octaves },
    'undulation': {'value': undulation },
    'ambientIntensity': {'value': ambientIntensity },
    'diffuseIntensity': {'value': diffuseIntensity },
    'specularIntensity': {'value': specularIntensity },
    'shininess': {'value': shininess },
    'lightDirection': {'value': lightDirection },
    'lightColor': {'value': lightColor },
    'bumpStrength': {'value': bumpStrength },
    'bumpOffset': {'value': bumpOffset },
    'color1': {'value': color1 },
    'color2': {'value': color2 },
    'color3': {'value': color3 },
    'color4': {'value': color4 },
    'color5': {'value': color5 },
    'transition2': {'value': transition2 },
    'transition3': {'value': transition3 },
    'transition4': {'value': transition4 },
    'transition5': {'value': transition5 },
    'blend12': {'value': blend12 },
    'blend23': {'value': blend23 },
    'blend34': {'value': blend34 },
    'blend45': {'value': blend45 }
  };
}

class PlanetGenerator extends Mesh{
  AtmosphereParameters get atmosphereParams => atmosphere.atmosphereParams;
  late final PlanetGeneratorParameters planetParams;
  late final Atmosphere atmosphere;

  PlanetGenerator({PlanetGeneratorParameters? planetParams,AtmosphereParameters? atmosphereParams, Texture? cloudTexture}):super(){
    this.planetParams = planetParams ?? PlanetGeneratorParameters();
    atmosphereParams ??= AtmosphereParameters();

    atmosphereParams.radius = this.planetParams.radius+1;
    atmosphereParams.lightDirection = this.planetParams.lightDirection;

    this.material = ShaderMaterial.fromMap({
      'uniforms': this.planetParams.uniforms,
      'vertexShader': vertexShader.replaceAll(
        'void main() {',
        '''${noiseFunctions}
        void main() {'''
      ),
      'fragmentShader': fragmentShader.replaceAll(
        'void main() {',
        '''${noiseFunctions}
        void main() {'''
      ),
    });

    this.geometry = SphereGeometry(1, 128, 128);
    this.geometry?.computeTangents();
    
    atmosphere = Atmosphere(atmosphereParams, cloudTexture);
    atmosphere.renderOrder = 1;
    this.add(atmosphere);

    type = "Mesh";
    updateMorphTargets();

    geometry?.computeBoundingSphere();
    geometry?.computeBoundingBox();

    this.renderOrder = 0;
  }
}