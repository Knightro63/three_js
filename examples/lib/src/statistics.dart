import 'package:flutter/material.dart';

class Statistics extends StatefulWidget {
  const Statistics({super.key, required this.data});

  final List<int> data;

  @override
  createState() => _State();
}

class _State extends State<Statistics> {
  int smallest = 256;
  int largest = 0;

  @override
  void initState() {
    super.initState();
  }
  @override
  void dispose() {
    super.dispose();
  }

  Widget pointBars(){
    List<Widget> bars = [
      Container(
        width: 1,
        height: 60,
        color: Colors.transparent,
      )
    ];

    for(final h in widget.data){
      final r = h>120?120:h;
      if(r > largest){
        largest = r;
      }
      if(r != 0 && r < smallest){
        smallest = r;
      }
      bars.add(
        Container(
          width: 2,
          height: (r/120)*60,
          color: Colors.blue,
        )
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: bars,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(5),
      width: 121,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(5)
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            height: 20,
            decoration: const BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(5),
                topRight: Radius.circular(5)
              )
            ),
            alignment: Alignment.center,
            child: Text(
              "FPS: ${widget.data.last}(${smallest == 256?'':smallest} - $largest)"
            ),
          ),
          pointBars()
        ],
      ),
    );
  }
}
