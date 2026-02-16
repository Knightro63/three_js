import 'dart:typed_data';

import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';
import './shaders/index.dart';
import 'dart:math' as math;

class AtmosphereParameters{
  late int particles;
  late int minParticleSize;
  late int maxParticleSize;
  late double radius;
  late double thickness;
  late double density;
  late double opacity;
  late double scale;
  late Color color;
  late double speed;
  late Vector3 lightDirection;

  AtmosphereParameters.fromMap([Map<String,dynamic>? map]){
    map = map ?? {};
    particles = map['particles'] ?? 4000;
    minParticleSize = map['minParticleSize'] ?? 50;
    maxParticleSize = map['maxParticleSize'] ?? 100;
    radius = map['radius'] ?? 0.0;
    thickness = map['thickness'] ?? 1.5;
    density = map['density'] ?? 0.0;
    opacity = map['opacity'] ?? 0.35;
    scale = map['scale'] ?? 8.0;
    color = map['color'] != null ? Color.fromHex32(map['color']) : Color.fromHex32(0xffffff);
    speed = map['speed'] ?? 0.03;
    lightDirection = map['lightDirection'] != null ? Vector3(map['lightDirection'][0], map['lightDirection'][1], map['lightDirection'][2]) : Vector3(1,1,1);
  }

  AtmosphereParameters({
    this.particles = 4000,
    this.minParticleSize = 50,
    this.maxParticleSize = 100,
    this.radius = 0.0,
    this.thickness = 1.5,
    this.density = 0,
    this.opacity = 0.35,
    this.scale = 8,
    Color? color,
    this.speed = 0.03,
    Vector3? lightDirection
  }){
    this.color = color ?? Color.fromHex32(0xffffff);
    this.lightDirection = lightDirection ?? Vector3(1,1,1);
  }

  dynamic operator [] (key) => uniforms[key]['value'];
  void operator []=(String key, dynamic value) => setProperty(key, value);

  void setProperty(String key, value){
    if(key == 'particles'){
      particles = value;
    }
    else if(key == 'minParticleSize'){
      minParticleSize = value;
    }
    else if(key == 'maxParticleSize'){
      maxParticleSize = value;
    }
    else if(key == 'radius'){
      radius = value;
    }
    else if(key == 'thickness'){
      thickness = value;
    }
    else if(key == 'scale'){
      scale = value;
    }
    else if(key == 'density'){
      density = value;
    }
    else if(key == 'opacity'){
      opacity = value;
    }
    else if(key == 'color'){
      color = value;
    }
    else if(key == 'speed'){
      speed = value;
    }
    else if(key == 'lightDirection'){
      lightDirection = value;
    }
  }

  Map<String,dynamic> get json =>{
    'particles': particles,
    'minParticleSize': minParticleSize,
    'maxParticleSize': maxParticleSize,
    'radius': radius,
    'thickness': thickness,
    'density': density,
    'opacity': opacity,
    'scale': scale,
    'color': color,
    'speed': speed,
    'lightDirection': lightDirection
  };

  Map<String,dynamic> get uniforms =>{
    'particles': {'value': particles },
    'minParticleSize': {'value': minParticleSize },
    'maxParticleSize': {'value': maxParticleSize },
    'radius': {'value': radius },
    'thickness': {'value': thickness },
    'density': {'value': density },
    'opacity': {'value': opacity },
    'scale': {'value': scale },
    'color': {'value': color },
    'speed': {'value': speed },
    'lightDirection': {'value': lightDirection},
  };
}

class Atmosphere extends Points {
  late final AtmosphereParameters atmosphereParams;
  
  Atmosphere._(super.geometry, super.material, this.atmosphereParams, int renderOrder){
    this.renderOrder = renderOrder;
  }

  factory Atmosphere({AtmosphereParameters? atmosphereParams, Texture? cloudTexture, int renderOrder = 2}){
    atmosphereParams ??= AtmosphereParameters();

    final material = ShaderMaterial.fromMap({
      'uniforms': {
        'time': { 'value': 0.0 },
        'pointTexture': { 'value': cloudTexture },
        'radius': { 'value': atmosphereParams.radius },
        'thickness': { 'value': atmosphereParams.thickness },
        ...atmosphereParams.uniforms
      },
      'vertexShader': atosphereVertexShader,
      'fragmentShader': atmosphereFragmentShader.replaceAll(
        'void main() {',
        '''${noiseFunctions}
         void main() {'''
      ),
      'depthWrite': false,
      'transparent': true,
      'blending': AdditiveBlending,
    });
    material.polygonOffset = true;
    material.polygonOffsetFactor = -1.0;
    material.polygonOffsetUnits = -4.0;

    
    final int count = atmosphereParams.particles;
    final Float32List combinedData = Float32List(count * 6);
    final random = math.Random();
    for(int i = 0; i < count; i++) {
      double r = random.nextDouble() * atmosphereParams.thickness + atmosphereParams.radius;

      // Pick a random point within a cube of size [-1, 1]
      // This approach works better than parameterizing the spherical coordinates
      // since it doesn't have the issue of particles being bunched at the poles
      final p = Vector3(
        2 * random.nextDouble() - 1,
        2 * random.nextDouble() - 1,
        2 * random.nextDouble() - 1
      );

      // Project onto the surface of a sphere
      p.normalize();
      p.scale(r);

      final minSize = atmosphereParams.minParticleSize;
      final maxSize = atmosphereParams.maxParticleSize;
      final size = random.nextDouble() * (maxSize - minSize) + minSize;

      combinedData.setAll(i * 4, [p.x, p.y, p.z, size]);
    }

    final geometry = BufferGeometry();
    final interleavedBuffer = InterleavedBuffer(combinedData, 4);

    geometry.setAttributeFromString('position', InterleavedBufferAttribute(interleavedBuffer, 3, 0));
    geometry.setAttributeFromString('size', InterleavedBufferAttribute(interleavedBuffer, 1, 3));   

    geometry.computeBoundingSphere();
    geometry.computeBoundingBox();

    return Atmosphere._(geometry, material, atmosphereParams, renderOrder);
  }

  void update(double dt){
    material?.uniforms['time']['value'] += dt;
  }
}