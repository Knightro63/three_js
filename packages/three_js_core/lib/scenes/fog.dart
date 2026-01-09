import 'package:three_js_math/three_js_math.dart';

class FogBase {
  String name = "";
  late Color color;

  late double density;
  late double near;
  late double far;

  bool isFog = false;
  bool isFogExp2 = false;

  dynamic operator [] (key) => getProperty(key);
  void operator []=(String key, dynamic value) => setProperty(key, value);

  FogBase clone() {
    throw(" need implement .... ");
  }

  Map<String,dynamic> toJson() {
    throw(" need implement .... ");
  }

  dynamic getProperty(String propertyName, [int? offset]) {
    if(propertyName == 'density'){
      return density;
    }
    else if(propertyName == 'near'){
      return near;
    }
    else if(propertyName == 'far'){
      return far;
    }
    else if(propertyName == 'color'){
      return color;
    }
    return null;
  }

  FogBase setProperty(String propertyName, dynamic value, [int? offset]){
    if(propertyName == 'density'){
      density = value.toDouble();
    }
    else if(propertyName == 'near'){
      near = value.toDouble();
    }
    else if(propertyName == 'far'){
      far = value.toDouble();
    }
    else if(propertyName == 'fog'){
      if(value is num){
        color = Color.fromHex32(value.toInt());
      }

      color = value;
    }

    return this;
  }
}

/// This class contains the parameters that define linear fog, i.e., that
/// grows linearly denser with the distance.
/// ```
/// final scene = Scene();
/// scene.fog = Fog(Color.fromHex32(0xcccccc), 10, 15 );
/// ```
class Fog extends FogBase {
  /// The color parameter is passed to the [Color] constructor to set the color property.
  Fog(int color, [double? near, double? far]) {
    name = 'Fog';
    this.color = Color.fromHex32(color);
    this.near = near ?? 1;
    this.far = far ?? 1000;
    isFog = true;
  }

  Fog.fromJson(Map<String,dynamic> json){
    name = 'Fog';
    this.color = Color.fromHex32(json['color'] ?? 0);
    this.near = json['near'] ?? 1;
    this.far = json['far'] ?? 1000;
    isFog = true;
  }

  /// Returns a new fog instance with the same parameters as this one.
  @override
  Fog clone() {
    return Fog(color.getHex(), near, far);
  }
  
  /// Return fog data in JSON format.
  @override
  Map<String,dynamic> toJson(/* meta */) {
    return {
      "type": 'Fog',
      "color": color.getHex(),
      "near": near,
      "far": far
    };
  }
}
