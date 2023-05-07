import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hi/home.dart';
import 'package:hi/main.dart';
import 'package:sensors_plus/sensors_plus.dart';

class TravelGuide extends StatefulWidget {
  BluetoothConnection connection;
  List<String> path;
  TravelGuide({required this.path, required this.connection});

  @override
  State<TravelGuide> createState() => _TravelGuideState();
}

class _TravelGuideState extends State<TravelGuide> {
  int ind = 0;
  var magnet;
  bool cond = true;
  int mult = 100000;
  var geoloc;
  String currName = "";
  late Timer t;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    const oneSec = Duration(milliseconds: 2000);
    t = Timer.periodic(oneSec, (Timer ti) {
      setState(() {
        cond = true;
      });
    });
    ind = 0;
    magnet = magnetometerEvents.listen((MagnetometerEvent event) {
      double x = event.x;
      double y = event.y;
      double z = event.z;
      double heading = atan2(y, x);
      setState(() {
        _heading = (heading * 180 / pi);
      });
      // print(_heading);
      if (ind != widget.path.length - 1) {
        int dir = int.parse(widget.path[ind + 1]);
        // print("_____________");
        // print(_heading);
        // print(dir);
        // print((_heading - dir).abs());
        if ((_heading - dir).abs() > 10) {
          if (cond == true) {
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Keep Turning"),
                duration: Duration(milliseconds: 250),
              ),
            );
            setState(() {
              cond = false;
            });
          }
        } else {
          if (cond == true) {
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Move in this direction"),
                duration: Duration(milliseconds: 250),
              ),
            );
          }
        }
      }
    });
    geoloc = Geolocator.getPositionStream(
            locationSettings:
                LocationSettings(accuracy: LocationAccuracy.bestForNavigation))
        .listen((Position position) async {
      if (ind == widget.path.length - 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: Duration(milliseconds: 250),
            content: Text("Reached Locatiob"),
          ),
        );
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) {
          return Home(connection: widget.connection);
        }));
      }
      print("Bonjour");
      double lat = position.latitude * mult;
      double long = position.longitude * mult;
      int iLat = lat.round();
      int iLong = long.round();
      currName = iLat.toString() + "_" + iLong.toString();
      print(currName);
      print(widget.path[ind + 2]);
      print("______________");
      if (currName == widget.path[ind + 2]) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: Duration(milliseconds: 250),
            content: Text("Reached This Location"),
          ),
        );
        ind += 2;
        if (ind == widget.path.length - 1) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              duration: Duration(milliseconds: 250),
              content: Text("Reached Location"),
            ),
          );
          widget.connection.close();
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) {
            return MyHomePage();
          }));
        }
        setState(() {
          cond = true;
        });
      }
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    magnet.cancel();
    geoloc.cancel();
    t.cancel();
  }

  double _heading = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Bonjour"),
        actions: [
          IconButton(
              onPressed: () {
                widget.connection.close();
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (_) {
                  return MyHomePage();
                }));
              },
              icon: Icon(Icons.home))
        ],
      ),
      body: ListView.builder(
        itemCount: widget.path.length,
        itemBuilder: (context, index) {
          if (index == widget.path.length - 1) {
            return Text(widget.path[index]);
          } else if (index % 2 == 0) {
            return Text(widget.path[index] + " ->" + widget.path[index + 1]);
          } else {
            return Container();
          }
        },
      ),
    );
  }
}
