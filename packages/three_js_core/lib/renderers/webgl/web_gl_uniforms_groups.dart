part of three_webgl;

class WebGLUniformsGroups{
  WebGLState state;
  WebGLCapabilities capabilities;
  WebGLInfo info;
  
	Map buffers = {};
	Map updateList = {};
	List<int> allocatedBindingPoints = [];
  RenderingContext gl;

	late final int maxBindingPoints; // binding points are global whereas block indices are per shader program
  
  WebGLUniformsGroups(this.gl, this.info, this.capabilities, this.state ){
    maxBindingPoints = gl.getParameter( WebGL.MAX_UNIFORM_BUFFER_BINDINGS );
  }

	void bind(UniformsGroup uniformsGroup, WebGLProgram? program ) {
		final webglProgram = program?.program;
		state.uniformBlockBinding( uniformsGroup, webglProgram );
	}

	void update(uniformsGroup, WebGLProgram? program ) {
		dynamic buffer = buffers[uniformsGroup.id];

		if ( buffer == null ) {
			prepareUniformsGroup( uniformsGroup );
			buffer = createBuffer( uniformsGroup );
			buffers[ uniformsGroup.id ] = buffer;
			uniformsGroup.addEventListener( 'dispose', onUniformsGroupsDispose );
		}

		// ensure to update the binding points/block indices mapping for this program

		final webglProgram = program?.program;
		state.updateUBOMapping( uniformsGroup, webglProgram! );

		// update UBO once per frame

		final frame = info.render['frame'];

		if ( updateList[ uniformsGroup.id ] != frame ) {
			updateBufferData( uniformsGroup );
			updateList[ uniformsGroup.id ] = frame;
		}
	}

	Buffer createBuffer(UniformsGroup uniformsGroup ) {
		final bindingPointIndex = allocateBindingPointIndex();
		uniformsGroup.bindingPointIndex = bindingPointIndex;

		final buffer = gl.createBuffer();
		final size = uniformsGroup.size;
		final usage = uniformsGroup.usage;

		gl.bindBuffer( WebGL.UNIFORM_BUFFER, buffer );
		gl.bufferData( WebGL.UNIFORM_BUFFER, size!, usage);
		gl.bindBuffer( WebGL.UNIFORM_BUFFER, null );
		gl.bindBufferBase( WebGL.UNIFORM_BUFFER, bindingPointIndex, buffer );

		return buffer;
	}

	int allocateBindingPointIndex() {
		for (int i = 0; i < maxBindingPoints; i ++ ) {
			if (!allocatedBindingPoints.contains( i )) {
				allocatedBindingPoints.add( i );
				return i;
			}
		}

		console.error( 'THREE.WebGLRenderer: Maximum number of simultaneously usable uniforms groups reached.' );
		return 0;
	}

	void updateBufferData(Map uniformsGroup ) {
		final buffer = buffers[ uniformsGroup['id'] ];
		final uniforms = uniformsGroup['uniforms'];
		final cache = uniformsGroup['__cache'];

		gl.bindBuffer( WebGL.UNIFORM_BUFFER, buffer );

		for (int i = 0, il = uniforms.length; i < il; i ++ ) {
			final uniformArray = uniforms[ i ] is List? uniforms[ i ] : [ uniforms[ i ] ];

			for (int j = 0, jl = uniformArray.length; j < jl; j ++ ) {
				final uniform = uniformArray[ j ];

				if ( hasUniformChanged( uniform, i, j, cache ) == true ) {
					final offset = uniform['__offset'];
					final values = uniform['value'] is List? uniform['value'] : [ uniform['value'] ];
					int arrayOffset = 0;

					for (int k = 0; k < values.length; k ++ ) {
						final value = values[ k ];
						final info = getUniformSize( value );

						// TODO add integer and struct support
						if (value is double || value is int || value is num || value is bool ) {
							uniform['__data'][ 0 ] = value;
							gl.bufferSubData( WebGL.UNIFORM_BUFFER, offset + arrayOffset, uniform['__data'] );
						} 
            else if ( value is Matrix3 ) {
							uniform['__data'][ 0 ] = value.storage[ 0 ];
							uniform['__data'][ 1 ] = value.storage[ 1 ];
							uniform['__data'][ 2 ] = value.storage[ 2 ];
							uniform['__data'][ 3 ] = 0;
							uniform['__data'][ 4 ] = value.storage[ 3 ];
							uniform['__data'][ 5 ] = value.storage[ 4 ];
							uniform['__data'][ 6 ] = value.storage[ 5 ];
							uniform['__data'][ 7 ] = 0;
							uniform['__data'][ 8 ] = value.storage[ 6 ];
							uniform['__data'][ 9 ] = value.storage[ 7 ];
							uniform['__data'][ 10 ] = value.storage[ 8 ];
							uniform['__data'][ 11 ] = 0;
						} 
            else {
							value.toArray( uniform['__data'], arrayOffset );
							arrayOffset += info['storage']! ~/ Float32List.bytesPerElement;
						}
					}

					gl.bufferSubData( WebGL.UNIFORM_BUFFER, offset, uniform['__data'] );
				}
			}
		}

		gl.bindBuffer( WebGL.UNIFORM_BUFFER, null );
	}

