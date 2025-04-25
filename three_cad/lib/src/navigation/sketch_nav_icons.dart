import 'package:flutter/material.dart';
import 'package:three_cad/src/cad/draw_types.dart';

class SketchIcons extends StatelessWidget{
  final onTap;
  final selected;
  final DrawType drawType;

  SketchIcons(
    this.drawType,
    this.selected,
    this.onTap,
  );

  Widget getDrawType(Color color){
    switch (drawType) {
      case DrawType.line:
        return _SketchIcons.line(color);
      case DrawType.box2Point:
        return _SketchIcons.box2Point(color);
      case DrawType.circleCenter:
        return _SketchIcons.circleCenter(color);
      case DrawType.boxCenter:
        return _SketchIcons.boxCenter(color);
      case DrawType.spline:
        return _SketchIcons.spline(color);
      default:
        return Container();
    }
  }

  @override
  Widget build(BuildContext context) {
    Color color = (selected?Theme.of(context).secondaryHeaderColor:Theme.of(context).primaryColorLight);
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(5),
        width: 45,
        height: 35,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color)
        ),
        alignment: Alignment.center,
        child: getDrawType(color)
      ),
    );
  }
}

class _SketchIcons{
  static Widget boxCenter(Color color){
    return CustomPaint(
      painter: BoxCenterIcon(color),
      size: Size(100,100),
    );
  }

  static Widget box2Point(Color color){
    return CustomPaint(
      painter: Box2PointIcon(color),
      size: Size(100,100),
    );
  }
  
  static Widget line(Color color){
    return CustomPaint(
      painter: LineIcon(color),
      size: Size(100,100),
    );
  }  
  
  static Widget spline(Color color){
    return CustomPaint(
      painter: SplineIcon(color),
      size: Size(100,100),
    );
  }

  static Widget circleCenter(Color color){
    return CustomPaint(
      painter: CircleCenterIcon(color),
      size: Size(100,100),
    );
  }
}

class LineIcon extends CustomPainter{
  Color color;
  LineIcon(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint();
    paint.color = color;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2;

    canvas.drawRect(Rect.fromCenter(center: Offset(7.5,7.5), width: 4, height: 4), paint);
    canvas.drawLine(Offset(7.5,7.5), Offset(size.width/2,size.height-7.5), paint);
    canvas.drawRect(Rect.fromCenter(center: Offset(size.width/2,size.height-7.5), width: 4, height: 4), paint);
    canvas.drawLine(Offset(size.width/2,size.height-7.5), Offset(size.width-7.5,7.5), paint);
    canvas.drawRect(Rect.fromCenter(center: Offset(size.width-7.5,7.5), width: 4, height: 4), paint);
  }

  @override
  bool shouldRepaint(LineIcon oldDelegate) {
    return false;
  }
}

class SplineIcon extends CustomPainter{
  Color color;
  SplineIcon(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint();
    paint.color = color;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2;

    final Path path = Path();
    var firstControlPoint = Offset(7.5,size.height-7.5);
    var firstEndPoint = Offset(size.width/2,size.height-7.5);
    var secondControlPoint = Offset(size.width-7.5, size.height-7.5);
    var secondEndPoint = Offset(size.width-7.5,7.5);

    path.moveTo(7.5, 7.5);
    path.quadraticBezierTo(firstControlPoint.dx, firstControlPoint.dy,
        firstEndPoint.dx, firstEndPoint.dy);
    path.quadraticBezierTo(secondControlPoint.dx, secondControlPoint.dy,
        secondEndPoint.dx, secondEndPoint.dy);

    canvas.drawRect(Rect.fromCenter(center: Offset(7.5,7.5), width: 4, height: 4), paint);
    canvas.drawRect(Rect.fromCenter(center: Offset(size.width/2,size.height-7.5), width: 4, height: 4), paint);
    canvas.drawRect(Rect.fromCenter(center: Offset(size.width-7.5,7.5), width: 4, height: 4), paint);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(SplineIcon oldDelegate) {
    return false;
  }
}

class Box2PointIcon extends CustomPainter{
  Color color;
  Box2PointIcon(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint();
    paint.color = color;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2;

    canvas.drawRect(Rect.fromCenter(center: Offset(size.width/2,size.height/2), width: size.width-15, height: size.height-15), paint);
    canvas.drawRect(Rect.fromCenter(center: Offset(7.5,7.5), width: 4, height: 4), paint);
    canvas.drawRect(Rect.fromCenter(center: Offset(size.width-7.5,size.height-7.5), width: 4, height: 4), paint);
  }

  @override
  bool shouldRepaint(Box2PointIcon oldDelegate) {
    return false;
  }
}

class BoxCenterIcon extends CustomPainter{
  Color color;
  BoxCenterIcon(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint();
    paint.color = color;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2;

    canvas.drawRect(Rect.fromCenter(center: Offset(size.width/2,size.height/2), width: size.width-15, height: size.height-15), paint);
    canvas.drawRect(Rect.fromCenter(center: Offset(size.width/2,size.height/2), width: 4, height: 4), paint);
    canvas.drawRect(Rect.fromCenter(center: Offset(size.width-7.5,size.height-7.5), width: 4, height: 4), paint);
  }

  @override
  bool shouldRepaint(BoxCenterIcon oldDelegate) {
    return false;
  }
}

class CircleCenterIcon extends CustomPainter{
  Color color;
  CircleCenterIcon(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint();
    paint.color = color;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2;

    canvas.drawCircle(Offset(size.width/2,size.height/2), size.height/2-5, paint);
    canvas.drawRect(Rect.fromCenter(center: Offset(size.width/2,size.height/2), width: 4, height: 4), paint);
  }

  @override
  bool shouldRepaint(CircleCenterIcon oldDelegate) {
    return false;
  }
}