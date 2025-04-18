/// List of all the attributes used in threejs
enum Attribute{
  position,
  normal,
  color,
  uv,
  uv2,
  tangent,
  lineDistances,
  skinWeight,
  skinIndex,
  faceIndex,
  morphs;

  static Attribute? getFromName(String name){
    for(int i = 0; i < values.length;i++){
      if(values[i].name == name){
        return values[i];
      } 
    }

    return null;
  }
}