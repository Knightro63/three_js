import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:three_cad/src/cad/draw_types.dart';

class SketchIcons extends StatelessWidget{
  final onTap;
  final selected;
  final DrawType drawType;
  final ThemeData theme;

  SketchIcons(
    this.drawType,
    this.selected,
    this.theme,
    this.onTap,
  );

  Widget getDrawType(Color color){
    switch (drawType) {
      case DrawType.point:
        return _SketchIcons.point(color);
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
      case DrawType.arc3Point:
        return _SketchIcons.arc3Point(color);
      case DrawType.dimensions:
        return _SketchIcons.dimensions(color);
      default:
        return _SketchIcons.sketch(color);
    }
  }

  @override
  Widget build(BuildContext context) {
    Color color = (selected?theme.secondaryHeaderColor:theme.hintColor);
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
  static Widget sketch(Color color){
    return CustomPaint(
      painter: SketchIcon(color),
      size: Size(100,100),
    );
  }

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

  static Widget point(Color color){
    return CustomPaint(
      painter: PointIcon(color),
      size: Size(100,100),
    );
  }  

  static Widget dimensions(Color color){
    return CustomPaint(
      painter: DimensionsIcon(color),
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

  static Widget arc3Point(Color color){
    return CustomPaint(
      painter: Arc3PointIcon(color),
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
    return oldDelegate.color != color;
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

    path.moveTo(7.5, size.height-7.5);
    path.cubicTo(
      size.width*0.2,-size.height*0.5,
      size.width*0.8,size.height*1.5,
      size.width-7.5,7.5
    );

    canvas.drawRect(Rect.fromCenter(center: Offset(7.5,size.height-7.5), width: 4, height: 4), paint);
    canvas.drawRect(Rect.fromCenter(center: Offset(size.width*1/3,size.height/3), width: 4, height: 4), paint);
    canvas.drawRect(Rect.fromCenter(center: Offset(size.width*2/3,size.height*2/3), width: 4, height: 4), paint);
    canvas.drawRect(Rect.fromCenter(center: Offset(size.width-7.5,7.5), width: 4, height: 4), paint);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(SplineIcon oldDelegate) {
    return oldDelegate.color != color;
  }
}

class Arc3PointIcon extends CustomPainter{
  Color color;
  Arc3PointIcon(this.color);

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
  bool shouldRepaint(Arc3PointIcon oldDelegate) {
    return oldDelegate.color != color;
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
    return oldDelegate.color != color;
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
    return oldDelegate.color != color;
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
    return oldDelegate.color != color;
  }
}

class PointIcon extends CustomPainter{
  Color color;
  PointIcon(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint();
    paint.color = color;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2;

    canvas.drawLine(Offset(size.width/2,5), Offset(size.width/2,size.height/2), paint);
    canvas.drawLine(Offset(size.width/2,size.height-5), Offset(size.width/2,size.height/2), paint);
    canvas.drawRect(Rect.fromCenter(center: Offset(size.width/2,size.height/2), width: 4, height: 4), paint);
    canvas.drawLine(Offset(5,size.height/2), Offset(size.width/2,size.height/2), paint);
    canvas.drawLine(Offset(size.width-5,size.height/2), Offset(size.width/2,size.height/2), paint);
  }

  @override
  bool shouldRepaint(PointIcon oldDelegate) {
    return oldDelegate.color != color;
  }
}

class DimensionsIcon extends CustomPainter{
  Color color;
  DimensionsIcon(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint();
    paint.color = color;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2;

    canvas.drawLine(Offset(5,5), Offset(5,size.height-5), paint);
    canvas.drawLine(Offset(size.width-5,5), Offset(size.width-5,size.height-5), paint);
    canvas.drawLine(Offset(5,size.height/2), Offset(size.width-5,size.height/2), paint);
    
    canvas.drawLine(Offset(5,size.height/2), Offset(10,size.height/2-5), paint);
    canvas.drawLine(Offset(5,size.height/2), Offset(10,size.height/2+5), paint);

    canvas.drawLine(Offset(size.width-5,size.height/2), Offset(size.width-10,size.height/2-5), paint);
    canvas.drawLine(Offset(size.width-5,size.height/2), Offset(size.width-10,size.height/2+5), paint);
  }

  @override
  bool shouldRepaint(DimensionsIcon oldDelegate) {
    return oldDelegate.color != color;
  }
}

class SketchIcon extends CustomPainter{
  Color color;
  SketchIcon(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint();
    paint.color = color;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2;

    canvas.drawRect(Rect.fromCenter(center: Offset(size.width/2,size.height/2), width: size.width-15, height: size.height-15), paint);
    canvas.drawRect(Rect.fromCenter(center: Offset(7.5,7.5), width: 4, height: 4), paint);
    canvas.drawRect(Rect.fromCenter(center: Offset(7.5,size.height-7.5), width: 4, height: 4), paint);
    canvas.drawRect(Rect.fromCenter(center: Offset(size.width-7.5,7.5), width: 4, height: 4), paint);

    canvas.drawRect(Rect.fromCenter(center: Offset(size.width*1/3,size.height*1/3), width: 2, height: 2), paint);
    canvas.drawRect(Rect.fromCenter(center: Offset(size.width*2/3,size.height*1/3), width: 2, height: 2), paint);
    canvas.drawRect(Rect.fromCenter(center: Offset(size.width*1/3,size.height*2/3), width: 2, height: 2), paint);

    canvas.drawLine(Offset(size.width*1/3,size.height*1/3), Offset(size.width*2/3,size.height*1/3), paint);
    canvas.drawLine(Offset(size.width*1/3,size.height*1/3), Offset(size.width*1/3,size.height*2/3), paint);

    canvas.drawArc(
      Rect.fromCenter(center: Offset(size.width*1/3,size.height*1/3), width: size.width*2/3, height: size.height*2/3), 
      0, 
      math.pi/2, 
      false, 
      paint
    );

    canvas.drawRect(Rect.fromCenter(center: Offset(size.width-7.5,size.height-7.5), width: 2, height: 8), paint..color = Colors.green);
    canvas.drawRect(Rect.fromCenter(center: Offset(size.width-7.5,size.height-7.5), width: 8, height: 2), paint..color = Colors.green);
  }

  @override
  bool shouldRepaint(SketchIcon oldDelegate) {
    return oldDelegate.color != color;
  }
}