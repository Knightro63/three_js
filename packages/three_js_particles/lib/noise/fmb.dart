//import { Perlin } from "./Perlin";
import 'package:three_js_math/three_js_math.dart';
import 'dart:math' as math;

import 'package:three_js_particles/noise/perlin.dart';

class FBMOpts{
  double? seed;
  double? scale;
  double? persistance;
  double? lacunarity;
  double? octaves;
  double? redistribution;

  FBMOpts({
    this.scale,
    this.seed,
    this.persistance,
    this.redistribution,
    this.lacunarity,
    this.octaves
  });
}

class FBM {
  late Perlin _noise;
  late double _scale;
  late double _persistance;
  late double _lacunarity;
  late double _octaves;
  late double _redistribution;

  FBM(FBMOpts options) {
    final seed = options.seed;
    final scale = options.scale; 
    final persistance = options.persistance;
    final lacunarity = options.lacunarity;
    final octaves = options.octaves; 
    final redistribution = options.redistribution;
    
    this._noise = Perlin(seed);
    this._scale = scale ?? 1;
    this._persistance = persistance ?? 0.5;
    this._lacunarity = lacunarity ?? 2;
    this._octaves = octaves ?? 6;
    this._redistribution = redistribution ?? 1;
  }

  double get2(Vector2 input) {
    double result = 0;
    double amplitude = 1;
    double frequency = 1;
    double max = amplitude;

    double Function(Vector2) noiseFunction = this._noise.get2;//.bind(this._noise);

    for (int i = 0; i < this._octaves; i++) {
      final position = Vector2(
        input.x * this._scale * frequency,
        input.y * this._scale * frequency
      );

      final noiseVal = noiseFunction(position);
      result += noiseVal * amplitude;

      frequency *= this._lacunarity;
      amplitude *= this._persistance;
      max += amplitude;
    }

    final redistributed = math.pow(result, this._redistribution);
    return redistributed / max;
  }

  double get3(Vector3 input) {
    double result = 0;
    double amplitude = 1;
    double frequency = 1;
    double max = amplitude;

    double Function(Vector3)  noiseFunction = this._noise.get3;//.bind(this._noise);

    for (int i = 0; i < this._octaves; i++) {
      final position = new Vector3(
        input.x * this._scale * frequency,
        input.y * this._scale * frequency,
        input.z * this._scale * frequency
      );

      final noiseVal = noiseFunction(position);
      result += noiseVal * amplitude;

      frequency *= this._lacunarity;
      amplitude *= this._persistance;
      max += amplitude;
    }

    final redistributed = math.pow(result, this._redistribution);
    return redistributed / max;
  }
}