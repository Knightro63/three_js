import 'package:three_js_gpu/gpu_backend.dart';

import './backend.dart';
import 'package:three_js_math/three_js_math.dart';
import './data_map.dart';
import './constants.dart';

class Attributes extends DataMap {
  Backend backend;

	Attributes(this.backend ):super();

	Map? delete(dynamic attribute ) {
    if(attribute is! BufferAttribute ){
      throw('Attribute must be BufferAttribute');
    }
		final attributeData = super.delete( attribute );

		if ( attributeData != null ) {
			backend.destroyAttribute( attribute );
		}

		return attributeData;
	}

	void update(BufferAttribute attribute, int type ) {
		final data = get( attribute );

		if ( data.version == null ) {
			if ( type == AttributeType.vertex.index ) {
				backend.createAttribute( attribute );
			} else if ( type == AttributeType.indx.index ) {
				backend.createIndexAttribute( attribute );
			} else if ( type == AttributeType.storage.index ) {
				backend.createStorageAttribute( attribute );
			} else if ( type == AttributeType.indirect.index ) {
				(backend as WebGPUBackend).createIndirectStorageAttribute( attribute );
			}

			data.version =_getBufferAttribute( attribute ).version;

		}
    else {
			final bufferAttribute = _getBufferAttribute( attribute );

			if ( data.version < bufferAttribute.version || bufferAttribute.usage == DynamicDrawUsage ) {
				backend.updateAttribute( attribute );
				data.version = bufferAttribute.version;
			}
		}
	}

	BufferAttribute _getBufferAttribute(BufferAttribute attribute ) {
		if ( attribute is InterleavedBufferAttribute ) attribute = attribute.data;
		return attribute;
	}

}
