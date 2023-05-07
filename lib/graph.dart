import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hi/main.dart';

late Map<String, Map<int, String>> g;
late Map<String, GeoPoint> cord;
late Map<String, String> names;

Future<List<String>> createGraph(String source, String target) async {
  g = new Map();
  cord = new Map();
  names = new Map();
  CollectionReference users = FirebaseFirestore.instance.collection('points');
  await users.get().then((QuerySnapshot querySnapshot) async {
    for (var element in querySnapshot.docs) {
      if (g[element.id] == null) {
        g[element.id] = new Map();
      }
      if (element['name'] != '') {
        names[element.id] = element['name'];
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
  List<String> ans = await pathGenerate(source, target);
  print(ans);
  return ans;
}

Future<List<String>> pathGenerate(String source, String target) async {
  List<String> finalPath = [];
  final q = Queue<List<String>>();
  names.forEach((key, value) {
    if (value == target) {
      target = key;
      return;
    }
  });
  if (source == target) {
    return [source];
  }
  var temp = [source];
  q.addLast(temp);
  int val = 0;
  while (q.isNotEmpty) {
    var currPath = q.first;
    q.removeFirst();
    String currNode = currPath.last;
    if (g[currNode] == null) {
      continue;
    }
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
    if (val == 1) {
      break;
    }
  }
  if (val == 0) {
    val = 2;
    print("No path");
    return [];
  }
  return finalPath;
}
