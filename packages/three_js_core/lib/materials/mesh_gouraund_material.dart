import "package:three_js_core/three_js_core.dart";

class MeshGouraudMaterial extends ShaderMaterial {
  Map<String,dynamic> gouraudShader;

  MeshGouraudMaterial(this.gouraudShader,[Map<MaterialProperty, dynamic>? parameters]) : super() {
    _init();
    setValues(parameters);
  }
  MeshGouraudMaterial.fromMap(this.gouraudShader,[Map<String, dynamic>? parameters]) : super() {
    _init();
    setValuesFromString(parameters);
  }

	void _init(){
		type = 'MeshGouraudMaterial';
		combine = 0; // combine has no uniform
		fog = false; // set to use scene fog
		lights = true; // set to use scene lights
		clipping = false; // set to use user-defined clipping planes

		final shader = gouraudShader;
    shader['defines'] = {};
    defines = shader['defines'];
		uniforms = UniformsUtils.clone( shader['uniforms'] );
		vertexShader = shader['vertexShader'];
		fragmentShader = shader['fragmentShader'];

		const exposePropertyNames = [
			'map', 'lightMap', 'lightMapIntensity', 'aoMap', 'aoMapIntensity',
			'emissive', 'emissiveIntensity', 'emissiveMap', 'specularMap', 'alphaMap',
			'envMap', 'reflectivity', 'refractionRatio', 'opacity', 'diffuse'
		];

    //map = Texture();

		for (final propertyName in exposePropertyNames ) {
      if(gouraudShader[propertyName] != null){
        gouraudShader[propertyName]['get'] = () {
          return uniforms[ propertyName ]['value'];
        };
        gouraudShader[propertyName]['set'] = ( value ) {
          uniforms[ propertyName ]['value'] = value;
        };
      }
      else{
        gouraudShader[propertyName] = {
          'get': () {
            return uniforms[ propertyName ]['value'];
          },
          'set': ( value ) {
            uniforms[ propertyName ]['value'] = value;
          }
        };
      }
		}

		//color = diffuse;
	}

  @override
	MeshGouraudMaterial copy(Material source ) {
		super.copy( source );
		color.setFrom( source.color );

		map = source.map;

		lightMap = source.lightMap;
		lightMapIntensity = source.lightMapIntensity;

		aoMap = source.aoMap;
		aoMapIntensity = source.aoMapIntensity;

		emissive?.setFrom( source.emissive! );
		emissiveMap = source.emissiveMap;
		emissiveIntensity = source.emissiveIntensity;

		specularMap = source.specularMap;

		alphaMap = source.alphaMap;

		envMap = source.envMap;
		combine = source.combine;
		reflectivity = source.reflectivity;
		refractionRatio = source.refractionRatio;

		wireframe = source.wireframe;
		wireframeLinewidth = source.wireframeLinewidth;
		wireframeLinecap = source.wireframeLinecap;
		wireframeLinejoin = source.wireframeLinejoin;

		fog = source.fog;

		return this;
	}

  /// Return a new material with the same parameters as this material.
  @override
  MeshGouraudMaterial clone() {
    return MeshGouraudMaterial(gouraudShader)..copy(this);
  }
}