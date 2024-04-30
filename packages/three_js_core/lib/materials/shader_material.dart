import 'dart:convert';
import 'package:three_js_core/others/index.dart';
import '../renderers/shaders/index.dart';
import '../renderers/shaders/shader_chunk/default_fragment.glsl.dart';
import '../renderers/shaders/shader_chunk/default_vertex.glsl.dart';
import './material.dart';

class ShaderMaterial extends Material {
  ShaderMaterial([Map<MaterialProperty, dynamic>? parameters]) : super() {
    _init();
    if (parameters != null) {
      if (parameters[MaterialProperty.attributes] != null) {
        console.warning('ShaderMaterial: attributes should now be defined in BufferGeometry instead.');
      }

      setValues(parameters);
    }
  }
  ShaderMaterial.fromMap([Map<String, dynamic>? parameters]) : super() {
    _init();
    if (parameters != null) {
      if (parameters['attributes'] != null) {
        console.warning('ShaderMaterial: attributes should now be defined in BufferGeometry instead.');
      }

      setValuesFromString(parameters);
    }
  }

  void _init(){
    type = 'ShaderMaterial';
    defines = {};
    uniforms = {};

    vertexShader = defaultVertex;
    fragmentShader = defaultFragment;

    linewidth = 1;

    wireframe = false;
    wireframeLinewidth = 1;

    fog = false; // set to use scene fog
    lights = false; // set to use scene lights
    clipping = false; // set to use user-defined clipping planes

    extensions = {
      "derivatives": false, // set to use derivatives
      "fragDepth": false, // set to use fragment depth values
      "drawBuffers": false, // set to use draw buffers
      "shaderTextureLOD": false // set to use shader texture LOD
    };

    // When rendered geometry doesn't include these attributes but the material does,
    // use these default values in WebGL. This avoids errors when buffer data is missing.
    defaultAttributeValues = {
      'color': [1, 1, 1],
      'uv': [0, 0],
      'uv2': [0, 0]
    };

    index0AttributeName = null;
    uniformsNeedUpdate = false;

    glslVersion = null;

  }

  @override
  ShaderMaterial copy(Material source) {
    super.copy(source);

    fragmentShader = source.fragmentShader;
    vertexShader = source.vertexShader;

    uniforms = cloneUniforms(source.uniforms);

    defines = json.decode(json.encode(source.defines));

    wireframe = source.wireframe;
    wireframeLinewidth = source.wireframeLinewidth;

    fog = source.fog;

    lights = source.lights;
    clipping = source.clipping;

    extensions = json.decode(json.encode(source.extensions));

    glslVersion = source.glslVersion;

    return this;
  }

  @override
  ShaderMaterial clone() {
    return ShaderMaterial({}).copy(this);
  }

  // toJson( meta ) {

  //   var data = super.toJson( meta );

  //   data.glslVersion = this.glslVersion;
  //   data.uniforms = {};

  //   for ( var name in this.uniforms ) {

  //     var uniform = this.uniforms[ name ];
  //     var value = uniform.value;

  //     if ( value && value.isTexture ) {

  //       data.uniforms[ name ] = {
  //         type: 't',
  //         value: value.toJson( meta ).uuid
  //       };

  //     } else if ( value && value.isColor ) {

  //       data.uniforms[ name ] = {
  //         type: 'c',
  //         value: value.getHex()
  //       };

  //     } else if ( value && value.isVector2 ) {

  //       data.uniforms[ name ] = {
  //         type: 'v2',
  //         value: value.toArray()
  //       };

  //     } else if ( value && value.isVector3 ) {

  //       data.uniforms[ name ] = {
  //         type: 'v3',
  //         value: value.toArray()
  //       };

  //     } else if ( value && value.isVector4 ) {

  //       data.uniforms[ name ] = {
  //         type: 'v4',
  //         value: value.toArray()
  //       };

  //     } else if ( value && value.isMatrix3 ) {

  //       data.uniforms[ name ] = {
  //         type: 'm3',
  //         value: value.toArray()
  //       };

  //     } else if ( value && value.isMatrix4 ) {

  //       data.uniforms[ name ] = {
  //         type: 'm4',
  //         value: value.toArray()
  //       };

  //     } else {

  //       data.uniforms[ name ] = {
  //         value: value
  //       };

  //       // note: the array variants v2v, v3v, v4v, m4v and tv are not supported so far

  //     }

  //   }

  //   if ( Object.keys( this.defines ).length > 0 ) data.defines = this.defines;

  //   data.vertexShader = this.vertexShader;
  //   data.fragmentShader = this.fragmentShader;

  //   var extensions = {};

  //   for ( var key in this.extensions ) {

  //     if ( this.extensions[ key ] === true ) extensions[ key ] = true;

  //   }

  //   if ( Object.keys( extensions ).length > 0 ) data.extensions = extensions;

  //   return data;

  // }

}
