import 'dart:convert';
import 'dart:math' as math;
import 'utils.dart';
import 'package:three_js/three_js.dart' as three;
// import { Gyroscope } from 'three/examples/jsm/misc/Gyroscope.js';
// import { FBM } from 'three-noise/build/three-noise.module.js';
import './shaders/particle-system-fragment-shader.glsl.dart';
import './shaders/particle-system-vertex-shader.glsl.dart';
import 'bezier.dart';
import 'enums.dart';
import 'modifiers.dart';
import './types.dart';

int _particleSystemId = 0;
List<ParticleSystemInstance> createdParticleSystems  = [];

class Particles {
  final blendingMap = {
    'NoBlending': three.NoBlending,
    'NormalBlending': three.NormalBlending,
    'AdditiveBlending': three.AdditiveBlending,
    'SubtractiveBlending': three.SubtractiveBlending,
    'MultiplyBlending': three.MultiplyBlending,
  };

  Map get getDefaultParticleSystemConfig => DEFAULT_PARTICLE_SYSTEM_CONFIG;

  final Map DEFAULT_PARTICLE_SYSTEM_CONFIG = {
    'transform': {
      'position': three.Vector3(),
      'rotation': three.Vector3(),
      'scale': three.Vector3(1, 1, 1),
    },
    'duration': 5.0,
    'looping': true,
    'startDelay': 0,
    'startLifetime': 5.0,
    'startSpeed': 1.0,
    'startSize': 1.0,
    'startOpacity': 1.0,
    'startRotation': 0.0,
    'startColor': {
      'min': { 'r': 1.0, 'g': 1.0, 'b': 1.0 },
      'max': { 'r': 1.0, 'g': 1.0, 'b': 1.0 },
    },
    'gravity': 0.0,
    'simulationSpace': SimulationSpace.local,
    'maxParticles': 100.0,
    'emission': {
      'rateOverTime': 10.0,
      'rateOverDistance': 0.0,
    },
    'shape': {
      'shape': Shape.sphere,
      'sphere': {
        'radius': 1.0,
        'radiusThickness': 1.0,
        'arc': 360.0,
      },
      'cone': {
        'angle': 25.0,
        'radius': 1.0,
        'radiusThickness': 1.0,
        'arc': 360.0,
      },
      'circle': {
        'radius': 1.0,
        'radiusThickness': 1.0,
        'arc': 360.0,
      },
      'rectangle': {
        'rotation': { 'x': 0.0, 'y': 0.0 }, // TODO: add z rotation
        'scale': { 'x': 1.0, 'y': 1.0 },
      },
      'box': {
        'scale': { 'x': 1.0, 'y': 1.0, 'z': 1.0 },
        'emitFrom': EmitFrom.volume,
      },
    },
    'map': null,
    'renderer': {
      'blending': three.NormalBlending,
      'discardBackgroundColor': false,
      'backgroundColorTolerance': 1.0,
      'backgroundColor': { 'r': 1.0, 'g': 1.0, 'b': 1.0 },
      'transparent': true,
      'depthTest': true,
      'depthWrite': false,
    },
    'velocityOverLifetime': {
      'isActive': false,
      'linear': {
        'x': 0,
        'y': 0,
        'z': 0,
      },
      'orbital': {
        'x': 0,
        'y': 0,
        'z': 0,
      },
    },
    'sizeOverLifetime': {
      'isActive': false,
      'lifetimeCurve': {
        'type': LifeTimeCurve.bezier,
        'scale': 1,
        'bezierPoints': [
          { 'x': 0, 'y': 0, 'percentage': 0 },
          { 'x': 1, 'y': 1, 'percentage': 1 },
        ],
      },
    },
    /* colorOverLifetime: {
      isActive: false,
      lifetimeCurve: {
        type: LifeTimeCurve.EASING,
        scale: 1,
        curveFunction: CurveFunctionId.LINEAR,
      },
    }, */
    'opacityOverLifetime': {
      'isActive': false,
      'lifetimeCurve': {
        'type': LifeTimeCurve.bezier,
        'scale': 1,
        'bezierPoints': [
          { 'x': 0, 'y': 0, 'percentage': 0 },
          { 'x': 1, 'y': 1, 'percentage': 1 },
        ],
      },
    },
    'rotationOverLifetime': {
      'isActive': false,
      'min': 0.0,
      'max': 0.0,
    },
    'noise': {
      'isActive': false,
      'useRandomOffset': false,
      'strength': 1.0,
      'frequency': 0.5,
      'octaves': 1,
      'positionAmount': 1.0,
      'rotationAmount': 0.0,
      'sizeAmount': 0.0,
    },
    'textureSheetAnimation': {
      'tiles': three.Vector2(1.0, 1.0),
      'timeMode': TimeMode.lifetime,
      'fps': 30.0,
      'startFrame': 0,
    },
  };

