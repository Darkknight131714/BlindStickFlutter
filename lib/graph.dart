import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hi/main.dart';

late Map<String, Map<int, String>> g;
late Map<String, GeoPoint> cord;

class MyGraph extends StatefulWidget {
  const MyGraph({super.key});

  @override
  State<MyGraph> createState() => _MyGraphState();
}

class _MyGraphState extends State<MyGraph> {
  List<String> finalPath = [];
  int val = 0;
  @override
  void initState() {
    g = new Map();
    cord = new Map();
    print("Starting Graph Service");
    createGraph();
    super.initState();
  }

  Future createGraph() async {
    CollectionReference users = FirebaseFirestore.instance.collection('points');
    await users.get().then((QuerySnapshot querySnapshot) async {
      for (var element in querySnapshot.docs) {
        if (g[element.id] == null) {
          g[element.id] = new Map();
        }
        cord[element.id] = element['point'];
        CollectionReference children = FirebaseFirestore.instance
            .collection('points')
            .doc(element.id)
            .collection('children');
        await children.get().then((QuerySnapshot querySnapshot) {
          for (var child in querySnapshot.docs) {
            g[element.id]![child['heading']] = child['name'];
          }
        });
      }
    });
    // print(g);
    // print(cord);
    pathGenerate();
  }

  void pathGenerate() {
    final q = Queue<List<String>>();
    var temp = ["2225601_7077014"];
    q.addLast(temp);
    String target = "2225603_7077011";
    while (q.isNotEmpty) {
      var currPath = q.first;
      q.removeFirst();
      String currNode = currPath.last;
      g[currNode]!.forEach((key, value) {
        if (!currPath.contains(value)) {
          var nextPath = List<String>.from(currPath);
          nextPath.add(key.toString());
          nextPath.add(value);
          if (value == target) {
            val = 1;
            print(nextPath);
            finalPath = nextPath;
            return;
          }
          q.addLast(nextPath);
        }
      });
    }
    if (val == 0) {
      val = 2;
      print("No path");
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Graph Screen"),
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
      body: finalPath.length == 0
          ? val == 0
              ? Text("Waiting for path")
              : Text("No path found")
          : ListView.builder(
              itemCount: finalPath.length,
              itemBuilder: (context, index) {
                if (index % 2 == 1) {
                  return Container();
                } else {
                  if (index == finalPath.length - 1) {
                    return Text(finalPath[index]);
                  } else {
                    return Text(
                        finalPath[index] + " ->" + finalPath[index + 1]);
                  }
                }
              },
            ),
    );
  }
}
