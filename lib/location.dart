import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'main.dart';

double calculateDistance(lat1, lon1, lat2, lon2) {
  var p = 0.017453292519943295;
  var c = cos;
  var a = 0.5 -
      c((lat2 - lat1) * p) / 2 +
      c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
  return 12742 * 100000 * asin(sqrt(a));
}

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  double _heading = 0;
  int iter = 0;
  double sum = 0;
  double avgHeading = 0;
  var geoloc;
  var magnet;

  late Position _position = Position(
      longitude: 0,
      latitude: 0,
      timestamp: DateTime.now(),
      accuracy: 100,
      altitude: 0,
      heading: 0,
      speed: 0,
      speedAccuracy: 0);
  late Position _prev = Position(
      longitude: 0,
      latitude: 0,
      timestamp: DateTime.now(),
      accuracy: 100,
      altitude: 0,
      heading: 0,
      speed: 0,
      speedAccuracy: 0);
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    Geolocator.requestPermission();
    geoloc = Geolocator.getPositionStream(
            locationSettings:
                LocationSettings(accuracy: LocationAccuracy.bestForNavigation))
        .listen((Position position) async {
      setState(() {
        _prev = _position;
        _position = position;
      });
      if (_prev.latitude == 0 && _prev.longitude == 0) {
        return;
      }
      GeoPoint last = GeoPoint(_prev.latitude, _prev.longitude);
      GeoPoint now = GeoPoint(_position.latitude, _position.longitude);
      double lat = _position.latitude * 100000;
      double long = _position.longitude * 100000;
      int iLat = lat.round();
      int iLong = long.round();
      String currName = iLat.toString() + "_" + iLong.toString();
      double prevLat = _prev.latitude * 100000;
      double prevLong = _prev.longitude * 100000;
      int pLat = prevLat.round();
      int pLong = prevLong.round();
      String prevName = pLat.toString() + "_" + pLong.toString();
      if (prevName == currName) {
        print("BYE");
        return;
      }
      double dist = calculateDistance(_prev.latitude, _prev.longitude,
          _position.latitude, _position.longitude);
      CollectionReference points =
          FirebaseFirestore.instance.collection('points');
      var prevPoint = await points.doc(prevName).get();

      if (!prevPoint.exists) {
        points.doc(prevName).set({
          'name': "",
          'point': last,
        });
        int temp = _heading.round();
        points.doc(prevName).collection('children').doc(temp.toString()).set({
          'point': now,
          'name': currName,
          'heading': temp,
        });
      } else {
        int temp = _heading.round();
        bool cond = true;
        var tempDoc;
        while (true) {
          tempDoc = await points
              .doc(prevName)
              .collection('children')
              .doc(temp.toString())
              .get();
          if (tempDoc.exists) {
            cond = true;
            GeoPoint chil = tempDoc['point'];
            double chilDistance = calculateDistance(
                chil.latitude, chil.longitude, last.latitude, last.longitude);
            double dist = calculateDistance(
                last.latitude, last.longitude, now.latitude, now.longitude);
            if (chilDistance < dist) {
              prevName = tempDoc['name'];
              last = tempDoc['point'];
            } else {
              String chilName = tempDoc['name'];
              await points
                  .doc(prevName)
                  .collection('children')
                  .doc(temp.toString())
                  .update({'name': currName, 'point': now, 'heading': temp});
              await points
                  .doc(currName)
                  .collection('children')
                  .doc(temp.toString())
                  .set({
                'name': chilName,
                'point': chil,
                'heading': temp,
              });
              int opp = 0;
              if (temp < 0) {
                opp = temp + 180;
              } else {
                opp = temp - 180;
              }
              await points
                  .doc(chilName)
                  .collection('children')
                  .doc(opp.toString())
                  .set({
                'name': currName,
                'point': now,
                'heading': opp,
              });
              cond = false;
              break;
            }
          } else {
            break;
          }
        }
        if (cond) {
          await points
              .doc(prevName)
              .collection('children')
              .doc(temp.toString())
              .set({'name': currName, 'point': now, 'heading': temp});
        }
      }
      var currPoint = await points.doc(currName).get();

      if (!currPoint.exists) {
        points.doc(currName).set({
          'name': "",
          'point': now,
        });
        if (_heading < 0) {
          _heading += 180;
        } else {
          _heading -= 180;
        }
        int temp = _heading.round();
        points.doc(currName).collection('children').doc(temp.toString()).set({
          'point': last,
          'name': prevName,
          'heading': temp,
        });
      } else {
        int opp = 0;
        if (_heading < 0) {
          opp = _heading.round() + 180;
        } else {
          opp = _heading.round() - 180;
        }
        bool cond = true;
        var tempDoc;
        while (true) {
          tempDoc = await points
              .doc(currName)
              .collection('children')
              .doc(opp.toString())
              .get();
          if (tempDoc.exists) {
            cond = true;
            GeoPoint chil = tempDoc['point'];
            double chilDistance = calculateDistance(
                chil.latitude, chil.longitude, now.latitude, now.longitude);
            double dist = calculateDistance(
                last.latitude, last.longitude, now.latitude, now.longitude);
            if (chilDistance < dist) {
              currName = tempDoc['name'];
              now = tempDoc['point'];
            } else {
              String chilName = tempDoc['name'];
              await points
                  .doc(currName)
                  .collection('children')
                  .doc(opp.toString())
                  .update({'name': prevName, 'point': last, 'heading': opp});
              await points
                  .doc(prevName)
                  .collection('children')
                  .doc(opp.toString())
                  .set({
                'name': chilName,
                'point': chil,
                'heading': opp,
              });
              int tt = 0;
              if (opp < 0) {
                tt = opp + 180;
              } else {
                tt = opp - 180;
              }
              await points
                  .doc(chilName)
                  .collection('children')
                  .doc(tt.toString())
                  .set({
                'name': prevName,
                'point': last,
                'heading': tt,
              });
              cond = false;
              break;
            }
          } else {
            break;
          }
        }
        if (cond) {
          await points
              .doc(currName)
              .collection('children')
              .doc(opp.toString())
              .set({'name': prevName, 'point': now, 'heading': opp});
        }
      }
    });
    magnet = magnetometerEvents.listen((MagnetometerEvent event) {
      double x = event.x;
      double y = event.y;
      double z = event.z;
      double heading = atan2(y, x);
      setState(() {
        _heading = (heading * 180 / pi);
      });
      iter++;
      sum += _heading;
      setState(() {});
      if (iter == 20) {
        setState(() {
          avgHeading = sum / 20;
          iter = 0;
          sum = 0;
        });
      }
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    geoloc.cancel();
    magnet.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Bonjour"),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) {
                return MyHomePage();
              }));
            },
            icon: Icon(Icons.home),
          )
        ],
      ),
      body: Column(
        children: [
          Text(_position.toString()),
          Text(
            'Heading: ${(avgHeading).toStringAsFixed(2)}',
            style: TextStyle(fontSize: 20),
          ),
        ],
      ),
    );
  }
}
