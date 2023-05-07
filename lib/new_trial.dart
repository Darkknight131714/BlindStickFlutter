import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:telephony/telephony.dart';

class SMSTrial extends StatefulWidget {
  const SMSTrial({super.key});

  @override
  State<SMSTrial> createState() => _SMSTrialState();
}

class _SMSTrialState extends State<SMSTrial> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Bonjour"),
      ),
      body: ElevatedButton(
        onPressed: () async {
          final Telephony telephony = Telephony.instance;
          bool? permissionsGranted =
              await telephony.requestPhoneAndSmsPermissions;
          if (permissionsGranted! == false) {
            return;
          }
          telephony.sendSms(
              to: "9521424328", message: "May the force be with you!");
        },
        child: Text("Press"),
      ),
    );
  }
}
