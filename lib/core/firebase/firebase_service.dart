import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FB {
  FB._();
  static final auth    = FirebaseAuth.instance;
  static final db      = FirebaseFirestore.instance;
  static final storage = FirebaseStorage.instance;
  static String get uid => auth.currentUser!.uid;
  static String get today => DateTime.now().toIso8601String().substring(0, 10);
}