  void createFloat32Attributes({
    three.BufferGeometry geometry,
    String propertyName,
    int maxParticles,
    factory,
  }: {
    geometry: ;
    propertyName: string;
    maxParticles: number;
    factory: ((value: never, index: number) => number) | number;
  }){
    geometry.setAttribute(
      propertyName,
      three.BufferAttribute(
        three.Float32Array(
          Array.from(
            { length: maxParticles },
            typeof factory === 'function' ? factory : () => factory
          )
        ),
        1
      )
    );
  };

  void calculatePositionAndVelocity (
    GeneralData generalData,
    ShapeConfig config,
    //{ shape, sphere, cone, circle, rectangle, box }: ,
    dynamic startSpeed,//: Constant | RandomBetweenTwoConstants | LifetimeCurve,
    three.Vector3 position,
    three.Vector3 velocity
  ){

    final shape = config.shape;
    final calculatedStartSpeed = Utils.calculateValue(
      generalData.particleSystemId,
      startSpeed,
      generalData.normalizedLifetimePercentage
    );

    switch (shape) {
      case Shape.sphere:
        Utils.calculateRandomPositionAndVelocityOnSphere(
          position,
          generalData.wrapperQuaternion!,
          velocity,
          calculatedStartSpeed,
          config.sphere!
        );
        break;

      case Shape.cone:
        Utils.calculateRandomPositionAndVelocityOnCone(
          position,
          generalData.wrapperQuaternion!,
          velocity,
          calculatedStartSpeed,
          config.cone!
        );
        break;

      case Shape.circle:
        Utils.calculateRandomPositionAndVelocityOnCircle(
          position,
          generalData.wrapperQuaternion!,
          velocity,
          calculatedStartSpeed,
          config.circle!
        );
        break;

      case Shape.rectangle:
        Utils.calculateRandomPositionAndVelocityOnRectangle(
          position,
          generalData.wrapperQuaternion!,
          velocity,
          calculatedStartSpeed,
          config.rectangle!
        );
        break;

      case Shape.box:
        Utils.calculateRandomPositionAndVelocityOnBox(
          position,
          generalData.wrapperQuaternion!,
          velocity,
          calculatedStartSpeed,
          config.box!
        );
        break;
      default:
        break;
    }
  }

  bool destroyParticleSystem(three.Points particleSystem){
    createdParticleSystems = createdParticleSystems.filter(
      ({
        particleSystem: savedParticleSystem,
        wrapper,
        generalData: { particleSystemId },
      }){
        if (
          savedParticleSystem != particleSystem &&
          wrapper != particleSystem
        ) {
          return true;
        }

        removeBezierCurveFunction(particleSystemId);
        savedParticleSystem.geometry.dispose();
        if (Array.isArray(savedParticleSystem.material))
          savedParticleSystem.material.forEach((material) => material.dispose());
        else savedParticleSystem.material.dispose();

        if (savedParticleSystem.parent)
          savedParticleSystem.parent.remove(savedParticleSystem);
        return false;
      }
    );
  }

