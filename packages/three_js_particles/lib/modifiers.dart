import 'package:three_js/three_js.dart' as three;
import 'utils.dart';
import 'types.dart';

final noiseInput = three.Vector3(0, 0, 0);
final orbitalEuler = three.Euler();

class Modifiers{
  static void applyModifiers({
    required double delta,
    required GeneralData generalData,
    required NormalizedParticleSystemConfig normalizedConfig,
    required Map attributes,
    required double particleLifetimePercentage,
    required int particleIndex,
  }){
    final particleSystemId = generalData.particleSystemId;
    final startValues = generalData.startValues;
    final lifetimeValues = generalData.lifetimeValues;
    final linearVelocityData = generalData.linearVelocityData;
    final orbitalVelocityData = generalData.orbitalVelocityData;
    final noise = generalData.noise;

    final positionIndex = particleIndex * 3;
    final positionArr = attributes['position'].array;

    if (linearVelocityData != null) {
      final speed = linearVelocityData[particleIndex].speed;
      final valueModifiers = linearVelocityData[particleIndex].valueModifiers;

      final normalizedXSpeed = valueModifiers?.x != null
        ? valueModifiers!.x!(particleLifetimePercentage)
        : speed!.x;

      final normalizedYSpeed = valueModifiers?.y != null
        ? valueModifiers!.y!(particleLifetimePercentage)
        : speed!.y;

      final normalizedZSpeed = valueModifiers?.z != null
        ? valueModifiers!.z!(particleLifetimePercentage)
        : speed!.z;

      positionArr[positionIndex] += normalizedXSpeed * delta;
      positionArr[positionIndex + 1] += normalizedYSpeed * delta;
      positionArr[positionIndex + 2] += normalizedZSpeed * delta;

      attributes['position'].needsUpdate = true;
    }

    if (orbitalVelocityData != null) {
      final speed = orbitalVelocityData[particleIndex].speed;
      final positionOffset = orbitalVelocityData[particleIndex].positionOffset!;
      final valueModifiers = orbitalVelocityData[particleIndex].valueModifiers;

      positionArr[positionIndex] -= positionOffset.x;
      positionArr[positionIndex + 1] -= positionOffset.y;
      positionArr[positionIndex + 2] -= positionOffset.z;

      final normalizedXSpeed = valueModifiers?.x != null
        ? valueModifiers!.x!(particleLifetimePercentage)
        : speed!.x;

      final normalizedYSpeed = valueModifiers?.y != null
        ? valueModifiers!.y!(particleLifetimePercentage)
        : speed!.y;

      final normalizedZSpeed = valueModifiers?.z != null
        ? valueModifiers!.z!(particleLifetimePercentage)
        : speed!.z;

      orbitalEuler.set(
        normalizedXSpeed * delta,
        normalizedZSpeed * delta,
        normalizedYSpeed * delta
      );
      positionOffset.applyEuler(orbitalEuler);

      positionArr[positionIndex] += positionOffset.x;
      positionArr[positionIndex + 1] += positionOffset.y;
      positionArr[positionIndex + 2] += positionOffset.z;

      attributes['position'].needsUpdate = true;
    }

    if (normalizedConfig.sizeOverLifetime?.isActive == true) {
      final multiplier = Utils.calculateValue(
        particleSystemId,
        normalizedConfig.sizeOverLifetime!.lifetimeCurve,
        particleLifetimePercentage
      );
      attributes['size'].array[particleIndex] =
        startValues!['startSize']![particleIndex] * multiplier;
      attributes['size'].needsUpdate = true;
    }

    if (normalizedConfig.opacityOverLifetime?.isActive == true) {
      final multiplier = Utils.calculateValue(
        particleSystemId,
        normalizedConfig.opacityOverLifetime!.lifetimeCurve,
        particleLifetimePercentage
      );
      attributes['colorA'].array[particleIndex] =
        startValues!['startOpacity']![particleIndex] * multiplier;
      attributes['colorA'].needsUpdate = true;
    }

    if (lifetimeValues!['rotationOverLifetime']!.isNotEmpty) {
      attributes['rotation'].array[particleIndex] +=
        lifetimeValues['rotationOverLifetime']![particleIndex] * delta * 0.02;
      attributes['rotation'].needsUpdate = true;
    }

    if (noise?.isActive == true) {
      final sampler = noise!.sampler;
      final strength = noise.strength;
      final offsets = noise.offsets;
      final positionAmount = noise.positionAmount;
      final rotationAmount = noise.rotationAmount;
      final sizeAmount = noise.sizeAmount;
      double noiseOnPosition;

      final noisePosition =
        (particleLifetimePercentage + (offsets != null? offsets[particleIndex] : 0)) *
        10 *
        strength;
      final noisePower = 0.15 * strength;

      noiseInput.setValues(noisePosition, 0, 0);
      noiseOnPosition = sampler!.get3(noiseInput);
      positionArr[positionIndex] += noiseOnPosition * noisePower * positionAmount;

      if (rotationAmount != 0) {
        attributes['rotation'].array[particleIndex] +=
          noiseOnPosition * noisePower * rotationAmount;
        attributes['rotation'].needsUpdate = true;
      }

      if (sizeAmount != 0) {
        attributes['size'].array[particleIndex] +=
          noiseOnPosition * noisePower * sizeAmount;
        attributes['size'].needsUpdate = true;
      }

      noiseInput.setValues(noisePosition, noisePosition, 0);
      noiseOnPosition = sampler.get3(noiseInput);
      positionArr[positionIndex + 1] +=
        noiseOnPosition * noisePower * positionAmount;

      noiseInput.setValues(noisePosition, noisePosition, noisePosition);
      noiseOnPosition = sampler.get3(noiseInput);
      positionArr[positionIndex + 2] +=
        noiseOnPosition * noisePower * positionAmount;

      attributes['position'].needsUpdate = true;
    }
  }
}