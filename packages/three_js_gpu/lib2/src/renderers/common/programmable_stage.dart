int _id = 0;

class ProgrammableStage {
  int id = _id ++;
  List?  transforms;
  List?  attributes;
  String name;
  String stage;
  String code;
  int usedTimes = 0;
	ProgrammableStage( this.code, this.stage, this.name, [this.transforms,this.attributes]);
}