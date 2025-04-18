import './material.dart';
import 'package:three_js_math/three_js_math.dart';

/// A standard physically based material, using Metallic-Roughness
/// workflow.
///
/// Physically based rendering (PBR) has recently become the standard in many
/// 3D applications, such as
/// [Unity](https://blogs.unity3d.com/2014/10/29/physically-based-shading-in-unity-5-a-primer/),
/// [Unreal](https://docs.unrealengine.com/latest/INT/Engine/Rendering/Materials/PhysicallyBased/) and
/// [3D Studio Max](http://area.autodesk.com/blogs/the-3ds-max-blog/what039s-new-for-rendering-in-3ds-max-2017).
///
/// This approach differs from older approaches in that instead of using
/// approximations for the way in which light interacts with a surface, a
/// physically correct model is used. The idea is that, instead of tweaking
/// materials to look good under specific lighting, a material can be created
/// that will react 'correctly' under all lighting scenarios.
///
/// In practice this gives a more accurate and realistic looking result than
/// the [MeshLambertMaterial] or [MeshPhongMaterial], at the cost of
/// being somewhat more computationally expensive. [MeshStandardMaterial] uses per-fragment
/// shading.
///
/// Note that for best results you should always specify an [environment map] 
/// when using this material.
///
/// For a non-technical introduction to the concept of PBR and how to set up a
/// PBR material, check out these articles by the people at
/// [marmoset](https://www.marmoset.co):
/// 
/// * [Basic Theory of Physically Based Rendering](https://www.marmoset.co/posts/basic-theory-of-physically-based-rendering/)
/// * [Physically Based Rendering and You Can Too](https://www.marmoset.co/posts/physically-based-rendering-and-you-can-too/)
/// 
/// Technical details of the approach used in three.js (and most other PBR
/// systems) can be found is this
/// [ paper from Disney](https://media.disneyanimation.com/uploads/production/publication_asset/48/asset/s2012_pbs_disney_brdf_notes_v3.pdf)
/// (pdf), by Brent Burley.
class MeshStandardMaterial extends Material {

  /// [parameters] - (optional) an object with one or more
  /// properties defining the material's appearance. Any property of the
  /// material (including any property inherited from [Material] and
  /// [MeshStandardMaterial]) can be passed in here.
  /// 
  /// The exception is the property [color], which can be
  /// passed in as a hexadecimal int and is 0xffffff (white) by default.
  /// [Color] is called internally.
  MeshStandardMaterial([Map<MaterialProperty, dynamic>? parameters]) : super() {
    _init();
    setValues(parameters);
  }
  MeshStandardMaterial.fromMap([Map<String, dynamic>? parameters]) : super() {
    _init();
    setValuesFromString(parameters);
  }
  void _init(){
    type = "MeshStandardMaterial";
    roughness = 1.0;
    metalness = 0.0;
    bumpScale = 1.0;
    normalScale = Vector2(1, 1);
    envMapIntensity = 1.0;

    defines = {'STANDARD': ''};

    color = Color.fromHex32(0xffffff); // diffuse
    roughness = 1.0;
    metalness = 0.0;

    map = null;
    envMapRotation = Euler();

    lightMap = null;
    lightMapIntensity = 1.0;

    aoMap = null;
    aoMapIntensity = 1.0;

    emissive = Color.fromHex32(0x000000);
    emissiveIntensity = 1.0;
    emissiveMap = null;

    bumpMap = null;
    bumpScale = 1;

    normalMap = null;
    normalMapType = TangentSpaceNormalMap;
    normalScale = Vector2(1, 1);

    displacementMap = null;
    displacementScale = 1;
    displacementBias = 0;

    roughnessMap = null;

    metalnessMap = null;

    alphaMap = null;

    // this.envMap = null;
    envMapIntensity = 1.0;

    wireframe = false;
    wireframeLinewidth = 1;
    wireframeLinecap = 'round';
    wireframeLinejoin = 'round';

    fog = true;
  }

  @override
  MeshStandardMaterial clone() {
    return MeshStandardMaterial(<MaterialProperty, dynamic>{}).copy(this);
  }

  @override
  MeshStandardMaterial copy(Material source) {
    super.copy(source);

    defines = {'STANDARD': ''};

    color = source.color.clone();
    roughness = source.roughness;
    metalness = source.metalness;

    map = source.map;

    lightMap = source.lightMap;
    lightMapIntensity = source.lightMapIntensity;

    aoMap = source.aoMap;
    aoMapIntensity = source.aoMapIntensity;

    emissive = source.emissive?.clone();
    emissiveMap = source.emissiveMap;
    emissiveIntensity = source.emissiveIntensity;

    bumpMap = source.bumpMap;
    bumpScale = source.bumpScale;

    normalMap = source.normalMap;
    normalMapType = source.normalMapType;
    normalScale = source.normalScale?.clone();

    displacementMap = source.displacementMap;
    displacementScale = source.displacementScale;
    displacementBias = source.displacementBias;

    roughnessMap = source.roughnessMap;

    metalnessMap = source.metalnessMap;

    alphaMap = source.alphaMap;

    envMap = source.envMap;
    envMapRotation?.copy(source.envMapRotation!);
    envMapIntensity = source.envMapIntensity;

    wireframe = source.wireframe;
    wireframeLinewidth = source.wireframeLinewidth;
    wireframeLinecap = source.wireframeLinecap;
    wireframeLinejoin = source.wireframeLinejoin;

    flatShading = source.flatShading;

    fog = source.fog;

    return this;
  }
}