	bool hasUniformChanged( uniform, int index, indexArray, cache ) {
		final value = uniform['value'];
		final indexString = '${index}_$indexArray';

		if ( cache[ indexString ] == null ) {
			if (value is double || value is int || value is num || value is bool ) {
				cache[ indexString ] = value;
			} else {
				cache[ indexString ] = value.clone();
			}

			return true;
		} 
    else {
			final cachedObject = cache[ indexString ];

			// compare current value with cached entry

			if (value is double || value is int || value is num || value is bool ) {
				if ( cachedObject != value ) {
					cache[ indexString ] = value;
					return true;
				}
			}
      else {
				if ( cachedObject.equals( value ) == false ) {
					cachedObject.copy( value );
					return true;
				}
			}
		}

		return false;
	}

	WebGLUniformsGroups prepareUniformsGroup(UniformsGroup uniformsGroup ) {
		// determine total buffer size according to the STD140 layout
		// Hint: STD140 is the only supported layout in WebGL 2
		final uniforms = uniformsGroup.uniforms;

		int offset = 0; // global buffer offset in bytes
		const int chunkSize = 16; // size of a chunk in bytes

		for (int i = 0, l = uniforms.length; i < l; i ++ ) {
			final List<Uniform> uniformArray = [uniforms[ i ]];

			for (int j = 0, jl = uniformArray.length; j < jl; j ++ ) {
				final uniform = uniformArray[ j ];
				final values = uniform.value is List ? uniform.value : [ uniform.value ];

				for (int k = 0, kl = values.length; k < kl; k ++ ) {
					final value = values[ k ];
					final info = getUniformSize( value );
					// Calculate the chunk offset
					final chunkOffset = offset % chunkSize;
					final chunkPadding = chunkOffset % info['boundary']!; // required padding to match boundary
					final chunkStart = chunkOffset + chunkPadding; // the start position in the current chunk for the data

          offset += chunkPadding;

					// Check for chunk overflow
					if ( chunkStart != 0 && ( chunkSize - chunkStart ) < info['storage']! ) {
						// Add padding and adjust offset
						offset += ( chunkSize - chunkStart );
					}

					// the following two properties will be used for partial buffer updates
					uniform.data = Float32Array( info['storage']! ~/ Float32List.bytesPerElement);
					uniform.offset = offset;

					// Update the global offset
					offset += info['storage']!;
				}
			}
		}

		// ensure correct final padding

		final chunkOffset = offset % chunkSize;

		if ( chunkOffset > 0 ) offset += ( chunkSize - chunkOffset );

		uniformsGroup.size = offset;
		uniformsGroup.cache = {};

		return this;
	}

	Map<String,int> getUniformSize( value ) {
		final Map<String,int> info = {
			'boundary': 0, // bytes
			'storage': 0 // bytes
		};

		// determine sizes according to STD140

		if (value is double || value is int || value is num || value is bool ) {
			info['boundary'] = 4;
			info['storage'] = 4;
		} else if ( value is Vector2 ) {
			info['boundary'] = 8;
			info['storage'] = 8;
		} else if ( value is Vector3 || value is Color ) {
			info['boundary'] = 16;
			info['storage'] = 12; // evil: vec3 must start on a 16-byte boundary but it only consumes 12 bytes
		} else if ( value is Vector4 ) {
			info['boundary'] = 16;
			info['storage'] = 16;
		} else if ( value is Matrix3 ) {
			info['boundary'] = 48;
			info['storage'] = 48;
		} else if ( value is Matrix4 ) {
			info['boundary'] = 64;
			info['storage'] = 64;
		} else if ( value is Texture ) {
			console.warning( 'THREE.WebGLRenderer: Texture samplers can not be part of an uniforms group.' );
		} else {
			console.warning( 'THREE.WebGLRenderer: Unsupported uniform value type. $value');
		}

		return info;
	}

	void onUniformsGroupsDispose( event ) {
		final uniformsGroup = event.target;

		uniformsGroup.removeEventListener( 'dispose', onUniformsGroupsDispose );

		final index = allocatedBindingPoints.indexOf( uniformsGroup['__bindingPointIndex'] );
		allocatedBindingPoints.removeAt(index);

		gl.deleteBuffer( buffers[ uniformsGroup.id ] );

    buffers.remove(uniformsGroup.id);
    updateList.remove(uniformsGroup.id);
	}

	void dispose() {
		for ( final id in buffers.keys ) {
			gl.deleteBuffer( buffers[ id ] );
		}

		allocatedBindingPoints = [];
		buffers = {};
		updateList = {};
	}
}