  ParticleSystem createParticleSystem([
    ParticleSystemConfig config = DEFAULT_PARTICLE_SYSTEM_CONFIG,
    double? externalNow
  ]){
    final now = externalNow ?? DateTime.now().millisecondsSinceEpoch;
    final GeneralData generalData = GeneralData(
      particleSystemId: _particleSystemId++,
      normalizedLifetimePercentage: 0,
      distanceFromLastEmitByDistance: 0,
      lastWorldPosition: three.Vector3(-99999),
      currentWorldPosition: three.Vector3(-99999),
      worldPositionChange: three.Vector3(),
      worldQuaternion: three.Quaternion(),
      wrapperQuaternion: three.Quaternion(),
      lastWorldQuaternion: three.Quaternion(-99999),
      worldEuler: three.Euler(),
      gravityVelocity: three.Vector3(0, 0, 0),
      startValues: {},
      lifetimeValues: {},
      creationTimes: [],
      noise: Noise(
        isActive: false,
        strength: 0,
        positionAmount: 0,
        rotationAmount: 0,
        sizeAmount: 0,
      ),
      isEnabled: true,
    );

    const normalizedConfig = ObjectUtils.deepMerge(
      DEFAULT_PARTICLE_SYSTEM_CONFIG as NormalizedParticleSystemConfig,
      config,
      { applyToFirstObject: false, skippedProperties: [] }
    ) as NormalizedParticleSystemConfig;
    let particleMap: Texture | null =
      normalizedConfig.map || createDefaultParticleTexture();

    const {
      transform,
      duration,
      looping,
      startDelay,
      startLifetime,
      startSpeed,
      startSize,
      startRotation,
      startColor,
      startOpacity,
      gravity,
      simulationSpace,
      maxParticles,
      emission,
      shape,
      renderer,
      noise,
      velocityOverLifetime,
      onUpdate,
      onComplete,
      textureSheetAnimation,
    } = normalizedConfig;

    if (typeof renderer?.blending == 'string')
      renderer.blending = blendingMap[renderer.blending];

    const startPositions = Array.from(
      { length: maxParticles },
      () => Vector3()
    );
    const velocities = Array.from(
      { length: maxParticles },
      () => Vector3()
    );

    generalData.creationTimes = Array.from({ length: maxParticles }, () => 0);

    if (velocityOverLifetime.isActive) {
      generalData.linearVelocityData = Array.from(
        { length: maxParticles },
        () => ({
          speed: Vector3(
            velocityOverLifetime.linear.x
              ? calculateValue(
                  generalData.particleSystemId,
                  velocityOverLifetime.linear.x,
                  0
                )
              : 0,
            velocityOverLifetime.linear.y
              ? calculateValue(
                  generalData.particleSystemId,
                  velocityOverLifetime.linear.y,
                  0
                )
              : 0,
            velocityOverLifetime.linear.z
              ? calculateValue(
                  generalData.particleSystemId,
                  velocityOverLifetime.linear.z,
                  0
                )
              : 0
          ),
          valueModifiers: {
            x: isLifeTimeCurve(velocityOverLifetime.linear.x || 0)
              ? getCurveFunctionFromConfig(
                  generalData.particleSystemId,
                  velocityOverLifetime.linear.x as LifetimeCurve
                )
              : undefined,
            y: isLifeTimeCurve(velocityOverLifetime.linear.y || 0)
              ? getCurveFunctionFromConfig(
                  generalData.particleSystemId,
                  velocityOverLifetime.linear.y as LifetimeCurve
                )
              : undefined,
            z: isLifeTimeCurve(velocityOverLifetime.linear.z || 0)
              ? getCurveFunctionFromConfig(
                  generalData.particleSystemId,
                  velocityOverLifetime.linear.z as LifetimeCurve
                )
              : undefined,
          },
        })
      );

      generalData.orbitalVelocityData = Array.from(
        { length: maxParticles },
        () => ({
          speed: Vector3(
            velocityOverLifetime.orbital.x
              ? calculateValue(
                  generalData.particleSystemId,
                  velocityOverLifetime.orbital.x,
                  0
                )
              : 0,
            velocityOverLifetime.orbital.y
              ? calculateValue(
                  generalData.particleSystemId,
                  velocityOverLifetime.orbital.y,
                  0
                )
              : 0,
            velocityOverLifetime.orbital.z
              ? calculateValue(
                  generalData.particleSystemId,
                  velocityOverLifetime.orbital.z,
                  0
                )
              : 0
          ),
          valueModifiers: {
            x: isLifeTimeCurve(velocityOverLifetime.orbital.x || 0)
              ? getCurveFunctionFromConfig(
                  generalData.particleSystemId,
                  velocityOverLifetime.orbital.x as LifetimeCurve
                )
              : undefined,
            y: isLifeTimeCurve(velocityOverLifetime.orbital.y || 0)
              ? getCurveFunctionFromConfig(
                  generalData.particleSystemId,
                  velocityOverLifetime.orbital.y as LifetimeCurve
                )
              : undefined,
            z: isLifeTimeCurve(velocityOverLifetime.orbital.z || 0)
              ? getCurveFunctionFromConfig(
                  generalData.particleSystemId,
                  velocityOverLifetime.orbital.z as LifetimeCurve
                )
              : undefined,
          },
          positionOffset: Vector3(),
        })
      );
    }

    const startValueKeys: Array<keyof NormalizedParticleSystemConfig> = [
      'startSize',
      'startOpacity',
    ];
    startValueKeys.forEach((key) => {
      generalData.startValues[key] = Array.from({ length: maxParticles }, () =>
        calculateValue(
          generalData.particleSystemId,
          normalizedConfig[key] as
            | Constant
            | RandomBetweenTwoConstants
            | LifetimeCurve,
          0
        )
      );
    });

    const lifetimeValueKeys: Array<keyof NormalizedParticleSystemConfig> = [
      'rotationOverLifetime',
    ];
    lifetimeValueKeys.forEach((key) => {
      const value = normalizedConfig[key] as {
        isActive: boolean;
      } & RandomBetweenTwoConstants;
      if (value.isActive)
        generalData.lifetimeValues[key] = Array.from(
          { length: maxParticles },
          () => MathUtils.randFloat(value.min!, value.max!)
        );
    });

    generalData.noise = Noise(
      isActive: noise.isActive,
      strength: noise.strength,
      positionAmount: noise.positionAmount,
      rotationAmount: noise.rotationAmount,
      sizeAmount: noise.sizeAmount,
      sampler: noise.isActive
        ? new FBM({
            seed: Math.random(),
            scale: noise.frequency,
            octaves: noise.octaves,
          })
        : null,
      offsets: noise.useRandomOffset
        ? Array.from({ length: maxParticles }, () => Math.random() * 100)
        : null,
    );

    final material = three.ShaderMaterial.fromMap({
      'uniforms': {
        'elapsed': {
          'value': 0.0,
        },
        'map': {
          'value': particleMap,
        },
        'tiles': {
          'value': textureSheetAnimation.tiles,
        },
        'fps': {
          'value': textureSheetAnimation.fps,
        },
        'useFPSForFrameIndex': {
          'value': textureSheetAnimation.timeMode == TimeMode.fps,
        },
        'backgroundColor': {
          'value': renderer.backgroundColor,
        },
        'discardBackgroundColor': {
          'value': renderer.discardBackgroundColor,
        },
        'backgroundColorTolerance': {
          'value': renderer.backgroundColorTolerance,
        },
      },
      'vertexShader': ParticleSystemVertexShader,
      'fragmentShader': ParticleSystemFragmentShader,
      'transparent': renderer.transparent,
      'blending': renderer.blending,
      'depthTest': renderer.depthTest,
      'depthWrite': renderer.depthWrite,
  });

    final geometry = three.BufferGeometry();

    for (int i = 0; i < maxParticles; i++)
      calculatePositionAndVelocity(
        generalData,
        shape,
        startSpeed,
        startPositions[i],
        velocities[i]
      );

    geometry.setFromPoints(
      Array.from({ length: maxParticles }, (_, index) =>
        startPositions[index].clone()
      )
    );

    createFloat32AttributesRequest(
      String propertyName,
      dynamic factory,//: ((value: never, index: number) => number) | number
    ){
      createFloat32Attributes(
        geometry: geometry,
        propertyName: propertyName,
        maxParticles: maxParticles,
        factory: factory,
      );
    };

    createFloat32AttributesRequest('isActive', 0);

    createFloat32AttributesRequest('lifetime', 0);

    createFloat32AttributesRequest(
      'startLifetime',
      () => calculateValue(generalData.particleSystemId, startLifetime, 0) * 1000
    );

    createFloat32AttributesRequest('startFrame', () =>
      textureSheetAnimation.startFrame
        ? calculateValue(
            generalData.particleSystemId,
            textureSheetAnimation.startFrame,
            0
          )
        : 0
    );

    createFloat32AttributesRequest('opacity', () =>
      calculateValue(generalData.particleSystemId, startOpacity, 0)
    );

    createFloat32AttributesRequest('rotation', () =>
      calculateValue(generalData.particleSystemId, startRotation, 0)
    );

    createFloat32AttributesRequest(
      'size',
      (_, index) => generalData.startValues.startSize[index]
    );

    createFloat32AttributesRequest('rotation', 0);

    const colorRandomRatio = Math.random();
    createFloat32AttributesRequest(
      'colorR',
      () =>
        startColor.min!.r! +
        colorRandomRatio * (startColor.max!.r! - startColor.min!.r!)
    );
    createFloat32AttributesRequest(
      'colorG',
      () =>
        startColor.min!.g! +
        colorRandomRatio * (startColor.max!.g! - startColor.min!.g!)
    );
    createFloat32AttributesRequest(
      'colorB',
      () =>
        startColor.min!.b! +
        colorRandomRatio * (startColor.max!.b! - startColor.min!.b!)
    );
    createFloat32AttributesRequest('colorA', 0);

    const deactivateParticle = (particleIndex: number) => {
      geometry.attributes.isActive.array[particleIndex] = 0;
      geometry.attributes.colorA.array[particleIndex] = 0;
      geometry.attributes.colorA.needsUpdate = true;
    };

    const activateParticle = ({
      particleIndex,
      activationTime,
      position,
    }: {
      particleIndex: number;
      activationTime: number;
      position: Required<Point3D>;
    }) => {
      geometry.attributes.isActive.array[particleIndex] = 1;
      generalData.creationTimes[particleIndex] = activationTime;

      if (generalData.noise.offsets)
        generalData.noise.offsets[particleIndex] = Math.random() * 100;

      const colorRandomRatio = Math.random();

      geometry.attributes.colorR.array[particleIndex] =
        startColor.min!.r! +
        colorRandomRatio * (startColor.max!.r! - startColor.min!.r!);
      geometry.attributes.colorR.needsUpdate = true;

      geometry.attributes.colorG.array[particleIndex] =
        startColor.min!.g! +
        colorRandomRatio * (startColor.max!.g! - startColor.min!.g!);
      geometry.attributes.colorG.needsUpdate = true;

      geometry.attributes.colorB.array[particleIndex] =
        startColor.min!.b! +
        colorRandomRatio * (startColor.max!.b! - startColor.min!.b!);
      geometry.attributes.colorB.needsUpdate = true;

      geometry.attributes.startFrame.array[particleIndex] =
        textureSheetAnimation.startFrame
          ? calculateValue(
              generalData.particleSystemId,
              textureSheetAnimation.startFrame,
              0
            )
          : 0;
      geometry.attributes.startFrame.needsUpdate = true;

      geometry.attributes.startLifetime.array[particleIndex] =
        calculateValue(
          generalData.particleSystemId,
          startLifetime,
          generalData.normalizedLifetimePercentage
        ) * 1000;
      geometry.attributes.startLifetime.needsUpdate = true;

      generalData.startValues.startSize[particleIndex] = calculateValue(
        generalData.particleSystemId,
        startSize,
        generalData.normalizedLifetimePercentage
      );
      geometry.attributes.size.array[particleIndex] =
        generalData.startValues.startSize[particleIndex];
      geometry.attributes.size.needsUpdate = true;

      generalData.startValues.startOpacity[particleIndex] = calculateValue(
        generalData.particleSystemId,
        startOpacity,
        generalData.normalizedLifetimePercentage
      );
      geometry.attributes.colorA.array[particleIndex] =
        generalData.startValues.startOpacity[particleIndex];
      geometry.attributes.colorA.needsUpdate = true;

      geometry.attributes.rotation.array[particleIndex] = calculateValue(
        generalData.particleSystemId,
        startRotation,
        generalData.normalizedLifetimePercentage
      );
      geometry.attributes.rotation.needsUpdate = true;

      if (normalizedConfig.rotationOverLifetime.isActive)
        generalData.lifetimeValues.rotationOverLifetime[particleIndex] =
          MathUtils.randFloat(
            normalizedConfig.rotationOverLifetime.min!,
            normalizedConfig.rotationOverLifetime.max!
          );

      calculatePositionAndVelocity(
        generalData,
        shape,
        startSpeed,
        startPositions[particleIndex],
        velocities[particleIndex]
      );
      const positionIndex = Math.floor(particleIndex * 3);
      geometry.attributes.position.array[positionIndex] =
        position.x + startPositions[particleIndex].x;
      geometry.attributes.position.array[positionIndex + 1] =
        position.y + startPositions[particleIndex].y;
      geometry.attributes.position.array[positionIndex + 2] =
        position.z + startPositions[particleIndex].z;
      geometry.attributes.position.needsUpdate = true;

      if (generalData.linearVelocityData) {
        generalData.linearVelocityData[particleIndex].speed.set(
          normalizedConfig.velocityOverLifetime.linear.x
            ? calculateValue(
                generalData.particleSystemId,
                normalizedConfig.velocityOverLifetime.linear.x,
                0
              )
            : 0,
          normalizedConfig.velocityOverLifetime.linear.y
            ? calculateValue(
                generalData.particleSystemId,
                normalizedConfig.velocityOverLifetime.linear.y,
                0
              )
            : 0,
          normalizedConfig.velocityOverLifetime.linear.z
            ? calculateValue(
                generalData.particleSystemId,
                normalizedConfig.velocityOverLifetime.linear.z,
                0
              )
            : 0
        );
      }

      if (generalData.orbitalVelocityData) {
        generalData.orbitalVelocityData[particleIndex].speed.set(
          normalizedConfig.velocityOverLifetime.orbital.x
            ? calculateValue(
                generalData.particleSystemId,
                normalizedConfig.velocityOverLifetime.orbital.x,
                0
              )
            : 0,
          normalizedConfig.velocityOverLifetime.orbital.y
            ? calculateValue(
                generalData.particleSystemId,
                normalizedConfig.velocityOverLifetime.orbital.y,
                0
              )
            : 0,
          normalizedConfig.velocityOverLifetime.orbital.z
            ? calculateValue(
                generalData.particleSystemId,
                normalizedConfig.velocityOverLifetime.orbital.z,
                0
              )
            : 0
        );
        generalData.orbitalVelocityData[particleIndex].positionOffset.set(
          startPositions[particleIndex].x,
          startPositions[particleIndex].y,
          startPositions[particleIndex].z
        );
      }

      geometry.attributes.lifetime.array[particleIndex] = 0;
      geometry.attributes.lifetime.needsUpdate = true;

      applyModifiers({
        delta: 0,
        generalData,
        normalizedConfig,
        attributes: particleSystem.geometry.attributes,
        particleLifetimePercentage: 0,
        particleIndex,
      });
    };

    let particleSystem = Points(geometry, material);

    particleSystem.position.copy(transform!.position!);
    particleSystem.rotation.x = three.MathUtils.degToRad(transform.rotation!.x);
    particleSystem.rotation.y = three.MathUtils.degToRad(transform.rotation!.y);
    particleSystem.rotation.z = three.MathUtils.degToRad(transform.rotation!.z);
    particleSystem.scale.copy(transform.scale!);

    const calculatedCreationTime =
      now + calculateValue(generalData.particleSystemId, startDelay) * 1000;

    let wrapper: Gyroscope | undefined;
    if (normalizedConfig.simulationSpace == SimulationSpace.world) {
      wrapper = new Gyroscope();
      wrapper.add(particleSystem);
    }

    createdParticleSystems.add(ParticleSystemInstance(
      particleSystem: particleSystem,
      wrapper: wrapper,
      generalData: generalData,
      onUpdate:onUpdate,
      onComplete: onComplete,
      creationTime: calculatedCreationTime,
      lastEmissionTime: calculatedCreationTime,
      duration:duration,
      looping:looping,
      simulationSpace:simulationSpace,
      gravity:gravity,
      emission:emission,
      normalizedConfig:normalizedConfig,
      iterationCount: 0,
      velocities:velocities,
      deactivateParticle:deactivateParticle,
      activateParticle:activateParticle,
    ));

    final resumeEmitter = () => (generalData.isEnabled = true);
    final pauseEmitter = () => (generalData.isEnabled = false);
    final dispose = () => destroyParticleSystem(particleSystem);

    return ParticleSystem(
      instance: wrapper ?? particleSystem,
      resumeEmitter:resumeEmitter,
      pauseEmitter:pauseEmitter,
      dispose:dispose,
    );
  };

