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

  ParticleSystemConfig get getDefaultParticleSystemConfig => DEFAULT_PARTICLE_SYSTEM_CONFIG;

  final ParticleSystemConfig DEFAULT_PARTICLE_SYSTEM_CONFIG = ParticleSystemConfig(
    transform: Transform(
      position: three.Vector3(),
      rotation: three.Vector3(),
      scale: three.Vector3(1, 1, 1),
    ),
    duration: 5.0,
    looping: true,
    startDelay: 0,
    startLifetime: 5.0,
    startSpeed: 1.0,
    startSize: 1.0,
    startOpacity: 1.0,
    startRotation: 0.0,
    startColor: MinMaxColor(
      min: Rgb(r: 1.0, g: 1.0, b: 1.0 ),
      max: Rgb(r: 1.0, g: 1.0, b: 1.0 ),
    ),
    gravity: 0.0,
    simulationSpace: SimulationSpace.local,
    maxParticles: 100,
    emission: Emission(
      rateOverTime: 10.0,
      rateOverDistance: 0.0,
    ),
    shape: ShapeConfig(
      shape: Shape.sphere,
      sphere: Sphere(
        radius: 1.0,
        radiusThickness: 1.0,
        arc: 360.0,
      ),
      cone: Cone(
        angle: 25.0,
        radius: 1.0,
        radiusThickness: 1.0,
        arc: 360.0,
      ),
      circle: Circle(
        radius: 1.0,
        radiusThickness: 1.0,
        arc: 360.0,
      ),
      rectangle: Rectangle(
        rotation: Point3D(x: 0.0, y: 0.0 ), // TODO: add z rotation
        scale: Point3D(x: 1.0, y: 1.0 ),
      ),
      box: Box(
        scale: Point3D( x: 1.0, y: 1.0, z: 1.0 ),
        emitFrom: EmitFrom.volume,
      ),
    ),
    renderer: Renderer(
      blending: three.NormalBlending,
      discardBackgroundColor: false,
      backgroundColorTolerance: 1.0,
      backgroundColor: Rgb(r: 1.0, g: 1.0, b: 1.0 ),
      transparent: true,
      depthTest: true,
      depthWrite: false,
    ),
    velocityOverLifetime: VelocityOverLifetime(
      isActive: false,
      linear: VOLVector3(
        x: 0,
        y: 0,
        z: 0,
      ),
      orbital: VOLVector3(
        x: 0,
        y: 0,
        z: 0,
      ),
    ),
    sizeOverLifetime: OverLifetime(
      isActive: false,
      lifetimeCurve: BezierCurve(
        scale: 1,
        bezierPoints: [
          BezierPoint( x: 0, y: 0, percentage: 0 ),
          BezierPoint( x: 1, y: 1, percentage: 1 ),
        ],
      ),
    ),
    /* colorOverLifetime: {
      isActive: false,
      lifetimeCurve: {
        type: LifeTimeCurve.EASING,
        scale: 1,
        curveFunction: CurveFunctionId.LINEAR,
      },
    }, */
    opacityOverLifetime: OverLifetime(
      isActive: false,
      lifetimeCurve: BezierCurve(
        scale: 1,
        bezierPoints: [
          BezierPoint( x: 0, y: 0, percentage: 0 ),
          BezierPoint( x: 1, y: 1, percentage: 1 ),
        ],
      ),
    ),
    rotationOverLifetime: OverLifetime(
      isActive: false,
      min: 0.0,
      max: 0.0,
    ),
    noise: NoiseConfig(
      isActive: false,
      useRandomOffset: false,
      strength: 1.0,
      frequency: 0.5,
      octaves: 1,
      positionAmount: 1.0,
      rotationAmount: 0.0,
      sizeAmount: 0.0,
    ),
    textureSheetAnimation: TextureSheetAnimation(
      tiles: three.Vector2(1.0, 1.0),
      timeMode: TimeMode.lifetime,
      fps: 30.0,
      startFrame: 0,
    ),
  );

  void createFloat32Attributes({
    required three.BufferGeometry geometry,
    required String propertyName,
    required int maxParticles,
    List<double>? factory,
  }){
    geometry.setAttributeFromString(
      propertyName,
      three.Float32BufferAttribute(
        factory != null?three.Float32Array.fromList(factory):three.Float32Array(maxParticles),
        1
      )
    );
  }

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
    createdParticleSystems = createdParticleSystems.where(
      (ps){
        three.Points? savedParticleSystem = ps.particleSystem;
        var wrapper = ps.wrapper;
        int particleSystemId = ps.generalData?.particleSystemId ?? 0;
      
        if (
          savedParticleSystem != particleSystem &&
          wrapper != particleSystem
        ) {
          return true;
        }

        Bezier.removeBezierCurveFunction(particleSystemId);
        savedParticleSystem?.geometry?.dispose();
        if (savedParticleSystem?.material is three.GroupMaterial){
          (savedParticleSystem?.material as three.GroupMaterial).children.forEach((material) => material.dispose());
        }
        else{
          savedParticleSystem?.material?.dispose();
        }

        if (savedParticleSystem?.parent != null){
          savedParticleSystem?.parent?.remove(savedParticleSystem);
        }
        return false;
      }
    ).toList();

    return false;
  }

  ParticleSystem createParticleSystem([
    ParticleSystemConfig? config,
    double? externalNow
  ]){
    config ??= DEFAULT_PARTICLE_SYSTEM_CONFIG;
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

    final normalizedConfig = ObjectUtils.deepMerge(
      DEFAULT_PARTICLE_SYSTEM_CONFIG as NormalizedParticleSystemConfig,
      config,
      { applyToFirstObject: false, skippedProperties: [] }
    ) as NormalizedParticleSystemConfig;

    three.Texture? particleMap = normalizedConfig.map ?? Utils.createDefaultParticleTexture();

    final transform = normalizedConfig.transform;
    final duration = normalizedConfig.duration;
    final looping = normalizedConfig.looping;
    final startDelay = normalizedConfig.startDelay;
    final startLifetime = normalizedConfig.startLifetime;
    final startSpeed = normalizedConfig.startSpeed;
    final startSize = normalizedConfig.startSize;
    final startRotation = normalizedConfig.startRotation;
    final startColor = normalizedConfig.startColor;
    final startOpacity = normalizedConfig.startOpacity;
    final gravity = normalizedConfig.gravity;
    final simulationSpace = normalizedConfig.simulationSpace;
    final maxParticles = normalizedConfig.maxParticles ?? 0;
    final emission = normalizedConfig.emission;
    final shape = normalizedConfig.shape;
    final renderer = normalizedConfig.renderer;
    final noise = normalizedConfig.noise!;
    final velocityOverLifetime = normalizedConfig.velocityOverLifetime;
    final onUpdate = normalizedConfig.onUpdate;
    final onComplete = normalizedConfig.onComplete;
    final textureSheetAnimation = normalizedConfig.textureSheetAnimation;

    final startPositions = List.filled(maxParticles,new three.Vector3());
    final velocities = List.filled(maxParticles,new three.Vector3());
    generalData.creationTimes = List.filled(maxParticles,0);

    if (velocityOverLifetime?.isActive == true) {
      generalData.linearVelocityData = List.generate(maxParticles,
        (i) => VelocityData(
          speed: three.Vector3(
            velocityOverLifetime?.linear.x != null
              ? Utils.calculateValue(
                  generalData.particleSystemId,
                  velocityOverLifetime!.linear.x,
                  0
                )
              : 0,
            velocityOverLifetime?.linear.y != null
              ? Utils.calculateValue(
                  generalData.particleSystemId,
                  velocityOverLifetime!.linear.y,
                  0
                )
              : 0,
            velocityOverLifetime?.linear.z != null
              ? Utils.calculateValue(
                  generalData.particleSystemId,
                  velocityOverLifetime!.linear.z,
                  0
                )
              : 0
          ),
          valueModifiers: VOLCurveFunction(
            x: Utils.isLifeTimeCurve(velocityOverLifetime?.linear.x ?? 0)
              ? Utils.getCurveFunctionFromConfig(
                  generalData.particleSystemId,
                  velocityOverLifetime?.linear.x as LifetimeCurve
                )
              : null,
            y: Utils.isLifeTimeCurve(velocityOverLifetime?.linear.y ?? 0)
              ? Utils.getCurveFunctionFromConfig(
                  generalData.particleSystemId,
                  velocityOverLifetime?.linear.y as LifetimeCurve
                )
              : null,
            z: Utils.isLifeTimeCurve(velocityOverLifetime?.linear.z ?? 0)
              ? Utils.getCurveFunctionFromConfig(
                  generalData.particleSystemId,
                  velocityOverLifetime?.linear.z as LifetimeCurve
                )
              : null,
          ),
        )
      );

      generalData.orbitalVelocityData = List.generate(maxParticles,
        (i) => VelocityData(
          speed: three.Vector3(
            velocityOverLifetime?.orbital.x != null
              ? Utils.calculateValue(
                  generalData.particleSystemId,
                  velocityOverLifetime!.orbital.x,
                  0
                )
              : 0,
            velocityOverLifetime?.orbital.y != null
              ? Utils.calculateValue(
                  generalData.particleSystemId,
                  velocityOverLifetime!.orbital.y,
                  0
                )
              : 0,
            velocityOverLifetime?.orbital.z != null
              ? Utils.calculateValue(
                  generalData.particleSystemId,
                  velocityOverLifetime!.orbital.z,
                  0
                )
              : 0
          ),
          valueModifiers: VOLCurveFunction(
            x: Utils.isLifeTimeCurve(velocityOverLifetime?.orbital.x ?? 0)
              ? Utils.getCurveFunctionFromConfig(
                  generalData.particleSystemId,
                  velocityOverLifetime?.orbital.x as LifetimeCurve
                )
              : null,
            y: Utils.isLifeTimeCurve(velocityOverLifetime?.orbital.y ?? 0)
              ? Utils.getCurveFunctionFromConfig(
                  generalData.particleSystemId,
                  velocityOverLifetime?.orbital.y as LifetimeCurve
                )
              : null,
            z: Utils.isLifeTimeCurve(velocityOverLifetime?.orbital.z ?? 0)
              ? Utils.getCurveFunctionFromConfig(
                  generalData.particleSystemId,
                  velocityOverLifetime?.orbital.z as LifetimeCurve
                )
              : null,
          ),
          positionOffset: three.Vector3(),
        )
      );
    }

    final List<String> startValueKeys = [
      'startSize',
      'startOpacity',
    ];

    startValueKeys.forEach((key){
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

    final List<String> lifetimeValueKeys = [
      'rotationOverLifetime',
    ];
    lifetimeValueKeys.forEach((key){
      final value = normalizedConfig[key] as {
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
            seed: math.Random().nextDouble(),
            scale: noise.frequency,
            octaves: noise.octaves,
          })
        : null,
      offsets: noise.useRandomOffset
        ? List.generate(maxParticles, (i) => math.Random().nextDouble() * 100)// Array.from({ length: maxParticles }, () => Math.random() * 100)
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
          'value': textureSheetAnimation?.tiles,
        },
        'fps': {
          'value': textureSheetAnimation?.fps,
        },
        'useFPSForFrameIndex': {
          'value': textureSheetAnimation?.timeMode == TimeMode.fps,
        },
        'backgroundColor': {
          'value': renderer?.backgroundColor,
        },
        'discardBackgroundColor': {
          'value': renderer?.discardBackgroundColor,
        },
        'backgroundColorTolerance': {
          'value': renderer?.backgroundColorTolerance,
        },
      },
      'vertexShader': ParticleSystemVertexShader,
      'fragmentShader': ParticleSystemFragmentShader,
      'transparent': renderer?.transparent,
      'blending': renderer?.blending,
      'depthTest': renderer?.depthTest,
      'depthWrite': renderer?.depthWrite,
  });

    final geometry = three.BufferGeometry();

    for (int i = 0; i < maxParticles; i++)
      calculatePositionAndVelocity(
        generalData,
        shape!,
        startSpeed,
        startPositions[i],
        velocities[i]
      );

    geometry.setFromPoints( List.generate(maxParticles, (i) => startPositions[i].clone()));

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
      () => Utils.calculateValue(generalData.particleSystemId, startLifetime, 0) * 1000
    );

    createFloat32AttributesRequest('startFrame', () =>
      textureSheetAnimation?.startFrame != null
        ? Utils.calculateValue(
            generalData.particleSystemId,
            textureSheetAnimation!.startFrame,
            0
          )
        : 0
    );

    createFloat32AttributesRequest('opacity', () =>
      Utils.calculateValue(generalData.particleSystemId, startOpacity, 0)
    );

    createFloat32AttributesRequest('rotation', () =>
      Utils.calculateValue(generalData.particleSystemId, startRotation, 0)
    );

    createFloat32AttributesRequest(
      'size',
      (_, index) => generalData.startValues?['startSize']?[index]
    );

    createFloat32AttributesRequest('rotation', 0);

    final colorRandomRatio = math.Random().nextDouble();
    createFloat32AttributesRequest(
      'colorR',
      () =>
        startColor!.min!.r! +
        colorRandomRatio * (startColor.max!.r! - startColor.min!.r!)
    );
    createFloat32AttributesRequest(
      'colorG',
      () =>
        startColor!.min!.g! +
        colorRandomRatio * (startColor.max!.g! - startColor.min!.g!)
    );
    createFloat32AttributesRequest(
      'colorB',
      () =>
        startColor!.min!.b! +
        colorRandomRatio * (startColor.max!.b! - startColor.min!.b!)
    );
    createFloat32AttributesRequest('colorA', 0);

    final deactivateParticle = (int particleIndex){
      geometry.attributes['isActive'].array[particleIndex] = 0;
      geometry.attributes['colorA'].array[particleIndex] = 0;
      geometry.attributes['colorA'].needsUpdate = true;
    };

    activateParticle({
      required int particleIndex,
      required double activationTime,
      required Point3D position,
    }){
      geometry.attributes['isActive'].array[particleIndex] = 1;
      generalData.creationTimes?[particleIndex] = activationTime;

      if (generalData.noise?.offsets != null){
        generalData.noise!.offsets![particleIndex] = math.Random().nextDouble() * 100;
      }

      final colorRandomRatio = math.Random().nextDouble();

      geometry.attributes['colorR'].array[particleIndex] =
        startColor!.min!.r! +
        colorRandomRatio * (startColor.max!.r! - startColor.min!.r!);
      geometry.attributes['colorR'].needsUpdate = true;

      geometry.attributes['colorG'].array[particleIndex] =
        startColor.min!.g! +
        colorRandomRatio * (startColor.max!.g! - startColor.min!.g!);
      geometry.attributes['colorG'].needsUpdate = true;

      geometry.attributes['colorB'].array[particleIndex] =
        startColor.min!.b! +
        colorRandomRatio * (startColor.max!.b! - startColor.min!.b!);
      geometry.attributes['colorB'].needsUpdate = true;

      geometry.attributes['startFrame'].array[particleIndex] =
        textureSheetAnimation?.startFrame != null
          ? Utils.calculateValue(
              generalData.particleSystemId,
              textureSheetAnimation!.startFrame,
              0
            )
          : 0;
      geometry.attributes['startFrame'].needsUpdate = true;

      geometry.attributes['startLifetime'].array[particleIndex] =
        Utils.calculateValue(
          generalData.particleSystemId,
          startLifetime,
          generalData.normalizedLifetimePercentage
        ) * 1000;
      geometry.attributes['startLifetime'].needsUpdate = true;

      generalData.startValues?['startSize']?[particleIndex] = Utils.calculateValue(
        generalData.particleSystemId,
        startSize,
        generalData.normalizedLifetimePercentage
      );
      geometry.attributes['size'].array[particleIndex] =
        generalData.startValues?['startSize']?[particleIndex];
      geometry.attributes['size'].needsUpdate = true;

      generalData.startValues?['startOpacity']?[particleIndex] = Utils.calculateValue(
        generalData.particleSystemId,
        startOpacity,
        generalData.normalizedLifetimePercentage
      );
      geometry.attributes['colorA'].array[particleIndex] =
        generalData.startValues?['startOpacity']?[particleIndex];
      geometry.attributes['colorA'].needsUpdate = true;

      geometry.attributes['rotation'].array[particleIndex] = Utils.calculateValue(
        generalData.particleSystemId,
        startRotation,
        generalData.normalizedLifetimePercentage
      );
      geometry.attributes['rotation'].needsUpdate = true;

      if (normalizedConfig.rotationOverLifetime?.isActive == true)
        generalData.lifetimeValues.rotationOverLifetime[particleIndex] =
          three.MathUtils.randFloat(
            normalizedConfig.rotationOverLifetime.min!,
            normalizedConfig.rotationOverLifetime.max!
          );

      calculatePositionAndVelocity(
        generalData,
        shape!,
        startSpeed,
        startPositions[particleIndex],
        velocities[particleIndex]
      );
      final positionIndex = (particleIndex * 3).floor();
      geometry.attributes['position'].array[positionIndex] =
        position.x + startPositions[particleIndex].x;
      geometry.attributes['position'].array[positionIndex + 1] =
        position.y + startPositions[particleIndex].y;
      geometry.attributes['position'].array[positionIndex + 2] =
        position.z + startPositions[particleIndex].z;
      geometry.attributes['position'].needsUpdate = true;

      if (generalData.linearVelocityData != null) {
        generalData.linearVelocityData![particleIndex].speed?.setValues(
          normalizedConfig.velocityOverLifetime?.linear.x != null
            ? Utils.calculateValue(
                generalData.particleSystemId,
                normalizedConfig.velocityOverLifetime!.linear.x,
                0
              )
            : 0,
          normalizedConfig.velocityOverLifetime?.linear.y != null
            ? Utils.calculateValue(
                generalData.particleSystemId,
                normalizedConfig.velocityOverLifetime!.linear.y,
                0
              )
            : 0,
          normalizedConfig.velocityOverLifetime?.linear.z != null
            ? Utils.calculateValue(
                generalData.particleSystemId,
                normalizedConfig.velocityOverLifetime!.linear.z,
                0
              )
            : 0
        );
      }

      if (generalData.orbitalVelocityData != null) {
        generalData.orbitalVelocityData![particleIndex].speed?.setValues(
          normalizedConfig.velocityOverLifetime?.orbital.x != null
            ? Utils.calculateValue(
                generalData.particleSystemId,
                normalizedConfig.velocityOverLifetime!.orbital.x,
                0
              )
            : 0,
          normalizedConfig.velocityOverLifetime?.orbital.y != null
            ? Utils.calculateValue(
                generalData.particleSystemId,
                normalizedConfig.velocityOverLifetime!.orbital.y,
                0
              )
            : 0,
          normalizedConfig.velocityOverLifetime?.orbital.z != null
            ? Utils.calculateValue(
                generalData.particleSystemId,
                normalizedConfig.velocityOverLifetime!.orbital.z,
                0
              )
            : 0
        );
        generalData.orbitalVelocityData?[particleIndex].positionOffset?.setValues(
          startPositions[particleIndex].x,
          startPositions[particleIndex].y,
          startPositions[particleIndex].z
        );
      }

      geometry.attributes['lifetime'].array[particleIndex] = 0;
      geometry.attributes['lifetime'].needsUpdate = true;

      Modifiers.applyModifiers(
        delta: 0,
        generalData: generalData,
        normalizedConfig: normalizedConfig,
        attributes: particleSystem.geometry!.attributes,
        particleLifetimePercentage: 0,
        particleIndex: particleIndex,
      );
    };

    three.Points particleSystem = three.Points(geometry, material);

    particleSystem.position.setFrom(transform!.position!);
    particleSystem.rotation.x = three.MathUtils.degToRad(transform.rotation!.x);
    particleSystem.rotation.y = three.MathUtils.degToRad(transform.rotation!.y);
    particleSystem.rotation.z = three.MathUtils.degToRad(transform.rotation!.z);
    particleSystem.scale.setFrom(transform.scale!);

    final calculatedCreationTime =
      now + Utils.calculateValue(generalData.particleSystemId, startDelay) * 1000;

    Gyroscope? wrapper;
    if (normalizedConfig.simulationSpace == SimulationSpace.world) {
      wrapper = new Gyroscope();
      wrapper.add(particleSystem);
    }

    createdParticleSystems.add(ParticleSystemInstance(
      particleSystem: particleSystem,
      wrapper: wrapper,
      generalData: generalData,
      onUpdate: onUpdate,
      onComplete: onComplete,
      creationTime: calculatedCreationTime,
      lastEmissionTime: calculatedCreationTime,
      duration:duration,
      looping: looping ?? false,
      simulationSpace:simulationSpace,
      gravity: gravity ?? 0,
      emission:emission,
      normalizedConfig:normalizedConfig,
      iterationCount: 0,
      velocities:velocities,
      deactivateParticle: deactivateParticle,
      activateParticle: activateParticle,
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
  }

  void updateParticleSystems({ now, delta, elapsed }){
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

      if (wrapper?.parent != null){
        generalData.wrapperQuaternion?.setFrom(wrapper.parent.quaternion);
      }

      final lastWorldPositionSnapshot = { ...lastWorldPosition };

      if (particleSystem?.material is three.GroupMaterial){
        (particleSystem!.material as three.GroupMaterial).children.forEach((material){
          if (material is three.ShaderMaterial){
            material.uniforms['elapsed']['value'] = elapsed;
          }
        });
      }
      else {
        if (particleSystem?.material is three.ShaderMaterial){
          particleSystem!.material?.uniforms['elapsed']['value'] = elapsed;
        }
      }

      particleSystem?.getWorldPosition(currentWorldPosition);
      if (lastWorldPosition?.x != -99999) {
        worldPositionChange?.setValues(
          currentWorldPosition!.x - lastWorldPosition!.x,
          currentWorldPosition.y - lastWorldPosition.y,
          currentWorldPosition.z - lastWorldPosition.z
        );
      }
      generalData.distanceFromLastEmitByDistance += worldPositionChange!.length;
      particleSystem?.getWorldPosition(lastWorldPosition);
      particleSystem?.getWorldQuaternion(worldQuaternion!);
      if (
        lastWorldQuaternion?.x == -99999 ||
        lastWorldQuaternion?.x != worldQuaternion?.x ||
        lastWorldQuaternion?.y != worldQuaternion?.y ||
        lastWorldQuaternion?.z != worldQuaternion?.z
      ) {
        worldEuler?.setFromQuaternion(worldQuaternion!);
        lastWorldQuaternion?.setFrom(worldQuaternion!);
        gravityVelocity?.setValues(
          lastWorldPosition!.x,
          lastWorldPosition.y + gravity,
          lastWorldPosition.z
        );
        particleSystem?.worldToLocal(gravityVelocity!);
      }

      int index = 0;
      generalData.creationTimes?.forEach((entry){
        if (particleSystem?.geometry?.attributes['isActive'].array[index] != null) {
          final particleLifetime = now - entry;
          if (
            particleLifetime >
            (particleSystem?.geometry?.attributes['startLifetime'].array[index] ?? 0)
          ){
            deactivateParticle?.call(index);
          }
          else {
            final velocity = velocities![index];
            velocity.x -= gravityVelocity!.x * delta;
            velocity.y -= gravityVelocity.y * delta;
            velocity.z -= gravityVelocity.z * delta;

            if (
              gravity != 0 ||
              velocity.x != 0 ||
              velocity.y != 0 ||
              velocity.z != 0 ||
              worldPositionChange.x != 0 ||
              worldPositionChange.y != 0 ||
              worldPositionChange.z != 0
            ) {
              final positionIndex = index * 3;
              final positionArr = particleSystem!.geometry!.attributes['position'].array;

              if (simulationSpace == SimulationSpace.world) {
                positionArr[positionIndex] -= worldPositionChange.x;
                positionArr[positionIndex + 1] -= worldPositionChange.y;
                positionArr[positionIndex + 2] -= worldPositionChange.z;
              }

              positionArr[positionIndex] += velocity.x * delta;
              positionArr[positionIndex + 1] += velocity.y * delta;
              positionArr[positionIndex + 2] += velocity.z * delta;
              particleSystem!.geometry!.attributes['position'].needsUpdate = true;
            }

            particleSystem!.geometry!.attributes['lifetime'].array[index] = particleLifetime;
            particleSystem.geometry!.attributes['lifetime'].needsUpdate = true;

            final particleLifetimePercentage =
              particleLifetime /
              particleSystem.geometry!.attributes['startLifetime'].array[index];
              
            Modifiers.applyModifiers(
              delta: delta,
              generalData: generalData,
              normalizedConfig: normalizedConfig!,
              attributes: particleSystem!.geometry!.attributes,
              particleLifetimePercentage: particleLifetimePercentage,
              particleIndex: index,
            );
          }
        }
        index++;
      });

      if (isEnabled && (looping || lifetime < duration * 1000)) {
        final emissionDelta = now - lastEmissionTime;
        final neededParticlesByTime = emission?.rateOverTime != null
          ? (
              Utils.calculateValue(
                generalData.particleSystemId,
                emission!.rateOverTime,
                generalData.normalizedLifetimePercentage
              ) *
                (emissionDelta / 1000)
            ).floor()
          : 0;

        final rateOverDistance = emission?.rateOverDistance != null
          ? Utils.calculateValue(
              generalData.particleSystemId,
              emission!.rateOverDistance,
              generalData.normalizedLifetimePercentage
            )
          : 0;
        final neededParticlesByDistance =
          rateOverDistance > 0 && generalData.distanceFromLastEmitByDistance > 0
            ? (
                generalData.distanceFromLastEmitByDistance /
                  (1 / rateOverDistance)
              ).floor()
            : 0;
        final distanceStep =
          neededParticlesByDistance > 0
            ? Point3D(
                x:
                  (currentWorldPosition!.x - lastWorldPositionSnapshot.x) /
                  neededParticlesByDistance,
                y:
                  (currentWorldPosition.y - lastWorldPositionSnapshot.y) /
                  neededParticlesByDistance,
                z:
                  (currentWorldPosition.z - lastWorldPositionSnapshot.z) /
                  neededParticlesByDistance,
            )
            : null;
        final neededParticles = neededParticlesByTime + neededParticlesByDistance;

        if (rateOverDistance > 0 && neededParticlesByDistance >= 1) {
          generalData.distanceFromLastEmitByDistance = 0;
        }

        if (neededParticles > 0) {
          int generatedParticlesByDistanceNeeds = 0;
          for (int i = 0; i < neededParticles; i++) {
            int particleIndex = -1;
            particleSystem?.geometry?.attributes['isActive'].array,.find(
              (isActive, index){
                if (!isActive) {
                  particleIndex = index;
                  return true;
                }
                return false;
              }
            );

            if (
              particleIndex != -1 &&
              particleIndex <
                (particleSystem?.geometry?.attributes['isActive'].array.length ?? 0)
            ) {
              Point3D position = Point3D();
              if (
                distanceStep != null &&
                generatedParticlesByDistanceNeeds < neededParticlesByDistance
              ) {
                position = Point3D(
                  x: distanceStep.x * generatedParticlesByDistanceNeeds,
                  y: distanceStep.y * generatedParticlesByDistanceNeeds,
                  z: distanceStep.z * generatedParticlesByDistanceNeeds,
                );
                generatedParticlesByDistanceNeeds++;
              }
              activateParticle?.call(
                particleIndex: particleIndex,
                activationTime: now,
                position: position,
              );
              props.lastEmissionTime = now;
            }
          }
        }

        if (onUpdate != null)
          onUpdate(
            particleSystem: particleSystem,
            delta: delta,
            elapsed: elapsed,
            lifetime: lifetime,
            normalizedLifetime: normalizedLifetime,
            iterationCount: iterationCount + 1,
          );
      } else if (onComplete!= null)
        onComplete(
          particleSystem: particleSystem,
        );
    });
  }
}