import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

abstract final class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (!kIsWeb) {
      throw UnsupportedError('The administration app only supports the web.');
    }
    return web;
  }

  static const web = FirebaseOptions(
    apiKey: 'AIzaSyABPkahCCOUVcfeFops0kURujITabk-OL8',
    appId: '1:340710725222:web:db4a5cb1e6e6f767d53fa7',
    messagingSenderId: '340710725222',
    projectId: 'question-reponse-app',
    authDomain: 'question-reponse-app.firebaseapp.com',
    storageBucket: 'question-reponse-app.firebasestorage.app',
  );
}
