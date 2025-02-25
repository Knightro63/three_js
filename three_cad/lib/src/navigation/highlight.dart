import 'package:flutter/material.dart';

class HighLight{
  HighLight({
    required BuildContext context,
    double width = 150,
    this.offset = const Offset(0,0),
    TextStyle? style,
  }){
    _context = context;
    _style = style;
    _width = width;
  }

  late BuildContext _context;
  late String _text;
  late double _width;
  TextStyle? _style;
  late OverlayEntry _overlayEntry;
  late GlobalKey _key;
  Offset offset;
  late Offset buttonPosition;
  late Size buttonSize;
  bool isMenuOpen = false;

  OverlayEntry _overlayEntryBuilder() {
    return OverlayEntry(
      builder: (context) {
        context = _context;
        return Positioned(
          top: positionY(),
          left: positionX(),
          width: _width,
          height: 30,
          child: OverlayClass(
            theme: Theme.of(_context),
            text: _text,
            style: _style,
            width: _width,
          )
        );
      },
    );
  }

  double positionY(){
    if((buttonPosition.dy+buttonSize.height+30+5 > MediaQuery.of(_context).size.height))return buttonPosition.dy-35;
    return buttonPosition.dy+35;
  }
  double positionX(){
    if(buttonPosition.dx+_width > MediaQuery.of(_context).size.width) return buttonPosition.dx-(buttonPosition.dx+_width-MediaQuery.of(_context).size.width)-5-offset.dx;
    return buttonPosition.dx-_width/4-offset.dx;
  }

  findButton() {
    RenderBox renderBox = _key.currentContext!.findRenderObject() as RenderBox;
    buttonSize = renderBox.size;
    buttonPosition = renderBox.localToGlobal(Offset.zero);
  }

  void closeMenu(){
    //currentItem = '';
    _overlayEntry.remove();
    isMenuOpen = !isMenuOpen;
  }

  void openMenu(String text,GlobalKey key){
    _key = key;
    _text = text;
    findButton();
    _overlayEntry = _overlayEntryBuilder();
    Overlay.of(_context).insert(_overlayEntry);
    isMenuOpen = !isMenuOpen;
  }
}

class OverlayClass extends StatefulWidget {
  const OverlayClass({
    Key? key,
    this.text = 'Text',
    this.style,
    required this.width,
    required this.theme
  }):super(key: key);

  final ThemeData theme;
  final String text;
  final TextStyle? style;
  final double width;

  @override
  _OverlayClassState createState() => _OverlayClassState();
}
class _OverlayClassState extends State<OverlayClass> {
  String itemName = '';
  
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.only(top: 5),
        alignment: Alignment.center,
        height: 30,
        width: widget.width,
        decoration: BoxDecoration(
          color: widget.theme.cardColor,
          borderRadius: BorderRadius.circular(5),
          boxShadow: [BoxShadow(
            color: widget.theme.shadowColor,
            blurRadius: 5,
            offset: const Offset(2,2),
          ),]
        ),
        child: Text(
          widget.text,
          style: widget.theme.primaryTextTheme.titleSmall,
        )
      )
    );
  }
}