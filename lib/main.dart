import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:hi/graph.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:hi/home.dart';
import 'package:hi/location.dart';
import 'package:hi/new_trial.dart';
import 'package:hi/voice_trial.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        colorScheme:
            ThemeData.dark().colorScheme.copyWith(primary: Colors.orange),
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var player = AssetsAudioPlayer.newPlayer();
  late BluetoothConnection connection;
  late Timer t;
  bool cond = true;
  int j = 1;
  SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  String _lastWords = '';
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _initSpeech();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    t.cancel();
  }

  void _initSpeech() async {
    await Permission.microphone.request();
    _speechEnabled = await _speechToText.initialize();
    setState(() {});
    t = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_speechToText.isNotListening) {
        _startListening();
      }
    });
  }

  void _startListening() async {
    await _speechToText.listen(onResult: _onSpeechResult);
    setState(() {});
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() {});
  }

  /// This is the callback that the SpeechToText plugin calls when
  /// the platform returns recognized words.
  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      _lastWords = result.recognizedWords;
    });
    print(_lastWords);
    if (_lastWords.toLowerCase().contains("connect")) {
      connect();
    }
  }

  Future connect() async {
    var status = await Permission.bluetooth.status;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Attempting to connect to HC-05....")));
    print(status);
    if (status.isDenied) {
      await Permission.bluetooth.request();
    }

    if (await Permission.bluetooth.status.isPermanentlyDenied) {
      print("Ded");
      openAppSettings();
    }
    try {
      connection = await BluetoothConnection.toAddress("98:D3:35:00:D3:90");
      print(connection.isConnected);
      print('Connected to the device');
      String signal = "2";
      var v = signal.split('');
      connection.output.add(ascii.encode(signal));
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) {
        return Home(connection: connection);
      }));
    } catch (exception) {
      print('Cannot connect, exception occured' + exception.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 35.0),
            child: Center(
              child: Image.asset('assets/logo.png'),
            ),
          ),
          SizedBox(
            height: 30,
          ),
          Center(
            child: ElevatedButton(
              child: Text("Connect"),
              onPressed: () async {
                await connect();
              },
            ),
          ),
          // Center(
          //   child: ElevatedButton(
          //     child: Text("Location Screen"),
          //     onPressed: () {
          //       Navigator.pushReplacement(context,
          //           MaterialPageRoute(builder: (_) {
          //         return LocationScreen();
          //       }));
          //     },
          //   ),
          // ),
          // Center(
          //   child: ElevatedButton(
          //     child: Text("Create Graph"),
          //     onPressed: () {
          //       Navigator.pushReplacement(context,
          //           MaterialPageRoute(builder: (_) {
          //         return MyGraph();
          //       }));
          //     },
          //   ),
          // ),
        ],
      ),
    );
  }
}