  CycleData updateParticleSystems({ now, delta, elapsed }){
    createdParticleSystems.forEach((props){
      final onUpdate = props.onUpdate;
      final generalData = props.generalData;
      final onComplete = props.onComplete;
      final particleSystem = props.particleSystem;
      final wrapper = props.wrapper;
      final creationTime = props.creationTime;
      final lastEmissionTime = props.lastEmissionTime;
      final duration = props.duration;
      final looping = props.looping;
      final emission = props.emission;
      final normalizedConfig = props.normalizedConfig;
      final iterationCount = props.iterationCount;
      final velocities = props.velocities;
      final deactivateParticle = props.deactivateParticle;
      final activateParticle = props.activateParticle;
      final simulationSpace = props.simulationSpace;
      final gravity = props.gravity;

      final lifetime = now - creationTime;
      final normalizedLifetime = lifetime % (duration * 1000);

      generalData?.normalizedLifetimePercentage = math.max(
        math.min(normalizedLifetime / (duration * 1000), 1),
        0
      );

      final lastWorldPosition = generalData!.lastWorldPosition;
      final currentWorldPosition = generalData.currentWorldPosition;
      final worldPositionChange = generalData.worldPositionChange;
      final lastWorldQuaternion = generalData.lastWorldQuaternion;
      final worldQuaternion = generalData.worldQuaternion;
      final worldEuler = generalData.worldEuler;
      final gravityVelocity = generalData.gravityVelocity;
      final isEnabled = generalData.isEnabled;

      if (wrapper?.parent)
        generalData.wrapperQuaternion?.setFrom(wrapper.parent.quaternion);

      const lastWorldPositionSnapshot = { ...lastWorldPosition };

      if (Array.isArray(particleSystem.material))
        particleSystem.material.forEach((material) => {
          if (material instanceof ShaderMaterial)
            material.uniforms.elapsed.value = elapsed;
        });
      else {
        if (particleSystem.material instanceof ShaderMaterial)
          particleSystem.material.uniforms.elapsed.value = elapsed;
      }

      particleSystem.getWorldPosition(currentWorldPosition);
      if (lastWorldPosition.x !== -99999) {
        worldPositionChange.set(
          currentWorldPosition.x - lastWorldPosition.x,
          currentWorldPosition.y - lastWorldPosition.y,
          currentWorldPosition.z - lastWorldPosition.z
        );
      }
      generalData.distanceFromLastEmitByDistance += worldPositionChange.length();
      particleSystem.getWorldPosition(lastWorldPosition);
      particleSystem.getWorldQuaternion(worldQuaternion);
      if (
        lastWorldQuaternion.x === -99999 ||
        lastWorldQuaternion.x !== worldQuaternion.x ||
        lastWorldQuaternion.y !== worldQuaternion.y ||
        lastWorldQuaternion.z !== worldQuaternion.z
      ) {
        worldEuler.setFromQuaternion(worldQuaternion);
        lastWorldQuaternion.copy(worldQuaternion);
        gravityVelocity.set(
          lastWorldPosition.x,
          lastWorldPosition.y + gravity,
          lastWorldPosition.z
        );
        particleSystem.worldToLocal(gravityVelocity);
      }

      generalData.creationTimes.forEach((entry, index) => {
        if (particleSystem.geometry.attributes.isActive.array[index]) {
          const particleLifetime = now - entry;
          if (
            particleLifetime >
            particleSystem.geometry.attributes.startLifetime.array[index]
          )
            deactivateParticle(index);
          else {
            const velocity = velocities[index];
            velocity.x -= gravityVelocity.x * delta;
            velocity.y -= gravityVelocity.y * delta;
            velocity.z -= gravityVelocity.z * delta;

            if (
              gravity !== 0 ||
              velocity.x !== 0 ||
              velocity.y !== 0 ||
              velocity.z !== 0 ||
              worldPositionChange.x !== 0 ||
              worldPositionChange.y !== 0 ||
              worldPositionChange.z !== 0
            ) {
              const positionIndex = index * 3;
              const positionArr =
                particleSystem.geometry.attributes.position.array;

              if (simulationSpace === SimulationSpace.WORLD) {
                positionArr[positionIndex] -= worldPositionChange.x;
                positionArr[positionIndex + 1] -= worldPositionChange.y;
                positionArr[positionIndex + 2] -= worldPositionChange.z;
              }

              positionArr[positionIndex] += velocity.x * delta;
              positionArr[positionIndex + 1] += velocity.y * delta;
              positionArr[positionIndex + 2] += velocity.z * delta;
              particleSystem.geometry.attributes.position.needsUpdate = true;
            }

            particleSystem.geometry.attributes.lifetime.array[index] =
              particleLifetime;
            particleSystem.geometry.attributes.lifetime.needsUpdate = true;

            const particleLifetimePercentage =
              particleLifetime /
              particleSystem.geometry.attributes.startLifetime.array[index];
            applyModifiers({
              delta,
              generalData,
              normalizedConfig,
              attributes: particleSystem.geometry.attributes,
              particleLifetimePercentage,
              particleIndex: index,
            });
          }
        }
      });

      if (isEnabled && (looping || lifetime < duration * 1000)) {
        const emissionDelta = now - lastEmissionTime;
        const neededParticlesByTime = emission.rateOverTime
          ? Math.floor(
              calculateValue(
                generalData.particleSystemId,
                emission.rateOverTime,
                generalData.normalizedLifetimePercentage
              ) *
                (emissionDelta / 1000)
            )
          : 0;

        const rateOverDistance = emission.rateOverDistance
          ? calculateValue(
              generalData.particleSystemId,
              emission.rateOverDistance,
              generalData.normalizedLifetimePercentage
            )
          : 0;
        const neededParticlesByDistance =
          rateOverDistance > 0 && generalData.distanceFromLastEmitByDistance > 0
            ? Math.floor(
                generalData.distanceFromLastEmitByDistance /
                  (1 / rateOverDistance!)
              )
            : 0;
        const distanceStep =
          neededParticlesByDistance > 0
            ? {
                x:
                  (currentWorldPosition.x - lastWorldPositionSnapshot.x) /
                  neededParticlesByDistance,
                y:
                  (currentWorldPosition.y - lastWorldPositionSnapshot.y) /
                  neededParticlesByDistance,
                z:
                  (currentWorldPosition.z - lastWorldPositionSnapshot.z) /
                  neededParticlesByDistance,
              }
            : null;
        const neededParticles = neededParticlesByTime + neededParticlesByDistance;

        if (rateOverDistance > 0 && neededParticlesByDistance >= 1) {
          generalData.distanceFromLastEmitByDistance = 0;
        }

        if (neededParticles > 0) {
          let generatedParticlesByDistanceNeeds = 0;
          for (let i = 0; i < neededParticles; i++) {
            let particleIndex = -1;
            particleSystem.geometry.attributes.isActive.array.find(
              (isActive, index) => {
                if (!isActive) {
                  particleIndex = index;
                  return true;
                }
                return false;
              }
            );

            if (
              particleIndex !== -1 &&
              particleIndex <
                particleSystem.geometry.attributes.isActive.array.length
            ) {
              let position: Required<Point3D> = { x: 0, y: 0, z: 0 };
              if (
                distanceStep &&
                generatedParticlesByDistanceNeeds < neededParticlesByDistance
              ) {
                position = {
                  x: distanceStep.x * generatedParticlesByDistanceNeeds,
                  y: distanceStep.y * generatedParticlesByDistanceNeeds,
                  z: distanceStep.z * generatedParticlesByDistanceNeeds,
                };
                generatedParticlesByDistanceNeeds++;
              }
              activateParticle({
                particleIndex,
                activationTime: now,
                position,
              });
              props.lastEmissionTime = now;
            }
          }
        }

        if (onUpdate)
          onUpdate({
            particleSystem,
            delta,
            elapsed,
            lifetime,
            normalizedLifetime,
            iterationCount: iterationCount + 1,
          });
      } else if (onComplete)
        onComplete({
          particleSystem,
        });
    });
  };
}