import 'package:flutter/cupertino.dart';

class NavItems{
  NavItems({
    required this.name,
    this.icon,
    this.function,
    this.subItems,
    this.reset = false,
    this.input,
    this.quarterTurns = 0,
    this.show = true
  });

  String name;
  IconData? icon;
  void Function(dynamic)? function;
  List<NavItems>? subItems;
  dynamic input;
  bool reset;
  int quarterTurns;
  bool show;
}

class NavTab{
  NavTab({
    required this.name,
    this.function
  });

  String name;
  void Function(int)? function;
}