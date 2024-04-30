enum Semantic{
  position,
  normal,
  color,
  uv,
  uv2,
  tangent,
  lineDistances,
  skinWeights,
  skinIndex,
  faceIndex,
  morphs;

  static Semantic? getFromName(String name){
    for(int i = 0; i < values.length;i++){
      if(values[i].name == name){
        return values[i];
      } 
    }

    return null;
  }
}