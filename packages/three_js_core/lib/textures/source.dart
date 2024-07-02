import 'package:three_js_core/others/index.dart';
import 'package:three_js_math/three_js_math.dart';
import 'image_element.dart';

/// Represents the data source of a texture.
class Source {
  late String uuid;
  dynamic data;
  late int version;
  int currentVersion = 0;

  /// [data] -- The data definition of a texture. Default is `null`.
	Source([this.data]){
    uuid = MathUtils.generateUUID();
    version = 0;
	}

	set needsUpdate(bool value ) {
    if(value) version++;
	}

  void dispose(){
    if(data is List){
      for(final temp in data){
        if(temp is NativeArray){
          temp.dispose();
        }
        else if(temp is ImageElement){
          temp.dispose();
        }
      }
    }
    else if(data is ImageElement){
      (data as ImageElement).dispose();
    }
    else if(data is NativeArray){
      (data as NativeArray).dispose();
    }
  }

  /// [meta] - optional object containing metadata.
  /// 
  /// Convert the data source to three.js
  /// [JSON Object/Scene format](https://github.com/mrdoob/three.js/wiki/JSON-Object-Scene-format-4).
	Map<String,dynamic> toJson(meta) {
		final isRootObject = ( meta == null || meta is String );

    if (!isRootObject && meta.images[uuid] != null) {
      return meta.images[uuid];
		}

		final output = {
			"uuid": uuid,
			"url": ''
		};

		final data = this.data;

		if ( data != null ) {
			dynamic url;

			if ( data is List ) {
				url = [];

				for ( int i = 0, l = data.length; i < l; i ++ ) {
					if ( data[ i ].isDataTexture ) {
						url.add( serializeImage( data[ i ].image ) );
					} 
          else {
						url.add( serializeImage( data[ i ] ) );
					}
				}
			} 
      else {
				url = serializeImage( data );
			}

			output["url"] = url;
		}

		if(!isRootObject){
      meta.images[uuid] = output;
		}

		return output;
	}
}

Map<String,dynamic> serializeImage( image ) {
	if (image is ImageElement){
		return {'image': image.src};//ImageUtils.getDataURL( image );
	} 
  else {
		if ( image.data != null ) {
			return {
				"data": image.data.sublist(0),
				"width": image.width,
				"height": image.height,
				"type": image.data.runtimeType.toString()
			};

		} 
    else {
			console.warning('Texture: Unable to serialize Texture.');
			return {};
		}
	}
}
