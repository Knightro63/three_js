class Point{
  Point(this.x,this.y);
  double x;
  double y;
}
class Edge{
  Edge(this.p1,this.p2);
  String p1; //index of pont1
  String p2; //index of pont2

  bool containsPointInEdge(Edge edge){
    return p1 == edge.p1 || p1 == edge.p2 || p2 == edge.p1 || p2 == edge.p2;
  }
  bool containsPoint(String point){
    return p1 == point || p2 == point;
  }
  List<String> getPointOrder(Edge edge){
    if(p1 == edge.p1 || p1 == edge.p2){
      return [p1,p2];
    }
    else{
      return [p2,p1];
    }
  }
  String getNextPoint(String point){
    if(p1 == point){
      return p2;
    }
    else{
      return p1;
    }
  }
}
class Polygon{
  Polygon(this.points);
  List<String> points = []; //index of edges
}

class SvgEdgeFinder{
  String reduce(String path){
    List<String> tosplit = path.split('z');
    Map<String,Point> points = {};
    Map<String,Edge> edges = {};
    List<String> edgesToRemove = [];

    String sort(List<double> edge){
      List<double> temp = [edge[2],edge[3],edge[0],edge[1]];
      temp.sort();
      return temp.toString().replaceAll(' ', '');
    }

    //get edges poits and ploys
    for(int i = 0; i < tosplit.length; i++){
      List<String> temp = tosplit[i].replaceAll('M', '').split('L');
      if(temp.first != ''){
        for(int j = 0; j < temp.length; j++){
          List<String> points1 = temp[j].split(',');
          int k = j != temp.length-1?j+1:0;
          List<String> points2 = temp[k].split(',');
          String p1Loc = temp[j].replaceAll(' ', '');
          double? x1 = double.tryParse(points1[0]);
          double? y1 = double.tryParse(points1[1]);
          if(x1 != null && y1 != null){
            points[p1Loc] = Point( x1, y1 );
          }
          else{ points[p1Loc] = Point( 0, 0 ); }
          String p2Loc = temp[k].replaceAll(' ', '');
          double? x2 = double.tryParse(points2[0]);
          double? y2 = double.tryParse(points2[1]);
          if(x2 != null && y2 != null){
            points[p2Loc] = Point( x2, y2 );
          }
          else{ points[p2Loc] = Point( 0, 0 ); }
          String edgeLoc = sort([points[p1Loc]!.x,points[p1Loc]!.y,points[p2Loc]!.x,points[p2Loc]!.y]);
          if(edges[edgeLoc] != null){
            edgesToRemove.add(edgeLoc);
          }
          edges[edgeLoc] = Edge(p1Loc,p2Loc);
        }
      }
    }
    for(int i = 0; i < edgesToRemove.length;i++){
      edges.remove(edgesToRemove[i]);
    }

    List<Polygon>? polys = getPolys(edges);
    //polys = removeInteriorPolygons(polys,points);
    return placePoints(polys,points);
  }

  List<Polygon>? getPolys(Map<String,Edge> edges){
    List<Polygon> polygons = [];
    List<String> keys = edges.keys.toList();
    if(keys.isNotEmpty){
      List<String> pointToAdd = [edges[keys[0]]!.p1,edges[keys[0]]!.p2];
      edges.remove(keys[0]);

      while(edges.isNotEmpty){
        bool contin = false;
        
        for(String edge in edges.keys){
          if(edges[edge]!.containsPoint(pointToAdd.first)){
            String point = edges[edge]!.getNextPoint(pointToAdd.first);
            pointToAdd.insert(0, point);
            edges.remove(edge);
            contin = true;
            break;
          }
          else if(edges[edge]!.containsPoint(pointToAdd.last)){
            String point = edges[edge]!.getNextPoint(pointToAdd.last);
            pointToAdd.add(point);
            edges.remove(edge);
            contin = true;
            break;
          }
        }

        if(!contin){
          polygons.add(Polygon(pointToAdd));
          List<String> keys = edges.keys.toList();
          pointToAdd = [edges[keys[0]]!.p1,edges[keys[0]]!.p2];
          edges.remove(keys[0]);
        }
      }
      polygons.add(Polygon(pointToAdd));
      return polygons;
    }
    return null;
  }
  String placePoints(List<Polygon>? poly,Map<String,Point> points){
    String text = '';
    if(poly != null){
      for(int j = 0; j < poly.length; j++){
        if(poly[j].points.length > 4){
          String startPoint = poly[j].points.first;
          text += 'M${points[startPoint]!.x},${points[startPoint]!.y}';
          for(int i = 1; i < poly[j].points.length; i++){
            String newPoint = poly[j].points[i];
            text += 'L${points[newPoint]!.x},${points[newPoint]!.y}';
          }
          text += 'z';
        }
      }
    }
    return text;
  }
}
