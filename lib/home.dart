import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:assets_audio_player/assets_audio_player.dart';

import 'main.dart';

class Home extends StatefulWidget {
  BluetoothConnection connection;

  Home({required this.connection});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late Timer temp;
  var t = AssetsAudioPlayer.newPlayer();
  String current = "P";
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    const oneSec = Duration(milliseconds: 1500);
    temp = Timer.periodic(oneSec, (Timer ti) {
      String signal = "1";
      var v = signal.split('');
      widget.connection.output.add(ascii.encode(signal));
      // sleep(Duration(milliseconds: 100));
    });
    widget.connection.input!.listen((event) {
      setState(() {
        current = ascii.decode(event);
      });
      if (t.playlist != null) {
        t.playlist!.audios.clear();
      }
      t.stop();
      t.open(Audio("assets/${current}.mp3"), showNotification: false);
      t.play();
      // if (current == "P") {
      //   t.open(Audio("assets/P.mp3"), showNotification: false);
      //   t.play();
      // } else if (current == "F") {
      //   t.open(Audio("assets/F.mp3"), showNotification: false);
      //   t.play();
      // } else if (current == "L") {
      //   t.open(Audio("assets/L.m4a"), showNotification: false);
      //   t.play();
      // } else if (current == "R") {
      //   t.open(Audio("assets/R.m4a"), showNotification: false);
      //   t.play();
      // } else if (current == "E") {
      //   t.open(Audio("assets/E.m4a"), showNotification: false);
      //   t.play();
      // }
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    temp.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Home"),
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
      body: Center(
        child: Text(current),
      ),
    );
  }
}
