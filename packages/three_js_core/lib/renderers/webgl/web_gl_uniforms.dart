/*
 * Uniforms of a program.
 * Those form a tree structure with a special top-level container for the root,
 * which you get by calling 'new WebGLUniforms( gl, program )'.
 *
 *
 * Properties of inner nodes including the top-level container:
 *
 * .seq - array of nested uniforms
 * .map - nested uniforms by name
 *
 *
 * Methods of all nodes except the top-level container:
 *
 * .setValue( gl, value, [textures] )
 *
 * 		uploads a uniform value(s)
 *  	the 'textures' parameter is needed for sampler uniforms
 *
 *
 * Static methods of the top-level container (textures factorizations):
 *
 * .upload( gl, seq, values, textures )
 *
 * 		sets uniforms in 'seq' to 'values[id].value'
 *
 * .seqWithValue( seq, values ) : filteredSeq
 *
 * 		filters 'seq' entries with corresponding entry in values
 *
 *
 * Methods of the top-level container (textures factorizations):
 *
 * .setValue( gl, name, value, textures )
 *
 * 		sets uniform with  name 'name' to 'value'
 *
 * .setOptional( gl, obj, prop )
 *
 * 		like .set for an optional property of the object
 *
 */

// Root Container

part of three_webgl;

class WebGLUniforms with WebGLUniform {
  dynamic gl;
  WebGLProgram program;

  WebGLUniforms(this.gl, this.program) {
    seq = [];
    map = {};

    final n = gl.getProgramParameter(program.program, gl.ACTIVE_UNIFORMS);

    for (int i = 0; i < n; ++i) {
      final info = gl.getActiveUniform(program.program, i);
      final addr = gl.getUniformLocation(program.program, info.name);
      parseUniform(info, addr, this);
    }
  }

  void setValue(gl, name, value, [WebGLTextures? textures]) {
    final u = map[name];
    if (u != null) u.setValue(gl, value, textures);
  }

  void setOptional(gl, object, name) {
    final v = object.getValue(name);
    if (v != null) setValue(gl, name, v);
  }

  static void upload(gl, List seq, Map<String, dynamic> values, textures) {
    for (int i = 0, n = seq.length; i != n; ++i) {
      final u = seq[i];
      final v = values[u.id];

      // final value = v["value"];
      // final _vt = value.runtimeType.toString();
      // print("WebGLUniforms.upload ${_vt} name: ${u.id}  value: ${value} ");
      // if(_vt == "Matrix4" || _vt == "Matrix3" || _vt == "Color" || _vt == "Vector2" || _vt == "Vector3") {
      //   print(value.toJson());
      // } else if(_vt == "List<Vector3>") {
      //   print(value.map((e) => e.toJson()));
      // } else if( u.id == "lightProbe" ) {
      //   print(value.map((e) => e.toJson() ) );
      // } else if( u.id == "directionalLights" ) {
      //   print(value.map((e) => e["color"].toJson() ) );
      //   print(value.map((e) => e["direction"].toJson() ) );
      // } else if(u.id == "spotLights") {
      //   print("spotLights... ");
      //   print(value.map((e) => e["position"].toJson() ) );
      //   print(value.map((e) => e["direction"].toJson() ) );
      //   print(value.map((e) => e["color"].toJson() ) );
      // } else if(u.id == "spotShadowMatrix" || u.id == "directionalShadowMatrix") {
      //   print(value.map((e) => e.toJson()));
      // } else {
      //   print(value);
      // }

      if (v["needsUpdate"] != false) {
        // note: always updating when .needsUpdate is null
        u.setValue(gl, v["value"], textures);
      }
    }
  }

  static List<dynamic> seqWithValue(List seq, Map<String, dynamic> values) {
    List<dynamic> r = [];

    for (int i = 0, n = seq.length; i != n; ++i) {
      final u = seq[i];

      // print("seqWithValue  u.id: ${u.id} ");

      if (values.keys.contains(u.id)) {
        r.add(u);
      } else {
        // print("seqWithValue  u.id: ${u.id} is not add ");
      }
    }

    return r;
  }
}
