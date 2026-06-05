class NodeFunctionInput {
  bool isConst;
  String type;
  String name;
  int? count;
  String qualifier;

	NodeFunctionInput( this.type, this.name, [this.count, this.qualifier = '', this.isConst = false ]);
}
